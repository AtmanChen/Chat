//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/10.
//

import Combine
import ComposableArchitecture
import DatabaseClient
import Foundation
import MessageFeature
import SwiftUI

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
		case messageOperationUpdate(MessageOperation)
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
					let dialogs = try await databaseClient.fetchAllDialogs()
					await send(.fetchDialogsResponse(dialogs))
				} catch: { error, _ in
					debugPrint("fetchDialogs: \(error.localizedDescription)")
				}
				
			case let .fetchDialogsResponse(dialogs):
				state.dialogs = IdentifiedArray(uniqueElements: dialogs)
				return .none
				
			case let .didOpenDialog(dialog):
				state.dialogs.insert(dialog, at: 0)
				return .none
				
			case let .contactOperationUpdate(contactOperation):
				switch contactOperation {
				case let .open(dialogId):
					if let targetDialogIndex = state.dialogs.firstIndex(where: { $0.id == dialogId }) {
						state.dialogs.move(fromOffsets: IndexSet(integer: targetDialogIndex), toOffset: 0)
						return .none
					}
					return .run { [dialogId] send in
						if let dialog = try await databaseClient.fetchDialogs([dialogId]).first {
							await send(.didOpenDialog(dialog))
						}
					}
					
				case let .delete(dialogIds):
					state.dialogs.removeAll(where: { dialogIds.contains($0.id) })
					return .none
				}
				
			case let .didSelectDialog(dialog):
				return .send(.delegate(.didSelectDialog(dialog)))
				
			case let .messageOperationUpdate(messageOperation):
				switch messageOperation {
				case let .didSendMessage(messages):
					guard !messages.isEmpty else {
						return .none
					}
					guard let message = messages.last else {
						return .none
					}
					let messageDialogId = message.dialogId
					if let messageDialogIndex = state.dialogs.firstIndex(where: { $0.id == messageDialogId }) {
						var targetDialog = state.dialogs[messageDialogIndex]
						targetDialog.latestMessageId = message.id
						targetDialog.latestMessage = message
						state.dialogs[messageDialogIndex] = targetDialog
						if messageDialogIndex != 0 {
							state.dialogs.move(fromOffsets: IndexSet(integer: messageDialogIndex), toOffset: 0)
						}
						return .none
					} else {
						return .run { [dialogId = message.dialogId] send in
							if let targetDialog = try await databaseClient.fetchDialogs([dialogId]).first {
								await send(.didOpenDialog(targetDialog))
							}
						}
					}
				}
				
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
				Text("Chat")
					.font(.system(size: 40, weight: .black))
					.frame(maxWidth: .infinity, alignment: .leading)
					.listRowSeparator(.hidden)
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
