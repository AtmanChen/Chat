//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/14.
//

import Account
import ComposableArchitecture
import Constant
import Foundation
import MqttClient
import CocoaMQTT
import DatabaseClient



@Reducer
public struct Mqtt {
	public enum Cancel { case id }
	@Dependency(\.mqtt) var mqtt
	public func reduce(into state: inout ChatLogic.State, action: ChatLogic.Action) -> Effect<ChatLogic.Action> {
		
		switch action {
		case .registerMqtt:
			guard state.account != nil else {
				return .none
			}
			return .run { send in
				try await mqtt.connect()
				for await event in mqtt.delegate() {
					await send(.mqttEvent(event))
				}
			}
			.cancellable(id: Cancel.id)
		case let .mqttEvent(event):
			switch event {
			case let .didStateChangeTo(connState):
				state.connState = connState
				return .run { send in
					await send(.view(.navigation(.mqttConnState(connState))), animation: .default)
					await send(.view(.navigation(.dialog(.updateConnState(connState)))), animation: .default)
				}
			case .didDisConnected:
				state.connState = .disconnected
				return .run { send in
					await send(.view(.navigation(.mqttConnState(.disconnected))), animation: .default)
					await send(.view(.navigation(.dialog(.updateConnState(.disconnected)))), animation: .default)
				}
				
			case let .didConnect(ack):
				return .run { [accountId = state.account?.id]send in
					if case .success = ack,
							let accountId {
						try await mqtt.subscribeTopics(
							[
								(Constant.mqttChatTopicString(accountId.uuidString), .qos1)
							]
						)
					}
				}
				
			case let .didReceiveMessage(mqttMessage):
				if let messageData = mqttMessage.string?.data(using: .utf8),
					 let message = try? JSONDecoder().decode(Message.self, from: messageData) {
					return .run { send in
						@Dependency(\.databaseClient) var databaseClient
						if let insertedMessages = try await databaseClient.insertMessages([message]) {
							await send(.view(.navigation(.didReceiveMessageOperation(.didSendMessage(message: insertedMessages)))))
						}
					}
				}
				return .none
				
			default: return .none
//			case let .didConnect(ack):
//			case let .didPublishMessage(message):
//			case let .didReceiveMessage(message):
//			case let .didSubscribeTopics(result):
//			case let .didUnsubscribeTopics(topics):
			}
		default: return .none
		}
	}
}
