/// The current keep-awake session.
///
/// The power assertion is held if and only if the activation is not ``inactive``.
public enum Activation: Equatable, Sendable {
	case inactive
	case indefinite
	case timed(Duration)
}
