//
//  SharedModels.swift
//  FindMe
//
//  메인 앱과 App Clip이 공유하는 모델
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Location Data (QR에 담기는 데이터)
struct LocationData: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var name: String
    var memo: String
    var address: String
    var ownerName: String       // 멘토 이름
    var pushToken: String       // 푸시 알림용 토큰
    
    init(
        latitude: Double = 0,
        longitude: Double = 0,
        name: String = "",
        memo: String = "",
        address: String = "",
        ownerName: String = "",
        pushToken: String = ""
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.memo = memo
        self.address = address
        self.ownerName = ownerName
        self.pushToken = pushToken
    }
    
    init(coordinate: CLLocationCoordinate2D, name: String = "", memo: String = "", address: String = "") {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.name = name
        self.memo = memo
        self.address = address
        self.ownerName = ""
        self.pushToken = ""
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isValid: Bool {
        latitude != 0 && longitude != 0
    }
    
    // MARK: - URL 생성 (App Clip용)
    
    /// App Clip URL 생성
    /// 형식: https://m1zz.github.io/l?lat=37.5665&lng=126.9780&name=스타벅스&memo=2층창가&owner=김멘토&token=xxx
    func toAppClipURL(baseURL: String = "https://m1zz.github.io/l") -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.6f", latitude)),
            URLQueryItem(name: "lng", value: String(format: "%.6f", longitude)),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "memo", value: memo),
            URLQueryItem(name: "addr", value: address),
            URLQueryItem(name: "owner", value: ownerName),
            URLQueryItem(name: "token", value: pushToken)
        ]
        return components?.url
    }
    
    /// Apple Maps URL (백업용)
    func toAppleMapsURL() -> URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "q", value: name.isEmpty ? "위치" : name),
            URLQueryItem(name: "z", value: "17")
        ]
        return components?.url
    }
    
    /// Google Maps URL (백업용)
    func toGoogleMapsURL() -> URL? {
        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: "\(latitude),\(longitude)")
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
            case "lat":
                data.latitude = Double(item.value ?? "") ?? 0
            case "lng":
                data.longitude = Double(item.value ?? "") ?? 0
            case "name":
                data.name = item.value ?? ""
            case "memo":
                data.memo = item.value ?? ""
            case "addr":
                data.address = item.value ?? ""
            case "owner":
                data.ownerName = item.value ?? ""
            case "token":
                data.pushToken = item.value ?? ""
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
    var defaultMapType: MapType
    var showMemoOnQR: Bool
    var qrSize: QRSize
    
    init(
        defaultMapType: MapType = .apple,
        showMemoOnQR: Bool = true,
        qrSize: QRSize = .medium
    ) {
        self.defaultMapType = defaultMapType
        self.showMemoOnQR = showMemoOnQR
        self.qrSize = qrSize
    }
}

enum MapType: String, Codable, CaseIterable {
    case apple = "apple"
    case google = "google"
    
    var displayName: String {
        switch self {
        case .apple: return "Apple Maps"
        case .google: return "Google Maps"
        }
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
