//
//  FindMeApp.swift
//  FindMe
//
//  내 위치를 QR로 공유하는 앱
//  상대방은 App Clip으로 위치 확인
//

import SwiftUI
import UserNotifications

@main
struct FindMeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataManager = DataManager()
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(notificationManager)
                .task {
                    // 알림 권한 요청
                    await notificationManager.requestPermission()
                    // 로컬 토큰 생성 (실제 배포 시에는 APNs 토큰 사용)
                    _ = notificationManager.generateLocalToken()
                }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // MARK: - Push Token
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationManager.shared.handleDeviceToken(deviceToken)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Foreground Notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 앱이 포그라운드일 때도 알림 표시
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Notification Tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 알림 탭 시 처리
        completionHandler()
    }
}
