import Foundation
import CoreGraphics
import AppKit

@MainActor
protocol SystemAutomationService: ObservableObject {
    
    // MARK: - Permission Management
    
    var permissions: AutomationPermissions { get }
    
    func requestPermissions() async -> Bool
    func checkPermissionStatus() async -> AutomationPermissions
    
    // MARK: - Display Management
    
    func setBrightness(_ level: Float, displayID: UInt32?) async throws
    func getBrightness(displayID: UInt32?) async throws -> Float
    func getDisplayInfo() async throws -> [DisplayInfo]
    func setDisplayResolution(_ size: CGSize, displayID: UInt32?) async throws
    
    // MARK: - Application Management
    
    func launchApplication(_ bundleIdentifier: String) async throws
    func quitApplication(_ bundleIdentifier: String, force: Bool) async throws
    func activateApplication(_ bundleIdentifier: String) async throws
    func hideApplication(_ bundleIdentifier: String) async throws
    func getRunningApplications() async throws -> [RunningApplication]
    func isApplicationRunning(_ bundleIdentifier: String) async throws -> Bool
    
    // MARK: - Window Management
    
    func resizeWindow(_ windowID: UInt32, to size: CGSize) async throws
    func moveWindow(_ windowID: UInt32, to position: CGPoint) async throws
    func minimizeWindow(_ windowID: UInt32) async throws
    func maximizeWindow(_ windowID: UInt32) async throws
    func closeWindow(_ windowID: UInt32) async throws
    func getVisibleWindows() async throws -> [WindowInfo]
    func getWindowsForApplication(_ bundleIdentifier: String) async throws -> [WindowInfo]
    
    // MARK: - System Control
    
    func setSystemVolume(_ level: Float) async throws
    func getSystemVolume() async throws -> SystemVolume
    func sleepSystem() async throws
    func lockScreen() async throws
    func showDesktop() async throws
    func getDateTime() async throws -> DateTimeInfo
    
    // MARK: - Screenshot Management
    
    func captureScreen() async throws -> ScreenshotInfo
    func captureWindow(_ windowID: UInt32) async throws -> ScreenshotInfo
    func captureSelection() async throws -> ScreenshotInfo
    func getLastScreenshot() async throws -> ScreenshotInfo?
    
    // MARK: - Clipboard Management
    
    func getClipboardContent() async throws -> ClipboardContent
    func getClipboardContentWithMetadata() async throws -> ClipboardContent
    func getClipboardImage() async throws -> ClipboardImage?
    func setClipboardContent(_ content: String) async throws
    func setClipboardImage(_ image: NSImage) async throws
    func clearClipboard() async throws
    func hasClipboardContent() async throws -> Bool
    
    // MARK: - Memory Management
    
    func getUserPreferences() async throws -> [String]
    func addUserPreference(_ preference: String) async throws
    func updateUserPreferences(_ preferences: [String]) async throws
    func removeUserPreference(_ preference: String) async throws
    func clearUserPreferences() async throws
    
    // MARK: - Generic Command Interface
    
    func executeCommand(_ command: AutomationCommand) async -> AutomationResult
}

// MARK: - Default Implementations

extension SystemAutomationService {
    
    func executeCommand(_ command: AutomationCommand) async -> AutomationResult {
        do {
            switch command {
            case .display(let displayCommand):
                return try await executeDisplayCommand(displayCommand)
            case .application(let appCommand):
                return try await executeApplicationCommand(appCommand)
            case .window(let windowCommand):
                return try await executeWindowCommand(windowCommand)
            case .system(let systemCommand):
                return try await executeSystemCommand(systemCommand)
            case .screenshot(let screenshotCommand):
                return try await executeScreenshotCommand(screenshotCommand)
            case .clipboard(let clipboardCommand):
                return try await executeClipboardCommand(clipboardCommand)
            case .memory(let memoryCommand):
                return try await executeMemoryCommand(memoryCommand)
            }
        } catch {
            if let automationError = error as? AutomationError {
                return .error(automationError)
            } else {
                return .error(.systemError(underlying: error))
            }
        }
    }
    
    private func executeDisplayCommand(_ command: DisplayCommand) async throws -> AutomationResult {
        switch command {
        case .setBrightness(let level):
            try await setBrightness(level, displayID: nil)
            return .success
        case .getBrightness:
            let brightness = try await getBrightness(displayID: nil)
            return .brightness(brightness)
        case .setResolution(let size, let displayID):
            try await setDisplayResolution(size, displayID: displayID)
            return .success
        case .getDisplayInfo:
            let displays = try await getDisplayInfo()
            return .displayInfo(displays)
        }
    }
    
    private func executeApplicationCommand(_ command: ApplicationCommand) async throws -> AutomationResult {
        switch command {
        case .launch(let bundleId):
            try await launchApplication(bundleId)
            return .success
        case .quit(let bundleId, let force):
            try await quitApplication(bundleId, force: force)
            return .success
        case .activate(let bundleId):
            try await activateApplication(bundleId)
            return .success
        case .hide(let bundleId):
            try await hideApplication(bundleId)
            return .success
        case .getRunning:
            let apps = try await getRunningApplications()
            return .runningApplications(apps)
        case .isRunning(let bundleId):
            let isRunning = try await isApplicationRunning(bundleId)
            return .applicationRunning(isRunning)
        }
    }
    
    private func executeWindowCommand(_ command: WindowCommand) async throws -> AutomationResult {
        switch command {
        case .resize(let windowID, let size):
            try await resizeWindow(windowID, to: size)
            return .success
        case .move(let windowID, let position):
            try await moveWindow(windowID, to: position)
            return .success
        case .minimize(let windowID):
            try await minimizeWindow(windowID)
            return .success
        case .maximize(let windowID):
            try await maximizeWindow(windowID)
            return .success
        case .close(let windowID):
            try await closeWindow(windowID)
            return .success
        case .getVisible:
            let windows = try await getVisibleWindows()
            return .windowInfo(windows)
        case .getForApplication(let bundleId):
            let windows = try await getWindowsForApplication(bundleId)
            return .windowInfo(windows)
        }
    }
    
    private func executeSystemCommand(_ command: SystemCommand) async throws -> AutomationResult {
        switch command {
        case .setVolume(let level):
            try await setSystemVolume(level)
            return .success
        case .getVolume:
            let volume = try await getSystemVolume()
            return .volume(volume)
        case .sleep:
            try await sleepSystem()
            return .success
        case .wake:
            throw AutomationError.operationNotSupported(operation: "Wake system")
        case .lockScreen:
            try await lockScreen()
            return .success
        case .showDesktop:
            try await showDesktop()
            return .success
        case .getDateTime:
            let dateTime = try await getDateTime()
            return .dateTime(dateTime)
        }
    }
    
    private func executeScreenshotCommand(_ command: ScreenshotCommand) async throws -> AutomationResult {
        switch command {
        case .captureScreen:
            let screenshot = try await captureScreen()
            return .screenshot(screenshot)
        case .captureWindow(let windowID):
            let screenshot = try await captureWindow(windowID)
            return .screenshot(screenshot)
        case .captureSelection:
            let screenshot = try await captureSelection()
            return .screenshot(screenshot)
        case .getLastScreenshot:
            if let screenshot = try await getLastScreenshot() {
                return .screenshot(screenshot)
            } else {
                throw AutomationError.screenshotCaptureFailed
            }
        }
    }
    
    private func executeClipboardCommand(_ command: ClipboardCommand) async throws -> AutomationResult {
        switch command {
        case .getContent:
            let content = try await getClipboardContent()
            return .clipboardContent(content)
        case .getContentWithMetadata:
            let content = try await getClipboardContentWithMetadata()
            return .clipboardContent(content)
        case .getImage:
            if let image = try await getClipboardImage() {
                return .clipboardImage(image)
            } else {
                throw AutomationError.clipboardEmpty
            }
        case .setContent(let content):
            try await setClipboardContent(content)
            return .success
        case .setImage(let image):
            try await setClipboardImage(image)
            return .success
        case .clear:
            try await clearClipboard()
            return .success
        case .hasContent:
            let hasContent = try await hasClipboardContent()
            return .clipboardHasContent(hasContent)
        }
    }
    
    private func executeMemoryCommand(_ command: MemoryCommand) async throws -> AutomationResult {
        switch command {
        case .getUserPreferences:
            let preferences = try await getUserPreferences()
            return .userPreferences(preferences)
        case .addUserPreference(let preference):
            try await addUserPreference(preference)
            return .success
        case .updateUserPreferences(let preferences):
            try await updateUserPreferences(preferences)
            return .success
        case .removeUserPreference(let preference):
            try await removeUserPreference(preference)
            return .success
        case .clearUserPreferences:
            try await clearUserPreferences()
            return .success
        }
    }
}