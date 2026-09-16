# Sitewire Coding Challenge

A native iOS app that displays user profiles and login history while remaining responsive against an intentionally unreliable API.

## Requirements

- Xcode 16.0+
- iOS 17.0+
- Swift 6.0

## Run the app

1. Open `SitewireChallenge/SitewireChallenge.xcodeproj`.
2. Select an iOS simulator.
3. Build and run with **⌘R**.

In debug builds, use the globe button in the navigation bar to switch between live and mock data.

## Features

- Displays each user's ID, name, email, last login time, and IP address
- Shows the total number of users
- Formats login times as relative dates
- Highlights users who have been inactive for more than one month
- Loads login history progressively instead of blocking the entire list
- Reports loading progress as each user is updated
- Retries transient API failures with exponential backoff
- Preserves partial results when an individual login-history request fails

## Architecture

The project separates presentation, application state, and networking into three layers:


- **SwiftUI + The Composable Architecture** manage presentation, state, and side effects.
- **UserStore** translates SDK events into app-facing models.
- **SitewireUserSDK** owns API access, retry behavior, streaming, and transport models.

The SDK is a separate Swift package so its networking behavior can be tested independently and reused by other targets.

## Data loading

Loading happens in two phases:

1. Fetch the user list and display it immediately.
2. Fetch login histories concurrently and update each row as its request completes.

This keeps the interface useful during the API's simulated delays. A failed login-history request affects only that user; the rest of the list continues loading.

Transient network errors and `5xx` responses are retried up to three total attempts with delays of 100 ms and 200 ms. Client errors and decoding failures are not retried.

## Testing

The test suites cover:

- TCA actions and state transitions
- Streaming and partial-failure behavior
- Retry rules and API error mapping
- Model decoding and computed properties

Run the app tests in Xcode with **⌘U**, or from the command line:

```bash
xcodebuild test \
  -scheme SitewireChallenge \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Run the package tests with:

```bash
cd SitewireUserSDK
swift test
```

## Logging

The app uses Apple's unified logging system. In Console.app, filter by:

- `subsystem:com.sitewire.challenge` for app events
- `subsystem:com.sitewire.sdk` for SDK and network events
