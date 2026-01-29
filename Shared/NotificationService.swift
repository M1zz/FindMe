//
//  NotificationService.swift
//  FindMe
//
//  알림 전송 서비스 (App Clip에서 사용)
//  CloudKit Web Services API로 공용 DB에 레코드 저장
//  (App Clip은 CloudKit 네이티브 쓰기가 불가하므로 HTTP API 사용)
//

import Foundation

struct NotificationService {

    // CloudKit Web Services 설정
    private static let containerID = "iCloud.com.leeo.FindMe"
    private static let environment = "production" // TestFlight/App Store용
    private static let baseURL = "https://api.apple-cloudkit.com/database/1/\(containerID)/\(environment)/public/records/modify"

    // CloudKit Web Services API Key (CloudKit Dashboard → API Access → API Tokens에서 생성)
    // ⚠️ 반드시 본인의 API 토큰으로 교체하세요
    private static let apiToken = "5e2372babeed6db4c439bcc57d47b65c1062412c855c29b8f2433d214ada9855"

    /// 멘토에게 알림 전송 (CloudKit Web Services로 공용 DB에 레코드 저장)
    static func notifyOwner(
        ownerID: String,
        locationName: String,
        viewerName: String = ""
    ) async throws {
        print("[CLIP] notifyOwner 호출 - ownerID: \(ownerID), locationName: \(locationName), viewerName: \(viewerName)")

        guard !ownerID.isEmpty else {
            print("[CLIP] ownerID가 비어있음 - 알림 전송 취소")
            return
        }

        let urlString = "\(baseURL)?ckAPIToken=\(apiToken)"
        guard let url = URL(string: urlString) else {
            print("[CLIP] URL 생성 실패: \(urlString)")
            return
        }

        print("[CLIP] CloudKit Web Services 요청 URL: \(url)")

        let body: [String: Any] = [
            "operations": [[
                "operationType": "create",
                "record": [
                    "recordType": "ViewNotification",
                    "fields": [
                        "ownerID": ["value": ownerID],
                        "locationName": ["value": locationName],
                        "viewerName": ["value": viewerName],
                        "timestamp": ["value": Int(Date().timeIntervalSince1970 * 1000), "type": "TIMESTAMP"]
                    ]
                ]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("[CLIP] CloudKit Web Services 요청 전송 중...")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            let responseBody = String(data: data, encoding: .utf8) ?? "no body"
            if httpResponse.statusCode == 200 {
                print("[CLIP] 레코드 저장 성공 (200)")
                print("[CLIP] 응답: \(responseBody)")
            } else {
                print("[CLIP] 레코드 저장 실패 (\(httpResponse.statusCode))")
                print("[CLIP] 응답: \(responseBody)")
            }
        }
    }
}
