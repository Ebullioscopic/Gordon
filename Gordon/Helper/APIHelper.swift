//
//  APIHelper.swift
//  Gordon
//
//  Created by admin63 on 15/10/24.
//

import Foundation

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
    }
    
    func getTextResponse(for messages: [Message], completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/models/\(textModel):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": messages.map { [
                "role": $0.role.rawValue,
                "parts": [["text": $0.content.textContent ?? ""]]
            ]}
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, error: error, completion: completion)
        }.resume()
    }
    
    func getImageResponse(for prompt: String, imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let uploadURL = URL(string: "\(baseURL)/upload/v1beta/files?key=\(apiKey)")!
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "POST"
        uploadRequest.addValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        uploadRequest.addValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        uploadRequest.addValue("\(imageData.count)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        uploadRequest.addValue("image/jpeg", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
        uploadRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let uploadMetadata = ["file": ["display_name": "UploadedImage"]]
        uploadRequest.httpBody = try? JSONSerialization.data(withJSONObject: uploadMetadata)
        
        URLSession.shared.dataTask(with: uploadRequest) { _, response, _ in
            guard let httpResponse = response as? HTTPURLResponse,
                  let uploadURL = httpResponse.allHeaderFields["X-Goog-Upload-URL"] as? String else {
                completion(.failure(NSError(domain: "Upload URL not found", code: 0, userInfo: nil)))
                return
            }
            
            self.uploadImage(to: uploadURL, imageData: imageData) { result in
                switch result {
                case .success(let fileURI):
                    self.generateContentFromImage(prompt: prompt, fileURI: fileURI, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    private func uploadImage(to url: String, imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        request.addValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        request.addValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        request.httpBody = imageData
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fileURI = json["file"] as? [String: Any],
                  let uri = fileURI["uri"] as? String else {
                completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                return
            }
            
            completion(.success(uri))
        }.resume()
    }
    
    private func generateContentFromImage(prompt: String, fileURI: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/models/\(imageModel):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["file_data": [
                        "mime_type": "image/jpeg",
                        "file_uri": fileURI
                    ]]
                ]
            ]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, error: error, completion: completion)
        }.resume()
    }
    
    private func handleResponse(data: Data?, error: Error?, completion: @escaping (Result<String, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                completion(.success(text))
            } else {
                completion(.failure(NSError(domain: "Invalid response format", code: 0, userInfo: nil)))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
