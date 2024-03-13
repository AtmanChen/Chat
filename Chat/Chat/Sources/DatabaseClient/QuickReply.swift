//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/13.
//

import Foundation

public struct QuickReply: Identifiable, Equatable {
	public let id: Int64
	public let message: String
	public init(id: Int64, message: String) {
		self.id = id
		self.message = message
	}
}
