//
//  GordonViewModel.swift
//  Gordon
//
//  Created by admin63 on 15/10/24.
//

import Foundation
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
        guard !userInput.isEmpty || selectedImage != nil else { return }
        
        isLoading = true
        
        if let image = selectedImage {
            sendImageMessage(image: image)
        } else {
            sendTextMessage()
        }
    }
    
    private func sendTextMessage() {
        let userMessage = Message(role: .user, content: .text(userInput))
        chatHistory.append(userMessage)
        
        apiHelper.getTextResponse(for: chatHistory) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleAPIResponse(result)
            }
        }
    }
    
    private func sendImageMessage(image: UIImage) {
        let userMessage = Message(role: .user, content: .image(image.jpegData(compressionQuality: 0.8)!))
        chatHistory.append(userMessage)
        
        apiHelper.getImageResponse(for: userInput, image: image) { [weak self] result in
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
