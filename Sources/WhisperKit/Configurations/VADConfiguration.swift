//
//  VADConfiguration.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct VADConfiguration {
    public var threshold: Float = 0.5
    public var minSpeechDurationMs: Int = 250
    public var minSilenceDurationMs: Int = 2000
    public var maxSpeechDurationS: Float = 30.0
    public var speechPadMs: Int = 400
    public var samplesOverlap: Float = 0.1

    public init(
        threshold: Float = 0.5,
        minSpeechDurationMs: Int = 250,
        minSilenceDurationMs: Int = 2000,
        maxSpeechDurationS: Float = 30.0,
        speechPadMs: Int = 400,
        samplesOverlap: Float = 0.1
    ) {
        self.threshold = max(0.0, min(1.0, threshold))
        self.minSpeechDurationMs = max(0, minSpeechDurationMs)
        self.minSilenceDurationMs = max(0, minSilenceDurationMs)
        self.maxSpeechDurationS = max(0.0, maxSpeechDurationS)
        self.speechPadMs = max(0, speechPadMs)
        self.samplesOverlap = max(0.0, min(1.0, samplesOverlap))
    }
}
