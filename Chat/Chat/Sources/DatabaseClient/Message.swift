//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation
import SQLite

public enum MessageOperation: DatabaseOperation {
	case didSendMessageInDialog(dialogId: Int64)
}

public struct Message: Identifiable, Codable, Equatable {
	
	public let id: Int64
	public let dialogId: Int64
	public let senderId: Int64
	public let content: String
	public let timestamp: Int64
	public init(id: Int64 = 0, dialogId: Int64, senderId: Int64, content: String, timestamp: Int64) {
		self.id = id
		self.dialogId = dialogId
		self.senderId = senderId
		self.content = content
		self.timestamp = timestamp
	}
	public static func==(lhs: Message, rhs: Message) -> Bool {
		lhs.id == rhs.id
	}
}
