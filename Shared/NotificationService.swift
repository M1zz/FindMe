//
//  NotificationService.swift
//  FindMe
//
//  알림 전송 서비스 (App Clip + 메인 앱 공유)
//  CloudKit Server-to-Server Key 인증으로 공용 DB에 레코드 저장
//

import Foundation
import CryptoKit

struct NotificationService {

    // CloudKit Server-to-Server Key ID
    private static let keyID = "a0f254028114af9b3598da0c512c2acf16374137420190552c2b55f054659329"

    // EC Private Key (DER format, base64 encoded)
    private static let privateKeyBase64 = "MHcCAQEEIM8NjqwL5q8DkD6T6BivterW+AULt24r7xoy/5zgmnVaoAoGCCqGSM49AwEHoUQDQgAEGpZUe/W9ir6aqnbpgY0anf+HmepjjeEla81XjZacEHMjlMTG1FT5kocZ8Mkv1ae41fbFPuSlB9WPY74U6sqtLg=="

    private static let containerID = "iCloud.com.leeo.FindMe"

    #if DEBUG
    private static let environment = "development"
    #else
    private static let environment = "production"
    #endif

    /// 소유자에게 알림 전송 (CloudKit Web Services API로 ViewNotification 레코드 생성)
    static func notifyOwner(
        ownerID: String,
        locationName: String,
        viewerName: String = ""
    ) async throws {
        print("[CLIP] ===== notifyOwner 시작 (S2S) =====")
        print("[CLIP] ownerID: \(ownerID) (길이: \(ownerID.count))")
        print("[CLIP] locationName: \(locationName)")
        print("[CLIP] viewerName: \(viewerName)")
        print("[CLIP] environment: \(environment)")

        guard !ownerID.isEmpty else {
            print("[CLIP] ❌ ownerID가 비어있음 - 알림 전송 취소")
            return
        }

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // CloudKit Web Services API - records/modify
        let subpath = "/database/1/\(containerID)/\(environment)/public/records/modify"
        let urlString = "https://api.apple-cloudkit.com\(subpath)"

        guard let url = URL(string: urlString) else {
            print("[CLIP] ❌ URL 생성 실패")
            return
        }

        // 요청 본문
        let body: [String: Any] = [
            "operations": [[
                "operationType": "create",
                "record": [
                    "recordType": "ViewNotification",
                    "fields": [
                        "ownerID": ["value": ownerID],
                        "locationName": ["value": locationName],
                        "viewerName": ["value": viewerName],
                        "timestamp": ["value": timestamp, "type": "INT64"]
                    ]
                ]
            ]]
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        print("[CLIP] 요청 본문: \(String(data: bodyData, encoding: .utf8) ?? "")")

        // ISO 8601 날짜
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let dateString = dateFormatter.string(from: Date())

        // 서명 생성
        let signature = try signRequest(date: dateString, body: bodyData, subpath: subpath)
        print("[CLIP] 서명 생성 완료")

        // HTTP 요청
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(keyID, forHTTPHeaderField: "X-Apple-CloudKit-Request-KeyID")
        request.setValue(dateString, forHTTPHeaderField: "X-Apple-CloudKit-Request-ISO8601Date")
        request.setValue(signature, forHTTPHeaderField: "X-Apple-CloudKit-Request-SignatureV1")

        print("[CLIP] CloudKit API 호출 중...")
        print("[CLIP] URL: \(urlString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("[CLIP] HTTP 상태 코드: \(httpResponse.statusCode)")

            if let responseString = String(data: data, encoding: .utf8) {
                print("[CLIP] 응답: \(responseString)")
            }

            if httpResponse.statusCode == 200 {
                print("[CLIP] ✅ 레코드 저장 성공!")
            } else {
                print("[CLIP] ❌ API 에러 - 상태 코드: \(httpResponse.statusCode)")
                throw NSError(
                    domain: "NotificationService",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "CloudKit API error: \(httpResponse.statusCode)"]
                )
            }
        }

        print("[CLIP] ===== notifyOwner 완료 =====")
    }

    /// CloudKit S2S 요청 서명 생성
    /// 서명 대상: "[ISO8601 날짜]:[Base64(SHA256(본문))]:[URL subpath]"
    private static func signRequest(date: String, body: Data, subpath: String) throws -> String {
        // 1. 본문 SHA256 해시 → Base64
        let bodyHash = SHA256.hash(data: body)
        let bodyHashBase64 = Data(bodyHash).base64EncodedString()

        // 2. 서명 대상 문자열 조합
        let message = "\(date):\(bodyHashBase64):\(subpath)"
        print("[CLIP] 서명 메시지: \(message)")

        // 3. EC P-256 비밀키 로드
        guard let keyData = Data(base64Encoded: privateKeyBase64) else {
            throw NSError(domain: "NotificationService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "비밀키 디코딩 실패"])
        }
        let privateKey = try P256.Signing.PrivateKey(derRepresentation: keyData)

        // 4. ECDSA-SHA256 서명
        let messageData = Data(message.utf8)
        let signature = try privateKey.signature(for: messageData)

        // 5. DER 형식 → Base64
        return signature.derRepresentation.base64EncodedString()
    }
}
