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
