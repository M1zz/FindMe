//
//  NotificationService.swift
//  FindMe
//
//  알림 전송 서비스 (App Clip에서 사용)
//

import Foundation

struct NotificationService {
    
    /// 멘토에게 알림 전송 (Firebase Function 호출)
    static func notifyOwner(
        token: String,
        locationName: String,
        viewerName: String = ""
    ) async {
        guard !token.isEmpty else {
            print("⚠️ Push token is empty")
            return
        }
        
        // Firebase Cloud Function URL
        // 실제 배포 시 본인의 Function URL로 교체
        let functionURL = "https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendViewNotification"
        
        guard let url = URL(string: functionURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "token": token,
            "locationName": locationName,
            "viewerName": viewerName,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Notification sent successfully")
                } else {
                    print("❌ Notification failed: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Failed to send notification: \(error.localizedDescription)")
            // 네트워크 에러 시에도 앱은 계속 작동
        }
    }
}
