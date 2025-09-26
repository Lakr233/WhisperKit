//
//  WhisperKitManager.swift
//  WhisperKitExample
//
//  Created by 秋星桥 on 8/21/25.
//

import Foundation
import WhisperKit

class WhisperKitManager {
    static let shared = WhisperKitManager()
    private(set) var whisperKit: WhisperKit?
    private(set) var vadService: VADService?

    private init() {}

    func initialize() throws {
        vadService = try VADService()
        print("VADService initialized at \(vadService!)")

        guard let modelURL = Bundle.main
            .url(
                forResource: "ggml-large-v3-turbo-q8_0",
                withExtension: "bin",
                subdirectory: "Models"
            ),
            FileManager.default.fileExists(atPath: modelURL.path)
        else {
            throw NSError(
                domain: "WhisperKit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Model file not found"]
            )
        }

        whisperKit = try WhisperKit(modelURL: modelURL)
        print("WhisperKit initialized successfully")
    }
}
