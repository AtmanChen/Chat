//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/10.
//

import ComposableArchitecture
import DatabaseClient
import Foundation
import MessageFeature
import SwiftUI

@Reducer
public struct ContactListLogic {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var contacts: IdentifiedArrayOf<ContactRowLogic.State> = []
		public var isLoading = false
		public var initialized = false
		public var selectedContactId: Int64?
		public init() {}
	}

	public enum Action {
		case onTask
		case contacts(IdentifiedActionOf<ContactRowLogic>)
		case fetchContactsFromDBResponse([Contact])
		case didTapAddContactButton
		case addContactResponse(Result<Contact, Error>)
		case didSelectContact(Contact)
		case delegate(Delegate)

		public enum Delegate {
			case didSelectContact(Int64)
		}
	}

	@Dependency(\.databaseClient) var databaseClient

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .onTask:
				return .run { send in
					var contacts = try await databaseClient.fetchContacts()
					if contacts.isEmpty {
						try contacts.append(contentsOf: await databaseClient.insertContacts(Contact.mocks))
					}
					await send(.fetchContactsFromDBResponse(contacts))
				} catch: { _, _ in
					debugPrint("Fetch Contacts failed...")
				}

			case let .fetchContactsFromDBResponse(contacts):
				state.initialized = true
				state.contacts = IdentifiedArray(uniqueElements: contacts.map(ContactRowLogic.State.init(contact:)))
				return .none

			case .didTapAddContactButton:
				state.isLoading = true
				return .run { [ids = state.contacts.ids] send in
					@Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
					let maxContactId = ids.max()!
					let contactId: Int64 = withRandomNumberGenerator { _ in
						Int64.random(in: maxContactId ..< 9999)
					}
					let (data, _) = try await URLSession.shared.data(from: URL(string: "https://randomuser.me/api")!)
					let randomResponse = try JSONDecoder().decode(Response.self, from: data)
					if let name = randomResponse.results.first?.name.description {
						let contact = Contact(id: contactId, name: name)
						_ = try await databaseClient.insertContact(contact)
						await send(.addContactResponse(.success(contact)), animation: .default)
					}
				} catch: { error, send in
					debugPrint("Add random contact error: \(error.localizedDescription)")
					await send(.addContactResponse(.failure(error)))
				}

			case let .addContactResponse(result):
				state.isLoading = false
				switch result {
				case let .success(contact):
					if let index = state.contacts.firstIndex(where: { $0.contact.name > contact.name }) {
						state.contacts.insert(ContactRowLogic.State(contact: contact), at: index)
					} else {
						state.contacts.append(ContactRowLogic.State(contact: contact))
					}
				default: break
				}
				return .none

			case .contacts:
				return .none

			case let .didSelectContact(contact):
				return .run { [peerId = contact.id, peerName = contact.name] send in
					let isDialogExist = try await databaseClient.isDialogExist(peerId)
					if !isDialogExist {
						let insertDialog = Dialog(peerId: peerId, title: peerName)
						let _ = try await databaseClient.insertDialog(insertDialog)
					}
					await send(.delegate(.didSelectContact(peerId)))
				}

			default: return .none
			}
		}
	}
}

public struct ContactListView: View {
	@Bindable var store: StoreOf<ContactListLogic>
	public init(store: StoreOf<ContactListLogic>) {
		self.store = store
	}

	public var body: some View {
		ZStack(alignment: .bottomTrailing) {
			List {
				ForEach(store.scope(state: \.contacts, action: \.contacts)) { contactStore in
					ContactRow(store: contactStore)
						.contentShape(Rectangle())
						.onTapGesture {
							store.send(.didSelectContact(contactStore.contact))
						}
				}
			}
			.listStyle(.plain)
			.task {
				if !store.initialized {
					await store.send(.onTask).finish()
				}
			}
			Button {
				store.send(.didTapAddContactButton)
			} label: {
				ZStack {
					if store.isLoading {
						ProgressView()
							.progressViewStyle(.circular)
							.foregroundStyle(.white)
					} else {
						Image(systemName: "plus")
							.resizable()
							.scaledToFill()
							.foregroundStyle(.background)
					}
				}
				.padding(8)
				.background {
					Circle()
						.fill(store.isLoading ? Color(.systemGray6).gradient : Color.primary.gradient)
				}
				.frame(width: 44, height: 44)
			}
			.disabled(store.isLoading)
			.padding()
		}
		.navigationTitle("Contacts")
		.navigationBarTitleDisplayMode(.large)
	}
}

#Preview {
	ContactListView(
		store: Store(
			initialState: ContactListLogic.State(),
			reducer: ContactListLogic.init
		)
	)
}
