
//  NotificationScheduler.swift
//  Reading Tracker
//
//  Thin delivery wrapper around UNUserNotificationCenter.
//  The IntelligentNotificationEngine decides WHAT to send and WHEN.
//  This file handles only HOW to send it.
//
//  It is intentionally stateless — no candidate history, no cooldown logic.
//  The engine's own gating (shouldNotify threshold, notificationHistory param)
//  is the authority on delivery frequency.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    // MARK: - Authorization

    /// Requests notification permission from the user.
    /// Safe to call multiple times — UNUserNotificationCenter is idempotent once
    /// the user has made a decision.
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                // User denied. App functions fully without notifications.
                // Log for diagnostics but treat as a soft failure.
                print("[NotificationScheduler] User denied notification permission.")
            }
        } catch {
            print("[NotificationScheduler] Authorization request failed: \(error)")
        }
    }

    // MARK: - Delivery

    /// Schedules a notification from an IntelligentNotificationEngine candidate.
    ///
    /// Delivery timing:
    ///   - If `candidate.recommendedDeliveryTime` is > 60 s in the future,
    ///     a time-interval trigger is used.
    ///   - Otherwise the notification fires immediately (nil trigger = now).
    ///
    /// Each notification receives a unique identifier so concurrent candidates
    /// don't silently replace each other in the pending queue.
    func schedule(candidate: NotificationCandidate) async {
        let content = UNMutableNotificationContent()
        content.title = candidate.title
        content.body = candidate.message
        content.sound = .default

        let secondsUntilDelivery = candidate.recommendedDeliveryTime.timeIntervalSinceNow
        let trigger: UNNotificationTrigger? = secondsUntilDelivery > 60
            ? UNTimeIntervalNotificationTrigger(timeInterval: secondsUntilDelivery,
                                                repeats: false)
            : nil

        let request = UNNotificationRequest(
            identifier: "rt-prompt-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("[NotificationScheduler] Failed to schedule notification: \(error)")
        }
    }
}
