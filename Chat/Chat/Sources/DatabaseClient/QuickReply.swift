//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/13.
//

import Foundation

public struct QuickReply: Identifiable, Equatable {
	public let id: UUID
	public let message: String
	public init(id: UUID, message: String) {
		self.id = id
		self.message = message
	}
}
