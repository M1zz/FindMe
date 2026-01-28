//
//  QRGenerator.swift
//  FindMe
//
//  QR 코드 생성 (메인 앱 + App Clip 공유)
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

class QRGenerator {
    static let shared = QRGenerator()
    
    private let context = CIContext()
    
    // MARK: - Generate QR Code
    func generateQRCode(from string: String, size: CGFloat = 200) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"  // 높은 오류 복구율
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let scale = size / ciImage.extent.width
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Generate Styled QR
    func generateStyledQRCode(
        from string: String,
        size: CGFloat = 200,
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"
        
        guard let ciImage = filter.outputImage else { return nil }
        
        // 색상 필터
        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = ciImage
        colorFilter.color0 = CIColor(color: foregroundColor)
        colorFilter.color1 = CIColor(color: backgroundColor)
        
        guard let coloredImage = colorFilter.outputImage else { return nil }
        
        let scale = size / coloredImage.extent.width
        let scaledImage = coloredImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Generate Location QR
    func generateLocationQR(location: LocationData, size: CGFloat = 200) -> UIImage? {
        guard let url = location.toAppClipURL() else { return nil }
        return generateQRCode(from: url.absoluteString, size: size)
    }
}

// MARK: - QR Code View
struct QRCodeView: View {
    let content: String
    let size: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color
    
    @State private var qrImage: UIImage?
    
    init(
        content: String,
        size: CGFloat = 200,
        foregroundColor: Color = .black,
        backgroundColor: Color = .white
    ) {
        self.content = content
        self.size = size
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Group {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
        .onAppear { generateQR() }
        .onChange(of: content) { _, _ in generateQR() }
    }
    
    private func generateQR() {
        qrImage = QRGenerator.shared.generateStyledQRCode(
            from: content,
            size: size * 3,
            foregroundColor: UIColor(foregroundColor),
            backgroundColor: UIColor(backgroundColor)
        )
    }
}

// MARK: - Location QR View
struct LocationQRView: View {
    let location: LocationData
    let size: CGFloat
    
    @State private var qrImage: UIImage?
    
    init(location: LocationData, size: CGFloat = 200) {
        self.location = location
        self.size = size
    }
    
    var body: some View {
        Group {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .onAppear { generateQR() }
        .onChange(of: location) { _, _ in generateQR() }
    }
    
    private func generateQR() {
        qrImage = QRGenerator.shared.generateLocationQR(location: location, size: size * 3)
    }
}
