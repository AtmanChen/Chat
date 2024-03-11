//
//  ChatApp.swift
//  Chat
//
//  Created by Anderson  on 2024/3/9.
//

import SwiftUI
import ComposableArchitecture
import ChatFeature

@main
struct ChatApp: App {
	let store = Store(
		initialState: ChatLogic.State(),
		reducer: {
			ChatLogic()._printChanges()
		}
	)
	var body: some Scene {
		WindowGroup {
			ChatView(store: store)
		}
	}
}
