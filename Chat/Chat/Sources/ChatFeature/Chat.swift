import Account
import ComposableArchitecture
import DatabaseClient
import LoginFeature
import NavigationFeature
import SwiftUI
import TcaHelpers
import UserDefaultsClient

@Reducer
public struct ChatLogic {
	public init() {}
	public struct State: Equatable {
		public var account: Account?
		var view: View.State
		public init() {
			@Dependency(\.accountClient) var accountClient
			do {
				account = try accountClient.currentAccount()
				view = .navigation(NavigationLogic.State())
			} catch {
				view = .login(LoginLogic.State())
			}
		}
	}

	public enum Action {
		case onTask
		case registerNotification
		case didLoginSuccessResponse(Account)
		case registerDatabaseObservation
		case contactOperationUpdate(ContactOperation)
		case didLogout
		case view(View.Action)
	}
	
	@Dependency(\.databaseClient) var databaseClient
	
	public var body: some ReducerOf<Self> {
		core
			.onChange(of: \.account) { account, state, _ in
				withAnimation {
					if account != nil {
						state.view = .navigation(NavigationLogic.State())
					} else {
						state.view = .login(LoginLogic.State())
					}
				}
				return .none
			}
		Reduce { _, action in
			switch action {
			case .onTask:
				return .run { send in
					try await databaseClient.createTables()
					await send(.registerNotification)
					await send(.registerDatabaseObservation)
				} catch: { _, _ in
					debugPrint("Create Tables Failed...")
				}
			case .view:
				return .none
			default: return .none
			}
		}
	}
	
	@ReducerBuilder<State, Action>
	private var core: some Reducer<State, Action> {
		Scope(state: \.view.login, action: \.view.login) {
			LoginLogic()
		}
		Scope(state: \.view.navigation, action: \.view.navigation) {
			NavigationLogic()
		}
		AuthLogic()
		DatabaseObersavation()
	}
	
	@Reducer(state: .equatable)
	public enum View {
		case login(LoginLogic)
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
			case let .login(store):
				LoginView(store: store)
			case let .navigation(store):
				RootView(store: store)
			}
		}
		.task {
			await store.send(.onTask).finish()
		}
	}
}
