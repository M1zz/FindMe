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
    
    // MARK: - App Clip Style QR
    func generateAppClipStyleQR(from string: String, size: CGFloat = 200) -> UIImage? {
        // 1. Generate base QR with high error correction
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"

        guard let ciImage = filter.outputImage else { return nil }

        // White QR on transparent
        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = ciImage
        colorFilter.color0 = CIColor.white
        colorFilter.color1 = CIColor.clear

        guard let coloredImage = colorFilter.outputImage else { return nil }

        let qrSize = size * 0.65
        let qrScale = qrSize / coloredImage.extent.width
        let scaledQR = coloredImage.transformed(by: CGAffineTransform(scaleX: qrScale, y: qrScale))

        guard let qrCGImage = context.createCGImage(scaledQR, from: scaledQR.extent) else {
            return nil
        }
        let qrUIImage = UIImage(cgImage: qrCGImage)

        // 2. Compose circular background + QR + logo
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            let gc = ctx.cgContext

            // Circular clip
            let circlePath = UIBezierPath(ovalIn: rect)
            circlePath.addClip()

            // Blue gradient background
            let colors = [
                UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 0.0, green: 0.35, blue: 0.85, alpha: 1.0).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1]) {
                gc.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size, y: size), options: [])
            }

            // Draw QR centered
            let qrOrigin = CGPoint(x: (size - qrSize) / 2, y: (size - qrSize) / 2)
            qrUIImage.draw(in: CGRect(origin: qrOrigin, size: CGSize(width: qrSize, height: qrSize)))

            // Central logo circle
            let logoSize = size * 0.22
            let logoRect = CGRect(
                x: (size - logoSize) / 2,
                y: (size - logoSize) / 2,
                width: logoSize,
                height: logoSize
            )

            // White circle behind logo
            gc.setFillColor(UIColor.white.cgColor)
            gc.fillEllipse(in: logoRect.insetBy(dx: -2, dy: -2))

            // Draw App Clip SF Symbol
            let config = UIImage.SymbolConfiguration(pointSize: logoSize * 0.5, weight: .medium)
            if let symbol = UIImage(systemName: "appclip", withConfiguration: config) {
                let tinted = symbol.withTintColor(
                    UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
                    renderingMode: .alwaysOriginal
                )
                let symbolSize = tinted.size
                let symbolRect = CGRect(
                    x: logoRect.midX - symbolSize.width / 2,
                    y: logoRect.midY - symbolSize.height / 2,
                    width: symbolSize.width,
                    height: symbolSize.height
                )
                tinted.draw(in: symbolRect)
            }

            // Circular border
            gc.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
            gc.setLineWidth(size * 0.02)
            gc.strokeEllipse(in: rect.insetBy(dx: size * 0.01, dy: size * 0.01))
        }
    }

    // MARK: - Generate Location QR
    func generateLocationQR(location: LocationData, size: CGFloat = 200) -> UIImage? {
        guard let url = location.toAppClipURL() else { return nil }
        return generateAppClipStyleQR(from: url.absoluteString, size: size)
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
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "appclip")
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
