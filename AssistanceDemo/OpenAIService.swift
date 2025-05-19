//
//  OpenAIService.swift
//  AssistanceDemo
//
//  Created by JLYVM206TH on 22/3/25.
//

import Foundation
import SwiftUI

class OpenAIService {
    private let apiKey = ""  // Replace with actual API key
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    let prompt = """
    Analyze the attached image and determine its type. Based on the type, provide the appropriate response without any explanation and import neccessary library. The possible types are:

    1. if they are Figma Mobile App Design or something similar to mobile design: try to Convert it into SwiftUI code 100% ui and make the preview.
    2. or if Algorithm Problem: Provide the solution in Swift without any explanation.
    3. or if Multiple Choice Question: Respond with only the correct answer as a single character.
    4. or Trading Chart: Predict the next price using the format: "Price: [value]".
    5. or Json Data: Provide the corresponding Swift struct.
    6. or Text: Provide a summary or response algorithm solution based on the text content.
    7. or swift code: Provide the better solution with the same output.
    if the image is not related to any of the above types, try to make the swiftUI code for small view like child view
    

    Ensure the response is concise and directly follows the format specified above.
    """
    
    func sendImageToOpenAI(_ base64Image: String, completion: @escaping (Result<String, Error>) -> Void) {
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text",
                         "text": "\(prompt)"],
                        ["type": "image_url",
                         "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "DataError", code: -1, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: -2, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func sendStringToOpenAI(_ string: String, completion: @escaping (Result<String, Error>) -> Void) {
        let localPrompt = """
        Analyze the provided text and provide the appropriate response without any explanation and import neccessary library
        1. or Text: Provide a summary or response algorithm solution based on the text content in swift.
        2. or swift code: Provide the better solution with the same output in swift and runable solution.

        Ensure the response is concise and directly follows the format specified above.
        """
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text",
                         "text": "\(localPrompt)"],
                        ["type": "text", "text": string]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "DataError", code: -1, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: -2, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
