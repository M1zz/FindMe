//
//  DataManager.swift
//  FindMe
//
//  데이터 관리 (저장된 위치들)
//

import Foundation
import CoreLocation

@MainActor
class DataManager: ObservableObject {
    @Published var savedLocations: [SavedLocation] = []
    @Published var currentLocation: LocationData?
    @Published var settings: AppSettings = AppSettings()
    
    private let savedLocationsKey = "savedLocations"
    private let settingsKey = "appSettings"
    
    init() {
        loadData()
    }
    
    // MARK: - Load / Save
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: savedLocationsKey),
           let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = locations
        }
        
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = settings
        }
    }
    
    func saveData() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(data, forKey: savedLocationsKey)
        }
        
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    // MARK: - Location Operations
    func saveLocation(_ locationData: LocationData) {
        let saved = SavedLocation(data: locationData)
        savedLocations.insert(saved, at: 0)
        
        // 최대 50개만 유지
        if savedLocations.count > 50 {
            savedLocations = Array(savedLocations.prefix(50))
        }
        
        saveData()
    }
    
    func updateLocation(_ location: SavedLocation) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations[index] = location
            saveData()
        }
    }
    
    func deleteLocation(_ location: SavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
        saveData()
    }
    
    func toggleFavorite(_ location: SavedLocation) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations[index].isFavorite.toggle()
            saveData()
        }
    }
    
    // MARK: - Favorites
    var favoriteLocations: [SavedLocation] {
        savedLocations.filter { $0.isFavorite }
    }
    
    var recentLocations: [SavedLocation] {
        savedLocations.filter { !$0.isFavorite }
    }
}
