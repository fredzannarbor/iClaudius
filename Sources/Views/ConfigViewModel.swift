import SwiftUI

@MainActor
class ConfigViewModel: ObservableObject {
    @Published var config = ClaudeConfiguration()
    @Published var cpConfig = ControlPlaneConfiguration()
    @Published var selectedSection: NavSection = .overview
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?

    // Autonomous Improvement
    @Published var autonomousSettings = AutonomousImprovementSettings()
    @Published var autonomousChanges: [AutonomousChange] = []

    private let scanner = ConfigScanner()
    private let cpScanner = ControlPlaneScanner()
    private let improvementService = AutonomousImprovementService()

    func load() async {
        // Small delay to ensure view has finished initial render
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Set loading state on main thread
        await MainActor.run {
            isLoading = true
            error = nil
        }

        // Fetch data from scanners (off main thread work happens inside actors)
        let newConfig = await scanner.scanAll()
        let newCpConfig = await cpScanner.scanControlPlane(baseConfig: newConfig)

        // Load autonomous improvement state
        let aiSettings = await improvementService.getSettings()
        let aiChanges = await improvementService.getChanges()

        // Update on main thread after a brief yield
        await MainActor.run {
            self.config = newConfig
            self.cpConfig = newCpConfig
            self.autonomousSettings = aiSettings
            self.autonomousChanges = aiChanges
            self.isLoading = false
        }
    }

    func refresh() async {
        await load()
    }

    // MARK: - Cron Job CRUD

    func addCronJob(schedule: String, command: String) async {
        do {
            try await scanner.addCronJob(schedule: schedule, command: command)
            successMessage = "Cron job added successfully"
            await refresh()
        } catch {
            self.error = "Failed to add cron job: \(error.localizedDescription)"
        }
    }

    func deleteCronJob(at index: Int) async {
        do {
            try await scanner.deleteCronJob(at: index)
            successMessage = "Cron job deleted"
            await refresh()
        } catch {
            self.error = "Failed to delete cron job: \(error.localizedDescription)"
        }
    }

    func updateCronJob(at index: Int, schedule: String, command: String) async {
        do {
            try await scanner.updateCronJob(at: index, schedule: schedule, command: command)
            successMessage = "Cron job updated"
            await refresh()
        } catch {
            self.error = "Failed to update cron job: \(error.localizedDescription)"
        }
    }

    func clearMessages() {
        error = nil
        successMessage = nil
    }

    // MARK: - Command/Skill Creation

    func createCommand(name: String, content: String, isSkill: Bool = false) async {
        let directory = isSkill
            ? "\(NSHomeDirectory())/.claude/skills"
            : "\(NSHomeDirectory())/.claude/commands"

        let path = "\(directory)/\(name).md"

        do {
            // Ensure directory exists
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

            // Write the file
            try content.write(toFile: path, atomically: true, encoding: .utf8)

            successMessage = "\(isSkill ? "Skill" : "Command") /\(name) created successfully"
            await refresh()
        } catch {
            self.error = "Failed to create \(isSkill ? "skill" : "command"): \(error.localizedDescription)"
        }
    }

    // MARK: - Autonomous Improvement

    func loadAutonomousState() async {
        let settings = await improvementService.getSettings()
        let changes = await improvementService.getChanges()

        await MainActor.run {
            self.autonomousSettings = settings
            self.autonomousChanges = changes
        }
    }

    func toggleAutonomousImprovement(_ enabled: Bool) async {
        await improvementService.setEnabled(enabled)
        autonomousSettings.enabled = enabled
    }

    func updateAutonomousSettings(_ settings: AutonomousImprovementSettings) async {
        await improvementService.updateSettings(settings)
        autonomousSettings = settings
    }

    func revertAutonomousChange(id: UUID) async {
        let result = await improvementService.revertChange(id: id)
        switch result {
        case .success:
            successMessage = "Change reverted successfully"
            await loadAutonomousState()
            await refresh()
        case .failure(let error):
            self.error = "Failed to revert: \(error.localizedDescription)"
        }
    }

    func revertAllAutonomousChanges() async {
        let result = await improvementService.revertAllChanges()
        switch result {
        case .success(let count):
            successMessage = "Reverted \(count) change\(count == 1 ? "" : "s")"
            await loadAutonomousState()
            await refresh()
        case .failure(let error):
            self.error = "Failed to revert all: \(error.localizedDescription)"
        }
    }
}
