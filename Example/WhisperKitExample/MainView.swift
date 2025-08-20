//
//  MainView.swift
//  WhisperKitExample
//
//  Created by 秋星桥 on 8/21/25.
//

import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case transcribe = "Transcribe"
    case vad = "VAD"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .transcribe: "waveform.and.mic"
        case .vad: "waveform.circle"
        }
    }

    var title: String {
        switch self {
        case .transcribe: "Transcription"
        case .vad: "Voice Activity Detection"
        }
    }

    var description: String {
        switch self {
        case .transcribe: "Convert audio files to text"
        case .vad: "Analyze speech activity segments"
        }
    }
}

struct MainView: View {
    @State private var selectedItem: SidebarItem = .transcribe

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private var sidebarView: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            NavigationLink(value: item) {
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("WhisperKit Demo")
        .frame(minWidth: 250)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .transcribe: TranscribeView()
        case .vad: VADView()
        }
    }
}

#Preview { MainView() }
