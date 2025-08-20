//
//  VADSegment.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct VADSegment {
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let probability: Float

    public init(startTime: TimeInterval, endTime: TimeInterval, probability: Float = 1.0) {
        self.startTime = startTime
        self.endTime = endTime
        self.probability = probability
    }

    public var duration: TimeInterval {
        endTime - startTime
    }
}
