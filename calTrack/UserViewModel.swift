import SwiftUI
import Combine

class UserViewModel: ObservableObject {
    enum LoadingState {
        case loading
        case loaded
        case error(String)
    }
    
    @Published var users: [User] = []
    @Published var loadingState: LoadingState = .loading
    
    func fetchUsers() {
        loadingState = .loading
        guard let url = URL(string: "http://192.168.0.19:5001/users") else {
            loadingState = .error("Invalid URL")
            return
        }
        
        print("Starting network request to: \(url)")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error)")
                    self?.loadingState = .error("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received from server")
                    self?.loadingState = .error("No data received from server")
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
                    self?.users = usersList
                    self?.loadingState = .loaded
                } catch {
                    print("Decoding error: \(error)")
                    print("Detailed error: \(String(describing: error))")
                    self?.loadingState = .error("Data decoding error: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
    }
}
