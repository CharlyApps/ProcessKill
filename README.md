# ProcessKill
<img width="1024" height="1024" alt="App Icon" src="https://github.com/user-attachments/assets/f745633d-49a1-4912-bc4d-56dee7c26fb8" />

A small native macOS SwiftUI utility for checking what is listening on a local port and managing it from one compact window or menu bar popover.

## Run

```sh
swift run ProcessKill
```

## Build a macOS app

```sh
./scripts/build_app.sh
open dist/ProcessKill.app
```

The app bundle runs independently from Terminal, so closing the shell will not close ProcessKill.

The build script also attaches the Dock/Finder icon from `assets/ProcessKillIcon.png`.

## Release build

For a local GitHub release artifact:

```sh
swift test
./scripts/build_app.sh
ditto -c -k --keepParent dist/ProcessKill.app dist/ProcessKill.app.zip
```

Upload `dist/ProcessKill.app.zip` to the GitHub Release. The `dist/` folder is generated output and should not be committed.

The current build script creates an ad-hoc signed app bundle. That is fine for personal use, but macOS Gatekeeper may warn on another machine because the app is not Developer ID signed or notarized yet.

## Font size

ProcessKill has a persisted app-wide font size preference.

- Open macOS Settings for the app to use the slider
- Use `Cmd` + `+` to increase font size
- Use `Cmd` + `-` to decrease font size
- Use `Cmd` + `0` to reset

## Current features

- Save a local project library
- Add project folders with `package.json` or `pubspec.yaml`
- Detect Node scripts from `package.json`
- Label Vue projects when `package.json` includes Vue dependencies
- Suggest Flutter workflow commands from `pubspec.yaml`
- Detect .NET projects and solutions from `.sln`, `.csproj`, and `.fsproj`
- Click a detected command to fill the runner and working directory
- Add manual project command templates with placeholders like `{{tenant}}`
- Fill template parameters from the UI before running commands
- Scan a local TCP port, defaulting to `3000`
- Show the listening process, PID, parent PID, command arguments, cwd, and Terminal attachment state
- Stop the selected process with `SIGTERM`, escalating to `SIGKILL` if needed
- Save a start command and working directory per port
- Start or restart the command from the saved working directory
- Open `http://localhost:{port}`
- Use either the floating window or the menu bar popover
- Use Compact Mode from the menu bar for quick actions
- Use Dashboard Mode from the main app window for a larger project/process command center
- Compact Mode follows the command-first menu bar design
- Dashboard Mode uses the wide sidebar plus two-column runner/details design
- Store preferred ports per project and suggest the next free port when a selected port is occupied by another project
- Assign projects to local groups and collapse/expand them in the dashboard sidebar
- Show a live command console with stdout, stderr, and process exit status after starting or restarting commands
- Re-scan ports when a launched command exits so failed launches do not leave stale running state

## Test

```sh
swift test
```

## Manual Command Templates

Manual commands are saved on the selected project. Use `{{name}}` placeholders for values that change per run.

Example:

```sh
npm run migrate -- --tenant {{tenant}} --direction {{direction}}
```

When selected, ProcessKill shows fields for `tenant` and `direction`, then fills the final command in the runner.

## Release notes for future packaging

- `scripts/build_app.sh` owns the `.app` bundle layout, `Info.plist`, icon generation, and ad-hoc signing.
- Update `CFBundleShortVersionString` and `CFBundleVersion` in `scripts/build_app.sh` before cutting a tagged release.
- Keep `assets/ProcessKillIcon.png` committed; the `.icns` file is generated during packaging.
- A public release should eventually use Developer ID signing and notarization instead of ad-hoc signing.
# ProcessKill
