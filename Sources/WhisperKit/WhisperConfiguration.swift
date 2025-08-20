//
//  WhisperConfiguration.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct WhisperConfiguration {
    // MARK: - Audio Processing

    public var sampleRate: Int = 16000
    public var numberOfThreads: Int = ProcessInfo.processInfo.processorCount
    public var useGPU: Bool = true
    public var flashAttention: Bool = false

    // MARK: - Language Settings

    public var language: String?
    public var autoDetectLanguage: Bool = true
    public var translate: Bool = false

    // MARK: - Transcription Options

    public var useTokenTimestamps: Bool = false
    public var maxSegmentLength: Int = 0
    public var temperature: Float = 0.0
    public var printProgress: Bool = true
    public var printTimestamps: Bool = false
    public var printSpecialTokens: Bool = false

    // MARK: - VAD Configuration

    public var enableVAD: Bool = false
    public var vadModelPath: String?
    public var vadConfig: VADConfiguration = .init()

    // MARK: - Decoder Settings

    public enum SamplingStrategy {
        case greedy
        case beamSearch
    }

    public var samplingStrategy: SamplingStrategy = .greedy
    public var beamSize: Int = 5
    public var bestOf: Int = 5
    public var patience: Float = 1.0

    // MARK: - Advanced Options

    public var suppressBlank: Bool = true
    public var suppressNonSpeechTokens: Bool = true
    public var lengthPenalty: Float = -1.0
    public var entropyThreshold: Float = 2.4
    public var logProbThreshold: Float = -1.0
    public var noSpeechThreshold: Float = 0.6

    public init() {}

    public static let `default` = WhisperConfiguration()
}
