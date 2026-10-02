# smartvan

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Phase 3 (parent app)

Backend contract: `docs/PHASE3_API.md` in the `smartvan` repo.

- Setup: put `MAPS_API_KEY=...` in `android/local.properties` (the key is
  no longer in source). Auth token is stored in secure storage.
- **Live tracking**: per-kid ETA from the socket `etaUpdate` event; red
  banner when the driver raises an SOS.
- **Notifications**: in-app banners for foreground pushes; tapping a push
  opens the right screen.
- **Chat** (`lib/features/chat/`): message the van driver; quick replies.
- **Fees** (`lib/features/fees/`): pay online (JazzCash / Easypaisa / Raast;
  test mode with `PAYMENTS_MODE=mock`) and shareable receipts.
