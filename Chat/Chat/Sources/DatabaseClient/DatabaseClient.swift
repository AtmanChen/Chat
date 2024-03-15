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
	public var fetchContact: @Sendable (UUID) async throws -> Contact?
	public var fetchContacts: @Sendable () async throws -> [Contact]
	public var openDialogWithPeerId: @Sendable (UUID) async throws -> UUID?
	public var isDialogExist: @Sendable (UUID) async throws -> Bool
	public var fetchAllDialogs: @Sendable () async throws -> [Dialog]
	public var fetchDialogs: @Sendable ([UUID]) async throws -> [Dialog]
	public var fetchDialogMessages: @Sendable (UUID) async throws -> [Message]
	public var insertContacts: @Sendable ([Contact]) async throws -> [Contact]
	public var deleteContacts: @Sendable ([UUID]) async throws -> Void
	public var insertDialogs: @Sendable ([Dialog]) async throws -> [Dialog]
	public var insertMessages: @Sendable ([Message]) async throws -> [Message]?
	public var listener: @Sendable () -> AsyncStream<any DatabaseOperation> = { .finished }
	public var logout: @Sendable () async throws -> Void

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
		let supportDir = FileManager.SearchPathDirectory.applicationSupportDirectory
		let supportPath = try! FileManager.default.url(for: supportDir, in: .userDomainMask, appropriateFor: nil, create: true)
		let dbPath = supportPath.appendingPathComponent("db.sqlite3")
		debugPrint("\(dbPath.absoluteString)")
		let db = try! Connection(dbPath.path)

		let contactsTable = Table("contacts")
		let contactIdEx = Expression<UUID>("id")
		let contactNameEx = Expression<String>("name")

		let dialogsTable = Table("dialogs")
		let dialogIdEx = Expression<UUID>("id")
		let dialogparticipantId1Ex = Expression<UUID>("participantId1")
		let dialogparticipantId2Ex = Expression<UUID>("participantId2")
		let dialogTitleEx = Expression<String>("title")
		let dialogLatestUpdateTimestampEx = Expression<Int64>("latestUpdateTimestamp")
		let dialogLatestMessageIdEx = Expression<UUID?>("latestMessageId")

		let messagesTable = Table("messages")
		let messageIdEx = Expression<UUID>("id")
		let messageDialogIdEx = Expression<UUID>("dialogId")
		let messageSenderIdEx = Expression<UUID>("senderId")
		let messageReceiverIdEx = Expression<UUID>("receiverId")
		let messageSenderNameEx = Expression<String>("senderName")
		let messageContentEx = Expression<String>("content")
		let messageTimestampEx = Expression<Int64>("timestamp")

		let quickRepliesTable = Table("quickReplies")
		let quickReplyIdEx = Expression<UUID>("id")
		let quickReplyMessageEx = Expression<String>("message")

		return DatabaseClient(
			createTables: {
				try db.run(contactsTable.create(ifNotExists: true) { table in
					table.column(contactIdEx, primaryKey: true)
					table.column(contactNameEx)
				})

				try db.run(dialogsTable.create(ifNotExists: true) { table in
					table.column(dialogIdEx, primaryKey: true)
					table.column(dialogparticipantId1Ex)
					table.column(dialogparticipantId2Ex)
					table.column(dialogTitleEx)
					table.column(dialogLatestMessageIdEx)
					table.column(dialogLatestUpdateTimestampEx)
				})

				try db.run(messagesTable.create(ifNotExists: true) { table in
					table.column(messageIdEx, primaryKey: true)
					table.column(messageDialogIdEx)
					table.column(messageSenderIdEx)
					table.column(messageReceiverIdEx)
					table.column(messageSenderNameEx)
					table.column(messageContentEx)
					table.column(messageTimestampEx)
				})

				try db.run(quickRepliesTable.create(ifNotExists: true) { table in
					table.column(quickReplyIdEx, primaryKey: true)
					table.column(quickReplyMessageEx)
				})

				// 插入默认的快速回复内容
				let defaultQuickReplies = [
					"Hello!",
					"Thank you!",
					"I agree.",
					"Could you please provide more information?",
					"I'm not sure, let me check and get back to you.",
				]

				if try db.scalar(quickRepliesTable.count) == 0 {
					@Dependency(\.uuid) var uuid
					try db.run(
						quickRepliesTable.insertMany(
							defaultQuickReplies.map {
								reply in
								[
									quickReplyMessageEx <- reply,
									quickReplyIdEx <- uuid(),
								]
							}
						)
					)
				}
			},
			fetchQuickReplies: {
				try db.prepare(quickRepliesTable).map { row in
					try QuickReply(
						id: row.get(quickReplyIdEx),
						message: row.get(quickReplyMessageEx)
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
//			fetchDialog: { dialogId in
//				let query = dialogsTable
//					.filter(dialogPeerIdEx == peerId)
//				return try db.pluck(query).map { row in
//					try Dialog(
//						peerId: row.get(dialogPeerIdEx),
//						title: row.get(dialogTitleEx)
//					)
//				}
//			},
			openDialogWithPeerId: { peerId in
				let dialogQuery = dialogsTable.filter(dialogparticipantId1Ex == peerId || dialogparticipantId2Ex == peerId)
				let dialogIdQuery = dialogQuery.select(dialogIdEx)
				if let dialogId = try db.pluck(dialogIdQuery)?.get(dialogIdEx) {
					updateSubject.send(ContactOperation.open(dialogId: dialogId))
					return dialogId
				}
				return nil
			},
			isDialogExist: { peerId in
				let countQuery = dialogsTable.filter(dialogparticipantId1Ex == peerId || dialogparticipantId2Ex == peerId).count
				let count = try db.scalar(countQuery)
				return count > 0
			},
			fetchAllDialogs: {
				var dialogs: [Dialog] = []
				try db.transaction {
					let dialogsQuery = dialogsTable.order(dialogLatestUpdateTimestampEx.desc)
					for dialogRow in try db.prepare(dialogsQuery) {
						let dialogId = try dialogRow.get(dialogIdEx)
						let dialogName = try dialogRow.get(dialogTitleEx)
						if let latestMessageId = try dialogRow.get(dialogLatestMessageIdEx) {
							let latestMessageQuery = messagesTable.filter(messageIdEx == latestMessageId)
							if let messageRow = try db.pluck(latestMessageQuery) {
								let dialog = try Dialog(
									id: dialogId,
									participantId1: dialogRow.get(dialogparticipantId1Ex),
									participantId2: dialogRow.get(dialogparticipantId2Ex),
									title: dialogName,
									latestUpdateTimestamp: dialogRow.get(dialogLatestUpdateTimestampEx),
									latestMessageId: latestMessageId,
									latestMessage: Message(
										id: messageRow.get(messageIdEx),
										dialogId: dialogId,
										senderId: messageRow.get(messageSenderIdEx),
										receiverId: messageRow.get(messageReceiverIdEx),
										senderName: messageRow.get(messageSenderNameEx),
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
			fetchDialogs: { dialogIds in
				let query = dialogsTable.filter(dialogIds.contains(dialogIdEx))
				let rows = try db.prepare(query)
				var fetchedDialogs: [Dialog] = []
				for row in rows {
					var dialog = try Dialog(
						id: row.get(dialogIdEx),
						participantId1: row.get(dialogparticipantId1Ex),
						participantId2: row.get(dialogparticipantId2Ex),
						title: row.get(dialogTitleEx),
						latestUpdateTimestamp: row.get(dialogLatestUpdateTimestampEx),
						latestMessageId: row.get(dialogLatestMessageIdEx)
					)
					if let latestMessageId = dialog.latestMessageId {
						let messageQuery = messagesTable.filter(messageIdEx == latestMessageId)
						if let messageRow = try db.pluck(messageQuery) {
							let message = try Message(
								id: messageRow.get(messageIdEx),
								dialogId: messageRow.get(messageDialogIdEx),
								senderId: messageRow.get(messageSenderIdEx),
								receiverId: messageRow.get(messageReceiverIdEx),
								senderName: messageRow.get(messageSenderNameEx),
								content: messageRow.get(messageContentEx),
								timestamp: messageRow.get(messageTimestampEx)
							)
							dialog.latestMessage = message
						}
					}
					fetchedDialogs.append(dialog)
				}
				return fetchedDialogs
			},
			fetchDialogMessages: { dialogId in
				let query = messagesTable.filter(messageDialogIdEx == dialogId).order(messageTimestampEx.asc)
				return try db.prepare(query).map { row in
					try Message(
						id: row.get(messageIdEx),
						dialogId: row.get(messageDialogIdEx),
						senderId: row.get(messageSenderIdEx),
						receiverId: row.get(messageReceiverIdEx),
						senderName: row.get(messageSenderNameEx),
						content: row.get(messageContentEx),
						timestamp: row.get(messageTimestampEx)
					)
				}
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
			deleteContacts: { peerIds in
				var deletedDialogIds: [UUID] = []
				try db.transaction {
					for peerId in peerIds {
						try db.run(contactsTable.filter(contactIdEx == peerId).delete())
						let dialogQuery = dialogsTable.filter(dialogparticipantId1Ex == peerId || dialogparticipantId2Ex == peerId)
						let dialogIdQuery = dialogQuery.select(dialogIdEx)
						if let dialogIdRow = try? db.pluck(dialogIdQuery) {
							let dialogId = try dialogIdRow.get(dialogIdEx)
							try db.run(messagesTable.filter(messageDialogIdEx == dialogId).delete())
							try db.run(dialogQuery.delete())
							deletedDialogIds.append(dialogId)
						}
					}
				}
				updateSubject.send(ContactOperation.delete(dialogIds: deletedDialogIds))
			},
			insertDialogs: { dialogs in
				var insertedDialogs: [Dialog] = []
				try db.transaction {
					for dialog in dialogs {
						let insert = dialogsTable.insert(
							dialogIdEx <- dialog.id,
							dialogparticipantId1Ex <- dialog.participantId1,
							dialogparticipantId2Ex <- dialog.participantId2,
							dialogTitleEx <- dialog.title,
							dialogLatestUpdateTimestampEx <- dialog.latestUpdateTimestamp,
							dialogLatestMessageIdEx <- dialog.latestMessageId
						)
						try db.run(insert)
						updateSubject.send(ContactOperation.open(dialogId: dialog.id))
					}
				}
				return insertedDialogs
			},
			insertMessages: { messages in
				var insertedMessages: [Message] = []
				try db.transaction {
					for message in messages {
						let insert = messagesTable.insert(
							messageIdEx <- message.id,
							messageDialogIdEx <- message.dialogId,
							messageSenderIdEx <- message.senderId,
							messageReceiverIdEx <- message.receiverId,
							messageSenderNameEx <- message.senderName,
							messageContentEx <- message.content,
							messageTimestampEx <- message.timestamp
						)
						try db.run(insert)
						let targetDialog = try db.pluck(dialogsTable.filter(dialogIdEx == message.dialogId)).map { row in
							try Dialog(
								id: row.get(dialogIdEx),
								participantId1: row.get(dialogparticipantId1Ex),
								participantId2: row.get(dialogparticipantId2Ex),
								title: row.get(dialogTitleEx),
								latestUpdateTimestamp: row.get(dialogLatestUpdateTimestampEx)
							)
						}

						if let targetDialog {
							let dialogUpdate = dialogsTable
								.filter(dialogIdEx == message.dialogId)
								.update(
									dialogLatestMessageIdEx <- message.id
								)
							try db.run(dialogUpdate)
						} else {
							let dialogInsert = dialogsTable.insert(
								dialogIdEx <- message.dialogId,
								dialogparticipantId1Ex <- message.senderId,
								dialogparticipantId2Ex <- message.receiverId,
								dialogTitleEx <- message.senderName,
								dialogLatestUpdateTimestampEx <- message.timestamp,
								dialogLatestMessageIdEx <- message.id
							)
							try db.run(dialogInsert)
						}
						insertedMessages.append(message)
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
			},
			logout: {
				try db.transaction {
					try db.run(contactsTable.delete())
					try db.run(dialogsTable.delete())
					try db.run(messagesTable.delete())
				}
			}
		)
	}()
}
