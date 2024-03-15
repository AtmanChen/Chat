//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/10.
//

import ComposableArchitecture
import DatabaseClient
import Foundation
import SwiftUI
import Account

public extension Message {
	var isOutgoing: Bool {
		@Dependency(\.accountClient) var accountClient
		if let selfId = accountClient.currentAccount()?.id {
			return senderId == selfId
		}
		return false
	}

	var bubbleBackground: AnyGradient {
		isOutgoing ? Color(.darkGray).gradient : Color(.gray).gradient
	}
}

public struct MessageView: View {
	public let message: Message
	public init(message: Message) {
		self.message = message
	}

	public var body: some View {
		HStack {
			if message.isOutgoing {
				Spacer()
				bubbleContent
					.padding(.leading, 40)
					.padding(.trailing, 8)
			} else {
				bubbleContent
					.padding(.leading, 8)
					.padding(.trailing, 40)
				Spacer()
			}
		}
	}

	@ViewBuilder
	@MainActor
	private var bubbleContent: some View {
		VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
			Text(message.content)
				.foregroundStyle(Color.white.gradient)
			Text(Date(timeIntervalSince1970: Double(message.timestamp)), style: .time)
				.font(.system(size: 10, weight: .semibold))
				.foregroundStyle(Color.white.opacity(0.5).gradient)
		}
		.padding(10)
		.background(message.bubbleBackground)
		.clipShape(RoundedCornerShape(isOutgoing: message.isOutgoing))
		.frame(maxWidth: .infinity, alignment: message.isOutgoing ? .trailing : .leading)
	}
}
