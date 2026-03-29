import ComposableArchitecture
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
		public var duration: Duration?
		public var isActive = false
		public var launchAtLogin = false

		init() {}

		#if DEBUG
			init(
				activateOnLaunch: Bool = false,
				duration: Duration? = nil,
				isActive: Bool = false,
				launchAtLogin: Bool = false
			) {
				self._activateOnLaunch = Shared(wrappedValue: activateOnLaunch, .activateOnLaunch)
				self.duration = duration
				self.isActive = isActive
				self.launchAtLogin = launchAtLogin
			}
		#endif
	}

	public enum Action: ViewAction {
		case setup
		case timerFinished
		case view(View)

		@CasePathable
		public enum View {
			case activateForDuration(Duration)
			case activateIndefinitely
			case deactivate
			case quit
			case toggleActivateOnLaunch
			case toggleLaunchAtLogin
		}
	}

	private enum CancelID { case timer }

	@Dependency(\.continuousClock) var clock
	@Dependency(\.nsApp) var nsApp
	@Dependency(\.powerAssertion) var powerAssertion
	@Dependency(\.smAppService) var smAppService

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .setup:
				state.launchAtLogin = smAppService.isEnabled()
				if state.activateOnLaunch {
					logger.info("Activate on launch enabled, activating")
					powerAssertion.activate()
					state.isActive = true
				}
				return .none

			case let .view(.activateForDuration(duration)):
				logger.info("Activating for \(duration)")
				powerAssertion.activate()
				state.isActive = true
				state.duration = duration
				return .run { send in
					try await clock.sleep(for: duration)
					await send(.timerFinished)
				}
				.cancellable(id: CancelID.timer, cancelInFlight: true)

			case .view(.activateIndefinitely):
				logger.info("Activating indefinitely")
				powerAssertion.activate()
				state.isActive = true
				state.duration = nil
				return .cancel(id: CancelID.timer)

			case .view(.deactivate), .timerFinished:
				logger.info("Deactivating")
				powerAssertion.deactivate()
				state.isActive = false
				state.duration = nil
				return .cancel(id: CancelID.timer)

			case .view(.quit):
				logger.info("Quitting")
				powerAssertion.deactivate()
				return .run { [nsApp] _ in
					await nsApp.terminate()
				}

			case .view(.toggleActivateOnLaunch):
				state.$activateOnLaunch.withLock { $0.toggle() }
				let activateOnLaunch = state.activateOnLaunch
				logger.info("Activate on launch: \(activateOnLaunch)")
				return .none

			case .view(.toggleLaunchAtLogin):
				do {
					if state.launchAtLogin {
						try smAppService.unregister()
					} else {
						try smAppService.register()
					}
					state.launchAtLogin.toggle()
					let launchAtLogin = state.launchAtLogin
					logger.info("Launch at login: \(launchAtLogin)")
				} catch {
					logger.error("Failed to toggle launch at login: \(error)")
				}
				return .none
			}
		}
	}
}

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
	static var activateOnLaunch: Self {
		Self[.appStorage("activateOnLaunch"), default: false]
	}
}

public enum ActivationDuration: String, CaseIterable, Identifiable, Sendable {
	case thirtyMinutes = "30 Minutes"
	case oneHour = "1 Hour"
	case twoHours = "2 Hours"
	case fourHours = "4 Hours"

	public var id: Self { self }

	public var label: String { rawValue }

	public var duration: Duration {
		switch self {
		case .thirtyMinutes: .seconds(1_800)
		case .oneHour: .seconds(3_600)
		case .twoHours: .seconds(7_200)
		case .fourHours: .seconds(14_400)
		}
	}
}
