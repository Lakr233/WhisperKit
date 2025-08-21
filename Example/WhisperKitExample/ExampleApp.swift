//
//  ExampleApp.swift
//  WhisperKitExample
//
//  Created by 秋星桥 on 8/20/25.
//

import SwiftUI

struct ExampleApp: App {
    @State var initialized = false

    var body: some Scene {
        WindowGroup {
            if initialized {
                MainView()
            } else {
                ProgressView()
                    .onAppear {
                        DispatchQueue.global().async {
                            do {
                                try WhisperKitManager.shared.initialize()
                                DispatchQueue.main.async {
                                    initialized = true
                                }
                            } catch {
                                fatalError(error.localizedDescription)
                            }
                        }
                    }
                    .frame(width: 800, height: 600)
            }
        }
    }
}
