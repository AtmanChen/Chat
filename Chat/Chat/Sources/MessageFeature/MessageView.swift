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
		isOutgoing ? Color.primary.gradient : Color(.darkGray).gradient
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
					.background(.clear)
			}
			bubbleContent
				.background(.clear)
			Spacer()
		}
	}
	
	@ViewBuilder
	@MainActor
	private var bubbleContent: some View {
		GeometryReader { geometry in
			Text(message.content)
				.padding(10)
				.foregroundColor(.white)
				.background(message.bubbleBackground)
				.clipShape(RoundedCornerShape(isOutgoing: message.isOutgoing))
				.frame(maxWidth: geometry.size.width * 0.7, alignment: message.isOutgoing ? .trailing : .leading)
		}
	}
}
