//
//  ChatApp.swift
//  Chat
//
//  Created by Anderson  on 2024/3/9.
//

import SwiftUI
import ComposableArchitecture
import ChatFeature
import Account
import MqttClient

@main
struct ChatApp: App {
	let store = Store(
		initialState: ChatLogic.State(),
		reducer: {
			ChatLogic()
//				._printChanges()
//				.transformDependency(
//					\.mqtt
//				) {
//					@Dependency(\.accountClient) var accountClient
//					if let accountId = accountClient.currentAccount()?.id {
//						$0 = .live(config: MqttClientConfiguration(accountId: accountId))
//					} else {
//						$0 = .noop
//					}
//				}
		}
	)
	var body: some Scene {
		WindowGroup {
			ChatView(store: store)
		}
	}
}
