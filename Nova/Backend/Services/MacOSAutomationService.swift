import Foundation
import CoreGraphics
import ApplicationServices
import IOKit
import IOKit.graphics
import IOKit.pwr_mgt
import AppKit
import OSLog
import ScreenCaptureKit

@MainActor
final class MacOSAutomationService: SystemAutomationService {
    
    private let logger = Logger(subsystem: "com.nova.automation", category: "MacOSAutomationService")
    
    @Published private(set) var permissions = AutomationPermissions()
    
    // Integrate existing services
    private let screenshotService = ScreenshotService.shared
    private let clipboardService = ClipboardService.shared
    
    // Store last screenshot for retrieval
    private var lastScreenshot: ScreenshotInfo?
    
    init() {
        Task {
            await updatePermissionStatus()
        }
    }
    
    // MARK: - Permission Management
    
    func requestPermissions() async -> Bool {
        await updatePermissionStatus()
        
        if permissions.accessibility != .authorized {
            await requestAccessibilityPermission()
        }
        
        await updatePermissionStatus()
        return permissions.hasBasicAccess
    }
    
    func checkPermissionStatus() async -> AutomationPermissions {
        await updatePermissionStatus()
        return permissions
    }
    
    private func updatePermissionStatus() async {
        permissions.accessibility = checkAccessibilityPermission()
        permissions.systemEvents = .authorized // System Events generally available
        permissions.adminPrivileges = .notDetermined // Would need runtime check
        permissions.screenRecording = await checkScreenRecordingPermission()
    }
    
    private func checkAccessibilityPermission() -> PermissionStatus {
        let trusted = AXIsProcessTrusted()
        return trusted ? .authorized : .denied
    }
    
    private func requestAccessibilityPermission() async {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func checkScreenRecordingPermission() async -> PermissionStatus {
        // ScreenCaptureKit permission check
        do {
            let _ = try await SCShareableContent.current
            return .authorized
        } catch {
            return .denied
        }
    }
    
    // MARK: - Display Management
    
    func setBrightness(_ level: Float, displayID: UInt32? = nil) async throws {
        let clampedLevel = max(0.0, min(1.0, level))
        
        if let displayID = displayID {
            try setBrightnessForDisplay(clampedLevel, displayID: displayID)
        } else {
            try setBrightnessForMainDisplay(clampedLevel)
        }
        
        logger.info("Set brightness to \(clampedLevel) for display \(displayID?.description ?? "main")")
    }
    
    func getBrightness(displayID: UInt32? = nil) async throws -> Float {
        if let displayID = displayID {
            return try getBrightnessForDisplay(displayID: displayID)
        } else {
            return try getBrightnessForMainDisplay()
        }
    }
    
    func getDisplayInfo() async throws -> [DisplayInfo] {
        var displays: [DisplayInfo] = []
        
        let maxDisplays: UInt32 = 16
        var displayIDs = Array<CGDirectDisplayID>(repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0
        
        let result = CGGetActiveDisplayList(maxDisplays, &displayIDs, &displayCount)
        guard result == .success else {
            throw AutomationError.systemError(underlying: NSError(domain: "CGError", code: Int(result.rawValue)))
        }
        
        for i in 0..<Int(displayCount) {
            let displayID = displayIDs[i]
            let bounds = CGDisplayBounds(displayID)
            let isMain = CGDisplayIsMain(displayID) != 0
            
            var brightness: Float?
            do {
                brightness = try getBrightnessForDisplay(displayID: displayID)
            } catch {
                brightness = nil // External displays may not support brightness control
            }
            
            let displayInfo = DisplayInfo(
                id: displayID,
                bounds: bounds,
                brightness: brightness,
                isMain: isMain,
                name: getDisplayName(displayID: displayID),
                colorSpace: nil,
                refreshRate: nil
            )
            
            displays.append(displayInfo)
        }
        
        return displays
    }
    
    func setDisplayResolution(_ size: CGSize, displayID: UInt32? = nil) async throws {
        throw AutomationError.operationNotSupported(operation: "Display resolution changing requires additional privileges")
    }
    
    // MARK: - Application Management
    
    func launchApplication(_ bundleIdentifier: String) async throws {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw AutomationError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }
        
        do {
            try await NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
            logger.info("Launched application: \(bundleIdentifier)")
        } catch {
            throw AutomationError.systemError(underlying: error)
        }
    }
    
    func quitApplication(_ bundleIdentifier: String, force: Bool = false) async throws {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw AutomationError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }
        
        let success = force ? app.forceTerminate() : app.terminate()
        if !success {
            throw AutomationError.systemError(underlying: NSError(domain: "AppTermination", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to terminate application"]))
        }
        
        logger.info("Quit application: \(bundleIdentifier) (force: \(force))")
    }
    
    func activateApplication(_ bundleIdentifier: String) async throws {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw AutomationError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }
        
        let success = app.activate()
        if !success {
            throw AutomationError.systemError(underlying: NSError(domain: "AppActivation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to activate application"]))
        }
        
        logger.info("Activated application: \(bundleIdentifier)")
    }
    
    func hideApplication(_ bundleIdentifier: String) async throws {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw AutomationError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }
        
        let success = app.hide()
        if !success {
            throw AutomationError.systemError(underlying: NSError(domain: "AppHiding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to hide application"]))
        }
        
        logger.info("Hid application: \(bundleIdentifier)")
    }
    
    func getRunningApplications() async throws -> [RunningApplication] {
        let runningApps = NSWorkspace.shared.runningApplications
        
        return runningApps.compactMap { app in
            guard let bundleId = app.bundleIdentifier else { return nil }
            
            return RunningApplication(
                id: app.processIdentifier,
                bundleIdentifier: bundleId,
                localizedName: app.localizedName,
                processIdentifier: app.processIdentifier,
                isActive: app.isActive,
                isHidden: app.isHidden,
                activationPolicy: RunningApplication.ApplicationActivationPolicy(rawValue: app.activationPolicy.rawValue) ?? .regular
            )
        }
    }
    
    func isApplicationRunning(_ bundleIdentifier: String) async throws -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }
    
    // MARK: - Window Management (Placeholder - requires Accessibility)
    
    func resizeWindow(_ windowID: UInt32, to size: CGSize) async throws {
        guard permissions.accessibility == .authorized else {
            throw AutomationError.accessibilityNotEnabled
        }
        
        throw AutomationError.operationNotSupported(operation: "Window resizing requires additional Accessibility API implementation")
    }
    
    func moveWindow(_ windowID: UInt32, to position: CGPoint) async throws {
        guard permissions.accessibility == .authorized else {
            throw AutomationError.accessibilityNotEnabled
        }
        
        throw AutomationError.operationNotSupported(operation: "Window moving requires additional Accessibility API implementation")
    }
    
    func minimizeWindow(_ windowID: UInt32) async throws {
        guard permissions.accessibility == .authorized else {
            throw AutomationError.accessibilityNotEnabled
        }
        
        throw AutomationError.operationNotSupported(operation: "Window minimizing requires additional Accessibility API implementation")
    }
    
    func maximizeWindow(_ windowID: UInt32) async throws {
        guard permissions.accessibility == .authorized else {
            throw AutomationError.accessibilityNotEnabled
        }
        
        throw AutomationError.operationNotSupported(operation: "Window maximizing requires additional Accessibility API implementation")
    }
    
    func closeWindow(_ windowID: UInt32) async throws {
        guard permissions.accessibility == .authorized else {
            throw AutomationError.accessibilityNotEnabled
        }
        
        throw AutomationError.operationNotSupported(operation: "Window closing requires additional Accessibility API implementation")
    }
    
    func getVisibleWindows() async throws -> [WindowInfo] {
        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
        
        return windowList.compactMap { windowDict in
            guard let windowID = windowDict[kCGWindowNumber as String] as? UInt32,
                  let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else {
                return nil
            }
            
            let title = windowDict[kCGWindowName as String] as? String
            let ownerName = windowDict[kCGWindowOwnerName as String] as? String
            let ownerPID = windowDict[kCGWindowOwnerPID as String] as? Int32 ?? 0
            let layer = windowDict[kCGWindowLayer as String] as? Int ?? 0
            
            return WindowInfo(
                id: windowID,
                title: title,
                ownerName: ownerName,
                ownerPID: ownerPID,
                bounds: bounds,
                layer: layer,
                isOnScreen: true,
                isMinimized: false,
                applicationBundleIdentifier: nil
            )
        }
    }
    
    func getWindowsForApplication(_ bundleIdentifier: String) async throws -> [WindowInfo] {
        let allWindows = try await getVisibleWindows()
        let runningApps = try await getRunningApplications()
        
        guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw AutomationError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }
        
        return allWindows.filter { $0.ownerPID == app.processIdentifier }
    }
    
    // MARK: - System Control
    
    func setSystemVolume(_ level: Float) async throws {
        throw AutomationError.operationNotSupported(operation: "System volume control requires additional AudioUnit implementation")
    }
    
    func getSystemVolume() async throws -> SystemVolume {
        throw AutomationError.operationNotSupported(operation: "System volume control requires additional AudioUnit implementation")
    }
    
    func sleepSystem() async throws {
        let result = IOPMSleepSystem(IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL)))
        if result != kIOReturnSuccess {
            throw AutomationError.systemError(underlying: NSError(domain: "IOKit", code: Int(result)))
        }
        
        logger.info("System sleep initiated")
    }
    
    func lockScreen() async throws {
        let task = Process()
        task.launchPath = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        task.arguments = ["-suspend"]
        task.launch()
        
        logger.info("Screen lock initiated")
    }
    
    func showDesktop() async throws {
        throw AutomationError.operationNotSupported(operation: "Show Desktop requires Mission Control API implementation")
    }
    
    // MARK: - Screenshot Management
    
    func captureScreen() async throws -> ScreenshotInfo {
        guard permissions.hasScreenshotAccess else {
            throw AutomationError.screenRecordingNotEnabled
        }
        
        guard let image = await screenshotService.captureScreen() else {
            throw AutomationError.screenshotCaptureFailed
        }
        
        let screenshotInfo = ScreenshotInfo(
            image: image,
            timestamp: Date(),
            displayID: CGMainDisplayID(),
            windowID: nil,
            bounds: CGDisplayBounds(CGMainDisplayID())
        )
        
        lastScreenshot = screenshotInfo
        logger.info("Screen captured successfully")
        
        return screenshotInfo
    }
    
    func captureWindow(_ windowID: UInt32) async throws -> ScreenshotInfo {
        guard permissions.hasScreenshotAccess else {
            throw AutomationError.screenRecordingNotEnabled
        }
        
        throw AutomationError.operationNotSupported(operation: "Window capture not yet implemented")
    }
    
    func captureSelection() async throws -> ScreenshotInfo {
        guard permissions.hasScreenshotAccess else {
            throw AutomationError.screenRecordingNotEnabled
        }
        
        throw AutomationError.operationNotSupported(operation: "Selection capture not yet implemented")
    }
    
    func getLastScreenshot() async throws -> ScreenshotInfo? {
        return lastScreenshot
    }
    
    // MARK: - Clipboard Management
    
    func getClipboardContent() async throws -> ClipboardContent {
        let content = clipboardService.getCurrentClipboardContent()
        let hasImage = clipboardService.getClipboardImage() != nil
        
        return ClipboardContent(
            content: content,
            type: "string",
            timestamp: Date(),
            hasImage: hasImage
        )
    }
    
    func getClipboardContentWithMetadata() async throws -> ClipboardContent {
        let (content, type) = clipboardService.getClipboardContentWithMetadata()
        let hasImage = clipboardService.getClipboardImage() != nil
        
        return ClipboardContent(
            content: content,
            type: type,
            timestamp: Date(),
            hasImage: hasImage
        )
    }
    
    func getClipboardImage() async throws -> ClipboardImage? {
        guard let image = clipboardService.getClipboardImage() else {
            return nil
        }
        
        return ClipboardImage(
            image: image,
            timestamp: Date()
        )
    }
    
    func setClipboardContent(_ content: String) async throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        logger.info("Clipboard content set")
    }
    
    func setClipboardImage(_ image: NSImage) async throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(image.tiffRepresentation, forType: .tiff)
        
        logger.info("Clipboard image set")
    }
    
    func clearClipboard() async throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        logger.info("Clipboard cleared")
    }
    
    func hasClipboardContent() async throws -> Bool {
        return clipboardService.hasContent
    }
}

// MARK: - Private Brightness Helpers

private extension MacOSAutomationService {
    
    func setBrightnessForMainDisplay(_ level: Float) throws {
        // For now, brightness control requires additional system privileges
        
        throw AutomationError.operationNotSupported(operation: "Brightness control requires system privileges and IOKit integration. Use System Preferences > Displays for now.")
    }
    
    func getBrightnessForMainDisplay() throws -> Float {
        // Placeholder implementation - brightness reading requires IOKit privileges
        throw AutomationError.operationNotSupported(operation: "Brightness reading requires system privileges and IOKit integration")
    }
    
    func setBrightnessForDisplay(_ level: Float, displayID: UInt32) throws {
        throw AutomationError.operationNotSupported(operation: "Specific display brightness control not yet implemented")
    }
    
    func getBrightnessForDisplay(displayID: UInt32) throws -> Float {
        throw AutomationError.operationNotSupported(operation: "External display brightness reading not yet implemented")
    }
    
    func getDisplayName(displayID: UInt32) -> String? {
        return nil // Would require additional CoreDisplay framework integration
    }
    
    // MARK: - System Control Implementation
    
    internal func getDateTime() async throws -> DateTimeInfo {
        let now = Date()
        let timeZone = TimeZone.current
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        
        let iso8601Formatter = ISO8601DateFormatter()
        
        return DateTimeInfo(
            timestamp: now,
            timeZone: timeZone,
            formattedString: formatter.string(from: now),
            unixTimestamp: now.timeIntervalSince1970,
            iso8601String: iso8601Formatter.string(from: now)
        )
    }
    
    // MARK: - Memory Management Implementation
    
    internal func getUserPreferences() async throws -> [String] {
        return AppConfig.shared.getUserPreferences()
    }
    
    internal func addUserPreference(_ preference: String) async throws {
        AppConfig.shared.addUserPreference(preference)
    }
    
    internal func updateUserPreferences(_ preferences: [String]) async throws {
        AppConfig.shared.updateUserPreferences(preferences)
    }
    
    internal func removeUserPreference(_ preference: String) async throws {
        AppConfig.shared.removeUserPreference(preference)
    }
    
    internal func clearUserPreferences() async throws {
        AppConfig.shared.clearUserPreferences()
    }
}