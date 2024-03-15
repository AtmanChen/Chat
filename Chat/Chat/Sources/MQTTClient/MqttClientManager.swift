//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/15.
//

import Foundation

public class MqttClientManager {
	public static let shared = MqttClientManager()
		
	public private(set) var mqttClient: MqttClient?
		
	private init() {}
		
	func setupMqttClient(configuration: MqttClientConfiguration) {
		if mqttClient == nil {
			debugPrint("\(configuration.clientId)")
			mqttClient = mqttClientWith(configuration: configuration)
		}
	}
	
	func getMqttClient() -> MqttClient {
		guard let client = mqttClient else {
			fatalError("MqttClient not initialized. Call setupMqttClient(configuration:) first.")
		}
		return client
	}
	
	func logou() {
		self.mqttClient = nil
	}
}
