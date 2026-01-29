//
//  FindMeApp.swift
//  FindMe
//
//  내 위치를 QR로 공유하는 앱
//  상대방은 App Clip으로 위치 확인
//

import SwiftUI
import UserNotifications
import CloudKit

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
                    // ownerID 생성
                    _ = notificationManager.generateOwnerID()
                    // CloudKit 구독 설정
                    notificationManager.setupCloudKitSubscription()
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
        print("[APP] didFinishLaunchingWithOptions")
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // MARK: - Push Token (APNs 등록은 유지, 토큰 저장은 불필요)
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("[STEP 3] APNs 등록 성공 (CloudKit 구독용, 토큰 저장 불필요)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[STEP 3] APNs 등록 실패: \(error)")
    }

    // MARK: - Remote Notification (CloudKit)
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("[PUSH] didReceiveRemoteNotification 호출됨")
        Task { @MainActor in
            NotificationManager.shared.handleCloudKitNotification(userInfo: userInfo)
        }
        completionHandler(.newData)
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
