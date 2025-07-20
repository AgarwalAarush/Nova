import AVFoundation
import Foundation

@MainActor
class AudioRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var hasPermission = false
    @Published var audioLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var levelTimer: Timer?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        // Configure audio session for recording
        configureAudioSession()
        
        // Check actual permission status
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        hasPermission = (authStatus == .authorized)
        
        if authStatus != .authorized {
            print("🎤 ⚠️ Microphone permission not granted. Status: \(authStatus)")
        }
    }
    
    private func configureAudioSession() {
        print("🎤 Configuring audio session for recording...")
        
        // On macOS, we need to ensure we have the proper audio session setup
        // This will help with microphone access and recording quality
        validateAudioInputDevices()
    }
    
    private func validateAudioInputDevices() {
        print("🎤 Validating audio input devices...")
        
        // Use AVCaptureDeviceDiscoverySession instead of deprecated devices(for:)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        
        let inputDevices = discoverySession.devices
        print("🎤 Available audio input devices: \(inputDevices.count)")
        
        if inputDevices.isEmpty {
            print("🎤 ❌ No audio input devices found")
            return
        }
        
        // List all devices with detailed info
        for (index, device) in inputDevices.enumerated() {
            print("🎤 Device \(index + 1): \(device.localizedName)")
            print("🎤   - Unique ID: \(device.uniqueID)")
            print("🎤   - Model ID: \(device.modelID)")
            print("🎤   - Connected: \(device.isConnected)")
            
            // Check if device is in use
            if device.isInUseByAnotherApplication {
                print("🎤   - ⚠️ Device is in use by another application")
            }
            
            // Check supported formats using updated API
            let formats = device.formats
            print("🎤   - Supported formats: \(formats.count)")
        }
        
        // Try to find the default microphone
        if let defaultDevice = AVCaptureDevice.default(for: .audio) {
            print("🎤 ✅ Default audio device: \(defaultDevice.localizedName)")
            
            // Check if default device has proper configuration
            do {
                try defaultDevice.lockForConfiguration()
                print("🎤 ✅ Successfully locked default device for configuration")
                defaultDevice.unlockForConfiguration()
            } catch {
                print("🎤 ❌ Failed to lock default device: \(error)")
            }
        } else {
            print("🎤 ❌ No default audio device found")
        }
        
        // Check microphone permission status specifically
        checkMicrophonePermission()
    }
    
    private func checkMicrophonePermission() {
        print("🎤 Checking microphone permission status...")
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch authStatus {
        case .authorized:
            print("🎤 ✅ Microphone access authorized")
        case .denied:
            print("🎤 ❌ Microphone access denied")
        case .restricted:
            print("🎤 ❌ Microphone access restricted")
        case .notDetermined:
            print("🎤 ⚠️ Microphone permission not determined - will request on first use")
        @unknown default:
            print("🎤 ❓ Unknown microphone permission status")
        }
    }
    
    func requestPermission() async -> Bool {
        print("🎤 Requesting microphone permission...")
        
        // Check current status first
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        print("🎤 Current auth status before request: \(currentStatus)")
        
        // If already authorized, return true
        if currentStatus == .authorized {
            print("🎤 Already authorized")
            hasPermission = true
            return true
        }
        
        // If denied, we can't request again - user must go to System Settings
        if currentStatus == .denied {
            print("🎤 ❌ Permission previously denied - user must enable in System Settings")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    print("🎤 Permission request result: \(granted)")
                    let newStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                    print("🎤 New auth status after request: \(newStatus)")
                    
                    self?.hasPermission = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func startRecording() async throws -> URL {
        print("🎤 Starting recording process...")
        
        // Check permission before recording
        if !hasPermission {
            print("🎤 ❌ No microphone permission - requesting...")
            let granted = await requestPermission()
            if !granted {
                print("🎤 ❌ Microphone permission denied by user")
                throw AudioRecorderError.permissionDenied
            }
        }
        
        // Double-check current permission status
        let currentAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if currentAuthStatus != .authorized {
            print("🎤 ❌ Microphone not authorized. Status: \(currentAuthStatus)")
            throw AudioRecorderError.permissionDenied
        }
        
        print("🎤 ✅ Microphone permission confirmed - proceeding with recording")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("dictation_\(UUID().uuidString).wav")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ] as [String : Any]
        
        print("🎤 Recording settings: \(settings)")
        
        guard let url = recordingURL else {
            print("🎤 ❌ Failed to create recording URL")
            throw AudioRecorderError.urlCreationFailed
        }
        
        print("🎤 Recording to: \(url.path)")
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            
            guard let recorder = audioRecorder else {
                print("🎤 ❌ Failed to create AVAudioRecorder")
                throw AudioRecorderError.recordingFailed
            }
            
            // Enable metering to monitor audio levels
            recorder.isMeteringEnabled = true
            
            let success = recorder.record()
            if !success {
                print("🎤 ❌ AVAudioRecorder.record() returned false")
                throw AudioRecorderError.recordingFailed
            }
            
            print("🎤 ✅ Recording started successfully")
            isRecording = true
            
            // Start monitoring audio levels
            startLevelMonitoring()
            
            return url
        } catch {
            print("🎤 ❌ Recording failed with error: \(error)")
            // If recording fails, it might be due to permission issues
            throw AudioRecorderError.permissionDenied
        }
    }
    
    func stopRecording() -> URL? {
        print("🎤 Stopping recording...")
        
        // Stop level monitoring
        stopLevelMonitoring()
        
        audioRecorder?.stop()
        isRecording = false
        
        // Log final recording info
        if let url = recordingURL {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? NSNumber {
                    print("🎤 Recording stopped. File size: \(fileSize.intValue) bytes")
                    
                    if fileSize.intValue < 1000 {
                        print("🎤 ⚠️ Warning: Very small file size, may indicate no audio was recorded")
                    }
                }
            } catch {
                print("🎤 ❌ Error checking file attributes: \(error)")
            }
        }
        
        return recordingURL
    }
    
    func cancelRecording() async {
        print("🎤 Cancelling recording...")
        
        // Stop level monitoring
        stopLevelMonitoring()
        
        audioRecorder?.stop()
        isRecording = false
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    private func startLevelMonitoring() {
        print("🎤 Starting audio level monitoring...")
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevel()
            }
        }
    }
    
    private func stopLevelMonitoring() {
        print("🎤 Stopping audio level monitoring...")
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0.0
    }
    
    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)
        
        // Convert decibel to linear scale (0.0 to 1.0)
        let normalizedLevel = max(0.0, (averagePower + 80) / 80)
        audioLevel = normalizedLevel
        
        // Log audio levels periodically
        if Int(Date().timeIntervalSince1970 * 10) % 10 == 0 { // Every second
            print("🎤 Audio levels - Average: \(String(format: "%.1f", averagePower))dB, Peak: \(String(format: "%.1f", peakPower))dB, Normalized: \(String(format: "%.3f", normalizedLevel))")
            
            if averagePower < -50 {
                print("🎤 ⚠️ Very low audio input detected - check microphone")
            }
        }
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            isRecording = false
            if let error = error {
                print("Audio recording error: \(error)")
            }
        }
    }
}

enum AudioRecorderError: Error, LocalizedError {
    case permissionDenied
    case urlCreationFailed
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied or unavailable"
        case .urlCreationFailed:
            return "Failed to create recording URL"
        case .recordingFailed:
            return "Recording failed"
        }
    }
}