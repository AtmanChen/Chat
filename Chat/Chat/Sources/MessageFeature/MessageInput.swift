//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/13.
//

import ComposableArchitecture
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
		case delegate(Delegate)

		public enum Delegate {
			case sendMessage(String)
		}
	}

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
				return .none

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
					.focused($focusedField, equals: .messageInput)
			}
			.frame(minHeight: 40, maxHeight: 100)
			.fixedSize(horizontal: false, vertical: true)
			.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
			.background(Color(.systemGray6).gradient)
			.clipShape(RoundedRectangle(cornerRadius: 20))
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
	}
}
