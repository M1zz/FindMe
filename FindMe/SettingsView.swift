//
//  SettingsView.swift
//  FindMe
//
//  설정 화면
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.requestReview) var requestReview

    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // App Clip 안내
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "appclip")
                                .font(.title)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Clip 지원")
                                    .font(.headline)
                                Text("QR 스캔 시 앱 설치 없이 바로 메모 확인!")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("기능")
                }

                // QR 설정
                Section {
                    Picker("QR 크기", selection: $dataManager.settings.qrSize) {
                        ForEach(QRSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .onChange(of: dataManager.settings.qrSize) { _, _ in
                        dataManager.saveData()
                    }
                } header: {
                    Text("QR 설정")
                }

                // 사용 방법
                Section {
                    NavigationLink {
                        HowToUseView()
                    } label: {
                        Label("사용 방법", systemImage: "questionmark.circle")
                    }

                    NavigationLink {
                        AppClipSetupGuideView()
                    } label: {
                        Label("App Clip 설정 가이드", systemImage: "appclip")
                    }
                } header: {
                    Text("도움말")
                }

                // 앱 정보
                Section {
                    HStack {
                        Label("버전", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.1")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        requestReview()
                    } label: {
                        Label("앱 평가하기", systemImage: "star")
                    }

                    Link(destination: URL(string: "https://m1zz.github.io/FindMe/support")!) {
                        Label("지원 및 문의", systemImage: "questionmark.bubble")
                    }
                } header: {
                    Text("정보")
                }

                // 데이터
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("모든 데이터 삭제", systemImage: "trash")
                    }
                } header: {
                    Text("데이터")
                }
            }
            .navigationTitle("설정")
            .alert("데이터 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    dataManager.savedLocations.removeAll()
                    dataManager.saveData()
                }
            } message: {
                Text("모든 저장된 메모가 삭제됩니다.")
            }
        }
    }
}

// MARK: - How To Use View
struct HowToUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 기본 사용법
                VStack(alignment: .leading, spacing: 16) {
                    Text("기본 사용법")
                        .font(.headline)

                    StepView(number: 1, title: "제목 입력", description: "메모의 제목을 입력하세요")
                    StepView(number: 2, title: "메모 추가", description: "전달할 메모를 작성하세요\n예: '2층 창가 자리'")
                    StepView(number: 3, title: "QR 생성", description: "자동으로 QR 코드가 생성됩니다")
                    StepView(number: 4, title: "공유", description: "QR 이미지를 저장하거나 카톡/메시지로 공유하세요")
                }

                Divider()

                // 활용 팁
                VStack(alignment: .leading, spacing: 16) {
                    Text("활용 팁")
                        .font(.headline)

                    TipView(icon: "creditcard", title: "명함에 인쇄", description: "자주 사용하는 메모가 있다면 명함에 QR을 인쇄하세요")
                    TipView(icon: "star", title: "즐겨찾기", description: "자주 사용하는 메모는 즐겨찾기에 추가하세요")
                    TipView(icon: "arrow.clockwise", title: "메모 업데이트", description: "매번 다른 메모를 QR로 공유할 수 있어요")
                }

                Divider()

                // 상대방 경험
                VStack(alignment: .leading, spacing: 16) {
                    Text("상대방이 QR을 스캔하면?")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "1.circle.fill")
                                .foregroundStyle(.blue)
                            Text("카메라로 QR 스캔")
                        }

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "2.circle.fill")
                                .foregroundStyle(.blue)
                            Text("App Clip 카드가 나타남")
                        }

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "3.circle.fill")
                                .foregroundStyle(.blue)
                            Text("탭하면 바로 메모를 확인!")
                        }
                    }
                    .font(.subheadline)

                    Text("앱 설치 없이 바로 사용 가능")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("사용 방법")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Step View
struct StepView: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Tip View
struct TipView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - App Clip Setup Guide
struct AppClipSetupGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 개요
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Clip이란?")
                        .font(.headline)

                    Text("App Clip은 앱의 작은 부분으로, 사용자가 앱을 설치하지 않고도 특정 기능을 바로 사용할 수 있게 해줍니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("10MB 미만의 작은 크기")
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("QR, NFC, 링크로 실행")
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("설치 없이 즉시 사용")
                    }
                }
                .font(.subheadline)

                Divider()

                // 설정 방법
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Store Connect 설정")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. App Store Connect에서 App Clip 등록")
                        Text("2. Associated Domains 설정")
                        Text("3. AASA 파일 서버에 호스팅")
                        Text("4. App Clip Experiences 구성")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Divider()

                // URL 형식
                VStack(alignment: .leading, spacing: 12) {
                    Text("QR URL 형식")
                        .font(.headline)

                    Text("https://m1zz.github.io/FindMe/l?owner=이름&memo=메모&name=제목&token=xxx")
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("이 URL이 App Clip을 실행시키고, 파라미터로 메모 정보를 전달합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("App Clip 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager())
}
