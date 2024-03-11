// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Chat",
		platforms: [
			.iOS(.v17),
			.macOS(.v10_15),
		],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ChatFeature",
            targets: ["ChatFeature"]),
				.library(
						name: "DatabaseClient",
						targets: ["DatabaseClient"]),
				.library(
						name: "LoginFeature",
						targets: ["LoginFeature"]),
				.library(
						name: "NavigationFeature",
						targets: ["NavigationFeature"]),
				.library(
						name: "Account",
						targets: ["Account"]),
				.library(
						name: "UserDefaultsClient",
						targets: ["UserDefaultsClient"]),
				.library(
						name: "NotificationCenterClient",
						targets: ["NotificationCenterClient"]),
				.library(
						name: "Constant",
						targets: ["Constant"]),
				.library(
						name: "TcaHelpers",
						targets: ["TcaHelpers"]),
				.library(
						name: "SettingFeature",
						targets: ["SettingFeature"]),
				.library(
						name: "ContactFeature",
						targets: ["ContactFeature"]),
				.library(
						name: "DialogFeature",
						targets: ["DialogFeature"]),
				.library(
						name: "MessageFeature",
						targets: ["MessageFeature"]),
    ],
		dependencies: [
			.package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
			.package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.8.0")
			
		],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ChatFeature",
						dependencies: [
							"DatabaseClient",
							"LoginFeature",
							"NavigationFeature",
							"UserDefaultsClient",
							"Account",
							"NotificationCenterClient",
							"Constant",
							"TcaHelpers",
							.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
						]),
				.target(
					name: "DatabaseClient",
					dependencies: [
						.product(name: "SQLite", package: "SQLite.swift"),
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "LoginFeature",
					dependencies: [
						"DatabaseClient",
						"Account",
						"NotificationCenterClient",
						"Constant",
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "NavigationFeature",
					dependencies: [
						"ContactFeature",
						"DialogFeature",
						"SettingFeature",
						"MessageFeature",
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "Account",
					dependencies: [
						"UserDefaultsClient",
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "UserDefaultsClient",
					dependencies: [
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "NotificationCenterClient",
					dependencies: [
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "Constant",
					dependencies: [
					]
				),
				.target(
					name: "TcaHelpers",
					dependencies: [
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "ContactFeature",
					dependencies: [
						"Account",
						"UserDefaultsClient",
						"NotificationCenterClient",
						"Constant",
						"DatabaseClient",
						"MessageFeature",
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "DialogFeature",
					dependencies: [
						"Account",
						"UserDefaultsClient",
						"NotificationCenterClient",
						"Constant",
						"DatabaseClient",
						"MessageFeature",
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "SettingFeature",
					dependencies: [
						"Account",
						"UserDefaultsClient",
						"NotificationCenterClient",
						"Constant",
						"DatabaseClient",
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
				.target(
					name: "MessageFeature",
					dependencies: [
						"Account",
						"UserDefaultsClient",
						"NotificationCenterClient",
						"Constant",
						"DatabaseClient",
						.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
					]
				),
    ]
)
