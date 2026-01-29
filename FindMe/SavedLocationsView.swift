//
//  SavedLocationsView.swift
//  FindMe
//
//  저장된 메모 목록
//

import SwiftUI

struct SavedLocationsView: View {
    @EnvironmentObject var dataManager: DataManager

    @State private var selectedLocation: SavedLocation?
    @State private var showingQRDetail = false

    var body: some View {
        NavigationStack {
            Group {
                if dataManager.savedLocations.isEmpty {
                    emptyState
                } else {
                    locationsList
                }
            }
            .navigationTitle("저장됨")
            .sheet(item: $selectedLocation) { location in
                QRDetailView(locationData: location.data)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("저장된 메모가 없습니다")
                .font(.title3)
                .fontWeight(.semibold)

            Text("자주 사용하는 메모를 저장하면\n여기에서 바로 QR을 만들 수 있어요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Locations List
    private var locationsList: some View {
        List {
            // 즐겨찾기
            if !dataManager.favoriteLocations.isEmpty {
                Section("즐겨찾기") {
                    ForEach(dataManager.favoriteLocations) { location in
                        LocationRow(location: location) {
                            selectedLocation = location
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                dataManager.toggleFavorite(location)
                            } label: {
                                Image(systemName: "star.slash")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                dataManager.deleteLocation(location)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }

            // 최근
            if !dataManager.recentLocations.isEmpty {
                Section("최근") {
                    ForEach(dataManager.recentLocations) { location in
                        LocationRow(location: location) {
                            selectedLocation = location
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                dataManager.toggleFavorite(location)
                            } label: {
                                Image(systemName: "star.fill")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                dataManager.deleteLocation(location)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Location Row
struct LocationRow: View {
    let location: SavedLocation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "text.bubble.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                // 정보
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(location.data.name.isEmpty ? "저장된 메모" : location.data.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if location.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }

                    if !location.data.memo.isEmpty {
                        Text(location.data.memo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(location.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "qrcode")
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    SavedLocationsView()
        .environmentObject(DataManager())
}
