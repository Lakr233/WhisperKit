//
//  WhisperEvent.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public enum WhisperEvent {
    case progress(progress: Float, segment: Int, totalSegments: Int)
    case segmentCompleted(text: String, startTime: TimeInterval, endTime: TimeInterval)
    case encodingStarted
    case encodingCompleted
    case languageDetected(language: String, probability: Float)
    case failed(error: WhisperError)
    case success(result: TranscriptionResult)
}
