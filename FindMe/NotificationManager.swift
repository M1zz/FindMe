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
    private let subscriptionID = "findme-view-notification"
    private let container = CKContainer(identifier: "iCloud.com.leeo.FindMe")
    
    override init() {
        super.init()
        print("[STEP 1] NotificationManager init 시작")
        loadData()
        _ = generateOwnerID()
        print("[STEP 1] NotificationManager init 완료 - ownerID: \(ownerID)")
        print("[STEP 1] ownerID 길이: \(ownerID.count)자")
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        print("[STEP 2] 알림 권한 요청 시작")
        let center = UNUserNotificationCenter.current()

        // 현재 알림 설정 상태 진단
        let settings = await center.notificationSettings()
        print("[STEP 2] 현재 알림 설정 상태:")
        print("  - authorizationStatus: \(settings.authorizationStatus.rawValue) (0=notDetermined, 1=denied, 2=authorized, 3=provisional)")
        print("  - alertSetting: \(settings.alertSetting.rawValue) (0=notSupported, 1=disabled, 2=enabled)")
        print("  - soundSetting: \(settings.soundSetting.rawValue)")
        print("  - badgeSetting: \(settings.badgeSetting.rawValue)")

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            print("[STEP 2] 알림 권한 결과: \(granted ? "허용" : "거부")")

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("[STEP 2] APNs 등록 요청 완료")
            } else {
                print("[STEP 2] ⚠️ 알림 권한 거부됨 - 설정에서 알림을 허용해주세요")
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
        guard !ownerID.isEmpty else {
            print("[STEP 4] ownerID가 비어있어 구독 스킵")
            return
        }

        print("[STEP 4] CloudKit 구독 설정 시작 - ownerID: \(ownerID)")
        print("[STEP 4] Container: \(container.containerIdentifier ?? "nil")")
        print("[STEP 4] SubscriptionID: \(subscriptionID)")

        // MainActor 프로퍼티를 클로저 밖에서 미리 캡처
        let currentOwnerID = self.ownerID
        let currentSubscriptionID = self.subscriptionID

        let database = container.publicCloudDatabase
        database.fetch(withSubscriptionID: currentSubscriptionID) { existingSub, fetchError in
            if let existingSub = existingSub {
                print("[STEP 4] 기존 구독 확인됨: \(existingSub.subscriptionID)")

                if let querySub = existingSub as? CKQuerySubscription {
                    let predicateStr = querySub.predicate.predicateFormat
                    print("[STEP 4]   - predicate: \(predicateStr)")
                    print("[STEP 4]   - 현재 ownerID: \(currentOwnerID)")

                    let predicateMatchesCurrent = predicateStr.contains(currentOwnerID)

                    if predicateMatchesCurrent {
                        print("[STEP 4] ✅ 기존 구독의 ownerID가 현재와 일치 - 유지")
                        if let notifInfo = querySub.notificationInfo {
                            print("[STEP 4]   - alertBody: \(notifInfo.alertBody ?? "nil")")
                            print("[STEP 4]   - shouldSendContentAvailable: \(notifInfo.shouldSendContentAvailable)")
                            print("[STEP 4]   - desiredKeys: \(notifInfo.desiredKeys ?? [])")
                        }
                        return
                    }

                    // ownerID 불일치 → 기존 구독 삭제 후 새로 생성
                    print("[STEP 4] ⚠️ ownerID 불일치! 기존 구독 삭제 후 재생성")
                    print("[STEP 4]   - 구독 predicate: \(predicateStr)")
                    print("[STEP 4]   - 현재 ownerID: \(currentOwnerID)")
                    database.delete(withSubscriptionID: currentSubscriptionID) { _, deleteError in
                        if let deleteError = deleteError {
                            print("[STEP 4] ❌ 기존 구독 삭제 실패: \(deleteError.localizedDescription)")
                            return
                        }
                        print("[STEP 4] 기존 구독 삭제 완료 - 새로 생성 시작")
                        Self.createSubscription(database: database, ownerID: currentOwnerID, subscriptionID: currentSubscriptionID)
                    }
                    return
                }
            }

            if let fetchError = fetchError {
                print("[STEP 4] 기존 구독 조회 실패 (새로 생성 시도): \(fetchError.localizedDescription)")
            } else {
                print("[STEP 4] 기존 구독 없음 - 새로 생성")
            }

            Self.createSubscription(database: database, ownerID: currentOwnerID, subscriptionID: currentSubscriptionID)
        }
    }

    private static func createSubscription(database: CKDatabase, ownerID: String, subscriptionID: String) {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let subscription = CKQuerySubscription(
            recordType: "ViewNotification",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: .firesOnRecordCreation
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = ["locationName", "viewerName", "timestamp"]
        notificationInfo.alertBody = "메모가 확인되었습니다"
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo

        database.save(subscription) { savedSub, error in
            if let error = error as? CKError {
                print("[STEP 4] CloudKit 구독 에러 - code: \(error.code.rawValue), desc: \(error.localizedDescription)")
                if error.code == .serverRejectedRequest {
                    print("[STEP 4] → 구독이 이미 존재 (serverRejectedRequest)")
                }
            } else if let error = error {
                print("[STEP 4] CloudKit 구독 일반 에러: \(error.localizedDescription)")
            } else {
                print("[STEP 4] ✅ CloudKit 구독 생성 성공 - subscriptionID: \(savedSub?.subscriptionID ?? "nil")")
                print("[STEP 4]   - ownerID: \(ownerID)")
            }
        }
    }

    // MARK: - Diagnose (진단 메서드)
    func diagnose() {
        print("========== [진단] FindMe 알림 시스템 진단 ==========")
        print("[진단] ownerID: \(ownerID)")
        print("[진단] ownerID 길이: \(ownerID.count)")
        print("[진단] isAuthorized: \(isAuthorized)")
        print("[진단] 저장된 알림 수: \(viewNotifications.count)")

        let containerID = container.containerIdentifier ?? "nil"
        print("[진단] Container ID: \(containerID)")

        // 알림 권한 상태 확인
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            print("[진단] 알림 authorizationStatus: \(settings.authorizationStatus.rawValue)")
            print("[진단] 알림 alertSetting: \(settings.alertSetting.rawValue)")
        }

        // CloudKit 계정 상태 확인
        Task {
            do {
                let status = try await container.accountStatus()
                let statusStr: String
                switch status {
                case .available: statusStr = "available ✅"
                case .noAccount: statusStr = "noAccount ❌ (iCloud 로그인 필요)"
                case .restricted: statusStr = "restricted ⚠️"
                case .couldNotDetermine: statusStr = "couldNotDetermine ⚠️"
                case .temporarilyUnavailable: statusStr = "temporarilyUnavailable ⚠️"
                @unknown default: statusStr = "unknown(\(status.rawValue))"
                }
                print("[진단] CloudKit 계정 상태: \(statusStr)")
            } catch {
                print("[진단] CloudKit 계정 에러: \(error.localizedDescription)")
            }
        }

        // 구독 목록 확인
        Task {
            do {
                let subscriptions = try await container.publicCloudDatabase.allSubscriptions()
                print("[진단] 등록된 구독 수: \(subscriptions.count)")
                for sub in subscriptions {
                    print("[진단]   - \(sub.subscriptionID) (type: \(type(of: sub)))")
                }
            } catch {
                print("[진단] 구독 조회 에러: \(error.localizedDescription)")
            }
        }
        print("========== [진단] 진단 완료 ==========")
    }

    // MARK: - Handle CloudKit Notification
    func handleCloudKitNotification(userInfo: [AnyHashable: Any]) {
        print("[PUSH] ========== 리모트 알림 수신 ==========")
        print("[PUSH] userInfo keys: \(userInfo.keys.map { "\($0)" })")
        print("[PUSH] userInfo 전체: \(userInfo)")

        // CKNotification으로 먼저 파싱 시도
        let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        print("[PUSH] CKNotification 타입: \(type(of: ckNotification))")
        print("[PUSH] notificationType: \(ckNotification?.notificationType.rawValue ?? -1) (1=query, 2=recordZone, 3=readNotification)")
        print("[PUSH] subscriptionID: \(ckNotification?.subscriptionID ?? "nil")")

        guard let notification = ckNotification as? CKQueryNotification else {
            print("[PUSH] ❌ CKQueryNotification 캐스팅 실패 - notificationType: \(ckNotification?.notificationType.rawValue ?? -1)")
            // CKQueryNotification이 아니어도 데이터가 있을 수 있음
            if let aps = userInfo["aps"] as? [String: Any] {
                print("[PUSH] aps 내용: \(aps)")
                if let alert = aps["alert"] as? String {
                    print("[PUSH] alert: \(alert)")
                }
            }
            return
        }

        print("[PUSH] reason: \(notification.queryNotificationReason.rawValue) (1=recordCreated, 2=recordUpdated, 3=recordDeleted)")
        print("[PUSH] recordFields: \(notification.recordFields ?? [:])")
        print("[PUSH] recordID: \(notification.recordID?.recordName ?? "nil")")

        guard notification.queryNotificationReason == .recordCreated else {
            print("[PUSH] recordCreated가 아니므로 무시 (reason=\(notification.queryNotificationReason.rawValue))")
            return
        }

        let locationName = notification.recordFields?["locationName"] as? String ?? "공유된 메모"
        let viewerName = notification.recordFields?["viewerName"] as? String ?? ""

        print("[PUSH] ✅ 알림 데이터 추출 - locationName: \(locationName), viewerName: \(viewerName)")

        let viewNotification = ViewNotification(
            locationName: locationName,
            viewerName: viewerName
        )
        viewNotifications.insert(viewNotification, at: 0)
        if viewNotifications.count > 100 {
            viewNotifications = Array(viewNotifications.prefix(100))
        }
        saveData()

        // 로컬 알림도 표시 (CloudKit alertBody가 동작하지 않을 수 있으므로 백업용)
        showLocalNotification(viewNotification)
        print("[PUSH] ✅ 알림 데이터 저장 + 로컬 알림 표시 완료")
        print("[PUSH] ========== 리모트 알림 처리 완료 ==========")
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

