# Async::Signals

Composable process signal handling for Ruby.

[![Development Status](https://github.com/socketry/async-signals/workflows/Test/badge.svg)](https://github.com/socketry/async-signals/actions?workflow=Test)

## Features

  - Coordinates process-wide signal traps across multiple consumers.
  - Supports overlapping signal handlers without replacing each other.
  - Supports scoped ignore handlers for specific signals.
  - Provides a no-op signal backend for components that should not install process signal traps.
  - Restores previous signal traps when handlers are removed.
  - Resets inherited signal state in forked children on Ruby implementations with `Process._fork`.
  - Documents thread-safe signal handler design for portable signal delivery.

## Usage

Please see the [project documentation](https://socketry.github.io/async-signals/) for more details.

  - [Getting Started](https://socketry.github.io/async-signals/guides/getting-started/index) - This guide explains how to get started with `async-signals`.

## Releases

Please see the [project releases](https://socketry.github.io/async-signals/releases/index) for all releases.

### v0.6.0

  - Add `async/signals/graceful` for installing default `SIGINT` and `SIGTERM` handlers that raise `Interrupt`.

### v0.5.0

  - Change `Async::Signals.default` to select process signal handling only on the main thread when no fiber scheduler is installed.

### v0.4.0

  - Use `Fiber::Scheduler#fiber_interrupt` from `Context#raise` when available, falling back to `Thread#raise`.

### v0.3.0

  - Pass the installing context as the second signal handler argument and allow handler exceptions to propagate.

### v0.2.0

  - Add `Async::Signals.default` and `Async::Signals::Ignore` for selecting process signal handling based on the current thread.

### v0.1.0

  - Initial release.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Running Tests

To run the test suite:

``` shell
bundle exec sus
```

### Making Releases

To make a new release:

``` shell
bundle exec bake gem:release:patch # or minor or major
```

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
