//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation

public enum ContactOperation: DatabaseOperation {
	case open(dialogId: UUID)
	case delete(dialogIds: [UUID])
}

public enum ContactError: Error {
	case notFound
	case others
}

public struct Contact: Identifiable, Codable, Equatable {
	public let id: UUID
	public var name: String
	public init(id: UUID, name: String) {
		self.id = id
		self.name = name
	}
	public static func ==(lhs: Contact, rhs: Contact) -> Bool {
		lhs.id == rhs.id &&
		lhs.name == rhs.name
	}
	
	public static var mocks: [Contact] = [
//		Contact(id: UUID(1), name: "Bob"),
//		Contact(id: UUID(2), name: "Lambert"),
		Contact(id: UUID(3), name: "Anderson"),
//		Contact(id: UUID(4), name: "Alice")
	]
}

