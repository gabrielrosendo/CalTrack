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
    
    struct Meal: Identifiable, Decodable, Equatable {
        var name: String
        var calories: Int
        var carbs: Int
        var fat: Int
        var protein: Int
        
        var id: String { name }

        // Conform to Equatable by providing the == operator
        static func ==(lhs: Meal, rhs: Meal) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.calories == rhs.calories &&
                   lhs.carbs == rhs.carbs &&
                   lhs.fat == rhs.fat &&
                   lhs.protein == rhs.protein
        }
    }
}
