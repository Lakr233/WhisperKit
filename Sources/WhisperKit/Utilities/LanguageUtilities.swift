//
//  LanguageUtilities.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation
import whisper

/// Language option structure for UI components
public struct LanguageOption {
    public let code: String
    public let name: String

    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}

public enum LanguageUtilities {
    public static func getSupportedLanguages() -> [String] {
        var languages: [String] = []

        for i in 0 ... whisper_lang_max_id() {
            if let langStr = whisper_lang_str(i) {
                let code = String(cString: langStr)
                languages.append(code)
            }
        }

        return languages
    }

    public static func getLanguageFullName(for code: String) -> String? {
        for i in 0 ... whisper_lang_max_id() {
            if let langStr = whisper_lang_str(i), String(cString: langStr) == code {
                if let fullName = whisper_lang_str_full(i) {
                    return String(cString: fullName)
                }
            }
        }
        return nil
    }

    public static func getLanguageId(for code: String) -> Int? {
        let id = whisper_lang_id(code)
        return id >= 0 ? Int(id) : nil
    }

    /// Get common language options for UI components
    /// - Returns: Array of commonly used language options including auto-detect
    public static func getCommonLanguageOptions() -> [LanguageOption] {
        [
            LanguageOption(code: "auto", name: "Auto Detect"),
            LanguageOption(code: "zh", name: "Chinese"),
            LanguageOption(code: "en", name: "English"),
            LanguageOption(code: "ja", name: "Japanese"),
            LanguageOption(code: "ko", name: "Korean"),
            LanguageOption(code: "es", name: "Spanish"),
            LanguageOption(code: "fr", name: "French"),
            LanguageOption(code: "de", name: "German"),
            LanguageOption(code: "it", name: "Italian"),
            LanguageOption(code: "pt", name: "Portuguese"),
            LanguageOption(code: "ru", name: "Russian"),
            LanguageOption(code: "ar", name: "Arabic"),
        ]
    }

    /// Get all available language options as LanguageOption structs
    /// - Returns: Array of all supported languages with their full names
    public static func getAllLanguageOptions() -> [LanguageOption] {
        var options: [LanguageOption] = [LanguageOption(code: "auto", name: "Auto Detect")]

        let supportedCodes = getSupportedLanguages()
        for code in supportedCodes {
            if let fullName = getLanguageFullName(for: code) {
                options.append(LanguageOption(code: code, name: fullName))
            }
        }

        return options.sorted { $0.name < $1.name }
    }
}
