//
//  ContinuousAudioService.swift
//  Nova
//
//  Provides continuous audio monitoring with voice activity detection
//  and automatic recording of speech segments
//

import Foundation
import AVFoundation

protocol ContinuousAudioServiceDelegate: AnyObject {
    /// Called when a voice activity segment is captured and ready for transcription
    /// - Parameter audioURL: URL to the temporary audio file containing the speech
    func didCaptureVoiceSegment(audioURL: URL)
    
    /// Called when voice activity detection state changes
    /// - Parameter isActive: True when voice activity is detected
    func voiceActivityDidChange(isActive: Bool)
    
    /// Called when an error occurs during continuous monitoring
    /// - Parameter error: The error that occurred
    func continuousAudioDidEncounterError(_ error: Error)
}

@MainActor
class ContinuousAudioService: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var isMonitoring: Bool = false
    @Published var isVoiceActive: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var hasPermission: Bool = false
    
    // MARK: - Private Properties
    
    weak var delegate: ContinuousAudioServiceDelegate?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var silenceDetectionService: SilenceDetectionService
    
    // Audio buffer management
    private var circularBuffer: CircularAudioBuffer
    private var currentRecordingBuffer: [Data] = []
    private var isRecordingSegment: Bool = false
    
    // Audio format configuration
    private let sampleRate: Double = 16000.0
    private let channels: AVAudioChannelCount = 1
    private let chunkSize: Int = 1280 // 80ms at 16kHz
    
    // Recording state
    private var voiceSegmentStartTime: Date?
    private var lastVoiceActivityTime: Date?
    
    // MARK: - Initialization
    
    override init() {
        self.silenceDetectionService = SilenceDetectionService()
        self.circularBuffer = CircularAudioBuffer(capacity: 32) // Store ~2.5 seconds of audio
        super.init()
        
        checkPermissions()
    }
    
    // MARK: - Permission Management
    
    func checkPermissions() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        hasPermission = (authStatus == .authorized)
        
        if authStatus != .authorized {
            print("🎙️ ⚠️ Microphone permission not granted. Status: \(authStatus)")
        }
    }
    
    func requestPermission() async -> Bool {
        print("🎙️ Requesting microphone permission...")
        
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if currentStatus == .authorized {
            hasPermission = true
            return true
        }
        
        if currentStatus == .denied {
            print("🎙️ ❌ Permission previously denied - user must enable in System Settings")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Monitoring Control
    
    func startContinuousMonitoring() async throws {
        print("🎙️ Starting continuous audio monitoring...")
        
        guard !isMonitoring else {
            print("🎙️ Already monitoring")
            return
        }
        
        // Check permissions
        if !hasPermission {
            let granted = await requestPermission()
            if !granted {
                throw ContinuousAudioError.permissionDenied
            }
        }
        
        try setupAudioEngine()
        try startAudioEngine()
        
        silenceDetectionService.startMonitoring()
        isMonitoring = true
        
        print("🎙️ ✅ Continuous monitoring started")
    }
    
    func stopContinuousMonitoring() {
        print("🎙️ Stopping continuous audio monitoring...")
        
        guard isMonitoring else {
            print("🎙️ Not currently monitoring")
            return
        }
        
        // Stop current recording if active
        if isRecordingSegment {
            finishRecordingSegment()
        }
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Reset state
        silenceDetectionService.stopMonitoring()
        circularBuffer.clear()
        isMonitoring = false
        isVoiceActive = false
        audioLevel = 0.0
        
        print("🎙️ ✅ Continuous monitoring stopped")
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() throws {
        print("🎙️ Setting up audio engine...")
        
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            throw ContinuousAudioError.audioEngineSetupFailed
        }
        
        inputNode = engine.inputNode
        guard let input = inputNode else {
            throw ContinuousAudioError.audioEngineSetupFailed
        }
        
        // Use the input node's native format for the tap to avoid format mismatch
        let inputFormat = input.inputFormat(forBus: 0)
        print("🎙️ Input hardware format: \(inputFormat)")
        
        // Calculate buffer size for the tap (use hardware sample rate)
        let tapBufferSize = AVAudioFrameCount(inputFormat.sampleRate * 0.08) // 80ms at hardware sample rate
        
        print("🎙️ Installing tap with hardware format: \(inputFormat)")
        print("🎙️ Tap buffer size: \(tapBufferSize) frames")
        
        // Install tap using hardware format
        input.installTap(onBus: 0, bufferSize: tapBufferSize, format: inputFormat) { [weak self] buffer, time in
            Task { @MainActor in
                self?.processAudioBuffer(buffer)
            }
        }
        
        print("🎙️ ✅ Audio engine setup complete")
    }
    
    private func startAudioEngine() throws {
        guard let engine = audioEngine else {
            throw ContinuousAudioError.audioEngineSetupFailed
        }
        
        print("🎙️ Starting audio engine...")
        
        do {
            try engine.start()
            print("🎙️ ✅ Audio engine started successfully")
        } catch {
            print("🎙️ ❌ Failed to start audio engine: \(error)")
            throw ContinuousAudioError.audioEngineStartFailed(error)
        }
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Convert hardware audio format to our target format (16kHz Int16)
        guard let convertedData = convertAudioBuffer(buffer) else {
            print("🎙️ ⚠️ Failed to convert audio buffer")
            return
        }
        
        // Add to circular buffer
        circularBuffer.add(convertedData)
        
        // Calculate audio level for UI
        let rms = silenceDetectionService.calculateRMS(from: convertedData)
        audioLevel = rms
        
        // Detect voice activity
        let isSilent = silenceDetectionService.detectSilence(in: convertedData)
        let shouldStopRecording = silenceDetectionService.processSilenceResult(isSilent)
        
        // Handle voice activity state changes
        if !isSilent {
            // Voice activity detected
            if !isVoiceActive {
                handleVoiceActivityStart()
            }
            lastVoiceActivityTime = Date()
        } else if isVoiceActive && shouldStopRecording {
            // Silence detected for sufficient duration
            handleVoiceActivityEnd()
        }
        
        // Add current chunk to recording if active
        if isRecordingSegment {
            currentRecordingBuffer.append(convertedData)
        }
    }
    
    // MARK: - Audio Format Conversion
    
    private func convertAudioBuffer(_ buffer: AVAudioPCMBuffer) -> Data? {
        let format = buffer.format
        let frameLength = Int(buffer.frameLength)
        
        // Handle Float32 format (common hardware format)
        if format.commonFormat == .pcmFormatFloat32 {
            guard let channelData = buffer.floatChannelData else { return nil }
            
            // Simple downsampling: take every Nth sample to convert from hardware rate to 16kHz
            let downsampleRatio = Int(format.sampleRate / sampleRate)
            let targetFrameCount = frameLength / downsampleRatio
            
            var int16Samples: [Int16] = []
            int16Samples.reserveCapacity(targetFrameCount)
            
            for i in stride(from: 0, to: frameLength, by: downsampleRatio) {
                // Convert Float32 to Int16 with proper scaling
                let floatSample = channelData[0][i]
                let scaledSample = max(-1.0, min(1.0, floatSample)) // Clamp to [-1, 1]
                let int16Sample = Int16(scaledSample * 32767.0)
                int16Samples.append(int16Sample)
            }
            
            return Data(bytes: int16Samples, count: int16Samples.count * MemoryLayout<Int16>.size)
        }
        // Handle Int16 format (if already in target format)
        else if format.commonFormat == .pcmFormatInt16 {
            guard let channelData = buffer.int16ChannelData else { return nil }
            
            // If sample rates match, use directly
            if format.sampleRate == sampleRate {
                return Data(bytes: channelData[0], count: frameLength * MemoryLayout<Int16>.size)
            } else {
                // Downsample Int16 data
                let downsampleRatio = Int(format.sampleRate / sampleRate)
                let targetFrameCount = frameLength / downsampleRatio
                
                var downsampledSamples: [Int16] = []
                downsampledSamples.reserveCapacity(targetFrameCount)
                
                for i in stride(from: 0, to: frameLength, by: downsampleRatio) {
                    downsampledSamples.append(channelData[0][i])
                }
                
                return Data(bytes: downsampledSamples, count: downsampledSamples.count * MemoryLayout<Int16>.size)
            }
        }
        
        print("🎙️ ⚠️ Unsupported audio format: \(format.commonFormat)")
        return nil
    }
    
    private func handleVoiceActivityStart() {
        print("🎙️ 🗣️ Voice activity started")
        
        isVoiceActive = true
        delegate?.voiceActivityDidChange(isActive: true)
        
        // Start recording segment
        if !isRecordingSegment {
            startRecordingSegment()
        }
    }
    
    private func handleVoiceActivityEnd() {
        print("🎙️ 🤫 Voice activity ended")
        
        isVoiceActive = false
        delegate?.voiceActivityDidChange(isActive: false)
        
        // Finish recording segment
        if isRecordingSegment {
            finishRecordingSegment()
        }
    }
    
    // MARK: - Recording Management
    
    private func startRecordingSegment() {
        print("🎙️ 📹 Starting voice segment recording")
        
        isRecordingSegment = true
        voiceSegmentStartTime = Date()
        currentRecordingBuffer.removeAll()
        
        // Include some pre-buffer audio (previous frames before voice activity)
        let preBufferFrames = circularBuffer.getRecentFrames(count: 8) // ~640ms before voice activity
        currentRecordingBuffer.append(contentsOf: preBufferFrames)
        
        print("🎙️ Added \(preBufferFrames.count) pre-buffer frames to recording")
    }
    
    private func finishRecordingSegment() {
        print("🎙️ 🏁 Finishing voice segment recording")
        
        guard isRecordingSegment else { return }
        
        isRecordingSegment = false
        
        // Create audio file from recorded data
        let audioData = combineAudioData(currentRecordingBuffer)
        
        if audioData.count > 0 {
            Task {
                do {
                    let audioURL = try await saveAudioToFile(audioData)
                    delegate?.didCaptureVoiceSegment(audioURL: audioURL)
                    
                    let duration = Date().timeIntervalSince(voiceSegmentStartTime ?? Date())
                    print("🎙️ ✅ Voice segment saved: \(audioURL.lastPathComponent) (duration: \(String(format: "%.2f", duration))s)")
                } catch {
                    print("🎙️ ❌ Failed to save voice segment: \(error)")
                    delegate?.continuousAudioDidEncounterError(error)
                }
            }
        } else {
            print("🎙️ ⚠️ No audio data in recording buffer")
        }
        
        currentRecordingBuffer.removeAll()
        voiceSegmentStartTime = nil
    }
    
    private func combineAudioData(_ chunks: [Data]) -> Data {
        var combinedData = Data()
        for chunk in chunks {
            combinedData.append(chunk)
        }
        return combinedData
    }
    
    private func saveAudioToFile(_ audioData: Data) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("voice_segment_\(UUID().uuidString).wav")
        
        // Create WAV file header
        let wavData = createWAVFile(from: audioData)
        
        try wavData.write(to: audioURL)
        return audioURL
    }
    
    private func createWAVFile(from audioData: Data) -> Data {
        let sampleRate: UInt32 = UInt32(self.sampleRate)
        let channels: UInt16 = UInt16(self.channels)
        let bitsPerSample: UInt16 = 16
        let byteRate: UInt32 = sampleRate * UInt32(channels) * UInt32(bitsPerSample / 8)
        let blockAlign: UInt16 = channels * (bitsPerSample / 8)
        
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(36 + audioData.count).littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })  // Chunk size
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })   // Audio format (PCM)
        wavData.append(withUnsafeBytes(of: channels.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(audioData.count).littleEndian) { Data($0) })
        wavData.append(audioData)
        
        return wavData
    }
}

// MARK: - Circular Audio Buffer

private class CircularAudioBuffer {
    private var buffer: [Data]
    private var head: Int = 0
    private let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: Data(), count: capacity)
    }
    
    func add(_ data: Data) {
        buffer[head] = data
        head = (head + 1) % capacity
    }
    
    func getRecentFrames(count: Int) -> [Data] {
        let actualCount = min(count, capacity)
        var result: [Data] = []
        
        for i in 0..<actualCount {
            let index = (head - actualCount + i + capacity) % capacity
            if !buffer[index].isEmpty {
                result.append(buffer[index])
            }
        }
        
        return result
    }
    
    func clear() {
        buffer = Array(repeating: Data(), count: capacity)
        head = 0
    }
}

// MARK: - Error Types

enum ContinuousAudioError: Error, LocalizedError {
    case permissionDenied
    case audioEngineSetupFailed
    case audioEngineStartFailed(Error)
    case invalidAudioFormat
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .audioEngineSetupFailed:
            return "Failed to setup audio engine"
        case .audioEngineStartFailed(let error):
            return "Failed to start audio engine: \(error.localizedDescription)"
        case .invalidAudioFormat:
            return "Invalid audio format configuration"
        case .recordingFailed:
            return "Voice segment recording failed"
        }
    }
}