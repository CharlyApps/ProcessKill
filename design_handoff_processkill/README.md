# Handoff: ProcessKill — Compact Mode (B) + Dashboard Mode (B)

## Overview

ProcessKill is a native macOS developer utility for managing local development processes. It lets
developers see what is running on local ports, stop or restart those processes, and launch saved
project commands without switching Terminal windows.

This handoff covers two preferred UI directions selected from the design exploration:

- **Compact Mode B — "Command-First"**: A floating window / menu-bar popover. ~480 px wide,
  auto height. The command list is the hero element — the user picks a command, then runs it.
- **Dashboard Mode B — "Wide Sidebar + Two-Column Main"**: The full main-window view. Wide
  sidebar holds projects + running processes; the main area is split into a command-list column
  and a runner/details column.

---

## About the Design Files

`ProcessKill_design_reference.html` is an **HTML design prototype** — a high-fidelity visual
mock created to communicate look, layout, spacing, colors, and interactions. It is **not**
production code to copy directly.

Your task is to **recreate these designs in the existing SwiftUI codebase**, using SwiftUI
idioms and the app's existing architecture. Treat every hex value, spacing measurement, and
interaction note below as a precise specification.

---

## Fidelity

**High-fidelity.** Colors, typography, spacing, border radii, shadows, and interactions are all
specified precisely. Implement pixel-for-pixel where SwiftUI allows. The prototype uses the
system sans-serif font (`-apple-system`), which maps directly to `.systemFont` / `SF Pro` in
SwiftUI.

---

## Design Tokens

### Color Palette — Dark Purple System

All colors are derived from the Go1 brand palette, dark-adapted for a native utility aesthetic.

```
--pk-bg-deepest:   #0A0818   Window chrome, title bars, deepest surface
--pk-bg-main:      #121024   Main window body
--pk-bg-section:   #181330   Section/card backgrounds
--pk-bg-input:     #1F1B3C   Input fields, inactive chips
--pk-bg-selected:  #292147   Selected chip hover background
--pk-bg-sidebar:   #0A0816   Sidebar background
--pk-bg-deep2:     #0D0A1C   Secondary deep surface (Dashboard B body)

--pk-text-primary:   #ECE5F7   Primary text (near-white, purple-tinted)
--pk-text-secondary: #9790B2   Secondary / supporting text
--pk-text-muted:     #5A5272   Labels, section headers, placeholder text

--pk-cyan:    #00B4DA   Scan button, active port, links, Open localhost
--pk-teal:    #5EDFD0   Start button, active project chip, selected command accent
--pk-purple:  #7A5CF0   Type badges (custom), badge pill count
--pk-red:     #E53834   Stop button
--pk-orange:  #FF7043   Restart button
--pk-green:   #28BF7D   Running status dot
```

### Border Values

```
Border default:    1px solid rgba(91, 60, 196, 0.16)
Border normal:     1px solid rgba(91, 60, 196, 0.22)
Border selected:   1px solid rgba(91, 60, 196, 0.32)
Border active:     1px solid rgba(0, 180, 218, 0.40)    ← focused inputs, hero command
Border running:    1px solid rgba(40, 191, 125, 0.20)   ← running process cards
Border teal chip:  1px solid rgba(94, 223, 208, 0.28)   ← Flutter badge, selected chip
Border divider:    1px solid rgba(91, 60, 196, 0.12)    ← sidebar rule, section rule
```

### Project Type Badge Colors

```
Flutter:  text #5EDFD0  bg rgba(94,223,208,0.12)   border rgba(94,223,208,0.28)
Node:     text #7A5CF0  bg rgba(122,92,240,0.12)   border rgba(122,92,240,0.22)
.NET:     text #00B4DA  bg rgba(0,180,218,0.10)    border rgba(0,180,218,0.22)
Vue:      text #7A5CF0  bg rgba(122,92,240,0.12)   border rgba(122,92,240,0.22)  (same as Node)
```

### Typography

```
Sans-serif:  SF Pro Text / SF Pro Display  (.systemFont in SwiftUI)
Monospace:   SF Mono                       (.monospacedSystemFont in SwiftUI)

Section header labels:   9–10px  weight 600  uppercase  letter-spacing +1.1px  color --pk-text-muted
Primary text:            12–13px weight 400–600                                color --pk-text-primary
Secondary text:          11–12px weight 400                                    color --pk-text-secondary
Monospace fields:        11–13px weight 400–500                                color varies (see below)
App title:               19–20px weight 700  letter-spacing -0.4px             color --pk-text-primary
Type badges:             9px     weight 600  uppercase  letter-spacing +0.4px
```

### Corner Radii

```
Window:          12px  (outer NSWindow / popover container)
Section card:     8px
Input field:      6px
Command chip:     5px
Project chip:     7px
Type badge:       3px
Icon buttons:     4px
Pill badge:     999px
```

### Shadows

```
Compact window:    0 24px 80px rgba(0,0,0,0.88), 0 0 0 1px rgba(91,60,196,0.28)
Dashboard window:  0 24px 80px rgba(0,0,0,0.80), 0 0 0 1px rgba(91,60,196,0.25)
```

### Running Dot Animation

```
Name:       pkPulse
Keyframes:  opacity 1 → 0.25 → 1
Duration:   2s
Easing:     ease-in-out
Repeat:     infinite
Apply to:   any 6–7px green circle where a process is actively running
```

---

## Screen 1: Compact Mode B — "Command-First"

### Purpose

This is the menu-bar popover / floating utility window. The user opens it to quickly pick a
project, select a command, and run it — or to stop/restart a running process.

### Window

```
Width:           480pt
Height:          Auto (content-driven, approximately 480–520pt with 5 commands)
Background:      #0A0818
Border-radius:   12pt
Shadow:          see Shadows above
Overflow:        clip (hidden)
```

### Layout (top to bottom)

---

#### 1. macOS Traffic Lights

```
Height:     36pt (including padding)
Padding:    12pt top, 16pt horizontal, 8pt bottom
Layout:     HStack, spacing 7pt
Circles:    12×12pt, corner-radius 6pt
Colors:     Close #FF5F56 · Minimize #FFBD2E · Zoom #27C93F
Note:       These are decorative in the design — connect to real NSWindow controls in SwiftUI
```

---

#### 2. Project Selector Bar

```
Background:   #181330
Border:       1px solid rgba(91,60,196,0.22)
Corner-radius: 8pt
Padding:      8pt vertical, 12pt horizontal
Margin:       4pt top, 12pt horizontal

Layout: HStack justify-between
  Left side (HStack spacing 8pt):
    - Running dot: 7×7pt circle, #28BF7D, pkPulse animation when running
                   #5A5272 when idle
    - Project name: 13pt SF Pro, weight 700, color #ECE5F7
    - Type badge:   see Badge spec below

  Right side (HStack spacing 8pt):
    - Port:         12pt SF Mono, weight 500, color #00B4DA  (e.g. ":3000")
    - Chevron:      "▾"  11pt, color #5A5272

Tap action: opens project picker / sheet to switch active project
```

---

#### 3. Hero Command Input

```
Background:    #181330
Border:        1px solid rgba(0,180,218,0.40)    ← cyan, always — not just on focus
Corner-radius: 8pt
Padding:       10pt vertical, 12pt horizontal
Margin:        8pt top, 12pt horizontal

Layout: HStack spacing 8pt
  - Search glyph:  "⌕"  15pt, color #5A5272
  - Command text:  13pt SF Mono, weight 400, color #ECE5F7  (editable NSTextField / TextField)
  - Hint badge:    background rgba(91,60,196,0.14), corner-radius 3pt, padding 2pt 7pt
                   text "↵ {commandName}"  9pt weight 600, color #5A5272

Behavior:
  - Populated by tapping a command row below
  - Also directly editable (user can type a custom command)
  - Pressing Return executes Start action
  - The hint badge shows the name of the currently selected command
```

---

#### 4. Command List

```
Margin:        6pt top, 12pt horizontal
Border:        1px solid rgba(91,60,196,0.16)
Corner-radius: 8pt
Overflow:      clip

Each row is a full-width tappable item. Two visual states:

SELECTED ROW:
  Background:    #1F1B3C
  Left accent:   2pt solid #5EDFD0  (leading edge)
  Padding:       8pt vertical, 12pt horizontal, 10pt leading (after accent bar)
  Layout: HStack justify-between
    Left (HStack spacing 9pt):
      - Play icon: "▶"  10pt, color #5EDFD0
      - VStack:
          Name:    12pt SF Pro, weight 600, color #ECE5F7
          Command: 10pt SF Mono, weight 400, color #5EDFD0, top-offset 3pt
    Right:
      - Return badge: background rgba(91,60,196,0.14), corner-radius 3pt
                      padding 2pt 7pt, "⏎"  10pt weight 600, color #5A5272

UNSELECTED ROW:
  Background:    #121024
  Top border:    1px solid rgba(91,60,196,0.10)
  Padding:       7pt vertical, 12pt right, 23pt left
  Layout: VStack align-leading spacing 3pt
    Name:    12pt SF Pro, weight 400, color #9790B2
    Command: 10pt SF Mono, weight 400, color #5A5272
```

---

#### 5. Working Directory Strip

```
Background:    #181330
Corner-radius: 6pt
Padding:       7pt vertical, 12pt horizontal
Margin:        6pt top, 12pt horizontal

Layout: HStack spacing 8pt
  - "DIR" label:  9pt SF Pro, weight 600, uppercase, letter-spacing 1pt, color #5A5272
  - Path text:    10pt SF Mono, weight 400, color #9790B2
                  truncated with ellipsis at tail, single line
```

---

#### 6. Action Buttons

```
Margin:      6pt top, 12pt horizontal, 10pt bottom
Layout:      3-column equal grid, gap 6pt

START:
  Background:  #5EDFD0
  Text:        "▶ Start"  12pt SF Pro, weight 700, color #0A0818
  Height:      ~36pt (padding 10pt)
  Corner-radius: 6pt

RESTART:
  Background:  #FF7043
  Text:        "Restart"  12pt SF Pro, weight 700, color #FFFFFF
  Height:      ~36pt
  Corner-radius: 6pt

STOP (default state):
  Background:  #E53834
  Text:        "Stop"  12pt SF Pro, weight 700, color #FFFFFF
  Height:      ~36pt
  Corner-radius: 6pt

STOP (confirm state — see Interactions):
  Background:  #E53834  (same)
  Text:        "Confirm?"  11pt SF Pro, weight 700, color #FFFFFF
  Height:      ~36pt
  Corner-radius: 6pt
```

---

#### 7. Status Bar

```
Top border:   1px solid rgba(91,60,196,0.14)
Padding:      9pt vertical, 16pt horizontal

Layout: HStack justify-between
  Left (HStack spacing 7pt):
    - Status dot:  6×6pt circle
                   color #5A5272 when idle / port free
                   color #28BF7D + pkPulse when process running on port
    - Status text: 11pt SF Pro, weight 400, color #9790B2
                   Examples: "Port 3000 is free." / "npm run dev is listening."

  Right:
    - "↗ localhost" link: 11pt SF Pro, weight 500, color #00B4DA
    - Tapping opens http://localhost:{port} in Safari
    - Hidden / disabled when no port is selected
```

---

## Screen 2: Dashboard Mode B — "Wide Sidebar + Two-Column Main"

### Purpose

The full main-window experience. The user manages multiple projects, sees all running processes,
browses a command list, and runs or stops processes — all without leaving the window.

### Window

```
Width:         Full window (minimum ~1100pt recommended)
Height:        Full window (minimum 700pt recommended)
Background:    #0D0A1C
Border-radius: 12pt (or use standard NSWindow rounding)
Shadow:        see Shadows above
```

### Layout

```
VStack:
  Title Bar (44pt fixed)
  HStack (flex 1, overflow hidden):
    Wide Sidebar (280pt fixed width)
    Main Area (flex 1):
      HStack:
        Command List Column (350pt fixed width)
        Runner + Details Column (flex 1)
```

---

#### Title Bar (44pt)

```
Background:   #0A0818
Bottom border: 1px solid rgba(91,60,196,0.14)
Padding:      0 16pt horizontal
Layout:       HStack spacing 12pt, vertically centered

  - Traffic lights (see Compact spec above)
  - App name: "ProcessKill"  13pt SF Pro, weight 700, color #ECE5F7, letter-spacing -0.2pt
  - Search bar (flex, max-width 360pt, centered):
      Background:    #181330
      Border:        1px solid rgba(91,60,196,0.20)
      Corner-radius: 6pt
      Padding:       6pt vertical, 10pt horizontal
      Content:       "⌕" glyph + placeholder "Search projects, commands…"
                     11pt SF Pro, color #5A5272
  - "Compact ↗" ghost button (trailing):
      Background:    rgba(91,60,196,0.10)
      Border:        1px solid rgba(91,60,196,0.20)
      Corner-radius: 5pt
      Padding:       5pt vertical, 9pt horizontal
      Text:          10pt SF Pro, weight 600, color #9790B2
      Action:        Switches window to Compact Mode
```

---

#### Wide Sidebar (280pt)

```
Background:    #0A0816
Right border:  1px solid rgba(91,60,196,0.12)
Layout:        VStack

  ── PROJECTS section (flex 1) ──────────────────────────────────

  Header (padding 12pt top+horizontal, 8pt bottom):
    Layout: HStack justify-between
      - "PROJECTS" label: 10pt, weight 600, uppercase, letter-spacing 1.1pt, color #5A5272
      - "+ Add" button:
          Background:    rgba(91,60,196,0.10)
          Border:        1px solid rgba(91,60,196,0.20)
          Corner-radius: 4pt
          Padding:       3pt vertical, 8pt horizontal
          Text:          10pt weight 600, color #9790B2

  Project list (scrollable, padding 0 8pt 8pt):
    See Project Row spec below.

  Bottom border: 1px solid rgba(91,60,196,0.12)

  ── RUNNING section (fixed, padding 10pt 12pt) ──────────────────

  "RUNNING" label: 10pt, weight 600, uppercase, letter-spacing 1.1pt, color #5A5272
  Bottom margin: 8pt

  Running Process Card:
    Background:    #181330
    Border:        1px solid rgba(40,191,125,0.20)   ← stronger when actively running
    Corner-radius: 6pt
    Padding:       8pt 10pt
    Bottom margin: 5pt

    Row 1 (HStack justify-between):
      Left (HStack spacing 6pt):
        - Running dot: 6×6pt circle, #28BF7D, pkPulse animation
        - Command name: 11pt SF Pro, weight 600, color #ECE5F7
      Right (HStack spacing 3pt):
        - Restart icon button: "↺"  9pt weight 600, color #9790B2
                                background rgba(91,60,196,0.10), corner-radius 3pt, padding 2pt 5pt
        - Stop icon button:    "■"  9pt weight 600, color #E53834
                                background rgba(229,56,52,0.10), corner-radius 3pt, padding 2pt 5pt

    Row 2 (HStack spacing 8pt, top margin 4pt):
      - Port:    10pt SF Mono, weight 500, color #00B4DA  (e.g. ":3000")
      - PID:     10pt SF Pro,  weight 400, color #5A5272  (e.g. "PID 12847")
      - Project: 10pt SF Pro,  weight 400, color #5A5272  (e.g. "wolves-den-bjj")
```

---

#### Project Row (used in both sidebar and compact project selector list)

```
SELECTED state:
  Background:    #1F1B3C
  Corner-radius: 6–7pt
  Padding:       8pt 10pt
  Bottom margin: 3pt
  Layout: HStack justify-between
    Left VStack spacing 4pt:
      - Name:   12pt SF Pro, weight 700, color #ECE5F7
      - HStack spacing 5pt: Type badge + running dot + port (if running)
    Right:
      - "›" chevron: 14pt, color #5A5272

UNSELECTED state:
  Background:    transparent (or very subtle hover: rgba(91,60,196,0.06))
  Corner-radius: 6pt
  Padding:       8pt 10pt
  Bottom margin: 3pt
  Layout: same as selected but name is weight 600, color #9790B2, no chevron
```

---

#### Command List Column (350pt)

```
Right border: 1px solid rgba(91,60,196,0.12)
Layout: VStack

  ── Column Header ───────────────────────────────────────────────
  Padding: 14pt top+horizontal, 10pt bottom
  Bottom border: 1px solid rgba(91,60,196,0.10)
  Content:
    Row 1 (HStack spacing 7pt):
      - Project name: 16pt SF Pro, weight 700, color #ECE5F7, letter-spacing -0.3pt
      - Type badge (see Badge spec)
    Row 2 (top margin 4pt):
      - Path: 10pt SF Mono, color #5A5272

  ── Table Header ────────────────────────────────────────────────
  Background:    #0D0A1C
  Padding:       7pt vertical, 14pt horizontal
  Bottom border: 1px solid rgba(91,60,196,0.10)
  Grid: 2 columns — 80pt | flex
    "NAME"    9pt weight 600 uppercase letter-spacing 0.8pt color #5A5272
    "COMMAND" 9pt weight 600 uppercase letter-spacing 0.8pt color #5A5272

  ── Command Rows ────────────────────────────────────────────────
  SELECTED row:
    Background:     #1F1B3C
    Leading accent: 2pt solid #5EDFD0
    Padding:        9pt vertical, 12pt horizontal
    Grid: 2 columns — 80pt | flex
      Name:    12pt SF Pro, weight 700, color #ECE5F7
      Command: 11pt SF Mono, weight 400, color #5EDFD0
               truncated, single line

  UNSELECTED row:
    Background:     clear
    Top border:     1px solid rgba(91,60,196,0.08)
    Padding:        9pt vertical, 12pt right, 14pt left
    Grid: 2 columns — 80pt | flex
      Name:    12pt SF Pro, weight 400, color #9790B2
      Command: 11pt SF Mono, weight 400, color #5A5272
               truncated, single line

  ── Add Custom row ──────────────────────────────────────────────
  Top border: 1px solid rgba(91,60,196,0.08)
  Padding: 9pt vertical, 12pt right, 14pt left
  Text: "＋ Add custom command"  11pt SF Pro, weight 400, color #7A5CF0
  Action: opens inline edit or sheet to add a new command
```

---

#### Runner + Details Column (flex 1)

```
Padding:   14pt all sides
Layout:    VStack spacing 12pt, scrollable

  ── Runner Card ─────────────────────────────────────────────────
  Background:    #181330
  Corner-radius: 8pt
  Padding:       12pt

  Section label: "RUNNER"  10pt weight 600 uppercase letter-spacing 1.1pt color #5A5272
  Bottom margin: 10pt

  COMMAND field:
    Field label: "COMMAND"  9pt weight 600 uppercase letter-spacing 0.8pt color #5A5272
    Bottom margin label: 5pt
    Field: Background #1F1B3C, border rgba(0,180,218,0.35), corner-radius 6pt
           Padding 8pt 10pt, 12pt SF Mono weight 400, color #ECE5F7

  PORT + STATUS (2-column equal grid, gap 8pt, top margin 8pt):
    PORT:
      Label: "PORT"  same as COMMAND label style
      Field: Background #1F1B3C, border rgba(91,60,196,0.25), corner-radius 6pt
             Padding 8pt 10pt, 12pt SF Mono weight 500, color #00B4DA
    STATUS:
      Label: "STATUS"  same style
      Field: Background #1F1B3C, border rgba(40,191,125,0.25), corner-radius 6pt
             Padding 8pt 10pt
             HStack spacing 6pt:
               - 6×6pt circle, #28BF7D, pkPulse when running; #5A5272 when idle
               - "Running" / "Idle"  11pt weight 500, color #28BF7D / #5A5272

  WORKING DIRECTORY (top margin 8pt):
    Label + field as above
    Field text: 11pt SF Mono, color #9790B2, truncated

  Action Buttons (3-column grid, gap 6pt, top margin 10pt):
    See Compact Mode action button spec — identical sizing and colors.

  ── Process Details Card ─────────────────────────────────────────
  Background:    #181330
  Corner-radius: 8pt
  Padding:       12pt

  Section label: "PROCESS DETAILS"  same style as above

  2-column equal grid (gap 10pt, bottom margin 10pt):
    PID field:
      Label "PID", value: 14pt SF Mono weight 500, color #ECE5F7
    PPID field:
      Label "PPID", value: 14pt SF Mono weight 500, color #9790B2

  COMMAND ARGS:
    Label "COMMAND ARGS"
    Value box: Background #1F1B3C, corner-radius 5pt, padding 7pt 9pt
               10pt SF Mono weight 400, color #9790B2, line-height 1.5

  Top-rule separator (top margin 10pt): 1px solid rgba(91,60,196,0.10)
  "↗ Open localhost:5173" link trailing-aligned, 11pt weight 500, color #00B4DA
```

---

## Interactions & Behavior

### Stop Button — Inline Confirmation

```
1. User taps/clicks "Stop"
2. Button text immediately changes to "Confirm?"
   Background remains #E53834, font-size drops to 11pt (to fit longer label)
3. If user taps again within 3 seconds → execute SIGTERM → port rescan
4. If 3 seconds pass with no second tap → revert button to "Stop"
5. This applies to both the inline Compact stop button and the
   Dashboard runner card stop button.
   The small "■" inline stop buttons in Running process cards (Sidebar / Title bar)
   use the same 2-tap pattern.
```

### Restart Flow

```
1. User taps "Restart"
2. Send SIGTERM to current PID (escalate to SIGKILL if still running after 2s)
3. Wait for process to die (listen for exit)
4. Launch saved command from working directory
5. Rescan port
6. Update running dot + status bar
```

### Running Dot States

```
Idle / port free:    6–7pt circle, color #5A5272, no animation
Running:             6–7pt circle, color #28BF7D, pkPulse 2s ease-in-out infinite
  → pkPulse: opacity pulses 1.0 → 0.25 → 1.0 over 2 seconds
```

### Project Selection (Compact popover)

```
1. User taps project selector bar (full row is tappable)
2. Expand a sheet or popover listing all saved projects
3. Tapping a project:
   a. Updates project selector bar (name, type badge, port)
   b. Populates command list with that project's commands
   c. Auto-selects the last-used (or first) command
   d. Updates hero command input field
   e. Updates working directory strip
```

### Command Selection

```
1. User taps a command row in the list
2. Command row becomes SELECTED state (teal left accent, highlighted background)
3. Hero command input (Compact) or Command field (Dashboard) updates with the full command string
4. Return badge in hero input updates to show command shortname "↵ {name}"
5. Working directory stays unchanged unless the project changed
```

### Start Flow

```
1. Validate: command field non-empty, working directory exists on disk
2. Launch process: shell out the command string from the working directory
3. Begin polling the port (if port is specified) every 500ms for up to 10s
4. On port detected:
   - Status dot → green + pulse
   - Status text → "{command name} is listening."
   - Running dot on project selector → green + pulse
5. Show PID / PPID in Process Details section
```

### Open Localhost

```
Compact footer: "↗ Open localhost"  → opens http://localhost:{port} in default browser
Dashboard detail footer: "↗ Open localhost:{port}" → same behavior
Disabled / hidden when no port is configured or process is not running
```

---

## State Variables

| Variable | Type | Description |
|---|---|---|
| `selectedProject` | `Project?` | Currently active project |
| `selectedCommand` | `Command?` | Currently selected command |
| `customCommandText` | `String` | Content of the hero command input |
| `portNumber` | `String` | Port field value |
| `runningProcess` | `Process?` | Active process on selected port |
| `portScanResult` | `PortStatus` | `.free` / `.listening(PID)` |
| `stopConfirmPending` | `Bool` | True during the 3s confirm window |
| `stopConfirmTimer` | `Timer?` | Auto-reverts stopConfirmPending after 3s |
| `allProjects` | `[Project]` | Persisted local project library |
| `runningProcesses` | `[Process]` | All currently running tracked processes |

---

## Assets

No image assets. All visual elements are:
- System colors / fills
- SF Pro Text + SF Pro Display (system fonts, no custom imports)
- SF Mono (system monospace)
- Unicode glyphs: `▶` `■` `↺` `↗` `▾` `⌕` `⏎` `›` `{}`

Project type detection icons in the prototype use `{}` (Node) and `▶` (Flutter). In the
real app, consider replacing these with small custom glyphs or a minimal icon set (e.g.
Lucide at 14–16pt) using the same brand accent colors.

---

## Files in This Package

| File | Purpose |
|---|---|
| `README.md` | This document — full implementation spec |
| `ProcessKill_design_reference.html` | High-fidelity HTML prototype — open in Safari to view both Compact B and Dashboard B. Pan and zoom the canvas to inspect each frame. |

---

## Reference: Open Questions for the Developer

These UX details were flagged during design but left for implementation to decide:

1. **Compact window placement**: Should it always anchor to the menu bar icon, or be a free-floating window the user can drag?
2. **Project list in Compact**: Show as a popover/sheet from the project selector bar, or a drawer that expands the window downward?
3. **Port persistence**: Should the port number be saved per-project, per-command, or globally?
4. **Custom commands**: Should the "+ Add custom command" row open an inline edit field or a separate sheet?
5. **Dashboard min-size**: What is the minimum resizable window size before switching to a compact column layout?
