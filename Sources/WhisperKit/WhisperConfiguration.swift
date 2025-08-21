//
//  WhisperConfiguration.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation
import Metal

private let hasMetalDevice = MTLCreateSystemDefaultDevice() != nil
private let isUnsupportedDeviceVersionForMetalCompute = {
    // check if is on iOS and 16.x < 17.0, if so, fallback to CPU
    if #available(iOS 16.0, *) {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        return systemVersion.majorVersion < 17
    }
    return false
}()

public struct WhisperConfiguration {
    // MARK: - Audio Processing

    public var sampleRate: Int = 16000
    public var numberOfThreads: Int = ProcessInfo.processInfo.processorCount

    private var _useGPU: Bool = true
    public var useGPU: Bool {
        get {
            if _useGPU, !hasMetalDevice {
                print("Warning: GPU support is enabled, but no Metal device is available. Falling back to CPU.")
                return false
            }
            if _useGPU, isUnsupportedDeviceVersionForMetalCompute {
                print("Warning: Unsupported device version for Metal compute. Falling back to CPU.")
                return false
            }
            return _useGPU
        }
        set { _useGPU = newValue }
    }

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
