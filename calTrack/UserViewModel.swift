import SwiftUI
import Combine

class UserViewModel: ObservableObject {
    enum LoadingState {
        case loading
        case loaded
        case error(String)
    }
    
    @Published private(set) var users: [User] = []
    @Published private(set) var loadingState: LoadingState = .loading
    
    private let baseURL = "http://192.168.0.19:5001"
    
    func fetchUsers() {
        loadingState = .loading
        guard let url = URL(string: "\(baseURL)/users") else {
            loadingState = .error("Invalid URL")
            return
        }
        
        print("Starting network request to: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleFetchUsersResponse(data: data, response: response as? HTTPURLResponse, error: error)
            }
        }.resume()
    }
    
    private func handleFetchUsersResponse(data: Data?, response: HTTPURLResponse?, error: Error?) {
        if let error = error {
            print("Network error: \(error)")
            loadingState = .error("Network error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            print("No data received from server")
            loadingState = .error("No data received from server")
            return
        }
        
        print("Received \(data.count) bytes of data")
        
        if let dataString = String(data: data, encoding: .utf8) {
            print("Raw response: \(dataString)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let usersList = try decoder.decode([User].self, from: data)
            print("Successfully decoded \(usersList.count) users")
            users = usersList
            loadingState = .loaded
        } catch {
            print("Decoding error: \(error)")
            print("Detailed error: \(String(describing: error))")
            loadingState = .error("Data decoding error: \(error.localizedDescription)")
        }
    }
    
    func addMeal(name: String, calories: String, protein: String, fat: String, carbs: String, userID: String) {
        // Convert string inputs to integers
        guard let caloriesInt = Int(calories),
              let proteinInt = Int(protein),
              let fatInt = Int(fat),
              let carbsInt = Int(carbs),
              !name.isEmpty else {
            print("Invalid input: Please check all fields are filled correctly")
            return
        }

        print("Adding meal for userID: \(userID)") // Debug print

        let newMeal: [String: Any] = [
            "name": name,
            "calories": caloriesInt,
            "protein": proteinInt,
            "fat": fatInt,
            "carbs": carbsInt
        ]

        let requestBody: [String: Any] = [
            "userID": userID,
            "meal": newMeal
        ]

        guard let url = URL(string: "\(baseURL)/addMeal") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            // Debug print the JSON being sent
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Sending JSON: \(jsonString)")
            }
        } catch {
            print("Failed to encode JSON: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let responseString = String(data: data, encoding: .utf8) {
                    print("Server response: \(responseString)")
                }
                self?.handleAddMealResponse(response: response as? HTTPURLResponse, error: error)
            }
        }.resume()
    }
    
    private func handleAddMealResponse(response: HTTPURLResponse?, error: Error?) {
        if let error = error {
            print("Error during network request: \(error)")
            return
        }

        if let response = response {
            print("Response status code: \(response.statusCode)")
            if response.statusCode == 200 {
                print("Meal added successfully!")
                fetchUsers() // Refresh the users list after adding a meal
            } else {
                print("Failed to add meal. Status code: \(response.statusCode)")
            }
        } else {
            print("No response received")
        }
    }
}
