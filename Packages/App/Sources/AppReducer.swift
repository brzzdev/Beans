public import ComposableArchitecture
import DepBatteryLevel
import DepNSApp
import DepPowerAssertion
import DepSMAppService
import OSLog

private let logger = Logger(subsystem: "com.brzzdev.Beans", category: "App")

@Reducer
public struct AppReducer: Reducer, Sendable {
	@ObservableState
	public struct State: Equatable {
		@Shared(.activateOnLaunch) public var activateOnLaunch
		@Shared(.deactivateOnLowBattery) public var deactivateOnLowBattery
		public var duration: Duration?
		public var isActive = false
		public var launchAtLogin = false

		init() {}

		#if DEBUG
		init(
			activateOnLaunch: Bool = false,
			deactivateOnLowBattery: Bool = false,
			duration: Duration? = nil,
			isActive: Bool = false,
			launchAtLogin: Bool = false,
		) {
			_activateOnLaunch = Shared(wrappedValue: activateOnLaunch, .activateOnLaunch)
			_deactivateOnLowBattery = Shared(wrappedValue: deactivateOnLowBattery, .deactivateOnLowBattery)
			self.duration = duration
			self.isActive = isActive
			self.launchAtLogin = launchAtLogin
		}
		#endif
	}

	public enum Action: ViewAction {
		case batteryLevelUpdated(Int)
		case timerFinished
		case view(View)

		@CasePathable
		public enum View {
			case activateForDuration(Duration)
			case activateIndefinitely
			case deactivate
			case quit
			case setActivateOnLaunch(Bool)
			case setDeactivateOnLowBattery(Bool)
			case setLaunchAtLogin(Bool)
			case setup
		}
	}

	private enum CancelID { case batteryMonitor, timer }

	@Dependency(\.batteryLevel) var batteryLevel
	@Dependency(\.continuousClock) var clock
	@Dependency(\.nsApp) var nsApp
	@Dependency(\.powerAssertion) var powerAssertion
	@Dependency(\.smAppService) var smAppService

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .batteryLevelUpdated(level):
				if state.isActive, state.deactivateOnLowBattery, level <= 10 {
					logger.info("Battery at \(level)%, deactivating")
					return deactivate(state: &state)
				}
				return .none

			case .view(.setup):
				state.launchAtLogin = smAppService.isEnabled()
				if state.activateOnLaunch {
					logger.info("Activate on launch enabled, activating")
					powerAssertion.activate()
					state.isActive = true
				}
				return startBatteryMonitorIfNeeded(state: state)

			case let .view(.activateForDuration(duration)):
				logger.info("Activating for \(duration)")
				powerAssertion.activate()
				state.isActive = true
				state.duration = duration
				return .merge(
					.run { send in
						try await clock.sleep(for: duration)
						await send(.timerFinished)
					}
					.cancellable(id: CancelID.timer, cancelInFlight: true),
					startBatteryMonitorIfNeeded(state: state),
				)

			case .view(.activateIndefinitely):
				logger.info("Activating indefinitely")
				powerAssertion.activate()
				state.isActive = true
				state.duration = nil
				return .merge(
					.cancel(id: CancelID.timer),
					startBatteryMonitorIfNeeded(state: state),
				)

			case .timerFinished, .view(.deactivate):
				logger.info("Deactivating")
				return deactivate(state: &state)

			case .view(.quit):
				logger.info("Quitting")
				powerAssertion.deactivate()
				return .run { [nsApp] _ in
					await nsApp.terminate()
				}

			case let .view(.setActivateOnLaunch(enabled)):
				state.$activateOnLaunch.withLock { $0 = enabled }
				logger.info("Activate on launch: \(enabled)")
				return .none

			case let .view(.setDeactivateOnLowBattery(enabled)):
				state.$deactivateOnLowBattery.withLock { $0 = enabled }
				logger.info("Deactivate on low battery: \(enabled)")
				return startBatteryMonitorIfNeeded(state: state)

			case let .view(.setLaunchAtLogin(enabled)):
				do {
					if enabled {
						try smAppService.register()
					} else {
						try smAppService.unregister()
					}
					state.launchAtLogin = enabled
					logger.info("Launch at login: \(enabled)")
				} catch {
					logger.error("Failed to set launch at login: \(error)")
				}
				return .none
			}
		}
	}

	public init() {}

	private func deactivate(state: inout State) -> Effect<Action> {
		powerAssertion.deactivate()
		state.isActive = false
		state.duration = nil
		return .merge(
			.cancel(id: CancelID.batteryMonitor),
			.cancel(id: CancelID.timer),
		)
	}

	private func startBatteryMonitorIfNeeded(state: State) -> Effect<Action> {
		if state.deactivateOnLowBattery, state.isActive {
			return .run { send in
				for await level in batteryLevel.updates() {
					await send(.batteryLevelUpdated(level))
				}
			}
			.cancellable(id: CancelID.batteryMonitor, cancelInFlight: true)
		}
		return .cancel(id: CancelID.batteryMonitor)
	}
}

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
	static var activateOnLaunch: Self {
		Self[.appStorage("activateOnLaunch"), default: false]
	}

	static var deactivateOnLowBattery: Self {
		Self[.appStorage("deactivateOnLowBattery"), default: false]
	}
}
