import Account
import ComposableArchitecture
import DatabaseClient
import LoginFeature
import NavigationFeature
import SwiftUI
import TcaHelpers
import UserDefaultsClient
import MqttClient
import Constant
import AccountSelectionFeature

@Reducer
public struct ChatLogic {
	public init() {}
	public struct State: Equatable {
		public var account: Account?
		public var connState: MqttConnState = .connecting
		var view: View.State
		public init() {
			@Dependency(\.accountClient) var accountClient
			if accountClient.currentAccount() != nil {
				view = .navigation(NavigationLogic.State())
			} else {
				view = .accountSelection(AccountSelectionLogic.State())
			}
		}
	}

	public enum Action {
		case onTask
		case fetchAccountSuccessResponse(Account)
		case registerNotification
		case didLoginSuccessResponse(Account)
		case registerDatabaseObservation
		case registerMqtt
		case contactOperationUpdate(ContactOperation)
		case messageOperationUpdate(MessageOperation)
		case mqttEvent(MqttClient.DelegateEvent)
		case didLogout
		case view(View.Action)
	}
	
	@Dependency(\.databaseClient) var databaseClient
	
	public var body: some ReducerOf<Self> {
		core
			.onChangeAction(of: \.account) { account, state, _ in
				let accountExist = account != nil
				withAnimation {
					if accountExist {
						state.view = .navigation(NavigationLogic.State())
					} else {
						state.view = .accountSelection(AccountSelectionLogic.State())
					}
				}
				if accountExist {
					return .send(.onTask)
				}
				return .none
			}
		Reduce { state, action in
			switch action {
			case .onTask:
				return .run { send in
					try await databaseClient.createTables()
					await send(.registerNotification)
					await send(.registerDatabaseObservation)
					@Dependency(\.accountClient) var accountClient
					if let account = accountClient.currentAccount() {
						await send(.fetchAccountSuccessResponse(account))
					}
				} catch: { _, _ in
					debugPrint("Create Tables Failed...")
				}
				
			case let .fetchAccountSuccessResponse(account):
				state.account = account
				return .send(.registerMqtt)
				
			case .view:
				return .none
			default: return .none
			}
		}
	}
	
	@ReducerBuilder<State, Action>
	private var core: some Reducer<State, Action> {
		Scope(state: \.view.accountSelection, action: \.view.accountSelection) {
			AccountSelectionLogic()
		}
		Scope(state: \.view.navigation, action: \.view.navigation) {
			NavigationLogic()
		}
		AuthLogic()
		DatabaseObservation()
		Mqtt()
	}
	
	@Reducer(state: .equatable)
	public enum View {
		case accountSelection(AccountSelectionLogic)
		case navigation(NavigationLogic)
	}
}

public struct ChatView: View {
	@Bindable var store: StoreOf<ChatLogic>
	public init(store: StoreOf<ChatLogic>) {
		self.store = store
	}

	public var body: some View {
		Group {
			switch store.scope(state: \.view, action: \.view).case {
			case let .accountSelection(store):
				AccountSelectionView(store: store)
			case let .navigation(store):
				RootView(store: store)
			}
		}
		.task {
			await store.send(.onTask).finish()
		}
	}
}
