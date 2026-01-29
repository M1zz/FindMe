//
//  SharedModels.swift
//  FindMe
//
//  메인 앱과 App Clip이 공유하는 모델
//

import Foundation
import SwiftUI

// MARK: - Location Data (QR에 담기는 데이터)
struct LocationData: Codable, Equatable {
    var name: String
    var memo: String
    var ownerName: String       // 멘토 이름
    var ownerID: String         // CloudKit 알림용 소유자 ID

    init(
        name: String = "",
        memo: String = "",
        ownerName: String = "",
        ownerID: String = ""
    ) {
        self.name = name
        self.memo = memo
        self.ownerName = ownerName
        self.ownerID = ownerID
    }

    var isValid: Bool {
        !name.isEmpty || !memo.isEmpty
    }

    // MARK: - URL 생성 (App Clip용)

    /// App Clip URL 생성
    /// 형식: https://m1zz.github.io/FindMe/l?owner=김멘토&memo=메모&name=제목&oid=xxx
    func toAppClipURL(baseURL: String = "https://m1zz.github.io/FindMe/l") -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "owner", value: ownerName),
            URLQueryItem(name: "memo", value: memo),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "oid", value: ownerID)
        ]
        return components?.url
    }

    // MARK: - URL 파싱 (App Clip에서 사용)

    /// URL에서 LocationData 파싱
    static func fromURL(_ url: URL) -> LocationData? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }

        var data = LocationData()

        for item in queryItems {
            switch item.name {
            case "name":
                data.name = item.value ?? ""
            case "memo":
                data.memo = item.value ?? ""
            case "owner":
                data.ownerName = item.value ?? ""
            case "oid":
                data.ownerID = item.value ?? ""
            default:
                break
            }
        }

        return data.isValid ? data : nil
    }
}

// MARK: - Saved Location (메인 앱에서 저장)
struct SavedLocation: Codable, Identifiable, Equatable {
    let id: UUID
    var data: LocationData
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        data: LocationData,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.data = data
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
    }
}

// MARK: - App Settings
struct AppSettings: Codable {
    var showMemoOnQR: Bool
    var qrSize: QRSize

    init(
        showMemoOnQR: Bool = true,
        qrSize: QRSize = .medium
    ) {
        self.showMemoOnQR = showMemoOnQR
        self.qrSize = qrSize
    }
}

enum QRSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"

    var displayName: String {
        switch self {
        case .small: return "작게"
        case .medium: return "보통"
        case .large: return "크게"
        }
    }

    var points: CGFloat {
        switch self {
        case .small: return 150
        case .medium: return 200
        case .large: return 280
        }
    }
}
