// swift-tools-version: 6.3

import PackageDescription

let package = Package(
	name: "App",
	platforms: [
		.macOS(.v26),
	],
	products: [
		.library(
			name: "App",
			targets: ["App"],
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/pointfreeco/swift-composable-architecture",
			from: "1.25.1",
		),
		.package(
			url: "https://github.com/pointfreeco/swift-dependencies",
			from: "1.12.0",
		),
		.package(path: "../Dependencies/DepBatteryLevel"),
		.package(path: "../Dependencies/DepNSApp"),
		.package(path: "../Dependencies/DepPowerAssertion"),
		.package(path: "../Dependencies/DepSMAppService"),
	],
	targets: [
		.target(
			name: "App",
			dependencies: [
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				"DepBatteryLevel",
				"DepNSApp",
				"DepPowerAssertion",
				"DepSMAppService",
			],
			path: "Sources",
		),
		.testTarget(
			name: "AppTests",
			dependencies: [
				"App",
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "DependenciesTestSupport", package: "swift-dependencies"),
				"DepBatteryLevel",
				"DepNSApp",
				"DepPowerAssertion",
				"DepSMAppService",
			],
			path: "Tests",
		),
	],
)
