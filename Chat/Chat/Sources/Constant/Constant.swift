//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation

public enum Constant {
	public static let DidLoginNotification = Notification.Name(rawValue: "DidLoginNotification")
	public static let DidLogoutNotification = Notification.Name(rawValue: "DidLogoutNotification")
	public static let mqttHost = "broker.emqx.io"
	public static let mqttPort: UInt16 = 1883
	public static let mqttUserName = String(ProcessInfo().processIdentifier)
	public static let mqttPassword = "com.adaspace.chat"
	public static func mqttClientID(_ accountId: UUID) -> String {
		"AdaSpace-Chat-\(accountId.uuidString)"
	}
	public static func mqttChatTopicString(_ id: String) -> String {
		"adaSpace/chat/client/\(id)"
	}
}
