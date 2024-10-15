//
//  GordonViewModel.swift
//  Gordon
//
//  Created by admin63 on 15/10/24.
//

import Foundation
import Combine
import SwiftUI

class GordonViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var chatHistory: [Message] = []
    @Published var isLoading: Bool = false
    @Published var selectedImage: UIImage?
    
    private let apiHelper: APIHelper
    
    init(apiHelper: APIHelper = APIHelper()) {
        self.apiHelper = apiHelper
    }
    
    func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        let userMessage = Message(role: .user, content: .text(userInput))
        chatHistory.append(userMessage)
        
        isLoading = true
        
        if let image = selectedImage {
            sendImageMessage(image: image)
        } else {
            sendTextMessage()
        }
    }
    
    private func sendTextMessage() {
        apiHelper.getTextResponse(for: chatHistory) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleAPIResponse(result)
            }
        }
    }
    
    private func sendImageMessage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            handleAPIResponse(.failure(NSError(domain: "Image conversion failed", code: 0, userInfo: nil)))
            return
        }
        
        apiHelper.getImageResponse(for: userInput, imageData: imageData) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleAPIResponse(result)
            }
        }
    }
    
    private func handleAPIResponse(_ result: Result<String, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            let botMessage = Message(role: .model, content: .text(response))
            chatHistory.append(botMessage)
        case .failure(let error):
            let errorMessage = Message(role: .model, content: .text("Error: \(error.localizedDescription)"))
            chatHistory.append(errorMessage)
        }
        
        userInput = ""
        selectedImage = nil
    }
}
