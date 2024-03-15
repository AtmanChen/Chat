//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/10.
//

import Account
import ComposableArchitecture
import DatabaseClient
import Foundation
import MqttClient
import SwiftUI
import Constant
import CocoaMQTT

@Reducer
public struct MessageListLogic {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var dialogId: UUID
		public var contactId: UUID
		public var messages: IdentifiedArrayOf<Message> = []
		public var messageInput = MessageInputLogic.State()
		public var dialogTitle: String = ""
		public init(dialogId: UUID, contactId: UUID) {
			self.dialogId = dialogId
			self.contactId = contactId
		}
	}

	public enum Action {
		case onTask
		case fetchContactResponse(Result<Contact, ContactError>)
		case fetchMessages
		case fetchMessagesResponse([Message])
		case didTapBackButton
		case messageInput(MessageInputLogic.Action)
		case sendMessageResponse(Result<[Message], Error>)
		case didReceiveMessages(messages: [Message])
		case mockReceivedMessages
	}

	@Dependency(\.databaseClient) var databaseClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.mqtt) var mqtt

	public var body: some ReducerOf<Self> {
		Scope(state: \.messageInput, action: \.messageInput) {
			MessageInputLogic()
		}
		Reduce {
			state,
				action in
			switch action {
			case .onTask:
				return .run { [contactId = state.contactId] send in
					if let contact = try await databaseClient.fetchContact(contactId) {
						await send(.fetchContactResponse(.success(contact)))
					} else {
						await send(.fetchContactResponse(.failure(.notFound)))
					}
				} catch: { _, send in
					await send(.fetchContactResponse(.failure(.others)))
				}
			case let .fetchContactResponse(result):
				guard case let .success(contact) = result else {
					return .run { _ in
						await dismiss()
					}
				}
				state.dialogTitle = contact.name
				return .run { send in
					await send(.fetchMessages)
				}

			case .fetchMessages:
				return .run { [dialogId = state.dialogId] send in
					let messages = try await databaseClient.fetchDialogMessages(dialogId)
					await send(.fetchMessagesResponse(messages))
				}

			case let .fetchMessagesResponse(messages):
				state.messages.append(contentsOf: messages)
				return .none

			case .didTapBackButton:
				return .run { _ in
					await dismiss()
				}

			case let .messageInput(.delegate(.sendMessage(messageText))):
				return .run { [dialogId = state.dialogId, receiverId = state.contactId] send in
					@Dependency(\.uuid) var uuid
					@Dependency(\.accountClient) var accountClient
					let currentAccount = accountClient.currentAccount()!
					let message = Message(
						id: uuid(),
						dialogId: dialogId,
						senderId: currentAccount.id,
						receiverId: receiverId,
						senderName: currentAccount.name,
						content: messageText,
						timestamp: Int64(Date.now.timeIntervalSince1970)
					)
					if let messages = try await databaseClient.insertMessages([message]) {
						await send(.sendMessageResponse(.success(messages)), animation: .default)
						
						let sendMessageTopic = Constant.mqttChatTopicString(receiverId.uuidString)
						if let messageData = try? JSONEncoder().encode(message),
							 let messageContent = String(data: messageData, encoding: .utf8) {
							try await mqtt.publishMessages(
								[
									CocoaMQTT5Message(topic: sendMessageTopic, string: messageContent)
								]
							)
						}
						
					}
				} catch: { error, send in
					await send(.sendMessageResponse(.failure(error)))
				}

			case let .sendMessageResponse(result):
				switch result {
				case let .success(messages):
					state.messages.append(contentsOf: messages)
					return .none
				case .failure:
					return .none
				}

			case let .didReceiveMessages(messages):
				state.messages.append(contentsOf: messages)
				return .none

			case .mockReceivedMessages:
				return .run { [dialogId = state.dialogId, senderId = state.contactId, dialogTitle = state.dialogTitle] send in
					let quickReplies = try await databaseClient.fetchQuickReplies()
					if let mockMessageContent = quickReplies.randomElement()?.message {
						@Dependency(\.uuid) var uuid
						@Dependency(\.accountClient) var accountClient
						let currentAccount = accountClient.currentAccount()!
						let mockMessage = Message(
							id: uuid(),
							dialogId: dialogId,
							senderId: senderId,
							receiverId: currentAccount.id,
							senderName: dialogTitle,
							content: mockMessageContent,
							timestamp: Int64(Date.now.timeIntervalSince1970)
						)
						let insertedMockMessages = try await databaseClient.insertMessages([mockMessage]) ?? []
						await send(.didReceiveMessages(messages: insertedMockMessages), animation: .default)
					}
				}

			case .messageInput:
				return .none
			}
		}
	}
}

public struct MessageListView: View {
	@Bindable var store: StoreOf<MessageListLogic>
	public init(store: StoreOf<MessageListLogic>) {
		self.store = store
	}

	public var body: some View {
		VStack {
			List {
				ForEach(store.messages.reversed()) { message in
					MessageView(message: message)
						.listRowSeparator(.hidden)
						.scaleEffect(x: 1, y: -1)
				}
			}

			.listStyle(.plain)
			.padding(5)
			.scrollIndicators(.hidden)
			.scaleEffect(x: 1, y: -1)

			Spacer()
			MessageInputView(
				store: store.scope(state: \.messageInput, action: \.messageInput)
			)
		}
		.onTapGesture {
			store.send(.messageInput(.resignMessageInput))
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				HStack {
					Button {
						store.send(.didTapBackButton)
					} label: {
						Image(systemName: "chevron.backward.circle.fill")
							.resizable()
							.scaledToFill()
							.frame(width: 32, height: 32)
							.foregroundStyle(Color.primary.gradient)
					}
					Image(systemName: "person.circle.fill")
						.resizable()
						.scaledToFill()
						.frame(width: 40, height: 40)
						.foregroundStyle(Color(.gray).gradient)
					HStack {
						VStack(alignment: .leading) {
							Text(store.dialogTitle)
								.fontWeight(.bold)
								.lineLimit(1)
								.frame(maxWidth: 200, alignment: .leading)
							Text("Online")
								.fontWeight(.regular)
								.font(.subheadline)
								.lineLimit(1)
								.foregroundStyle(Color(.systemGreen).gradient)
						}
					}
				}
			}
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					store.send(.mockReceivedMessages)
				} label: {
					Image(systemName: "arrow.down.app")
						.foregroundStyle(Color.primary.gradient)
				}
			}
		}
		.navigationBarBackButtonHidden()
		.task {
			await store.send(.onTask).finish()
		}
	}
}
