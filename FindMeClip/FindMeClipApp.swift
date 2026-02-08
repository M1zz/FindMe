//
//  FindMeClipApp.swift
//  FindMeClip
//
//  App Clip - QR 스캔 시 위치 표시
//

import SwiftUI

@main
struct FindMeClipApp: App {
    @State private var locationData: LocationData?

    var body: some Scene {
        WindowGroup {
            ClipContentView(locationData: $locationData)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    print("[CLIP-APP] ===== onContinueUserActivity 호출됨 =====")
                    print("[CLIP-APP] activityType: \(userActivity.activityType)")
                    print("[CLIP-APP] webpageURL: \(userActivity.webpageURL?.absoluteString ?? "nil")")
                    handleUserActivity(userActivity)
                }
                .onOpenURL { url in
                    print("[CLIP-APP] ===== onOpenURL 호출됨 =====")
                    print("[CLIP-APP] URL: \(url.absoluteString)")
                    print("[CLIP-APP] scheme: \(url.scheme ?? "nil")")
                    print("[CLIP-APP] host: \(url.host ?? "nil")")
                    print("[CLIP-APP] path: \(url.path)")
                    print("[CLIP-APP] query: \(url.query ?? "nil")")
                    locationData = LocationData.fromURL(url)
                    if let data = locationData {
                        print("[CLIP-APP] ✅ 파싱 성공:")
                        print("[CLIP-APP]   name: \(data.name)")
                        print("[CLIP-APP]   memo: \(data.memo)")
                        print("[CLIP-APP]   ownerName: \(data.ownerName)")
                        print("[CLIP-APP]   ownerID: \(data.ownerID) (길이: \(data.ownerID.count))")
                    } else {
                        print("[CLIP-APP] ❌ 파싱 실패 - LocationData.fromURL 반환값 nil")
                    }
                }
                .onAppear {
                    print("[CLIP-APP] ===== App Clip 시작됨 =====")
                    print("[CLIP-APP] 시간: \(Date())")
                    // Xcode 테스트: _XCAppClipURL 환경변수에서 URL 읽기
                    if locationData == nil,
                       let urlString = ProcessInfo.processInfo.environment["_XCAppClipURL"],
                       let url = URL(string: urlString) {
                        print("[CLIP-APP] _XCAppClipURL 감지: \(urlString)")
                        locationData = LocationData.fromURL(url)
                        if let data = locationData {
                            print("[CLIP-APP] ✅ 환경변수 URL 파싱 성공 - ownerID: \(data.ownerID)")
                        } else {
                            print("[CLIP-APP] ❌ 환경변수 URL 파싱 실패")
                        }
                    }

                    if locationData == nil {
                        print("[CLIP-APP] ⚠️ locationData가 nil - URL이 전달되지 않았음")
                        print("[CLIP-APP] onContinueUserActivity 또는 onOpenURL을 기다리는 중...")
                    }
                }
        }
    }

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else {
            print("[CLIP-APP] ❌ userActivity에 webpageURL 없음")
            return
        }
        print("[CLIP-APP] Universal Link URL: \(url.absoluteString)")
        print("[CLIP-APP] query params: \(url.query ?? "nil")")
        locationData = LocationData.fromURL(url)
        if let data = locationData {
            print("[CLIP-APP] ✅ 파싱 성공 - ownerID: \(data.ownerID) (길이: \(data.ownerID.count))")
        } else {
            print("[CLIP-APP] ❌ 파싱 실패")
        }
    }
}
