//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Account
import NotificationCenterClient
import Constant
import DatabaseClient
import MqttClient

@Reducer
public struct SettingLogic {
	public init() {}
	
	@ObservableState
	public struct State: Equatable {
		public var account: Account?
		public init() {}
	}
	public enum Action: Equatable {
		case onTask
		case fetchAccountResponse(Account)
		case didTapLogoutButton
	}
	@Dependency(\.accountClient) var accountClient
	public func reduce(into state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .onTask:
			return .run { send in
				
				if let account = accountClient.currentAccount() {
					await send(.fetchAccountResponse(account))
				}
			}
		case let .fetchAccountResponse(account):
			state.account = account
			return .none
			
		case .didTapLogoutButton:
			return .run { send in
				try await accountClient.removeCurrentAccount()
				@Dependency(\.databaseClient) var databaseClient
				try await databaseClient.logout()
				@Dependency(\.notificationCenter) var notificationCenter
				notificationCenter.post(Constant.DidLogoutNotification, nil, nil)
				@Dependency(\.mqtt) var mqtt
				try await mqtt.disconnect()
				try await mqtt.logout()
			}
		}
	}
}

public struct SettingView: View {
	@Bindable var store: StoreOf<SettingLogic>
	public init(store: StoreOf<SettingLogic>) {
		self.store = store
	}
	public var body: some View {
		ScrollView {
			VStack {
				if let account = store.account {
					Text("\(account.name)")
						.font(.system(size: 40, weight: .black))
						.padding()
					Button {
						store.send(.didTapLogoutButton)
					} label: {
						Text("Log out")
							.font(.title.bold())
							.foregroundStyle(Color(.systemBackground).gradient)
							.padding()
							.background(
								RoundedRectangle(cornerRadius: 10)
							)
					}
				}
			}
			.task {
				await store.send(.onTask).finish()
			}
		}
	}
}
