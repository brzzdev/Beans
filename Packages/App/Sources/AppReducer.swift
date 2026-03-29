import ComposableArchitecture
import DepNSApp
import DepPowerAssertion
import OSLog

private let logger = Logger(subsystem: "com.brzzdev.Beans", category: "App")

@Reducer
public struct AppReducer: Reducer, Sendable {
	@ObservableState
	public struct State: Equatable {
		public var isActive = false
		public var duration: Duration?

		init() {}

		#if DEBUG
			init(isActive: Bool, duration: Duration?) {
				self.isActive = isActive
				self.duration = duration
			}
		#endif
	}
	
	public enum Action: ViewAction {
		case timerFinished
		case view(View)
		
		@CasePathable
		public enum View {
			case activateForDuration(Duration)
			case activateIndefinitely
			case deactivate
			case quit
		}
	}
	
	private enum CancelID { case timer }
	
	@Dependency(\.continuousClock) var clock
	@Dependency(\.nsApp) var nsApp
	@Dependency(\.powerAssertion) var powerAssertion
	
	public init() {}
	
	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
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
			}
		}
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
