import Dependencies
import DependenciesMacros
import IOKit.pwr_mgt
import OSLog
import Synchronization

private let logger = Logger(subsystem: "com.brzzdev.Beans", category: "PowerAssertion")

extension DependencyValues {
	public var powerAssertion: PowerAssertionClient {
		get { self[PowerAssertionClient.self] }
		set { self[PowerAssertionClient.self] = newValue }
	}
}

@DependencyClient
public struct PowerAssertionClient: Sendable {
	public var activate: @Sendable () -> Void
	public var deactivate: @Sendable () -> Void
}

extension PowerAssertionClient: DependencyKey {
	private static let assertionID = Mutex<IOPMAssertionID>(0)

	public static let testValue = Self()

	public static let liveValue = Self(
		activate: {
			assertionID.withLock { id in
				deactivate(id: &id)
				let reason = "Beans: keeping display awake" as CFString
				let result = IOPMAssertionCreateWithName(
					kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
					IOPMAssertionLevel(kIOPMAssertionLevelOn),
					reason,
					&id
				)
				let createdID = id
				if result == kIOReturnSuccess {
					logger.info("Power assertion created (id: \(createdID))")
				} else {
					logger.error("Failed to create power assertion: \(result)")
				}
			}
		},
		deactivate: {
			assertionID.withLock { id in
				deactivate(id: &id)
			}
		}
	)

	private static func deactivate(id: inout IOPMAssertionID) {
		if id != 0 {
			let releasedID = id
			IOPMAssertionRelease(id)
			logger.info("Power assertion released (id: \(releasedID))")
			id = 0
		}
	}
}
