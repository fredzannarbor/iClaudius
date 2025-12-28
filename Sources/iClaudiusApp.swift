import SwiftUI
import os.log

let logger = Logger(subsystem: "com.fred.iClaudius", category: "main")

@main
struct iClaudiusApp: App {
    init() {
        logger.info("🚀 App starting!")
        NSLog("🚀 [iClaudiusApp] App starting!")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    logger.info("🚀 ContentView appeared!")
                    NSLog("🚀 [ContentView] View appeared!")
                }
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Configuration") {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshConfig, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Open ~/.claude in Finder") {
                    let path = NSHomeDirectory() + "/.claude"
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                }

                Button("Open CLAUDE.md in Editor") {
                    let path = NSHomeDirectory() + "/.claude/CLAUDE.md"
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
            }
        }
    }
}

extension Notification.Name {
    static let refreshConfig = Notification.Name("refreshConfig")
}
