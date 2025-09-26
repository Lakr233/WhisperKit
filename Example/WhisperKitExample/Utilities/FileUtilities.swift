//
//  FileUtilities.swift
//  WhisperKitExample
//
//  Created by 秋星桥 on 8/21/25.
//

import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
    import MobileCoreServices
    import UIKit
#else
    import AppKit
#endif

/// Utilities for file selection and management
public enum FileUtilities {
    /// Present a file picker for audio files
    /// - Parameters:
    ///   - completion: Callback with selected file URL or nil if cancelled
    public static func presentAudioFilePicker(completion: @escaping (URL?) -> Void) {
        #if canImport(UIKit)
            presentDocumentPicker(completion: completion)
        #else
            presentNSOpenPanel(completion: completion)
        #endif
    }

    #if canImport(UIKit)
        private static func presentDocumentPicker(completion: @escaping (URL?) -> Void) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController
            else {
                completion(nil)
                return
            }

            let documentPicker = UIDocumentPickerViewController(
                forOpeningContentTypes: [
                    .audio,
                    UTType(filenameExtension: "mp3") ?? .audio,
                    UTType(filenameExtension: "wav") ?? .audio,
                    UTType(filenameExtension: "m4a") ?? .audio,
                    UTType(filenameExtension: "aac") ?? .audio,
                    UTType(filenameExtension: "flac") ?? .audio,
                    UTType(filenameExtension: "ogg") ?? .audio,
                ],
                asCopy: true
            )

            let coordinator = DocumentPickerCoordinator(completion: completion)
            documentPicker.delegate = coordinator

            // Store coordinator to prevent deallocation
            objc_setAssociatedObject(
                documentPicker,
                &AssociatedObjectKeys.coordinator,
                coordinator,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            rootViewController.present(documentPicker, animated: true)
        }

        private enum AssociatedObjectKeys {
            static var coordinator = "coordinator"
        }

        private class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
            private let completion: (URL?) -> Void

            init(completion: @escaping (URL?) -> Void) {
                self.completion = completion
            }

            func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                completion(urls.first)
            }

            func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
                completion(nil)
            }
        }

    #else
        private static func presentNSOpenPanel(completion: @escaping (URL?) -> Void) {
            let openPanel = NSOpenPanel()
            openPanel.title = "Choose an Audio File"
            openPanel.showsResizeIndicator = true
            openPanel.showsHiddenFiles = false
            openPanel.canChooseDirectories = false
            openPanel.canCreateDirectories = false
            openPanel.allowsMultipleSelection = false
            openPanel.allowedContentTypes = [
                .audio,
                UTType(filenameExtension: "mp3") ?? .audio,
                UTType(filenameExtension: "wav") ?? .audio,
                UTType(filenameExtension: "m4a") ?? .audio,
                UTType(filenameExtension: "aac") ?? .audio,
                UTType(filenameExtension: "flac") ?? .audio,
                UTType(filenameExtension: "ogg") ?? .audio,
            ]

            openPanel.begin { result in
                DispatchQueue.main.async {
                    if result == .OK {
                        completion(openPanel.url)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    #endif

    /// Check if a file URL is a supported audio format
    /// - Parameter url: The file URL to check
    /// - Returns: True if the file is a supported audio format
    public static func isSupportedAudioFormat(url: URL) -> Bool {
        let supportedExtensions = ["mp3", "wav", "m4a", "aac", "flac", "ogg", "mp4", "mov", "avi"]
        let fileExtension = url.pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }

    /// Get a user-friendly display name for a file
    /// - Parameter url: The file URL
    /// - Returns: Display name for the file
    public static func getDisplayName(for url: URL) -> String {
        url.lastPathComponent
    }
}
