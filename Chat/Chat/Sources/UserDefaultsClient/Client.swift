//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation
import Dependencies
import DependenciesMacros

extension DependencyValues {
	public var userDefaults: UserDefaultsClient {
		get { self[UserDefaultsClient.self] }
		set { self[UserDefaultsClient.self] = newValue }
	}
}

@DependencyClient
public struct UserDefaultsClient {
	public var boolForKey: @Sendable (String) -> Bool = { _ in false }
	public var dataForKey: @Sendable (String) -> Data?
	public var doubleForKey: @Sendable (String) -> Double = { _ in 0 }
	public var integerForKey: @Sendable (String) -> Int = { _ in 0 }
	public var stringForKey: @Sendable (String) -> String?
	public var remove: @Sendable (String) async -> Void
	public var setBool: @Sendable (Bool, String) async -> Void
	public var setData: @Sendable (Data?, String) async -> Void
	public var setDouble: @Sendable (Double, String) async -> Void
	public var setInteger: @Sendable (Int, String) async -> Void
	public var setString: @Sendable (String, String) async -> Void
}

extension UserDefaultsClient: DependencyKey {
	public static let liveValue: Self = {
		let defaults = { UserDefaults.standard }
		return Self(
			boolForKey: { defaults().bool(forKey: $0) },
			dataForKey: { defaults().data(forKey: $0) },
			doubleForKey: { defaults().double(forKey: $0) },
			integerForKey: { defaults().integer(forKey: $0) },
			stringForKey: { defaults().string(forKey: $0) },
			remove: { defaults().removeObject(forKey: $0) },
			setBool: { defaults().set($0, forKey: $1) },
			setData: { defaults().set($0, forKey: $1) },
			setDouble: { defaults().set($0, forKey: $1) },
			setInteger: { defaults().set($0, forKey: $1) },
			setString: { defaults().set($0, forKey: $1) }
		)
	}()
}
