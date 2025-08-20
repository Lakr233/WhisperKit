//
//  TranscriptionSegment.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct TranscriptionSegment {
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let tokens: [TokenData]
    public let noSpeechProbability: Float
    public let speakerTurnNext: Bool

    public init(
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        tokens: [TokenData] = [],
        noSpeechProbability: Float = 0.0,
        speakerTurnNext: Bool = false
    ) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.tokens = tokens
        self.noSpeechProbability = noSpeechProbability
        self.speakerTurnNext = speakerTurnNext
    }

    public var duration: TimeInterval {
        endTime - startTime
    }

    public var averageTokenProbability: Float {
        guard !tokens.isEmpty else { return 0.0 }
        return tokens.map(\.probability).reduce(0, +) / Float(tokens.count)
    }

    public var words: [WordTimestamp] {
        guard !tokens.isEmpty else { return [] }

        var words: [WordTimestamp] = []
        var currentWord = ""
        var currentTokens: [TokenData] = []
        var wordStartTime: TimeInterval = 0

        for token in tokens {
            let tokenText = token.text.trimmingCharacters(in: .whitespaces)

            if tokenText.isEmpty { continue }

            if tokenText.hasPrefix(" ") || currentWord.isEmpty {
                if !currentWord.isEmpty {
                    let avgProbability = currentTokens.map(\.probability).reduce(0, +) / Float(currentTokens.count)
                    words.append(WordTimestamp(
                        word: currentWord.trimmingCharacters(in: .whitespaces),
                        startTime: wordStartTime,
                        endTime: currentTokens.last?.endTime ?? wordStartTime,
                        probability: avgProbability,
                        tokens: currentTokens
                    ))
                }

                currentWord = tokenText.trimmingCharacters(in: .whitespaces)
                currentTokens = [token]
                wordStartTime = token.startTime
            } else {
                currentWord += tokenText
                currentTokens.append(token)
            }
        }

        if !currentWord.isEmpty {
            let avgProbability = currentTokens.map(\.probability).reduce(0, +) / Float(currentTokens.count)
            let word = WordTimestamp(
                word: currentWord.trimmingCharacters(in: .whitespaces),
                startTime: wordStartTime,
                endTime: currentTokens.last?.endTime ?? wordStartTime,
                probability: avgProbability,
                tokens: currentTokens
            )
            words.append(word)
        }

        return words
    }
}
