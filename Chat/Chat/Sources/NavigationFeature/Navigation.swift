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
import Account
import MqttClient
import DatabaseClient

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
		var connState: MqttConnState = .connecting
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
		case mqttConnState(MqttConnState)
		case didReceiveMessageOperation(MessageOperation)
		case path(StackAction<Path.State, Path.Action>)
	}

	public var body: some ReducerOf<Self> {
		Scope(state: \.dialog, action: \.dialog, child: DialogListLogic.init)
		Scope(state: \.contact, action: \.contact, child: ContactListLogic.init)
		Scope(state: \.setting, action: \.setting, child: SettingLogic.init)
		Reduce { state, action in
			switch action {
			case let .contact(.delegate(.didSelectContact(dialogId, peerId))):
				state.path.append(.messageList(MessageListLogic.State(dialogId: dialogId, contactId: peerId)))
				return .none
				
			case let .dialog(.delegate(.didSelectDialog(dialog))):
				@Dependency(\.accountClient) var accountClient
				let selfId = accountClient.currentAccount()!.id
				let peerId = selfId == dialog.participantId1 ? dialog.participantId2 : dialog.participantId1
				state.path.append(.messageList(MessageListLogic.State(dialogId: dialog.id, contactId: peerId)))
				return .none

			case let .tabChanged(tab):
				state.currentTab = tab
				return .none
				
			case let .mqttConnState(connState):
				state.connState = connState
				return .none
				
			case let .didReceiveMessageOperation(messageOperation):
				switch messageOperation {
				case let .didSendMessage(messages):
					for pathStateId in state.path.ids {
						let pathState = state.path[id: pathStateId]
						switch pathState {
						case let .messageList(messageListState):
							let filteredMessages = messages.filter { $0.dialogId == messageListState.dialogId }
							if !filteredMessages.isEmpty {
								return .run { send in
									await send(.path(.element(id: pathStateId, action: .messageList(.didReceiveMessages(messages: filteredMessages)))), animation: .default)
								}
							}
						case .none:
							return .none
						}
					}
					return .none
				}
			case .onTask:
				return .run { send in
					@Dependency(\.databaseClient) var databaseClient
					@Dependency(\.accountClient) var accountClient
					let contacts = try await databaseClient.fetchContacts()
					if contacts.isEmpty,
						let account = accountClient.currentAccount() {
						let _ = try await databaseClient.insertContacts(Account.mocks.filter({ $0.id != account.id }).map({ Contact(id: $0.id, name: $0.name) }))
					}
				}
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
			VStack {
				TabView(selection: $store.currentTab.sending(\.tabChanged)) {
					DialogListView(
						store: store.scope(
							state: \.dialog,
							action: \.dialog
						)
					)
					.tabItem {
						Label("Chat", systemImage: "bubble.left.fill")
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
					}
					.tag(NavigationLogic.Tab.setting)
				}
				
				if store.connState != .connected {
					HStack {
						Spacer()
						Text("\(store.connState.rawValue)")
							.font(.footnote.bold())
							.foregroundStyle(Color(.systemBackground).gradient)
							.padding(.vertical)
						Spacer()
					}
					.background(Color.primary.gradient)
					.transition(.move(edge: .bottom))
				}
			}
			.task {
				await store.send(.onTask).finish()
			}
			.tint(.primary)
		} destination: { store in
			switch store.case {
			case let .messageList(store):
				MessageListView(store: store)
			}
		}
	}
}
