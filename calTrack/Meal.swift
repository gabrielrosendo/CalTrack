//
//  Meal.swift
//  calTrack
//
//  Created by Gabriel on 11/9/24.
//

import Foundation

struct Meal: Identifiable {
    var id: String
    var name: String
    var calories: Int
    var carbs: Int
    var fat: Int
    var protein: Int
}
