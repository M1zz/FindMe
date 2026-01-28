//
//  ClipContentView.swift
//  FindMeClip
//
//  App Clip 메인 화면 - 위치 표시 + 알림 전송
//

import SwiftUI
import MapKit

struct ClipContentView: View {
    @Binding var locationData: LocationData?
    
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var showingActions = false
    @State private var viewerName = ""
    @State private var showingNameInput = false
    @State private var notificationSent = false
    @State private var showingNotificationBanner = false
    
    var body: some View {
        if let data = locationData {
            locationView(data)
                .onAppear {
                    // 위치 확인 시 알림 전송
                    sendViewNotification(data)
                }
        } else {
            loadingView
        }
    }
    
    // MARK: - Location View
    private func locationView(_ data: LocationData) -> some View {
        ZStack(alignment: .bottom) {
            // 지도
            Map(position: $mapPosition) {
                Marker(data.name.isEmpty ? "위치" : data.name, coordinate: data.coordinate)
                    .tint(.blue)
            }
            .ignoresSafeArea()
            .onAppear {
                mapPosition = .region(MKCoordinateRegion(
                    center: data.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
            
            // 알림 전송 배너
            if showingNotificationBanner {
                VStack {
                    notificationBanner(data)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 하단 카드
            VStack(spacing: 0) {
                // 드래그 핸들
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                
                // 위치 정보
                VStack(alignment: .leading, spacing: 12) {
                    // 소유자 정보
                    if !data.ownerName.isEmpty {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(data.ownerName)님의 위치")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // 장소 이름
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(data.name.isEmpty ? "공유된 위치" : data.name)
                                .font(.headline)
                            
                            if !data.address.isEmpty {
                                Text(data.address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // 메모
                    if !data.memo.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "text.bubble.fill")
                                .foregroundStyle(.blue)
                            
                            Text(data.memo)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 좌표
                    Text(String(format: "%.5f, %.5f", data.latitude, data.longitude))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    // 버튼들
                    HStack(spacing: 12) {
                        // 길찾기
                        Button {
                            openDirections(data)
                        } label: {
                            Label("길찾기", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // 내 이름 알리기
                        Button {
                            showingNameInput = true
                        } label: {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.headline)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // 더보기
                        Button {
                            showingActions = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.headline)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            )
        }
        .confirmationDialog("더보기", isPresented: $showingActions) {
            Button("Apple Maps에서 열기") {
                openInAppleMaps(data)
            }
            
            Button("Google Maps에서 열기") {
                openInGoogleMaps(data)
            }
            
            Button("주소 복사") {
                copyAddress(data)
            }
            
            Button("전체 앱 다운로드") {
                downloadFullApp()
            }
            
            Button("취소", role: .cancel) {}
        }
        .alert("내 이름 알리기", isPresented: $showingNameInput) {
            TextField("이름", text: $viewerName)
            Button("취소", role: .cancel) {}
            Button("알리기") {
                sendNameNotification(data)
            }
        } message: {
            Text("\(data.ownerName.isEmpty ? "상대방" : data.ownerName)님에게 내 이름을 알립니다")
        }
    }
    
    // MARK: - Notification Banner
    private func notificationBanner(_ data: LocationData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .foregroundStyle(.white)
            
            Text("\(data.ownerName.isEmpty ? "상대방" : data.ownerName)님에게 알림을 보냈습니다")
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.green)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .shadow(radius: 5)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("위치 정보를 불러오는 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Send Notification
    private func sendViewNotification(_ data: LocationData) {
        guard !notificationSent else { return }
        notificationSent = true
        
        Task {
            // Firebase Function 호출 (실제 배포 시)
            await NotificationService.notifyOwner(
                token: data.pushToken,
                locationName: data.name.isEmpty ? "공유된 위치" : data.name,
                viewerName: ""
            )
            
            // 배너 표시
            withAnimation {
                showingNotificationBanner = true
            }
            
            // 3초 후 배너 숨김
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showingNotificationBanner = false
            }
        }
    }
    
    private func sendNameNotification(_ data: LocationData) {
        guard !viewerName.isEmpty else { return }
        
        Task {
            await NotificationService.notifyOwner(
                token: data.pushToken,
                locationName: data.name.isEmpty ? "공유된 위치" : data.name,
                viewerName: viewerName
            )
            
            // 배너 표시
            withAnimation {
                showingNotificationBanner = true
            }
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showingNotificationBanner = false
            }
        }
    }
    
    // MARK: - Actions
    private func openDirections(_ data: LocationData) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: data.coordinate))
        destination.name = data.name
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func openInAppleMaps(_ data: LocationData) {
        if let url = data.toAppleMapsURL() {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInGoogleMaps(_ data: LocationData) {
        if let url = data.toGoogleMapsURL() {
            UIApplication.shared.open(url)
        }
    }
    
    private func copyAddress(_ data: LocationData) {
        let text = """
        \(data.name)
        \(data.address)
        \(String(format: "%.5f, %.5f", data.latitude, data.longitude))
        """
        UIPasteboard.general.string = text
    }
    
    private func downloadFullApp() {
        // App Store 링크
        if let url = URL(string: "https://apps.apple.com/app/findme/id0000000000") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ClipContentView(locationData: .constant(LocationData(
        latitude: 37.5665,
        longitude: 126.9780,
        name: "스타벅스 강남역점",
        memo: "2층 창가 자리에서 기다리고 있어요",
        address: "서울 강남구 강남대로 396",
        ownerName: "김멘토",
        pushToken: "test-token-123"
    )))
}
