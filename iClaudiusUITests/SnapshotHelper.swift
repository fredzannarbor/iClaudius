//
//  SnapshotHelper.swift
//  iClaudiusUITests
//
//  macOS-compatible version for Fastlane snapshot integration
//

import Foundation
import XCTest

var deviceLanguage = ""
var locale = ""

func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = false) {
    Snapshot.snapshot(name, waitForLoadingIndicator: waitForLoadingIndicator)
}

enum SnapshotError: Error, LocalizedError {
    case cannotFindHomeDirectory
    case cannotFindSimulatorHomeDirectory
    case cannotAccessSimulatorHomeDirectory(String)
    case cannotRunOnPhysicalDevice

    var errorDescription: String? {
        switch self {
        case .cannotFindHomeDirectory:
            return "Couldn't find home directory"
        case .cannotFindSimulatorHomeDirectory:
            return "Couldn't find simulator home directory"
        case .cannotAccessSimulatorHomeDirectory(let path):
            return "Couldn't access simulator home directory: \(path)"
        case .cannotRunOnPhysicalDevice:
            return "Cannot run on physical device (macOS uses the actual machine)"
        }
    }
}

open class Snapshot: NSObject {
    static var app: XCUIApplication?
    static var waitForAnimations = true
    static var cacheDirectory: URL?
    static var screenshotsDirectory: URL? {
        return cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }

    open class func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        Snapshot.app = app
        Snapshot.waitForAnimations = waitForAnimations

        do {
            let cacheDir = try getCacheDirectory()
            Snapshot.cacheDirectory = cacheDir
            setLanguage(app)
            setLocale(app)
            setLaunchArguments(app)
        } catch {
            NSLog("Snapshot setup error: \(error)")
        }
    }

    class func setLanguage(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else { return }
        let path = cacheDirectory.appendingPathComponent("language.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            deviceLanguage = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
        } catch {
            NSLog("Couldn't detect language from Fastlane (using default): \(error.localizedDescription)")
        }
    }

    class func setLocale(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else { return }
        let path = cacheDirectory.appendingPathComponent("locale.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            locale = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
        } catch {
            NSLog("Couldn't detect locale from Fastlane (using default): \(error.localizedDescription)")
        }

        if locale.isEmpty && !deviceLanguage.isEmpty {
            locale = Locale(identifier: deviceLanguage).identifier
        }

        if !locale.isEmpty {
            app.launchArguments += ["-AppleLocale", "\"\(locale)\""]
        }
    }

    class func setLaunchArguments(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else { return }
        let path = cacheDirectory.appendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArgumentsString = try String(contentsOf: path, encoding: .utf8)
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            let launchArguments = launchArgumentsString.components(separatedBy: "\n")
            launchArguments.forEach { argument in
                let trimmed = argument.trimmingCharacters(in: trimCharacterSet)
                if !trimmed.isEmpty {
                    app.launchArguments.append(trimmed)
                }
            }
        } catch {
            // Ignore if file doesn't exist
        }
    }

    open class func snapshot(_ name: String, waitForLoadingIndicator: Bool = false) {
        guard let app = app else {
            NSLog("XCUIApplication not set, call setupSnapshot first")
            return
        }

        // Wait for animations if configured
        if waitForAnimations {
            sleep(1)
        }

        let screenshot = app.screenshot()
        guard var screenshotsDir = screenshotsDirectory else {
            // Fallback to a default location
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            let fallbackDir = homeDir.appendingPathComponent("Desktop/iClaudius_Screenshots")
            saveScreenshot(screenshot: screenshot, to: fallbackDir, name: name)
            return
        }

        // Add language subdirectory if available
        if !deviceLanguage.isEmpty {
            screenshotsDir = screenshotsDir.appendingPathComponent(deviceLanguage)
        }

        saveScreenshot(screenshot: screenshot, to: screenshotsDir, name: name)
    }

    private class func saveScreenshot(screenshot: XCUIScreenshot, to directory: URL, name: String) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent("\(name).png")
            try screenshot.pngRepresentation.write(to: fileURL)
            NSLog("Screenshot saved: \(fileURL.path)")
        } catch {
            NSLog("Error saving screenshot: \(error)")
        }
    }

    class func getCacheDirectory() throws -> URL {
        // For macOS, use the standard caches directory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let cacheDir = homeDir.appendingPathComponent("Library/Caches/tools.fastlane")
        return cacheDir
    }
}

// MARK: - Snapshot Helper Version
// This is used by Fastlane to check if an update is needed
let SnapshotHelperVersion: [String] = ["1", "0", "0"]
