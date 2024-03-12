//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/11.
//

import Combine
import Dependencies
import Foundation

public struct DatabaseOperationAsyncStream<T: DatabaseOperation>: DependencyKey {
	public private(set) var stream: AsyncStream<T>
	private let continuation: AsyncStream<T>.Continuation
	public init() {
		var continuation: AsyncStream<T>.Continuation?
		self.stream = AsyncStream { cont in
			continuation = cont
		}
		self.continuation = continuation!
	}

	public func send(_ operation: T) {
		continuation.yield(operation)
	}

	public static var liveValue: DatabaseOperationAsyncStream<T> {
		DatabaseOperationAsyncStream()
	}
}

public extension DependencyValues {
	var contactOperationAsyncStream: DatabaseOperationAsyncStream<ContactOperation> {
		get { self[DatabaseOperationAsyncStream<ContactOperation>.self] }
		set { self[DatabaseOperationAsyncStream<ContactOperation>.self] = newValue }
	}
}
