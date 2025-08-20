//
//  SpecialTokens.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

import Foundation

public struct SpecialTokens {
    public let endOfText: Int32
    public let startOfText: Int32
    public let startOfLanguageModel: Int32
    public let previous: Int32
    public let noSpeech: Int32
    public let notTimestamp: Int32
    public let beginning: Int32
    public let translate: Int32
    public let transcribe: Int32

    public init(
        endOfText: Int32,
        startOfText: Int32,
        startOfLanguageModel: Int32,
        previous: Int32,
        noSpeech: Int32,
        notTimestamp: Int32,
        beginning: Int32,
        translate: Int32,
        transcribe: Int32
    ) {
        self.endOfText = endOfText
        self.startOfText = startOfText
        self.startOfLanguageModel = startOfLanguageModel
        self.previous = previous
        self.noSpeech = noSpeech
        self.notTimestamp = notTimestamp
        self.beginning = beginning
        self.translate = translate
        self.transcribe = transcribe
    }
}
