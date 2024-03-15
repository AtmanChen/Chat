//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation

public enum AccountError: Error {
	case notFound
	case accountAlreadyExist
}

public struct Account: Identifiable, Codable, Equatable {
	public let id: UUID
	public var name: String
	public init(id: UUID, name: String) {
		self.id = id
		self.name = name
	}

	public static func ==(lhs: Account, rhs: Account) -> Bool {
		lhs.id == rhs.id
	}
}

#if DEBUG
public extension Account {
	static let mocks: [Account] = [
		Account(id: UUID(1), name: "Benjamin"),
		Account(id: UUID(2), name: "Lambert"),
		Account(id: UUID(3), name: "Frank"),
		Account(id: UUID(4), name: "Anderson"),
		Account(id: UUID(5), name: "Bob"),
		Account(id: UUID(6), name: "White"),
		Account(id: UUID(7), name: "Alice"),
		Account(id: UUID(8), name: "Michael"),
		Account(id: UUID(9), name: "Lucy"),
	]
}
#endif
