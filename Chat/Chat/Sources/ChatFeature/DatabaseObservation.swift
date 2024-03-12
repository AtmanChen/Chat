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
	@Dependency(\.contactOperationAsyncStream) var contactOperationAsyncStream
	@Dependency(\.databaseClient) var databaseClient

	public func reduce(into state: inout ChatLogic.State, action: ChatLogic.Action) -> Effect<ChatLogic.Action> {
		switch action {
		case .registerDatabaseObservation:
			enum Cancel { case id }
			return .run { send in
				debugPrint("ContactOperationPublisher -->> register")
				for await contactOperation in contactOperationAsyncStream.stream {
					debugPrint("ContactOperationPublisher -->> received: \(contactOperation)")
					await send(.contactOperationUpdate(contactOperation), animation: .default)
				}
			}
			.cancellable(id: Cancel.id)
		case let .contactOperationUpdate(contactOperation):
			return .send(.view(.navigation(.dialog(.contactOperationUpdate(contactOperation)))))

		default: return .none
		}
	}
}
