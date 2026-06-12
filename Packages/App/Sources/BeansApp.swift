public import ComposableArchitecture
public import SwiftUI

@ViewAction(for: AppReducer.self)
public struct BeansApp: App {
	@State private var isInserted = true

	public let store = Store(initialState: AppReducer.State()) {
		AppReducer()
	}

	public var body: some Scene {
		MenuBarExtra(isInserted: $isInserted) {
			MenuContent(store: store)
		} label: {
			Image(systemName: store.isActive ? "mug.fill" : "mug")
				.symbolRenderingMode(.hierarchical)
		}
	}

	public init() {
		send(.setup)
	}
}

private struct MenuContent: View {
	@Bindable var store: StoreOf<AppReducer>

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
		Toggle("Activate on Launch", isOn: $store.activateOnLaunch.sending(\.view.setActivateOnLaunch))
		Toggle(
			"Deactivate on Low Battery",
			isOn: $store.deactivateOnLowBattery.sending(\.view.setDeactivateOnLowBattery),
		)
		Toggle("Launch at Login", isOn: $store.launchAtLogin.sending(\.view.setLaunchAtLogin))
		Divider()
		Button("Quit") {
			store.send(.view(.quit))
		}
		.keyboardShortcut("q")
	}
}
