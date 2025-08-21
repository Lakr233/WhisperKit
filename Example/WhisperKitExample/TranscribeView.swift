//
//  TranscribeView.swift
//  WhisperKitExample
//
//  Created by 秋星桥 on 8/21/25.
//

import AVFoundation
import SwiftUI
import UniformTypeIdentifiers
import WhisperKit

#if canImport(UIKit)
    import UIKit
#endif

struct TranscribeView: View {
    // MARK: - State Properties

    @State private var transcriptionText = "Click to select an audio file to start transcription..."
    @State private var isProcessing = false
    @State private var processingProgress = ""
    @State private var audioFileName = ""
    @State private var transcriptionResult: TranscriptionResult?
    @State private var selectedLanguage = "auto"
    @State private var showLanguageSettings = false

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 20) {
            fileSelectionView
            processingView
            transcriptionResultView
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Audio Transcription")
    }
}

// MARK: - View Components

extension TranscribeView {
    private var fileSelectionView: some View {
        VStack(spacing: 12) {
            Button(action: selectAudioFile) {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                    #if canImport(UIKit)
                        .font(.title)
                    #else
                        .font(.largeTitle)
                    #endif
                        .foregroundStyle(.blue)

                    Text("Select Audio File")
                        .font(.headline)
                        .foregroundStyle(.blue)

                    Text("Click to choose an audio file")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                #if canImport(UIKit)
                    .frame(height: 100)
                #else
                    .frame(height: 120)
                #endif
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    .background(Color.blue.opacity(0.1))
            )
            .cornerRadius(12)

            if !audioFileName.isEmpty {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundStyle(.green)
                    Text("Selected: \(audioFileName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var processingView: some View {
        if isProcessing {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(processingProgress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var transcriptionResultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                resultHeaderView
                transcriptionContentView
                if transcriptionResult != nil {
                    metadataView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultHeaderView: some View {
        HStack {
            Text("Transcription Result")
                .font(.headline)
            Spacer()
            if transcriptionResult != nil {
                Button("Copy") {
                    copyToClipboard()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private var transcriptionContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if transcriptionResult != nil {
                Text(transcriptionText)
                    .textSelection(.enabled)
                    .font(.body)
                    .lineSpacing(4)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(8)
            } else {
                Text(transcriptionText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private var metadataView: some View {
        if let result = transcriptionResult {
            VStack(alignment: .leading, spacing: 8) {
                Text("Processing Information")
                    .font(.headline)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], alignment: .leading, spacing: 8) {
                    if let language = result.detectedLanguage {
                        MetadataItem(title: "Detected Language", value: language)
                    }

                    MetadataItem(title: "Processing Time", value: "\(String(format: "%.2f", result.processingTime))s")
                    MetadataItem(title: "Audio Duration", value: "\(String(format: "%.2f", result.audioLength))s")

                    if result.realTimeFactor > 0 {
                        MetadataItem(title: "Real-time Factor", value: "\(String(format: "%.2f", result.realTimeFactor))x")
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

// MARK: - Helper Views

struct MetadataItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Data Models

// MARK: - Data Processing Methods

enum TranscriptionError: Error {
    case whisperNotInitialized
}

extension TranscribeView {
    private func selectAudioFile() {
        FileUtilities.presentAudioFilePicker { url in
            guard let url else { return }

            DispatchQueue.main.async {
                self.audioFileName = FileUtilities.getDisplayName(for: url)
                self.processAudioFile(url: url)
            }
        }
    }

    private func processAudioFile(url: URL) {
        isProcessing = true
        processingProgress = "Loading audio file..."
        transcriptionText = "Processing, please wait..."

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let audioData = try AudioUtilities.loadAudioData(from: url) { progress in
                    DispatchQueue.main.async {
                        self.processingProgress = "Loading audio: \(Int(progress * 100))%"
                    }
                }

                DispatchQueue.main.async {
                    self.processingProgress = "Transcribing audio..."
                }

                guard let whisper = self.getWhisperInstance() else {
                    throw TranscriptionError.whisperNotInitialized
                }

                let result = try whisper.transcribe(
                    audioData: audioData,
                    eventHandler: createEventHandler()
                )

                DispatchQueue.main.async {
                    self.handleTranscriptionSuccess(result)
                }

            } catch {
                DispatchQueue.main.async {
                    self.handleTranscriptionError(error)
                }
            }
        }
    }

    private func createEventHandler() -> (WhisperEvent) -> Void {
        { event in
            print(event)
            DispatchQueue.main.async {
                switch event {
                case let .transcribeReceivedProgress(progress):
                    self.processingProgress = "Transcription progress: \(Int(progress.fractionCompleted * 100))%"
                case let .transcribeReceivedSegment(text, _, _):
                    self.processingProgress = "Processing segment: \(text.prefix(20))..."
                default:
                    break
                }
            }
        }
    }

    private func handleTranscriptionSuccess(_ result: TranscriptionResult) {
        transcriptionResult = result
        transcriptionText = result.fullText.isEmpty ? "No speech content detected" : result.fullText
        isProcessing = false
        processingProgress = ""
    }

    private func handleTranscriptionError(_ error: Error) {
        transcriptionText = "Transcription failed: \(error.localizedDescription)"
        isProcessing = false
        processingProgress = ""
    }

    private func copyToClipboard() {
        guard let result = transcriptionResult else { return }

        #if canImport(UIKit)
            UIPasteboard.general.string = result.fullText
        #else
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.fullText, forType: .string)
        #endif
    }

    private func getWhisperInstance() -> WhisperKit? {
        WhisperKitManager.shared.whisperKit
    }
}

#Preview {
    TranscribeView()
}
