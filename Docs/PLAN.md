# PLAN

Roadmap and planned work. Not commitments — direction.

## Near term

- Reconcile the two install paths: either route the flow through
  `Installer.swift` or remove it, and decide on `/Applications` vs
  `~/Applications` as the canonical destination.
- Surface install success/failure more clearly in the UI (currently only in the
  log text).
- Handle projects that produce multiple `.app` products (target/scheme picker).

## Medium term

- Allow choosing build configuration (Debug/Release) and destination.
- Show structured build progress instead of raw log streaming only.
- Persist and display a history of recently built/installed projects.

## Longer term / ideas

- Optional automated tests around `BuildManager` project-type detection and the
  script marker parsing.
- Drag-and-drop of a project folder onto the window (partially supported today
  via `application(_:open:)`).
