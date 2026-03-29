import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppReducer.self)
public struct BeansApp: App {
	@State private var isInserted = true

	public let store = Store(initialState: AppReducer.State()) {
		AppReducer()
	}

	public init() {
		send(.setup)
	}

	public var body: some Scene {
		MenuBarExtra(isInserted: $isInserted) {
			MenuContent(store: store)
		} label: {
			Image(systemName: store.isActive ? "mug.fill" : "mug")
				.symbolRenderingMode(.hierarchical)
		}
	}
}

private struct MenuContent: View {
	let store: StoreOf<AppReducer>

	var body: some View {
		if store.isActive {
			if let duration = store.duration {
				Text("Keeping awake for \(duration.formatted())")
			} else {
				Text("Keeping awake indefinitely")
			}
			Divider()
			Button("Deactivate") {
				store.send(.view(.deactivate))
			}
			.keyboardShortcut("d")
		} else {
			Text("Inactive")
			Divider()
			Button("Indefinitely") {
				store.send(.view(.activateIndefinitely))
			}
			.keyboardShortcut("a")
			ForEach(ActivationDuration.allCases) { activationDuration in
				Button(activationDuration.label) {
					store.send(.view(.activateForDuration(activationDuration.duration)))
				}
			}
		}
		Divider()
		Toggle("Activate on Launch", isOn: Binding(
			get: { store.activateOnLaunch },
			set: { _ in store.send(.view(.toggleActivateOnLaunch)) },
		))
		Toggle("Launch at Login", isOn: Binding(
			get: { store.launchAtLogin },
			set: { _ in store.send(.view(.toggleLaunchAtLogin)) },
		))
		Divider()
		Button("Quit") {
			store.send(.view(.quit))
		}
		.keyboardShortcut("q")
	}
}
