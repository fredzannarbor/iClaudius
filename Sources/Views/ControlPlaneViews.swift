import SwiftUI

// MARK: - Control Plane Overview

struct ControlPlaneOverview: View {
    let cpConfig: ControlPlaneConfiguration

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Control Plane")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Layer Summary Cards
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                    ForEach(ControlPlaneLayer.allCases, id: \.self) { layer in
                        LayerCard(
                            layer: layer,
                            entityCount: cpConfig.entities.filter { $0.layer == layer }.count
                        )
                    }
                }

                // Health Summary
                GroupBox {
                    HStack {
                        Image(systemName: cpConfig.overallHealth.icon)
                            .font(.title2)
                            .foregroundColor(colorFor(cpConfig.overallHealth.color))

                        VStack(alignment: .leading) {
                            Text("System Health")
                                .font(.headline)
                            Text(cpConfig.overallHealth.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(cpConfig.entities.count) entities")
                            Text("\(cpConfig.conflictCount) conflicts")
                                .foregroundColor(cpConfig.conflictCount > 0 ? .orange : .secondary)
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }

                // Quick Stats
                HStack(spacing: 16) {
                    QuickStatPill(
                        label: "Autonomous Loops",
                        value: "\(cpConfig.autonomousLoopCount)",
                        color: cpConfig.autonomousLoopCount > 0 ? .orange : .gray
                    )

                    QuickStatPill(
                        label: "Dependencies",
                        value: "\(cpConfig.dependencies.count)",
                        color: .blue
                    )

                    QuickStatPill(
                        label: "Sessions",
                        value: "\(cpConfig.sessions.count)",
                        color: .purple
                    )
                }

                Spacer()
            }
            .padding()
        }
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }
}

struct LayerCard: View {
    let layer: ControlPlaneLayer
    let entityCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: layer.icon)
                    .foregroundColor(colorFor(layer.color))
                Text("\(entityCount)")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(layer.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(layer.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(colorFor(layer.color).opacity(0.1))
        .cornerRadius(12)
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
}

struct QuickStatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Safety Dashboard View

struct SafetyDashboardView: View {
    let dashboard: SafetyDashboard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with score
                HStack {
                    VStack(alignment: .leading) {
                        Text("Safety Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        HStack {
                            Image(systemName: dashboard.overallStatus.icon)
                                .foregroundColor(colorFor(dashboard.overallStatus.color))
                            Text(dashboard.overallStatus.rawValue)
                                .font(.headline)
                        }
                    }

                    Spacer()

                    // Safety Score Gauge
                    SafetyScoreGauge(score: dashboard.safetyScore)
                }

                // Permission Surface Summary
                GroupBox("Permission Surface") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: dashboard.permissionSurface.riskLevel.icon)
                                .foregroundColor(colorFor(dashboard.permissionSurface.riskLevel.color))
                            Text(dashboard.permissionSurface.riskLevel.rawValue)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(dashboard.permissionSurface.totalPermissions) permissions")
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        Text("Sensitive Operations (\(dashboard.permissionSurface.sensitiveOperations.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ForEach(dashboard.permissionSurface.sensitiveOperations.prefix(5)) { op in
                            HStack {
                                Circle()
                                    .fill(colorFor(op.risk.color))
                                    .frame(width: 8, height: 8)
                                Text(op.operation)
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                                Text(op.risk.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if dashboard.permissionSurface.sensitiveOperations.count > 5 {
                            Text("+ \(dashboard.permissionSurface.sensitiveOperations.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }

                // Autonomous Loops
                GroupBox("Autonomous Loops") {
                    VStack(alignment: .leading, spacing: 12) {
                        if dashboard.autonomousLoops.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                Text("No autonomous loops detected")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(dashboard.autonomousLoops) { loop in
                                HStack {
                                    Image(systemName: loop.type.icon)
                                        .foregroundColor(colorFor(loop.type.riskLevel))
                                        .frame(width: 24)

                                    VStack(alignment: .leading) {
                                        Text(loop.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(loop.type.rawValue) - \(loop.frequency)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if loop.isActive {
                                        Text("Active")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }

                // Recommendations
                if !dashboard.permissionSurface.recommendations.isEmpty {
                    GroupBox("Recommendations") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(dashboard.permissionSurface.recommendations) { rec in
                                HStack(alignment: .top) {
                                    Circle()
                                        .fill(colorFor(rec.priority.color))
                                        .frame(width: 10, height: 10)
                                        .padding(.top, 4)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(rec.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(rec.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
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

    func colorFor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        case "low": return .green
        case "medium": return .yellow
        case "high": return .red
        default: return .gray
        }
    }
}

struct SafetyScoreGauge: View {
    let score: Int

    var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 50 { return .yellow }
        return .red
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Interaction Graph View

struct InteractionGraphView: View {
    let graph: InteractionGraph
    @State private var selectedLayer: ControlPlaneLayer?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Interaction Graph")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(graph.nodes.count) nodes, \(graph.edges.count) edges")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Layer filter
                Picker("Layer", selection: $selectedLayer) {
                    Text("All").tag(nil as ControlPlaneLayer?)
                    ForEach(ControlPlaneLayer.allCases, id: \.self) { layer in
                        Text(layer.rawValue).tag(layer as ControlPlaneLayer?)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
            }
            .padding()

            // Graph visualization
            ScrollView([.horizontal, .vertical]) {
                GraphCanvas(graph: filteredGraph)
                    .frame(minWidth: 800, minHeight: 600)
                    .padding(40)
            }
            .background(Color(NSColor.textBackgroundColor))
        }
    }

    var filteredGraph: InteractionGraph {
        guard let layer = selectedLayer else { return graph }

        let filteredNodes = graph.nodes.filter { $0.layer == layer }
        let nodeIds = Set(filteredNodes.map { $0.id })
        let filteredEdges = graph.edges.filter {
            nodeIds.contains($0.source.id) || nodeIds.contains($0.target.id)
        }

        return InteractionGraph(nodes: filteredNodes, edges: filteredEdges)
    }
}

struct GraphCanvas: View {
    let graph: InteractionGraph

    let centerX: CGFloat = 400
    let centerY: CGFloat = 300

    var body: some View {
        ZStack {
            // Draw edges
            ForEach(graph.edges) { edge in
                let sourcePos = positionFor(edge.source, in: graph.nodes)
                let targetPos = positionFor(edge.target, in: graph.nodes)

                Path { path in
                    path.move(to: sourcePos)
                    path.addLine(to: targetPos)
                }
                .stroke(colorFor(edge.relationship), lineWidth: CGFloat(edge.weight) * 2)
            }

            // Draw nodes
            ForEach(graph.nodes) { node in
                let pos = positionFor(node, in: graph.nodes)

                GraphNode(node: node)
                    .position(pos)
            }
        }
    }

    func positionFor(_ node: InteractionNode, in nodes: [InteractionNode]) -> CGPoint {
        // Group by layer
        let layerNodes = nodes.filter { $0.layer == node.layer }
        guard let index = layerNodes.firstIndex(where: { $0.id == node.id }) else {
            return CGPoint(x: centerX, y: centerY)
        }

        let layerIndex = ControlPlaneLayer.allCases.firstIndex(of: node.layer) ?? 0
        let yOffset = CGFloat(layerIndex) * 150 + 50

        let xSpacing: CGFloat = 150
        let totalWidth = CGFloat(layerNodes.count - 1) * xSpacing
        let startX = centerX - totalWidth / 2
        let xOffset = startX + CGFloat(index) * xSpacing

        return CGPoint(x: xOffset, y: yOffset)
    }

    func colorFor(_ type: Dependency.DependencyType) -> Color {
        switch type {
        case .imports: return .blue
        case .references: return .gray
        case .triggers: return .orange
        case .requires: return .red
        case .conflicts: return .red
        }
    }
}

struct GraphNode: View {
    let node: InteractionNode

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(colorFor(node.layer.color).opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: node.type.icon)
                        .foregroundColor(colorFor(node.layer.color))
                )

            Text(node.name)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
}

// MARK: - Dependency View

struct DependencyView: View {
    let dependencies: [Dependency]
    let conflicts: [Conflict]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dependencies & Conflicts")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Conflicts section (if any)
                if !conflicts.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("\(conflicts.count) Conflict\(conflicts.count == 1 ? "" : "s") Detected")
                                    .font(.headline)
                            }

                            ForEach(conflicts) { conflict in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Circle()
                                            .fill(colorFor(conflict.severity.color))
                                            .frame(width: 8, height: 8)
                                        Text(conflict.type.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }

                                    Text(conflict.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if let resolution = conflict.resolution {
                                        HStack {
                                            Image(systemName: "lightbulb")
                                                .foregroundColor(.yellow)
                                            Text(resolution)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding()
                                .background(colorFor(conflict.severity.color).opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }

                // Dependencies list
                GroupBox("Dependencies (\(dependencies.count))") {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(dependencies) { dep in
                            HStack {
                                Text(dep.source)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)

                                Image(systemName: arrowFor(dep.type))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(dep.target)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)

                                Spacer()

                                Text(dep.type.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Circle()
                                    .fill(strengthColor(dep.strength))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .padding()
        }
    }

    func arrowFor(_ type: Dependency.DependencyType) -> String {
        switch type {
        case .imports: return "arrow.right"
        case .references: return "arrow.right.dotted"
        case .triggers: return "bolt.horizontal"
        case .requires: return "arrow.right.circle"
        case .conflicts: return "exclamationmark.triangle"
        }
    }

    func strengthColor(_ strength: Dependency.DependencyStrength) -> Color {
        switch strength {
        case .hard: return .red
        case .soft: return .orange
        case .optional: return .gray
        }
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Prompt Archaeology View

struct PromptArchaeologyView: View {
    let versions: [PromptVersion]
    @State private var selectedVersion: PromptVersion?

    var body: some View {
        HSplitView {
            // Version list
            List(versions, selection: $selectedVersion) { version in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: version.changeType.icon)
                            .foregroundColor(colorFor(version.changeType.color))
                        Text("v\(version.version)")
                            .font(.headline)
                        Text(version.changeType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(version.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let summary = version.summary {
                        Text(summary)
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }

                    Text(version.timestamp.formatted())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .tag(version)
            }
            .frame(minWidth: 250)

            // Version content
            if let version = selectedVersion {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Version \(version.version)")
                                .font(.title2)
                                .fontWeight(.bold)

                            Spacer()

                            Text(version.timestamp.formatted())
                                .foregroundColor(.secondary)
                        }

                        Text(version.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        Text(version.content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding()
                }
            } else {
                Text("Select a version to view its content")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Capability Coverage View

struct CapabilityCoverageView: View {
    let coverage: CapabilityCoverage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Capability Coverage")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Extension ratio gauge
                HStack {
                    Text("Extension Ratio")
                        .font(.headline)
                    Spacer()

                    ProgressView(value: coverage.extensionRatio)
                        .progressViewStyle(.linear)
                        .frame(width: 200)

                    Text("\(Int(coverage.extensionRatio * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

                // Domain coverage
                GroupBox("Domains") {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(coverage.domains) { domain in
                            HStack {
                                Image(systemName: domain.icon)
                                    .foregroundColor(colorFor(domain.color))
                                    .frame(width: 24)

                                VStack(alignment: .leading) {
                                    Text(domain.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("\(domain.capabilities.count) capabilities")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if domain.isExtended {
                                    Text("Extended")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.2))
                                        .cornerRadius(4)
                                }

                                ProgressView(value: domain.coverage)
                                    .progressViewStyle(.linear)
                                    .frame(width: 60)
                            }
                        }
                    }
                    .padding()
                }

                // Base capabilities
                GroupBox("Base Capabilities") {
                    FlowLayout(spacing: 8) {
                        ForEach(coverage.baseCapabilities, id: \.self) { cap in
                            Text(cap)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }

                // Extended capabilities
                GroupBox("Extended Capabilities") {
                    FlowLayout(spacing: 8) {
                        ForEach(coverage.extendedCapabilities, id: \.self) { cap in
                            Text(cap)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }

                // Gap analysis
                if !coverage.gapAnalysis.isEmpty {
                    GroupBox("Identified Gaps") {
                        ForEach(coverage.gapAnalysis) { gap in
                            HStack(alignment: .top) {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.yellow)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(gap.domain): \(gap.missingCapability)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(gap.suggestion)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(gap.difficulty.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(colorFor(gap.difficulty.color).opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 4)
                        }
                        .padding()
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Flow Layout (for tag clouds)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (positions: [CGPoint], height: CGFloat) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (positions, currentY + lineHeight)
    }
}

// MARK: - Runtime State View

struct RuntimeStateView: View {
    let state: RuntimeState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Runtime State")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    HStack {
                        Circle()
                            .fill(state.isActive ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        Text(state.isActive ? "Active" : "Inactive")
                            .font(.subheadline)
                    }
                }

                // Last activity
                if let lastActivity = state.lastActivity {
                    GroupBox {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("Last Activity")
                                .font(.subheadline)
                            Spacer()
                            Text(lastActivity.formatted())
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Loaded plugins
                GroupBox("Loaded Plugins (\(state.loadedPlugins.count))") {
                    if state.loadedPlugins.isEmpty {
                        Text("No plugins currently loaded")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(state.loadedPlugins, id: \.self) { plugin in
                                HStack(spacing: 4) {
                                    Image(systemName: "puzzlepiece.extension")
                                        .font(.caption)
                                    Text(plugin)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }

                // Active hooks
                GroupBox("Active Hooks (\(state.activeHooks.count))") {
                    if state.activeHooks.isEmpty {
                        Text("No hooks currently active")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(state.activeHooks, id: \.self) { hook in
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(.orange)
                                    Text(hook)
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .padding()
                    }
                }

                // Recent commands
                GroupBox("Recent Commands") {
                    if state.recentCommands.isEmpty {
                        Text("No recent commands")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(state.recentCommands, id: \.self) { cmd in
                                HStack {
                                    Image(systemName: "terminal")
                                        .foregroundColor(.green)
                                    Text("/\(cmd)")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .padding()
                    }
                }

                // Memory usage (if available)
                if let memory = state.memoryUsage {
                    GroupBox("Context Memory") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Tokens Used")
                                Spacer()
                                Text("\(memory.contextTokens) / \(memory.maxTokens)")
                                    .foregroundColor(.secondary)
                            }

                            ProgressView(value: memory.percentUsed / 100)
                                .progressViewStyle(.linear)

                            Text("\(Int(memory.percentUsed))% of context window used")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

// MARK: - Execution Traces View

struct ExecutionTracesView: View {
    let traces: [ExecutionTrace]
    let sessions: [SessionInfo]

    var body: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack {
                Text("\(sessions.count) sessions")
                    .font(.subheadline)
                Spacer()
                Text("\(traces.count) traces")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            if sessions.isEmpty && traces.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No execution traces available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Traces will appear after using Claude commands")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("Sessions") {
                        ForEach(sessions) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("\(session.messageCount) messages, \(session.toolCallCount) tool calls")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(session.status.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(colorFor(session.status.color).opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "blue": return .blue
        case "red": return .red
        default: return .gray
        }
    }
}
