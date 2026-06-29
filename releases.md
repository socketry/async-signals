# Releases

## Unreleased

  - Add `Async::Signals::Reset.trap` for signal traps restored by `Async::Signals.reset!`, including after fork.
  - Add `async/signals/graceful` to register graceful reset traps for `SIGINT` and `SIGTERM`.

## v0.5.0

  - Change `Async::Signals.default` to select process signal handling only on the main thread when no fiber scheduler is installed.

## v0.4.0

  - Use `Fiber::Scheduler#fiber_interrupt` from `Context#raise` when available, falling back to `Thread#raise`.

## v0.3.0

  - Pass the installing context as the second signal handler argument and allow handler exceptions to propagate.

## v0.2.0

  - Add `Async::Signals.default` and `Async::Signals::Ignore` for selecting process signal handling based on the current thread.

## v0.1.0

  - Initial release.
