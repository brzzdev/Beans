# Beans

A macOS menu bar app that prevents your display from sleeping.

A modern alternative to [Caffeine](https://intelliscapesolutions.com/apps/caffeine), [KeepingYouAwake](https://keepingyouawake.app), and similar utilities — built with SwiftUI and [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

## Features

- Prevent idle display sleep indefinitely or on a timer (30 min, 1 hr, 2 hr, 4 hr)
- Activate on launch
- Launch at login
- Notarized and signed for direct distribution
- Survives menu bar icon hiding (macOS 26+)

## Install

Download the latest release from the [Releases](https://github.com/brzzdev/Beans/releases) page, unzip, and drag `Beans.app` to `/Applications`.

### Build from source

```bash
just build    # build
just test     # run tests
just install  # archive, notarize, install to /Applications
```

Requires Xcode 26+ and [just](https://github.com/casey/just).

## How it works

Beans holds an `IOPMAssertionCreateWithName` power assertion of type `PreventUserIdleDisplaySleep`. This prevents the display from dimming or sleeping due to inactivity. Closing the lid or manually sleeping the Mac still works normally.

## License

MIT
