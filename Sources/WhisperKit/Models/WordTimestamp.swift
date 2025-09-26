//
//  WordTimestamp.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct WordTimestamp {
    public let word: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let probability: Float
    public let tokens: [TokenData]

    public init(word: String, startTime: TimeInterval, endTime: TimeInterval,
                probability: Float = 1.0, tokens: [TokenData] = [])
    {
        self.word = word
        self.startTime = startTime
        self.endTime = endTime
        self.probability = probability
        self.tokens = tokens
    }

    public var duration: TimeInterval {
        endTime - startTime
    }

    public var confidence: Float {
        probability
    }

    public var isValid: Bool {
        !word.isEmpty && endTime > startTime
    }
}
