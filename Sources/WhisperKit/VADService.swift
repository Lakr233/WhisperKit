//
//  VADService.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation
import whisper

public final class VADService {
    private var context: OpaquePointer?
    private let configuration: VADConfiguration

    public init(
        modelPath: String? = builtinModel.path,
        configuration: VADConfiguration = VADConfiguration()
    ) throws {
        self.configuration = configuration

        guard let modelPath else {
            throw WhisperError.vadNotInitialized
        }

        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw WhisperError.modelNotFound
        }

        var vadParams = whisper_vad_default_context_params()
        vadParams.use_gpu = true
        vadParams.n_threads = 4

        context = whisper_vad_init_from_file_with_params(modelPath, vadParams)

        guard context != nil else {
            throw WhisperError.vadInitializationFailed
        }
    }

    deinit {
        if let context {
            whisper_vad_free(context)
        }
    }

    public func detectSpeechSegments(in audioData: [Float]) throws -> [VADSegment] {
        guard let context else {
            throw WhisperError.vadNotInitialized
        }

        guard !audioData.isEmpty else {
            return []
        }

        var vadParams = whisper_vad_default_params()
        vadParams.threshold = max(0.0, min(1.0, configuration.threshold))
        vadParams.min_speech_duration_ms = Int32(max(0, configuration.minSpeechDurationMs))
        vadParams.min_silence_duration_ms = Int32(max(0, configuration.minSilenceDurationMs))
        vadParams.max_speech_duration_s = max(0.0, configuration.maxSpeechDurationS)
        vadParams.speech_pad_ms = Int32(max(0, configuration.speechPadMs))
        vadParams.samples_overlap = max(0.0, min(1.0, configuration.samplesOverlap))

        let segments = audioData.withUnsafeBufferPointer { buffer in
            whisper_vad_segments_from_samples(
                context, vadParams, buffer.baseAddress, Int32(buffer.count)
            )
        }

        guard let segments else {
            throw WhisperError.vadProcessingFailed
        }

        defer { whisper_vad_free_segments(segments) }

        let segmentCount = whisper_vad_segments_n_segments(segments)
        var result: [VADSegment] = []

        for i in 0 ..< segmentCount {
            let startTime = TimeInterval(whisper_vad_segments_get_segment_t0(segments, i)) / 100.0
            let endTime = TimeInterval(whisper_vad_segments_get_segment_t1(segments, i)) / 100.0
            if endTime > startTime {
                result.append(VADSegment(startTime: startTime, endTime: endTime))
            }
        }

        return result
    }

    public func isSpeechDetected(in audioData: [Float]) -> Bool {
        guard let context, !audioData.isEmpty else { return false }

        return audioData.withUnsafeBufferPointer { buffer in
            whisper_vad_detect_speech(context, buffer.baseAddress, Int32(buffer.count))
        }
    }

    public func getSpeechProbabilities() -> [Float] {
        guard let context else { return [] }

        let probCount = whisper_vad_n_probs(context)
        guard probCount > 0, let probsPtr = whisper_vad_probs(context) else {
            return []
        }

        let probsBuffer = UnsafeBufferPointer(start: probsPtr, count: Int(probCount))
        return Array(probsBuffer)
    }
}

public extension VADService {
    static let builtinModel = Bundle.module
        .url(forResource: "ggml-silero-v5.1.2", withExtension: "")!
}
