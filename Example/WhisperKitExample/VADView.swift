import AVFoundation
import SwiftUI
import UniformTypeIdentifiers
import WhisperKit

struct VADView: View {
    @State private var isProcessing = false
    @State private var processingProgress = ""
    @State private var audioFileName = ""
    @State private var vadSegments: [VADSegment] = []
    @State private var vadProcessingTime: TimeInterval = 0
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            fileSelectionView
            processingView
            vadResultView
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Voice Activity Detection")
    }

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

    @ViewBuilder
    private var vadResultView: some View {
        if !vadSegments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Detected \(vadSegments.count) voice segments")
                    .font(.headline)
                if vadProcessingTime > 0 {
                    Text("VAD processing time: \(String(format: "%.3f", vadProcessingTime))s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                let totalSpeechDuration = vadSegments.reduce(0) { $0 + $1.duration }
                Text("Total speech duration: \(String(format: "%.2f", totalSpeechDuration))s")
                    .font(.caption)
                Divider()
                ScrollView {
                    ForEach(Array(vadSegments.enumerated()), id: \ .offset) { idx, seg in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Segment \(idx + 1): \(String(format: "%.2f", seg.startTime))s - \(String(format: "%.2f", seg.endTime))s (\(String(format: "%.2f", seg.duration))s), Confidence: \(String(format: "%.2f", seg.probability))")
                                .font(.caption)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .frame(maxHeight: 200)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        } else if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        }
    }

    private func selectAudioFile() {
        FileUtilities.presentAudioFilePicker { url in
            guard let url else { return }

            DispatchQueue.main.async {
                audioFileName = FileUtilities.getDisplayName(for: url)
                processAudioFile(url: url)
            }
        }
    }

    private func processAudioFile(url: URL) {
        isProcessing = true
        processingProgress = "Loading audio file..."
        vadSegments = []
        vadProcessingTime = 0
        errorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let audioData = try AudioUtilities.loadAudioData(from: url) { progress in
                    DispatchQueue.main.async {
                        processingProgress = "Loading audio: \(Int(progress * 100))%"
                    }
                }
                let vadStartTime = Date()
                DispatchQueue.main.async {
                    processingProgress = "Analyzing speech segments..."
                }
                guard let vadService = WhisperKitManager.shared.vadService else {
                    throw WhisperError.vadNotInitialized
                }
                let detectedSegments = try vadService.detectSpeechSegments(in: audioData)
                vadProcessingTime = Date().timeIntervalSince(vadStartTime)
                DispatchQueue.main.async {
                    vadSegments = detectedSegments
                    isProcessing = false
                    processingProgress = ""
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "VAD detection failed: \(error.localizedDescription)"
                    isProcessing = false
                    processingProgress = ""
                }
            }
        }
    }
}
