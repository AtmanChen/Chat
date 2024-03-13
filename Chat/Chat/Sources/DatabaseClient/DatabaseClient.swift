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

public protocol DatabaseOperation: Equatable {}

public struct DatabaseClient {
	public var createTables: @Sendable () async throws -> Void
	public var fetchQuickReplies: @Sendable () async throws -> [QuickReply]
	public var fetchContact: @Sendable (Int64) async throws -> Contact?
	public var fetchContacts: @Sendable () async throws -> [Contact]
	public var fetchDialog: @Sendable (Int64) async throws -> Dialog?
	public var openDialog: @Sendable (Int64) async throws -> Void
	public var isDialogExist: @Sendable (Int64) async throws -> Bool
	public var fetchDialogs: @Sendable () async throws -> [Dialog]
	public var fetchDialogMessages: @Sendable (Int64) async throws -> [Message]
	public var insertContact: @Sendable (Contact) async throws -> Contact
	public var insertContacts: @Sendable ([Contact]) async throws -> [Contact]
	public var deleteContact: @Sendable (Int64) async throws -> Void
	public var insertDialog: @Sendable (Dialog) async throws -> Dialog
	public var insertMessages: @Sendable ([Message]) async throws -> [Message]?
	public var listener: @Sendable () -> AsyncStream<any DatabaseOperation> = { .finished }

	private static let updateSubject = PassthroughSubject<any DatabaseOperation, Never>()
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

		let contactsTable = Table("contacts")
		let contactIdEx = Expression<Int64>("id")
		let contactNameEx = Expression<String>("name")

		let dialogsTable = Table("dialogs")
		let dialogPeerIdEx = Expression<Int64>("peerId")
		let dialogTitleEx = Expression<String>("title")
		let dialogLatestMessageIdEx = Expression<Int64?>("latestMessageId")

		let messagesTable = Table("messages")
		let messageIdEx = Expression<Int64>("id")
		let messageDialogIdEx = Expression<Int64>("dialogId")
		let messageSenderIdEx = Expression<Int64>("senderId")
		let messageContentEx = Expression<String>("content")
		let messageTimestampEx = Expression<Int64>("timestamp")

		let quickRepliesTable = Table("quickReplies")
		let quickReplyIdEx = Expression<Int64>("id")
		let quickReplyMessageEx = Expression<String>("message")

		return DatabaseClient(
			createTables: {
				try db.run(contactsTable.create(ifNotExists: true) { table in
					table.column(contactIdEx, primaryKey: true)
					table.column(contactNameEx)
				})

				try db.run(dialogsTable.create(ifNotExists: true) { table in
					table.column(dialogPeerIdEx, primaryKey: true)
					table.column(dialogTitleEx)
					table.column(dialogLatestMessageIdEx)
				})

				try db.run(messagesTable.create(ifNotExists: true) { table in
					table.column(messageIdEx, primaryKey: .autoincrement)
					table.column(messageDialogIdEx)
					table.column(messageSenderIdEx)
					table.column(messageContentEx)
					table.column(messageTimestampEx)
				})

				try db.run(quickRepliesTable.create(ifNotExists: true) { table in
					table.column(quickReplyIdEx, primaryKey: .autoincrement)
					table.column(quickReplyMessageEx)
				})

				// 插入默认的快速回复内容
				let defaultQuickReplies = [
					"Hello!",
					"Thank you!",
					"I agree.",
					"Could you please provide more information?",
					"I'm not sure, let me check and get back to you."
				]

				if try db.scalar(quickRepliesTable.count) == 0 {
					try db.run(quickRepliesTable.insertMany(defaultQuickReplies.map({ reply in
						[quickReplyMessageEx <- reply]
					})))
				}
			},
			fetchQuickReplies: {
				try db.prepare(quickRepliesTable.order(quickReplyIdEx.desc)).map { row in
					QuickReply(
						id: try row.get(quickReplyIdEx),
						message: try row.get(quickReplyMessageEx)
					)
				}
			},
			fetchContact: { contactId in
				let query = contactsTable.filter(contactIdEx == contactId)
				return try db.pluck(query).map { row in
					try Contact(
						id: row.get(contactIdEx),
						name: row.get(contactNameEx)
					)
				}
			},
			fetchContacts: {
				try db.prepare(contactsTable.order(contactNameEx.asc)).map { row in
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
				let query = dialogsTable
					.filter(dialogPeerIdEx == peerId)
				return try db.pluck(query).map { row in
					try Dialog(
						peerId: row.get(dialogPeerIdEx),
						title: row.get(dialogTitleEx)
					)
				}
			},
			openDialog: { peerId in
				updateSubject.send(ContactOperation.open(contactId: peerId))
			},
			isDialogExist: { peerId in
				let countQuery = dialogsTable.filter(dialogPeerIdEx == peerId).count
				let count = try db.scalar(countQuery)
				return count > 0
			},
			fetchDialogs: {
				var dialogs: [Dialog] = []
				try db.transaction {
					let dialogsQuery = dialogsTable.order(dialogLatestMessageIdEx.desc)
					for dialogRow in try db.prepare(dialogsQuery) {
						let dialogId = try dialogRow.get(dialogPeerIdEx)
						let dialogName = try dialogRow.get(dialogTitleEx)
						if let latestMessageId = try dialogRow.get(dialogLatestMessageIdEx) {
							let latestMessageQuery = messagesTable.filter(messageIdEx == latestMessageId)
							if let messageRow = try db.pluck(latestMessageQuery) {
								let dialog = try Dialog(
									peerId: dialogId,
									title: dialogName,
									latestMessageId: latestMessageId,
									latestMessage: Message(
										dialogId: dialogId,
										senderId: messageRow.get(messageSenderIdEx),
										content: messageRow.get(messageContentEx),
										timestamp: messageRow.get(messageTimestampEx)
									)
								)
								dialogs.append(dialog)
							}
						}
					}
				}
				return dialogs
			},
			fetchDialogMessages: { dialogId in
				try db.prepare("SELECT * FROM messages WHERE dialogId = ? ORDER BY timestamp ASC", dialogId).map { row in
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
				let insert = contactsTable.insert(
					contactIdEx <- contact.id,
					contactNameEx <- contact.name
				)
				try db.run(insert)
				return contact
			},
			insertContacts: { cs in
				try db.transaction {
					for contact in cs {
						let insert = contactsTable.insert(
							contactIdEx <- contact.id,
							contactNameEx <- contact.name
						)
						try db.run(insert)
					}
				}
				return cs
			},
			deleteContact: { peerId in
				try db.transaction {
					try db.run(contactsTable.filter(contactIdEx == peerId).delete())
					try db.run(dialogsTable.filter(dialogPeerIdEx == peerId).delete())
					try db.run(messagesTable.filter(messageDialogIdEx == peerId).delete())
				}
				updateSubject.send(ContactOperation.delete(contactIds: [peerId]))
			},
			insertDialog: { dialog in
				let insert = dialogsTable.insert(
					dialogPeerIdEx <- dialog.peerId,
					dialogTitleEx <- dialog.title,
					dialogLatestMessageIdEx <- dialog.latestMessageId
				)
				try db.run(insert)
				updateSubject.send(ContactOperation.open(contactId: dialog.peerId))
				return dialog
			},
			insertMessages: { messages in
				var insertedMessages: [Message] = []
				try db.transaction {
					for message in messages {
						let insert = messagesTable.insert(
							messageDialogIdEx <- message.dialogId,
							messageSenderIdEx <- message.senderId,
							messageContentEx <- message.content,
							messageTimestampEx <- message.timestamp
						)
						let rowId = try db.run(insert)
						let insertedMessage = Message(
							id: rowId,
							dialogId: message.dialogId,
							senderId: message.senderId,
							content: message.content,
							timestamp: message.timestamp
						)
						let dialogUpdate = dialogsTable
							.filter(dialogPeerIdEx == message.dialogId)
							.update(
								dialogLatestMessageIdEx <- rowId
							)
						try db.run(dialogUpdate)
						insertedMessages.append(insertedMessage)
					}
					updateSubject.send(MessageOperation.didSendMessage(message: insertedMessages))
				}
				return insertedMessages
			},
			listener: {
				AsyncStream { continuation in
					let cancellable = updateSubject.sink(receiveValue: {
						continuation.yield($0)
					})
					continuation.onTermination = { _ in
						cancellable.cancel()
					}
				}
			}
		)
	}()
}
