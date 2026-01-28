//
//  LocationManager.swift
//  FindMe
//
//  GPS 및 장소 검색
//

import Foundation
import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Authorization
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Location
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - Search Places
    func searchPlaces(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let location = currentLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        }
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            searchResults = response.mapItems.map { item in
                SearchResult(
                    name: item.name ?? "알 수 없는 장소",
                    address: formatAddress(item.placemark),
                    coordinate: item.placemark.coordinate
                )
            }
        } catch {
            searchResults = []
        }
        
        isSearching = false
    }
    
    // MARK: - Reverse Geocoding
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> (name: String, address: String)? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let name = placemark.name ?? ""
                let address = formatCLAddress(placemark)
                return (name, address)
            }
        } catch {
            print("Geocode error: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Format Address
    private func formatAddress(_ placemark: MKPlacemark) -> String {
        var parts: [String] = []
        if let locality = placemark.locality { parts.append(locality) }
        if let subLocality = placemark.subLocality { parts.append(subLocality) }
        if let thoroughfare = placemark.thoroughfare { parts.append(thoroughfare) }
        if let subThoroughfare = placemark.subThoroughfare { parts.append(subThoroughfare) }
        return parts.joined(separator: " ")
    }
    
    private func formatCLAddress(_ placemark: CLPlacemark) -> String {
        var parts: [String] = []
        if let locality = placemark.locality { parts.append(locality) }
        if let subLocality = placemark.subLocality { parts.append(subLocality) }
        if let thoroughfare = placemark.thoroughfare { parts.append(thoroughfare) }
        if let subThoroughfare = placemark.subThoroughfare { parts.append(subThoroughfare) }
        return parts.joined(separator: " ")
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            currentLocation = locations.last
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}

// MARK: - Search Result
struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}
