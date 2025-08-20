//
//  ModelInfo.swift
//  WhisperKit
//
//  Created by 秋星桥 on 8/20/25.
//

public struct ModelInfo {
    public let vocabularySize: Int
    public let audioContextSize: Int
    public let textContextSize: Int
    public let audioLayers: Int
    public let textLayers: Int
    public let audioHeads: Int
    public let textHeads: Int
    public let melBands: Int
    public let modelType: String
    public let isMultilingual: Bool
    public let version: String

    public init(
        vocabularySize: Int,
        audioContextSize: Int,
        textContextSize: Int,
        audioLayers: Int,
        textLayers: Int,
        audioHeads: Int,
        textHeads: Int,
        melBands: Int,
        modelType: String,
        isMultilingual: Bool,
        version: String
    ) {
        self.vocabularySize = vocabularySize
        self.audioContextSize = audioContextSize
        self.textContextSize = textContextSize
        self.audioLayers = audioLayers
        self.textLayers = textLayers
        self.audioHeads = audioHeads
        self.textHeads = textHeads
        self.melBands = melBands
        self.modelType = modelType
        self.isMultilingual = isMultilingual
        self.version = version
    }
}
