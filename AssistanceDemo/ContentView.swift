//
//  ContentView.swift
//  AssistanceDemo
//
//  Created by JLYVM206TH on 21/3/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedImage: NSImage?
    @State private var responseText: String = "Response will appear here"
    @State private var isLoading = false
    @State private var isChatOpen = false
    @State private var isOpenVoiceRecognition = false
    @State private var userInput = ""
    private let openAIService = OpenAIService()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.3, alpha: 1)), Color(#colorLiteral(red: 0.2, green: 0.2, blue: 0.5, alpha: 1))]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                Text("Swift/SwiftUI Code Generator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                // Main action buttons container
                VStack(spacing: 16) {
                    // Generate from clipboard button
                    ActionButton(
                        title: "Generate Code From Clipboard",
                        icon: "clipboard.fill",
                        isLoading: isLoading,
                        accentColor: Color.green.opacity(0.8)
                    ) {
                        generateCodeFromClipboard()
                    }
                    
                    // Chat button
                    ActionButton(
                        title: "Chat with Assistant",
                        icon: "message.fill",
                        accentColor: Color.blue.opacity(0.8)
                    ) {
                        isChatOpen = true
                    }
                }
                .padding(.horizontal)
                
                // Response display area
                VStack(alignment: .leading, spacing: 10) {
                    Text("Response")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Processing ...")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                    } else {
                        ScrollView {
                            Text(responseText)
                                .padding()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 250)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // Status bar
                HStack {
                    Circle()
                        .fill(isLoading ? Color.yellow : Color.green)
                        .frame(width: 10, height: 10)
                    
                    Text(isLoading ? "Working..." : "Ready")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding()
        }
        .sheet(isPresented: $isChatOpen) {
            ChatBoxView(userInput: $userInput)
        }
        .sheet(isPresented: $isOpenVoiceRecognition) {
            SpeechToTextView()
        }
    }
    
    private func generateCodeFromClipboard() {
        if let image = getClipboardImage(), let base64String = convertImageToBase64(image) {
            isLoading = true
            openAIService.sendImageToOpenAI(base64String) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let content):
                        handleAPIResponse(content)
                    case .failure(let error):
                        responseText = "Error: \(error.localizedDescription)"
                    }
                }
            }
        } else if let text = getTextFromClipboard() {
            isLoading = true
            openAIService.sendStringToOpenAI(text) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let content):
                        handleAPIResponse(content)
                    case .failure(let error):
                        responseText = "Error: \(error.localizedDescription)"
                    }
                }
            }
        } else  {
            responseText = "No valid image found in clipboard."
        }
    }
    
    private func getClipboardImage() -> NSImage? {
        let pasteboard = NSPasteboard.general
        if let data = pasteboard.data(forType: .tiff), let image = NSImage(data: data) {
            return image
        }
        return nil
    }
    
    private func getTextFromClipboard() -> String? {
        let pastboard = NSPasteboard.general
        let text = pastboard.string(forType: .string)
        return text
    }
    
    private func convertImageToBase64(_ image: NSImage?) -> String? {
        guard let image = image,
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [:]) else {
            return nil
        }
        return jpegData.base64EncodedString()
    }
    
    private func handleAPIResponse(_ content: String) {
        if content.count > 1 {
            copySwiftFileToClipboard(fileContent: content.clearUnnecessaryCharacters())
        } else {
            responseText = "Answer: \(content)"
        }
    }
    
    private func copySwiftFileToClipboard(fileContent: String) {
        let name = extractStructName(from: fileContent)
        let fileName = "\(name).swift"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            try fileContent.write(to: tempURL, atomically: true, encoding: .utf8)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(fileContent, forType: .string)
            pasteboard.writeObjects([tempURL as NSURL])
            responseText = "Swift file '\(fileName)' copied to clipboard"
        } catch {
            responseText = "Error reading file: \(error)"
        }
    }
    
    private func extractStructName(from text: String) -> String {
        let pattern = #"struct\s+(\w+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return "Unknown"
    }
}

// Reusable action button
struct ActionButton: View {
    var title: String
    var icon: String
    var isLoading: Bool = false
    var accentColor: Color = Color.blue.opacity(0.8)
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .opacity(0.7)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        accentColor,
                        accentColor.opacity(0.7)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: accentColor.opacity(0.4), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

extension String {
    func clearUnnecessaryCharacters() -> String {
        self.replacingOccurrences(of: "```swift", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    ContentView()
}
