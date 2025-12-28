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
    @State private var selection: NavSection? = .overview

    var body: some View {
        List(selection: $selection) {
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

            Section("Control Plane") {
                NavigationLink(value: NavSection.controlPlane) {
                    Label("Overview", systemImage: "cpu")
                }

                NavigationLink(value: NavSection.safety) {
                    Label("Safety Dashboard", systemImage: "shield.checkered")
                }
                .badge(viewModel.cpConfig.safetyDashboard?.safetyScore ?? 0)

                NavigationLink(value: NavSection.interactions) {
                    Label("Interaction Graph", systemImage: "point.3.connected.trianglepath.dotted")
                }
                .badge(viewModel.cpConfig.interactionGraph?.nodes.count ?? 0)

                NavigationLink(value: NavSection.dependencies) {
                    Label("Dependencies", systemImage: "arrow.triangle.branch")
                }
                .badge(viewModel.cpConfig.conflictCount)

                NavigationLink(value: NavSection.archaeology) {
                    Label("Prompt History", systemImage: "clock.arrow.circlepath")
                }
                .badge(viewModel.cpConfig.promptVersions.count)

                NavigationLink(value: NavSection.coverage) {
                    Label("Capability Map", systemImage: "map")
                }

                NavigationLink(value: NavSection.runtime) {
                    Label("Runtime State", systemImage: "gauge.with.dots.needle.bottom.50percent")
                }

                NavigationLink(value: NavSection.traces) {
                    Label("Execution Traces", systemImage: "list.bullet.rectangle")
                }
                .badge(viewModel.cpConfig.sessions.count)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .onChange(of: selection) { _, newValue in
            if let newValue = newValue {
                viewModel.selectedSection = newValue
            }
        }
        .onAppear {
            selection = viewModel.selectedSection
        }
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
            // Control Plane sections
            case .controlPlane:
                ControlPlaneOverview(cpConfig: viewModel.cpConfig, viewModel: viewModel)
            case .safety:
                SafetyDashboardView(dashboard: viewModel.cpConfig.safetyDashboard, viewModel: viewModel)
            case .interactions:
                InteractionGraphView(graph: viewModel.cpConfig.interactionGraph, viewModel: viewModel)
            case .dependencies:
                DependencyView(dependencies: viewModel.cpConfig.dependencies, conflicts: viewModel.cpConfig.conflicts, viewModel: viewModel)
            case .archaeology:
                PromptArchaeologyView(viewModel: viewModel)
            case .coverage:
                CapabilityCoverageView(coverage: viewModel.cpConfig.capabilityCoverage, viewModel: viewModel)
            case .runtime:
                RuntimeStateView(state: viewModel.cpConfig.runtimeState, viewModel: viewModel)
            case .traces:
                ExecutionTracesView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 500)
    }
}

// MARK: - Health Alert Bar

struct HealthAlertBar: View {
    let health: ConfigHealth
    let issues: [HealthIssue]
    @ObservedObject var viewModel: ConfigViewModel
    @State private var isExpanded = false
    @State private var expandedIssueId: UUID?

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
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(issues) { issue in
                        VStack(alignment: .leading, spacing: 8) {
                            // Issue header - clickable to expand
                            Button(action: {
                                withAnimation {
                                    if expandedIssueId == issue.id {
                                        expandedIssueId = nil
                                    } else {
                                        expandedIssueId = issue.id
                                    }
                                }
                            }) {
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

                                    Spacer()

                                    Image(systemName: expandedIssueId == issue.id ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            // Expanded issue details
                            if expandedIssueId == issue.id {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Explanation
                                    if let explanation = issue.explanation {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(.blue)
                                                .frame(width: 16)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Why this matters")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.blue)
                                                Text(explanation)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    // Suggested action
                                    if let action = issue.suggestedAction {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "lightbulb")
                                                .foregroundColor(.yellow)
                                                .frame(width: 16)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Suggested action")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.yellow)
                                                Text(action)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    // Navigation button
                                    if let target = issue.navigationTarget {
                                        Button(action: {
                                            navigateTo(target: target)
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.right.circle.fill")
                                                Text("Go to \(sectionName(for: target))")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.accentColor.opacity(0.15))
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.leading, 28)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)

                        if issue.id != issues.last?.id {
                            Divider()
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

    func navigateTo(target: String) {
        switch target {
        case "claudeMD": viewModel.selectedSection = .claudeMD
        case "commands": viewModel.selectedSection = .commands
        case "plugins": viewModel.selectedSection = .plugins
        case "permissions": viewModel.selectedSection = .permissions
        case "cron": viewModel.selectedSection = .cron
        case "safety": viewModel.selectedSection = .safety
        case "dependencies": viewModel.selectedSection = .dependencies
        default: break
        }
    }

    func sectionName(for target: String) -> String {
        switch target {
        case "claudeMD": return "CLAUDE.md Files"
        case "commands": return "Commands"
        case "plugins": return "Plugins"
        case "permissions": return "Permissions"
        case "cron": return "Scheduled Jobs"
        case "safety": return "Safety Dashboard"
        case "dependencies": return "Dependencies"
        default: return target
        }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: CustomizationSuggestion
    @ObservedObject var viewModel: ConfigViewModel
    let onDismiss: () -> Void
    @State private var showingCreateSheet = false

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

                        // Always show Create Command for command suggestions
                        Button(suggestion.category == .command ? "Create Command" : suggestion.actionLabel) {
                            if suggestion.category == .command {
                                showingCreateSheet = true
                            } else if let path = suggestion.actionPath {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
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
        .sheet(isPresented: $showingCreateSheet) {
            CommandCreatorSheet(
                suggestedName: extractCommandName(from: suggestion.title),
                suggestedContent: generateCommandTemplate(for: suggestion),
                viewModel: viewModel,
                onCreated: onDismiss
            )
        }
    }

    func extractCommandName(from title: String) -> String {
        // Extract command name from title like "Add /review-pr Command"
        if let match = title.range(of: #"/[\w-]+"#, options: .regularExpression) {
            return String(title[match]).dropFirst().lowercased()
        }
        return title.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    func generateCommandTemplate(for suggestion: CustomizationSuggestion) -> String {
        let name = extractCommandName(from: suggestion.title)

        // Generate specific, useful content based on the suggestion
        switch name {
        case "review-pr":
            return """
            Review the current pull request and provide actionable feedback.

            ## Instructions

            1. First, get the current branch and find the associated PR:
               ```bash
               gh pr view --json number,title,body,files
               ```

            2. Analyze the changes in this PR:
               - Review each modified file for bugs, security issues, and code quality
               - Check for proper error handling and edge cases
               - Verify naming conventions and code style consistency
               - Look for potential performance issues

            3. Provide a structured review with:
               - **Summary**: Brief overview of what the PR does
               - **Strengths**: What's done well
               - **Issues**: Problems that should be fixed (with line references)
               - **Suggestions**: Optional improvements
               - **Verdict**: Approve, Request Changes, or Comment

            4. Format feedback as GitHub-compatible markdown that can be posted as a review comment.

            ## Example Output
            ```
            ## PR Review: Add user authentication

            ### Summary
            This PR implements JWT-based authentication...

            ### Issues
            - `src/auth.ts:45` - Password not hashed before storage
            - `src/routes.ts:12` - Missing rate limiting on login endpoint

            ### Verdict: Request Changes
            ```
            """

        case "fitness-summary":
            return """
            Generate a weekly fitness and health summary from tracked metrics.

            ## Instructions

            1. Read the health data from the configured data store (check ~/.claude/CLAUDE.md for location)

            2. Aggregate the past 7 days of data for:
               - Weight trends (if tracked)
               - Blood pressure readings (if tracked)
               - Exercise/activity logs
               - Sleep data (if available)
               - Any custom metrics

            3. Generate a summary report including:
               - **Weekly Overview**: Key stats at a glance
               - **Trends**: Are metrics improving, stable, or declining?
               - **Achievements**: Goals met or personal bests
               - **Insights**: Patterns noticed (e.g., "BP lower on days with morning walks")
               - **Focus for Next Week**: One actionable recommendation

            4. Format as a clean markdown report suitable for personal review.

            ## Output Format
            ```markdown
            # Weekly Health Summary: [Date Range]

            ## At a Glance
            | Metric | This Week | Last Week | Trend |
            |--------|-----------|-----------|-------|
            | Weight | 185.2 lbs | 186.1 lbs | ↓ 0.9 |

            ## Insights
            - Your blood pressure averaged 118/76, within healthy range
            - Activity was highest on Tuesday and Thursday

            ## Next Week Focus
            Consider adding one more cardio session...
            ```
            """

        case "budget-forecast":
            return """
            Generate a financial forecast based on historical spending patterns.

            ## Instructions

            1. Access the financial data from the budget system (check Financial Survival Planner or configured location)

            2. Analyze the past 3-6 months of:
               - Income sources and amounts
               - Fixed expenses (rent, subscriptions, etc.)
               - Variable expenses by category
               - Seasonal patterns (holidays, quarterly bills)

            3. Generate a forecast for the next 1-3 months:
               - **Projected Income**: Expected earnings
               - **Projected Expenses**: By category with confidence levels
               - **Net Cash Flow**: Surplus or deficit prediction
               - **Risk Factors**: Unusual upcoming expenses or income gaps

            4. Provide actionable recommendations:
               - Areas where spending can be reduced
               - Bills that could be renegotiated
               - Savings opportunities

            ## Output Format
            ```markdown
            # Financial Forecast: [Next Month]

            ## Projected Cash Flow
            - Expected Income: $X,XXX
            - Expected Expenses: $X,XXX
            - Net: +/- $XXX

            ## By Category
            | Category | Projected | vs. Avg | Confidence |
            |----------|-----------|---------|------------|
            | Housing  | $1,500    | =       | High       |
            | Food     | $450      | +$50    | Medium     |

            ## Recommendations
            1. Streaming subscriptions total $85/mo - consider consolidating
            ```
            """

        case "weekly-reflection":
            return """
            Conduct a weekly reflection on commitments, progress, and intentions.

            ## Instructions

            1. Review the followthrough/accountability data from the past week:
               - Commitments made and their status
               - Tasks completed vs. planned
               - Patterns in what got done vs. what slipped

            2. Guide a structured reflection:

               **What Went Well**
               - Which commitments were honored?
               - What enabled success?

               **What Was Challenging**
               - What commitments were missed or delayed?
               - What got in the way?

               **Patterns Noticed**
               - Are certain types of commitments consistently harder?
               - What time of day/week is most productive?

               **Intentions for Next Week**
               - What are the top 3 priorities?
               - What will you do differently?
               - What support do you need?

            3. Store the reflection in a designated location for future reference.

            ## Output Format
            ```markdown
            # Weekly Reflection: Week of [Date]

            ## Wins 🎉
            - Completed the API refactor ahead of schedule
            - Maintained morning exercise routine (5/7 days)

            ## Challenges 🤔
            - Documentation updates pushed to next week again
            - Evening commitments consistently deprioritized

            ## Pattern
            I notice I'm more likely to complete tasks with external deadlines...

            ## Next Week Intentions
            1. Ship documentation by Wednesday
            2. Block 30 min each evening for personal projects
            3. Say no to at least one new commitment
            ```
            """

        case "ux-test-terminal", "ux-test":
            return """
            Run a virtual user testing session for a terminal/CLI application.

            ## Instructions

            1. Identify the CLI tool or terminal workflow to test

            2. Create 3-5 virtual user personas with varying technical levels:
               - **Novice**: First-time user, unfamiliar with CLI conventions
               - **Intermediate**: Comfortable with terminal, new to this tool
               - **Expert**: Power user, looking for efficiency
               - **Accessibility**: User relying on screen reader

            3. For each persona, simulate their experience:
               - First impressions of help text and documentation
               - Attempting common tasks
               - Error recovery and feedback clarity
               - Discoverability of features

            4. Document findings:

               **Friction Points**: Where users get stuck or confused
               **Delights**: Unexpectedly good experiences
               **Accessibility Issues**: Problems for users with disabilities
               **Suggestions**: Specific improvements with priority

            ## Output Format
            ```markdown
            # UX Test Report: [CLI Tool Name]

            ## Persona: Novice User (Pat)
            ### Task: Install and run first command
            - ❌ Help text assumes familiarity with flags
            - ❌ Error message "ENOENT" unhelpful
            - ✅ Tab completion discovered accidentally, very helpful

            ## Summary
            | Issue | Severity | Effort | Priority |
            |-------|----------|--------|----------|
            | Unclear error messages | High | Low | P0 |
            | No --help examples | Medium | Low | P1 |
            ```
            """

        case "model-selector":
            return """
            Help select the appropriate LLM model for the current task.

            ## Model Selection Guidelines

            When choosing a model, consider these factors:

            ### Task Complexity vs. Cost

            | Task Type | Recommended Model | Reasoning |
            |-----------|-------------------|-----------|
            | Simple extraction, formatting | haiku | Fast, cheap, sufficient |
            | Code generation, analysis | sonnet | Good balance of capability/cost |
            | Complex reasoning, planning | opus | Highest capability needed |
            | High-volume content | deepseek/deepseek-chat | Cost-effective for bulk |
            | Image generation | gemini-3.0-image-* | Specialized capability |

            ### Decision Process

            1. **Can Claude Max handle this?**
               If yes, use Task tool with appropriate agent (no API cost)

            2. **Is this high-volume writing?**
               Consider deepseek for cost efficiency

            3. **Does this require complex reasoning?**
               Use opus for planning, architecture, nuanced analysis

            4. **Is this routine code work?**
               Sonnet is the default for most development tasks

            5. **Is this simple text processing?**
               Haiku is fast and cheap

            ### Verification

            Before using any model, verify it's current:
            ```bash
            python -c "import litellm; print([k for k in litellm.model_cost.keys() if 'claude' in k][:10])"
            ```

            ### Current Model IDs
            - Claude Opus 4.5: `anthropic/claude-opus-4-5-20251101`
            - Claude Sonnet 4: `anthropic/claude-sonnet-4-20250514`
            - Claude Haiku: `anthropic/claude-haiku-3-5-20241022`
            """

        default:
            // Generic but still useful template
            return """
            \(suggestion.description)

            ## Purpose
            This command extends Claude's capabilities by providing a structured workflow for \(name.replacingOccurrences(of: "-", with: " ")).

            ## Instructions

            When the user invokes /\(name), follow these steps:

            1. **Gather Context**
               - Identify relevant files, data, or state needed
               - Ask clarifying questions if the scope is ambiguous

            2. **Execute the Task**
               - [Define the specific actions this command performs]
               - Use appropriate tools (Read, Edit, Bash, etc.)
               - Provide progress updates for longer operations

            3. **Deliver Results**
               - Present findings in a clear, structured format
               - Include actionable next steps if applicable
               - Offer to iterate or refine based on feedback

            ## Example Usage
            ```
            User: /\(name)
            Assistant: [Expected behavior description]
            ```

            ## Notes
            - This command works best when [conditions]
            - Consider combining with [related commands] for [enhanced workflow]
            """
        }
    }
}

struct CommandCreatorSheet: View {
    @State var suggestedName: String
    @State var suggestedContent: String
    @ObservedObject var viewModel: ConfigViewModel
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State var isSkill = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New \(isSkill ? "Skill" : "Command")")
                .font(.headline)

            Toggle("Create as Skill (in ~/.claude/skills/)", isOn: $isSkill)
                .padding(.horizontal)

            GroupBox("Command Name") {
                HStack {
                    Text("/")
                        .foregroundColor(.secondary)
                    TextField("command-name", text: $suggestedName)
                        .textFieldStyle(.roundedBorder)
                        .fontDesign(.monospaced)
                }
                .padding()
            }

            GroupBox("Content (Markdown)") {
                TextEditor(text: $suggestedContent)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
                    .padding(4)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)

                Spacer()

                Button("Create") {
                    Task {
                        await viewModel.createCommand(
                            name: suggestedName,
                            content: suggestedContent,
                            isSkill: isSkill
                        )
                        dismiss()
                        onCreated()
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(suggestedName.isEmpty || suggestedContent.isEmpty)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

// MARK: - Overview

struct OverviewView: View {
    @ObservedObject var viewModel: ConfigViewModel
    @State private var showSuggestion = true
    @State private var showMindMap = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Health Alert Bar at top
                HealthAlertBar(
                    health: viewModel.config.overallHealth,
                    issues: viewModel.config.healthIssues,
                    viewModel: viewModel
                )

                // Capability Analysis Section - NOW AT TOP
                if let analysis = viewModel.config.capabilityAnalysis, !analysis.categories.isEmpty {
                    CapabilitySummaryView(analysis: analysis, showMindMap: $showMindMap)
                }

                // Suggestion Popup (dismissable)
                if showSuggestion, let suggestion = viewModel.config.suggestion {
                    SuggestionCard(suggestion: suggestion, viewModel: viewModel) {
                        withAnimation {
                            showSuggestion = false
                        }
                    }
                }

                // Config Hierarchy
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

                        Divider()
                            .padding(.vertical, 4)

                        // Commands Hierarchy
                        HStack {
                            Image(systemName: "terminal")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Commands")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("~/.claude/commands/")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(viewModel.config.commandCount) files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedSection = .commands
                        }

                        // Skills Hierarchy
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Skills")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("~/.claude/skills/")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(viewModel.config.skillCount) files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedSection = .commands
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
        .sheet(isPresented: $showMindMap) {
            if let analysis = viewModel.config.capabilityAnalysis {
                MindMapSheet(analysis: analysis, commands: viewModel.config.slashCommands)
            }
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

// MARK: - Capability Summary View

struct CapabilitySummaryView: View {
    let analysis: CapabilityAnalysis
    @Binding var showMindMap: Bool
    @State private var isExpanded = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("Capability Summary")
                        .font(.headline)
                    Spacer()

                    Button(action: { showMindMap = true }) {
                        Label("Mind Map", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Summary text
                Text(analysis.summaryText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Bar chart visualization
                CapabilityBarChart(categories: analysis.categories)
                    .frame(height: 120)

                // Expanded details
                if isExpanded {
                    Divider()

                    ForEach(analysis.categories) { category in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: category.icon)
                                .foregroundColor(colorFor(category.color))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(category.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(category.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .background(colorFor(category.color).opacity(0.2))
                                        .cornerRadius(4)
                                }

                                Text(category.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    func colorFor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "cyan": return .cyan
        case "mint": return .mint
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

struct CapabilityBarChart: View {
    let categories: [CapabilityAnalysis.CapabilityCategory]

    var maxCount: Int {
        categories.map { $0.count }.max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(categories.prefix(6)) { category in
                VStack(spacing: 4) {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorFor(category.color).gradient)
                        .frame(width: 36, height: barHeight(for: category.count))

                    // Count label
                    Text("\(category.count)")
                        .font(.caption2)
                        .fontWeight(.medium)

                    // Category icon
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundColor(colorFor(category.color))
                }
                .help(category.name)
            }

            Spacer()

            // Legend
            VStack(alignment: .leading, spacing: 4) {
                ForEach(categories.prefix(6)) { category in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorFor(category.color))
                            .frame(width: 8, height: 8)
                        Text(category.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    func barHeight(for count: Int) -> CGFloat {
        let maxHeight: CGFloat = 80
        let minHeight: CGFloat = 12
        guard maxCount > 0 else { return minHeight }
        return max(minHeight, CGFloat(count) / CGFloat(maxCount) * maxHeight)
    }

    func colorFor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "cyan": return .cyan
        case "mint": return .mint
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Mind Map Sheet

struct MindMapSheet: View {
    let analysis: CapabilityAnalysis
    let commands: [SlashCommand]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Command Mind Map")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(commands.count) commands in \(analysis.categories.count) categories")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            // Mind Map Canvas
            ScrollView([.horizontal, .vertical]) {
                MindMapCanvas(analysis: analysis, commands: commands)
                    .frame(minWidth: 800, minHeight: 600)
                    .padding(40)
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(minWidth: 600, idealWidth: 900, maxWidth: .infinity,
               minHeight: 400, idealHeight: 700, maxHeight: .infinity)
    }
}

struct MindMapCanvas: View {
    let analysis: CapabilityAnalysis
    let commands: [SlashCommand]

    // Center position
    let centerX: CGFloat = 400
    let centerY: CGFloat = 300

    var body: some View {
        ZStack {
            // Draw connection lines first (behind nodes)
            ForEach(Array(analysis.categories.enumerated()), id: \.element.id) { index, category in
                let angle = angleFor(index: index, total: analysis.categories.count)
                let branchEnd = pointAt(angle: angle, distance: 180)

                // Main branch line
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.addLine(to: CGPoint(x: centerX + branchEnd.x, y: centerY + branchEnd.y))
                }
                .stroke(colorFor(category.color).opacity(0.5), lineWidth: 3)

                // Sub-branch lines to commands
                ForEach(Array(category.commands.prefix(5).enumerated()), id: \.offset) { cmdIndex, cmdName in
                    let subAngle = angle + subAngleOffset(index: cmdIndex, total: min(category.commands.count, 5))
                    let leafEnd = pointAt(angle: subAngle, distance: 280)

                    Path { path in
                        path.move(to: CGPoint(x: centerX + branchEnd.x, y: centerY + branchEnd.y))
                        path.addLine(to: CGPoint(x: centerX + leafEnd.x, y: centerY + leafEnd.y))
                    }
                    .stroke(colorFor(category.color).opacity(0.3), lineWidth: 1.5)
                }
            }

            // Central node
            MindMapNode(
                text: "Claude",
                icon: "brain.head.profile",
                color: .accentColor,
                isCenter: true
            )
            .position(x: centerX, y: centerY)

            // Category nodes and command leaves
            ForEach(Array(analysis.categories.enumerated()), id: \.element.id) { index, category in
                let angle = angleFor(index: index, total: analysis.categories.count)
                let branchEnd = pointAt(angle: angle, distance: 180)

                // Category node
                MindMapNode(
                    text: category.name,
                    icon: category.icon,
                    color: colorFor(category.color),
                    count: category.count
                )
                .position(x: centerX + branchEnd.x, y: centerY + branchEnd.y)

                // Command leaf nodes (show up to 5)
                ForEach(Array(category.commands.prefix(5).enumerated()), id: \.offset) { cmdIndex, cmdName in
                    let subAngle = angle + subAngleOffset(index: cmdIndex, total: min(category.commands.count, 5))
                    let leafEnd = pointAt(angle: subAngle, distance: 280)

                    MindMapLeaf(text: "/\(cmdName)", color: colorFor(category.color))
                        .position(x: centerX + leafEnd.x, y: centerY + leafEnd.y)
                }

                // "More" indicator if there are more than 5 commands
                if category.commands.count > 5 {
                    let moreAngle = angle + subAngleOffset(index: 5, total: 6)
                    let moreEnd = pointAt(angle: moreAngle, distance: 280)

                    Text("+\(category.commands.count - 5) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(x: centerX + moreEnd.x, y: centerY + moreEnd.y)
                }
            }
        }
    }

    func angleFor(index: Int, total: Int) -> Double {
        let startAngle = -Double.pi / 2 // Start from top
        let angleStep = (2 * Double.pi) / Double(total)
        return startAngle + Double(index) * angleStep
    }

    func subAngleOffset(index: Int, total: Int) -> Double {
        let spread = Double.pi / 4 // 45 degree spread for sub-items
        let step = spread / Double(max(total - 1, 1))
        return -spread / 2 + Double(index) * step
    }

    func pointAt(angle: Double, distance: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(cos(angle)) * distance,
            y: CGFloat(sin(angle)) * distance
        )
    }

    func colorFor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "cyan": return .cyan
        case "mint": return .mint
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

struct MindMapNode: View {
    let text: String
    let icon: String
    let color: Color
    var isCenter: Bool = false
    var count: Int? = nil

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: isCenter ? 80 : 60, height: isCenter ? 80 : 60)

                Circle()
                    .stroke(color, lineWidth: isCenter ? 3 : 2)
                    .frame(width: isCenter ? 80 : 60, height: isCenter ? 80 : 60)

                Image(systemName: icon)
                    .font(isCenter ? .title : .title3)
                    .foregroundColor(color)
            }

            Text(text)
                .font(isCenter ? .headline : .caption)
                .fontWeight(isCenter ? .bold : .medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 100)

            if let count = count {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color)
                    .cornerRadius(8)
            }
        }
    }
}

struct MindMapLeaf: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
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
    // Control Plane sections
    case controlPlane
    case safety
    case interactions
    case dependencies
    case archaeology
    case coverage
    case runtime
    case traces
}
