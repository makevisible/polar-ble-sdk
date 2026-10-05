# PFTP cancellation: 6.13.x vs 8.x-visible

Why it matters: when the band disconnects, the app cancels in-flight PFTP operations (file sync, sleep data, firmware) so they fail fast instead of hanging for the 90 s protocol timeout (900 s for sleep archives). Upstream 8.0 deleted the machinery that made this work. The fork restored it in `8.0.1-visible`; the status sections below say which parts upstream has since taken over.

## How it worked on 6.13.x (Rx)

- Cancellation = disposing the Rx chain.
- Android: each operation ran on its own thread; dispose interrupted that thread. The blocking waits threw InterruptedException, the handlers sent a cancel packet to the band, done.
- iOS: each operation was a BlockOperation; dispose called block.cancel(), and the condition waits checked the cancelled flag when they woke.
- The caller saw nothing: dispose was silent and instant.

## What broke on 8.0.0 (upstream Rx removal)

- Android: operations became suspend functions around the same blocking waits, but Job.cancel() never interrupts a blocked thread. Cancel did nothing: caller hung until the protocol timeout, transfer kept running, no cancel packet.
- iOS: Task.cancel() was never wired to block.cancel(). One-shot calls ignored cancel entirely. Worst case: a cancelled waitNotification left a zombie on the serial notification queue that swallowed every device notification until the next disconnect.

## How 8.0.1 fixes it

- Android: wrap the blocking bodies in runInterruptible. Job.cancel() becomes a thread interrupt again, and all the old 6.13.x interrupt handlers (including the cancel packet to the band) run unchanged.
- iOS: wire cancellation explicitly. One-shot calls get withTaskCancellationHandler, streams get onTermination. Both cancel the BlockOperation and signal the condition it is waiting on (cancelling alone never wakes an NSCondition). A ContinuationOnce guard makes resume exactly-once even in cancel races.
- Also fixed: the missing Task cancellation in the Combine bridge and in listOfflineRecordings.

## One behavior change to know about

- Old: cancellation was invisible to the caller.
- New: the caller gets CancellationException (Android) or operationCanceled / CancellationError (iOS). Any broad catch around a PFTP call must rethrow cancellation. This bug class produced 4 blockers in the app-port review.

## Bonus fixes beyond parity

- Android: disconnect during a response wait fails fast instead of stalling 90 s; the notification loop can no longer block forever holding its mutex after a disconnect race.
- iOS: request/write cancels wake their waits immediately (old code woke lazily); sendNotification is now actually cancelable (old code used a throwaway BlockOperation).

## Tests

- Android: cancelling a request that gets no device response unblocks in under 5 s (baseline: 90 s hang) and the scan stop/resume stays balanced.
- iOS: after cancelling a waitNotification consumer, a new consumer still receives notifications (proves the zombie fix). This test fails without the patch.
- Not covered by tests, verified by inspection only: the remaining cancel paths and the cancel packet actually reaching the band. Band QA covers those.

## Status at 8.3.0-visible

- Android: upstream 8.3.0 added its own disconnect fast-fail (a `disconnectSignal` deferred raced against every channel wait via `select`, completed exceptionally by `reset()`), so the fork's polling `receiveOrNullFailingFastOnDisconnect` is gone. The fork still wraps `waitNotificationEnabled` in `runInterruptible` on top of upstream's new 30 s timeout, so consumer cancellation keeps interrupting that wait.
- iOS: upstream 8.3.0 replaced the single-consumer `waitNotification` operation with a fan-out broadcast loop whose per-subscriber `onTermination` unsubscribes, which supersedes the fork's `onTermination` fix there. The fork keeps `withTaskCancellationHandler` + `ContinuationOnce` on `request`, `query`, `sendNotification` and `waitPsFtpReady`, `onTermination` on `write`, and the cancelable `transmitNotificationPacket`.
- Tests: the fork's `BlePsFtpClientTest` cases on both platforms live next to upstream's; both sets pass at 8.3.0-visible.

## Status at 8.4.0-visible

- Upstream 8.4.0 is a docs-and-tests release for the code the fork touches: the only source edits in fork-patched files are a `serializedBytes` → `serializedData` rename in `BlePsFtpClient.swift` and the Android `search()` flow rewritten from `callbackFlow`/`awaitClose` to `flow`/`try-finally` in `BDDeviceListenerImpl.kt` (the fork's log line moved into the `finally`). Every fork patch above carries over unchanged.

## Where

- Fork patches: commits `9d1dfa06` and `1b569393` (first shipped as `8.0.1-visible`), re-merged in `Merge upstream 8.3.0 into visible-fork`. Main files: `BlePsFtpClient.kt` + `BleGattBase.kt` (Android), `BlePsFtpClient.swift` + `AtomicList.swift` + `AsyncCombineHelpers.swift` + `PolarBleApiImpl.swift` (iOS), plus the tests.
- Old reference: branch `hotfix/6.13.2-visible`.
