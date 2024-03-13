//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/13.
//

import ComposableArchitecture
import DatabaseClient
import Foundation
import SwiftUI

@Reducer
public struct MessageInputLogic {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var messageText: String = ""
		public var sendMessageButtonDisabled = true
		public var focus: Field?
		public var shouldDisplayPlaceholder = true
		public var showQuickReplies = false
		public var quickReplies: [QuickReply] = []
		public init() {}
		public enum Field: Hashable {
			case messageInput
		}
	}

	public enum Action: BindableAction {
		case onTask
		case binding(BindingAction<State>)
		case didTapSendMessageButton
		case messageInputFocus
		case resignMessageInput
		case toggleQuickRepliesMenu
		case fetchQuickRepliesResponse(quickReplies: [QuickReply])
		case didTapQuickReply(message: String)
		case delegate(Delegate)

		public enum Delegate {
			case sendMessage(String)
		}
	}

	@Dependency(\.databaseClient.fetchQuickReplies) var fetchQuickReplies

	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .didTapSendMessageButton:
				guard !state.messageText.isEmpty else {
					return .none
				}
				let messageText = state.messageText
				state.messageText = ""
				return .send(.delegate(.sendMessage(messageText)))

			case .binding(\.focus):
				if state.focus != nil {
					state.shouldDisplayPlaceholder = false
				} else {
					state.shouldDisplayPlaceholder = state.messageText.isEmpty
				}
				return .none

			case .binding(\.messageText):
				state.sendMessageButtonDisabled = state.messageText.isEmpty
				return .none

			case .binding:
				return .none

			case .onTask:
				return .run { send in
					let quickReplies = try await fetchQuickReplies()
					await send(.fetchQuickRepliesResponse(quickReplies: quickReplies))
				}

			case .messageInputFocus:
				if state.focus == nil {
					state.focus = .messageInput
					state.shouldDisplayPlaceholder = false
				}
				return .none

			case .resignMessageInput:
				if state.focus != nil {
					state.focus = nil
					state.shouldDisplayPlaceholder = state.messageText.isEmpty
				}
				return .none

			case .toggleQuickRepliesMenu:
				return .none

			case let .fetchQuickRepliesResponse(quickReplies):
				state.quickReplies = quickReplies
				return .none

			case let .didTapQuickReply(message):
				if state.focus != nil {
					state.focus = nil
					state.shouldDisplayPlaceholder = state.messageText.isEmpty
				}
				return .send(.delegate(.sendMessage(message)))

			case .delegate:
				return .none
			}
		}
	}
}

public struct MessageInputView: View {
	@Bindable var store: StoreOf<MessageInputLogic>
	@FocusState var focusedField: MessageInputLogic.State.Field?
	public init(store: StoreOf<MessageInputLogic>) {
		self.store = store
	}

	public var body: some View {
		HStack {
			ZStack(alignment: .topLeading) {
				if store.shouldDisplayPlaceholder {
					Text("Type here...")
						.padding(.top, 10)
						.padding(.leading, 6)
						.foregroundColor(.gray)
						.onTapGesture {
							store.send(.messageInputFocus)
						}
				}

				TextEditor(text: $store.messageText)
					.colorMultiply(store.shouldDisplayPlaceholder ? .clear : .white)
					.tint(Color.primary)
					.focused($focusedField, equals: .messageInput)
					.overlay(alignment: .trailing) {
						Menu {
							ForEach(store.quickReplies) { quickReply in
								Button {
									store.send(.didTapQuickReply(message: quickReply.message))
								} label: {
									Text(quickReply.message)
								}
							}
						} label: {
							Image(systemName: "square.and.pencil.circle")
								.resizable()
								.scaledToFill()
								.foregroundStyle(Color.primary.gradient)
								.frame(width: 28, height: 28)
						}
					}
			}
			.frame(minHeight: 44, maxHeight: 100)
			.fixedSize(horizontal: false, vertical: true)
			.padding(.horizontal)
			.background(Color(.systemGray6).gradient)
			.clipShape(Capsule())
			.scrollContentBackground(.hidden)

			Button {
				store.send(.didTapSendMessageButton)
			} label: {
				Image(systemName: "paperplane.circle.fill")
					.resizable()
					.scaledToFit()
					.frame(width: 40, height: 40)
					.foregroundStyle(store.sendMessageButtonDisabled ? Color.secondary.gradient : Color.primary.gradient)
			}
			.disabled(store.sendMessageButtonDisabled)
		}
		.padding()
		.bind($store.focus, to: $focusedField)
		.task {
			await store.send(.onTask).finish()
		}
	}
}
