//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/13.
//

import Foundation
import SwiftUI

public struct TextView: View {
	@FocusState var focused: Bool
	@Binding var text: String
	public var placeholder = "Type Here..."
	public var shouldShowPlaceholder: Bool { text.isEmpty && !focused }
	public var body: some View {
		ZStack(alignment: .topLeading) {
			if shouldShowPlaceholder {
				Text(placeholder)
					.padding(.top, 10)
					.padding(.leading, 6)
					.foregroundColor(.gray)
			}

			TextEditor(text: $text)
				.colorMultiply(shouldShowPlaceholder ? .clear : .white)
				.focused($focused)
		}
	}
}
