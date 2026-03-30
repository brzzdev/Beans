macOS menu bar app that prevents idle display sleep (a Caffeine / KeepingYouAwake alternative), built with SwiftUI + TCA. Holds an `IOPMAssertionCreateWithName` assertion of type `PreventUserIdleDisplaySleep`.

- Build and test via `just build` / `just test` — never call xcodebuild directly
