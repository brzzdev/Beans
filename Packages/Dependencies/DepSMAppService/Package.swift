// swift-tools-version: 6.3

import PackageDescription

let package = Package(
	name: "DepSMAppService",
	platforms: [
		.macOS(.v26),
	],
	products: [
		.library(
			name: "DepSMAppService",
			targets: ["DepSMAppService"],
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/pointfreeco/swift-dependencies",
			from: "1.12.0",
		),
	],
	targets: [
		.target(
			name: "DepSMAppService",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			],
			path: "Sources",
		),
	],
)
