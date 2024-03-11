//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/11.
//

import Foundation
import Combine
import Dependencies

public struct ContactOperationPublisher {
	private let subject = PassthroughSubject<ContactOperation, Never>()
	public func send(_ operation: ContactOperation) {
		subject.send(operation)
	}
	public var publisher: AnyPublisher<ContactOperation, Never> {
		subject.eraseToAnyPublisher()
	}
}

extension ContactOperationPublisher: DependencyKey {
	public static var liveValue = Self()
}

extension DependencyValues {
	public var contactOperationPublisher: ContactOperationPublisher {
		get { self[ContactOperationPublisher.self] }
		set { self[ContactOperationPublisher.self] = newValue }
	}
}
