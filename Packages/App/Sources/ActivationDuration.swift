public enum ActivationDuration: String, CaseIterable, Identifiable, Sendable {
	case thirtyMinutes = "30 Minutes"
	case oneHour = "1 Hour"
	case twoHours = "2 Hours"
	case fourHours = "4 Hours"

	public var id: Self {
		self
	}

	public var label: String {
		rawValue
	}

	public var duration: Duration {
		switch self {
		case .thirtyMinutes: .seconds(1800)
		case .oneHour: .seconds(3600)
		case .twoHours: .seconds(7200)
		case .fourHours: .seconds(14400)
		}
	}
}
