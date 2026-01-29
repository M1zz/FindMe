//
//  NotificationManager.swift
//  FindMe
//
//  푸시 알림 관리
//

import Foundation
import UserNotifications
import UIKit
import CloudKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var ownerID: String = ""
    @Published var viewNotifications: [ViewNotification] = []

    private let ownerIDKey = "ownerID"
    private let notificationsKey = "viewNotifications"
    private let container = CKContainer(identifier: "iCloud.com.leeo.FindMe")
    
    override init() {
        super.init()
        print("[STEP 1] NotificationManager init 시작")
        loadData()
        _ = generateOwnerID()
        print("[STEP 1] NotificationManager init 완료 - ownerID: \(ownerID)")
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        print("[STEP 2] 알림 권한 요청 시작")
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            print("[STEP 2] 알림 권한 결과: \(granted ? "허용" : "거부")")

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("[STEP 2] APNs 등록 요청 완료")
            }

            return granted
        } catch {
            print("[STEP 2] 알림 권한 에러: \(error)")
            return false
        }
    }
    
    // MARK: - Generate Owner ID
    func generateOwnerID() -> String {
        if let saved = UserDefaults.standard.string(forKey: ownerIDKey), !saved.isEmpty {
            ownerID = saved
            return saved
        }

        let id = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        ownerID = id
        UserDefaults.standard.set(id, forKey: ownerIDKey)
        return id
    }

    // MARK: - CloudKit Subscription
    func setupCloudKitSubscription() {
        print("[STEP 4] CloudKit 구독 설정 시작 - ownerID: \(ownerID)")
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let subscription = CKQuerySubscription(
            recordType: "ViewNotification",
            predicate: predicate,
            options: .firesOnRecordCreation
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = ["locationName", "viewerName", "timestamp"]
        notificationInfo.alertBody = "메모가 확인되었습니다"
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo

        let database = container.publicCloudDatabase
        database.save(subscription) { _, error in
            if let error = error {
                print("[STEP 4] CloudKit 구독 에러: \(error.localizedDescription)")
            } else {
                print("[STEP 4] CloudKit 구독 생성 성공")
            }
        }
    }

    // MARK: - Handle CloudKit Notification
    func handleCloudKitNotification(userInfo: [AnyHashable: Any]) {
        print("[PUSH] 리모트 알림 수신 - userInfo: \(userInfo)")

        guard let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo) else {
            print("[PUSH] CKQueryNotification 파싱 실패")
            return
        }

        print("[PUSH] reason: \(notification.queryNotificationReason.rawValue) (1=recordCreated)")

        guard notification.queryNotificationReason == .recordCreated else {
            print("[PUSH] recordCreated가 아니므로 무시")
            return
        }

        let locationName = notification.recordFields?["locationName"] as? String ?? "공유된 메모"
        let viewerName = notification.recordFields?["viewerName"] as? String ?? ""

        print("[PUSH] 알림 데이터 - locationName: \(locationName), viewerName: \(viewerName)")

        let viewNotification = ViewNotification(
            locationName: locationName,
            viewerName: viewerName
        )
        addNotification(viewNotification)
        print("[PUSH] 알림 저장 + 로컬 알림 표시 완료")
    }
    
    // MARK: - Load/Save Notifications
    func loadData() {
        if let saved = UserDefaults.standard.string(forKey: ownerIDKey) {
            ownerID = saved
        }
        
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let notifications = try? JSONDecoder().decode([ViewNotification].self, from: data) {
            viewNotifications = notifications
        }
    }
    
    func saveData() {
        if let data = try? JSONEncoder().encode(viewNotifications) {
            UserDefaults.standard.set(data, forKey: notificationsKey)
        }
    }
    
    // MARK: - Add Notification
    func addNotification(_ notification: ViewNotification) {
        viewNotifications.insert(notification, at: 0)
        
        // 최대 100개만 유지
        if viewNotifications.count > 100 {
            viewNotifications = Array(viewNotifications.prefix(100))
        }
        
        saveData()
        
        // 로컬 알림 표시
        showLocalNotification(notification)
    }
    
    // MARK: - Show Local Notification
    private func showLocalNotification(_ notification: ViewNotification) {
        let content = UNMutableNotificationContent()
        content.title = "📍 메모 확인됨"
        content.body = notification.viewerName.isEmpty
            ? "누군가 '\(notification.locationName)' 메모를 확인했습니다"
            : "\(notification.viewerName)님이 '\(notification.locationName)' 메모를 확인했습니다"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil // 즉시 표시
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Clear Notifications
    func clearNotifications() {
        viewNotifications.removeAll()
        saveData()
    }
    
    // MARK: - Simulate View (테스트용)
    func simulateView(locationName: String) {
        let names = ["김철수", "이영희", "박민수", "최지은", ""]
        let notification = ViewNotification(
            locationName: locationName,
            viewerName: names.randomElement() ?? ""
        )
        addNotification(notification)
    }
}

// MARK: - View Notification Model
struct ViewNotification: Codable, Identifiable {
    let id: UUID
    let locationName: String
    let viewerName: String
    let viewedAt: Date
    
    init(
        id: UUID = UUID(),
        locationName: String,
        viewerName: String = "",
        viewedAt: Date = Date()
    ) {
        self.id = id
        self.locationName = locationName
        self.viewerName = viewerName
        self.viewedAt = viewedAt
    }
}

