import SwiftUI
import WebKit
import AVFoundation

// MARK: - Week Calendar
struct WeekCalendarView: View {
    let completedDays: [String]
    let joinedAt: String?

    var days: [(letter: String, date: Int, isToday: Bool, isComplete: Bool, isFuture: Bool, isPast: Bool)] {
        let cal = Calendar.current
        let today = Date()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let joinDate = joinedAt.flatMap { fmt.date(from: String($0.prefix(10))) }

        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        comps.weekday = 2
        let weekStart = cal.date(from: comps) ?? today

        let dayLetters = ["M","T","W","T","F","S","S"]

        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i, to: weekStart)!
            let key = fmt.string(from: date)
            let isToday = cal.isDateInToday(date)
            let isFuture = date > today && !isToday
            let isPast = date < today && !isToday
            let isBeforeJoin = joinDate.map { date < $0 } ?? false
            return (
                letter: dayLetters[i],
                date: cal.component(.day, from: date),
                isToday: isToday,
                isComplete: completedDays.contains(key) && !isBeforeJoin,
                isFuture: isFuture,
                isPast: isPast || isBeforeJoin
            )
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 6) {
                    Text(day.letter)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(
                            day.isPast ? Color(.systemGray3) :
                            day.isFuture ? Color(.systemGray4) :
                            .secondary
                        )

                    ZStack {
                        Circle()
                            .fill(
                                day.isComplete ? Color.brand.opacity(0.15) :
                                day.isToday ? Color.accent :
                                Color.clear
                            )
                            .frame(width: 36, height: 36)

                        if day.isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.brand)
                        } else {
                            Text("\(day.date)")
                                .font(.system(size: 14, weight: day.isToday ? .semibold : .regular))
                                .foregroundColor(
                                    day.isPast ? Color(.systemGray3) :
                                    day.isFuture ? Color(.systemGray5) :
                                    day.isToday ? .white : .primary
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct TaskCard: View {
    let task: (id: String, title: String, subtitle: String, duration: String)
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { if !isCompleted { action() } }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isCompleted ? Color.accent : Color(.systemGray4), lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isCompleted ? Color.accent : Color.clear))
                        .frame(width: 32, height: 32)
                    if isCompleted {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    } else {
                        Text(task.duration).font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title).font(.system(size: 15, weight: .semibold))
                        .strikethrough(isCompleted).foregroundColor(isCompleted ? .secondary : .primary)
                    Text(task.subtitle).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                if !isCompleted {
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .opacity(isCompleted ? 0.7 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let streak: Int

    var message: String {
        if streak == 0 { return "Start your streak today. Every journey begins with one step." }
        if streak == 1 { return "Day 1 complete. You showed up — that matters." }
        if streak < 7 { return "You're building something real. Keep going." }
        if streak < 14 { return "A whole week of showing up. That's not nothing." }
        if streak < 30 { return "This is becoming a habit. God notices faithfulness." }
        return "Your consistency is a form of worship. Keep it going."
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(streak)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color.accent)
                        Text(streak == 1 ? "day streak" : "day streak")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                // Flame stack
                HStack(spacing: -4) {
                    ForEach(0..<min(streak, 7), id: \.self) { i in
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.accent.opacity(Double(i + 1) / Double(min(streak, 7))))
                    }
                }
            }
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accent.opacity(0.2), lineWidth: 1)
        )
    }
}
struct DevotionalView: View {
    var body: some View {
        SGWebView(path: "/devotional")
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
    }
}

