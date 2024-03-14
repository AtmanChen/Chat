//
//  File.swift
//  
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import DatabaseClient

@Reducer
public struct ContactRowLogic {
	public init() {}
	
	@ObservableState
	public struct State: Equatable, Identifiable {
		public var contact: Contact
		public init(contact: Contact) {
			self.contact = contact
		}
		public var id: UUID {
			contact.id
		}
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

public struct ContactRow: View {
	@Bindable var store: StoreOf<ContactRowLogic>
	public init(store: StoreOf<ContactRowLogic>) {
		self.store = store
	}
	public var body: some View {
		HStack {
			Image(systemName: "person.circle.fill")
				.resizable()
				.scaledToFill()
				.frame(width: 44, height: 44)
				.foregroundStyle(Color(.systemGray).gradient)
			Text("\(store.contact.name)")
				.font(.body)
				.fontWeight(.bold)
				.foregroundStyle(Color(.systemGray).gradient)
		}
	}
}

