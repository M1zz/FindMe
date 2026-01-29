//
//  ClipContentView.swift
//  FindMeClip
//
//  App Clip 메인 화면 - 메모 표시 + 알림 전송
//

import SwiftUI

struct ClipContentView: View {
    @Binding var locationData: LocationData?

    @State private var viewerName = ""
    @State private var showingNameInput = false
    @State private var notificationSent = false
    @State private var showingNotificationBanner = false

    var body: some View {
        if let data = locationData {
            memoView(data)
                .onAppear {
                    // 메모 확인 시 알림 전송
                    sendViewNotification(data)
                }
        } else {
            loadingView
        }
    }

    // MARK: - Memo View
    private func memoView(_ data: LocationData) -> some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 알림 전송 배너
                    if showingNotificationBanner {
                        notificationBanner(data)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 소유자 정보
                    if !data.ownerName.isEmpty {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(data.ownerName)님의 메모")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }

                    // 메모 카드
                    VStack(alignment: .leading, spacing: 16) {
                        // 제목
                        if !data.name.isEmpty {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)

                                Text(data.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }

                        // 메모
                        if !data.memo.isEmpty {
                            Text(data.memo)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 5)

                    // 버튼들
                    HStack(spacing: 12) {
                        // 내 이름 알리기
                        Button {
                            showingNameInput = true
                        } label: {
                            Label("내 이름 알리기", systemImage: "person.crop.circle.badge.plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    // 전체 앱 다운로드
                    Button {
                        downloadFullApp()
                    } label: {
                        Label("전체 앱 다운로드", systemImage: "arrow.down.app")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
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
        .shadow(radius: 5)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("메모를 불러오는 중...")
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
            do {
                try await NotificationService.notifyOwner(
                    ownerID: data.ownerID,
                    locationName: data.name.isEmpty ? "공유된 메모" : data.name,
                    viewerName: ""
                )
            } catch {
                print("❌ View notification failed: \(error.localizedDescription)")
            }

            withAnimation {
                showingNotificationBanner = true
            }

            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showingNotificationBanner = false
            }
        }
    }

    private func sendNameNotification(_ data: LocationData) {
        guard !viewerName.isEmpty else { return }

        Task {
            do {
                try await NotificationService.notifyOwner(
                    ownerID: data.ownerID,
                    locationName: data.name.isEmpty ? "공유된 메모" : data.name,
                    viewerName: viewerName
                )
            } catch {
                print("❌ Name notification failed: \(error.localizedDescription)")
            }

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
    private func downloadFullApp() {
        if let url = URL(string: "https://apps.apple.com/app/findme/id0000000000") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ClipContentView(locationData: .constant(LocationData(
        name: "스타벅스 강남역점",
        memo: "2층 창가 자리에서 기다리고 있어요",
        ownerName: "김멘토",
        ownerID: "test-owner-id-123"
    )))
}
