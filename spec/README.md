# Kitchen Consolidation – Specification Index

This directory contains the **authoritative design and behavior specification**
for the *Kitchen Consolidation* mod.

These documents exist to:
- Capture hard‑won design decisions
- Prevent regression into engine‑dependent assumptions
- Enable confident future changes and extensions
- Onboard contributors without rediscovering pitfalls

If you are changing code, **start here**.

---

## How to Read This Spec

The specification is modular. Each document owns a single concern.
Read them in the order below for a complete mental model.

---

## 1. Purpose and Scope

### 📌 `purpose.md`
**Why this mod exists.**

- The player problem being solved
- The design intent
- What the mod explicitly is *not*

Start here to understand *why* Kitchen Consolidation exists at all.

---

## 2. Core Models (Authoritative)

### 🍽️ `hunger-model.md`
**The single most important document.**

Defines:
- Engine‑owned vs mod‑owned hunger state
- What “full” and “current” hunger mean
- Why engine fields like `BaseHunger` are not used
- The canonical fraction math used everywhere

All other documents depend on this model.

---

### 🔪 `model-preparation.md`
**How discrete foods become fungible Pieces.**

Defines:
- What preparation does and does not do
- How `KC_FullHunger` is assigned
- Multi‑output preparation semantics
- State preservation rules

Read after `hunger-model.md`.

---

### 🔄 `model-consolidation.md`
**How partial Pieces are merged.**

Defines:
- Eligibility for consolidation
- Strict equivalence rules
- Conservation of hunger math
- Output generation rules
- Refusal semantics

Relies directly on the hunger and preparation models.

---

## 3. Eligibility and Integration

### ✅ `eligibility.md`
**What is allowed to participate.**

Defines:
- Preparation eligibility
- Consolidation eligibility
- Explicit exclusions
- Fail‑closed behavior

This document prevents scope creep and ambiguity.

---

### 🍲 `cooking-integration.md`
**Why this mod composes cleanly with vanilla cooking.**

Defines:
- How soups and stews consume hunger
- Why no recipe overrides are required
- Interaction with cooking skill
- Ingredient slot motivation

---

## 4. Runtime and Architecture

### 🌐 `multiplayer.md`
**Multiplayer guarantees and constraints.**

Defines:
- Server authority model
- Timed action usage
- Determinism guarantees
- Refusal behavior in MP

Required reading for any gameplay‑affecting change.

---

### 🧱 `architecture.md`
**Code structure and responsibilities.**

Defines:
- File layout
- Layer responsibilities
- Data flow
- Extension points

Read this before touching Lua files.

---

## 5. Boundaries and Future Work

### 🚫 `non-goals.md`
**What this mod will not do.**

Explicitly documents excluded ideas to prevent future thrash.

---

### 🚀 `extension-path.md`
**How the mod may grow safely.**

Defines:
- Supported extension categories
- Constrained ideas
- Invariants extensions must preserve

Read before adding new item types or integrations.

---

## Design Invariant (Global)

> **Kitchen Consolidation never guesses engine intent.  
> All canonical values are captured explicitly and preserved.**

Any change that violates this invariant is a design defect.

---

## If You Are Making Changes

Before writing code:
1. Identify which spec document governs the behavior
2. Update the spec first
3. Ensure no invariants are violated
4. Then update implementation

If the spec does not clearly allow a change, the change is not allowed.

---

## Status

This specification reflects the current, battle‑tested understanding of
Project Zomboid’s food model and the design of Kitchen Consolidation.

It is intentionally conservative and explicit.
