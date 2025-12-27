import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ConfigViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            DetailView(viewModel: viewModel)
        }
        .navigationTitle("iClaudius")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await viewModel.refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh configuration")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @ObservedObject var viewModel: ConfigViewModel

    var body: some View {
        List(selection: $viewModel.selectedSection) {
            Section("Configuration") {
                NavigationLink(value: NavSection.overview) {
                    Label("Overview", systemImage: "square.grid.2x2")
                }

                NavigationLink(value: NavSection.claudeMD) {
                    Label("CLAUDE.md Files", systemImage: "doc.text")
                }
                .badge(viewModel.config.claudeMDFiles.count)
            }

            Section("Commands & Skills") {
                NavigationLink(value: NavSection.commands) {
                    Label("Custom Slash Commands", systemImage: "terminal")
                }
                .badge(viewModel.config.totalCommandCount)
            }

            Section("Extensions") {
                NavigationLink(value: NavSection.plugins) {
                    Label("Plugins", systemImage: "puzzlepiece.extension")
                }
                .badge(viewModel.config.plugins.count)
            }

            Section("Automation") {
                NavigationLink(value: NavSection.cron) {
                    Label("Scheduled Jobs", systemImage: "clock")
                }
                .badge(viewModel.config.cronJobs.count)
            }

            Section("Settings") {
                NavigationLink(value: NavSection.permissions) {
                    Label("Permissions", systemImage: "lock.shield")
                }

                NavigationLink(value: NavSection.account) {
                    Label("Account Info", systemImage: "person.circle")
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}

// MARK: - Detail View

struct DetailView: View {
    @ObservedObject var viewModel: ConfigViewModel

    var body: some View {
        Group {
            switch viewModel.selectedSection {
            case .overview:
                OverviewView(viewModel: viewModel)
            case .claudeMD:
                ClaudeMDListView(files: viewModel.config.claudeMDFiles)
            case .commands:
                CommandsListView(commands: viewModel.config.slashCommands, aliasCount: viewModel.config.aliasCount)
            case .plugins:
                PluginsListView(plugins: viewModel.config.plugins)
            case .cron:
                CronJobsListView(jobs: viewModel.config.cronJobs, viewModel: viewModel)
            case .permissions:
                PermissionsView(settings: viewModel.config.settings, localSettings: viewModel.config.localSettings)
            case .account:
                AccountInfoView(accountInfo: viewModel.config.accountInfo)
            }
        }
        .frame(minWidth: 500)
    }
}

// MARK: - Health Alert Bar

struct HealthAlertBar: View {
    let health: ConfigHealth
    let issues: [HealthIssue]
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: health.icon)
                        .foregroundColor(healthColor)
                    Text(health.rawValue)
                        .fontWeight(.medium)

                    if !issues.isEmpty {
                        Text("(\(issues.count) issue\(issues.count == 1 ? "" : "s"))")
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !issues.isEmpty {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(healthColor.opacity(0.15))
            }
            .buttonStyle(.plain)

            if isExpanded && !issues.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(issues) { issue in
                        HStack(alignment: .top) {
                            Image(systemName: issue.severity.icon)
                                .foregroundColor(colorFor(issue.severity))
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.message)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let detail = issue.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
            }
        }
        .cornerRadius(8)
    }

    var healthColor: Color {
        switch health {
        case .healthy: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    func colorFor(_ health: ConfigHealth) -> Color {
        switch health {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: CustomizationSuggestion
    let onDismiss: () -> Void

    var categoryColor: Color {
        switch suggestion.category {
        case .command: return .green
        case .plugin: return .purple
        case .automation: return .orange
        case .optimization: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Suggestion")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: suggestion.category.icon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.title)
                        .font(.headline)

                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Text(suggestion.category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryColor.opacity(0.2))
                            .cornerRadius(4)

                        Spacer()

                        if let path = suggestion.actionPath {
                            Button(suggestion.actionLabel) {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Overview

struct OverviewView: View {
    @ObservedObject var viewModel: ConfigViewModel
    @State private var showSuggestion = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Health Alert Bar at top
                HealthAlertBar(
                    health: viewModel.config.overallHealth,
                    issues: viewModel.config.healthIssues
                )

                // Suggestion Popup (dismissable)
                if showSuggestion, let suggestion = viewModel.config.suggestion {
                    SuggestionCard(suggestion: suggestion) {
                        withAnimation {
                            showSuggestion = false
                        }
                    }
                }

                // Config Hierarchy (moved to top)
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configuration Hierarchy")
                            .font(.headline)
                            .padding(.bottom, 4)

                        ForEach(viewModel.config.claudeMDFiles.sorted { $0.level.priority < $1.level.priority }) { file in
                            HierarchyRow(file: file)
                                .onTapGesture {
                                    viewModel.selectedSection = .claudeMD
                                }
                        }

                        if viewModel.config.claudeMDFiles.isEmpty {
                            Text("No CLAUDE.md files found")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Account info summary
                if let account = viewModel.config.accountInfo {
                    GroupBox {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.username)
                                    .font(.headline)
                                Text(account.cliVersion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(formatNumber(account.totalMessages)) messages")
                                    .font(.caption)
                                Text("\(formatNumber(account.totalToolCalls)) tool calls")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedSection = .account
                    }
                }

                // Stats Grid - Clickable cards
                Text("Quick Stats")
                    .font(.headline)
                    .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
                    ClickableStatCard(
                        title: "CLAUDE.md Files",
                        value: "\(viewModel.config.claudeMDFiles.count)",
                        icon: "doc.text",
                        color: .blue
                    ) {
                        viewModel.selectedSection = .claudeMD
                    }

                    ClickableStatCard(
                        title: "Custom Slash Commands",
                        value: "\(viewModel.config.totalCommandCount)",
                        subtitle: viewModel.config.aliasCount > 0 ? "incl. \(viewModel.config.aliasCount) aliases" : nil,
                        icon: "terminal",
                        color: .green
                    ) {
                        viewModel.selectedSection = .commands
                    }

                    ClickableStatCard(
                        title: "Plugins",
                        value: "\(viewModel.config.plugins.count)",
                        subtitle: "\(viewModel.config.enabledPluginCount) enabled",
                        icon: "puzzlepiece.extension",
                        color: .purple
                    ) {
                        viewModel.selectedSection = .plugins
                    }

                    ClickableStatCard(
                        title: "Cron Jobs",
                        value: "\(viewModel.config.cronJobs.count)",
                        icon: "clock",
                        color: .orange
                    ) {
                        viewModel.selectedSection = .cron
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000.0)
        }
        return "\(num)"
    }
}

// MARK: - Clickable Stat Card

struct ClickableStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HierarchyRow: View {
    let file: ClaudeMDFile

    var body: some View {
        HStack {
            Image(systemName: file.level.icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(file.level.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(file.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(file.lineCount) lines")
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Account Info View

struct AccountInfoView: View {
    let accountInfo: ClaudeAccountInfo?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Account Information")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let info = accountInfo {
                    GroupBox("User") {
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(label: "Username", value: info.username)
                            InfoRow(label: "Claude CLI Version", value: info.cliVersion)
                            InfoRow(label: "Home Directory", value: info.homeDirectory)
                            InfoRow(label: "Claude Directory", value: info.claudeDirectory)
                        }
                        .padding()
                    }

                    GroupBox("Usage Statistics") {
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(label: "Total Messages", value: "\(info.totalMessages.formatted())")
                            InfoRow(label: "Total Sessions", value: "\(info.totalSessions.formatted())")
                            InfoRow(label: "Total Tool Calls", value: "\(info.totalToolCalls.formatted())")
                            if let lastActive = info.lastActiveDate {
                                InfoRow(label: "Stats Last Computed", value: lastActive)
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("No account information available")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
    }
}

// MARK: - CLAUDE.md List

struct ClaudeMDListView: View {
    let files: [ClaudeMDFile]
    @State private var selectedFile: ClaudeMDFile?

    var body: some View {
        HSplitView {
            List(files.sorted { $0.level.priority < $1.level.priority }, selection: $selectedFile) { file in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: file.level.icon)
                            .foregroundColor(.accentColor)
                        Text(file.level.rawValue)
                            .font(.headline)
                    }
                    Text(file.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let date = file.lastModified {
                        Text("Modified: \(date.formatted())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .tag(file)
            }
            .frame(minWidth: 300)

            if let file = selectedFile {
                ScrollView {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(file.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                .font(.headline)
                            Spacer()
                            Button("Open in Finder") {
                                NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: file.directory)
                            }
                            Button("Edit") {
                                NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
                            }
                        }
                        .padding(.bottom)

                        Text(file.content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding()
                }
            } else {
                Text("Select a file to view its contents")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Commands List

struct CommandsListView: View {
    let commands: [SlashCommand]
    let aliasCount: Int
    @State private var selectedCommand: SlashCommand?
    @State private var searchText = ""

    var filteredCommands: [SlashCommand] {
        if searchText.isEmpty {
            return commands
        }
        return commands.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                // Header with count
                HStack {
                    Text("\(commands.count) custom slash commands")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if aliasCount > 0 {
                        Text("incl. \(aliasCount) alias\(aliasCount == 1 ? "" : "es")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                TextField("Search commands...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                List(filteredCommands, selection: $selectedCommand) { cmd in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: cmd.source.icon)
                                .foregroundColor(.accentColor)
                            Text("/\(cmd.name)")
                                .font(.headline)
                                .fontDesign(.monospaced)
                            if cmd.isAlias {
                                Text("alias")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        Text(cmd.source.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .tag(cmd)
                }
            }
            .frame(minWidth: 250)

            if let cmd = selectedCommand {
                ScrollView {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("/\(cmd.name)")
                                .font(.title)
                                .fontDesign(.monospaced)
                            if cmd.isAlias {
                                Text("ALIAS")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            Spacer()
                            Button("Open File") {
                                NSWorkspace.shared.selectFile(cmd.path, inFileViewerRootedAtPath: (cmd.path as NSString).deletingLastPathComponent)
                            }
                            Button("Edit") {
                                NSWorkspace.shared.open(URL(fileURLWithPath: cmd.path))
                            }
                        }

                        HStack {
                            Text(cmd.source.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let target = cmd.aliasTarget {
                                Text("→ \(target)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom)

                        Divider()

                        Text(cmd.content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding()
                }
            } else {
                Text("Select a command to view details")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Plugins List

struct PluginsListView: View {
    let plugins: [ClaudePlugin]

    var body: some View {
        List(plugins) { plugin in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plugin.name)
                            .font(.headline)
                        if plugin.isEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    Text("@\(plugin.marketplace)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("v\(plugin.version)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let date = plugin.installedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Cron Jobs List

struct CronJobsListView: View {
    let jobs: [CronJob]
    @ObservedObject var viewModel: ConfigViewModel
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var editingIndex: Int?
    @State private var editSchedule = ""
    @State private var editCommand = ""
    @State private var showingDeleteConfirm = false
    @State private var deleteIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("\(jobs.count) scheduled job\(jobs.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Label("Add Job", systemImage: "plus")
                }
            }
            .padding()

            // Messages
            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") { viewModel.clearMessages() }
                        .font(.caption)
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }

            if let success = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(success)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") { viewModel.clearMessages() }
                        .font(.caption)
                }
                .padding()
                .background(Color.green.opacity(0.1))
            }

            // Jobs list
            List {
                ForEach(Array(jobs.enumerated()), id: \.element.id) { index, job in
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                Text(job.scheduleDescription)
                                    .font(.headline)
                            }

                            Text(job.command)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(2)

                            Text(job.description)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        // Edit button
                        Button(action: {
                            editingIndex = index
                            let parts = job.schedule.components(separatedBy: " ")
                            editSchedule = parts.prefix(5).joined(separator: " ")
                            editCommand = job.command
                            showingEditSheet = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)

                        // Delete button
                        Button(action: {
                            deleteIndex = index
                            showingDeleteConfirm = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 8)
                }
            }

            if jobs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No scheduled jobs")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a cron job to automate tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Add First Job") { showingAddSheet = true }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CronJobEditorSheet(
                title: "Add Cron Job",
                schedule: "",
                command: "",
                onSave: { schedule, command in
                    Task { await viewModel.addCronJob(schedule: schedule, command: command) }
                }
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            CronJobEditorSheet(
                title: "Edit Cron Job",
                schedule: editSchedule,
                command: editCommand,
                onSave: { schedule, command in
                    if let index = editingIndex {
                        Task { await viewModel.updateCronJob(at: index, schedule: schedule, command: command) }
                    }
                }
            )
        }
        .alert("Delete Cron Job?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = deleteIndex {
                    Task { await viewModel.deleteCronJob(at: index) }
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct CronJobEditorSheet: View {
    let title: String
    @State var schedule: String
    @State var command: String
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)

            GroupBox("Schedule (cron format)") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("* * * * *", text: $schedule)
                        .textFieldStyle(.roundedBorder)
                        .fontDesign(.monospaced)

                    Text("Format: minute hour day month weekday")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        SchedulePreset(label: "Daily 9am", value: "0 9 * * *", schedule: $schedule)
                        SchedulePreset(label: "Hourly", value: "0 * * * *", schedule: $schedule)
                        SchedulePreset(label: "Weekly", value: "0 9 * * 1", schedule: $schedule)
                    }
                }
                .padding()
            }

            GroupBox("Command") {
                TextField("Command to run", text: $command, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .fontDesign(.monospaced)
                    .lineLimit(3...6)
                    .padding()
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)

                Spacer()

                Button("Save") {
                    onSave(schedule, command)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(schedule.isEmpty || command.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
    }
}

struct SchedulePreset: View {
    let label: String
    let value: String
    @Binding var schedule: String

    var body: some View {
        Button(label) {
            schedule = value
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// MARK: - Permissions View

struct PermissionsView: View {
    let settings: ClaudeSettings?
    let localSettings: ClaudeSettings?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Permissions & Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let perms = settings?.permissions {
                    GroupBox("Global Settings (settings.json)") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let mode = perms.defaultMode {
                                Label("Default Mode: \(mode)", systemImage: "gearshape")
                            }
                        }
                        .padding()
                    }
                }

                if let enabled = settings?.enabledPlugins {
                    GroupBox("Enabled Plugins") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(enabled.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Image(systemName: enabled[key] == true ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(enabled[key] == true ? .green : .gray)
                                    Text(key)
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .padding()
                    }
                }

                if let localPerms = localSettings?.permissions {
                    GroupBox("Local Settings (settings.local.json)") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let allow = localPerms.allow, !allow.isEmpty {
                                Text("Allowed Commands (\(allow.count))")
                                    .font(.headline)
                                ForEach(allow.prefix(10), id: \.self) { cmd in
                                    Text(cmd)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                                if allow.count > 10 {
                                    Text("... and \(allow.count - 10) more")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - NavSection Enum

enum NavSection: Hashable {
    case overview
    case claudeMD
    case commands
    case plugins
    case cron
    case permissions
    case account
}
