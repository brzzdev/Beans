// swift-tools-version: 6.3

import PackageDescription

let package = Package(
	name: "DepBatteryLevel",
	platforms: [
		.macOS(.v26),
	],
	products: [
		.library(
			name: "DepBatteryLevel",
			targets: ["DepBatteryLevel"],
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/pointfreeco/swift-dependencies",
			from: "1.13.1",
		),
	],
	targets: [
		.target(
			name: "DepBatteryLevel",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			],
			path: "Sources",
		),
	],
)
