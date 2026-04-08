import Foundation

// MARK: - User
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let hasCompletedOnboarding: Int

    var isOnboarded: Bool { hasCompletedOnboarding != 0 }
    var firstName: String { name.components(separatedBy: " ").first ?? name }
    var initials: String {
        name.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        // Server returns bool or int — handle both
        if let intVal = try? container.decode(Int.self, forKey: .hasCompletedOnboarding) {
            hasCompletedOnboarding = intVal
        } else if let boolVal = try? container.decode(Bool.self, forKey: .hasCompletedOnboarding) {
            hasCompletedOnboarding = boolVal ? 1 : 0
        } else {
            hasCompletedOnboarding = 0
        }
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let user: User?
    let error: String?
}

// MARK: - Conversation
struct Conversation: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let channel: String?
    let createdAt: String
    var displayTitle: String { title ?? "Conversation" }
}

struct Message: Codable, Identifiable {
    let id: Int
    let role: String
    let content: String
    let createdAt: String
    var isUser: Bool { role == "user" }
}

struct MessagesResponse: Codable {
    let messages: [Message]
}

struct CreateConversationResponse: Codable {
    let id: Int
    let title: String?
}

// MARK: - Devotional
struct Devotional: Codable, Identifiable {
    let id: Int
    let title: String?
    let scriptureReference: String?
    let scriptureText: String?
    let reflectionContent: String?
    let todaysPractice: String?
    let closingPrayer: String?
}

struct DevotionalResponse: Codable {
    let success: Bool
    let data: Devotional?
    let completedTaskIds: [String]?
}

struct DevotionalGreeting: Codable {
    let greeting: String
    let subtext: String
    let currentStreak: Int
    let joinedAt: String?
}

struct GreetingResponse: Codable {
    let success: Bool
    let data: DevotionalGreeting?
}

// MARK: - Persona
struct Persona: Codable {
    let primaryStruggle: String?
    let graceArchetype: String?
    let transformationGoals: [String]?
}

// MARK: - Notifications
struct AppNotification: Codable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let body: String
    let isRead: Int
    let createdAt: String
    var isUnread: Bool { isRead == 0 }
}

struct NotificationsResponse: Codable {
    let notifications: [AppNotification]
    let unreadCount: Int
}

// MARK: - Journal
struct JournalEntry: Codable, Identifiable {
    let id: Int
    let content: String
    let mood: String?
    let verseReference: String?
    let createdAt: String
}

struct JournalResponse: Codable {
    let entries: [JournalEntry]
}

// MARK: - Display Maps
let STRUGGLE_DISPLAY: [String: String] = [
    "distant_from_god": "Feeling distant from God",
    "wrestling_doubts": "Wrestling with doubts",
    "feel_alone": "Feeling alone in faith",
    "guilt_shame": "Carrying guilt or shame",
    "life_overwhelming": "Life feeling overwhelming",
    "new_to_faith": "New to faith",
]

let GOAL_DISPLAY: [String: String] = [
    "gods_presence": "Feel God's presence daily",
    "doubts_controlled": "My doubts don't control me",
    "prayer_meaningful": "Prayer means something to me",
    "free_from_guilt": "Free from guilt I'm carrying",
    "faith_steady": "Faith is steady, not up and down",
    "understand_bible": "Understand the Bible better",
    "peace_not_anxiety": "Peace instead of anxiety",
    "friends_understand": "Friends who get my journey",
]

struct OnboardingResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - Stats
struct UserStats: Codable {
    let conversationCount: Int
    let messageCount: Int
    let currentStreak: Int
    let longestStreak: Int
}

// MARK: - Journey
struct JourneyEntry: Codable {
    let completedAt: String?
}

struct JourneyResponse: Codable {
    let success: Bool
    let data: [JourneyEntry]?
}

// MARK: - Full Persona
struct FullPersona: Codable {
    let primaryStruggle: String?
    let graceArchetype: String?
    let transformationGoals: [String]?
}

let ARCHETYPE_DISPLAY: [String: (name: String, description: String)] = [
    "wounded_seeker": ("Wounded Seeker", "Finding God through the pain"),
    "eager_builder": ("Eager Builder", "Growing deliberately, day by day"),
    "curious_explorer": ("Curious Explorer", "Following questions toward faith"),
    "returning_prodigal": ("Returning Prodigal", "Coming home after time away"),
    "struggling_saint": ("Struggling Saint", "Faithful despite the doubts"),
]
