//
//  WhisperEvent.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public enum WhisperEvent {
    case languageDetectionBegin
    case languageDetected(language: String, probability: Float)
    case languageDetectionEnd
    case transcribeBegin
    case transcribeReceivedProgress(progress: Progress)
    case transcribeReceivedSegment(text: String, startTime: TimeInterval, endTime: TimeInterval)
    case transcribeEnd
    case failed(error: WhisperError)
    case success(result: TranscriptionResult)
}
