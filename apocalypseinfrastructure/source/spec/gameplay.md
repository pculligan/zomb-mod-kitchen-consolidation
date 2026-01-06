# Gameplay & Progression Considerations

This document explores **player-facing gameplay, progression, and role differentiation**
for the water, pumpable water, fuel, and propane systems.

It is intentionally **non-normative**:
- Core mechanics and invariants are defined in `spec.md`
- Concrete connector inventory lives in `items.md`
- Visual grammar and rendering rules live in `ui.md`

This file captures **design intent and fun**, not fixed balance.
All numbers, unlock timings, and efficiencies are tunable.

---

## 1. Core Gameplay Philosophy

The systems introduced by this mod should:

- Feel native to Project Zomboid
- Reward planning, foresight, and spatial reasoning
- Make infrastructure a meaningful survival choice
- Preserve scarcity without hard-locking players
- Support multiple viable paths to self-sufficiency

Players should feel *clever* for building good systems,
not *punished* for not picking the “right” profession.

---

## 2. Professions as Accelerators, Not Gates

Professions in Project Zomboid traditionally:
- Reduce friction
- Improve efficiency
- Accelerate access

They do **not**:
- Unlock exclusive mechanics
- Prevent other characters from progressing
- Override core survival loops

This mod follows that philosophy strictly.

Every character can eventually:
- Collect water
- Build irrigation
- Pump from wells or rivers
- Manage fuel and propane

Some characters simply get there sooner or more efficiently.

---

## 3. Water & Irrigation-Oriented Roles

### Natural Affinities
- Farmer
- Park Ranger
- Outdoorsman
- Carpenter

### Gameplay Advantages (Examples)
- Early knowledge of rain collectors and irrigation components
- Reduced material costs for barrels and pipes
- Improved irrigation efficiency (lower drain per interval)
- Faster build and repair times for water infrastructure

### Tuning & Optimization (Preferred Model)

Efficiency improvements (e.g., reduced irrigation drain, improved flow, lower waste)
are applied through **explicit tuning or optimization actions**, not by tracking
who originally built a connector.

Design intent:
- Connectors do not retain builder ownership or profession metadata
- Efficiency bonuses are applied at **runtime** when a system operates
- Skilled characters can actively improve existing infrastructure

Example interactions:
- Right-click → “Tune Irrigation System”
  - Requires relevant skill (e.g., Farming)
  - Applies a persistent but inspectable efficiency modifier
  - Reduces water drain per interval
- Right-click → “Optimize Pump”
  - Requires Engineering or Electrical skill
  - Improves fill rate or reduces noise

Tuning actions:
- Are explicit, player-initiated, and visible
- May require tools, time, or consumables
- Can be re-applied, refreshed, or overwritten by other players
- Avoid permanent, invisible bonuses tied to construction history

This model supports multiplayer, character death, and shared bases
without brittle ownership tracking.

### Player Fantasy
> “I know how to keep crops alive when others can’t.”

These characters shine in:
- early farming
- water planning
- long-term food security

---

## 4. Infrastructure & Pump-Oriented Roles

### Natural Affinities
- Engineer
- Electrician
- Metalworker

### Gameplay Advantages (Examples)
- Earlier access to pump construction
- Higher pump fill rates or storage capacity
- Reduced pump noise or failure chance
- Faster wiring and maintenance actions

### Player Fantasy
> “If it can be built, I can make it work.”

These roles excel in:
- mid-to-late game
- large bases
- multi-system layouts

---

## 5. Fuel & Propane Logistics Roles

### Natural Affinities
- Mechanic
- Metalworker
- Construction Worker

### Gameplay Advantages (Examples)
- Faster fuel transfer and refueling
- Reduced loss during equalization (abstracted spillage)
- Earlier access to large fuel or propane tanks
- Ability to convert generators or appliances to propane

### Player Fantasy
> “We don’t run out — we plan.”

These characters thrive in:
- energy independence
- vehicle-heavy play
- long-term base sustainability

---

## 6. Traits as Fine-Grained Modifiers

Traits provide more granular differentiation than professions.

Examples:
- **Plumbing Savvy** — cheaper connectors, faster placement
- **Organized** — effectively increases usable storage
- **Noise Sensitive** — pumps and generators are more disruptive
- **Handy** — reduced wear or failure rates on connectors

Traits modify **parameters**, not rules.
They stack with professions but do not replace them.

Traits and skills may influence the effectiveness, duration, or availability
of tuning actions, rather than directly modifying connector behavior.

---

## 7. Meaningful Player Choices

The systems are designed to force *interesting tradeoffs*.

Examples:
- Build early irrigation and spend resources now, or wait?
- Centralize storage and risk contamination, or isolate?
- Use gasoline generators, or invest in propane logistics?
- Pump from a river (easy) or dig a well (secure)?

No choice is strictly correct.
Each has spatial, logistical, and risk implications.

---

## 8. Progression Phases

### 8.1 Early Game — Improvisation

Characteristics:
- Manual labor
- Small-scale storage
- High friction

Player Experience:
- Buckets and rain collectors
- Portable fuel drums
- Outdoor propane grills
- Constant attention required

---

### 8.2 Mid Game — Stabilization

Characteristics:
- First infrastructure
- Intentional layouts
- Reduced micromanagement

Player Experience:
- Drip irrigation
- Pump-fed water storage
- Central fuel and propane tanks
- Valves protecting reserves

---

### 8.3 Late Game — Self-Sufficiency

Characteristics:
- Redundancy
- Large storage capacity
- Failure tolerance

Player Experience:
- Well-fed pumps
- Large propane installations
- Fully irrigated farms
- House-level water and propane services

Late-game success should feel **earned**, not automatic.

---

## 9. Failure, Recovery, and Drama

Infrastructure introduces new failure modes:
- Power loss
- Contamination
- Destruction or sabotage
- Poor layout decisions

But it also enables recovery:
- Isolated networks
- Backup storage
- Manual overrides

Players should learn from failures,
not be hard-stopped by them.

---

## 10. Sandbox & Difficulty Scaling

All progression advantages should be:
- Sandbox-tunable
- Difficulty-aware
- Mod-compatible

Possible sandbox axes:
- Resource abundance
- Build cost multipliers
- Efficiency bonuses
- Noise penalties

This ensures wide replayability.

---

## 11. Long-Term Fun & Extensibility

The design intentionally leaves room for:
- Heating systems
- Advanced filtration
- Resource contamination
- More specialized appliances

None of these require rethinking the core system.

They layer cleanly on top.

---

## 12. Summary

From a gameplay perspective, the system aims to:

- Reward planning over grind
- Encourage role diversity
- Support emergent base design
- Scale from desperate survival to confident autonomy

Infrastructure is not just convenience —
it is a **playstyle**.
