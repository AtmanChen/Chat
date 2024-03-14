//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation

public struct Dialog: Identifiable, Codable, Equatable {
	public let id: UUID
	public let participantId1: UUID
	public let participantId2: UUID
	public var title: String
	public var latestUpdateTimestamp: Int64
	public var latestMessageId: UUID?
	public var latestMessage: Message?
	public init(
		id: UUID,
		participantId1: UUID,
		participantId2: UUID,
		title: String,
		latestUpdateTimestamp: Int64,
		latestMessageId: UUID? = nil,
		latestMessage: Message? = nil
	) {
		self.id = id
		self.participantId1 = participantId1
		self.participantId2 = participantId2
		self.title = title
		self.latestUpdateTimestamp = latestUpdateTimestamp
		self.latestMessageId = latestMessageId
		self.latestMessage = latestMessage
	}
	public static func ==(lhs: Dialog, rhs: Dialog) -> Bool {
		lhs.id == rhs.id &&
		lhs.title == rhs.title &&
		lhs.latestUpdateTimestamp == rhs.latestUpdateTimestamp &&
		lhs.latestMessageId == rhs.latestMessageId &&
		lhs.latestMessage == rhs.latestMessage
	}
}
