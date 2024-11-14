import Foundation

struct User: Identifiable, Decodable {
    let _id: String
    var username: String
    var calorieGoal: Int
    var carbsGoal: Int
    var fatGoal: Int
    var proteinGoal: Int
    var meals: [Meal]
    
    var id: String { _id } 
    
    struct Meal: Identifiable, Decodable {
        var name: String
        var calories: Int
        var carbs: Int
        var fat: Int
        var protein: Int
        
        var id: String { name }
    }
}
