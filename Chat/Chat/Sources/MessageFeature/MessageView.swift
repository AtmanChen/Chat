//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import DatabaseClient

extension Message {
	public var isOutgoing: Bool {
		senderId == Contact.`self`.id
	}
	public var bubbleBackground: AnyGradient {
		isOutgoing ? Color(.darkGray).gradient : Color(.lightGray).gradient
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
		Text(message.content)
			.padding(10)
			.foregroundColor(.white)
			.background(message.bubbleBackground)
			.clipShape(RoundedCornerShape(isOutgoing: message.isOutgoing))
			.frame(maxWidth: .infinity, alignment: message.isOutgoing ? .trailing : .leading)
	}
}
