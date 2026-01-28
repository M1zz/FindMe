//
//  NotificationManager.swift
//  FindMe
//
//  푸시 알림 관리
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var deviceToken: String = ""
    @Published var viewNotifications: [ViewNotification] = []
    
    private let tokenKey = "devicePushToken"
    private let notificationsKey = "viewNotifications"
    
    override init() {
        super.init()
        loadData()
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Handle Device Token
    func handleDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        UserDefaults.standard.set(tokenString, forKey: tokenKey)
        print("📱 Device Token: \(tokenString)")
    }
    
    // MARK: - Generate Local Token (서버 없이 테스트용)
    func generateLocalToken() -> String {
        if let saved = UserDefaults.standard.string(forKey: tokenKey), !saved.isEmpty {
            deviceToken = saved
            return saved
        }
        
        // 로컬 테스트용 고유 ID 생성
        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        deviceToken = token
        UserDefaults.standard.set(token, forKey: tokenKey)
        return token
    }
    
    // MARK: - Load/Save Notifications
    func loadData() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            deviceToken = token
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
        content.title = "📍 위치 확인됨"
        content.body = notification.viewerName.isEmpty 
            ? "누군가 '\(notification.locationName)' 위치를 확인했습니다"
            : "\(notification.viewerName)님이 '\(notification.locationName)' 위치를 확인했습니다"
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

