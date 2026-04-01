import Dependencies
import DependenciesMacros
import IOKit.ps
import Synchronization

extension DependencyValues {
	public var batteryLevel: BatteryLevelClient {
		get { self[BatteryLevelClient.self] }
		set { self[BatteryLevelClient.self] = newValue }
	}
}

@DependencyClient
public struct BatteryLevelClient: Sendable {
	public var updates: @Sendable () -> AsyncStream<Int> = { .finished }
}

extension BatteryLevelClient: DependencyKey {
	public static let liveValue = Self(
		updates: {
			AsyncStream { continuation in
				let lastLevel = Mutex<Int?>(nil)

				@Sendable
				func emitCurrentLevel() {
					if let level = currentBatteryLevel() {
						lastLevel.withLock { last in
							if last != level {
								last = level
								continuation.yield(level)
							}
						}
					}
				}

				emitCurrentLevel()

				let context = Unmanaged.passRetained(
					CallbackContext(onUpdate: { emitCurrentLevel() }),
				)

				let runLoopSource = IOPSNotificationCreateRunLoopSource(
					{ context in
						guard let context else { return }
						let ctx = Unmanaged<CallbackContext>.fromOpaque(context)
							.takeUnretainedValue()
						ctx.onUpdate()
					},
					context.toOpaque(),
				)?.takeRetainedValue()

				if let runLoopSource {
					CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
				} else {
					context.release()
				}

				let cleanup = RunLoopSourceCleanup(source: runLoopSource, context: context)
				continuation.onTermination = { _ in
					cleanup.perform()
				}
			}
		},
	)

	public static let testValue = Self()
}

private final class CallbackContext: Sendable {
	let onUpdate: @Sendable () -> Void

	init(onUpdate: @Sendable @escaping () -> Void) {
		self.onUpdate = onUpdate
	}
}

private struct RunLoopSourceCleanup {
	nonisolated(unsafe) let source: CFRunLoopSource?
	let context: Unmanaged<CallbackContext>

	func perform() {
		if let source {
			CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
			context.release()
		}
	}
}

private func currentBatteryLevel() -> Int? {
	guard
		let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
		let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
		let source = sources.first,
		let description = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?
			.takeUnretainedValue() as? [String: Any],
		let capacity = description[kIOPSCurrentCapacityKey] as? Int
	else {
		return nil
	}
	return capacity
}
