//
//  HomeView.swift
//  FindMe
//
//  QR 생성 메인 화면
//

import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var locationData = LocationData()
    @State private var ownerName = ""
    @State private var showingSearch = false
    @State private var showingQRSheet = false
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var isLoadingLocation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 지도 섹션
                    mapSection
                    
                    // 위치 정보 입력
                    locationInfoSection
                    
                    // 내 이름 (알림에 표시)
                    ownerNameSection
                    
                    // 메모 입력
                    memoSection
                    
                    // QR 미리보기 & 생성 버튼
                    if locationData.isValid {
                        qrPreviewSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("내 위치 QR")
            .sheet(isPresented: $showingSearch) {
                SearchView(locationManager: locationManager) { result in
                    locationData.latitude = result.coordinate.latitude
                    locationData.longitude = result.coordinate.longitude
                    locationData.name = result.name
                    locationData.address = result.address
                    
                    mapPosition = .region(MKCoordinateRegion(
                        center: result.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))
                }
            }
            .sheet(isPresented: $showingQRSheet) {
                QRDetailView(locationData: locationDataWithToken)
            }
            .onAppear {
                // 저장된 이름 불러오기
                ownerName = UserDefaults.standard.string(forKey: "ownerName") ?? ""
            }
        }
    }
    
    // 토큰이 포함된 LocationData
    private var locationDataWithToken: LocationData {
        var data = locationData
        data.ownerName = ownerName
        data.pushToken = notificationManager.deviceToken
        return data
    }
    
    // MARK: - Map Section
    private var mapSection: some View {
        VStack(spacing: 12) {
            // 지도
            ZStack {
                Map(position: $mapPosition) {
                    if locationData.isValid {
                        Marker(locationData.name.isEmpty ? "위치" : locationData.name, 
                               coordinate: locationData.coordinate)
                            .tint(.blue)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 중앙 십자선 (위치 미선택 시)
                if !locationData.isValid {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.blue.opacity(0.7))
                }
            }
            
            // 버튼들
            HStack(spacing: 12) {
                // 현재 위치
                Button {
                    useCurrentLocation()
                } label: {
                    Label("현재 위치", systemImage: "location.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isLoadingLocation)
                
                // 장소 검색
                Button {
                    showingSearch = true
                } label: {
                    Label("검색", systemImage: "magnifyingglass")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Location Info Section
    private var locationInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("위치 정보", systemImage: "mappin.circle")
                .font(.headline)
            
            TextField("장소 이름", text: $locationData.name)
                .textFieldStyle(.roundedBorder)
            
            TextField("주소 (선택)", text: $locationData.address)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.secondary)
            
            if locationData.isValid {
                HStack {
                    Image(systemName: "location.circle")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.4f, %.4f", locationData.latitude, locationData.longitude))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Owner Name Section
    private var ownerNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("내 이름", systemImage: "person.circle")
                .font(.headline)
            
            TextField("예: 김멘토", text: $ownerName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: ownerName) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "ownerName")
                }
            
            Text("위치 확인 페이지에서 표시됩니다")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Memo Section
    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("메모", systemImage: "text.bubble")
                .font(.headline)
            
            TextField("예: 2층 창가 자리에 있어요", text: $locationData.memo, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - QR Preview Section
    private var qrPreviewSection: some View {
        VStack(spacing: 16) {
            // QR 미리보기
            LocationQRView(location: locationDataWithToken, size: 150)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 5)
            
            // 알림 상태
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.green)
                Text("QR 스캔 시 알림을 받습니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 버튼들
            HStack(spacing: 12) {
                // QR 크게 보기
                Button {
                    showingQRSheet = true
                } label: {
                    Label("QR 보기", systemImage: "qrcode")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // 저장
                Button {
                    saveLocation()
                } label: {
                    Image(systemName: "bookmark")
                        .font(.headline)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Actions
    private func useCurrentLocation() {
        isLoadingLocation = true
        
        locationManager.requestPermission()
        locationManager.requestLocation()
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            if let location = locationManager.currentLocation {
                locationData.latitude = location.coordinate.latitude
                locationData.longitude = location.coordinate.longitude
                
                mapPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
                
                // 역지오코딩
                if let result = await locationManager.reverseGeocode(coordinate: location.coordinate) {
                    locationData.name = result.name
                    locationData.address = result.address
                }
            }
            
            isLoadingLocation = false
        }
    }
    
    private func saveLocation() {
        dataManager.saveLocation(locationDataWithToken)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager())
        .environmentObject(NotificationManager.shared)
}
