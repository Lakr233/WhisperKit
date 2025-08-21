import AVFoundation
import SwiftUI
import UniformTypeIdentifiers
import WhisperKit

struct VADView: View {
    @State private var isProcessing = false
    @State private var isDragOver = false
    @State private var processingProgress = ""
    @State private var audioFileName = ""
    @State private var vadSegments: [VADSegment] = []
    @State private var vadProcessingTime: TimeInterval = 0
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            headerView
            dropAreaView
            processingView
            vadResultView
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Voice Activity Detection")
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("WhisperKit Voice Activity Detection")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Supports mp3, wav, m4a, aac and other audio formats")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
