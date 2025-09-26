//
//  WhisperError.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public enum WhisperError: Error, LocalizedError {
    case initializationFailed
    case stateInitializationFailed
    case vadInitializationFailed
    case vadNotInitialized
    case vadProcessingFailed
    case contextNotInitialized
    case audioProcessingFailed
    case inferenceFailed
    case invalidBuffer
    case languageDetectionFailed
    case modelNotFound
    case unsupportedFormat
    case memoryAllocationFailed
    case tokenizationFailed

    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            "Failed to initialize Whisper context"
        case .stateInitializationFailed:
            "Failed to initialize Whisper state"
        case .vadInitializationFailed:
            "Failed to initialize VAD context"
        case .vadNotInitialized:
            "VAD is not initialized"
        case .vadProcessingFailed:
            "VAD processing failed"
        case .contextNotInitialized:
            "Whisper context is not initialized"
        case .audioProcessingFailed:
            "Audio processing failed"
        case .inferenceFailed:
            "Inference failed"
        case .invalidBuffer:
            "Invalid audio buffer"
        case .languageDetectionFailed:
            "Language detection failed"
        case .modelNotFound:
            "Model file not found"
        case .unsupportedFormat:
            "Unsupported audio format"
        case .memoryAllocationFailed:
            "Memory allocation failed"
        case .tokenizationFailed:
            "Text tokenization failed"
        }
    }
}
