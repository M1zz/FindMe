//
//  NotificationsView.swift
//  FindMe
//
//  위치 확인 알림 목록
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if notificationManager.viewNotifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("알림")
            .toolbar {
                if !notificationManager.viewNotifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("지우기") {
                            showingClearAlert = true
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                // 테스트 버튼 (개발 중에만 사용)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        notificationManager.simulateView(locationName: "테스트 위치")
                    } label: {
                        Image(systemName: "bell.badge.fill")
                    }
                }
            }
            .alert("알림 삭제", isPresented: $showingClearAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    notificationManager.clearNotifications()
                }
            } message: {
                Text("모든 알림을 삭제하시겠습니까?")
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("아직 알림이 없습니다")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("누군가 QR을 스캔해서\n내 위치를 확인하면 알림이 옵니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 작동 방식 설명
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "1.circle.fill")
                        .foregroundStyle(.blue)
                    Text("QR 코드를 만들어 공유하세요")
                        .font(.subheadline)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "2.circle.fill")
                        .foregroundStyle(.blue)
                    Text("상대방이 QR을 스캔하면")
                        .font(.subheadline)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "3.circle.fill")
                        .foregroundStyle(.blue)
                    Text("여기서 알림을 받습니다")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        List {
            // 오늘
            let todayNotifications = notificationsForDate(Date())
            if !todayNotifications.isEmpty {
                Section("오늘") {
                    ForEach(todayNotifications) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
            
            // 어제
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let yesterdayNotifications = notificationsForDate(yesterday)
            if !yesterdayNotifications.isEmpty {
                Section("어제") {
                    ForEach(yesterdayNotifications) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
            
            // 이전
            let olderNotifications = notificationManager.viewNotifications.filter { notification in
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
                let notificationDate = calendar.startOfDay(for: notification.viewedAt)
                return notificationDate < yesterday
            }
            if !olderNotifications.isEmpty {
                Section("이전") {
                    ForEach(olderNotifications) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func notificationsForDate(_ date: Date) -> [ViewNotification] {
        let calendar = Calendar.current
        return notificationManager.viewNotifications.filter { notification in
            calendar.isDate(notification.viewedAt, inSameDayAs: date)
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: ViewNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "eye.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            // 정보
            VStack(alignment: .leading, spacing: 4) {
                if notification.viewerName.isEmpty {
                    Text("누군가 위치를 확인했습니다")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("\(notification.viewerName)님이 확인했습니다")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(notification.locationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(notification.viewedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Statistics Card
struct NotificationStatsCard: View {
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                title: "오늘",
                count: todayCount,
                icon: "eye.fill",
                color: .blue
            )
            
            Divider()
            
            StatItem(
                title: "이번 주",
                count: weekCount,
                icon: "calendar",
                color: .green
            )
            
            Divider()
            
            StatItem(
                title: "전체",
                count: notificationManager.viewNotifications.count,
                icon: "chart.bar.fill",
                color: .orange
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var todayCount: Int {
        let calendar = Calendar.current
        return notificationManager.viewNotifications.filter { notification in
            calendar.isDateInToday(notification.viewedAt)
        }.count
    }
    
    private var weekCount: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return notificationManager.viewNotifications.filter { notification in
            notification.viewedAt > weekAgo
        }.count
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NotificationsView()
        .environmentObject(NotificationManager.shared)
}
