//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/9.
//

import Combine
import Dependencies
import Foundation
import SQLite

protocol DatabaseOperation: Equatable {}

public struct DatabaseClient {
	public var createTables: @Sendable () async throws -> Void
	public var fetchContact: @Sendable (Int64) async throws -> Contact?
	public var fetchContacts: @Sendable () async throws -> [Contact]
	public var fetchDialog: @Sendable (Int64) async throws -> Dialog?
	public var isDialogExist: @Sendable (Int64) async throws -> Bool
	public var fetchDialogs: @Sendable () async throws -> [Dialog]
	public var fetchDialogMessages: @Sendable (Int64) async throws -> [Message]
	public var insertContact: @Sendable (Contact) async throws -> Contact
	public var insertContacts: @Sendable ([Contact]) async throws -> [Contact]
	public var insertDialog: @Sendable (Dialog) async throws -> Dialog
	public var insertMessage: @Sendable (Message) async throws -> Message
}

public extension DependencyValues {
	var databaseClient: DatabaseClient {
		get { self[DatabaseClient.self] }
		set { self[DatabaseClient.self] = newValue }
	}
}

extension DatabaseClient: DependencyKey {
	public static var liveValue: DatabaseClient = {
		let documentDir = FileManager.SearchPathDirectory.documentDirectory
		let documentPath = FileManager.default.urls(for: documentDir, in: .userDomainMask).first!
		let dbPath = documentPath.appendingPathComponent("db.sqlite3")
		debugPrint("\(dbPath.absoluteString)")
		let db = try! Connection(dbPath.path)

		let contacts = Table("contacts")
		let contactIdEx = Expression<Int64>("id")
		let contactNameEx = Expression<String>("name")

		let dialogs = Table("dialogs")
		let dialogPeerIdEx = Expression<Int64>("peerId")
		let dialogTitleEx = Expression<String>("title")
		let dialogLatestMessageIdEx = Expression<Int64?>("latestMessageId")

		let messages = Table("messages")
		let messageIdEx = Expression<Int64>("id")
		let messageDialogIdEx = Expression<Int64>("dialogId")
		let messageSenderIdEx = Expression<Int64>("senderId")
		let messageContentEx = Expression<String>("content")
		let messageTimestampEx = Expression<Int64>("timestamp")

		return DatabaseClient(
			createTables: {
				try db.run(contacts.create { table in
					table.column(contactIdEx, primaryKey: true)
					table.column(contactNameEx)
				})

				try db.run(dialogs.create { table in
					table.column(dialogPeerIdEx, primaryKey: true)
					table.column(dialogTitleEx)
					table.column(dialogLatestMessageIdEx)
				})

				try db.run(messages.create { table in
					table.column(messageIdEx, primaryKey: .autoincrement)
					table.column(messageDialogIdEx)
					table.column(messageSenderIdEx)
					table.column(messageContentEx)
					table.column(messageTimestampEx)
				})
			},
			fetchContact: { contactId in
				let query = contacts.filter(contactIdEx == contactId)
				return try db.pluck(query).map { row in
					try Contact(
						id: row.get(contactIdEx),
						name: row.get(contactNameEx)
					)
				}
			},
			fetchContacts: {
				try db.prepare(contacts.order(contactNameEx.asc)).map { row in
					try Contact(
						id: row.get(contactIdEx),
						name: row.get(contactNameEx)
					)
				}
			},
			fetchDialog: { peerId in
//				let query = """
//				SELECT
//						d.peerId,
//						d.title,
//						d.latestMessageId,
//						m.messageId,
//						m.senderId,
//						m.content,
//						m.timestamp
//				FROM
//						dialogs d
//				LEFT JOIN messages m ON d.latestMessageId = m.messageId
//				WHERE
//						d.peerId = ?
//				"""
				let query = dialogs
					.join(.leftOuter, messages, on: messages[messageIdEx] == dialogs[dialogLatestMessageIdEx])
					.filter(dialogPeerIdEx == peerId)
					.select(dialogPeerIdEx, dialogTitleEx, dialogLatestMessageIdEx, messageIdEx, messageSenderIdEx, messageContentEx, messageTimestampEx)
				if let row = try db.pluck(query) {
					let dialog = try Dialog(
						peerId: row.get(dialogPeerIdEx),
						title: row.get(dialogTitleEx),
						latestMessageId: row.get(dialogLatestMessageIdEx),
						latestMessage: row.get(dialogLatestMessageIdEx) != nil ? Message(dialogId: peerId, senderId: row.get(messageSenderIdEx), content: row.get(messageContentEx), timestamp: row.get(messageTimestampEx)) : nil
					)
				}
				return nil
			},
			isDialogExist: { peerId in
				let countQuery = dialogs.filter(dialogPeerIdEx == peerId).count
				let count = try db.scalar(countQuery)
				return count > 0
			},
			fetchDialogs: {
				try db.prepare(dialogs).map { row in
					try Dialog(
						peerId: row.get(dialogPeerIdEx),
						title: row.get(dialogTitleEx),
						latestMessageId: row.get(dialogLatestMessageIdEx),
						latestMessage: {
							if let latestMessageId = try row.get(dialogLatestMessageIdEx) {
								let messageQuery = messages.filter(messageIdEx == latestMessageId)
								return try db.pluck(messageQuery).map { row in
									try Message(
										dialogId: row.get(messageDialogIdEx),
										senderId: row.get(messageSenderIdEx),
										content: row.get(messageContentEx),
										timestamp: row.get(messageTimestampEx)
									)
								}
							}
							return nil
						}()
					)
				}
			},
			fetchDialogMessages: { dialogId in
				try db.prepare("SELECT * FROM messages WHERE dialogId = ?", dialogId).map { row in
					Message(
						id: row[0] as! Int64,
						dialogId: row[1] as! Int64,
						senderId: row[2] as! Int64,
						content: row[3] as! String,
						timestamp: row[4] as! Int64
					)
				}
			},
			insertContact: { contact in
				let insert = contacts.insert(
					contactIdEx <- contact.id,
					contactNameEx <- contact.name
				)
				try db.run(insert)
				return contact
			},
			insertContacts: { cs in
				try db.transaction {
					for contact in cs {
						let insert = contacts.insert(
							contactIdEx <- contact.id,
							contactNameEx <- contact.name
						)
						try db.run(insert)
					}
				}
				return cs
			},
			insertDialog: { dialog in
				let insert = dialogs.insert(
					dialogPeerIdEx <- dialog.peerId,
					dialogTitleEx <- dialog.title,
					dialogLatestMessageIdEx <- dialog.latestMessageId
				)
				try db.run(insert)

				Task.detached {
					@Dependency(\.contactOperationPublisher) var contactOperationPublisher
					contactOperationPublisher.send(.open(contactId: dialog.peerId))
				}
				return dialog
			},
			insertMessage: { message in
				let insert = messages.insert(
					messageDialogIdEx <- message.dialogId,
					messageSenderIdEx <- message.senderId,
					messageContentEx <- message.content,
					messageTimestampEx <- message.timestamp
				)
				try db.run(insert)
				return message
			}
		)
	}()
}
