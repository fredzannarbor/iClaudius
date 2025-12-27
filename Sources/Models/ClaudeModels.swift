import Foundation

// MARK: - Config Health Status

enum ConfigHealth: String {
    case healthy = "All OK"
    case warning = "Possible Issues"
    case critical = "Problems Detected"

    var color: String {
        switch self {
        case .healthy: return "green"
        case .warning: return "yellow"
        case .critical: return "red"
        }
    }

    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

struct HealthIssue: Identifiable {
    let id = UUID()
    let severity: ConfigHealth
    let message: String
    let detail: String?
}

// MARK: - Capability Analysis

struct CapabilityAnalysis {
    let categories: [CapabilityCategory]
    let summaryText: String
    let totalExtensions: Int

    struct CapabilityCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: String
        let count: Int
        let commands: [String]
        let description: String
    }
}

enum CapabilityCategoryType: String, CaseIterable {
    // Personal & Life Management
    case accountability = "Personal Accountability"
    case health = "Health & Wellness"
    case finance = "Finance & Budget"

    // Publishing & Creative
    case publishing = "Publishing Operations"
    case creative = "Creative Development"

    // Product & Quality
    case uxTesting = "UX Testing"
    case distribution = "App Distribution"

    // Development
    case versionControl = "Version Control"
    case codeQuality = "Code Quality"
    case deployment = "Deployment"

    // Infrastructure
    case workflow = "Workflow Automation"
    case infrastructure = "Dev Infrastructure"
    case custom = "Custom/Other"

    var icon: String {
        switch self {
        case .accountability: return "checkmark.circle"
        case .health: return "heart.text.square"
        case .finance: return "dollarsign.circle"
        case .publishing: return "book.closed"
        case .creative: return "brain.head.profile"
        case .uxTesting: return "person.crop.rectangle.stack"
        case .distribution: return "app.badge"
        case .versionControl: return "arrow.triangle.branch"
        case .codeQuality: return "checkmark.seal"
        case .deployment: return "shippingbox"
        case .workflow: return "arrow.triangle.2.circlepath"
        case .infrastructure: return "wrench.and.screwdriver"
        case .custom: return "star"
        }
    }

    var color: String {
        switch self {
        case .accountability: return "purple"
        case .health: return "pink"
        case .finance: return "green"
        case .publishing: return "brown"
        case .creative: return "cyan"
        case .uxTesting: return "orange"
        case .distribution: return "blue"
        case .versionControl: return "orange"
        case .codeQuality: return "mint"
        case .deployment: return "red"
        case .workflow: return "blue"
        case .infrastructure: return "gray"
        case .custom: return "gray"
        }
    }

    // Keywords matched against command name AND content
    var keywords: [String] {
        switch self {
        case .accountability: return ["followthrough", "ft", "commitment", "promise", "accountability", "reflection", "weekly-reflection", "track", "habit"]
        case .health: return ["health", "fitness", "weight", "blood", "pressure", "exercise", "sleep", "wellness", "strava", "track-health", "fitness-summary"]
        case .finance: return ["budget", "money", "expense", "income", "financial", "cost", "nimble-budget", "budget-report", "budget-forecast", "survival", "fro"]
        case .publishing: return ["book", "isbn", "imprint", "imprint-queue", "xynapse", "codex", "lsi-keywords", "book-search", "keywords", "ingram", "kdp"]
        case .creative: return ["multiverse", "rkhs", "creative", "write", "draft", "outline", "story", "manuscript", "evolve", "ideation"]
        case .uxTesting: return ["ux-test", "ux-test-terminal", "user-test", "persona", "friction", "usability"]
        case .distribution: return ["appstore", "appstore-launch", "launch", "screenshot", "marketing", "app-store"]
        case .versionControl: return ["commit", "push", "pull", "merge", "branch", "git", "pr", "release", "version", "tag", "changelog"]
        case .codeQuality: return ["review", "lint", "format", "refactor", "clean", "quality", "style", "analyze", "check", "validate"]
        case .deployment: return ["deploy", "build", "ship", "package", "bundle", "dist", "prod", "remote", "server", "gcp"]
        case .workflow: return ["workflow", "automate", "pipeline", "process", "queue", "schedule", "batch", "agent"]
        case .infrastructure: return ["model-selector", "model", "selector", "llm", "litellm", "config", "setup"]
        case .custom: return []
        }
    }
}

// MARK: - Customization Suggestion

struct CustomizationSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: SuggestionCategory
    let actionLabel: String
    let actionPath: String?

    enum SuggestionCategory: String {
        case command = "New Command"
        case plugin = "Plugin"
        case automation = "Automation"
        case optimization = "Optimization"

        var icon: String {
            switch self {
            case .command: return "terminal.fill"
            case .plugin: return "puzzlepiece.extension.fill"
            case .automation: return "clock.fill"
            case .optimization: return "bolt.fill"
            }
        }

        var color: String {
            switch self {
            case .command: return "green"
            case .plugin: return "purple"
            case .automation: return "orange"
            case .optimization: return "blue"
            }
        }
    }
}

// MARK: - Account Info

struct ClaudeAccountInfo {
    let username: String
    let cliVersion: String
    let homeDirectory: String
    let claudeDirectory: String
    let totalMessages: Int
    let totalSessions: Int
    let totalToolCalls: Int
    let lastActiveDate: String?
}

// MARK: - CLAUDE.md File

struct ClaudeMDFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let content: String
    let level: ConfigLevel
    let lastModified: Date?

    var filename: String {
        (path as NSString).lastPathComponent
    }

    var directory: String {
        (path as NSString).deletingLastPathComponent
    }

    var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }

    enum ConfigLevel: String, CaseIterable {
        case global = "Global (~/.claude)"
        case user = "User (~)"
        case project = "Project"
        case nested = "Nested"

        var icon: String {
            switch self {
            case .global: return "globe"
            case .user: return "person"
            case .project: return "folder"
            case .nested: return "doc.text"
            }
        }

        var priority: Int {
            switch self {
            case .global: return 0
            case .user: return 1
            case .project: return 2
            case .nested: return 3
            }
        }
    }
}

// MARK: - Slash Command / Skill

struct SlashCommand: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let content: String
    let source: CommandSource
    let isAlias: Bool
    let aliasTarget: String?

    init(name: String, path: String, content: String, source: CommandSource) {
        self.name = name
        self.path = path
        self.content = content
        self.source = source

        // Detect if this is an alias (short content that references another command)
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines).filter { !$0.isEmpty }

        // Alias detection: short file that mentions "Alias for" or just references another command
        if lines.count <= 3 && trimmed.lowercased().contains("alias for") {
            self.isAlias = true
            // Try to extract target
            if let match = trimmed.range(of: #"/\w+"#, options: .regularExpression) {
                self.aliasTarget = String(trimmed[match])
            } else {
                self.aliasTarget = nil
            }
        } else {
            self.isAlias = false
            self.aliasTarget = nil
        }
    }

    var description: String {
        // Extract first non-empty line as description
        content.components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespaces) ?? "No description"
    }

    enum CommandSource: String {
        case user = "User Command"
        case skill = "Skill"
        case plugin = "Plugin"

        var icon: String {
            switch self {
            case .user: return "terminal"
            case .skill: return "wand.and.stars"
            case .plugin: return "puzzlepiece.extension"
            }
        }
    }
}

// MARK: - Plugin

struct ClaudePlugin: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let marketplace: String
    let version: String
    let installPath: String
    let installedAt: Date?
    let isEnabled: Bool
    let skills: [String]

    var displayName: String {
        "\(name)@\(marketplace)"
    }
}

// MARK: - Cron Job

struct CronJob: Identifiable, Hashable {
    let id = UUID()
    let schedule: String
    let command: String
    let description: String

    var scheduleDescription: String {
        // Parse cron schedule to human-readable
        let parts = schedule.components(separatedBy: " ")
        guard parts.count >= 5 else { return schedule }

        let minute = parts[0]
        let hour = parts[1]
        let dayOfMonth = parts[2]
        let month = parts[3]
        let dayOfWeek = parts[4]

        if dayOfMonth == "*" && month == "*" && dayOfWeek == "*" {
            return "Daily at \(hour):\(minute.padding(toLength: 2, withPad: "0", startingAt: 0))"
        }
        return schedule
    }
}

// MARK: - Settings

struct ClaudeSettings: Codable {
    let permissions: Permissions?
    let enabledPlugins: [String: Bool]?

    struct Permissions: Codable {
        let defaultMode: String?
        let allow: [String]?
        let deny: [String]?
        let ask: [String]?
    }
}

// MARK: - Full Configuration

struct ClaudeConfiguration {
    var claudeMDFiles: [ClaudeMDFile] = []
    var slashCommands: [SlashCommand] = []
    var plugins: [ClaudePlugin] = []
    var cronJobs: [CronJob] = []
    var settings: ClaudeSettings?
    var localSettings: ClaudeSettings?
    var accountInfo: ClaudeAccountInfo?
    var healthIssues: [HealthIssue] = []
    var suggestion: CustomizationSuggestion?
    var capabilityAnalysis: CapabilityAnalysis?

    var enabledPluginCount: Int {
        settings?.enabledPlugins?.filter { $0.value }.count ?? 0
    }

    var totalCommandCount: Int {
        slashCommands.count
    }

    var commandCount: Int {
        slashCommands.filter { $0.source == .user }.count
    }

    var skillCount: Int {
        slashCommands.filter { $0.source == .skill }.count
    }

    var aliasCount: Int {
        slashCommands.filter { $0.isAlias }.count
    }

    var nonAliasCommandCount: Int {
        slashCommands.filter { !$0.isAlias }.count
    }

    var overallHealth: ConfigHealth {
        if healthIssues.contains(where: { $0.severity == .critical }) {
            return .critical
        } else if healthIssues.contains(where: { $0.severity == .warning }) {
            return .warning
        }
        return .healthy
    }

    var commandsDescription: String {
        let total = totalCommandCount
        let aliases = aliasCount
        if aliases > 0 {
            return "\(total) custom slash commands including \(aliases) alias\(aliases == 1 ? "" : "es")"
        }
        return "\(total) custom slash commands"
    }
}
