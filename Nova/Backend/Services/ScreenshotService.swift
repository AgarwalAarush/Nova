//
//  ScreenshotService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/16/25.
//

import AppKit
import ScreenCaptureKit

class ScreenshotService {
    
    static let shared = ScreenshotService()
    
    private init() {}
    
    /// Captures the main display's screen content using ScreenCaptureKit
    /// - Returns: An NSImage of the screen, or nil if capture fails
    func captureScreen() async -> NSImage? {
        do {
            // Get the main display
            guard let mainDisplay = try await SCShareableContent.current.displays.first(where: { $0.displayID == CGMainDisplayID() }) else {
                print("Error: Main display not found.")
                return nil
            }
            
            // Create a content filter for the main display
            let contentFilter = SCContentFilter(display: mainDisplay, excludingApplications: [], exceptingWindows: [])
            
            // Create a stream configuration
            let config = SCStreamConfiguration()
            config.width = mainDisplay.width
            config.height = mainDisplay.height
            config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            config.queueDepth = 5
            
            // Create a stream
            let stream = SCStream(filter: contentFilter, configuration: config, delegate: nil)
            
            // Create a stream output handler
            let streamOutput = StreamOutput()
            
            // Add the stream output handler
            try stream.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: .main)
            
            // Start capturing
            try await stream.startCapture()
            
            // Wait for the first frame
            let image = await streamOutput.waitForImage()
            
            // Stop capturing
            try await stream.stopCapture()
            
            return image
        } catch {
            print("Error capturing screen: \(error.localizedDescription)")
            return nil
        }
    }
}

private class StreamOutput: NSObject, SCStreamOutput {
    private var continuation: CheckedContinuation<NSImage?, Never>?
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let continuation = continuation else { return }
        
        // Get the image from the sample buffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            continuation.resume(returning: nil)
            self.continuation = nil
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            continuation.resume(returning: nil)
            self.continuation = nil
            return
        }
        
        let image = NSImage(cgImage: cgImage, size: .zero)
        
        // Resume the continuation with the captured image
        continuation.resume(returning: image)
        self.continuation = nil
    }
    
    func waitForImage() async -> NSImage? {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}