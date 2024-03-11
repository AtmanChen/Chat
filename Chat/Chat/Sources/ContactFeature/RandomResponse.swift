//
//  File.swift
//
//
//  Created by Anderson  on 2024/3/10.
//

import Foundation

struct Response: Codable {
	let results: [Person]
	let info: Info
}

struct Person: Codable {
	let gender: String
	let name: Name
	let location: Location
	let email: String
	let login: Login
	let dob: Dob
	let registered: Registered
	let phone: String
	let cell: String
	let id: ID
	let picture: Picture
	let nat: String
}

struct Name: Codable, CustomStringConvertible {
	let title: String
	let first: String
	let last: String
	
	var description: String {
		"\(first) \(last)"
	}
}

struct Location: Codable {
	let street: Street
	let city: String
	let state: String
	let country: String
	let postcode: Int
	let coordinates: Coordinates
	let timezone: Timezone
}

struct Street: Codable {
	let number: Int
	let name: String
}

struct Coordinates: Codable {
	let latitude: String
	let longitude: String
}

struct Timezone: Codable {
	let offset: String
	let description: String
}

struct Login: Codable {
	let uuid: String
	let username: String
	let password: String
	let salt: String
	let md5: String
	let sha1: String
	let sha256: String
}

struct Dob: Codable {
	let date: String
	let age: Int
}

struct Registered: Codable {
	let date: String
	let age: Int
}

struct ID: Codable {
	let name: String
	let value: String?
}

struct Picture: Codable {
	let large: String
	let medium: String
	let thumbnail: String
}

struct Info: Codable {
	let seed: String
	let results: Int
	let page: Int
	let version: String
}
