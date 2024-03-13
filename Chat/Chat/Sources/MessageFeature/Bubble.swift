//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/11.
//

import Foundation
import SwiftUI

struct RoundedCornerShape: Shape {
	let isOutgoing: Bool
	let corners: UIRectCorner = .allCorners
	let radius: CGFloat

	init(isOutgoing: Bool, radius: CGFloat = 10) {
		self.radius = radius
		self.isOutgoing = isOutgoing
//		if self.isOutgoing {
//			self.corners = [.topLeft, .topRight, .bottomLeft]
//		} else {
//			self.corners = [.topLeft, .topRight, .bottomRight]
//		}
	}

	func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(
			roundedRect: rect,
			byRoundingCorners: corners,
			cornerRadii: CGSize(width: radius, height: radius)
		)
		return Path(path.cgPath)
	}
}
