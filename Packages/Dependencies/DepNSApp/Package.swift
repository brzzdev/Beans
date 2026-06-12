// swift-tools-version: 6.3

import PackageDescription

let package = Package(
	name: "DepNSApp",
	platforms: [
		.macOS(.v26),
	],
	products: [
		.library(
			name: "DepNSApp",
			targets: ["DepNSApp"],
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
			name: "DepNSApp",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			],
			path: "Sources",
		),
	],
)

for target in package.targets {
	target.swiftSettings = target.swiftSettings ?? []
	target.swiftSettings?.append(contentsOf: [
		.enableUpcomingFeature("ExistentialAny"),
		.enableUpcomingFeature("ImmutableWeakCaptures"),
		.enableUpcomingFeature("InferIsolatedConformances"),
		.enableUpcomingFeature("InternalImportsByDefault"),
		.enableUpcomingFeature("MemberImportVisibility"),
		.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
	])
	#if compiler(>=6.4)
	target.swiftSettings?.append(contentsOf: [
		.treatAllWarnings(as: .error),
	])
	#endif
}
