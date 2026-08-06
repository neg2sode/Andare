# Andare

Finding the right pace in cycling, running and walking is hard: the human body doesn't naturally recognise its preferred cadence when the activity level changes or the terrain is unusual, and settling into a biased cadence over the long term can be genuinely harmful for people with persistent knee pain or muscular stress. Andare solves this by bringing sensor-based cadence measurement to the iPhone itself — no bike-mounted cadence sensor, no watch required — and wrapping it in a full workout app with health insights and data-driven statistics.

<img width="3000" height="2250" alt="andare_showcase" src="https://github.com/user-attachments/assets/34665887-57a2-4782-ba2d-25262da7f8a7" />

## The workout flow

1. **Pick a workout** — swipe the home carousel between Ride, Run and Walk (each with its own animated start-button shape), or tap a page-indicator dot in the drawer.
2. **First time per type: the guide** — a two-screen card flow explains where to place your phone for good gyro signal, warns about road safety, and requests the permissions the app actually needs, with live status rows and per-permission explanations.
3. **Countdown** — a 5-second countdown (tap anywhere to skip) prepares the HealthKit workout, location tracking and background execution, so you can lock the screen safely before you set off.
4. **Live workout** — big glanceable stats (cadence, speed *or* pace by type, calories, elevation, distance) in portrait and landscape. A Live Activity mirrors your preferred cadence on the Lock Screen and in the Dynamic Island. Swipe down for a "vibe" panel of three flowing gyroscope traces. Stopping requires a deliberate 1.5-second hold — accidental taps just nudge the button.
5. **Summary** — average-cadence hero card with a zone verdict and an icon that bounces at your actual cadence, a stat-card grid, a cadence-over-time chart coloured by zone, your route on a map (tap for full screen), and a debug-log section you can copy or email.
6. **History** — workouts persist on device and sync to Apple Health/Fitness. The drawer shows recent workouts, a weekly cadence verdict, and today's daylight/step counts.

## How cadence detection works

Andare derives cadence from the iPhone's gyroscope alone, using Accelerate/vDSP:

- **Sampling**: `CMGyroData` at **100 Hz** while a workout is active.
- **Segments**: every **512 samples (5.12 s)** the rotation signal is Hann-windowed and run through a radix-2 real FFT; the magnitude spectrum's dominant peak is searched **only inside the workout type's plausible cadence band**, and converted from Hz to RPM/SPM.
- **Sections**: every **8192 samples (81.92 s)** a longer FFT produces the *preferred cadence* — a stabler figure used by the Live Activity and notifications.
- **Power gate**: a per-type spectral power threshold rejects segments where no rhythmic motion is present (the "zero cadence" zone) rather than reporting noise.

Per-type tuning (`WorkoutType.cadenceInfo`):

| Type | Search band | Sound zone | Unit |
|---|---|---|---|
| Cycling | 20–150 RPM | 60–110 RPM | RPM |
| Running | 130–210 SPM | 160–200 SPM | SPM |
| Walking | 60–120 SPM | no cutoffs (any detected cadence is fine) | SPM |

The band bounds are behaviour, not just display: they clamp the FFT peak search and the chart axes. Zones are surfaced everywhere as **Low / Sound / High / Zero** with consistent colours.

Other measurements:

- **Elevation gain** from the barometer (`CMAltimeter` relative altitude).
- **Distance / speed / route** from Core Location (with the required coordinate transform for maps in China).
- **Calories** estimated from workout intensity and your body mass read from HealthKit (falling back to a default when unavailable), split into active and total.

## App tour

- **Home** — paging carousel with per-type sculpted start buttons (breathing animation, rotating hint text), countdown with lock-screen nudge, live stats overlay, long-press stop button.
- **Guide** (first run per workout type) — placement screen with animated phone-position checklist and risk warning, then a permissions screen with real status rows for Workouts (HealthKit), Location, and Motion & Fitness (hidden on devices without a barometer). Backing out doesn't burn your first-run guide.
- **Drawer** — a native SwiftUI sheet pinned at a 100 pt detent (background remains interactive) that expands to full height:
  - **Today** — real HealthKit read queries for Time in Daylight and Steps, with an honest em-dash when data is unreadable and an opt-in "Allow Health Access" prompt.
  - **Summary** — a weekly verdict card: >60 % of the week's workouts in the Sound zone earns "Sound Cadence", otherwise a gentle "Know Your Cadence" coaching card.
  - **Recent Workouts** — today/this-week windowing, cadence-led thumbnail cards with zone-coloured units and ↑/↓ hints, swipe to hide or delete (with confirmation), tap for the full summary.
  - **Articles** — in-app reading on cadence, consistency and technique.
  - **Contact Me** — rate, feedback mail, and links.
  - **Page indicator** — dots mirroring which workout the home carousel is showing.
- **Preferences** — unit system (metric / imperial / follow locale), profile (with Apple Health sync), notification toggles, and a permissions overview with live statuses.
- **Notifications** — optional local alerts for ride status and cadence guidance while the screen is off.
- **Live Activity** (`AndareWidgets` target) — Lock Screen banner plus Dynamic Island compact/expanded layouts showing elapsed time and preferred cadence.

## Requirements

- **iOS 18.2+** (app target; widget extension targets iOS 18.0).
- **A physical iPhone for anything sensor-related.** Simulators have no gyroscope (cadence never registers) and no barometer (no elevation, and the Motion & Fitness permission row hides itself). The UI, drawer, guide and summary flows all work in the simulator.
- Xcode 16+ (developed against Xcode 26 / iOS 26.5 SDK).
- An Apple Developer team for signing — HealthKit and Live Activities require real entitlements.

## Building

Open `Andare.xcodeproj`, select the `Andare` scheme, set your signing team, and run.

CLI equivalent (simulator):

```sh
xcodebuild -scheme Andare \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO build
```

The project uses filesystem-synchronised Xcode groups: adding or moving source files needs no `project.pbxproj` surgery. The one exception is target membership for shared files — `Models/WorkoutType.swift` is compiled into both the app and the widget extension.

## Testing

The UI-test suites double as scripted walkthroughs and capture screenshots at every step:

- `WorkoutFlowDiagnosticTests` — start → guide → permission grants (including the system HealthKit sheet and location alert) → countdown skip → live screen → gyro panel → hold-to-stop → summary.
- `DrawerSheetDiagnosticTests` — drawer detents, expand/collapse, background interaction.
- `PreferencesDiagnosticTests` — editable profile rows, keyboard toolbar, Apple Health sync indicator, notification info alerts.
- `ArticleLayoutDiagnosticTests` — asserts no article content is wider than the screen, which would turn the vertical scroll view into a two-axis one.

```sh
xcodebuild -scheme Andare \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  test
```

> **Warning:** never pass `CODE_SIGNING_ALLOWED=NO` to `xcodebuild test`. It strips the HealthKit entitlement from the test build, `requestAuthorization` fails silently, and the permission sheet never appears — the flow test then passes while quietly skipping the HealthKit path. Simulator test builds sign locally without any developer account, so just leave signing on.

Screenshots from a test run can be exported with:

```sh
xcodebuild ... -resultBundlePath results.xcresult test
xcrun xcresulttool export attachments --path results.xcresult --output-path shots/
```

## Project structure

```
Andare/
├── AndareApp.swift             # entry point; SwiftData container;
│                               #   haptic engine lifecycle
├── Managers/                   # long-lived services (mostly singletons)
│   ├── RideSessionManager.swift      # session orchestrator: HK workout builder,
│   │                                 #   location, motion, live activity, gyro stream
│   ├── MotionManager.swift           # 100 Hz gyro capture, FFT pipeline, altimeter
│   ├── LocationManager.swift         # Core Location auth + route tracking
│   ├── HealthKitManager.swift        # auth, workout saving, body metrics, Today queries
│   ├── MotionPermissionManager.swift # CMAltimeter-based Motion & Fitness auth
│   ├── NotificationManager.swift     # local notification auth + delivery
│   ├── AlertManager.swift            # app-wide alert presentation
│   └── VibrationManager.swift        # haptic patterns
├── Models/                     # value types & enums (WorkoutType, CadenceZone,
│                               #   PermissionStatus, UnitSystem, …)
├── Storage/                    # SwiftData models + plain-struct mirrors
│   ├── WorkoutDataModel.swift        # persisted workout (managementState:
│   │                                 #   visible / hidden / excluded)
│   ├── CadenceSegmentModel.swift     # per-segment cadence, zone, locations
│   └── WorkoutData.swift             # in-memory workout passed between views
├── Utilities/                  # formatters (units, pace), calories, coordinate
│                               #   transform, mail, logging
├── Views/
│   ├── Components/             # shared primitives: cardStyle, SummaryStatCard,
│   │                           #   PermissionRow, PrimaryButtonStyle, CardPressStyle,
│   │                           #   LongPressStopButton, SectionHeader
│   ├── Home/                   # carousel, start buttons, countdown, guide flow
│   ├── Session/                # live stats overlay + gyro panel, summary, full map
│   └── Drawer/                 # drawer sheet: Today, Summary, workouts, articles,
│                               #   preferences, page indicator
AndareWidgets/                  # Live Activity extension (Lock Screen + Dynamic Island)
AndareTests/                    # unit tests
AndareUITests/                  # diagnostic walkthrough suites (screenshots)
```

## Architecture notes

- **State machine**: the home screen runs on a single `SessionState` enum (`idle → guidePlacement → guidePermissions → countingDown → starting → active → summary → transitioning`), so exactly one flow view exists at a time.
- **Ownership**: shared singletons are observed with `@ObservedObject`; `@StateObject` is reserved for objects a view actually owns (e.g. `RideSessionManager` in `HomeView`).
- **Gated streaming**: the raw gyro feed for the live charts is published in 10-sample batches and only subscribed to while the panel is visible, the app is active, and the device is in portrait — the FFT pipeline itself never depends on the UI.
- **Persistence invariant**: `CadenceZone` raw values (e.g. `"Normal"`) are encoded inside persisted SwiftData records. UI copy goes through `displayName` (`"Sound"`); **never rename the raw values** or old workouts stop decoding.
- **Units**: everything is stored in SI (metres, m/s, kcal) and converted at display time by `StatsFormatter`, including the run/walk pace representation (`5'30" /KM`).
- **Alerts**: `AlertManager` keeps one host per presentation context (home, drawer, preferences sheet) because SwiftUI alerts must attach to the topmost presented context.
- **Notifications**: while the screen is off, the app can nudge you about low/high cadence, suggest pushing the bike on steep terrain, and ask whether you've finished; frequency and the finish-workout alert are configurable in Preferences.

## Permissions & privacy

| Permission | Why | Required? |
|---|---|---|
| HealthKit (share) | Save workouts, routes, cadence, energy; read body mass/height for calories | Yes, for saving workouts |
| HealthKit (read) | Today cards (Time in Daylight, Steps); profile sync | Optional |
| Location (when in use) | Distance, speed/pace, route map | Yes, for outdoor metrics |
| Motion & Fitness | Barometer elevation gain | Optional (elevation degrades without it) |
| Notifications | Ride status & cadence alerts with the screen off | Optional |

All workout data lives on device (SwiftData) and in your own Apple Health store. There is no server, no analytics, and no third-party SDK.

## License

MIT — see [LICENSE](LICENSE).

## About me

Hey! My name is neg2sode, and I'm an undergraduate student born & raised in Shanghai / studying in London. Aside from being a student, I'm also a passionate mountain biker who also spends time training on the road.

Dealing with knee pain has made me more aware of how critical proper cadence is during cycling, but I didn't want to rely on a physical cadence sensor for my bike, so Andare began as a personal project — born out of necessity and curiosity. After observing people in my community and speaking with my family and friends, I realised many people face similar challenges in maintaining a healthy cadence. So I started building Andare in a way that can benefit not just me, but others as well.

As a student with limited time, money and resources, I decided to share my work with the community. My hope is that it might not only inspire others, but perhaps open a door for me too — like publishing the app eventually.

Thanks for stopping and having a look.
