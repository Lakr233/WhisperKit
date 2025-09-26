//
//  TranscriptionResult.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct TranscriptionResult {
    public let segments: [TranscriptionSegment]
    public let detectedLanguage: String?
    public let languageProbability: Float?
    public let processingTime: TimeInterval
    public let audioLength: TimeInterval
    public let modelInfo: ModelInfo?

    public init(
        segments: [TranscriptionSegment],
        detectedLanguage: String? = nil,
        languageProbability: Float? = nil,
        processingTime: TimeInterval,
        audioLength: TimeInterval,
        modelInfo: ModelInfo? = nil
    ) {
        self.segments = segments
        self.detectedLanguage = detectedLanguage
        self.languageProbability = languageProbability
        self.processingTime = processingTime
        self.audioLength = audioLength
        self.modelInfo = modelInfo
    }

    public var fullText: String {
        segments.map(\.text).joined(separator: " ")
    }

    public var totalDuration: TimeInterval {
        audioLength
    }

    public var realTimeFactor: Float {
        guard audioLength > 0 else { return 0 }
        return Float(processingTime / audioLength)
    }

    public var allWords: [WordTimestamp] {
        segments.flatMap(\.words)
    }

    public var averageConfidence: Float {
        let allTokens = segments.flatMap(\.tokens)
        guard !allTokens.isEmpty else { return 0.0 }
        return allTokens.map(\.probability).reduce(0, +) / Float(allTokens.count)
    }

    public var isValid: Bool {
        !segments.isEmpty && processingTime > 0
    }
}
