import AVFoundation
import Foundation

@MainActor
class AudioRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var hasPermission = false
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        // On macOS, we'll assume permission is granted and handle any errors during recording
        // The system will prompt for permission when we first try to access the microphone
        hasPermission = true
    }
    
    func requestPermission() async -> Bool {
        // On macOS, permission is handled automatically by the system
        // when first accessing the microphone
        hasPermission = true
        return true
    }
    
    func startRecording() async throws -> URL {
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
        
        guard let url = recordingURL else {
            throw AudioRecorderError.urlCreationFailed
        }
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            
            guard let recorder = audioRecorder else {
                throw AudioRecorderError.recordingFailed
            }
            
            let success = recorder.record()
            if !success {
                throw AudioRecorderError.recordingFailed
            }
            
            isRecording = true
            return url
        } catch {
            // If recording fails, it might be due to permission issues
            throw AudioRecorderError.permissionDenied
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        return recordingURL
    }
    
    func cancelRecording() async {
        audioRecorder?.stop()
        isRecording = false
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        isRecording = false
        if let error = error {
            print("Audio recording error: \(error)")
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