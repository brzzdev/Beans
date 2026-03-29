import AppKit
import Dependencies
import DependenciesMacros

extension DependencyValues {
	public var nsApp: NSAppDependency {
		get { self[NSAppDependency.self] }
		set { self[NSAppDependency.self] = newValue }
	}
}

@DependencyClient
public struct NSAppDependency: Sendable {
	public var terminate: @MainActor @Sendable () async -> Void
}

extension NSAppDependency: DependencyKey {
	public static let testValue = Self()

	public static let liveValue = Self(
		terminate: { NSApp.terminate(nil) }
	)
}
