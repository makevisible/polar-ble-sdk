# Polar SDK 8.0 migration spec (Visible app plugin)

Working spec for porting the Visible app's `bluetooth_foreground_service` plugin (makevisible/visible-app) from this fork's `6.13.2-visible` to the 8.x line. File paths below are in the app repository. The port shipped against `8.2.0-visible` and was bumped to `8.3.0-visible`; see [pftp-cancellation.md](pftp-cancellation.md) for the fork-side part.

Migration of `packages/bluetooth_foreground_service` from fork tag `6.13.2-visible` to `8.0.0-visible` (upstream 8.0.0 merged into the makevisible fork). Android: RxJava replaced by coroutines (suspend/Flow). iOS: RxSwift replaced by async/await, AsyncThrowingStream, Combine.

## Locked decisions

- Scope: migrate `PolarClient.kt` / `PolarClient.swift` in place. No module split in this work (follow-up).
- Full Rx removal from the plugin on both platforms, including `PolarSequentialQueue`, DB clients, service-layer wrappers. No Rx bridging at the SDK boundary.
- Thin interceptor facade per platform: `sdkCall("op") { ... }` wrapping every SDK call with logging and unified error mapping. No per-method mirrored wrapper.
- Listener/report pairs (about 15 per platform) replaced by shared event streams: `SharedFlow` (Kotlin), `AsyncStream`/Combine (Swift).
- Strict behavior parity with 6.13.2. Known bugs (power-source sync restart, empty PPI files) fixed in follow-up PRs, not here.
- Same structure and log/error taxonomy on both platforms; platform quirks stay platform-local.
- minSdk stays 28.
- Delivery: single PR into `development`. QA: manual band matrix (Sense + 360, both platforms) plus dogfood before store release. Not Shorebird-patchable.

## Audit results (2026-07-22)

### Fork rc1 merge quality: clean

- Tag `8.0.0-visible-rc1` (= `8ce3f59b` on `merge/8.0.0-visible`) verified against upstream `8.0.0`: every diff hunk traces to a known fork patch, no merge artifacts remain.
- About 80% of the fork's old delta (Rx disposable-management patches) is moot: upstream deleted Rx itself.
- Surviving fork patches: `fetchSession`/`sessionPmdClientReady` public API, BleLogger format + `e_hex`, PmdSetting hex logging, `getFileListWithSizes` (replaces `dumpAllFiles`), Android `getFile`, podspec fixes (upstream 8.0's own `source_files` path is broken), gradle publishing variant fix, `-visible` version strings.
- Loose ends:
  - Branch has one commit past the tag (`a0ed129a`, publish coordinate overrides). Decide: retag or ignore.
  - PSDC OHR automation tooling in `examples/` was dropped by the merge; parked on branch `visible-ohr-tooling-6.16.4`. Non-shipped example app. Confirm intentional.

### minSdk: no risk, keep 28

- Upstream's "requires minSdk 33" is documentation debt from 7.1.0. Upstream 8.0.0 and 8.1.0 ship `minSdkVersion 26`. The fork's 26 matches upstream exactly.
- Every API-33+ platform call (`writeCharacteristic`/`writeDescriptor` new overloads, dual GATT callbacks) is runtime-guarded with the deprecated pre-33 fallback, identical pattern to 6.13.2 running on API 28 in production today, including the OnePlus/Oppo/Realme allowlist.
- `Stream.toList()` in `BDScanCallback` resolves to a Java 16 member at compileSdk 35 (missing below API 34) but is neutralized by D8 backporting and the app's `coreLibraryDesugaringEnabled true`. No action.
- QA note: our fleet exercises the deprecated fallback branches upstream no longer tests below 33. Band matrix must include an API 28-32 device doing full connect, subscribe, write.

## Cross-cutting blockers

1. iOS: RxSwift arrives only transitively via the SDK pod today, and the 8.0 podspec drops it. Every `import RxSwift` in the plugin breaks at once. Resolved by decision: full Rx removal, no explicit RxSwift pod.
2. `dumpAllFiles` → `getFileListWithSizes` on both platforms: stream becomes one-shot suspend/async list. Files-viewer Flutter contract gets results in one shot; the queue's stream-item path can be deleted (this was its only user on both platforms).
3. File ops move to `PolarBleLowLevelApi`: iOS `getFile` → `readFile` (returns `Data?`, nil for empty/missing: decide nil→throw vs nil→empty for the Flutter contract), `removeSingleFile` → `deleteFileOrDirectory` (both platforms; Android keeps public `getFile`).
4. Android date-type sweep (compile-breaking, timezone-sensitive):
   - `PolarOfflineRecordingEntry.date`: `Date` → `LocalDateTime`. Drives the 21-day filter, 60-min empty-file floor, and Flutter `sync_start_timestamp`. The chosen `ZoneOffset` must match what the SDK encodes (device local vs UTC).
   - `PolarOfflineRecordingData.startTime`: `Calendar` → `LocalDateTime` (doc says UTC; verify against impl, cf. VIS-2991 mislabeled-UTC precedent).
   - `PolarFirstTimeUseConfig.birthDate`: `Date` → `LocalDate` (Gson adapter needed).
   - `PolarNightlyRechargeData.sleepResultDate`: `Date?` → `LocalDate?`.
   - iOS date types unchanged.
5. Cancellation-cooperativeness of 8.0 PFTP suspends: VERIFIED BROKEN (2026-07-22). Upstream's Rx removal deleted the fork's disposal semantics. Android: PFTP waits are plain monitor waits; Job.cancel() neither unblocks the caller (hangs up to 90s, 900s for SYNCPART.TGZ) nor interrupts the worker; the InterruptedException handlers incl. the device cancel packet are dead code. iOS: request/query continuations ignore Task.cancel(); write runs to completion in background; a cancelled waitNotification leaves a zombie on the serial queue that swallows every subsequent D2H notification until disconnect. Fix: fork branch `fix/8.0-pftp-cancellation` (Android: runInterruptible + notification-queue poll fix; iOS: withTaskCancellationHandler + stream onTermination + Combine bridge task cancellation). Ships as tag `8.0.1-visible`; app pins must be bumped from 8.0.0-visible once tagged.
6. Android `setLedConfig("", ...)` at `PolarClient.kt:269` is an unsubscribed Completable today, i.e. a no-op. Naively awaiting it makes it real (and it would throw on the empty identifier). Parity says: delete the call. Confirm.
7. Error-string sniffing (`"SYSTEM_BUSY"`, `"Unknown offline file"`) targets SDK internal messages; re-verify exact strings at 8.0.
8. iOS `PmdResponseCode` app-side `description` extension has an exhaustive switch; new enum cases at 8.0 break compile. Re-check case list.

## Mechanical surface (per migration guides)

- Android: about 30 one-shot methods `Single`/`Completable` → `suspend fun`; streams `Flowable` → `Flow` (`startHrStreaming`, `startPpiStreaming`, `startAccStreaming`, `listOfflineRecordings`, `updateFirmware`, `searchForDevice`). `PolarBleApiCallback` overrides unchanged. `setUserDeviceSettings` deprecated in favor of `setUserDeviceLocation`.
- iOS: same set as `async throws`; streams become `AsyncThrowingStream` (`searchForDevice`, `startListenForPolarHrBroadcasts`, `startPpiStreaming`, `listOfflineRecordings`, `updateFirmware`). Observer protocols unchanged. `polarImplementation` keeps the queue param (plus optional `restoreIdentifier`).
- Internal SDK symbols used by the app all survive at 8.0 (verified individually): `BleDeviceSession` (+ state enums, address, rssi), `DisInfo`, `BleDisClient` UUID constants, `ChargeState`/`PowerSourcesState`/`PowerSourceState`, `PmdControlPointResponse`, `BleControlPointCommandError`, `BleDisconnected`; iOS `BleBasClient` types, `BleGattException`, `BlePsFtpException`, `AtomicListException`, `BlePmdError`, `PolarErrors`.
- One exception: `BleDeviceSession.readRssiValue()` changed `Single<Integer>` → `Deferred<Int>?`. Rewrite `getAverageRssi` on the new public `suspend fun getRSSIValue(identifier)` instead, preserving 2s per-read timeout, skip-on-error, 100ms spacing. iOS RSSI comes from `HeartRateFetcher` (CoreBluetooth), not the SDK; 8.0's `getRSSIValue` is an optional simplification, but parity says keep as is.
- Models: mostly unchanged. `PolarUserDeviceSettings` gained trailing optional param (positional ctor still compiles). `PolarSleepAnalysisResult` gained `sleepSkinTemperatureResult` (check Gson/Codable JSON tolerance on the Flutter side). iOS `PolarOfflineRecordingData` gained `emptyData` case (app has `default:`). Android `LogConfig` import is dead, delete.

## Concurrency semantics to preserve exactly

1. `PolarSequentialQueue` (both platforms): strict FIFO, item N+1 does not start until N terminates (including `stopSleep`'s trailing 10s delay, PLR-53, which must stay inside the item); per-item errors swallowed; results replayed to late subscribers; `dispose()` cancels in-flight and fails pending with queue-disposed error; enqueue-while-inactive fails immediately. Port: Kotlin `Channel` + single worker + `CompletableDeferred` per item; Swift actor or AsyncStream worker + continuations.
2. Availability gates (7 on Android, 4 on iOS): completed by `bleSdkFeatureReady`, recreated on every disconnect (avoids `PolarNotificationNotEnabled` on reconnect). Port: fresh `CompletableDeferred`-style gate per connection; `gate.await()` before gated ops.
3. Retry/timeout policies, exact parity:
   - `doFirstTimeUse`: SYSTEM_BUSY only, up to 3 retries at 1s; on 4th, `doRestart` (errors swallowed) then propagate original error.
   - `withTimeoutAndRetry`: per-attempt 30s timeout, up to 3 attempts, linear backoff of attempt-seconds.
   - `getSleepRecordingState`: 4 attempts, 1s delay, fallback false (iOS: 3 retries then caught to false).
   - `removeOfflineRecording`: plain retry(5).
   - RSSI reads: 2s timeout per sample.
   - Swift needs a `withTimeout` race helper (no built-in).
4. Power-source debounce 10s: long-lived across connections, only torn down in `dispose()`. iOS additionally restarts setup on discharge.
5. Sync pipeline: setup chain strictly sequential (free space, time sync, tracing, USB, stop/start HR, stop/start PPI), then full recording list, cleanup, filter, then per-entry sequence: 100ms delay, download, save, 50ms delay, remove; per-entry failure skips the entry, never aborts the pipeline. Cancellation must reset sync status to None and clear `downloadInProgress` (port `doOnDispose`/`onDisposed` to `finally`/`onCompletion(cause)` that also runs on cancellation).
6. iOS download pipeline brackets every stage in `UIBackgroundTask`, re-arming a fresh one per recording. Must survive the rewrite.
7. Timers: Android 300s download interval, 1s foreground debounce; iOS same plus adaptive 30-min idle interval. Port to `delay` loops in owned scopes; iOS main-queue constraint disappears.
8. Disconnect teardown / reconnect re-arm: all per-connection jobs (setup, HR, ACC, FTU, wakeup, nightly recharge, download, pairing check, broadcasts) cancelled on disconnect, recreated on connect, dispose-before-recreate per handle.
9. Pairing check (iOS): race between feature-ready gate and 30s timer; timeout branch disconnects, reconnects, re-arms recursively.
10. Threading: SDK 8.0 delivers on its own dispatchers / cooperative pool, not the queue passed at construction. Everything crossing into Flutter (EventChannel/MethodChannel), UIApplication, WidgetKit must hop explicitly to main (`Dispatchers.Main` / `@MainActor`). Current code implicitly relied on MainScheduler in places.
11. Owned scopes replace fire-and-forget `subscribe()`: PolarClient needs an explicit `CoroutineScope` (Android) and Task registry (iOS); `RxJavaPlugins.setErrorHandler` becomes a `CoroutineExceptionHandler` on those scopes.
12. Rx types cross internal boundaries today and must become suspend/Flow/async end-to-end: `HeartRateListener.onHeartRateBatch(): Completable?`, `PpiListener.onPpiBatch(): Completable?` (implemented by DB clients), `BluetoothForegroundService` wrappers consumed by the plugin channel layer, `AndroidBondChecker`, iOS `HeartRateFetcher` subjects, `monitorEvents` ReplaySubject.

## New facade and event streams

- `sdkCall(op) { ... }`: logs start/ok/error with the operation name, maps to a unified `PolarError` taxonomy shared in naming across platforms. All SDK calls route through it. Streams get an analogous wrapper that logs start/completion/error around collection.
- Listener pairs → one events hub per platform: `MutableSharedFlow`/`AsyncStream` per event type (connection, battery, version, contact, sync state, disk space, monitor events, debug, errors), replacing `setXListener`/`reportX`/`restoreLastX`. Replay semantics made explicit where `restoreLastDeviceContact`-style behavior exists today (replay=1 for those).

## Work breakdown

1. Fork prep: decide tag +1 commit and OHR tooling questions; publish/tag final `8.0.0-visible`.
2. Deps bump: Android `com.github.makevisible:polar-ble-sdk:8.0.0-visible`; iOS podspec/Podfile tag bump; remove plugin-declared RxJava deps; delete RxSwift imports.
3. Verify PFTP cancellation-cooperativeness in SDK sources (blocker 5) before porting the queue.
4. Port shared infrastructure: facade, error taxonomy, event streams, `PolarSequentialQueue`, gates, timeout/retry helpers.
5. Port `PolarClient.kt` (mechanical sweep + nontrivial items above), then dependent Kotlin files (service, plugin, bond checker, DB clients, reporters).
6. Port `PolarClient.swift` and dependent Swift files (service, plugin, HeartRateFetcher, DB clients).
7. Compile green via android-build / ios-build agents; existing Dart tests green (Flutter contract unchanged except files-viewer one-shot list).
8. QA band matrix: Sense + 360, iOS + Android (including one API 28-32 device): FTU, morning measurement, overnight sleep + morning sync, firmware update, reconnect/power scenarios, files viewer, factory reset.
9. Dogfood week, then store release train.

## Port outcomes (2026-07-22)

Both platform ports and the fork PFTP patch are code-complete and build green (Android: `:app:compileTstDebugKotlin` + plugin unit tests 10/10; iOS: full `tst` scheme build, plugin Dart tests 27/27; SDK fork: library builds + PFTP tests 3/3 Android, 7/7 iOS).

Verified corrections to this spec discovered during the port:
- `PolarOfflineRecordingEntry.date` is device-folder wall-clock time with no zone conversion in the SDK (both at 6.13.2 and 8.0); convert with `ZoneId.systemDefault()`, NOT UTC. `PolarOfflineRecordingData.startTime` is genuinely UTC. `birthDate` epoch conversion uses system zone (parity with the old `Calendar` path).
- Spec-directed behavior change (deliberate, not parity): a `removeOfflineRecord` failure after its retries now skips that entry and continues the batch; the old Rx code aborted the remaining batch.
- The SDK library (upstream choice) compiles with Java 21 target: local Android builds need a JDK 21 daemon (`JAVA_HOME` override) or kapt stub generation fails reading class files. CI (codemagic) already runs `java: 21` everywhere, so this is a local-dev note only.
- CocoaPods parses `-visible` tags as pre-release versions; the plugin podspec therefore declares `PolarBleSdk` with no version constraint (the app Podfile's git tag pin is the real constraint).
- The JitPack `polar-ble-sdk:8.0.0-visible` artifact carries Kotlin 2.3.0 metadata: consumers need Kotlin 2.2.x+ to compile against it. The app already builds with 2.2.20; the plugin example app needed the same bump.
- The plugin example app (`packages/bluetooth_foreground_service/example`) is now a full manual-test harness covering the entire Dart API surface; useful for the band-matrix QA phase. It also has a Stress Test section (5 scenarios: connect/disconnect churn, operation flood with mid-burst disconnect, stream churn, service lifecycle churn with duplicate-delivery detection, seeded soak) with hang detection and per-op counters; smoke preset = seed 42, one tap.
- Known PRE-EXISTING hazard (identical in 6.13.2, not a migration regression, follow-up candidate): for methods with a single stored Job/Task per method in the plugin channel layer (dumpAllFiles, flushHeartRateBuffer, restartDevice, factoryResetDevice, getSleepRecordingState, stopSleep, getUserDeviceSettings, deleteSleepData), a second Dart call before the first resolves cancels the first invocation's handler without ever completing its MethodChannel.Result: the first Future is orphaned forever. The old Rx code disposed the previous subscription with the same effect. Daily-data fetchers are safe (independent launch per invocation). The stress test's operation-flood scenario surfaces this as noResponse counts.

## Adversarial review round (2026-07-22)

Both ports were adversarially reviewed against 6.13.2 old code; 27 findings total (4 blockers, 11 majors), all fixed and re-verified green. Recurring root causes worth remembering for future coroutine/async ports:
- Generic catch blocks swallowing CancellationException/CancellationError, letting cancelled tasks run to completion (setup/download pipelines, per-sample RSSI, sleep-state fallbacks).
- Kotlin TimeoutCancellationException IS-A CancellationException: rethrow-cancellation-first catch blocks mistake exhausted timeouts for cancellation. withTimeoutAndRetry now wraps the final timeout in plain PolarOperationTimeoutException.
- Zombie-task finally blocks running after a reconnect and clobbering the successor's state; fixed with generation guards + synchronous state reset at the cancel site.
- Swift FeatureGate.wait needed explicit cancellation cooperativity (a cancelled waiter parked forever, deadlocking the pairing-check task-group race).
- Service-layer flow collectors stacking on every start(); StateFlow conflation eating back-to-back status emissions (Error then Synchronized) that BehaviorSubject delivered.
- Events emitted during dispose() while subscribers were still attached (old code nil'ed listeners first).
- RSSI: public getRSSIValue() returns the cached advertisement RSSI (frozen once connected); live reads must go through session.readRssiValue().
- retry(5) on removeOfflineRecording is Android-only (iOS 6.13.2 never had it); the earlier spec text implied both.

## Resolved questions (2026-07-22)

1. `setLedConfig` no-op: delete the call.
2. Fork: final tag `8.0.0-visible` created at `a0ed129a` and pushed.
3. OHR example tooling omission: accepted, stays parked on `visible-ohr-tooling-6.16.4`.
4. iOS `readFile` nil: map to an error (file not found), matching the old PFTP error-on-missing behavior.
