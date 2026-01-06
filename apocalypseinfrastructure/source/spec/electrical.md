

# Electrical Systems — Design Notes & Deferred Architecture

This document captures the reasoning, tradeoffs, and architectural implications around **modeling electricity as a first-class resource** within the Drip Irrigation & Resource Network system.

It is written for **future maintainers (including future-me)** to explain:
- why electricity is intentionally *not* modeled as a resource today
- what additional work would be required if that decision ever changes
- how the existing network/connector architecture could support it if explicitly enabled

This document is explanatory and non-normative.  
It does **not** mandate implementation.

---

## Current State of Electricity in Project Zomboid

In vanilla Project Zomboid, electricity is **not a simulated system**.

Key properties:

- Electricity is binary (powered / not powered)
- Availability is global (pre-shutoff) or radius-based (generators)
- There is no wiring topology
- There is no notion of load, contention, or capacity
- Appliances do not negotiate or compete for power
- Fuel consumption for generators is time-based and independent of appliance usage

Electricity functions as an **environmental condition**, not as a resource.

This abstraction is intentional and deeply baked into player expectations.

---

## Why Electricity Is Not Modeled as a Resource

The resource network system exists to solve problems that electricity in vanilla Zomboid does not have:

| Property | Water / Fuel | Electricity (Vanilla) |
|--------|--------------|------------------------|
| Requires routing | Yes | No |
| Stored locally | Yes | No |
| Quality matters | Yes | No |
| Flow path matters | Yes | No |
| Consumption negotiated | Yes | No |
| Player expects topology | Yes | No |

Modeling electricity as a resource would therefore introduce **new rules**, not formalize existing ones.

---

## What Changes If Electricity Becomes a Resource

If electricity were promoted from a condition to a resource, the following questions would become mandatory to answer:

- How much power does each appliance consume?
- Is consumption event-driven, periodic, or continuous?
- What happens when total demand exceeds supply?
- How are priorities resolved?
- Can electricity be stored (beyond batteries)?
- Do wires have capacity or loss?
- Can generators overload?
- What happens during partial availability (brownouts)?

None of these questions have vanilla answers.

Answering them would require introducing a **new electrical economy** into the game.

---

## Scope Explosion & Design Debt

Turning electricity into a resource would require:

- Defining electrical drain semantics (event vs periodic vs continuous)
- Introducing load modeling and arbitration
- Creating failure modes (overload, shutdown, degradation)
- Adding UI to explain power availability and failure
- Overriding or replacing vanilla generator behavior
- Maintaining compatibility with other mods
- Providing a sandbox option to disable the system

This would constitute a **major gameplay expansion**, not an incremental feature.

---

## Why a Settings Toggle Would Be Required

Because vanilla electricity is intentionally simple, many players expect it to remain so.

Any resource-based electricity system would need to be:

- Opt-in
- Explicitly labeled as advanced or hardcore
- Fully disableable without affecting water/fuel systems

Failing to gate it would risk alienating players and breaking expectations.

---

## How the Current Architecture Still Supports Future Electricity

Despite not implementing electricity as a resource, the current system was deliberately designed so that it *could* support it if explicitly chosen later.

Already in place:

- Generic resource networks
- Capability-based connectors (provide / consume / store)
- Event-driven and periodic drain semantics
- Connector-local policy and quality handling
- Zero idle-cost topology management
- Multiplayer-safe, server-authoritative design

If electricity were ever added as a resource, it would require **new connectors and semantics**, but not a new core architecture.

---

## Correct Current Integration: Electricity as an Activation Predicate

Today, electricity integrates cleanly as a **connector activation condition**, not as a resource.

Examples:

- A pump connector may require electricity to become active
- A house water source may require municipal power
- A generator connector may require fuel to operate

In all cases:
- Electricity gates connector activity
- Electricity does not participate in network topology
- No electrical drain occurs through the resource system

This matches vanilla behavior exactly.

---

## Batteries as a Special Case

Batteries already exist in vanilla as localized storage.

If electricity were ever modeled as a resource:
- Batteries would naturally map to connectors with Store capability
- However, this would further reinforce the need for full drain/load modeling

Until such a system exists, batteries remain outside the resource network abstraction.

---

## Design Rule (Authoritative)

**Only model as a resource what the base game already treats as a resource.**

- Water → resource
- Fuel → resource
- Electricity → condition

Violating this rule is an explicit design choice with large downstream consequences.

---

## Summary for Future-Me

- Electricity is intentionally *not* a resource today
- Modeling it as one would require answering many new design questions
- Doing so would significantly increase scope, complexity, and maintenance cost
- The current architecture keeps the door open without committing to it
- Any future implementation must be opt-in and explicitly scoped

If electricity-as-resource is ever revisited, treat it as a **new subsystem**, not a minor extension.