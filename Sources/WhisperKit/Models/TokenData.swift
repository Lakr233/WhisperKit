//
//  TokenData.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct TokenData {
    public let text: String
    public let tokenId: Int32
    public let probability: Float
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let voiceLength: Float

    public init(
        text: String,
        tokenId: Int32,
        probability: Float = 0.0,
        startTime: TimeInterval = 0.0,
        endTime: TimeInterval = 0.0,
        voiceLength: Float = 0.0
    ) {
        self.text = text
        self.tokenId = tokenId
        self.probability = max(0.0, min(1.0, probability))
        self.startTime = max(0.0, startTime)
        self.endTime = max(startTime, endTime)
        self.voiceLength = max(0.0, voiceLength)
    }

    public var duration: TimeInterval {
        endTime - startTime
    }

    public var isSpecialToken: Bool {
        text.hasPrefix("<|") && text.hasSuffix("|>")
    }
}
