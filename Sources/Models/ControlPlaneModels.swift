import Foundation

// MARK: - Control Plane Layer Model

/// The four-layer Control Plane architecture for understanding Claude's configuration
enum ControlPlaneLayer: String, CaseIterable {
    case context = "Context Layer"
    case capability = "Capability Layer"
    case behavior = "Behavior Layer"
    case orchestration = "Orchestration Layer"

    var icon: String {
        switch self {
        case .context: return "doc.text.fill"
        case .capability: return "wrench.and.screwdriver.fill"
        case .behavior: return "play.circle.fill"
        case .orchestration: return "clock.arrow.2.circlepath"
        }
    }

    var color: String {
        switch self {
        case .context: return "blue"
        case .capability: return "purple"
        case .behavior: return "green"
        case .orchestration: return "orange"
        }
    }

    var description: String {
        switch self {
        case .context:
            return "What Claude knows: CLAUDE.md files, conversation history, project context"
        case .capability:
            return "What Claude can do: MCP servers, plugins, allowed tools, permissions"
        case .behavior:
            return "How Claude acts: Commands, skills, hooks, agent definitions"
        case .orchestration:
            return "When Claude acts: Cron jobs, agent queues, event triggers"
        }
    }
}

// MARK: - Control Entity

/// Unified representation of any entity that controls Claude's behavior
struct ControlEntity: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: ControlEntityType
    let layer: ControlPlaneLayer
    let path: String?
    let content: String?
    let dependencies: [String]
    let lastModified: Date?
    let health: EntityHealth

    enum ControlEntityType: String, CaseIterable {
        // Context Layer
        case claudeMD = "CLAUDE.md"
        case memoryFile = "Memory File"

        // Capability Layer
        case mcpServer = "MCP Server"
        case plugin = "Plugin"
        case permission = "Permission"

        // Behavior Layer
        case command = "Command"
        case skill = "Skill"
        case hook = "Hook"
        case agent = "Agent"

        // Orchestration Layer
        case cronJob = "Cron Job"
        case agentQueue = "Agent Queue"
        case eventTrigger = "Event Trigger"

        var icon: String {
            switch self {
            case .claudeMD: return "doc.text"
            case .memoryFile: return "brain"
            case .mcpServer: return "server.rack"
            case .plugin: return "puzzlepiece.extension"
            case .permission: return "lock.shield"
            case .command: return "terminal"
            case .skill: return "wand.and.stars"
            case .hook: return "link"
            case .agent: return "person.badge.clock"
            case .cronJob: return "clock"
            case .agentQueue: return "list.bullet.clipboard"
            case .eventTrigger: return "bolt"
            }
        }

        var layer: ControlPlaneLayer {
            switch self {
            case .claudeMD, .memoryFile: return .context
            case .mcpServer, .plugin, .permission: return .capability
            case .command, .skill, .hook, .agent: return .behavior
            case .cronJob, .agentQueue, .eventTrigger: return .orchestration
            }
        }
    }

    enum EntityHealth: String {
        case healthy = "Healthy"
        case warning = "Warning"
        case error = "Error"
        case unknown = "Unknown"

        var color: String {
            switch self {
            case .healthy: return "green"
            case .warning: return "yellow"
            case .error: return "red"
            case .unknown: return "gray"
            }
        }

        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }
}

// MARK: - Execution Trace

/// Records a single execution of a command or interaction
struct ExecutionTrace: Identifiable {
    let id = UUID()
    let timestamp: Date
    let commandName: String
    let sessionId: String
    let status: ExecutionStatus
    let duration: TimeInterval
    let tokensUsed: Int?
    let toolCalls: [String]
    let errorMessage: String?

    enum ExecutionStatus: String {
        case success = "Success"
        case failure = "Failure"
        case timeout = "Timeout"
        case cancelled = "Cancelled"

        var color: String {
            switch self {
            case .success: return "green"
            case .failure: return "red"
            case .timeout: return "orange"
            case .cancelled: return "gray"
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle"
            case .failure: return "xmark.circle"
            case .timeout: return "clock.badge.exclamationmark"
            case .cancelled: return "stop.circle"
            }
        }
    }
}

/// Aggregated session information
struct SessionInfo: Identifiable {
    let id: String
    let startTime: Date
    let endTime: Date?
    let messageCount: Int
    let toolCallCount: Int
    let commandsUsed: [String]
    let status: SessionStatus

    enum SessionStatus: String {
        case active = "Active"
        case completed = "Completed"
        case crashed = "Crashed"

        var color: String {
            switch self {
            case .active: return "blue"
            case .completed: return "green"
            case .crashed: return "red"
            }
        }
    }
}

// MARK: - Dependency Graph

/// Represents a dependency relationship between entities
struct Dependency: Identifiable {
    let id = UUID()
    let source: String
    let target: String
    let type: DependencyType
    let strength: DependencyStrength

    enum DependencyType: String {
        case imports = "Imports"
        case references = "References"
        case triggers = "Triggers"
        case requires = "Requires"
        case conflicts = "Conflicts"
    }

    enum DependencyStrength: String {
        case hard = "Hard"       // Failure if missing
        case soft = "Soft"       // Degraded if missing
        case optional = "Optional"
    }
}

/// A detected conflict between entities
struct Conflict: Identifiable {
    let id = UUID()
    let entities: [String]
    let type: ConflictType
    let severity: ConflictSeverity
    let description: String
    let resolution: String?

    enum ConflictType: String {
        case nameCollision = "Name Collision"
        case contradictoryInstructions = "Contradictory Instructions"
        case permissionConflict = "Permission Conflict"
        case resourceContention = "Resource Contention"
    }

    enum ConflictSeverity: String {
        case critical = "Critical"
        case warning = "Warning"
        case info = "Info"

        var color: String {
            switch self {
            case .critical: return "red"
            case .warning: return "orange"
            case .info: return "blue"
            }
        }
    }
}

// MARK: - Permission Surface

/// Represents the full permission surface of Claude's configuration
struct PermissionSurface {
    let totalPermissions: Int
    let allowedCommands: [PermissionEntry]
    let deniedCommands: [PermissionEntry]
    let sensitiveOperations: [SensitiveOperation]
    let recommendations: [PermissionRecommendation]

    var riskLevel: RiskLevel {
        let sensitiveCount = sensitiveOperations.count
        let highRiskCount = sensitiveOperations.filter { $0.risk == .high }.count

        if highRiskCount > 5 || sensitiveCount > 20 {
            return .high
        } else if highRiskCount > 2 || sensitiveCount > 10 {
            return .medium
        }
        return .low
    }

    enum RiskLevel: String {
        case low = "Low Risk"
        case medium = "Medium Risk"
        case high = "High Risk"

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "red"
            }
        }

        var icon: String {
            switch self {
            case .low: return "shield.checkered"
            case .medium: return "shield.lefthalf.filled"
            case .high: return "exclamationmark.shield"
            }
        }
    }
}

struct PermissionEntry: Identifiable {
    let id = UUID()
    let pattern: String
    let source: String // Which settings file
    let grantedAt: Date?
}

struct SensitiveOperation: Identifiable {
    let id = UUID()
    let operation: String
    let risk: RiskLevel
    let description: String
    let mitigation: String?

    enum RiskLevel: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "red"
            }
        }
    }
}

struct PermissionRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    let action: String

    enum Priority: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: String {
            switch self {
            case .high: return "red"
            case .medium: return "orange"
            case .low: return "blue"
            }
        }
    }
}

// MARK: - Safety Dashboard

struct SafetyDashboard {
    let overallStatus: SafetyStatus
    let permissionSurface: PermissionSurface
    let autonomousLoops: [AutonomousLoop]
    let recentRiskyOperations: [RiskyOperation]
    let safetyScore: Int // 0-100

    enum SafetyStatus: String {
        case secure = "Secure"
        case caution = "Caution"
        case alert = "Alert"

        var color: String {
            switch self {
            case .secure: return "green"
            case .caution: return "yellow"
            case .alert: return "red"
            }
        }

        var icon: String {
            switch self {
            case .secure: return "lock.shield.fill"
            case .caution: return "exclamationmark.shield.fill"
            case .alert: return "xmark.shield.fill"
            }
        }
    }
}

struct AutonomousLoop: Identifiable {
    let id = UUID()
    let name: String
    let type: LoopType
    let frequency: String
    let lastRun: Date?
    let isActive: Bool
    let entities: [String] // Which entities participate in the loop

    enum LoopType: String {
        case cronTriggered = "Cron Triggered"
        case agentQueue = "Agent Queue"
        case eventDriven = "Event Driven"
        case selfInvoking = "Self Invoking"

        var icon: String {
            switch self {
            case .cronTriggered: return "clock.arrow.circlepath"
            case .agentQueue: return "list.bullet.clipboard"
            case .eventDriven: return "bolt.circle"
            case .selfInvoking: return "arrow.triangle.2.circlepath"
            }
        }

        var riskLevel: String {
            switch self {
            case .cronTriggered, .agentQueue: return "low"
            case .eventDriven: return "medium"
            case .selfInvoking: return "high"
            }
        }
    }
}

struct RiskyOperation: Identifiable {
    let id = UUID()
    let timestamp: Date
    let operation: String
    let command: String
    let outcome: String
    let riskLevel: String
}

// MARK: - Prompt Archaeology

/// Version history for a CLAUDE.md file
struct PromptVersion: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let version: Int
    let timestamp: Date
    let content: String
    let changeType: ChangeType
    let summary: String?

    enum ChangeType: String, Hashable {
        case created = "Created"
        case modified = "Modified"
        case majorRewrite = "Major Rewrite"
        case deleted = "Deleted"

        var icon: String {
            switch self {
            case .created: return "plus.circle"
            case .modified: return "pencil.circle"
            case .majorRewrite: return "arrow.triangle.2.circlepath.circle"
            case .deleted: return "trash.circle"
            }
        }

        var color: String {
            switch self {
            case .created: return "green"
            case .modified: return "blue"
            case .majorRewrite: return "purple"
            case .deleted: return "red"
            }
        }
    }
}

/// A diff between two versions
struct PromptDiff: Identifiable {
    let id = UUID()
    let oldVersion: Int
    let newVersion: Int
    let additions: Int
    let deletions: Int
    let changes: [DiffChunk]

    struct DiffChunk: Identifiable {
        let id = UUID()
        let type: ChunkType
        let content: String
        let lineNumber: Int

        enum ChunkType {
            case added
            case removed
            case context
        }
    }
}

// MARK: - Capability Coverage Map

/// Shows which domains Claude's capabilities cover
struct CapabilityCoverage {
    let domains: [CoverageDomain]
    let baseCapabilities: [String]
    let extendedCapabilities: [String]
    let gapAnalysis: [CapabilityGap]

    var extensionRatio: Double {
        let total = baseCapabilities.count + extendedCapabilities.count
        guard total > 0 else { return 0 }
        return Double(extendedCapabilities.count) / Double(total)
    }
}

struct CoverageDomain: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: String
    let coverage: Double // 0.0 to 1.0
    let capabilities: [String]
    let isExtended: Bool
}

struct CapabilityGap: Identifiable {
    let id = UUID()
    let domain: String
    let missingCapability: String
    let suggestion: String
    let difficulty: Difficulty

    enum Difficulty: String {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"

        var color: String {
            switch self {
            case .easy: return "green"
            case .medium: return "yellow"
            case .hard: return "red"
            }
        }
    }
}

// MARK: - Interaction Graph

/// Node in the interaction graph
struct InteractionNode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: ControlEntity.ControlEntityType
    let layer: ControlPlaneLayer

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InteractionNode, rhs: InteractionNode) -> Bool {
        lhs.id == rhs.id
    }
}

/// Edge in the interaction graph
struct InteractionEdge: Identifiable {
    let id = UUID()
    let source: InteractionNode
    let target: InteractionNode
    let relationship: Dependency.DependencyType
    let weight: Double
}

/// The full interaction graph
struct InteractionGraph {
    let nodes: [InteractionNode]
    let edges: [InteractionEdge]

    var density: Double {
        let maxEdges = nodes.count * (nodes.count - 1)
        guard maxEdges > 0 else { return 0 }
        return Double(edges.count) / Double(maxEdges)
    }

    var clusters: [[InteractionNode]] {
        // Group nodes by layer for visualization
        var layerGroups: [ControlPlaneLayer: [InteractionNode]] = [:]
        for node in nodes {
            layerGroups[node.layer, default: []].append(node)
        }
        return Array(layerGroups.values)
    }
}

// MARK: - Runtime State

/// Current runtime state of Claude
struct RuntimeState {
    let isActive: Bool
    let currentSession: SessionInfo?
    let recentCommands: [String]
    let activeHooks: [String]
    let loadedPlugins: [String]
    let memoryUsage: MemoryUsage?
    let lastActivity: Date?

    struct MemoryUsage {
        let contextTokens: Int
        let maxTokens: Int
        let percentUsed: Double
    }
}

// MARK: - Full Control Plane Configuration

/// Complete Control Plane configuration
struct ControlPlaneConfiguration {
    var entities: [ControlEntity] = []
    var dependencies: [Dependency] = []
    var conflicts: [Conflict] = []
    var executionTraces: [ExecutionTrace] = []
    var sessions: [SessionInfo] = []
    var permissionSurface: PermissionSurface?
    var safetyDashboard: SafetyDashboard?
    var promptVersions: [PromptVersion] = []
    var capabilityCoverage: CapabilityCoverage?
    var interactionGraph: InteractionGraph?
    var runtimeState: RuntimeState?

    // Layer summaries
    var contextEntities: [ControlEntity] {
        entities.filter { $0.layer == .context }
    }

    var capabilityEntities: [ControlEntity] {
        entities.filter { $0.layer == .capability }
    }

    var behaviorEntities: [ControlEntity] {
        entities.filter { $0.layer == .behavior }
    }

    var orchestrationEntities: [ControlEntity] {
        entities.filter { $0.layer == .orchestration }
    }

    var overallHealth: ControlEntity.EntityHealth {
        let hasErrors = entities.contains { $0.health == .error }
        let hasWarnings = entities.contains { $0.health == .warning }

        if hasErrors { return .error }
        if hasWarnings { return .warning }
        return .healthy
    }

    var conflictCount: Int {
        conflicts.count
    }

    var autonomousLoopCount: Int {
        safetyDashboard?.autonomousLoops.count ?? 0
    }
}

// MARK: - Autonomous Improvement System

/// Tracks settings for autonomous improvement feature
struct AutonomousImprovementSettings: Codable {
    var enabled: Bool = false
    var confidenceThreshold: Double = 0.85  // Only make changes with >= 85% confidence
    var allowPromptEdits: Bool = true
    var allowSkillCreation: Bool = true
    var allowCommandCreation: Bool = true
    var requireApprovalForMajorChanges: Bool = true
    var maxChangesPerDay: Int = 5
    var lastUpdated: Date = Date()
}

/// Represents a single autonomous change made by Claude
struct AutonomousChange: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let changeType: ChangeType
    let description: String
    let rationale: String
    let confidence: Double  // 0.0 to 1.0
    let affectedFile: String
    let originalContent: String?  // For reversion
    let newContent: String?
    var reverted: Bool = false
    var revertedAt: Date?

    enum ChangeType: String, Codable, CaseIterable {
        case promptEdit = "Prompt Edit"
        case skillCreated = "Skill Created"
        case commandCreated = "Command Created"
        case settingModified = "Setting Modified"
        case hookAdded = "Hook Added"

        var icon: String {
            switch self {
            case .promptEdit: return "doc.text.fill"
            case .skillCreated: return "wand.and.stars"
            case .commandCreated: return "terminal.fill"
            case .settingModified: return "gearshape.fill"
            case .hookAdded: return "arrow.triangle.branch"
            }
        }

        var color: String {
            switch self {
            case .promptEdit: return "blue"
            case .skillCreated: return "purple"
            case .commandCreated: return "green"
            case .settingModified: return "orange"
            case .hookAdded: return "teal"
            }
        }
    }

    init(changeType: ChangeType, description: String, rationale: String,
         confidence: Double, affectedFile: String,
         originalContent: String?, newContent: String?) {
        self.id = UUID()
        self.timestamp = Date()
        self.changeType = changeType
        self.description = description
        self.rationale = rationale
        self.confidence = confidence
        self.affectedFile = affectedFile
        self.originalContent = originalContent
        self.newContent = newContent
    }
}

/// Observation about user behavior that might inform improvements
struct UserBehaviorObservation: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let observationType: ObservationType
    let details: String
    let frequency: Int  // How often this pattern was observed

    enum ObservationType: String, Codable {
        case repeatedCommand = "Repeated Command Pattern"
        case errorPattern = "Common Error Pattern"
        case workflowGap = "Workflow Gap"
        case preferenceSignal = "Preference Signal"
        case efficiencyOpportunity = "Efficiency Opportunity"
    }

    init(observationType: ObservationType, details: String, frequency: Int = 1) {
        self.id = UUID()
        self.timestamp = Date()
        self.observationType = observationType
        self.details = details
        self.frequency = frequency
    }
}

/// Container for all autonomous improvement data
struct AutonomousImprovementState: Codable {
    var settings: AutonomousImprovementSettings = AutonomousImprovementSettings()
    var changes: [AutonomousChange] = []
    var observations: [UserBehaviorObservation] = []
    var changesTodayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return changes.filter {
            !$0.reverted && Calendar.current.startOfDay(for: $0.timestamp) == today
        }.count
    }

    var pendingChanges: [AutonomousChange] {
        changes.filter { !$0.reverted }
    }

    var revertedChanges: [AutonomousChange] {
        changes.filter { $0.reverted }
    }

    mutating func revertChange(id: UUID) -> Bool {
        guard let index = changes.firstIndex(where: { $0.id == id }) else {
            return false
        }
        changes[index].reverted = true
        changes[index].revertedAt = Date()
        return true
    }

    mutating func revertAllChanges() {
        for i in changes.indices {
            if !changes[i].reverted {
                changes[i].reverted = true
                changes[i].revertedAt = Date()
            }
        }
    }
}
