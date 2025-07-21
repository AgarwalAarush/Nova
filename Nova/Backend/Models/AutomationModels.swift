import Foundation
import CoreGraphics
import AppKit

// MARK: - Automation Command Types

enum AutomationCommand {
    case display(DisplayCommand)
    case application(ApplicationCommand)
    case window(WindowCommand)
    case system(SystemCommand)
    case screenshot(ScreenshotCommand)
    case clipboard(ClipboardCommand)
    case memory(MemoryCommand)
}

enum DisplayCommand {
    case setBrightness(Float)
    case getBrightness
    case setResolution(CGSize, displayID: UInt32? = nil)
    case getDisplayInfo
}

enum ApplicationCommand {
    case launch(bundleIdentifier: String)
    case quit(bundleIdentifier: String, force: Bool = false)
    case activate(bundleIdentifier: String)
    case hide(bundleIdentifier: String)
    case getRunning
    case isRunning(bundleIdentifier: String)
}

enum WindowCommand {
    case resize(windowID: UInt32, size: CGSize)
    case move(windowID: UInt32, position: CGPoint)
    case minimize(windowID: UInt32)
    case maximize(windowID: UInt32)
    case maximizeFrontmostWindow
    case close(windowID: UInt32)
    case getVisible
    case getForApplication(bundleIdentifier: String)
}

enum SystemCommand {
    case setVolume(Float)
    case getVolume
    case sleep
    case wake
    case lockScreen
    case showDesktop
    case getDateTime
}

enum ScreenshotCommand {
    case captureScreen
    case captureWindow(windowID: UInt32)
    case captureSelection
    case getLastScreenshot
}

enum ClipboardCommand {
    case getContent
    case getContentWithMetadata
    case getImage
    case setContent(String)
    case setImage(NSImage)
    case clear
    case hasContent
}

enum MemoryCommand {
    case getUserPreferences
    case addUserPreference(String)
    case updateUserPreferences([String])
    case removeUserPreference(String)
    case clearUserPreferences
}

// MARK: - Data Models

struct RunningApplication: Codable, Identifiable {
    let id: Int32
    let bundleIdentifier: String?
    let localizedName: String?
    let processIdentifier: Int32
    let isActive: Bool
    let isHidden: Bool
    let activationPolicy: ApplicationActivationPolicy
    
    enum ApplicationActivationPolicy: Int, Codable {
        case regular = 0
        case accessory = 1
        case prohibited = 2
    }
}

struct WindowInfo: Codable, Identifiable {
    let id: UInt32
    let title: String?
    let ownerName: String?
    let ownerPID: Int32
    let bounds: CGRect
    let layer: Int
    let isOnScreen: Bool
    let isMinimized: Bool
    let applicationBundleIdentifier: String?
}

struct DisplayInfo: Codable, Identifiable {
    let id: UInt32
    let bounds: CGRect
    let brightness: Float?
    let isMain: Bool
    let name: String?
    let colorSpace: String?
    let refreshRate: Double?
}

struct SystemVolume: Codable {
    let level: Float
    let isMuted: Bool
    let hasHardwareControl: Bool
}

struct ScreenshotInfo {
    let image: NSImage
    let timestamp: Date
    let displayID: UInt32?
    let windowID: UInt32?
    let bounds: CGRect
}

struct ClipboardContent {
    let content: String
    let type: String
    let timestamp: Date
    let hasImage: Bool
}

struct ClipboardImage {
    let image: NSImage
    let timestamp: Date
}

struct DateTimeInfo {
    let timestamp: Date
    let timeZone: TimeZone
    let formattedString: String
    let unixTimestamp: TimeInterval
    let iso8601String: String
}

// MARK: - Automation Results

enum AutomationResult {
    case success
    case displayInfo([DisplayInfo])
    case brightness(Float)
    case runningApplications([RunningApplication])
    case applicationRunning(Bool)
    case windowInfo([WindowInfo])
    case volume(SystemVolume)
    case screenshot(ScreenshotInfo)
    case clipboardContent(ClipboardContent)
    case clipboardImage(ClipboardImage)
    case clipboardHasContent(Bool)
    case dateTime(DateTimeInfo)
    case userPreferences([String])
    case error(AutomationError)
}

// MARK: - Automation Errors

enum AutomationError: Error, LocalizedError {
    case permissionDenied(requiredPermission: String)
    case applicationNotFound(bundleIdentifier: String)
    case windowNotFound(windowID: UInt32)
    case displayNotFound(displayID: UInt32)
    case operationNotSupported(operation: String)
    case systemError(underlying: Error)
    case invalidParameters(description: String)
    case timeout
    case accessibilityNotEnabled
    case adminPrivilegesRequired
    case screenshotCaptureFailed
    case screenRecordingNotEnabled
    case clipboardEmpty
    case clipboardAccessFailed
    case unsupportedClipboardFormat
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let permission):
            return "Permission denied: \(permission) access is required"
        case .applicationNotFound(let bundleId):
            return "Application not found: \(bundleId)"
        case .windowNotFound(let windowId):
            return "Window not found: \(windowId)"
        case .displayNotFound(let displayId):
            return "Display not found: \(displayId)"
        case .operationNotSupported(let operation):
            return "Operation not supported: \(operation)"
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        case .invalidParameters(let description):
            return "Invalid parameters: \(description)"
        case .timeout:
            return "Operation timed out"
        case .accessibilityNotEnabled:
            return "Accessibility access is not enabled. Please grant access in System Preferences > Security & Privacy > Accessibility"
        case .adminPrivilegesRequired:
            return "Administrator privileges are required for this operation"
        case .screenshotCaptureFailed:
            return "Failed to capture screenshot"
        case .screenRecordingNotEnabled:
            return "Screen recording permission is not granted. Please enable in System Preferences > Security & Privacy > Screen Recording"
        case .clipboardEmpty:
            return "Clipboard is empty"
        case .clipboardAccessFailed:
            return "Failed to access clipboard"
        case .unsupportedClipboardFormat:
            return "Unsupported clipboard format"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied, .accessibilityNotEnabled, .screenRecordingNotEnabled:
            return "Grant the required permissions in System Preferences"
        case .applicationNotFound:
            return "Verify the application is installed and the bundle identifier is correct"
        case .adminPrivilegesRequired:
            return "Run the application with administrator privileges or use a different operation"
        case .screenshotCaptureFailed:
            return "Ensure screen recording permissions are granted and try again"
        case .clipboardEmpty:
            return "Copy content to the clipboard first"
        case .clipboardAccessFailed:
            return "Restart the application and try again"
        case .unsupportedClipboardFormat:
            return "Copy content in a supported format (text, image, or URL)"
        default:
            return nil
        }
    }
}

// MARK: - Permission Status

enum PermissionStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}

struct AutomationPermissions {
    var accessibility: PermissionStatus = .notDetermined
    var systemEvents: PermissionStatus = .notDetermined
    var adminPrivileges: PermissionStatus = .notDetermined
    var screenRecording: PermissionStatus = .notDetermined
    
    var hasBasicAccess: Bool {
        return accessibility == .authorized && systemEvents == .authorized
    }
    
    var hasFullAccess: Bool {
        return hasBasicAccess && adminPrivileges == .authorized
    }
    
    var hasScreenshotAccess: Bool {
        return screenRecording == .authorized
    }
    
    var hasClipboardAccess: Bool {
        return true // Clipboard access doesn't require special permissions
    }
}