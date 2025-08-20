//
//  WhisperEngine.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation
import whisper

public final class WhisperEngine: @unchecked Sendable {
    var context: OpaquePointer?
    var state: OpaquePointer?

    public let configuration: WhisperConfiguration

    public init(modelURL: URL, configuration: WhisperConfiguration = .default) throws {
        self.configuration = configuration

        guard modelURL.isFileURL, FileManager.default.fileExists(atPath: modelURL.path) else {
            throw WhisperError.modelNotFound
        }

        var params = whisper_context_default_params()
        params.use_gpu = configuration.useGPU
        params.flash_attn = configuration.flashAttention
        params.dtw_token_timestamps = configuration.useTokenTimestamps

        context = whisper_init_from_file_with_params(modelURL.path, params)
        guard let context else {
            throw WhisperError.initializationFailed
        }

        state = whisper_init_state(context)
        guard state != nil else {
            whisper_free(context)
            throw WhisperError.stateInitializationFailed
        }
    }

    public init(modelData: Data, configuration: WhisperConfiguration = .default) throws {
        self.configuration = configuration

        var params = whisper_context_default_params()
        params.use_gpu = configuration.useGPU
        params.flash_attn = configuration.flashAttention
        params.dtw_token_timestamps = configuration.useTokenTimestamps

        try modelData.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else {
                throw WhisperError.invalidBuffer
            }

            context = whisper_init_from_buffer_with_params(
                UnsafeMutableRawPointer(mutating: baseAddress),
                modelData.count,
                params
            )
        }

        guard let context else {
            throw WhisperError.initializationFailed
        }

        state = whisper_init_state(context)
        guard state != nil else {
            whisper_free(context)
            throw WhisperError.stateInitializationFailed
        }
    }

    deinit {
        if let state {
            whisper_free_state(state)
            self.state = nil
        }
        if let context {
            whisper_free(context)
            self.context = nil
        }
    }

    public func getModelInfo() -> ModelInfo {
        let vocabularySize = Int(whisper_model_n_vocab(context))
        let audioContextSize = Int(whisper_model_n_audio_ctx(context))
        let textContextSize = Int(whisper_model_n_text_ctx(context))
        let audioLayers = Int(whisper_model_n_audio_layer(context))
        let textLayers = Int(whisper_model_n_text_layer(context))
        let audioHeads = Int(whisper_model_n_audio_head(context))
        let textHeads = Int(whisper_model_n_text_head(context))
        let melBands = Int(whisper_model_n_mels(context))
        let isMultilingual = whisper_is_multilingual(context) != 0
        let modelTypeStr = String(cString: whisper_model_type_readable(context))
        let version = String(cString: whisper_version())

        return ModelInfo(
            vocabularySize: vocabularySize,
            audioContextSize: audioContextSize,
            textContextSize: textContextSize,
            audioLayers: audioLayers,
            textLayers: textLayers,
            audioHeads: audioHeads,
            textHeads: textHeads,
            melBands: melBands,
            modelType: modelTypeStr,
            isMultilingual: isMultilingual,
            version: version
        )
    }
}
