//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/12.
//

import ComposableArchitecture
import DatabaseClient

@Reducer
public struct DatabaseObersavation {
	@Dependency(\.contactOperationAsyncStream) var contactOperationAsyncStream
	public func reduce(into state: inout ChatLogic.State, action: ChatLogic.Action) -> Effect<ChatLogic.Action> {
		switch action {
		case .registerDatabaseObservation:
			enum Cancel { case id }
			return .run { send in
				debugPrint("ContactOperationPublisher -->> register")
				for await contactOperation in contactOperationAsyncStream.stream {
					debugPrint("ContactOperationPublisher -->> received: \(contactOperation)")
					await send(.contactOperationUpdate(contactOperation))
				}
			}
			.cancellable(id: Cancel.id)
			
		case let .contactOperationUpdate(contactOperation):
			return .run { send in
				await send(.view(.navigation(.dialog(.contactOperationUpdate(contactOperation)))))
			}
		default: return .none
		}
	}
}
