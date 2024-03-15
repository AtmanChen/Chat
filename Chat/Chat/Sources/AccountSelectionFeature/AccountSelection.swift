//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/15.
//

import Foundation
import Account
import ComposableArchitecture
import SwiftUI
import NotificationCenterClient
import Constant

@Reducer
public struct AccountSelectionLogic {
	public init() {}
	
	@ObservableState
	public struct State: Equatable {
		public var accounts: [Account] = []
		public var selectedAccount: Account?
		@Presents public var alert: AlertState<Action.Alert>?
		public init() {}
	}
	public enum Action: Equatable {
		case alert(PresentationAction<Alert>)
		case onTask
		case accountsResponse([Account])
		case didTapAccount(Account)
		
		public enum Alert: Equatable {
			case confirmSelection(Account)
			case cancelSelection
		}
	}
	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .onTask:
				return .run { send in
					@Dependency(\.accountClient) var accountClient
					await send(.accountsResponse(try accountClient.mocks()))
				}
			case let .accountsResponse(accounts):
				state.accounts = accounts
				return .none
				
			case let .didTapAccount(account):
				state.alert = AlertState {
					TextState("确定选择该账号吗?")
				} actions: {
					ButtonState(role: .cancel, action: .cancelSelection) {
						TextState("取消")
					}
					ButtonState(action: .confirmSelection(account)) {
						TextState("确定")
					}
				}
				return .none
				
			case .alert(.presented(.cancelSelection)):
				state.alert = nil
				return .none
				
			case let .alert(.presented(.confirmSelection(account))):
				state.alert = nil
				state.selectedAccount = account
				return .run { send in
					try await Task.sleep(for: .seconds(1.5))
					@Dependency(\.accountClient) var accountClient
					try await accountClient.createAccount(account)
					@Dependency(\.notificationCenter) var notificationCenter
					notificationCenter.post(
						Constant.DidLoginNotification,
						nil,
						["account": account]
					)
				}
				
			default: return .none
			}
			
		}
		.ifLet(\.$alert, action: \.alert)
	}
}

public struct AccountSelectionView: View {
	@Bindable var store: StoreOf<AccountSelectionLogic>
	let columns = [GridItem(.flexible(minimum: 120, maximum: 120)), GridItem(.flexible(minimum: 120, maximum: 120)), GridItem(.flexible(minimum: 120, maximum: 120))]
	public init(store: StoreOf<AccountSelectionLogic>) {
		self.store = store
	}
	public var body: some View {
			VStack {
				Text("Chat")
					.font(.system(size: 56, weight: .black))
					.padding()
				Text("Choose an account to get started.")
					.font(.body.bold())
					.padding()
					
				LazyVGrid(columns: columns) {
					ForEach (store.accounts) { account in
						Text(account.name)
							.font(.body.bold())
							.foregroundStyle(Color(.systemBackground).gradient)
							.padding()
							.background(
								Capsule()
									.fill(Color.primary)
							)
							.onTapGesture {
								store.send(.didTapAccount(account))
							}
					}
				}
				.padding(.top, 36)
				
				Spacer()
				if let selectedAccount = store.selectedAccount {
					VStack {
						ProgressView()
							.progressViewStyle(.circular)
						Text("\(selectedAccount.name)")
							.font(.largeTitle.bold())
							.foregroundStyle(Color.primary.gradient)
					}
			}
		}
		.alert(store: store.scope(state: \.$alert, action: \.alert))
		.task {
			await store.send(.onTask).finish()
		}
	}
}

#Preview {
	AccountSelectionView(
		store: Store(
			initialState: AccountSelectionLogic.State(),
			reducer: AccountSelectionLogic.init
		)
	)
}
