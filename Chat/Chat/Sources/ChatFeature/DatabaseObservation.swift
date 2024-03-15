//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/12.
//

import ComposableArchitecture
import DatabaseClient
import Foundation

@Reducer
public struct DatabaseObservation {
	@Dependency(\.databaseClient.listener) var databaseListener
	public enum Cancel { case id }
	public func reduce(into state: inout ChatLogic.State, action: ChatLogic.Action) -> Effect<ChatLogic.Action> {
		
		switch action {
		case .registerDatabaseObservation:
			return .run { send in
				for await databaseOperation in databaseListener() {
					if let contactOperation = databaseOperation as? ContactOperation {
						await send(.contactOperationUpdate(contactOperation), animation: .default)
					}
					if let messageOperation = databaseOperation as? MessageOperation {
						await send(.messageOperationUpdate(messageOperation), animation: .default)
					}
				}
			}
			.cancellable(id: Cancel.id)
		case let .contactOperationUpdate(contactOperation):
			return .send(.view(.navigation(.dialog(.contactOperationUpdate(contactOperation)))))
			
		case let .messageOperationUpdate(messageOperation):
			return .run { send in
					await send(.view(.navigation(.dialog(.messageOperationUpdate(messageOperation)))))
			}

		default: return .none
		}
	}
}
