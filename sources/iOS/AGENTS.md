# iOS — App Developer Notes

Inherits project-wide SDK integration rules from [AGENTS.md](/AGENTS.md). This file adds iOS-specific guidance.

> **Confirm the paradigm first.** As of SDK 8.0.0 the iOS public API uses **Swift Concurrency** (`async`/`await` and `AsyncThrowingStream`) together with **Combine** — RxSwift has been removed. Earlier versions used RxSwift. Verify against the API source under [sdk/api/](/sources/iOS/ios-communications/Sources/PolarBleSdk/sdk/api/) and [MigrationGuide8.0.0-iOS.md](/documentation/MigrationGuide8.0.0-iOS.md) before writing code. The patterns below assume the current (Swift Concurrency) API.

## Swift Concurrency — call patterns

The public API maps to these shapes (confirm each method's exact signature in the API source):

- **One-shot operations** → `async throws` functions returning a value or `Void`. Call with `try await` from an async context or a `Task`.
- **Continuous / infinite streams** (sensor streaming, device search, HR broadcast) → `AsyncThrowingStream<T, Error>`. Iterate with `for try await … in …` inside a `Task`; cancel the stream by cancelling that `Task`.
- **Hot / multicast streams** → Combine `AnyPublisher<T, Error>`. Subscribe with `sink` and store the returned `AnyCancellable`.
- **Delegate-based observers are unchanged** — connection, power-state, device-info, and feature-readiness callbacks (e.g. `bleSdkFeatureReady`) are still delivered through the observer protocols you assign (`api.observer`, `api.deviceFeaturesObserver`, etc.).

`import RxSwift` is no longer needed. Add `import Combine` where you consume a publisher, and `import PolarBleSdk` for the API.

For complete, current, compiling examples, follow the example app and the API source rather than copying snippets:

- [iOS example app](/examples/example-ios/)
- Streaming API source: [PolarOnlineStreamingApi.swift](/sources/iOS/ios-communications/Sources/PolarBleSdk/sdk/api/PolarOnlineStreamingApi.swift)

### Selecting sensor settings

Before starting a stream, request the device's available settings (`requestStreamSettings`, an `async throws` call), pick the values you need (e.g. `maxSettings()`), then pass them to the stream call.

## Threading

There is no `observeOn` / scheduler in the Swift Concurrency API. Stream values and `async` results may resume on a background cooperative-pool thread. **Hop to the main actor before touching UI** — annotate UI-facing work with `@MainActor`, or wrap UI updates in `await MainActor.run { … }`. If a delegate callback (e.g. `hrValueReceived`) updates UI, dispatch it to the main actor yourself.

## Error handling

Errors are thrown (`try await`) or delivered on the stream's error path / Combine completion as `PolarErrors` cases — never silently ignored. Always handle them with `do/catch` (or the Combine failure path).

| Case | Cause |
|---|---|
| `.serviceNotFound` | Feature not yet ready or device does not support it |
| `.deviceNotConnected` | Operation attempted on a disconnected device |
| `.deviceNotFound` | Device not found during scan |
| `.operationNotSupported` | Device/firmware does not support this operation |
| `.invalidArgument(description:)` | Invalid argument passed to an API call |
| `.timeout(description:)` | Operation timed out |
| `.polarOfflineRecordingError(description:)` | Error specific to offline recording |
| `.polarBleSdkInternalException(description:)` | Internal SDK error (file a bug if reproducible) |

The current, authoritative set is defined in [PolarErrors.swift](/sources/iOS/ios-communications/Sources/PolarBleSdk/sdk/api/errors/PolarErrors.swift). Pattern-match with a `switch` after casting via `error as? PolarErrors`.

## Lifecycle management

- Keep the `PolarBleApi` instance and your stream `Task`s / Combine `AnyCancellable`s at the object level (view model, controller, or a shared object such as an `@EnvironmentObject` / `AppDelegate`) — not in a local function scope, or they are cancelled as soon as the function returns.
- Share a single `PolarBleApi` instance across the app; multiple instances cause undefined BLE behavior.
- Cancel active stream `Task`s, release `AnyCancellable`s, and clear observers when the owner is deallocated.

See the [iOS example app](/examples/example-ios/) for the current view-model and SwiftUI patterns.

## Background Bluetooth

To receive BLE data in the background, enable **Background Modes → Uses Bluetooth LE accessories** in the Xcode target's *Signing & Capabilities*. Without it, active streams pause when the app backgrounds.

The `NSBluetoothAlwaysUsageDescription` key in `Info.plist` is required on iOS 13+ regardless of background-mode usage.

## Deployment target and dependencies

Do not hardcode the iOS deployment target or dependency versions — they change between releases. Read the current values from the manifests:

- [PolarBleSdk.podspec](/PolarBleSdk.podspec)
- [Package.swift](/Package.swift)
- [README.md](/README.md) — iOS getting-started / installation.

## watchOS

watchOS is listed in the SDK package manifest but is **not fully supported** at this time — see [issue #479](https://github.com/polarofficial/polar-ble-sdk/issues/479) for current status. Do not assume a specific watchOS deployment target; read it from [Package.swift](/Package.swift) if you need it.

## Common pitfalls

- **Calling feature APIs before the device-features observer fires**: always wait for the readiness callback for the specific feature. Premature calls return `.serviceNotFound`.
- **Multiple SDK instances**: create one `PolarBleApi` per app and share it.
- **Updating UI off the main actor**: results may resume on a background thread — hop to `@MainActor` before touching UI or `@Published` state.
- **Losing a stream `Task` / `AnyCancellable`**: if it is local to a function, the stream is cancelled when the function returns. Keep it at the object level.
- **Missing background mode**: if streams stop when the app backgrounds, enable the BLE background-mode capability.
- **Assuming the async paradigm**: confirm Swift Concurrency vs RxSwift from the API source / migration guide for the project's SDK version before generating code.

## Migration

- [MigrationGuide8.0.0-iOS.md](/documentation/MigrationGuide8.0.0-iOS.md) — RxSwift → Swift Concurrency (the current iOS paradigm), including the method-by-method mapping and the cancellation / threading changes.
- [MigrationGuide5.0.0.md](/documentation/MigrationGuide5.0.0.md) — earlier API and terminology changes (feature enums, data-type rename, unified readiness callback).
- Read the [documentation/](/documentation/) folder for any newer guides.
