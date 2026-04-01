@testable import App
import ComposableArchitecture
import DepBatteryLevel
import DependenciesTestSupport
import DepNSApp
import DepPowerAssertion
import DepSMAppService
import Synchronization
import Testing

@MainActor
@Suite(.dependencies)
struct AppReducerTests {
	final class Counter: Sendable {
		private let value = Mutex(0)

		func increment() {
			value.withLock { $0 += 1 }
		}

		func get() -> Int {
			value.withLock { $0 }
		}
	}

	let activateCount = Counter()
	let deactivateCount = Counter()

	@Test
	func `activate indefinitely`() async {
		let store = makeStore()

		await store.send(.view(.activateIndefinitely)) {
			$0.isActive = true
			$0.duration = nil
		}

		#expect(activateCount.get() == 1)
	}

	@Test
	func `activate for duration`() async {
		let clock = TestClock()
		let store = makeStore {
			$0.continuousClock = clock
		}

		let duration = Duration.seconds(1_800)
		await store.send(.view(.activateForDuration(duration))) {
			$0.isActive = true
			$0.duration = duration
		}

		#expect(activateCount.get() == 1)

		await clock.advance(by: duration)
		await store.receive(\.timerFinished) {
			$0.isActive = false
			$0.duration = nil
		}

		#expect(deactivateCount.get() == 1)
	}

	@Test
	func deactivate() async {
		let store = makeStore()

		await store.send(.view(.activateIndefinitely)) {
			$0.isActive = true
		}

		await store.send(.view(.deactivate)) {
			$0.isActive = false
		}

		#expect(activateCount.get() == 1)
		#expect(deactivateCount.get() == 1)
	}

	@Test
	func `deactivate cancels timer`() async {
		let clock = TestClock()
		let store = makeStore {
			$0.continuousClock = clock
		}

		let duration = Duration.seconds(3_600)
		await store.send(.view(.activateForDuration(duration))) {
			$0.isActive = true
			$0.duration = duration
		}

		await store.send(.view(.deactivate)) {
			$0.isActive = false
			$0.duration = nil
		}

		#expect(deactivateCount.get() == 1)
	}

	@Test
	func `activate indefinitely cancels existing timer`() async {
		let clock = TestClock()
		let store = makeStore {
			$0.continuousClock = clock
		}

		let duration = Duration.seconds(3_600)
		await store.send(.view(.activateForDuration(duration))) {
			$0.isActive = true
			$0.duration = duration
		}

		await store.send(.view(.activateIndefinitely)) {
			$0.duration = nil
		}

		#expect(activateCount.get() == 2)
	}

	@Test
	func `activate for duration replaces existing`() async {
		let clock = TestClock()
		let store = makeStore {
			$0.continuousClock = clock
		}

		await store.send(.view(.activateForDuration(.seconds(1_800)))) {
			$0.isActive = true
			$0.duration = .seconds(1_800)
		}

		await store.send(.view(.activateForDuration(.seconds(7_200)))) {
			$0.duration = .seconds(7_200)
		}

		#expect(activateCount.get() == 2)

		await clock.advance(by: .seconds(7_200))
		await store.receive(\.timerFinished) {
			$0.isActive = false
			$0.duration = nil
		}

		#expect(deactivateCount.get() == 1)
	}

	@Test
	func `timer finished`() async {
		let store = makeStore(state: AppReducer.State(duration: .seconds(1_800), isActive: true))

		await store.send(.timerFinished) {
			$0.isActive = false
			$0.duration = nil
		}

		#expect(deactivateCount.get() == 1)
	}

	@Test
	func quit() async {
		let terminateCount = Counter()
		let store = makeStore {
			$0.nsApp = NSAppDependency(terminate: { terminateCount.increment() })
		}

		await store.send(.view(.quit))
		#expect(terminateCount.get() == 1)
		#expect(deactivateCount.get() == 1)
	}

	@Test
	func `setup activates on launch`() async {
		let store = makeStore {
			$0.smAppService = SMAppServiceDependency(
				isEnabled: { false },
				register: {},
				unregister: {},
			)
		}

		store.state.$activateOnLaunch.withLock { $0 = true }

		await store.send(.view(.setup)) {
			$0.isActive = true
		}

		#expect(activateCount.get() == 1)
	}

	@Test
	func `setup does not activate when disabled`() async {
		let store = makeStore {
			$0.smAppService = SMAppServiceDependency(
				isEnabled: { false },
				register: {},
				unregister: {},
			)
		}

		await store.send(.view(.setup))

		#expect(activateCount.get() == 0)
	}

	@Test
	func `setup reads launch at login status`() async {
		let store = makeStore {
			$0.smAppService = SMAppServiceDependency(
				isEnabled: { true },
				register: {},
				unregister: {},
			)
		}

		await store.send(.view(.setup)) {
			$0.launchAtLogin = true
		}
	}

	@Test
	func `toggle activate on launch`() async {
		let store = makeStore()

		await store.send(.view(.toggleActivateOnLaunch)) {
			$0.$activateOnLaunch.withLock { $0 = true }
		}

		await store.send(.view(.toggleActivateOnLaunch)) {
			$0.$activateOnLaunch.withLock { $0 = false }
		}
	}

	@Test
	func `toggle launch at login`() async {
		let registerCount = Counter()
		let store = makeStore {
			$0.smAppService = SMAppServiceDependency(
				isEnabled: { false },
				register: { registerCount.increment() },
				unregister: {},
			)
		}

		await store.send(.view(.toggleLaunchAtLogin)) {
			$0.launchAtLogin = true
		}

		#expect(registerCount.get() == 1)
	}

	@Test
	func `toggle launch at login unregisters`() async {
		let unregisterCount = Counter()
		let store = makeStore(state: AppReducer.State(launchAtLogin: true)) {
			$0.smAppService = SMAppServiceDependency(
				isEnabled: { true },
				register: {},
				unregister: { unregisterCount.increment() },
			)
		}

		await store.send(.view(.toggleLaunchAtLogin)) {
			$0.launchAtLogin = false
		}

		#expect(unregisterCount.get() == 1)
	}

	@Test
	func `toggle deactivate on low battery`() async {
		let store = makeStore()

		await store.send(.view(.toggleDeactivateOnLowBattery)) {
			$0.$deactivateOnLowBattery.withLock { $0 = true }
		}

		await store.send(.view(.toggleDeactivateOnLowBattery)) {
			$0.$deactivateOnLowBattery.withLock { $0 = false }
		}
	}

	@Test
	func `deactivates when battery drops to 10 percent`() async {
		let store = makeStore(state: AppReducer.State(isActive: true))
		store.state.$deactivateOnLowBattery.withLock { $0 = true }

		await store.send(.batteryLevelUpdated(10)) {
			$0.isActive = false
		}

		#expect(deactivateCount.get() == 1)
	}

	@Test
	func `deactivates when battery drops below 10 percent`() async {
		let store = makeStore(state: AppReducer.State(isActive: true))
		store.state.$deactivateOnLowBattery.withLock { $0 = true }

		await store.send(.batteryLevelUpdated(5)) {
			$0.isActive = false
		}

		#expect(deactivateCount.get() == 1)
	}

	@Test
	func `does not deactivate when battery above 10 percent`() async {
		let store = makeStore(state: AppReducer.State(isActive: true))
		store.state.$deactivateOnLowBattery.withLock { $0 = true }

		await store.send(.batteryLevelUpdated(11))

		#expect(deactivateCount.get() == 0)
	}

	@Test
	func `does not deactivate when setting disabled`() async {
		let store = makeStore(state: AppReducer.State(isActive: true))

		await store.send(.batteryLevelUpdated(5))

		#expect(deactivateCount.get() == 0)
	}

	@Test
	func `does not deactivate when already inactive`() async {
		let store = makeStore()
		store.state.$deactivateOnLowBattery.withLock { $0 = true }

		await store.send(.batteryLevelUpdated(5))

		#expect(deactivateCount.get() == 0)
	}

	private func makeStore(
		state: AppReducer.State = AppReducer.State(),
		_ withDependencies: (inout DependencyValues) -> Void = { _ in },
	) -> TestStoreOf<AppReducer> {
		TestStore(initialState: state) {
			AppReducer()
		} withDependencies: {
			$0.powerAssertion = PowerAssertionClient(
				activate: { activateCount.increment() },
				deactivate: { deactivateCount.increment() },
			)
			withDependencies(&$0)
		}
	}
}
