//
//  ChatBoxView.swift
//  AssistanceDemo
//
//  Created by JLYVM206TH on 21/3/25.
//


import SwiftUI

class ChatService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ message: String) async throws -> String {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "developer",
                    "content": message
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatError.invalidResponse
        }
        
        return content
    }
}

enum ChatError: Error {
    case invalidResponse
    case networkError(Error)
}

struct ChatBoxView: View {
    @Binding var userInput: String
    @State private var responseText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    private let chatService = ChatService(apiKey: "YOUR_API_KEY") // Move this to a secure configuration
    
    var body: some View {
        VStack {
            Text("Enter your message:")
                .font(.headline)
                .padding()
            
            TextEditor(text: $userInput)
                .frame(height: 150)
                .border(Color.gray, width: 1)
                .padding()
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .padding()
                .disabled(isLoading)
                
                Spacer()
                
                Button("Send") {
                    Task {
                        await sendPrompt()
                    }
                }
                .padding()
                .disabled(userInput.isEmpty || isLoading)
            }
        }
        .padding()
        .frame(width: 500, height: 350)
    }
    
    private func sendPrompt() async {
        isLoading = true
        errorMessage = nil
        
        do {
            responseText = try await chatService.sendMessage(userInput)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
