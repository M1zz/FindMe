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
                    handleUserActivity(userActivity)
                }
                .onOpenURL { url in
                    locationData = LocationData.fromURL(url)
                }
                .onAppear {
                    // Xcode 테스트: _XCAppClipURL 환경변수에서 URL 읽기
                    if locationData == nil,
                       let urlString = ProcessInfo.processInfo.environment["_XCAppClipURL"],
                       let url = URL(string: urlString) {
                        locationData = LocationData.fromURL(url)
                    }
                }
        }
    }

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        locationData = LocationData.fromURL(url)
    }
}
