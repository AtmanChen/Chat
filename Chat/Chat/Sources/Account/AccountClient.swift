//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/9.
//

import Foundation
import Dependencies
import UserDefaultsClient
import DependenciesMacros

@DependencyClient
public struct AccountClient {
	public var mocks: @Sendable () throws -> [Account]
	public var currentAccount: @Sendable () -> Account?
	public var createAccount: @Sendable (Account) async throws -> Void
	public var removeCurrentAccount: @Sendable () async throws -> Void
}

extension AccountClient: DependencyKey {
	public static var liveValue: AccountClient = Self(
		mocks: {
			Account.mocks
		},
		currentAccount: {
			@Dependency(\.userDefaults) var userDefaults
			if let accountName = userDefaults.stringForKey("currentAccountName"),
				 let accountId = userDefaults.stringForKey("currentAccountId"),
				 let accountUUID = UUID(uuidString: accountId) {
				return Account(id: accountUUID, name: accountName)
			}
			return nil
		},
		createAccount: { account in
			@Dependency(\.userDefaults) var userDefaults
			await userDefaults.setString(account.id.uuidString, "currentAccountId")
			await userDefaults.setString(account.name, "currentAccountName")
		},
		removeCurrentAccount: {
			@Dependency(\.userDefaults) var userDefaults
			await userDefaults.remove("currentAccountId")
			await userDefaults.remove("currentAccountName")
		}
	)
}

extension DependencyValues {
	public var accountClient: AccountClient {
		get { self[AccountClient.self] }
		set { self[AccountClient.self] = newValue }
	}
}
