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

    @State private var transcriptionText = "Drag an audio file here to start transcription..."
    @State private var isProcessing = false
    @State private var isDragOver = false
    @State private var processingProgress = ""
    @State private var audioFileName = ""
    @State private var transcriptionResult: TranscriptionResult?
    @State private var selectedLanguage = "auto"
    @State private var showLanguageSettings = false

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 20) {
            headerView
            settingsView
            dropAreaView
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
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("WhisperKit Audio Transcription")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Supports mp3, wav, m4a, aac and other audio formats")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var settingsView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Language Settings")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text("Selected Language:")
                    .foregroundStyle(.secondary)
                Spacer()

                Button(action: { showLanguageSettings.toggle() }) {
                    HStack {
                        Text(languageDisplayName)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                #if canImport(UIKit)
                    .sheet(isPresented: $showLanguageSettings) {
                        NavigationView {
                            languageSelectionView
                                .navigationTitle("Select Language")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Done") {
                                            showLanguageSettings = false
                                        }
                                    }
                                }
                        }
                    }
                #else
                    .popover(isPresented: $showLanguageSettings) {
                            languageSelectionView
                        }
                #endif
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var languageSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            #if !canImport(UIKit)
                Text("Select Language")
                    .font(.headline)
                    .padding(.horizontal)
            #endif

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(supportedLanguages, id: \.code) { language in
                        Button(action: {
                            selectedLanguage = language.code
                            showLanguageSettings = false
                        }) {
                            HStack {
                                Text(language.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedLanguage == language.code {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background(selectedLanguage == language.code ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                    }
                }
            }
            #if canImport(UIKit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #else
            .frame(width: 200, height: 300)
            #endif
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    private var dropAreaView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragOver ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .strokeBorder(
                    isDragOver ? Color.blue : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
            #if canImport(UIKit)
                .frame(height: 100)
            #else
                .frame(height: 120)
            #endif

            VStack(spacing: 8) {
                Image(systemName: isDragOver ? "arrow.down.circle.fill" : "plus.circle.dashed")
                #if canImport(UIKit)
                    .font(.title)
                #else
                    .font(.largeTitle)
                #endif
                    .foregroundStyle(isDragOver ? .blue : .gray)

                Group {
                    #if canImport(UIKit)
                        Text(isDragOver ? "Drop to add file" : "Tap to select audio file")
                    #else
                        Text(isDragOver ? "Drop to add file" : "Drag audio file here")
                    #endif
                }
                .font(.headline)
                .foregroundStyle(isDragOver ? .blue : .gray)

                if !audioFileName.isEmpty {
                    Text("Current file: \(audioFileName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        #if canImport(UIKit)
        .onTapGesture {
            // iOS: Show file picker
            // TODO: Implement file picker for iOS
        }
        #endif
        .onDrop(of: [.audio], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
            return true
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
    private var supportedLanguages: [LanguageOption] {
        LanguageUtilities.getCommonLanguageOptions()
    }

    private var languageDisplayName: String {
        supportedLanguages.first { $0.code == selectedLanguage }?.name ?? "Auto Detect"
    }

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        provider.loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil) { item, error in
            if let error {
                print("Error loading item: \(error)")
                return
            }

            guard let url = item as? URL else {
                print("Item is not a URL")
                return
            }

            DispatchQueue.main.async {
                audioFileName = url.lastPathComponent
                processAudioFile(url: url)
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
                case let .progress(progress, _, _):
                    self.processingProgress = "Transcription progress: \(Int(progress * 100))%"
                case let .segmentCompleted(text, _, _):
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
