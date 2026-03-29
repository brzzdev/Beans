// swift-tools-version: 6.3

import PackageDescription

let package = Package(
	name: "DepPowerAssertion",
	platforms: [.macOS(.v26)],
	products: [
		.library(name: "DepPowerAssertion", targets: ["DepPowerAssertion"]),
	],
	dependencies: [
		.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.11.0"),
	],
	targets: [
		.target(
			name: "DepPowerAssertion",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			],
			path: "Sources"
		),
	]
)
