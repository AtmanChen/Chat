//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
public struct SettingLogic {
	public init() {}
	
	@ObservableState
	public struct State: Equatable {
		public init() {}
	}
	public enum Action: Equatable {
		
	}
	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
				
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
		/*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
	}
}
