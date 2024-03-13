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

public struct DialogCellView: View {
	public let dialog: Dialog
	public init(dialog: Dialog) {
		self.dialog = dialog
	}
	public var body: some View {
		HStack(alignment: .center, spacing: 10) {
			Image(systemName: "person.circle.fill")
				.resizable()
				.scaledToFill()
				.foregroundStyle(Color.primary.gradient)
				.frame(width: 44, height: 44)
			VStack(alignment: .leading) {
				HStack {
					Text(dialog.title)
						.font(.body.bold())
						.lineLimit(1)
					Spacer()
					if let latestMessage = dialog.latestMessage {
						Text(
							Date(timeIntervalSince1970: Double(latestMessage.timestamp)),
							style: .time
						)
						.font(.caption)
						.foregroundStyle(Color.secondary.gradient)
					}
				}
				
				if let latestMessage = dialog.latestMessage {
					Text(latestMessage.content)
						.lineLimit(1)
						.font(.subheadline)
						.foregroundStyle(Color.secondary.gradient)
				}
			}
		}
	}
}

