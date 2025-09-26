# WhisperKit

WhisperKit is a SwiftUI example application that demonstrates powerful on-device audio transcription (ASR) and voice activity detection (VAD) using whisper.cpp on Apple platforms.

## Features

- 🎤 Local audio transcription (multi-language support)
- 🔊 Voice activity detection (VAD)
- 🖥️ macOS 12+ support
- 📱 iOS 15+, tvOS 15+, visionOS 1+
- 🧩 High-performance inference powered by whisper.cpp

## Requirements

You must follow these requirements to run WhisperKit, otherwise it will likely not work as expected. We dont block you from compiling the code, but be sure to test them out.

- Swift 5.9 or later
- Supported platforms:
  - iOS 16.4+
  - macOS 13.3+ (Catalyst 16.4+)
  - tvOS 16.4+ 
  - visionOS 1.0+

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Lakr233/WhisperKit.git
cd WhisperKit/Example
```

### 2. Download Model File

Download the model file from [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-large-v3-turbo-q8_0.bin) and place it in:

```
Example/WhisperKitExample/Models/
```

> ⚠️ The example app will not work without the model file.

### 3. Open in Xcode

```bash
open WhisperKitExample.xcodeproj
```

### 4. Build & Run

Select your target device in Xcode and click Run to start using WhisperKit.

## Basic Usage

### Initialization

First, initialize WhisperKit with a model URL:

```swift
import WhisperKit

let modelURL = Bundle.main.url(forResource: "ggml-large-v3-turbo-q8_0", withExtension: "bin")!
let whisperKit = try WhisperKit(modelURL: modelURL)
```

### Transcribing Audio

To transcribe audio data, provide an array of Float values representing the audio samples:

```swift
let audioData: [Float] = // Your audio data here
let transcription = try whisperKit.transcribe(audioData: audioData)
print("Transcription: \(transcription.fullText)")
```

### Language Detection

Detect the language of the audio:

```swift
let language = try whisperKit.detectLanguage(from: audioData)
print("Detected language: \(language.languageCode)")
```

For more advanced usage, refer to the example app in the `Example/` directory.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

The submodule `whisper.cpp` is also licensed under the MIT License. Refer to the original repository for more information.

---

©️ 2025 Lakr Aream. All rights reserved.
