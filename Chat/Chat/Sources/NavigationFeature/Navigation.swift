//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/9.
//

import ComposableArchitecture
import ContactFeature
import DialogFeature
import Foundation
import MessageFeature
import SettingFeature
import SwiftUI

@Reducer
public struct NavigationLogic {
	public init() {}

	public enum Tab: Equatable, Hashable {
		case dialog
		case contact
		case setting
	}

	@ObservableState
	public struct State: Equatable {
		var currentTab: Tab = .dialog
		var dialog = DialogListLogic.State()
		var contact = ContactListLogic.State()
		var setting = SettingLogic.State()
		var path = StackState<Path.State>()
		public init() {}
	}

	public enum Action {
		case onTask
		case tabChanged(Tab)
		case dialog(DialogListLogic.Action)
		case contact(ContactListLogic.Action)
		case setting(SettingLogic.Action)
		case path(StackAction<Path.State, Path.Action>)
	}

	public var body: some ReducerOf<Self> {
		Scope(state: \.dialog, action: \.dialog, child: DialogListLogic.init)
		Scope(state: \.contact, action: \.contact, child: ContactListLogic.init)
		Scope(state: \.setting, action: \.setting, child: SettingLogic.init)
		Reduce { state, action in
			switch action {
			case let .contact(.delegate(.didSelectContact(contactId))):
				state.path.append(.messageList(MessageListLogic.State(contactId: contactId)))
				return .none
				
			case let .dialog(.delegate(.didSelectDialog(dialog))):
				state.path.append(.messageList(MessageListLogic.State(contactId: dialog.peerId)))
				return .none

			case let .tabChanged(tab):
				state.currentTab = tab
				return .none
			default: return .none
			}
		}
		.forEach(\.path, action: \.path)
	}

	@Reducer(state: .equatable)
	public enum Path {
		case messageList(MessageListLogic)
	}
}

public struct RootView: View {
	@Bindable var store: StoreOf<NavigationLogic>
	public init(store: StoreOf<NavigationLogic>) {
		self.store = store
	}

	public var body: some View {
		NavigationStack(
			path: $store.scope(state: \.path, action: \.path))
		{
			TabView(selection: $store.currentTab.sending(\.tabChanged)) {
				DialogListView(
					store: store.scope(
						state: \.dialog,
						action: \.dialog
					)
				)
				.tabItem {
					Label("Chat", systemImage: "bubble.left.fill")
						.tint(.primary)
				}
				.tag(NavigationLogic.Tab.dialog)

				ContactListView(
					store: store.scope(
						state: \.contact,
						action: \.contact
					)
				)
				.tabItem {
					Label("Contact", systemImage: "person.and.person.fill")
						.tint(.primary)
				}
				.tag(NavigationLogic.Tab.contact)

				SettingView(
					store: store.scope(
						state: \.setting,
						action: \.setting
					)
				)
				.tabItem {
					Label("Seeting", systemImage: "gearshape.fill")
						.tint(.primary)
				}
				.tag(NavigationLogic.Tab.setting)
			}
			.task { await store.send(.onTask).finish() }
		} destination: { store in
			switch store.case {
			case let .messageList(store):
				MessageListView(store: store)
			}
		}
	}
}
