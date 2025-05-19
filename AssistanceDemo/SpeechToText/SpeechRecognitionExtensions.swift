//
//  SpeechRecognitionExtensions.swift
//  SpeechToText
//
//  Created by legin098 on 10/10/24.
//

import Foundation
import Speech
import AVFoundation

extension SFSpeechRecognizer {
    /// Checks if the app has authorization to perform speech recognition.
    /// - Returns: `true` if authorized, `false` otherwise.
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

#if os(iOS)
import AVFoundation

extension AVAudioSession {
    /// Checks if the app has permission to record audio.
    /// - Returns: `true` if permission is granted, `false` otherwise.
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}
#elseif os(macOS)
import AVFoundation

struct MicrophonePermission {
    /// Checks if the app has permission to access the microphone on macOS.
    /// - Returns: `true` if permission is granted, `false` otherwise.
    static func hasPermissionToRecord() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }
}
#endif
