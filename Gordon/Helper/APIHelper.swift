//
//  APIHelper.swift
//  Gordon
//
//  Created by admin63 on 15/10/24.
//

import Foundation
import UIKit

class APIHelper {
    private let apiKey: String
    private let baseURL: String
    private let textModel: String
    private let imageModel: String
    
    init() {
        guard let path = Bundle.main.path(forResource: "APIConfig", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            fatalError("Couldn't find APIConfig.plist")
        }
        
        self.apiKey = dict["API_KEY"] as? String ?? ""
        self.baseURL = dict["BASE_URL"] as? String ?? ""
        self.textModel = dict["TEXT_MODEL"] as? String ?? "gemini-1.5-flash"
        self.imageModel = dict["IMAGE_MODEL"] as? String ?? "gemini-1.5-flash"
        
        print("APIHelper initialized with:")
        print("Base URL: \(baseURL)")
        print("Text Model: \(textModel)")
        print("Image Model: \(imageModel)")
    }
    
    func getTextResponse(for messages: [Message], completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/models/\(textModel):generateContent?key=\(apiKey)")!
        print("Text API URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": messages.map { [
                "role": $0.role.rawValue,
                "parts": [["text": $0.content.textContent ?? ""]]
            ]}
        ]
        
        print("Text API Request Body: \(body)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("Text API Response received")
            self.handleResponse(data: data, error: error, completion: completion)
        }.resume()
    }
    
    func getImageResponse(for prompt: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Image conversion failed", code: 0, userInfo: nil)))
            return
        }
        
        let uploadURL = URL(string: "\(baseURL)/upload/v1beta/files?key=\(apiKey)")!
        print("Image Upload URL: \(uploadURL)")
        
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "POST"
        uploadRequest.addValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        uploadRequest.addValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        uploadRequest.addValue("\(imageData.count)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        uploadRequest.addValue("image/jpeg", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
        uploadRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let uploadMetadata = ["file": ["display_name": "UploadedImage"]]
        uploadRequest.httpBody = try? JSONSerialization.data(withJSONObject: uploadMetadata)
        
        print("Image Upload Request Headers: \(uploadRequest.allHTTPHeaderFields ?? [:])")
        print("Image Upload Request Body: \(uploadMetadata)")
        
        URLSession.shared.dataTask(with: uploadRequest) { data, response, error in
            print("Image Upload Response received")
            if let error = error {
                print("Image Upload Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP Response")
                completion(.failure(NSError(domain: "Invalid HTTP Response", code: 0, userInfo: nil)))
                return
            }
            
            print("Image Upload Response Status Code: \(httpResponse.statusCode)")
            print("Image Upload Response Headers: \(httpResponse.allHeaderFields)")
            
            guard let uploadURL = httpResponse.allHeaderFields["X-Goog-Upload-URL"] as? String else {
                print("Upload URL not found in response headers")
                completion(.failure(NSError(domain: "Upload URL not found", code: 0, userInfo: nil)))
                return
            }
            
            print("Retrieved Upload URL: \(uploadURL)")
            
            self.uploadImage(to: uploadURL, imageData: imageData) { result in
                switch result {
                case .success(let fileInfo):
                    print("Image Upload Successful. File Info: \(fileInfo)")
                    self.generateContentFromImage(prompt: prompt, fileInfo: fileInfo, completion: completion)
                case .failure(let error):
                    print("Image Upload Failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    private func uploadImage(to url: String, imageData: Data, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        print("Uploading image to: \(url)")
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        request.addValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        request.addValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        request.httpBody = imageData
        
        print("Image Data Upload Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("Image Data Upload Response received")
            if let error = error {
                print("Image Data Upload Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("No data received from Image Data Upload")
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            print("Image Data Upload Response: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let fileInfo = json["file"] as? [String: Any] else {
                    print("Invalid JSON response from Image Data Upload")
                    completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                    return
                }
                
                print("File Info retrieved: \(fileInfo)")
                completion(.success(fileInfo))
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func generateContentFromImage(prompt: String, fileInfo: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        guard let fileURI = fileInfo["uri"] as? String else {
            completion(.failure(NSError(domain: "Invalid file info", code: 0, userInfo: nil)))
            return
        }
        
        let url = URL(string: "\(baseURL)/models/\(imageModel):generateContent?key=\(apiKey)")!
        print("Image Content Generation URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["file_data": [
                        "mime_type": "image/jpeg",
                        "file_uri": fileURI
                    ]],
                    ["text": prompt]
                ]
            ]]
        ]
        
        print("Image Content Generation Request Body: \(body)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("Image Content Generation Response received")
            self.handleResponse(data: data, error: error, completion: completion)
        }.resume()
    }
    
    private func handleResponse(data: Data?, error: Error?, completion: @escaping (Result<String, Error>) -> Void) {
        if let error = error {
            print("API Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            print("No data received from API")
            completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
            return
        }
        
        print("API Response: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                print("Extracted response text: \(text)")
                completion(.success(text))
            } else {
                print("Invalid response format")
                completion(.failure(NSError(domain: "Invalid response format", code: 0, userInfo: nil)))
            }
        } catch {
            print("JSON Parsing Error: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}
