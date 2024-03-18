//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/14.
//

import Account
import CasePaths
import CocoaMQTT
import Constant
import Dependencies
import DependenciesMacros
import Foundation

public enum MqttConnState: String, Equatable {
	case disconnected
	case connecting
	case connected
	public init(state: CocoaMQTTConnState) {
		switch state {
		case .disconnected: self = .disconnected
		case .connecting: self = .connecting
		case .connected: self = .connected
		}
	}
}


public enum MqttClientError: Error {
	case subscribeTopicsFailed(topics: [String])
}

public struct MqttClientConfiguration: Codable {
	public let clientId: String
	public let host: String
	public let port: UInt16
	public let userName: String
	public let password: String

	public init(clientId: String, host: String = Constant.mqttHost, port: UInt16 = Constant.mqttPort, userName: String = Constant.mqttUserName, password: String = Constant.mqttPassword) {
		self.clientId = clientId
		self.host = host
		self.port = port
		self.userName = userName
		self.password = password
	}
	
	public init(accountId: UUID, host: String = Constant.mqttHost, port: UInt16 = Constant.mqttPort, userName: String = Constant.mqttUserName, password: String = Constant.mqttPassword) {
		self.clientId = Constant.mqttClientID(accountId)
		self.host = host
		self.port = port
		self.userName = userName
		self.password = password
	}
}

public extension DependencyValues {
	var mqtt: MqttClient {
		get { self[MqttClient.self] }
		set { self[MqttClient.self] = newValue }
	}
}

@DependencyClient
public struct MqttClient {

	public var connect: @Sendable () async throws -> Void
	public var disconnect: @Sendable () async throws -> Void
	public var subscribeTopics: @Sendable ([(String, CocoaMQTTQoS)]) async throws -> Void
	public var unSubscribeTopics: @Sendable ([String]) async throws -> Void
	public var publishMessages: @Sendable ([CocoaMQTT5Message]) async throws -> Void
	public var logout: @Sendable () async throws -> Void
	public var delegate: @Sendable () -> AsyncStream<DelegateEvent> = { .finished }
	
	@CasePathable
	public enum DelegateEvent {
		case didConnect(ack: CocoaMQTTCONNACKReasonCode)
		case didPublishMessage(message: CocoaMQTT5Message)
		case didReceiveMessage(message: CocoaMQTT5Message)
		case didSubscribeTopics(Result<NSDictionary, MqttClientError>)
		case didUnsubscribeTopics(topics: [String])
		case didStateChangeTo(state: MqttConnState)
		case didDisConnected
	}
}

extension MqttClient: DependencyKey {
//	public static var liveValue = MqttClient.noop
//	public static func live(config: MqttClientConfiguration) -> Self {
//		MqttClientManager.shared.setupMqttClient(configuration: config)
//		return MqttClientManager.shared.getMqttClient()
//	}
	public static var liveValue: MqttClient = {
		@Dependency(\.accountClient) var accountClient
		guard let account = accountClient.currentAccount() else {
			return .noop
		}
		let mqttClientConfiguration = MqttClientConfiguration(clientId: Constant.mqttClientID(account.id))
		return mqttClientWith(configuration: mqttClientConfiguration)
	}()
}

extension MqttClient {
	public static let noop = Self(
		connect: {},
		disconnect: {},
		subscribeTopics: { _ in },
		unSubscribeTopics: { _ in },
		publishMessages: { _ in },
		logout: { },
		delegate: { .finished }
	)
}

public let defaultPublishProperies: MqttPublishProperties = {
	let publishProperties = MqttPublishProperties()
	publishProperties.contentType = "JSON"
	return publishProperties
}()

public func mqttClientWith(configuration: MqttClientConfiguration) -> MqttClient {
	debugPrint("mqtt -->> init: \(configuration.clientId)")
	let mqtt5 = CocoaMQTT5(clientID: configuration.clientId, host: configuration.host, port: configuration.port)
	mqtt5.username = configuration.userName
	mqtt5.password = configuration.password
	mqtt5.keepAlive = 60
	mqtt5.autoReconnect = true
	mqtt5.logLevel = .info
	return MqttClient(
		connect: {
			let _ = mqtt5.connect()
		},
		disconnect: {
			debugPrint("mqtt -->> disconnect")
			mqtt5.disconnect()
		},
		subscribeTopics: { topics in
			for topic in topics {
				mqtt5.subscribe(topic.0, qos: topic.1)
			}
		},
		unSubscribeTopics: { topics in
			topics.forEach { topic in
				mqtt5.unsubscribe(topic)
			}
		},
		publishMessages: { messages in
			for message in messages {
				mqtt5.publish(message, properties: defaultPublishProperies)
			}
		},
		logout: {
			
		},
		delegate: {
			AsyncStream { continuation in
				let delegate = MqttClient.Delegate(continuation: continuation)
				mqtt5.delegate = delegate
				continuation.onTermination = { _ in
					_ = delegate
				}
			}
		}
	)
}

extension MqttClient {
	fileprivate class Delegate: NSObject, CocoaMQTT5Delegate {
		let continuation: AsyncStream<DelegateEvent>.Continuation?
		init(continuation: AsyncStream<DelegateEvent>.Continuation?) {
			self.continuation = continuation
		}
		func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
			continuation?.yield(.didConnect(ack: ack))
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
			continuation?.yield(.didPublishMessage(message: message))
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {

		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
			
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
			continuation?.yield(.didReceiveMessage(message: message))
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
			if !failed.isEmpty {
				continuation?.yield(.didSubscribeTopics(.failure(.subscribeTopicsFailed(topics: failed))))
			} else {
				continuation?.yield(.didSubscribeTopics(.success(success)))
			}
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
			debugPrint("mqtt -->> didUnsubscribeTopics: \(topics)")
			continuation?.yield(.didUnsubscribeTopics(topics: topics))
			mqtt5.disconnect()
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
			debugPrint("mqtt -->> didReceiveDisconnectReasonCode: \(reasonCode)")
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
			
		}
		
		func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
			
		}
		
		func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
			
		}
		
		func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: Error?) {
			debugPrint("mqtt -->> didDisconnect")
			continuation?.yield(.didDisConnected)
		}
		
		func mqtt5(_ mqtt5: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
			continuation?.yield(.didStateChangeTo(state: MqttConnState(state: state)))
		}
	}
}

