// swift-tools-version:5.2

import PackageDescription

let package = Package(
	name: "Scout",
	platforms: [
		.macOS(.v10_15)
	],
	dependencies: [
		.package(name: "vapor", url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
		.package(name: "socket", url: "https://github.com/kenmueller/socket-server.git", from: "1.0.0")
	],
	targets: [
		.target(
			name: "App",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Socket", package: "socket")
			],
			swiftSettings: [
				.unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
			]
		),
		.target(name: "Run", dependencies: [.target(name: "App")])
	]
)
