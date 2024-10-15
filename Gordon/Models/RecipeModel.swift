//
//  RecipeModel.swift
//  Gordon
//
//  Created by admin63 on 15/10/24.
//

import Foundation

struct Recipe: Identifiable, Codable {
    let id: UUID
    let name: String
    let ingredients: [String]
    let instructions: [String]
    
    init(id: UUID = UUID(), name: String, ingredients: [String], instructions: [String]) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
    }
}
