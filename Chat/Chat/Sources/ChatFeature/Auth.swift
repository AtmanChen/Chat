//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation
import ComposableArchitecture
import NotificationCenterClient
import Constant
import Account

@Reducer
public struct AuthLogic {
	@Dependency(\.notificationCenter) var notificationCenter
	
	public func reduce(into state: inout ChatLogic.State, action: ChatLogic.Action) -> Effect<ChatLogic.Action> {
		switch action {
		case .registerNotification:
			enum Cancel { case id }
			return .run { send in
				for await notification in notificationCenter.observe([Constant.DidLoginNotification, Constant.DidLogoutNotification]) {
					if notification.name == Constant.DidLoginNotification {
						if let userInfo = notification.userInfo as? [String: Any],
							 let account = userInfo["account"] as? Account {
							await send(.didLoginSuccessResponse(account))
						}
					}
					if notification.name == Constant.DidLogoutNotification {
						await send(.didLogout)
					}
				}
			}
			.cancellable(id: Cancel.id)
			
		case .didLogout:
			state.account = nil
			return .none
			
		case let .didLoginSuccessResponse(account):
			state.account = account
			return .none
			
		default: return .none
		}
	}
}
