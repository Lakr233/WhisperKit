//
//  LanguageDetectionResult.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct LanguageDetectionResult {
    public let languageId: Int
    public let languageCode: String
    public let probability: Float
    public let allProbabilities: [String: Float]

    public init(
        languageId: Int,
        languageCode: String,
        probability: Float,
        allProbabilities: [String: Float]
    ) {
        self.languageId = languageId
        self.languageCode = languageCode
        self.probability = probability
        self.allProbabilities = allProbabilities
    }

    public var topLanguages: [(code: String, probability: Float)] {
        allProbabilities
            .sorted { $0.value > $1.value }
            .map { (code: $0.key, probability: $0.value) }
    }
}
