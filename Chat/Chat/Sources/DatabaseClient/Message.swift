//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation
import SQLite

public enum MessageOperation: DatabaseOperation {
	case didSendMessage(message: [Message])
}

public struct Message: Identifiable, Codable, Equatable {
	
	public let id: UUID
	public let dialogId: UUID
	public let senderId: UUID
	public let receiverId: UUID
	public let senderName: String
	public let content: String
	public let timestamp: Int64
	public init(
		id: UUID,
		dialogId: UUID,
		senderId: UUID,
		receiverId: UUID,
		senderName: String,
		content: String,
		timestamp: Int64
	) {
		self.id = id
		self.dialogId = dialogId
		self.senderId = senderId
		self.receiverId = receiverId
		self.senderName = senderName
		self.content = content
		self.timestamp = timestamp
	}
	public static func==(lhs: Message, rhs: Message) -> Bool {
		lhs.id == rhs.id
	}
}
