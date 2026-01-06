

# Testing Strategy & Validation Plan

This document defines a **layered testing approach** for the irrigation, water,
pumpable water, fuel, and propane systems.

The goal is to:
- Minimize slow, manual UI-driven testing
- Catch regressions early and deterministically
- Make complex interactions inspectable and debuggable
- Support confident iteration as features expand

This strategy is designed specifically for Project Zomboid’s modding environment
and assumes explicit connectors, event-driven logic, and minimal background ticking.

---

## Testing Philosophy

Testing follows a simple principle:

> **Test logic before visuals, and visuals before gameplay.**

Manual gameplay testing is valuable for *feel*, but poor for validating correctness.
Most correctness can and should be validated without touching the UI.

---

## Layered Testing Model

Testing is organized into four layers, from fastest to slowest.

Each higher layer assumes the lower layers are already reliable.

---

## Layer 1 — Pure Logic Tests (No World, No UI)

**Purpose:**  
Validate core rules and invariants without relying on the game world or renderer.

**Characteristics:**
- Fast
- Deterministic
- Repeatable
- Minimal dependencies

**What to test here:**
- Node registration and deregistration
- Neighbor discovery
- Network merge and split behavior
- Resource isolation by type
- Valve open/close gating
- Equalization eligibility (Store vs Observe)
- Availability propagation
- Connector activation/deactivation rules

**Approach:**
- Use mock nodes with fake positions and resource types
- Call core network functions directly
- Assert expected network membership and availability via logs or assertions

**Guiding rule:**
If a rule cannot be tested here, it is likely too tightly coupled to the UI.

---

## Layer 2 — Scripted World Tests (In-Game, No UI Interaction)

**Purpose:**  
Validate integration with the actual game world while avoiding manual interaction.

**Characteristics:**
- Runs inside Project Zomboid
- No clicking, dragging, or crafting
- Fully script-driven

**What to test here:**
- Connector placement and removal
- Observed object destruction or pickup
- Valve toggling
- Pump activation/deactivation
- Equalization behavior with real storage objects
- Resource availability after merges/splits

**Approach:**
- Write test Lua scripts that:
  - Spawn world objects at fixed coordinates
  - Attach connectors programmatically
  - Trigger events (e.g., destroy object, toggle valve)
  - Log outcomes deterministically

**Example flow:**
- Spawn rain barrel → attach connector
- Place water pipe → verify availability
- Close valve → verify downstream loss
- Destroy barrel → verify connector deactivation

**Benefit:**
This layer catches 90% of real bugs without human input.

---

## Layer 3 — Visual Validation Scenes

**Purpose:**  
Ensure visual grammar and rendering rules are upheld.

**Characteristics:**
- Minimal interaction
- High visual density
- Easy to re-run and compare

**What to test here:**
- Lane alignment across resources
- Multiple pipes in a single tile
- Cross, T, and corner orientation correctness
- Valve open/closed visuals
- Connector grounding in the correct lane
- Pumps bridging lanes correctly

**Approach:**
- Create dedicated “test maps” or zones containing:
  - A grid of all pipe orientations
  - All resource types in the same tiles
  - Valves in every state
- Add developer hotkeys:
  - Spawn full test grid
  - Clear test grid

**Validation method:**
- Visual inspection
- Screenshot comparison between versions

This layer prevents “it looks connected, why won’t it go?” regressions.

---

## Layer 4 — Manual Gameplay Testing

**Purpose:**  
Evaluate player experience, pacing, and fun.

**Characteristics:**
- Slow
- Subjective
- Irreplaceable for feel

**What to test here:**
- Progression pacing (early/mid/late game)
- Tuning usefulness and clarity
- Maintenance annoyance vs drama
- Failure recoverability
- Cognitive load for new players

**What not to rely on this layer for:**
- Verifying logic correctness
- Catching edge cases
- Regression detection

Manual testing should confirm *experience*, not correctness.

---

## Development Optimizations

### Developer Mode

A dedicated developer mode should enable:
- Instant builds
- Free materials
- Instant tuning and repair
- Forced degradation or damage
- Verbose logging

Testing should never require survival pacing.

---

### Inspection as a Debug Tool

All connectors should expose inspectable state, including:
- Resource type
- Active/inactive
- Network identifier
- Capabilities (Provide/Consume/Store)
- Tuning modifiers
- Degradation state (if enabled)

Inspection is the primary debugging interface.

---

### Logging Strategy

For development builds:
- Log network merges and splits
- Log drain and equalization events
- Log valve state changes
- Log connector activation/deactivation

Deterministic logs are more valuable than visual debugging.

---

## Vertical Slice Testing

Before expanding systems, validate at least one complete flow end-to-end:

Examples:
- Rain barrel → pipe → valve → irrigation
- Shore intake → pump → storage → house water
- Fuel barrel → hose → generator
- Propane tank → house service → stove

Each vertical slice should be:
- Scriptable
- Repeatable
- Inspectable

---

## Regression Strategy

When bugs are found:
- Reproduce via Layer 1 or Layer 2 tests if possible
- Add a dedicated test script for the case
- Never rely on “manual memory” of fixes

Over time, the test suite becomes a safety net.

---

## Summary

This testing strategy:

- Reduces reliance on manual UI testing
- Encourages deterministic validation
- Aligns with the explicit, event-driven system design
- Scales as new resources and connectors are added

Complex systems require **structured testing**.
This plan makes complexity manageable.