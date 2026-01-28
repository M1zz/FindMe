//
//  ContentView.swift
//  FindMe
//
//  메인 탭 뷰
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("만들기", systemImage: "qrcode")
                }
                .tag(0)
            
            SavedLocationsView()
                .tabItem {
                    Label("저장됨", systemImage: "bookmark.fill")
                }
                .tag(1)
            
            NotificationsView()
                .tabItem {
                    Label("알림", systemImage: "bell.fill")
                }
                .tag(2)
                .badge(notificationManager.viewNotifications.count)
            
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
        .environmentObject(NotificationManager.shared)
}
