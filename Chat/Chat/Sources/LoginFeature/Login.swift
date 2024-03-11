//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/9.
//

import Account
import ComposableArchitecture
import Foundation
import SwiftUI
import NotificationCenterClient
import Constant

@Reducer
public struct LoginLogic {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public var phoneNumber: String = ""
		public var focus: Field? = .phoneNumber
		@Presents public var alert: AlertState<Action.Alert>?
		public var isLoginDisabled = true
		public var isLoading = false
		public init() {}

		public enum Field: String, Hashable {
			case phoneNumber
		}
	}

	public enum Action: BindableAction, Sendable {
		case binding(BindingAction<State>)
		case didLoginSuccess
		case didTapLoginButton
		case alert(PresentationAction<Alert>)

		@CasePathable
		public enum Alert: Equatable, Sendable {
			case confirmAccountAlreadyExisted
		}
	}

	@Dependency(\.notificationCenter) var notificationCenter
	@Dependency(\.accountClient) var accountClient
	
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce {
			state,
				action in
			switch action {

			case .didTapLoginButton:
				state.focus = nil
				state.isLoading = true
				return .run { [phoneNumber = state.phoneNumber] send in
					@Dependency(\.uuid) var uuid
					try await Task.sleep(for: .seconds(1.5))
					try await accountClient.createAccount(
						Account(
							id: uuid(),
							name: phoneNumber
						)
					)
					await send(.didLoginSuccess)
				} catch: { error, send in
					if let accountError = error as? AccountError {
						switch accountError {
						case .accountAlreadyExist:
							await send(.alert(.presented(.confirmAccountAlreadyExisted)))
						default: break
						}
					}
				}

			case .alert(.presented(.confirmAccountAlreadyExisted)):
				state.alert = AlertState {
					TextState("This account is already existed")
				} actions: {
					ButtonState(role: .destructive, action: .send(.confirmAccountAlreadyExisted)) {
						TextState("OK")
					}
				}
				return .none

			case .didLoginSuccess:
				state.isLoading = false
				state.focus = nil
				return .run { send in
					let currentAccount = try accountClient.currentAccount()
					notificationCenter.post(
						Constant.DidLoginNotification,
						nil,
						["account": currentAccount]
					)
				} catch: { error, send in
					print("Get current account error")
				}

			case .binding(\.phoneNumber):
				state.isLoginDisabled = state.phoneNumber.count != 11
				return .none
				
			case .binding:
				return .none
			case .alert:
				return .none
			}
		}
	}
}

public struct LoginView: View {
	@Bindable var store: StoreOf<LoginLogic>
	@FocusState var focusedField: LoginLogic.State.Field?
	public init(store: StoreOf<LoginLogic>) {
		self.store = store
	}

	public var body: some View {
		GeometryReader { geometry in
			ScrollView(.vertical) {
				VStack {
					Text("Chat")
						.font(.system(size: 70, weight: .bold))
					TextField("PhoneNumer", text: $store.phoneNumber)
						.focused($focusedField, equals: .phoneNumber)
						.keyboardType(.numberPad)
						.padding(.vertical, 12)
						.padding(.horizontal, 15)
						.background(Color(.systemGray6).shadow(.drop(color: .white.opacity(0.25), radius: 2)), in: .rect(cornerRadius: 10))
						.padding(.bottom, 36)
						.tint(.primary)
					if store.isLoading {
						ProgressView()
							.padding()
					}
					Button {
						store.send(.didTapLoginButton)
					} label: {
						Text("Login")
							.font(.system(size: 24, weight: .semibold))
							.fontWeight(.semibold)
							.tint(.white)
							.padding(.vertical, 12)
							.frame(maxWidth: .infinity, alignment: .center)
							.background(Color("themeBackground", bundle: .main))
							.cornerRadius(10)
					}
					.disabled(store.isLoginDisabled)
				}
				.padding()
				.frame(width: geometry.size.width, height: geometry.size.height)
				.position(x: geometry.size.width / 2, y: geometry.size.height / 3)
			}
			.contentShape(Rectangle())
			.onTapGesture {
				focusedField = nil
			}
			.bind($store.focus, to: $focusedField)
		}
	}
}

#Preview {
	LoginView(
		store: Store(
			initialState: LoginLogic.State(),
			reducer: LoginLogic.init
		)
	)
}
