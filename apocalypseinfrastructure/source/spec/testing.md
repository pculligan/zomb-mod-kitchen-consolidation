# Testing Strategy & Validation Plan

This document defines a **reality-based, layered testing approach** for the
resource network system (water, pumpable water, fuel, propane, electricity).

The goals are to:
- Minimize slow, manual UI testing
- Catch regressions early and deterministically
- Make topology and flow behavior inspectable
- Support confident iteration as complexity increases

This strategy is designed specifically for **Project Zomboid modding** and assumes:
- Explicit connectors
- Event-driven topology updates
- Cached connectivity and sprite derivation
- Minimal background ticking

---

## Core Testing Principle

> **Test logic before visuals, and visuals before gameplay.  
> UI testing is last, not first.**

If correctness requires clicking around the UI, the system is already too opaque.

---

## Layered Testing Model

Testing is organized into **six layers**, from fastest to slowest.

Each higher layer assumes all lower layers are already reliable.

---

## Layer 1 — Pure Logic Tests (No World, No UI)

**Purpose**  
Validate core rules and invariants without relying on the game world or renderer.

**Characteristics**
- Fast
- Deterministic
- Repeatable
- No Project Zomboid runtime

**What belongs here**
- Node registration / deregistration
- Neighbor discovery
- Network merge and split behavior
- Resource isolation by type
- Valve open/close gating rules
- Allocation strategies
- Capability ordering invariants

**Rule**  
If a rule cannot be tested here, it is likely incorrectly coupled.

---

## Layer 2 — Inspector-Driven Tests (World-Aware, No UI)

**Purpose**  
Validate topology state by *inspecting* the world, not interacting with it.

**Characteristics**
- Runs inside Project Zomboid
- No clicking or context menus
- No placement or removal via UI

**What belongs here**
- Which entities exist on a square
- Which faces are occupied
- Which connectors are active
- Which resources are present
- Network membership consistency
- Cached faceConnectivity correctness

**Tools**
- `SquareInspector`
- `PipeInspector`
- `ConnectorInspector`
- `ResourceInspector`

This layer validates the **observable truth** the UI will later rely on.

---

## Layer 3 — Preview Validity Tests (No Placement)

**Purpose**  
Validate placement logic **without committing anything to the world**.

**Characteristics**
- World-aware
- Read-only
- Extremely fast feedback

**What belongs here**
- Placement validity rules
- Rejection reasons
- Face eligibility
- Derived connectivity masks
- Sprite selection correctness

**Approach**
- Call `Placement.preview(...)` directly
- Assert:
  - `valid`
  - `reason` (when invalid)
  - `attachedFaces`
  - `faceConnectivity`
  - `spriteByFace`

**Rule**  
If preview logic is wrong, commit will also be wrong.

---

## Layer 4 — Scripted World Mutation Tests (No UI Interaction)

**Purpose**  
Validate integration with the real world while avoiding manual interaction.

**Characteristics**
- Runs inside Project Zomboid
- Fully script-driven
- No menus, clicks, or crafting

**What belongs here**
- Entity attach / detach
- Connector activation / deactivation
- Valve toggling
- Observed object destruction
- Network splits and merges
- Resource availability after topology changes

This layer catches most real bugs without human input.

---

## Layer 5 — Visual Validation Scenes

**Purpose**  
Ensure the visual grammar matches topology and cached connectivity.

**Characteristics**
- Minimal interaction
- High visual density
- Easy to re-run

**What belongs here**
- Lane alignment across resources
- Pipe connectivity shapes
- Wall vs floor correctness
- Valve open / closed / bypassed visuals
- Sprite parity between preview and commit

This layer prevents:
> “It looks connected — why won’t it go?”

---

## Layer 6 — Manual Gameplay Testing (Last)

**Purpose**  
Evaluate pacing, clarity, and fun.

**Characteristics**
- Slow
- Subjective
- Irreplaceable for *feel*

**What belongs here**
- Progression balance
- Cognitive load
- Maintenance annoyance vs drama
- Failure recovery

**What does NOT belong here**
- Logic correctness
- Edge-case validation
- Regression detection

If you’re debugging here, you’re already too late.

---

## Developer Optimizations

### Developer Mode

Developer mode should allow:
- Instant builds
- Free materials
- Forced damage or degradation
- Verbose logging
- Direct state inspection

Testing should never require survival pacing.

---

## Inspection as the Primary Debug Interface

All entities and connectors should expose inspectable state:
- Resource type
- Active / inactive
- Network identifier
- Capabilities (Provide / Consume / Store)
- Cached face connectivity
- Degradation state (if enabled)

Inspection is faster and clearer than log spelunking.

---

## Regression Strategy

When bugs are found:
1. Reproduce in the lowest possible layer
2. Add a test for that case
3. Never rely on memory of fixes

The test suite is your long-term safety net.

---

## Summary

This testing strategy:
- Matches how the system is actually built
- Avoids UI-driven debugging
- Scales with new resources and connectors
- Makes complexity understandable and controllable