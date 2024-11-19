import SwiftUI
import AVFoundation

// New class to manage the capture session
class CaptureSessionManager {
    var captureSession: AVCaptureSession?
    
    func stopSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.stopRunning()
        }
    }
}

class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var parent: BarcodeScannerView
    var didFindCode: (String) -> Void
    
    init(parent: BarcodeScannerView, didFindCode: @escaping (String) -> Void) {
        self.parent = parent
        self.didFindCode = didFindCode
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            didFindCode(stringValue)
        }
    }
}

struct BarcodeScannerView: UIViewRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool
    @Binding var showingScanner: Bool
    let sessionManager: CaptureSessionManager
    
    init(scannedCode: Binding<String>, isScanning: Binding<Bool>, showingScanner: Binding<Bool>) {
        self._scannedCode = scannedCode
        self._isScanning = isScanning
        self._showingScanner = showingScanner
        self.sessionManager = CaptureSessionManager()
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return view
        }
        
        let captureSession = AVCaptureSession()
        sessionManager.captureSession = captureSession
        captureSession.addInput(input)
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce]
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> ScannerCoordinator {
        return ScannerCoordinator(parent: self) { code in
            self.scannedCode = code
            self.isScanning = false
            self.showingScanner = false  // This will dismiss the sheet
            
            // Stop the capture session
            self.sessionManager.stopSession()
        }
    }
}
struct NutritionResponse: Codable {
    let status: Int
    let product: Product?
    
    struct Product: Codable {
        let nutriments: Nutriments
        let productName: String?
        
        enum CodingKeys: String, CodingKey {
            case nutriments
            case productName = "product_name"
        }
    }
    
    struct Nutriments: Codable {
        let calories: Double
        let carbs: Double
        let proteins: Double
        let fat: Double
        
        enum CodingKeys: String, CodingKey {
            case calories = "energy-kcal_100g"
            case carbs = "carbohydrates_100g"
            case proteins = "proteins_100g"
            case fat = "fat_100g"
        }
    }
}

class NutritionFetcher: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var scannedMeal: User.Meal?
    
    func fetchNutrition(for barcode: String) {
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let nutritionInfo = try JSONDecoder().decode(NutritionResponse.self, from: data)
                    if nutritionInfo.status == 1, let product = nutritionInfo.product {
                        // Convert to User.Meal
                        let meal = User.Meal(
                            name: product.productName ?? "Scanned Item",
                            calories: Int(round(product.nutriments.calories)),
                            carbs: Int(round(product.nutriments.carbs)),
                            fat: Int(round(product.nutriments.fat)),
                            protein: Int(round(product.nutriments.proteins))
                        )
                        self?.scannedMeal = meal
                    } else {
                        self?.errorMessage = "Product not found"
                    }
                } catch {
                    self?.errorMessage = "Could not read product data"
                }
            }
        }.resume()
    }
}
struct BarcodeScanner: View {
    @State private var scannedCode: String = ""
    @State private var isScanning: Bool = false
    @State private var showingScanner: Bool = false
    @State private var showingAddMeal: Bool = false // New state for AddMealView
    @StateObject private var nutritionFetcher = NutritionFetcher()
    @ObservedObject var userViewModel: UserViewModel
    let userID: String
    
    init(userViewModel: UserViewModel, userID: String) {
        self.userViewModel = userViewModel
        self.userID = userID
    }

    var body: some View {
        VStack {
            Button(action: {
                showingScanner = true
            }) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 20))
                    Text("Scan Barcode")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showingScanner) {
            ZStack {
                BarcodeScannerView(scannedCode: $scannedCode,
                                    isScanning: $isScanning,
                                    showingScanner: $showingScanner)
                
                VStack {
                    Spacer()
                    Button("Cancel") {
                        showingScanner = false
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                    .padding(.bottom, 40)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: scannedCode) { newCode in
            if !newCode.isEmpty {
                nutritionFetcher.fetchNutrition(for: newCode)
            }
        }
        .onChange(of: nutritionFetcher.scannedMeal) { meal in
            if let meal = meal {
                showingAddMeal = true
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            if let meal = nutritionFetcher.scannedMeal {
                AddMealView(
                    userViewModel: userViewModel,
                    userID: userID,
                    name: meal.name,
                    calories: String(meal.calories),
                    protein: String(meal.protein),
                    fat: String(meal.fat),
                    carbs: String(meal.carbs)
                )
            }
        }
    }
}
