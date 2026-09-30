# Beans

A macOS menu bar app that prevents idle display sleep by holding an
`IOPMAssertionCreateWithName` assertion of type `PreventUserIdleDisplaySleep`.

## Language

**Activation**:
The current keep-awake session — whether the display is being kept awake and, if so,
for how long. Modelled as a three-case state: `inactive`, `indefinite`, `timed(Duration)`.
The power assertion is held if and only if the Activation is not `inactive`.
_Avoid_: active flag, awake state, isActive (that's a derived convenience, not the concept)

**ActivationDuration**:
A preset length of time offered in the menu (30 minutes, 1 hour, 2 hours, 4 hours).
A user's *choice*, distinct from the live **Activation** session it produces.
_Avoid_: timer, preset, interval

**Power assertion**:
The held `IOPMAssertionCreateWithName` of type `PreventUserIdleDisplaySleep` that keeps
the display awake. Owned behind the power-assertion seam; created on activate, released on deactivate.
_Avoid_: lock, wake lock, caffeine
