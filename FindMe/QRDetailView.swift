//
//  QRDetailView.swift
//  FindMe
//
//  QR 코드 상세 보기 + 공유
//

import SwiftUI

struct QRDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let locationData: LocationData
    
    @State private var copiedURL = false
    @State private var savedToPhotos = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // QR 코드
                    qrCodeSection
                    
                    // 위치 정보
                    locationInfoSection
                    
                    // 공유 옵션
                    shareOptionsSection
                    
                    // 사용 안내
                    usageGuideSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("QR 코드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - QR Code Section
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            // QR 코드
            LocationQRView(location: locationData, size: 250)
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10)
            
            // URL
            if let url = locationData.toAppClipURL() {
                HStack {
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button {
                        copyURL()
                    } label: {
                        Image(systemName: copiedURL ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(copiedURL ? .green : .blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Location Info Section
    private var locationInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !locationData.name.isEmpty {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.red)
                    Text(locationData.name)
                        .font(.headline)
                }
            }
            
            if !locationData.address.isEmpty {
                Text(locationData.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if !locationData.memo.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "text.bubble.fill")
                        .foregroundStyle(.blue)
                    Text(locationData.memo)
                        .font(.subheadline)
                }
            }
            
            // 좌표
            Text(String(format: "위도 %.4f, 경도 %.4f", locationData.latitude, locationData.longitude))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Share Options Section
    private var shareOptionsSection: some View {
        VStack(spacing: 12) {
            Text("공유하기")
                .font(.headline)
            
            // 버튼 그리드
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // QR 이미지 저장
                ShareOptionButton(
                    icon: "square.and.arrow.down",
                    title: "이미지 저장",
                    color: .blue
                ) {
                    saveQRImage()
                }
                
                // 공유
                ShareOptionButton(
                    icon: "square.and.arrow.up",
                    title: "공유",
                    color: .green
                ) {
                    shareQR()
                }
                
                // Apple Maps로 열기
                ShareOptionButton(
                    icon: "map",
                    title: "Apple Maps",
                    color: .orange
                ) {
                    openInAppleMaps()
                }
                
                // Google Maps로 열기
                ShareOptionButton(
                    icon: "globe",
                    title: "Google Maps",
                    color: .red
                ) {
                    openInGoogleMaps()
                }
            }
            
            if savedToPhotos {
                Text("✓ 사진에 저장되었습니다")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Usage Guide Section
    private var usageGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("사용 방법", systemImage: "info.circle")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                GuideRow(number: 1, text: "QR 이미지를 저장하거나 공유하세요")
                GuideRow(number: 2, text: "상대방이 QR을 스캔하면")
                GuideRow(number: 3, text: "App Clip이 열리며 위치가 표시됩니다")
                GuideRow(number: 4, text: "앱 설치 없이 바로 확인 가능!")
            }
            
            Divider()
            
            Text("💡 명함에 인쇄하면 영구적으로 사용할 수 있어요")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Actions
    private func copyURL() {
        guard let url = locationData.toAppClipURL() else { return }
        UIPasteboard.general.string = url.absoluteString
        
        withAnimation { copiedURL = true }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copiedURL = false }
        }
    }
    
    private func saveQRImage() {
        if let image = QRGenerator.shared.generateLocationQR(location: locationData, size: 600) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            withAnimation { savedToPhotos = true }
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { savedToPhotos = false }
            }
        }
    }
    
    private func shareQR() {
        guard let image = QRGenerator.shared.generateLocationQR(location: locationData, size: 600),
              let url = locationData.toAppClipURL() else { return }
        
        let text = """
        📍 내 위치를 확인하세요!
        
        \(locationData.name.isEmpty ? "위치" : locationData.name)
        \(locationData.memo.isEmpty ? "" : "메모: \(locationData.memo)")
        
        \(url.absoluteString)
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [text, image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func openInAppleMaps() {
        if let url = locationData.toAppleMapsURL() {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInGoogleMaps() {
        if let url = locationData.toGoogleMapsURL() {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Share Option Button
struct ShareOptionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Guide Row
struct GuideRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    QRDetailView(locationData: LocationData(
        latitude: 37.5665,
        longitude: 126.9780,
        name: "스타벅스 강남역점",
        memo: "2층 창가 자리",
        address: "서울 강남구 강남대로 396"
    ))
}
