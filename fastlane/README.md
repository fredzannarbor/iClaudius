fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac build_dev

```sh
[bundle exec] fastlane mac build_dev
```

Build for local development (no sandbox)

### mac build_release

```sh
[bundle exec] fastlane mac build_release
```

Build and archive for App Store submission

### mac upload_testflight

```sh
[bundle exec] fastlane mac upload_testflight
```

Upload to App Store Connect (TestFlight)

### mac upload_appstore

```sh
[bundle exec] fastlane mac upload_appstore
```

Upload to App Store for review

### mac build_dmg

```sh
[bundle exec] fastlane mac build_dmg
```

Build for direct distribution (notarized DMG)

### mac test

```sh
[bundle exec] fastlane mac test
```

Run tests

### mac screenshots

```sh
[bundle exec] fastlane mac screenshots
```

Take screenshots for App Store

### mac sync_certs

```sh
[bundle exec] fastlane mac sync_certs
```

Sync code signing certificates

### mac bump_version

```sh
[bundle exec] fastlane mac bump_version
```

Bump version number

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
