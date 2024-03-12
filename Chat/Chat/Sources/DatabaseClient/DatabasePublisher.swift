//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/11.
//

import Combine
import Dependencies
import Foundation

public struct ContactOperationPublisher {
	private let subject = PassthroughSubject<ContactOperation, Never>()
	private let queue = DispatchQueue(label: "com.adaspace.contactOperationUpdate")
	public func send(_ operation: ContactOperation) {
		DispatchQueue.main.async {
			debugPrint("ContactOperationPublisher -->> send: \(operation)")
			subject.send(operation)
		}
	}

	public var publisher: AnyPublisher<ContactOperation, Never> {
		subject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
	}
}

public struct ContactOperationAsyncStream {
	public private(set) var stream: AsyncStream<ContactOperation>
	private let continuation: AsyncStream<ContactOperation>.Continuation
	public init() {
		var continuation: AsyncStream<ContactOperation>.Continuation?
		self.stream = AsyncStream { cont in
			continuation = cont
		}
		self.continuation = continuation!
	}

	public func send(_ operation: ContactOperation) {
		debugPrint("ContactOperationPublisher -->> send: \(operation)")
		continuation.yield(operation)
	}
}

extension ContactOperationAsyncStream: DependencyKey {
	public static var liveValue = Self()
}

extension DependencyValues {
	public var contactOperationAsyncStream: ContactOperationAsyncStream {
		get { self[ContactOperationAsyncStream.self] }
		set { self[ContactOperationAsyncStream.self] = newValue }
	}
}

extension ContactOperationPublisher: DependencyKey {
	public static var liveValue = Self()
}

public extension DependencyValues {
	var contactOperationPublisher: ContactOperationPublisher {
		get { self[ContactOperationPublisher.self] }
		set { self[ContactOperationPublisher.self] = newValue }
	}
}
