//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation

public struct Dialog: Identifiable, Codable, Equatable {
	public let peerId: Int64
	public var title: String
	public var latestMessageId: Int64?
	public var latestMessage: Message?
	public init(peerId: Int64, title: String, latestMessageId: Int64? = nil, latestMessage: Message? = nil) {
		self.peerId = peerId
		self.title = title
		self.latestMessageId = latestMessageId
		self.latestMessage = latestMessage
	}
	public static func ==(lhs: Dialog, rhs: Dialog) -> Bool {
		lhs.peerId == rhs.peerId &&
		lhs.title == rhs.title &&
		lhs.latestMessageId == rhs.latestMessageId &&
		lhs.latestMessage == rhs.latestMessage
	}
	public var id: Int64 {
		peerId
	}
}
