//
//  WhisperEngineExtensions.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation
import whisper

// MARK: - EventHandlerWrapper

private class EventHandlerWrapper {
    let handler: (WhisperEvent) -> Void

    init(handler: @escaping (WhisperEvent) -> Void) {
        self.handler = handler
    }
}

// MARK: - WhisperEngine Inference Extension

public extension WhisperEngine {
    func transcribe(audioData: [Float], eventHandler: ((WhisperEvent) -> Void)? = nil) -> Result<TranscriptionResult, Error> {
        let startTime = Date()

        do {
            var detectedLanguage: String?
            var languageProbability: Float?

            if configuration.autoDetectLanguage {
                let detection = try detectLanguage(from: audioData)
                detectedLanguage = detection.languageCode
                languageProbability = detection.probability
                eventHandler?(.languageDetected(language: detection.languageCode, probability: detection.probability))
            }

            eventHandler?(.encodingStarted)

            let segments = try performSynchronousTranscription(audioData: audioData, eventHandler: eventHandler)
            let processingTime = Date().timeIntervalSince(startTime)
            let audioLength = TimeInterval(audioData.count) / TimeInterval(configuration.sampleRate)

            eventHandler?(.encodingCompleted)

            let result = TranscriptionResult(
                segments: segments,
                detectedLanguage: detectedLanguage,
                languageProbability: languageProbability,
                processingTime: processingTime,
                audioLength: audioLength,
                modelInfo: getModelInfo()
            )
            eventHandler?(.success(result: result))
            return .success(result)
        } catch {
            eventHandler?(.failed(error: error as? WhisperError ?? .inferenceFailed))
            return .failure(error)
        }
    }

    /// Detects language from audio data
    func detectLanguage(from audioData: [Float], offsetMs: Int = 0) throws -> LanguageDetectionResult {
        guard let context, let state else {
            throw WhisperError.contextNotInitialized
        }

        let result = try audioData.withUnsafeBufferPointer { buffer in
            let pcmResult = whisper_pcm_to_mel_with_state(
                context, state, buffer.baseAddress, Int32(buffer.count), Int32(configuration.numberOfThreads)
            )
            guard pcmResult == 0 else {
                throw WhisperError.audioProcessingFailed
            }

            let maxLangId = whisper_lang_max_id()
            var langProbs = [Float](repeating: 0.0, count: Int(maxLangId + 1))

            let detectedLangId = whisper_lang_auto_detect_with_state(
                context, state, Int32(offsetMs), Int32(configuration.numberOfThreads), &langProbs
            )

            guard detectedLangId >= 0 else {
                throw WhisperError.languageDetectionFailed
            }

            return (detectedLangId, langProbs)
        }

        let languageCode = String(cString: whisper_lang_str(result.0))
        let probability = result.1[Int(result.0)]

        var allProbabilities: [String: Float] = [:]
        for i in 0 ... whisper_lang_max_id() {
            if let langStr = whisper_lang_str(i) {
                let code = String(cString: langStr)
                allProbabilities[code] = result.1[Int(i)]
            }
        }

        return LanguageDetectionResult(
            languageId: Int(result.0),
            languageCode: languageCode,
            probability: probability,
            allProbabilities: allProbabilities
        )
    }
}

extension WhisperEngine {
    // MARK: - Private Methods

    private func performSynchronousTranscription(audioData: [Float], eventHandler: ((WhisperEvent) -> Void)? = nil) throws -> [TranscriptionSegment] {
        guard let context, let state else {
            throw WhisperError.contextNotInitialized
        }

        guard !audioData.isEmpty else {
            throw WhisperError.invalidBuffer
        }

        var params = whisper_full_default_params(
            configuration.samplingStrategy == .greedy
                ? WHISPER_SAMPLING_GREEDY
                : WHISPER_SAMPLING_BEAM_SEARCH
        )

        configureTranscriptionParameters(&params)

        var userData: UnsafeMutableRawPointer?
        var handlerBox: Unmanaged<AnyObject>?

        if let eventHandler {
            let handlerWrapper = EventHandlerWrapper(handler: eventHandler)
            handlerBox = Unmanaged.passRetained(handlerWrapper)
            userData = handlerBox?.toOpaque()
        }

        let progressCallback: @convention(c) (OpaquePointer?, OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void = { _, state, progress, userData in
            guard let userData else { return }
            let wrapper = Unmanaged<EventHandlerWrapper>.fromOpaque(userData).takeUnretainedValue()
            let segmentCount = whisper_full_n_segments_from_state(state)
            wrapper.handler(.progress(progress: Float(progress) / 100.0, segment: Int(progress), totalSegments: Int(segmentCount)))
        }
        let segmentCallback: @convention(c) (OpaquePointer?, OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void = { _, state, nNew, userData in
            guard let userData else { return }
            let wrapper = Unmanaged<EventHandlerWrapper>.fromOpaque(userData).takeUnretainedValue()
            let segmentCount = whisper_full_n_segments_from_state(state)
            for i in max(0, segmentCount - nNew) ..< segmentCount {
                let text = String(cString: whisper_full_get_segment_text_from_state(state, Int32(i)))
                let startTime = Double(whisper_full_get_segment_t0_from_state(state, Int32(i))) / 1000.0
                let endTime = Double(whisper_full_get_segment_t1_from_state(state, Int32(i))) / 1000.0
                wrapper.handler(.segmentCompleted(text: text, startTime: startTime, endTime: endTime))
            }
        }
        let encoderBeginCallback: @convention(c) (OpaquePointer?, OpaquePointer?, UnsafeMutableRawPointer?) -> Bool = { _, _, userData in
            guard let userData else { return true }
            let wrapper = Unmanaged<EventHandlerWrapper>.fromOpaque(userData).takeUnretainedValue()
            wrapper.handler(.encodingStarted)
            return true
        }
        params.progress_callback = progressCallback
        params.progress_callback_user_data = userData
        params.new_segment_callback = segmentCallback
        params.new_segment_callback_user_data = userData
        params.encoder_begin_callback = encoderBeginCallback
        params.encoder_begin_callback_user_data = userData

        let result = audioData.withUnsafeBufferPointer { buffer in
            whisper_full_with_state(context, state, params, buffer.baseAddress, Int32(buffer.count))
        }

        handlerBox?.release()

        guard result == 0 else {
            throw WhisperError.inferenceFailed
        }

        return try extractSegments(from: state)
    }

    private func configureTranscriptionParameters(_ params: inout whisper_full_params) {
        params.print_realtime = false
        params.print_progress = configuration.printProgress
        params.print_timestamps = configuration.printTimestamps
        params.print_special = configuration.printSpecialTokens
        params.translate = configuration.translate
        params.n_threads = Int32(configuration.numberOfThreads)
        params.token_timestamps = configuration.useTokenTimestamps
        params.temperature = configuration.temperature
        params.max_len = Int32(configuration.maxSegmentLength)
        params.suppress_blank = configuration.suppressBlank
        params.suppress_nst = configuration.suppressNonSpeechTokens
        params.length_penalty = configuration.lengthPenalty
        params.entropy_thold = configuration.entropyThreshold
        params.logprob_thold = configuration.logProbThreshold
        params.no_speech_thold = configuration.noSpeechThreshold

        if let language = configuration.language {
            params.language = language.withCString { $0 }
        } else {
            params.language = nil
        }

        if configuration.samplingStrategy == .beamSearch {
            params.beam_search.beam_size = Int32(configuration.beamSize)
            params.beam_search.patience = configuration.patience
        } else {
            params.greedy.best_of = Int32(configuration.bestOf)
        }
    }

    private func extractSegments(from state: OpaquePointer) throws -> [TranscriptionSegment] {
        let segmentCount = whisper_full_n_segments_from_state(state)
        var segments: [TranscriptionSegment] = []

        for i in 0 ..< segmentCount {
            let text = String(cString: whisper_full_get_segment_text_from_state(state, i))
            let startTime = whisper_full_get_segment_t0_from_state(state, i)
            let endTime = whisper_full_get_segment_t1_from_state(state, i)
            let noSpeechProb = whisper_full_get_segment_no_speech_prob_from_state(state, i)
            let speakerTurnNext = whisper_full_get_segment_speaker_turn_next_from_state(state, i)

            var tokens: [TokenData] = []
            if configuration.useTokenTimestamps {
                tokens = extractTokens(from: state, segmentIndex: i)
            }

            let segment = TranscriptionSegment(
                text: text,
                startTime: TimeInterval(startTime) / 1000.0,
                endTime: TimeInterval(endTime) / 1000.0,
                tokens: tokens,
                noSpeechProbability: noSpeechProb,
                speakerTurnNext: speakerTurnNext
            )
            segments.append(segment)
        }

        return segments
    }

    private func extractTokens(from state: OpaquePointer, segmentIndex: Int32) -> [TokenData] {
        guard let context else { return [] }

        let tokenCount = whisper_full_n_tokens_from_state(state, segmentIndex)
        var tokens: [TokenData] = []

        for j in 0 ..< tokenCount {
            let tokenData = whisper_full_get_token_data_from_state(state, segmentIndex, j)
            let tokenText = String(cString: whisper_full_get_token_text_from_state(context, state, segmentIndex, j))

            tokens.append(TokenData(
                text: tokenText,
                tokenId: tokenData.id,
                probability: tokenData.p,
                startTime: TimeInterval(tokenData.t0) / 1000.0,
                endTime: TimeInterval(tokenData.t1) / 1000.0,
                voiceLength: tokenData.vlen
            ))
        }

        return tokens
    }
}
