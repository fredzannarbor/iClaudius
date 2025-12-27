import Foundation

actor ConfigScanner {
    private let fileManager = FileManager.default
    private let homeDir: String

    init() {
        self.homeDir = NSHomeDirectory()
    }

    // MARK: - Main Scan

    func scanAll() async -> ClaudeConfiguration {
        var config = ClaudeConfiguration()

        async let mdFiles = scanClaudeMDFiles()
        async let commands = scanSlashCommands()
        async let plugins = scanPlugins()
        async let crons = scanCronJobs()
        async let settings = loadSettings()
        async let localSettings = loadLocalSettings()
        async let accountInfo = scanAccountInfo()

        config.claudeMDFiles = await mdFiles
        config.slashCommands = await commands
        config.plugins = await plugins
        config.cronJobs = await crons
        config.settings = await settings
        config.localSettings = await localSettings
        config.accountInfo = await accountInfo

        // Run health checks after loading all data
        config.healthIssues = checkHealth(config: config)

        // Generate a customization suggestion
        config.suggestion = generateSuggestion(config: config)

        return config
    }

    // MARK: - Suggestion Generator

    func generateSuggestion(config: ClaudeConfiguration) -> CustomizationSuggestion? {
        var possibleSuggestions: [CustomizationSuggestion] = []

        // Analyze existing commands to suggest complementary ones
        let commandNames = Set(config.slashCommands.map { $0.name.lowercased() })

        // If they have commit but not review-pr
        if commandNames.contains("commit") && !commandNames.contains("review-pr") {
            possibleSuggestions.append(CustomizationSuggestion(
                title: "Add /review-pr Command",
                description: "You have a commit workflow. Consider adding a PR review command to complete your git workflow with automated code review summaries.",
                category: .command,
                actionLabel: "Create in ~/.claude/commands/",
                actionPath: "\(homeDir)/.claude/commands"
            ))
        }

        // If they have health tracking, suggest fitness integration
        if commandNames.contains("track-health") && !commandNames.contains("fitness-summary") {
            possibleSuggestions.append(CustomizationSuggestion(
                title: "Add /fitness-summary Command",
                description: "Complement your health tracking with a weekly fitness summary command that aggregates your metrics and provides insights.",
                category: .command,
                actionLabel: "Create Command",
                actionPath: "\(homeDir)/.claude/commands"
            ))
        }

        // If they have budget commands, suggest forecasting
        if (commandNames.contains("budget-report") || commandNames.contains("nimble-budget")) && !commandNames.contains("budget-forecast") {
            possibleSuggestions.append(CustomizationSuggestion(
                title: "Add /budget-forecast Command",
                description: "Extend your budgeting workflow with a forecasting command that projects future months based on historical patterns.",
                category: .command,
                actionLabel: "Create Command",
                actionPath: "\(homeDir)/.claude/commands"
            ))
        }

        // If they have followthrough, suggest reflection
        if commandNames.contains("followthrough") && !commandNames.contains("weekly-reflection") {
            possibleSuggestions.append(CustomizationSuggestion(
                title: "Add /weekly-reflection Command",
                description: "Pair your accountability tracking with a weekly reflection command to review progress and set intentions.",
                category: .command,
                actionLabel: "Create Command",
                actionPath: "\(homeDir)/.claude/commands"
            ))
        }

        // If no cron jobs, suggest automation
        if config.cronJobs.isEmpty {
            possibleSuggestions.append(CustomizationSuggestion(
                title: "Set Up Scheduled Automation",
                description: "You have no cron jobs configured. Consider scheduling daily tasks like queue processing or report generation to run automatically.",
                category: .automation,
                actionLabel: "Edit crontab",
                actionPath: nil
            ))
        }

        // If many plugins but few enabled
        if config.plugins.count > 5 && config.enabledPluginCount < 3 {
            possibleSuggestions.append(CustomizationSuggestion(
                title: "Enable More Plugins",
                description: "You have \(config.plugins.count) plugins installed but only \(config.enabledPluginCount) enabled. Review your plugins and enable ones that match your workflow.",
                category: .plugin,
                actionLabel: "Edit settings.json",
                actionPath: "\(homeDir)/.claude/settings.json"
            ))
        }

        // If they have UX test commands, suggest terminal variant
        if commandNames.contains("ux-test") && !commandNames.contains("ux-test-terminal") {
            possibleSuggestions.append(CustomizationSuggestion(
                title: "Add Terminal UX Testing",
                description: "Complement your GUI UX testing with terminal-specific tests for CLI applications.",
                category: .command,
                actionLabel: "Create Command",
                actionPath: "\(homeDir)/.claude/commands"
            ))
        }

        // General suggestions if no specific ones apply
        if possibleSuggestions.isEmpty {
            // Check if they have project-level CLAUDE.md
            let hasProjectMD = config.claudeMDFiles.contains { $0.level == .project }
            if !hasProjectMD {
                possibleSuggestions.append(CustomizationSuggestion(
                    title: "Add Project-Level CLAUDE.md",
                    description: "Create a CLAUDE.md in your main project directory to give Claude project-specific context and coding conventions.",
                    category: .optimization,
                    actionLabel: "Create File",
                    actionPath: "\(homeDir)/xcu_my_apps"
                ))
            }

            // Suggest model-selector skill if not present
            if !commandNames.contains("model-selector") {
                possibleSuggestions.append(CustomizationSuggestion(
                    title: "Add /model-selector Skill",
                    description: "Create a skill to help select the right LLM model for each task, ensuring you use cost-effective models appropriately.",
                    category: .command,
                    actionLabel: "Create in ~/.claude/skills/",
                    actionPath: "\(homeDir)/.claude/skills"
                ))
            }
        }

        // Return a random suggestion from the possibilities
        return possibleSuggestions.randomElement()
    }

    // MARK: - Account Info

    func scanAccountInfo() -> ClaudeAccountInfo {
        let username = NSUserName()
        let claudeDir = "\(homeDir)/.claude"

        // Get CLI version
        var cliVersion = "Unknown"
        let versionProcess = Process()
        versionProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        versionProcess.arguments = ["claude", "--version"]
        let versionPipe = Pipe()
        versionProcess.standardOutput = versionPipe
        versionProcess.standardError = FileHandle.nullDevice
        if let _ = try? versionProcess.run() {
            versionProcess.waitUntilExit()
            if let output = String(data: versionPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
                cliVersion = output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Parse stats cache for usage info
        var totalMessages = 0
        var totalSessions = 0
        var totalToolCalls = 0
        var lastActiveDate: String? = nil

        let statsPath = "\(claudeDir)/stats-cache.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: statsPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            lastActiveDate = json["lastComputedDate"] as? String

            if let dailyActivity = json["dailyActivity"] as? [[String: Any]] {
                for day in dailyActivity {
                    totalMessages += day["messageCount"] as? Int ?? 0
                    totalSessions += day["sessionCount"] as? Int ?? 0
                    totalToolCalls += day["toolCallCount"] as? Int ?? 0
                }
            }
        }

        return ClaudeAccountInfo(
            username: username,
            cliVersion: cliVersion,
            homeDirectory: homeDir,
            claudeDirectory: claudeDir,
            totalMessages: totalMessages,
            totalSessions: totalSessions,
            totalToolCalls: totalToolCalls,
            lastActiveDate: lastActiveDate
        )
    }

    // MARK: - Health Checks

    func checkHealth(config: ClaudeConfiguration) -> [HealthIssue] {
        var issues: [HealthIssue] = []

        // Check for missing global CLAUDE.md
        if !config.claudeMDFiles.contains(where: { $0.level == .global }) {
            issues.append(HealthIssue(
                severity: .warning,
                message: "No global CLAUDE.md found",
                detail: "Consider creating ~/.claude/CLAUDE.md for global instructions"
            ))
        }

        // Check for no enabled plugins
        if config.enabledPluginCount == 0 && !config.plugins.isEmpty {
            issues.append(HealthIssue(
                severity: .warning,
                message: "Plugins installed but none enabled",
                detail: "Enable plugins in settings.json to use them"
            ))
        }

        // Check for stale CLAUDE.md files (not modified in 90+ days)
        let staleThreshold = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        for file in config.claudeMDFiles {
            if let modDate = file.lastModified, modDate < staleThreshold {
                issues.append(HealthIssue(
                    severity: .warning,
                    message: "Stale CLAUDE.md: \(file.level.rawValue)",
                    detail: "Not modified since \(modDate.formatted(date: .abbreviated, time: .omitted))"
                ))
            }
        }

        // Check for very long allowed permissions list
        if let allow = config.localSettings?.permissions?.allow, allow.count > 50 {
            issues.append(HealthIssue(
                severity: .warning,
                message: "Large permissions allowlist (\(allow.count) entries)",
                detail: "Consider reviewing and consolidating allowed commands"
            ))
        }

        // Check if no slash commands defined
        if config.slashCommands.isEmpty {
            issues.append(HealthIssue(
                severity: .warning,
                message: "No custom slash commands",
                detail: "Create .md files in ~/.claude/commands/ to add custom commands"
            ))
        }

        return issues
    }

    // MARK: - CLAUDE.md Files

    func scanClaudeMDFiles() -> [ClaudeMDFile] {
        var files: [ClaudeMDFile] = []
        let searchPaths = [
            "\(homeDir)/.claude/CLAUDE.md",
            "\(homeDir)/CLAUDE.md",
            "\(homeDir)/xcu_my_apps/CLAUDE.md",
            "\(homeDir)/xcu_my_apps/nimble/codexes-factory/CLAUDE.md"
        ]

        // Also search for any CLAUDE.md in common project directories
        let projectDirs = [
            "\(homeDir)/xcu_my_apps",
            "\(homeDir)/xcode_projects"
        ]

        for path in searchPaths {
            if let file = loadClaudeMD(at: path) {
                files.append(file)
            }
        }

        // Deep scan project directories
        for dir in projectDirs {
            files.append(contentsOf: findClaudeMDRecursively(in: dir, maxDepth: 3))
        }

        // Remove duplicates
        var seen = Set<String>()
        files = files.filter { seen.insert($0.path).inserted }

        return files.sorted { $0.path < $1.path }
    }

    private func loadClaudeMD(at path: String) -> ClaudeMDFile? {
        guard fileManager.fileExists(atPath: path),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }

        let attrs = try? fileManager.attributesOfItem(atPath: path)
        let modDate = attrs?[.modificationDate] as? Date

        let level: ClaudeMDFile.ConfigLevel
        if path.contains(".claude/CLAUDE.md") {
            level = .global
        } else if path == "\(homeDir)/CLAUDE.md" {
            level = .user
        } else if path.components(separatedBy: "/").filter({ $0 == "CLAUDE.md" }).count == 1 {
            level = .project
        } else {
            level = .nested
        }

        return ClaudeMDFile(path: path, content: content, level: level, lastModified: modDate)
    }

    private func findClaudeMDRecursively(in directory: String, maxDepth: Int, currentDepth: Int = 0) -> [ClaudeMDFile] {
        guard currentDepth < maxDepth else { return [] }

        var results: [ClaudeMDFile] = []
        let claudePath = "\(directory)/CLAUDE.md"

        if let file = loadClaudeMD(at: claudePath) {
            results.append(file)
        }

        // Skip certain directories
        let skipDirs = [".git", "node_modules", ".venv", "__pycache__", ".idea", "build", "dist"]

        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory) else {
            return results
        }

        for item in contents {
            if skipDirs.contains(item) { continue }
            let itemPath = "\(directory)/\(item)"
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue {
                results.append(contentsOf: findClaudeMDRecursively(in: itemPath, maxDepth: maxDepth, currentDepth: currentDepth + 1))
            }
        }

        return results
    }

    // MARK: - Slash Commands

    func scanSlashCommands() -> [SlashCommand] {
        var commands: [SlashCommand] = []
        let commandsDir = "\(homeDir)/.claude/commands"
        let skillsDir = "\(homeDir)/.claude/skills"

        // User commands
        if let files = try? fileManager.contentsOfDirectory(atPath: commandsDir) {
            for file in files where file.hasSuffix(".md") {
                let path = "\(commandsDir)/\(file)"
                if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                    let name = String(file.dropLast(3)) // Remove .md
                    commands.append(SlashCommand(name: name, path: path, content: content, source: .user))
                }
            }
        }

        // Skills
        if let files = try? fileManager.contentsOfDirectory(atPath: skillsDir) {
            for file in files where file.hasSuffix(".md") {
                let path = "\(skillsDir)/\(file)"
                if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                    let name = String(file.dropLast(3))
                    commands.append(SlashCommand(name: name, path: path, content: content, source: .skill))
                }
            }
        }

        return commands.sorted { $0.name < $1.name }
    }

    // MARK: - Plugins

    func scanPlugins() -> [ClaudePlugin] {
        let pluginsFile = "\(homeDir)/.claude/plugins/installed_plugins.json"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: pluginsFile)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let plugins = json["plugins"] as? [String: [[String: Any]]] else {
            return []
        }

        var results: [ClaudePlugin] = []

        for (key, installs) in plugins {
            let parts = key.components(separatedBy: "@")
            let name = parts.first ?? key
            let marketplace = parts.count > 1 ? parts[1] : "unknown"

            for install in installs {
                let version = install["version"] as? String ?? "unknown"
                let installPath = install["installPath"] as? String ?? ""
                let installedAtStr = install["installedAt"] as? String
                let installedAt = installedAtStr.flatMap { ISO8601DateFormatter().date(from: $0) }

                // Check if enabled
                let settingsPath = "\(homeDir)/.claude/settings.json"
                var isEnabled = false
                if let settingsData = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
                   let settings = try? JSONSerialization.jsonObject(with: settingsData) as? [String: Any],
                   let enabled = settings["enabledPlugins"] as? [String: Bool] {
                    isEnabled = enabled[key] ?? false
                }

                results.append(ClaudePlugin(
                    name: name,
                    marketplace: marketplace,
                    version: version,
                    installPath: installPath,
                    installedAt: installedAt,
                    isEnabled: isEnabled,
                    skills: []
                ))
            }
        }

        return results.sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Cron Jobs

    func scanCronJobs() -> [CronJob] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/crontab")
        process.arguments = ["-l"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }

            var jobs: [CronJob] = []
            for line in output.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

                let parts = trimmed.components(separatedBy: " ")
                guard parts.count >= 6 else { continue }

                let schedule = parts[0...4].joined(separator: " ")
                let command = parts[5...].joined(separator: " ")

                // Try to identify Claude-related jobs
                let description: String
                if command.contains("claude") || command.contains("xynapse") {
                    description = "Claude queue processor"
                } else if command.contains("daily_runner") {
                    description = "Daily automation runner"
                } else {
                    description = "Scheduled task"
                }

                jobs.append(CronJob(schedule: schedule, command: command, description: description))
            }

            return jobs
        } catch {
            return []
        }
    }

    // MARK: - Cron Job Management

    func addCronJob(schedule: String, command: String) async throws {
        // Get current crontab
        let currentCrontab = await getCurrentCrontab()

        // Append new job
        let newLine = "\(schedule) \(command)"
        let updatedCrontab = currentCrontab.isEmpty ? newLine : "\(currentCrontab)\n\(newLine)"

        // Write to crontab
        try await writeCrontab(updatedCrontab)
    }

    func deleteCronJob(at index: Int) async throws {
        let currentCrontab = await getCurrentCrontab()
        var lines = currentCrontab.components(separatedBy: .newlines)

        // Filter to only cron job lines (not comments or empty)
        var jobLines: [(index: Int, line: String)] = []
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                jobLines.append((i, line))
            }
        }

        guard index < jobLines.count else { return }

        // Remove the line at the original index
        lines.remove(at: jobLines[index].index)

        let updatedCrontab = lines.joined(separator: "\n")
        try await writeCrontab(updatedCrontab)
    }

    func updateCronJob(at index: Int, schedule: String, command: String) async throws {
        let currentCrontab = await getCurrentCrontab()
        var lines = currentCrontab.components(separatedBy: .newlines)

        // Filter to only cron job lines
        var jobLines: [(index: Int, line: String)] = []
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                jobLines.append((i, line))
            }
        }

        guard index < jobLines.count else { return }

        // Update the line
        lines[jobLines[index].index] = "\(schedule) \(command)"

        let updatedCrontab = lines.joined(separator: "\n")
        try await writeCrontab(updatedCrontab)
    }

    private func getCurrentCrontab() async -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/crontab")
        process.arguments = ["-l"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private func writeCrontab(_ content: String) async throws {
        // Write to temp file
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("crontab_temp")
        try content.write(to: tempFile, atomically: true, encoding: .utf8)

        // Install the crontab
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/crontab")
        process.arguments = [tempFile.path]

        try process.run()
        process.waitUntilExit()

        // Clean up
        try? FileManager.default.removeItem(at: tempFile)

        if process.terminationStatus != 0 {
            throw NSError(domain: "CronError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to update crontab"])
        }
    }

    // MARK: - Settings

    func loadSettings() -> ClaudeSettings? {
        let path = "\(homeDir)/.claude/settings.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return try? JSONDecoder().decode(ClaudeSettings.self, from: data)
    }

    func loadLocalSettings() -> ClaudeSettings? {
        let path = "\(homeDir)/.claude/settings.local.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return try? JSONDecoder().decode(ClaudeSettings.self, from: data)
    }
}
