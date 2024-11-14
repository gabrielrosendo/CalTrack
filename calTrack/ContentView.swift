import SwiftUI

struct ContentView: View {
    @StateObject var userViewModel = UserViewModel()
    
    var body: some View {
        NavigationView {
                VStack {
                    Text("Calorie Tracker")
                    switch userViewModel.loadingState {
                    case .loading:
                        ProgressView()
                        Text("Loading data...")
                            .padding()
                    case .loaded:
                        if let user = userViewModel.users.first {
                            UserContentView(user: user)
                        } else {
                            Text("No user data available")
                                .font(.title)
                                .padding()
                        }
                    case .error(let message):
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text("Error: \(message)")
                                .padding()
                            Button("Retry") {
                                userViewModel.fetchUsers()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
                .background(Color.black)
                .foregroundColor(.white)
            }
        .onAppear {
            userViewModel.fetchUsers()
        }
    }
}

struct UserContentView: View {
    let user: User
    var totalCalories: Int {
        user.meals.reduce(0) {$0 + $1.calories}
    }
    
    var body: some View {
        TabView{
            VStack {
                Text("Welcome, \(user.username)")
                    .font(.largeTitle)
                    .bold()
                
                Text("Calories")
                    .font(.title2)
                
                CalorieBar(user: user)
                
                ProgressSection(user: user)
                
            }
            .padding()
            .tag(0)
            VStack{
                Text("Meals Logged")
                    .font(.title2)
                    .padding([.top, .leading])
                
                MealListView(meals: user.meals)
            }
            .padding()
            .tag(1)
        }
        .tabViewStyle(.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CalorieBar: View {
    var user: User
    // Calculate the total calories consumed from meals
    var totalCalories: Int {
        user.meals.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if totalCalories >= user.calorieGoal {
                Text("Congrats! You've hit your calorie goal for the day")
            }
            else{
                Text("You need \(user.calorieGoal - totalCalories) more calories to reach your goal")
            }
            // Progress Bar showing the calorie intake
            ProgressView(value: Double(totalCalories), total: Double(user.calorieGoal))
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.vertical)
        
            Text("\(totalCalories) / \(user.calorieGoal)")
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

// Progress Section to show calorie/macros progress
struct ProgressSection: View {
    var user: User
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Progress")
                .font(.title2)
                .bold()
                .padding([.top, .leading])
            
            ProgressCircleView(
                calories: (current: currentCalories(user: user), goal: user.calorieGoal),
                carbs: (current: currentCarbs(user: user), goal: user.carbsGoal),
                fat: (current: currentFat(user: user), goal: user.fatGoal),
                protein: (current: currentProtein(user: user), goal: user.proteinGoal)
            )
            .padding()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.5))
        )
    }
    
    func currentCalories(user: User) -> Int {
        return user.meals.reduce(0) { $0 + $1.calories }
    }
    
    func currentCarbs(user: User) -> Int {
        return user.meals.reduce(0) { $0 + $1.carbs }
    }
    
    func currentFat(user: User) -> Int {
        return user.meals.reduce(0) { $0 + $1.fat }
    }
    
    func currentProtein(user: User) -> Int {
        return user.meals.reduce(0) { $0 + $1.protein }
    }
}

struct ProgressCircleView: View {
    let calories: (current: Int, goal: Int)
    let carbs: (current: Int, goal: Int)
    let fat: (current: Int, goal: Int)
    let protein: (current: Int, goal: Int)
    @State private var isAnimating = false
    
    private func progress(current: Int, goal: Int) -> CGFloat {
        CGFloat(min(current, goal)) / CGFloat(goal)
    }
    
    private func percentage(current: Int, goal: Int) -> Int {
        Int((CGFloat(current) / CGFloat(goal) * 100))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                
                ProgressRing(progress: progress(current: carbs.current, goal: carbs.goal),
                             diameter: 160,
                             color: .blue,
                             isAnimating: isAnimating)
                
                ProgressRing(progress: progress(current: fat.current, goal: fat.goal),
                             diameter: 120,
                             color: .red,
                             isAnimating: isAnimating)
                
                ProgressRing(progress: progress(current: protein.current, goal: protein.goal),
                             diameter: 80,
                             color: .green,
                             isAnimating: isAnimating)
                
                // Center Content
                VStack(spacing: 4) {
                    Text("\(percentage(current: calories.current, goal: calories.goal))%")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("of daily goals")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 280, height: 280)
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .blue, title: "Carbs", current: carbs.current, goal: carbs.goal)
                LegendItem(color: .red, title: "Fat", current: fat.current, goal: fat.goal)
                LegendItem(color: .green, title: "Protein", current: protein.current, goal: protein.goal)
            }
            .padding(.top)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
}

struct ProgressRing: View {
    let progress: CGFloat
    let diameter: CGFloat
    let color: Color
    let isAnimating: Bool
    
    var body: some View {
        Circle()
            .trim(from: 0, to: isAnimating ? progress : 0)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: 20,
                    lineCap: .round
                )
            )
            .frame(width: diameter+60, height: diameter+60)
            .rotationEffect(.degrees(-90))
    }
}

struct LegendItem: View {
    let color: Color
    let title: String
    let current: Int
    let goal: Int
    
    var body: some View {
        VStack(alignment: .center) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(current)/\(goal)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct MealListView: View {
    var meals: [User.Meal]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if meals.isEmpty {
                    Text("No meals logged yet.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(meals, id: \.id) { meal in
                        VStack(alignment: .leading) {
                            Text(meal.name)
                                .font(.headline)

                            HStack {
                                Text("Calories: \(meal.calories)")
                                Spacer()
                                Text("Carbs: \(meal.carbs)g")
                                Spacer()
                                Text("Fat: \(meal.fat)g")
                                Spacer()
                                Text("Protein: \(meal.protein)g")
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
