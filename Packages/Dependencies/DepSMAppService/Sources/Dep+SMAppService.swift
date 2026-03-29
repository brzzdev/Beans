import Dependencies
import DependenciesMacros
import ServiceManagement

extension DependencyValues {
	public var smAppService: SMAppServiceDependency {
		get { self[SMAppServiceDependency.self] }
		set { self[SMAppServiceDependency.self] = newValue }
	}
}

@DependencyClient
public struct SMAppServiceDependency: Sendable {
	public var isEnabled: @Sendable () -> Bool = { false }
	public var register: @Sendable () throws -> Void
	public var unregister: @Sendable () throws -> Void
}

extension SMAppServiceDependency: DependencyKey {
	public static let liveValue = Self(
		isEnabled: { SMAppService.mainApp.status == .enabled },
		register: { try SMAppService.mainApp.register() },
		unregister: { try SMAppService.mainApp.unregister() },
	)

	public static let testValue = Self()
}
