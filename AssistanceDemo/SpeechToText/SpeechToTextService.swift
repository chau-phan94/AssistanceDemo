//
//  SpeechToTextService.swift
//  SpeechToText
//
//  Created by legin098 on 10/10/24.
//

import AVFoundation
import Foundation
import Speech

class SpeechToTextService: SpeechToTextServiceProtocol {
    private var accumulatedText: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    init(localeIdentifier: String = Locale.current.identifier) {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
    
    func authorize() async throws {
        guard let recognizer = self.recognizer else {
            throw RecognizerError.recognizerUnavailable
        }
        
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .notDetermined:
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    continuation.resume()
                }
            }
        case .denied, .restricted:
            throw RecognizerError.notAuthorizedToRecognize
        case .authorized:
            break
        @unknown default:
            throw RecognizerError.recognizerUnavailable
        }
        
        if !recognizer.isAvailable {
            throw RecognizerError.recognizerUnavailable
        }
    }
    
    deinit {
        reset()
    }
    
    @MainActor
    func transcribe() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (audioEngine, request) = try Self.prepareEngine()
                    self.audioEngine = audioEngine
                    self.request = request
                    
                    guard let recognizer = self.recognizer else {
                        throw RecognizerError.recognizerUnavailable
                    }
                    
                    self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                        guard let self = self else {
                            return
                        }
                        
                        if let error = error {
                            continuation.finish(throwing: error)
                            self.reset()
                            return
                        }
                        print(result)
                        if let result = result {
                            let newText = result.bestTranscription.formattedString
                            continuation.yield(self.accumulatedText + newText)
                            
                            if result.speechRecognitionMetadata != nil {
                                self.accumulatedText += newText + " "
                            }
                            
                            if result.isFinal {
                                continuation.finish()
                                self.reset()
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                    self.reset()
                }
            }
        }
    }
    
    func stopTranscribing() {
        reset()
    }
    
    func reset() {
        task?.cancel()
        task = nil
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        accumulatedText = ""
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.addsPunctuation = true
        request.taskHint = .dictation
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
}
