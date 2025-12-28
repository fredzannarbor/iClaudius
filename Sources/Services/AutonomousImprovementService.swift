import Foundation

/// Service that manages autonomous improvement of user preferences and control plane
actor AutonomousImprovementService {
    private let stateFilePath: String
    private var state: AutonomousImprovementState

    init() {
        self.stateFilePath = "\(NSHomeDirectory())/.claude/autonomous_improvements.json"
        self.state = AutonomousImprovementState()
        Task {
            await loadState()
        }
    }

    // MARK: - State Management

    func loadState() {
        guard FileManager.default.fileExists(atPath: stateFilePath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: stateFilePath)) else {
            print("[AutonomousImprovement] No existing state, using defaults")
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            state = try decoder.decode(AutonomousImprovementState.self, from: data)
            print("[AutonomousImprovement] Loaded state: \(state.changes.count) changes, enabled=\(state.settings.enabled)")
        } catch {
            print("[AutonomousImprovement] Error loading state: \(error)")
        }
    }

    func saveState() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: URL(fileURLWithPath: stateFilePath))
            print("[AutonomousImprovement] State saved")
        } catch {
            print("[AutonomousImprovement] Error saving state: \(error)")
        }
    }

    // MARK: - Settings

    func getSettings() -> AutonomousImprovementSettings {
        return state.settings
    }

    func updateSettings(_ settings: AutonomousImprovementSettings) {
        var newSettings = settings
        newSettings.lastUpdated = Date()
        state.settings = newSettings
        saveState()
    }

    func isEnabled() -> Bool {
        return state.settings.enabled
    }

    func setEnabled(_ enabled: Bool) {
        state.settings.enabled = enabled
        state.settings.lastUpdated = Date()
        saveState()
    }

    // MARK: - Changes

    func getChanges() -> [AutonomousChange] {
        return state.changes
    }

    func getPendingChanges() -> [AutonomousChange] {
        return state.pendingChanges
    }

    func getRevertedChanges() -> [AutonomousChange] {
        return state.revertedChanges
    }

    func canMakeChange() -> Bool {
        guard state.settings.enabled else { return false }
        return state.changesTodayCount < state.settings.maxChangesPerDay
    }

    /// Record a new autonomous change
    func recordChange(_ change: AutonomousChange) {
        state.changes.insert(change, at: 0)  // Most recent first
        saveState()
        print("[AutonomousImprovement] Recorded change: \(change.changeType.rawValue) - \(change.description)")
    }

    /// Revert a specific change by restoring original content
    func revertChange(id: UUID) async -> Result<Void, Error> {
        guard let change = state.changes.first(where: { $0.id == id }) else {
            return .failure(ImprovementError.changeNotFound)
        }

        guard !change.reverted else {
            return .failure(ImprovementError.alreadyReverted)
        }

        // Restore original content if we have it
        if let originalContent = change.originalContent {
            do {
                try originalContent.write(toFile: change.affectedFile, atomically: true, encoding: .utf8)
                print("[AutonomousImprovement] Reverted file: \(change.affectedFile)")
            } catch {
                return .failure(error)
            }
        } else if change.changeType == .skillCreated || change.changeType == .commandCreated {
            // For created files, delete them
            do {
                try FileManager.default.removeItem(atPath: change.affectedFile)
                print("[AutonomousImprovement] Deleted created file: \(change.affectedFile)")
            } catch {
                return .failure(error)
            }
        }

        // Mark as reverted
        _ = state.revertChange(id: id)
        saveState()
        return .success(())
    }

    /// Revert all changes
    func revertAllChanges() async -> Result<Int, Error> {
        var revertedCount = 0
        var lastError: Error?

        for change in state.pendingChanges {
            let result = await revertChange(id: change.id)
            switch result {
            case .success:
                revertedCount += 1
            case .failure(let error):
                lastError = error
            }
        }

        if let error = lastError, revertedCount == 0 {
            return .failure(error)
        }
        return .success(revertedCount)
    }

    // MARK: - Observations

    func recordObservation(_ observation: UserBehaviorObservation) {
        // Check if we already have a similar observation
        if let index = state.observations.firstIndex(where: {
            $0.observationType == observation.observationType && $0.details == observation.details
        }) {
            // Update frequency - need to recreate since it's a struct
            let existing = state.observations[index]
            let updated = UserBehaviorObservation(
                observationType: existing.observationType,
                details: existing.details,
                frequency: existing.frequency + 1
            )
            state.observations[index] = updated
        } else {
            state.observations.append(observation)
        }
        saveState()
    }

    func getObservations() -> [UserBehaviorObservation] {
        return state.observations
    }

    // MARK: - Autonomous Actions

    /// Create a skill based on observed patterns (requires high confidence)
    func createSkill(name: String, content: String, rationale: String, confidence: Double) async -> Result<AutonomousChange, Error> {
        guard canMakeChange() else {
            return .failure(ImprovementError.dailyLimitReached)
        }

        guard confidence >= state.settings.confidenceThreshold else {
            return .failure(ImprovementError.insufficientConfidence)
        }

        guard state.settings.allowSkillCreation else {
            return .failure(ImprovementError.actionNotAllowed)
        }

        let skillsDir = "\(NSHomeDirectory())/.claude/skills"
        let filePath = "\(skillsDir)/\(name).md"

        // Check if file already exists
        guard !FileManager.default.fileExists(atPath: filePath) else {
            return .failure(ImprovementError.fileAlreadyExists)
        }

        do {
            // Ensure directory exists
            try FileManager.default.createDirectory(atPath: skillsDir, withIntermediateDirectories: true)

            // Write the skill
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)

            // Record the change
            let change = AutonomousChange(
                changeType: .skillCreated,
                description: "Created skill /\(name)",
                rationale: rationale,
                confidence: confidence,
                affectedFile: filePath,
                originalContent: nil,  // No original - new file
                newContent: content
            )
            recordChange(change)

            return .success(change)
        } catch {
            return .failure(error)
        }
    }

    /// Edit a CLAUDE.md or prompt file (requires high confidence)
    func editPrompt(filePath: String, newContent: String, rationale: String, confidence: Double) async -> Result<AutonomousChange, Error> {
        guard canMakeChange() else {
            return .failure(ImprovementError.dailyLimitReached)
        }

        guard confidence >= state.settings.confidenceThreshold else {
            return .failure(ImprovementError.insufficientConfidence)
        }

        guard state.settings.allowPromptEdits else {
            return .failure(ImprovementError.actionNotAllowed)
        }

        do {
            // Read original content for reversion
            let originalContent = try String(contentsOfFile: filePath, encoding: .utf8)

            // Write new content
            try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)

            // Record the change
            let change = AutonomousChange(
                changeType: .promptEdit,
                description: "Modified \(URL(fileURLWithPath: filePath).lastPathComponent)",
                rationale: rationale,
                confidence: confidence,
                affectedFile: filePath,
                originalContent: originalContent,
                newContent: newContent
            )
            recordChange(change)

            return .success(change)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Error Types

    enum ImprovementError: Error, LocalizedError {
        case changeNotFound
        case alreadyReverted
        case dailyLimitReached
        case insufficientConfidence
        case actionNotAllowed
        case fileAlreadyExists

        var errorDescription: String? {
            switch self {
            case .changeNotFound: return "Change not found"
            case .alreadyReverted: return "Change was already reverted"
            case .dailyLimitReached: return "Daily change limit reached"
            case .insufficientConfidence: return "Confidence below threshold"
            case .actionNotAllowed: return "This action type is not allowed"
            case .fileAlreadyExists: return "File already exists"
            }
        }
    }
}
