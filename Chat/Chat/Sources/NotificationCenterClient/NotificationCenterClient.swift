//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/10.
//

import Dependencies
import Foundation
import SwiftData

public struct NotificationCenterClient {
	public var observe: @Sendable ([Notification.Name]) -> AsyncStream<Notification>
	public var post: @Sendable (Notification.Name, Any?, [AnyHashable: Any]?) -> Void
}

extension NotificationCenterClient: DependencyKey {
	public static var liveValue: NotificationCenterClient = Self(
		observe: { notificationNames in
			AsyncStream { continuation in
				let observer = NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) { notification in
					if notificationNames.contains(notification.name) {
						continuation.yield(notification)
					}
				}
				continuation.onTermination = { @Sendable _ in
					NotificationCenter.default.removeObserver(observer)
				}
			}
		},
		post: { name, obj, userInfo in
			NotificationCenter.default.post(name: name, object: obj, userInfo: userInfo)
		}
	)
}

extension DependencyValues {
	public var notificationCenter: NotificationCenterClient {
		get { self[NotificationCenterClient.self] }
		set { self[NotificationCenterClient.self] = newValue }
	}
}
