
import SwiftUI
import AVFoundation

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
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return view
        }
        
        let captureSession = AVCaptureSession()
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
        }
    }
}

struct BarcodeScanner: View {
    @State private var scannedCode: String = ""
    @State private var isScanning: Bool = false
    @State private var showingScanner: Bool = false
    
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
            
            if !scannedCode.isEmpty {
                Text("Scanned Code: \(scannedCode)")
                    .padding()
            }
        }
        .sheet(isPresented: $showingScanner) {
            ZStack {
                BarcodeScannerView(scannedCode: $scannedCode, isScanning: $isScanning)
                
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
    }
}
