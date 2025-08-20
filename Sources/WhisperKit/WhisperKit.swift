//
//  WhisperKit.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

// This class is not designed to be thread safe. Do not access it from multiple threads simultaneously.

public final class WhisperKit {
    private let engine: WhisperEngine

    public var configuration: WhisperConfiguration {
        engine.configuration
    }

    public convenience init(modelPath: String, configuration: WhisperConfiguration = .default) throws {
        let modelURL = URL(fileURLWithPath: modelPath)
        try self.init(modelURL: modelURL, configuration: configuration)
    }

    public init(modelURL: URL, configuration: WhisperConfiguration = .default) throws {
        engine = try WhisperEngine(modelURL: modelURL, configuration: configuration)
    }

    public init(modelData: Data, configuration: WhisperConfiguration = .default) throws {
        engine = try WhisperEngine(modelData: modelData, configuration: configuration)
    }

    public convenience init(withModelAt path: String,
                            language: String? = nil,
                            useGPU: Bool = false,
                            enableTokenTimestamps: Bool = false) throws
    {
        let url = URL(fileURLWithPath: path)
        try self.init(withModelAt: url,
                      language: language,
                      useGPU: useGPU,
                      enableTokenTimestamps: enableTokenTimestamps)
    }

    public convenience init(withModelAt url: URL,
                            language: String? = nil,
                            useGPU: Bool = false,
                            enableTokenTimestamps: Bool = false) throws
    {
        var config = WhisperConfiguration.default
        config.language = language
        config.useGPU = useGPU
        config.useTokenTimestamps = enableTokenTimestamps
        config.autoDetectLanguage = language == nil

        try self.init(modelURL: url, configuration: config)
    }

    // MARK: - Public API

    public func transcribe(audioData: [Float], eventHandler: ((WhisperEvent) -> Void)? = nil) throws -> TranscriptionResult {
        try engine.transcribe(audioData: audioData, eventHandler: eventHandler).get()
    }

    public func transcribe(audioData: [Float]) -> String {
        (try? transcribe(audioData: audioData).fullText) ?? ""
    }

    public func detectLanguage(from audioData: [Float], offsetMs: Int = 0) throws -> LanguageDetectionResult {
        try engine.detectLanguage(from: audioData, offsetMs: offsetMs)
    }

    public func detectLanguage(_ audioData: [Float]) -> String? {
        try? detectLanguage(from: audioData).languageCode
    }

    public func getModelInfo() -> ModelInfo {
        engine.getModelInfo()
    }

    // MARK: - Static Utility Methods

    public static func getSupportedLanguages() -> [String] {
        LanguageUtilities.getSupportedLanguages()
    }

    public static func getLanguageFullName(for code: String) -> String? {
        LanguageUtilities.getLanguageFullName(for: code)
    }

    public static func getLanguageId(for code: String) -> Int? {
        LanguageUtilities.getLanguageId(for: code)
    }

    public static func isLanguageSupported(_ code: String) -> Bool {
        getSupportedLanguages().contains(code)
    }

    public static func getAllLanguageInfo() -> [(code: String, name: String)] {
        getSupportedLanguages().compactMap { code in
            guard let name = getLanguageFullName(for: code) else { return nil }
            return (code: code, name: name)
        }
    }
}
