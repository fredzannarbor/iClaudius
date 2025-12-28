import Foundation

actor ControlPlaneScanner {
    private let fileManager = FileManager.default
    private let homeDir: String

    init() {
        self.homeDir = NSHomeDirectory()
    }

    // MARK: - Main Scan

    func scanControlPlane(baseConfig: ClaudeConfiguration) async -> ControlPlaneConfiguration {
        var cpConfig = ControlPlaneConfiguration()

        print("[ControlPlaneScanner] Starting scan...")
        print("[ControlPlaneScanner] Base config has \(baseConfig.claudeMDFiles.count) CLAUDE.md files")

        // Build entities from base config
        cpConfig.entities = buildEntities(from: baseConfig)
        print("[ControlPlaneScanner] Built \(cpConfig.entities.count) entities")

        // Build dependency graph
        cpConfig.dependencies = buildDependencies(from: baseConfig)

        // Detect conflicts
        cpConfig.conflicts = detectConflicts(in: baseConfig)
        print("[ControlPlaneScanner] Detected \(cpConfig.conflicts.count) conflicts")

        // Build permission surface
        cpConfig.permissionSurface = buildPermissionSurface(from: baseConfig)

        // Build safety dashboard
        cpConfig.safetyDashboard = buildSafetyDashboard(from: baseConfig, permissionSurface: cpConfig.permissionSurface)

        // Load execution traces
        cpConfig.executionTraces = await loadExecutionTraces()
        print("[ControlPlaneScanner] Loaded \(cpConfig.executionTraces.count) execution traces")

        cpConfig.sessions = await loadSessions()
        print("[ControlPlaneScanner] Loaded \(cpConfig.sessions.count) sessions")

        // Load prompt versions (archaeology)
        cpConfig.promptVersions = await loadPromptVersions(for: baseConfig.claudeMDFiles)
        print("[ControlPlaneScanner] Loaded \(cpConfig.promptVersions.count) prompt versions")

        // Build capability coverage
        cpConfig.capabilityCoverage = buildCapabilityCoverage(from: baseConfig)

        // Build interaction graph
        cpConfig.interactionGraph = buildInteractionGraph(entities: cpConfig.entities, dependencies: cpConfig.dependencies)

        // Get runtime state
        cpConfig.runtimeState = await getRuntimeState(baseConfig: baseConfig)

        print("[ControlPlaneScanner] Scan complete!")
        return cpConfig
    }

    // MARK: - Entity Building

    private func buildEntities(from config: ClaudeConfiguration) -> [ControlEntity] {
        var entities: [ControlEntity] = []

        // Context Layer: CLAUDE.md files
        for file in config.claudeMDFiles {
            entities.append(ControlEntity(
                name: file.filename,
                type: .claudeMD,
                layer: .context,
                path: file.path,
                content: file.content,
                dependencies: extractDependencies(from: file.content),
                lastModified: file.lastModified,
                health: determineHealth(for: file)
            ))
        }

        // Behavior Layer: Commands and Skills
        for cmd in config.slashCommands {
            let entityType: ControlEntity.ControlEntityType = cmd.source == .skill ? .skill : .command
            entities.append(ControlEntity(
                name: cmd.name,
                type: entityType,
                layer: .behavior,
                path: cmd.path,
                content: cmd.content,
                dependencies: extractCommandDependencies(from: cmd.content),
                lastModified: nil,
                health: .healthy
            ))
        }

        // Capability Layer: Plugins
        for plugin in config.plugins {
            entities.append(ControlEntity(
                name: plugin.displayName,
                type: .plugin,
                layer: .capability,
                path: plugin.installPath,
                content: nil,
                dependencies: [],
                lastModified: plugin.installedAt,
                health: plugin.isEnabled ? .healthy : .warning
            ))
        }

        // Orchestration Layer: Cron Jobs
        for (index, job) in config.cronJobs.enumerated() {
            entities.append(ControlEntity(
                name: "Cron #\(index + 1)",
                type: .cronJob,
                layer: .orchestration,
                path: nil,
                content: "\(job.schedule) \(job.command)",
                dependencies: extractCronDependencies(from: job.command),
                lastModified: nil,
                health: .healthy
            ))
        }

        // Check for hooks
        let hooksDir = "\(homeDir)/.claude/hooks"
        if let hookFiles = try? fileManager.contentsOfDirectory(atPath: hooksDir) {
            for hookFile in hookFiles {
                entities.append(ControlEntity(
                    name: hookFile,
                    type: .hook,
                    layer: .behavior,
                    path: "\(hooksDir)/\(hookFile)",
                    content: nil,
                    dependencies: [],
                    lastModified: nil,
                    health: .healthy
                ))
            }
        }

        // Check for agent queues
        let agentQueuePaths = [
            "\(homeDir)/xcu_my_apps/nimble/codexes-factory/imprints/xynapse_traces/agent_queue"
        ]
        for queuePath in agentQueuePaths {
            if fileManager.fileExists(atPath: queuePath) {
                entities.append(ControlEntity(
                    name: "Xynapse Agent Queue",
                    type: .agentQueue,
                    layer: .orchestration,
                    path: queuePath,
                    content: nil,
                    dependencies: [],
                    lastModified: nil,
                    health: .healthy
                ))
            }
        }

        return entities
    }

    private func extractDependencies(from content: String) -> [String] {
        var deps: [String] = []

        // Look for references to other files
        let fileRefPattern = #"~/.claude/\S+"#
        if let regex = try? NSRegularExpression(pattern: fileRefPattern) {
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            let matches = regex.matches(in: content, range: range)
            for match in matches {
                if let range = Range(match.range, in: content) {
                    deps.append(String(content[range]))
                }
            }
        }

        // Look for command references
        let cmdPattern = #"/[\w-]+"#
        if let regex = try? NSRegularExpression(pattern: cmdPattern) {
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            let matches = regex.matches(in: content, range: range)
            for match in matches {
                if let range = Range(match.range, in: content) {
                    let cmd = String(content[range])
                    if cmd.count > 1 && cmd.count < 50 { // Reasonable command name length
                        deps.append(cmd)
                    }
                }
            }
        }

        return Array(Set(deps))
    }

    private func extractCommandDependencies(from content: String) -> [String] {
        var deps: [String] = []

        // Look for tool references
        let toolPatterns = ["Bash", "Read", "Edit", "Write", "Glob", "Grep", "Task"]
        for tool in toolPatterns {
            if content.contains(tool) {
                deps.append("Tool: \(tool)")
            }
        }

        // Look for other command references
        let cmdPattern = #"/[\w-]+"#
        if let regex = try? NSRegularExpression(pattern: cmdPattern) {
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            let matches = regex.matches(in: content, range: range)
            for match in matches {
                if let range = Range(match.range, in: content) {
                    deps.append(String(content[range]))
                }
            }
        }

        return Array(Set(deps))
    }

    private func extractCronDependencies(from command: String) -> [String] {
        var deps: [String] = []

        // Look for script paths
        if command.contains(".py") {
            deps.append("Python Runtime")
        }
        if command.contains("claude") {
            deps.append("Claude CLI")
        }
        if command.contains("xynapse") {
            deps.append("Xynapse Queue")
        }

        return deps
    }

    private func determineHealth(for file: ClaudeMDFile) -> ControlEntity.EntityHealth {
        // Check for staleness
        if let modified = file.lastModified {
            let daysSinceModified = Calendar.current.dateComponents([.day], from: modified, to: Date()).day ?? 0
            if daysSinceModified > 180 {
                return .warning
            }
        }

        // Check for basic content issues
        if file.content.isEmpty {
            return .error
        }

        return .healthy
    }

    // MARK: - Dependency Graph

    private func buildDependencies(from config: ClaudeConfiguration) -> [Dependency] {
        var deps: [Dependency] = []

        // Commands that reference other commands
        for cmd in config.slashCommands {
            let content = cmd.content.lowercased()
            for otherCmd in config.slashCommands where otherCmd.name != cmd.name {
                if content.contains("/\(otherCmd.name)") {
                    deps.append(Dependency(
                        source: cmd.name,
                        target: otherCmd.name,
                        type: .references,
                        strength: .soft
                    ))
                }
            }
        }

        // Cron jobs that invoke commands
        for (index, job) in config.cronJobs.enumerated() {
            for cmd in config.slashCommands {
                if job.command.contains(cmd.name) {
                    deps.append(Dependency(
                        source: "Cron #\(index + 1)",
                        target: cmd.name,
                        type: .triggers,
                        strength: .hard
                    ))
                }
            }
        }

        // CLAUDE.md files that reference commands
        for file in config.claudeMDFiles {
            for cmd in config.slashCommands {
                if file.content.contains("/\(cmd.name)") {
                    deps.append(Dependency(
                        source: file.filename,
                        target: cmd.name,
                        type: .references,
                        strength: .soft
                    ))
                }
            }
        }

        return deps
    }

    // MARK: - Conflict Detection

    private func detectConflicts(in config: ClaudeConfiguration) -> [Conflict] {
        var conflicts: [Conflict] = []

        // Check for name collisions in commands
        var commandNames: [String: [String]] = [:]
        for cmd in config.slashCommands {
            commandNames[cmd.name.lowercased(), default: []].append(cmd.path)
        }

        for (name, paths) in commandNames where paths.count > 1 {
            let fileNames = paths.map { ($0 as NSString).lastPathComponent }.joined(separator: ", ")
            conflicts.append(Conflict(
                entities: paths,
                type: .nameCollision,
                severity: .critical,
                description: "Command /\(name) defined in: \(fileNames)",
                resolution: "Remove duplicate definitions or rename one of the commands"
            ))
        }

        // Check for contradictory instructions in CLAUDE.md files
        let contradictionPairs: [(String, String, String)] = [
            ("always", "never", "contradictory frequency"),
            ("must", "must not", "contradictory requirement"),
            ("required", "forbidden", "contradictory mandate")
        ]

        for file in config.claudeMDFiles {
            let content = file.content.lowercased()
            let fileName = file.filename
            let fileLevel = file.level.rawValue

            for (word1, word2, context) in contradictionPairs {
                if content.contains(word1) && content.contains(word2) {
                    // Find lines containing these words for more context
                    let lines = file.content.components(separatedBy: .newlines)
                    var exampleLines: [String] = []

                    for line in lines {
                        let lower = line.lowercased()
                        if lower.contains(word1) || lower.contains(word2) {
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            if trimmed.count > 10 && exampleLines.count < 2 {
                                exampleLines.append(String(trimmed.prefix(60)) + (trimmed.count > 60 ? "..." : ""))
                            }
                        }
                    }

                    let exampleText = exampleLines.isEmpty ? "" : " Example: \"\(exampleLines.first ?? "")\""

                    conflicts.append(Conflict(
                        entities: [file.path],
                        type: .contradictoryInstructions,
                        severity: .warning,
                        description: "[\(fileLevel)] \(fileName): \(context) ('\(word1)' vs '\(word2)').\(exampleText)",
                        resolution: "Review \(fileName) and clarify the instructions to avoid ambiguity"
                    ))
                }
            }
        }

        // Check for permission conflicts
        if let settings = config.settings?.permissions,
           let localPerms = config.localSettings?.permissions {
            // If something is in both allow and deny
            let allowed = Set(settings.allow ?? [])
            let denied = Set(settings.deny ?? [])
            let overlap = allowed.intersection(denied)

            for item in overlap {
                conflicts.append(Conflict(
                    entities: ["settings.json", "settings.local.json"],
                    type: .permissionConflict,
                    severity: .critical,
                    description: "'\(item)' is in both allow and deny lists across settings files",
                    resolution: "Remove from one of the lists in settings.json or settings.local.json"
                ))
            }

            // Also check for local overrides conflicting with global
            let localAllowed = Set(localPerms.allow ?? [])
            let localDenied = Set(localPerms.deny ?? [])

            let globalAllowLocalDeny = allowed.intersection(localDenied)
            for item in globalAllowLocalDeny {
                conflicts.append(Conflict(
                    entities: ["settings.json (allow)", "settings.local.json (deny)"],
                    type: .permissionConflict,
                    severity: .warning,
                    description: "'\(item)' allowed globally but denied locally",
                    resolution: "This may be intentional (local override), but verify the intent"
                ))
            }

            let globalDenyLocalAllow = denied.intersection(localAllowed)
            for item in globalDenyLocalAllow {
                conflicts.append(Conflict(
                    entities: ["settings.json (deny)", "settings.local.json (allow)"],
                    type: .permissionConflict,
                    severity: .warning,
                    description: "'\(item)' denied globally but allowed locally - security concern",
                    resolution: "Local settings are overriding global security restrictions"
                ))
            }
        }

        return conflicts
    }

    // MARK: - Permission Surface

    private func buildPermissionSurface(from config: ClaudeConfiguration) -> PermissionSurface {
        var allowed: [PermissionEntry] = []
        let denied: [PermissionEntry] = []
        var sensitive: [SensitiveOperation] = []
        var recommendations: [PermissionRecommendation] = []

        // Parse allowed permissions
        if let allowList = config.localSettings?.permissions?.allow {
            for pattern in allowList {
                allowed.append(PermissionEntry(
                    pattern: pattern,
                    source: "settings.local.json",
                    grantedAt: nil
                ))

                // Check if this is a sensitive operation
                if isSensitiveOperation(pattern) {
                    sensitive.append(SensitiveOperation(
                        operation: pattern,
                        risk: riskLevel(for: pattern),
                        description: sensitiveOperationDescription(for: pattern),
                        mitigation: sensitiveOperationMitigation(for: pattern)
                    ))
                }
            }
        }

        // Generate recommendations
        if allowed.count > 100 {
            recommendations.append(PermissionRecommendation(
                title: "Large Permission List",
                description: "You have \(allowed.count) allowed operations. Consider consolidating with wildcards.",
                priority: .medium,
                action: "Review and consolidate permissions"
            ))
        }

        if sensitive.filter({ $0.risk == .high }).count > 3 {
            recommendations.append(PermissionRecommendation(
                title: "Multiple High-Risk Permissions",
                description: "You have several high-risk operations permitted. Review necessity.",
                priority: .high,
                action: "Audit high-risk permissions"
            ))
        }

        return PermissionSurface(
            totalPermissions: allowed.count,
            allowedCommands: allowed,
            deniedCommands: denied,
            sensitiveOperations: sensitive,
            recommendations: recommendations
        )
    }

    private func isSensitiveOperation(_ pattern: String) -> Bool {
        let sensitivePatterns = [
            "rm", "delete", "sudo", "chmod", "chown",
            "curl", "wget", "ssh", "scp",
            "git push", "git reset --hard",
            "drop", "truncate",
            ".env", "credentials", "secret", "password"
        ]
        return sensitivePatterns.contains { pattern.lowercased().contains($0) }
    }

    private func riskLevel(for pattern: String) -> SensitiveOperation.RiskLevel {
        let highRisk = ["rm -rf", "sudo", "drop", "truncate", "reset --hard", "force push"]
        let mediumRisk = ["rm", "delete", "curl", "wget", "ssh", ".env"]

        if highRisk.contains(where: { pattern.lowercased().contains($0) }) {
            return .high
        } else if mediumRisk.contains(where: { pattern.lowercased().contains($0) }) {
            return .medium
        }
        return .low
    }

    private func sensitiveOperationDescription(for pattern: String) -> String {
        if pattern.contains("rm") || pattern.contains("delete") {
            return "File deletion operations can cause data loss"
        } else if pattern.contains("ssh") || pattern.contains("curl") {
            return "Network operations can expose data or systems"
        } else if pattern.contains(".env") || pattern.contains("secret") {
            return "Access to sensitive configuration files"
        }
        return "Operation may have security implications"
    }

    private func sensitiveOperationMitigation(for pattern: String) -> String? {
        if pattern.contains("rm") {
            return "Consider requiring confirmation for destructive operations"
        } else if pattern.contains("ssh") {
            return "Limit to specific hosts when possible"
        }
        return nil
    }

    // MARK: - Safety Dashboard

    private func buildSafetyDashboard(from config: ClaudeConfiguration, permissionSurface: PermissionSurface?) -> SafetyDashboard {
        var loops: [AutonomousLoop] = []
        let riskyOps: [RiskyOperation] = []

        // Detect autonomous loops from cron jobs
        for job in config.cronJobs {
            loops.append(AutonomousLoop(
                name: job.description,
                type: .cronTriggered,
                frequency: job.scheduleDescription,
                lastRun: nil,
                isActive: true,
                entities: extractCronDependencies(from: job.command)
            ))
        }

        // Check for agent queues (Xynapse-style)
        let queuePath = "\(homeDir)/xcu_my_apps/nimble/codexes-factory/imprints/xynapse_traces/agent_queue"
        if fileManager.fileExists(atPath: queuePath) {
            loops.append(AutonomousLoop(
                name: "Xynapse Traces Queue",
                type: .agentQueue,
                frequency: "On demand",
                lastRun: nil,
                isActive: true,
                entities: ["Xynapse skill", "Queue processor"]
            ))
        }

        // Calculate safety score
        let permSurface = permissionSurface ?? buildPermissionSurface(from: config)
        let highRiskCount = permSurface.sensitiveOperations.filter { $0.risk == .high }.count
        let conflictCount = detectConflicts(in: config).count

        var safetyScore = 100
        safetyScore -= highRiskCount * 15
        safetyScore -= conflictCount * 10
        safetyScore -= loops.filter { $0.type == .selfInvoking }.count * 20
        safetyScore = max(0, min(100, safetyScore))

        // Determine overall status
        let status: SafetyDashboard.SafetyStatus
        if safetyScore >= 80 {
            status = .secure
        } else if safetyScore >= 50 {
            status = .caution
        } else {
            status = .alert
        }

        return SafetyDashboard(
            overallStatus: status,
            permissionSurface: permSurface,
            autonomousLoops: loops,
            recentRiskyOperations: riskyOps,
            safetyScore: safetyScore
        )
    }

    // MARK: - Execution Traces

    private func loadExecutionTraces() async -> [ExecutionTrace] {
        var traces: [ExecutionTrace] = []

        // Look for session directories in ~/.claude/projects
        let projectsDir = "\(homeDir)/.claude/projects"
        if let projectDirs = try? fileManager.contentsOfDirectory(atPath: projectsDir) {
            for projectDir in projectDirs.prefix(10) { // Limit to recent 10
                let projectPath = "\(projectsDir)/\(projectDir)"

                // Each project directory has .jsonl session files
                if let sessionFiles = try? fileManager.contentsOfDirectory(atPath: projectPath) {
                    // Filter for .jsonl files (session logs)
                    let jsonlFiles = sessionFiles.filter({ $0.hasSuffix(".jsonl") })

                    for sessionFile in jsonlFiles.prefix(5) {
                        // Get file modification date and size
                        let filePath = "\(projectPath)/\(sessionFile)"
                        let attrs = try? fileManager.attributesOfItem(atPath: filePath)
                        let modDate = attrs?[.modificationDate] as? Date ?? Date()
                        let fileSize = attrs?[.size] as? Int ?? 0

                        // Clean up project name for display
                        let displayName = projectDir
                            .replacingOccurrences(of: "-Users-fred-", with: "")
                            .replacingOccurrences(of: "-", with: "/")

                        traces.append(ExecutionTrace(
                            timestamp: modDate,
                            commandName: displayName,
                            sessionId: String(sessionFile.prefix(8)), // First 8 chars of UUID
                            status: .success,
                            duration: 0,
                            tokensUsed: fileSize > 0 ? fileSize / 1000 : nil, // Rough estimate
                            toolCalls: [],
                            errorMessage: nil
                        ))
                    }
                }
            }
        }

        // Also check for recent tool usage in stats
        let statsPath = "\(homeDir)/.claude/stats-cache.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: statsPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            // Extract tool call counts
            if let toolCalls = json["toolCallCount"] as? Int, toolCalls > 0 {
                traces.append(ExecutionTrace(
                    timestamp: Date(),
                    commandName: "Aggregate Stats",
                    sessionId: "tool-summary",
                    status: .success,
                    duration: 0,
                    tokensUsed: nil,
                    toolCalls: ["Total: \(toolCalls) tool calls"],
                    errorMessage: nil
                ))
            }

            if let messages = json["messageCount"] as? Int, messages > 0 {
                traces.append(ExecutionTrace(
                    timestamp: Date(),
                    commandName: "Message History",
                    sessionId: "message-summary",
                    status: .success,
                    duration: 0,
                    tokensUsed: messages,
                    toolCalls: [],
                    errorMessage: nil
                ))
            }
        }

        return traces
    }

    private func loadSessions() async -> [SessionInfo] {
        var sessions: [SessionInfo] = []

        // Parse from stats-cache.json
        let statsPath = "\(homeDir)/.claude/stats-cache.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: statsPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            // Try the dailyActivity format
            if let dailyActivity = json["dailyActivity"] as? [[String: Any]] {
                // Use simple date formatter for "YYYY-MM-DD" format
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone.current

                for day in dailyActivity.suffix(30) { // Last 30 days
                    if let sessionCount = day["sessionCount"] as? Int,
                       let messageCount = day["messageCount"] as? Int,
                       let dateStr = day["date"] as? String,
                       sessionCount > 0 {

                        if let date = formatter.date(from: dateStr) {
                            sessions.append(SessionInfo(
                                id: dateStr,
                                startTime: date,
                                endTime: Calendar.current.date(byAdding: .hour, value: 8, to: date),
                                messageCount: messageCount,
                                toolCallCount: day["toolCallCount"] as? Int ?? 0,
                                commandsUsed: [],
                                status: .completed
                            ))
                        }
                    }
                }
            }

            // If no dailyActivity parsed, create summary from totals
            if sessions.isEmpty {
                let messageCount = json["messageCount"] as? Int ?? 0
                let sessionCount = json["sessionCount"] as? Int ?? 0
                let toolCallCount = json["toolCallCount"] as? Int ?? 0

                if messageCount > 0 || sessionCount > 0 {
                    sessions.append(SessionInfo(
                        id: "aggregate-stats",
                        startTime: Date(),
                        endTime: nil,
                        messageCount: messageCount,
                        toolCallCount: toolCallCount,
                        commandsUsed: [],
                        status: .completed
                    ))
                }
            }
        }

        // If still empty, scan for project directories to show some activity
        if sessions.isEmpty {
            let projectsDir = "\(homeDir)/.claude/projects"
            if let projectDirs = try? fileManager.contentsOfDirectory(atPath: projectsDir) {
                for (index, projectDir) in projectDirs.prefix(10).enumerated() {
                    let projectPath = "\(projectsDir)/\(projectDir)"
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory), isDirectory.boolValue {
                        let attrs = try? fileManager.attributesOfItem(atPath: projectPath)
                        let modDate = attrs?[.modificationDate] as? Date ?? Date()

                        // Clean up the directory name for display
                        let displayName = projectDir.replacingOccurrences(of: "-", with: "/")

                        sessions.append(SessionInfo(
                            id: "project-\(index)",
                            startTime: modDate,
                            endTime: nil,
                            messageCount: 0,
                            toolCallCount: 0,
                            commandsUsed: [displayName],
                            status: .completed
                        ))
                    }
                }
            }
        }

        // Sort by date descending
        sessions.sort { $0.startTime > $1.startTime }

        return sessions
    }

    // MARK: - Prompt Archaeology

    private func loadPromptVersions(for files: [ClaudeMDFile]) async -> [PromptVersion] {
        var versions: [PromptVersion] = []

        for file in files {
            var hasGitHistory = false

            // Try to get git history for the file
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["log", "--oneline", "-5", "--", file.path]
            process.currentDirectoryURL = URL(fileURLWithPath: (file.path as NSString).deletingLastPathComponent)

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let commits = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    if !commits.isEmpty {
                        hasGitHistory = true
                        for (index, commit) in commits.enumerated() {
                            let parts = commit.components(separatedBy: " ")
                            let summary = parts.dropFirst().joined(separator: " ")

                            versions.append(PromptVersion(
                                path: file.path,
                                version: commits.count - index,
                                timestamp: file.lastModified ?? Date(),
                                content: file.content,
                                changeType: index == 0 ? .modified : .modified,
                                summary: summary
                            ))
                        }
                    }
                }
            } catch {
                // Git failed, will add current version below
            }

            // Always add at least the current version if no git history
            if !hasGitHistory {
                // Determine change type based on file level
                let changeType: PromptVersion.ChangeType = file.level == .global ? .created : .modified

                versions.append(PromptVersion(
                    path: file.path,
                    version: 1,
                    timestamp: file.lastModified ?? Date(),
                    content: file.content,
                    changeType: changeType,
                    summary: "[\(file.level.rawValue)] \(file.filename)"
                ))
            }
        }

        // Sort by timestamp descending
        versions.sort { ($0.timestamp) > ($1.timestamp) }

        return versions
    }

    // MARK: - Capability Coverage

    private func buildCapabilityCoverage(from config: ClaudeConfiguration) -> CapabilityCoverage {
        // Define base Claude capabilities
        let baseCapabilities = [
            "Code generation",
            "Code review",
            "Debugging",
            "File operations",
            "Git operations",
            "Web search",
            "Documentation"
        ]

        // Determine extended capabilities from commands/skills
        var extendedCapabilities: [String] = []
        var domainCoverage: [String: [String]] = [:]

        for cmd in config.slashCommands {
            let content = cmd.content.lowercased()

            // Categorize by domain
            if content.contains("health") || content.contains("fitness") {
                domainCoverage["Health & Wellness", default: []].append(cmd.name)
                extendedCapabilities.append("Health tracking")
            }
            if content.contains("budget") || content.contains("financial") {
                domainCoverage["Finance", default: []].append(cmd.name)
                extendedCapabilities.append("Financial analysis")
            }
            if content.contains("book") || content.contains("isbn") || content.contains("publish") {
                domainCoverage["Publishing", default: []].append(cmd.name)
                extendedCapabilities.append("Publishing workflow")
            }
            if content.contains("test") || content.contains("ux") {
                domainCoverage["Testing", default: []].append(cmd.name)
                extendedCapabilities.append("UX testing")
            }
            if content.contains("commit") || content.contains("pr") || content.contains("review") {
                domainCoverage["Development", default: []].append(cmd.name)
            }
        }

        // Build domain objects
        var domains: [CoverageDomain] = []
        let colors = ["blue", "green", "purple", "orange", "pink", "cyan"]
        let icons = ["heart.text.square", "dollarsign.circle", "book.closed", "person.crop.rectangle.stack", "hammer"]

        for (index, (domain, capabilities)) in domainCoverage.enumerated() {
            domains.append(CoverageDomain(
                name: domain,
                icon: icons[index % icons.count],
                color: colors[index % colors.count],
                coverage: Double(capabilities.count) / 10.0, // Arbitrary scale
                capabilities: capabilities,
                isExtended: true
            ))
        }

        // Identify gaps
        var gaps: [CapabilityGap] = []
        if !extendedCapabilities.contains("Health tracking") {
            gaps.append(CapabilityGap(
                domain: "Health & Wellness",
                missingCapability: "Health tracking",
                suggestion: "Add /track-health command",
                difficulty: .easy
            ))
        }

        return CapabilityCoverage(
            domains: domains,
            baseCapabilities: baseCapabilities,
            extendedCapabilities: Array(Set(extendedCapabilities)),
            gapAnalysis: gaps
        )
    }

    // MARK: - Interaction Graph

    private func buildInteractionGraph(entities: [ControlEntity], dependencies: [Dependency]) -> InteractionGraph {
        // Create nodes from entities
        var nodes: [InteractionNode] = []
        var nodeMap: [String: InteractionNode] = [:]

        for entity in entities {
            let node = InteractionNode(
                name: entity.name,
                type: entity.type,
                layer: entity.layer
            )
            nodes.append(node)
            nodeMap[entity.name] = node
        }

        // Create edges from dependencies
        var edges: [InteractionEdge] = []
        for dep in dependencies {
            if let sourceNode = nodeMap[dep.source],
               let targetNode = nodeMap[dep.target] {
                edges.append(InteractionEdge(
                    source: sourceNode,
                    target: targetNode,
                    relationship: dep.type,
                    weight: dep.strength == .hard ? 1.0 : 0.5
                ))
            }
        }

        return InteractionGraph(nodes: nodes, edges: edges)
    }

    // MARK: - Runtime State

    private func getRuntimeState(baseConfig: ClaudeConfiguration) async -> RuntimeState {
        // Check if Claude is currently running
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "claude"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        var isActive = false
        if let _ = try? process.run() {
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            isActive = !data.isEmpty
        }

        // Get recent commands from history if available
        var recentCommands: [String] = []
        for cmd in baseConfig.slashCommands.prefix(5) {
            recentCommands.append(cmd.name)
        }

        // Get active hooks
        let activeHooks = baseConfig.slashCommands
            .filter { $0.content.lowercased().contains("hook") }
            .map { $0.name }

        // Get loaded plugins (deduplicated)
        let loadedPlugins = Array(Set(baseConfig.plugins
            .filter { $0.isEnabled }
            .map { $0.name }))

        return RuntimeState(
            isActive: isActive,
            currentSession: nil,
            recentCommands: recentCommands,
            activeHooks: activeHooks,
            loadedPlugins: loadedPlugins,
            memoryUsage: nil,
            lastActivity: baseConfig.accountInfo?.lastActiveDate.flatMap { str in
                ISO8601DateFormatter().date(from: str)
            }
        )
    }
}
