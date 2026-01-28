//
//  SearchView.swift
//  FindMe
//
//  장소 검색
//

import SwiftUI
import MapKit

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    
    let onSelect: (SearchResult) -> Void
    
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if locationManager.isSearching {
                    ProgressView("검색 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if locationManager.searchResults.isEmpty {
                    if searchText.isEmpty {
                        emptyState
                    } else {
                        noResultsState
                    }
                } else {
                    resultsList
                }
            }
            .navigationTitle("장소 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "장소 또는 주소 검색")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await locationManager.searchPlaces(query: newValue)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("장소를 검색하세요")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                ForEach(["스타벅스 강남역", "서울역", "코엑스"], id: \.self) { example in
                    Button {
                        searchText = example
                    } label: {
                        Text(example)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Results
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("결과가 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Results List
    private var resultsList: some View {
        List(locationManager.searchResults) { result in
            Button {
                onSelect(result)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text(result.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    SearchView(locationManager: LocationManager()) { _ in }
}
