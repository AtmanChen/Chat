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
import SwiftUI

@Reducer
public struct MessageListLogic {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var contactId: Int64
		public var messages: IdentifiedArrayOf<Message> = []
		public var dialogTitle: String = ""
		public init(contactId: Int64) {
			self.contactId = contactId
		}
	}

	public enum Action {
		case onTask
		case fetchContactResponse(Result<Contact, ContactError>)
		case didTapBackButton
	}

	@Dependency(\.databaseClient) var databaseClient
	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
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
				return .none
				
			case .didTapBackButton:
				return .run { _ in
					await dismiss()
				}
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
				ForEach(store.messages) { message in
					MessageView(message: message)
				}
			}
			.listStyle(.plain)
			.padding(5)
			.scrollIndicators(.hidden)
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
		}
		.navigationBarBackButtonHidden()
		.task {
			await store.send(.onTask).finish()
		}
	}
}

#Preview {
	MessageListView(
		store: Store(
			initialState: MessageListLogic.State(contactId: 1000),
			reducer: MessageListLogic.init
		)
	)
}
