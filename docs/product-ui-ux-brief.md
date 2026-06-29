# ProcessKill Product and UI/UX Brief

## Product Summary

ProcessKill is a native macOS developer utility for managing local development processes. It helps developers see what is running on local ports, stop or restart those processes, and launch saved project commands without jumping between Terminal windows.

The app should feel like a lightweight local control center for development projects: fast, native, practical, and calm. It is not a deployment tool or a cloud dashboard. It is for everyday local development work.

## Core Problem

Developers often run many local projects and tools at the same time:

- Node, Vue, Vite, Next, Express, or similar apps on ports like `3000`, `5173`, `8080`
- Flutter apps and device/simulator commands
- .NET APIs and web apps
- Multiple terminals with long-running commands
- Forgotten processes occupying ports

The current workflow is fragmented:

- Use `lsof -i :3000` to find a PID
- Kill processes manually
- Search shell history for commands
- Open project folders manually
- Remember which command belongs to which project
- Restart projects by switching Terminal contexts

ProcessKill should make this easier by combining:

- Port inspection
- Process control
- Project command discovery
- Saved local project library
- Quick launch and restart actions

## Target User

The primary user is a developer working locally on macOS, especially someone who frequently switches between multiple projects.

Common project types:

- Node projects
- Vue projects
- Flutter projects
- .NET projects

Likely user habits:

- Runs projects from Terminal
- Uses local ports constantly
- Keeps several repos on disk
- Wants fast local actions instead of a complex IDE-like tool

## Product Goals

1. Make it obvious what is running on a given local port.
2. Let the user stop, start, and restart local processes quickly.
3. Let the user build a local library of project folders.
4. Detect available commands from project files.
5. Make command launching feel safer and less error-prone than typing from memory.
6. Support both a compact widget workflow and a larger dashboard workflow.
7. Keep the experience native, lightweight, and developer-focused.

## Non-Goals

ProcessKill should not become:

- A full terminal replacement
- A cloud deployment dashboard
- A Docker management platform
- A full IDE
- A complex process supervisor like PM2

It can later integrate with these things, but the core product should remain focused.

## Current App Capabilities

The current SwiftUI proof of concept already supports:

- Native macOS window
- Menu bar popover
- Port scan, defaulting to `3000`
- Process details:
  - PID
  - Parent PID
  - Command arguments
  - Working directory
  - Terminal/detached state
- Stop process
- Start command
- Restart command
- Save command and working directory per port
- Open `localhost:{port}`
- Local project library
- Add project folder
- Detect Node scripts from `package.json`
- Detect Vue projects from `package.json` dependencies
- Detect Flutter projects from `pubspec.yaml`
- Detect .NET projects from `.sln`, `.csproj`, and `.fsproj`

## Desired Product Shape

The app should have two complementary variations:

1. Compact Mode
2. Expanded Dashboard Mode

These should not feel like two different products. They should feel like two responsive presentations of the same tool.

## Variation 1: Compact Mode

Compact Mode is the quick utility surface. It should feel similar to a menu bar popover or small floating widget.

### Purpose

Use Compact Mode when the user wants to:

- Check a port quickly
- Stop something blocking a port
- Restart the current local dev server
- Pick a saved project and run a known command
- Keep a small always-available utility near the edge of the screen

### Layout

Suggested structure:

1. Header
   - App name: `ProcessKill`
   - Small status subtitle
   - Refresh button

2. Project Selector
   - Horizontal list of saved project chips
   - Add project button
   - Refresh project commands button
   - Remove project button

3. Command Suggestions
   - Horizontal command chips
   - Example: `dev`, `build`, `run`, `test`, `watch`
   - Clicking a command fills the runner

4. Port and Command Runner
   - Port input
   - Scan button
   - Start command field
   - Working directory field
   - Start / Restart / Stop buttons

5. Status Strip
   - Small colored status dot
   - Short status text

6. Listening Process Card
   - Shows what is running on the selected port
   - PID
   - Command
   - Working directory
   - Terminal/detached state

7. Footer
   - Open localhost

### Compact Mode Design Direction

The compact UI should be dense but not cramped.

Recommended feel:

- Native macOS utility
- Dark surface
- Clear controls
- Low visual noise
- Rounded corners no larger than 8px
- Monospace only for commands, ports, and paths
- Buttons should be obvious and compact
- Avoid marketing-style hero UI
- Avoid oversized cards

### Compact Mode Key Interactions

- User types `3000`, presses Enter, sees process.
- User clicks a project, clicks `dev`, clicks Start.
- User sees port is busy, clicks Stop.
- User changes command and the app remembers it for that port.
- User clicks Restart and the app stops the selected PID, then launches the saved command from the correct working directory.

## Variation 2: Expanded Dashboard Mode

Expanded Dashboard Mode is for managing multiple projects and running processes at once.

### Purpose

Use Expanded Mode when the user wants to:

- See all saved projects
- See multiple running local processes
- Manage several ports at once
- Compare commands across projects
- Keep a larger local development control center open

### Suggested Layout

The expanded layout should use three main regions:

1. Left Sidebar: Projects
2. Top Bar: Running Processes
3. Main Area: Selected Project and Command Runner

### Left Sidebar: Projects

The left sidebar should contain the saved local project library.

Project row information:

- Project name
- Project type badge:
  - Node
  - Vue
  - Flutter
  - .NET
- Folder path, truncated
- Optional running indicator if a known process is active
- Optional port indicator if known

Sidebar actions:

- Add folder
- Refresh selected project
- Remove selected project
- Search/filter projects

Sidebar behavior:

- Selecting a project updates the main area.
- Projects should be grouped or filterable by type later.
- The sidebar should support many projects without feeling crowded.

### Top Bar: Running Processes

The top bar should show currently relevant running local processes.

Initial implementation can show:

- Processes discovered by scanned ports
- Processes attached to saved project folders
- Recently started processes from the app

Future implementation could scan common dev ports:

- `3000`
- `3001`
- `4200`
- `5000`
- `5173`
- `5174`
- `8000`
- `8080`
- `9000`

Process chip information:

- Port
- Project or process name
- PID
- Status color

Process chip actions:

- Select
- Stop
- Restart
- Open localhost

Top bar behavior:

- Clicking a running process updates the main area to show detailed process controls.
- Processes should not dominate the UI; they are quick-glance controls.

### Main Area

The main area should show the selected project and command workflow.

Suggested sections:

1. Project Header
   - Project name
   - Project type
   - Folder path
   - Open folder action
   - Refresh commands action

2. Command Library
   - Detected commands from project files
   - User-saved custom commands
   - Favorite commands
   - Recent commands

3. Command Runner
   - Selected command
   - Working directory
   - Optional port field
   - Start button
   - Restart button
   - Stop button

4. Process Details
   - PID
   - Parent PID
   - Command arguments
   - Working directory
   - Terminal/detached state
   - Port
   - Open localhost

5. Output Preview, Future
   - Basic logs from commands launched by the app
   - Last few lines only
   - Not a full terminal replacement

### Expanded Mode Design Direction

The expanded app should feel like a practical developer dashboard.

Recommended feel:

- Calm and structured
- Sidebar-focused
- Dense but readable
- Fast scanning
- Clear status colors
- No decorative hero section
- No marketing cards
- No nested card-heavy layout

Layout inspiration:

- Native macOS utility apps
- Xcode organizer-style sidebars
- Raycast-style compact command affordances
- Table-plus-detail productivity apps

## Information Architecture

### Primary Objects

Project:

- ID
- Name
- Path
- Type
- Commands
- Favorite command, future
- Known ports, future

Command:

- ID
- Name
- Shell command
- Source
- Project ID
- Optional default port
- Optional environment variables, future

Process:

- PID
- Parent PID
- Command
- Args
- Port
- Working directory
- TTY state
- Running state

Port:

- Number
- Status
- Listening process
- Associated project, if known

## Project Detection Rules

### Node

Detect when folder contains:

- `package.json`

Read:

- `name`
- `scripts`
- `dependencies`
- `devDependencies`

Commands:

- Every `scripts` entry becomes `npm run {script}`
- Include `npm install`

### Vue

Detect as Vue when `package.json` contains:

- `vue` dependency
- `vue` dev dependency
- `@vitejs/plugin-vue` dev dependency

Commands:

- Same as Node
- Label project as Vue

### Flutter

Detect when folder contains:

- `pubspec.yaml`

Read:

- `name`

Commands:

- `flutter pub get`
- `flutter run`
- `flutter test`
- `flutter build macos`
- `flutter clean`

### .NET

Detect when folder contains:

- `.sln`
- `.csproj`
- `.fsproj`

Commands:

- `dotnet restore`
- `dotnet build`
- `dotnet run`
- `dotnet watch run`
- `dotnet test`

For project files:

- `dotnet run --project {file}`
- `dotnet watch --project {file}`

For solution files:

- Prefer solution-level restore/build/test
- Run command may need user refinement if the solution contains multiple runnable projects

## Future Detection Ideas

Python:

- `pyproject.toml`
- `requirements.txt`
- `manage.py`
- Commands:
  - `pip install -r requirements.txt`
  - `python manage.py runserver`
  - `pytest`

Rust:

- `Cargo.toml`
- Commands:
  - `cargo run`
  - `cargo test`
  - `cargo build`

Go:

- `go.mod`
- Commands:
  - `go run .`
  - `go test ./...`
  - `go build`

Docker:

- `docker-compose.yml`
- `compose.yaml`
- Commands:
  - `docker compose up`
  - `docker compose down`
  - `docker compose logs`

## Visual Design Principles

1. Native First
   The app should feel like a macOS utility, not a web dashboard.

2. Fast Scanning
   Users should immediately understand:
   - What project is selected
   - What command will run
   - What port is being inspected
   - What process is active

3. Safe Actions
   Stop and Restart are powerful actions. They should be visually clear and not too easy to trigger accidentally.

4. Compact Density
   This is a developer tool. It can be information-dense, but the layout should remain calm.

5. Commands Are First-Class
   Commands are not hidden settings. They are core objects in the UI.

6. Paths and Args Need Monospace
   Any command, path, PID, or port should use monospace styling where helpful.

7. Avoid Unnecessary Decoration
   No decorative blobs, oversized hero sections, or marketing-style layouts.

## Interaction Details

### Add Project

User clicks Add Project.

App opens folder picker.

After selecting folder:

- Detect project type
- Read available commands
- Save project locally
- Select project
- Populate working directory
- Optionally select first command

### Select Command

User clicks a command chip.

App should:

- Fill command field
- Set working directory to project path
- Save selection locally if needed

### Start

User clicks Start.

App should:

- Validate command exists
- Validate working directory exists
- Launch command using shell
- Update status
- Rescan port if a port is selected

### Stop

User clicks Stop.

App should:

- Stop selected process with `SIGTERM`
- Escalate to `SIGKILL` if still running
- Rescan port

### Restart

User clicks Restart.

App should:

- Stop selected process
- Launch selected command
- Rescan port

### Open Localhost

User clicks Open Localhost.

App should:

- Open `http://localhost:{port}`

## Important UX Questions

These are worth exploring in design:

1. Should Compact Mode and Expanded Mode be separate windows or one resizable window?
2. Should the menu bar popover always use Compact Mode?
3. Should the large dashboard have tabs or a single three-region layout?
4. How should risky actions like Stop and Restart be confirmed?
5. Should the app show live logs for commands it launches?
6. Should processes launched outside the app be visually different from processes launched by the app?
7. Should projects support custom user-added commands beyond detected ones?
8. Should ports be associated with projects and commands?

## Recommended MVP Roadmap

### Milestone 1: Strong Compact Mode

- Polish current compact UI
- Improve project command chips
- Add custom command save/edit
- Add known port per command
- Add better status states

### Milestone 2: Expanded Dashboard

- Add sidebar project list
- Add top running-process strip
- Add selected project detail view
- Add command library view
- Add process detail panel

### Milestone 3: Smarter Detection

- Add Python
- Add Rust
- Add Go
- Add Docker Compose
- Add common dev port scanning

### Milestone 4: macOS App Packaging

- App icon
- Signed `.app`
- Launch at login
- Better menu bar behavior
- App settings

## Success Criteria

The app is successful if a developer can:

- Add a repo folder once
- See the commands available for that repo
- Start the right command without remembering it
- Check whether the expected port is running
- Stop or restart the process quickly
- Repeat this across many projects without opening multiple terminals

The app should make local development feel less scattered.
