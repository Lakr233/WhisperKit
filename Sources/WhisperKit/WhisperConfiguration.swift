//
//  WhisperConfiguration.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation
import Metal

private let hasMetalDevice = MTLCreateSystemDefaultDevice() != nil

private let allowedLanguageCodes: Set<String> = [
    "en", "zh", "de", "es", "ru", "ko", "fr", "ja", "pt", "tr", "pl",
    "ca", "nl", "ar", "sv", "it", "id", "hi", "fi", "vi", "he", "uk",
    "el", "ms", "cs", "ro", "da", "hu", "ta", "no", "th", "ur", "hr",
    "bg", "lt", "la", "mi", "ml", "cy", "sk", "te", "fa", "lv", "bn",
    "sr", "az", "sl", "kn", "et", "mk", "br", "eu", "is", "hy", "ne",
    "mn", "bs", "kk", "sq", "sw", "gl", "mr", "pa", "si", "km", "sn",
    "yo", "so", "af", "oc", "ka", "be", "tg", "sd", "gu", "am", "yi",
    "lo", "uz", "fo", "ht", "ps", "tk", "nn", "mt", "sa", "lb", "my",
    "bo", "tl", "mg", "as", "tt", "haw", "ln", "ha", "ba", "jw", "su",
]

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
            return _useGPU
        }
        set { _useGPU = newValue }
    }

    public var flashAttention: Bool = false

    // MARK: - Language Settings

    public var language: String? {
        didSet {
            if let language {
                assert(
                    allowedLanguageCodes.contains(language),
                    "Unsupported language code: \(language)."
                )
            }
        }
    }

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

public extension WhisperConfiguration {
    private static var cLanguagePointers: [String: UnsafePointer<CChar>] = [:]
    private static let initialPrompt = """
    You are a helpful assistant that translates speech to text. Please translate the speech into text carefully and accurately. Please use the correct punctuation and capitalization for the language you are transcribing. Do not add extra spaces or punctuation marks that are not present in the original speech. For silent or non-speech segments, please return an empty string or null.
    """

    static func cLanguagePointer(language: String?) -> UnsafePointer<CChar>? {
        guard let language else { return nil }
        if let existingPointer = cLanguagePointers[language] {
            return existingPointer
        }
        let size = language.utf8.count + 1
        let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: size)
        _ = language.withCString { input in
            memcpy(pointer, input, size - 1)
        }
        pointer[size - 1] = 0 // Null-terminate the string
        let ans = UnsafePointer(pointer)
        cLanguagePointers[language] = ans
        return ans
    }

    static func cInitialPrompt() -> UnsafePointer<CChar>? {
        cLanguagePointer(language: initialPrompt)
    }
}
