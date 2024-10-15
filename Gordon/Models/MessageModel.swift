//
//  MessageModel.swift
//  Gordon
//
//  Created by admin63 on 15/10/24.
//

import Foundation
import SwiftUI

struct Message: Identifiable, Codable {
    let id: UUID
    let role: Role
    let content: MessageContent
    
    init(id: UUID = UUID(), role: Role, content: MessageContent) {
        self.id = id
        self.role = role
        self.content = content
    }
}

enum Role: String, Codable {
    case user
    case model
}

enum MessageContent: Codable {
    case text(String)
    case image(Data)
    
    var textContent: String? {
        switch self {
        case .text(let string):
            return string
        case .image:
            return nil
        }
    }
    
    var imageData: Data? {
        switch self {
        case .text:
            return nil
        case .image(let data):
            return data
        }
    }
}
