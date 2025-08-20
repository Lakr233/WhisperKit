//
//  AudioUtilities.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/21/25.
//

import AVFoundation
import Foundation

/// Utilities for audio file processing and format conversion
public enum AudioUtilities {
    /// Errors that can occur during audio processing
    public enum AudioError: Error, LocalizedError {
        case audioBufferCreationFailed
        case audioDataExtractionFailed
        case fileNotFound
        case unsupportedFormat

        public var errorDescription: String? {
            switch self {
            case .audioBufferCreationFailed:
                "Failed to create audio buffer"
            case .audioDataExtractionFailed:
                "Failed to extract audio data"
            case .fileNotFound:
                "Audio file not found"
            case .unsupportedFormat:
                "Unsupported audio format"
            }
        }
    }

    /// Load audio data from a file URL and convert to target sample rate
    /// - Parameters:
    ///   - url: The URL of the audio file
    ///   - targetSampleRate: Target sample rate (default: 16000 Hz)
    ///   - progressHandler: Optional progress callback (0.0 to 1.0)
    /// - Returns: Array of Float samples at target sample rate
    /// - Throws: AudioError if processing fails
    public static func loadAudioData(
        from url: URL,
        targetSampleRate: Double = 16000,
        progressHandler: ((Double) -> Void)? = nil
    ) throws -> [Float] {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let totalFrameCount = audioFile.length

        // Use 30-second chunks to manage memory
        let maxBufferSize = AVAudioFrameCount(format.sampleRate * 30)
        var audioData = [Float]()
        var currentFrame: AVAudioFramePosition = 0

        // Pre-allocate capacity for better performance
        let estimatedOutputSize = Int(Double(totalFrameCount) * targetSampleRate / format.sampleRate)
        audioData.reserveCapacity(estimatedOutputSize)

        while currentFrame < totalFrameCount {
            let remainingFrames = totalFrameCount - currentFrame
            let framesToRead = min(AVAudioFrameCount(remainingFrames), maxBufferSize)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToRead) else {
                throw AudioError.audioBufferCreationFailed
            }

            audioFile.framePosition = currentFrame
            try audioFile.read(into: buffer, frameCount: framesToRead)

            guard let floatChannelData = buffer.floatChannelData else {
                throw AudioError.audioDataExtractionFailed
            }

            let channelData = floatChannelData[0]
            let frameLength = Int(buffer.frameLength)

            let chunkData = convertToTargetSampleRate(
                channelData: channelData,
                frameLength: frameLength,
                sourceSampleRate: format.sampleRate,
                targetSampleRate: targetSampleRate
            )
            audioData.append(contentsOf: chunkData)

            // Report progress
            if let progressHandler {
                let progress = Double(currentFrame) / Double(totalFrameCount)
                progressHandler(progress)
            }

            currentFrame += AVAudioFramePosition(framesToRead)
        }

        return audioData
    }

    /// Convert audio data to target sample rate using simple linear interpolation
    /// - Parameters:
    ///   - channelData: Pointer to source audio data
    ///   - frameLength: Number of frames in source data
    ///   - sourceSampleRate: Source sample rate
    ///   - targetSampleRate: Target sample rate
    /// - Returns: Resampled audio data array
    public static func convertToTargetSampleRate(
        channelData: UnsafeMutablePointer<Float>,
        frameLength: Int,
        sourceSampleRate: Double,
        targetSampleRate: Double = 16000
    ) -> [Float] {
        // If sample rates are very close, no conversion needed
        if abs(sourceSampleRate - targetSampleRate) < 1 {
            return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        }

        let ratio = sourceSampleRate / targetSampleRate
        let outputLength = Int(Double(frameLength) / ratio)
        var audioData = [Float]()
        audioData.reserveCapacity(outputLength)

        for i in 0 ..< outputLength {
            let sourceIndex = Int(Double(i) * ratio)
            if sourceIndex < frameLength {
                audioData.append(channelData[sourceIndex])
            }
        }

        return audioData
    }

    /// Get the duration of an audio file in seconds
    /// - Parameter url: The URL of the audio file
    /// - Returns: Duration in seconds
    /// - Throws: Error if file cannot be read
    public static func getAudioDuration(from url: URL) throws -> TimeInterval {
        let audioFile = try AVAudioFile(forReading: url)
        let frameCount = audioFile.length
        let sampleRate = audioFile.fileFormat.sampleRate
        return Double(frameCount) / sampleRate
    }

    /// Check if the file at URL is a supported audio format
    /// - Parameter url: The URL to check
    /// - Returns: True if the format is supported by AVAudioFile
    public static func isSupportedAudioFormat(url: URL) -> Bool {
        do {
            _ = try AVAudioFile(forReading: url)
            return true
        } catch {
            return false
        }
    }
}
