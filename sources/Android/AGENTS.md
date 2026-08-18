# Android — App Developer Notes

Inherits project-wide SDK integration rules from [AGENTS.md](/AGENTS.md). This file adds Android-specific guidance.

> **Confirm the paradigm first.** As of SDK 7.0.0 the Android public API uses **Kotlin Coroutines** — `suspend` functions for one-shot operations and `Flow<T>` for continuous streams. Earlier versions used RxJava. Verify against the API source under [sdk/api/](/sources/Android/android-communications/library/src/sdk/java/com/polar/sdk/api/) and [MigrationGuide7.0.0-Android.md](/documentation/MigrationGuide7.0.0-Android.md) before writing code. The patterns below assume the current (Coroutines) API.

## Coroutines and Flow — subscription patterns

- **`suspend fun`** — one-shot operations (single result or completion). Call from a coroutine launched in a lifecycle-bound scope (`viewModelScope`, `lifecycleScope`); handle errors with `try/catch`.
- **`Flow<T>`** — continuous data streams (sensor streaming, event streams). Collect inside a coroutine, store the returned `Job`, and cancel it to stop the stream. Handle stream errors with the `catch` operator.

`suspend` functions and flows handle their own threading — the SDK dispatches BLE and file work to appropriate threads internally. You only need to ensure UI updates happen on the main dispatcher.

For complete, current, compiling examples (streaming, sensor-setting selection, `StateFlow` / `SharedFlow` exposure, lifecycle scoping), follow the example app and API source rather than copying snippets:

- [Android example app](/examples/example-android/)
- Streaming API source: [PolarOnlineStreamingApi.kt](/sources/Android/android-communications/library/src/sdk/java/com/polar/sdk/api/PolarOnlineStreamingApi.kt)

### Selecting sensor settings

Before starting a stream, request the device's available settings (`requestStreamSettings`) and pick the values you need (e.g. `maxSettings()`), then pass them to the stream call. See the example app for the current call shape.

## Error handling

SDK errors surface as exceptions — thrown from `suspend` functions and emitted via the `catch` operator on a `Flow`. Always handle them.

| Exception class | Cause |
|---|---|
| `PolarServiceNotAvailable` | Feature not yet ready or device does not support it |
| `PolarDeviceDisconnected` | Device disconnected during an operation |
| `PolarDeviceNotConnected` | Operation attempted on a not-connected device |
| `PolarDeviceNotFound` | Device not found during scan |
| `PolarInvalidArgument` | Invalid argument (e.g. empty device ID) |
| `PolarOperationNotSupported` | Device/firmware does not support this operation |
| `PolarOfflineRecordingError` | Error specific to offline recording operations |
| `PolarBleSdkInternalException` | Internal SDK error (file a bug if reproducible) |

The current, authoritative set is defined in [sdk/api/errors/](/sources/Android/android-communications/library/src/sdk/java/com/polar/sdk/api/errors/). Use `try/catch` for `suspend` functions and the `catch` operator for flows.

## Lifecycle management

- Keep the `PolarBleApi` instance in a `ViewModel` (or `Application`) so BLE state survives configuration changes, and share a single instance across the app.
- Call `api.shutDown()` when the owner is destroyed (`onCleared()` in a `ViewModel`, `onDestroy()` in an Activity/Fragment) to release BLE resources.
- Cancel stream `Job`s when done. Coroutines launched in `viewModelScope` / `lifecycleScope` are cancelled automatically when the scope is destroyed; rely on this structured concurrency or cancel each `Job` explicitly.

See the [Android example app](/examples/example-android/) for the current ViewModel pattern.

## Runtime permissions

Bluetooth permissions must be granted at runtime before any SDK call. The exact set depends on the Android version the app targets (e.g. `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` on newer Android, `ACCESS_FINE_LOCATION` on older). For the authoritative manifest entries and the runtime-request flow:

- [README.md](/README.md) — required permissions list.
- [Android example app](/examples/example-android/) — full manifest and runtime-request implementation.

## Minimum SDK version and dependencies

Do not hardcode the minimum SDK version or dependency versions — they change between releases (the 7.0.0 migration raised the minimum and swapped RxJava for Kotlin Coroutines). Read the current values from the library build manifest:

- [build.gradle](/sources/Android/android-communications/library/build.gradle)
- [README.md](/README.md) — Android getting-started / installation.

If your app's `minSdk` is lower than the SDK's, either raise it or guard SDK calls behind a runtime API-level check.

## ProGuard / R8

If you use code shrinking, keep the SDK classes. The example app's `proguard-rules.pro` carries the current, tested keep rules (covering the public `com.polar.sdk.**` and internal `com.polar.androidcommunications.**` packages) — copy them from there rather than from a static snippet:

- [Android example app](/examples/example-android/)

## Common pitfalls

- **Calling feature APIs before `bleSdkFeatureReady`**: always wait for the callback for the specific feature and device. Premature calls throw `PolarServiceNotAvailable`.
- **Not cancelling stream `Job`s**: active `Job`s keep BLE resources alive and may deliver data after the lifecycle owner is destroyed. Cancel each stream `Job`, or rely on scope cancellation.
- **Updating UI from a background dispatcher**: SDK calls may resume on a background thread — switch to the main dispatcher (e.g. `withContext(Dispatchers.Main)` or collect on a main-bound scope) before writing UI state.
- **Forgetting the `INTERNET` permission**: required in the manifest even if your app has no network use (internal SDK dependency).
- **Multiple SDK instances**: create one `PolarBleApi` per app process and share it.
- **Assuming the async paradigm**: confirm Coroutines vs RxJava from the API source / migration guide for the project's SDK version before generating code.

## Migration

- [MigrationGuide7.0.0-Android.md](/documentation/MigrationGuide7.0.0-Android.md) — RxJava → Kotlin Coroutines (the current Android paradigm).
- [MigrationGuide5.0.0.md](/documentation/MigrationGuide5.0.0.md) — earlier API and terminology changes (feature enums, data-type rename, unified readiness callback).
- Read the [documentation/](/documentation/) folder for any newer guides.
