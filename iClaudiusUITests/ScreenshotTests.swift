import XCTest

class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testCaptureScreenshots() throws {
        // Wait for app to fully load
        sleep(3)

        // 1. Overview screen (default) - always capture this
        snapshot("01_Overview")

        // Try to find sidebar items using different strategies
        // For SwiftUI NavigationSplitView, items might be in lists, outlines, or tables

        // Strategy 1: Look for any text element with matching label
        let claudeMDText = app.staticTexts["CLAUDE.md Files"]
        if claudeMDText.waitForExistence(timeout: 3) && claudeMDText.isHittable {
            claudeMDText.click()
            sleep(2)
            snapshot("02_ClaudeMD_Files")
        } else {
            // Try finding in the window's descendants
            let allButtons = app.buttons.allElementsBoundByIndex
            for button in allButtons {
                if button.label.contains("CLAUDE.md") || button.identifier.contains("CLAUDE.md") {
                    button.click()
                    sleep(2)
                    snapshot("02_ClaudeMD_Files")
                    break
                }
            }
        }

        // 2. Custom Slash Commands
        let commandsText = app.staticTexts["Custom Slash Commands"]
        if commandsText.waitForExistence(timeout: 2) && commandsText.isHittable {
            commandsText.click()
            sleep(2)
            snapshot("03_Commands")
        }

        // 3. Safety Dashboard
        let safetyText = app.staticTexts["Safety Dashboard"]
        if safetyText.waitForExistence(timeout: 2) && safetyText.isHittable {
            safetyText.click()
            sleep(2)
            snapshot("04_Safety_Dashboard")
        }

        // 4. Execution Traces
        let tracesText = app.staticTexts["Execution Traces"]
        if tracesText.waitForExistence(timeout: 2) && tracesText.isHittable {
            tracesText.click()
            sleep(2)
            snapshot("05_Execution_Traces")
        }

        // 5. Autonomous Tuning
        let autoText = app.staticTexts["Autonomous Tuning"]
        if autoText.waitForExistence(timeout: 2) && autoText.isHittable {
            autoText.click()
            sleep(2)
            snapshot("06_Autonomous_Tuning")
        }

        // If navigation didn't work, at least we have the Overview screenshot
    }
}
