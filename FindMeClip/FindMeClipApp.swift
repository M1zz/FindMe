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
                    print("[CLIP-APP] onContinueUserActivity 호출됨")
                    handleUserActivity(userActivity)
                }
                .onOpenURL { url in
                    print("[CLIP-APP] onOpenURL 호출됨 - URL: \(url)")
                    locationData = LocationData.fromURL(url)
                    print("[CLIP-APP] 파싱 결과 - name: \(locationData?.name ?? "nil"), ownerID: \(locationData?.ownerID ?? "nil")")
                }
                .onAppear {
                    print("[CLIP-APP] onAppear - App Clip 시작됨")
                    // Xcode 테스트: _XCAppClipURL 환경변수에서 URL 읽기
                    if locationData == nil,
                       let urlString = ProcessInfo.processInfo.environment["_XCAppClipURL"],
                       let url = URL(string: urlString) {
                        print("[CLIP-APP] _XCAppClipURL 감지: \(urlString)")
                        locationData = LocationData.fromURL(url)
                    }

                    if locationData == nil {
                        print("[CLIP-APP] locationData가 nil - URL이 전달되지 않았음")
                    }
                }
        }
    }

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else {
            print("[CLIP-APP] userActivity에 webpageURL 없음")
            return
        }
        print("[CLIP-APP] Universal Link URL: \(url)")
        locationData = LocationData.fromURL(url)
        print("[CLIP-APP] 파싱 결과 - name: \(locationData?.name ?? "nil"), ownerID: \(locationData?.ownerID ?? "nil")")
    }
}
