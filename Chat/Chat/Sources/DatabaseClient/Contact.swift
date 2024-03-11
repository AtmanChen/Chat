//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation

public enum ContactOperation: DatabaseOperation {
	case open(contactId: Int64)
	case delete(contactIds: [Int64])
}

public enum ContactError: Error {
	case notFound
	case others
}

public struct Contact: Identifiable, Codable, Equatable {
	public let id: Int64
	public var name: String
	public init(id: Int64, name: String) {
		self.id = id
		self.name = name
	}
	public static func ==(lhs: Contact, rhs: Contact) -> Bool {
		lhs.id == rhs.id &&
		lhs.name == rhs.name
	}
	
	public static var mocks: [Contact] = [
		Contact(id: 1001, name: "Bob"),
		Contact(id: 1002, name: "Lambert"),
		Contact(id: 1003, name: "Anderson"),
		Contact(id: 1004, name: "Alice")
	]
	
	public static let `self` = Contact(id: 1000, name: "Huang")
}

