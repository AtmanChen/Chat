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
import Combine

@Reducer
public struct DialogListLogic {
	public init() {}
	
	@ObservableState
	public struct State: Equatable {
		public var initialized = false
		public var dialogs: IdentifiedArrayOf<Dialog> = []
		public init() {}
	}

	public enum Action {
		case onTask
		case contactOperationUpdate(ContactOperation)
		case fetchDialogsResponse([Dialog])
		case didOpenDialog(Dialog)
		case didSelectDialog(Dialog)
		case delegate(Delegate)
		
		public enum Delegate {
			case didSelectDialog(Dialog)
		}
	}
	
	@Dependency(\.databaseClient) var databaseClient
	
	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .onTask:
				state.initialized = true
				return .run { send in
					let dialogs = try await databaseClient.fetchDialogs()
					await send(.fetchDialogsResponse(dialogs))
				}
				
			case let .fetchDialogsResponse(dialogs):
				state.dialogs = IdentifiedArray(uniqueElements: dialogs)
				return .none
				
			case let .didOpenDialog(dialog):
				state.dialogs.insert(dialog, at: 0)
				return .none
				
			case let .contactOperationUpdate(contactOperation):
				switch contactOperation {
				case let .open(contactId):
					if let targetDialogIndex = state.dialogs.firstIndex(where: { $0.peerId == contactId }) {
						state.dialogs.move(fromOffsets: IndexSet(integer: targetDialogIndex), toOffset: 0)
						return .none
					}
					return .run { [contactId] send in
						if let dialog = try await databaseClient.fetchDialog(contactId) {
							await send(.didOpenDialog(dialog))
						}
					}
					
				case let .delete(peerIds):
					state.dialogs.removeAll(where: { peerIds.contains($0.peerId) })
					return .none
				}
				
			case let .didSelectDialog(dialog):
				return .send(.delegate(.didSelectDialog(dialog)))
				
			case .delegate:
				return .none
			}
		}
	}
}

public struct DialogListView: View {
	@Bindable var store: StoreOf<DialogListLogic>
	public init(store: StoreOf<DialogListLogic>) {
		self.store = store
	}

	public var body: some View {
		VStack {
			List {
				ForEach(store.dialogs) { dialog in
					DialogCellView(dialog: dialog)
						.listRowBackground(Color.clear)
						.contentShape(Rectangle())
						.onTapGesture {
							store.send(.didSelectDialog(dialog))
						}
				}
			}
			.listStyle(.plain)
		}
		.task {
			if !store.initialized {
				await store.send(.onTask).finish()
			}
		}
	}
}
