# WageTrack

An iOS app for tracking work shifts and what they earn you – including tips, breaks and a live timer on the lock screen. Built with SwiftUI, SwiftData and ActivityKit.

The interface is in German.

## Features

- **Shifts** – record date, start, end, break, hourly wage and tip; edit or delete them later. Shifts that end after midnight are handled.
- **Live tracking** – start a shift with one tap and follow time and earnings in a Live Activity on the lock screen and in the Dynamic Island. The running shift survives the app being terminated; stopping it opens the form with the tracked times filled in.
- **Summary** – totals for wage and tips, average earnings per hour, this month, this year and the monthly average.
- **Monthly overview** – the list is grouped by month with earnings and tips per month.
- **Exclude shifts** – keep a shift in the list without counting it in the statistics.
- **CSV backup** – every change writes all shifts to a CSV file in the app's Documents folder, visible in the Files app.
- **Settings** – currency, default hourly wage, default break, and whether new shifts start from the values of the last one.

## Requirements

- Xcode 26 or later
- iOS 26.1 or later (Live Activities require an iPhone)

## Building

1. Open `WageTrack.xcodeproj` in Xcode.
2. Select your own team under *Signing & Capabilities* for the `WageTrack` and `WageTrackWidgetExtension` targets and, if needed, change the bundle identifiers.
3. Build and run the `WageTrack` scheme.

The background task identifier is derived from the bundle identifier, so nothing else needs to be adjusted.

## Project structure

| Path | Contents |
| --- | --- |
| `WageTrack/DataModels` | `Shift`, the SwiftData model |
| `WageTrack/Views` | Main list, forms for adding and editing shifts, settings |
| `WageTrack/Components` | Reusable views such as the summary tiles and the break picker |
| `WageTrack/LiveWidget` | Live tracking: shift state, Live Activity updates, background keep-alive |
| `WageTrack/Utils` | Settings, duration helpers, CSV export |
| `WageTrackWidget` | Widget extension that renders the Live Activity |
| `ShiftActivityAttributes.swift` | Live Activity data shared by app and extension |

## Live tracking and location

A Live Activity can only show values the app pushes to it, and iOS suspends apps shortly after they enter the background. To keep the earnings on the lock screen up to date, WageTrack can stay active during a running shift by receiving coarse location updates. The positions are never read, stored or sent anywhere.

This is optional: deny the location permission or turn the option off in the settings, and the timer keeps running while the earnings refresh whenever the app is opened.

## Data

All data stays on the device. There is no account, no server and no analytics.
