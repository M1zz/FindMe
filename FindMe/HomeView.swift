//
//  HomeView.swift
//  FindMe
//
//  QR 생성 메인 화면
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var locationData = LocationData()
    @State private var ownerName = ""
    @State private var showingQRSheet = false
    @State private var isSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 제목 입력
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
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("메모 QR")
            .sheet(isPresented: $showingQRSheet) {
                QRDetailView(locationData: locationDataWithOwnerID)
            }
            .onAppear {
                // 저장된 이름 불러오기
                ownerName = UserDefaults.standard.string(forKey: "ownerName") ?? ""
            }
            .onChange(of: locationData.name) { _, _ in
                isSaved = false
            }
            .onChange(of: locationData.memo) { _, _ in
                isSaved = false
            }
        }
    }

    // ownerID가 포함된 LocationData
    private var locationDataWithOwnerID: LocationData {
        var data = locationData
        data.ownerName = ownerName
        data.ownerID = notificationManager.ownerID
        return data
    }

    // MARK: - Location Info Section
    private var locationInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("제목", systemImage: "text.bubble")
                .font(.headline)

            TextField("제목", text: $locationData.name)
                .textFieldStyle(.roundedBorder)
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

            Text("메모 확인 페이지에서 표시됩니다")
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
            LocationQRView(location: locationDataWithOwnerID, size: 150)
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
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.headline)
                        .padding()
                        .background(isSaved ? Color.orange.opacity(0.2) : Color(.systemGray5))
                        .foregroundStyle(isSaved ? .orange : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if isSaved {
                Text("저장됨")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Actions
    private func saveLocation() {
        dataManager.saveLocation(locationDataWithOwnerID)

        withAnimation {
            isSaved = true
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager())
        .environmentObject(NotificationManager.shared)
}
