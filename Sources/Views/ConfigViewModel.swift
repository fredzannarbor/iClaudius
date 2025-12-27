import SwiftUI

@MainActor
class ConfigViewModel: ObservableObject {
    @Published var config = ClaudeConfiguration()
    @Published var selectedSection: NavSection = .overview
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?

    private let scanner = ConfigScanner()

    func load() async {
        isLoading = true
        error = nil
        config = await scanner.scanAll()
        isLoading = false
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
}
