# UI & Rendering Specification — Pipes and Connectors

This document defines the **visual grammar** and **technical rendering approach**
used to represent pipes, connectors, and resource networks in the world.

The goals of this specification are to:
- Prevent visual ambiguity (e.g., “it looks connected, why won’t it go?”)
- Support multiple resource networks occupying the same world tile
- Remain performant at scale
- Align with Project Zomboid’s isometric visual language

This document is descriptive and prescriptive for UI and rendering only.
Network semantics are defined elsewhere.

---

## 1. Core Visual Principles

### 1.1 Explicitness Over Magic

All connectivity must be visually explicit.
If two elements appear connected, they **must** be connected.
If they are not connected, the visuals must make that obvious.

The system must not rely on:
- Tooltips
- Debug overlays
- Implicit proximity rules

to explain basic connectivity.

---

### 1.2 Visual Grammar, Not Decoration

Pipe and connector visuals encode **meaning**, not aesthetics.

Every visual element communicates:
- Resource type
- Connection plane
- Directionality
- Whether flow is possible

Visual consistency is more important than visual detail.

---

## 2. Resource Lanes (Per-Tile Visual Planes)

### 2.0 Screen-Space Anchoring (Authoritative)

All pipe and connector sprites are positioned using **screen-space anchoring**
relative to the isometric tile, not by offsets from the tile center.

Anchoring rules:

- Each tile has a single, consistent **screen-space anchor point**
  derived from the isometric diamond (not the tile center).
- Resource lane offsets are measured from this anchor point.
- Offsets are chosen so that increasing lane offset moves sprites
  **horizontally across the screen**, not diagonally.

The canonical anchor edges are:
- **Upper-left edge** of the isometric tile for north-aligned elements
- **Lower-left edge** of the isometric tile for south-aligned elements

This ensures that multiple resource lanes within the same tile appear
**side-by-side horizontally** when rendered on screen.

### 2.1 Lane Assignment (Conceptual)

Example conceptual ordering (north → south):

- Pumpable Water
- Water
- Fuel
- Propane

Exact pixel offsets are implementation-defined but must be:
- Globally consistent
- Large enough to prevent overlap
- Small enough to remain visually grounded

---

### 2.2 Lane Invariants

- A pipe or connector **never leaves its lane**
- Pipes of different resources may occupy the same tile but never overlap visually
- Pipes in different lanes must never visually imply connection
- Lane position is the primary indicator of resource type; color is secondary

This ensures players can visually parse networks without inspection.

- Lane offsets are defined so that pipes, junctions, and valves belonging to
  different resource lanes appear horizontally aligned on screen.
- Crosses and junctions for different resources within the same tile must
  align horizontally, not diagonally or vertically.

---

## 3. Pipe Orientation and Alignment

---

## 3.4 Sprite Selection Contract (Authoritative)

Sprite selection is governed by a single, immutable contract:

```
sprite = f(resource, face, connectivityMask)
```

Where:
- `resource` is the topology resource (Water, Fuel, Propane, etc.)
- `face` is one of: `floor`, `north`, `east`, `south`, `west`
- `connectivityMask` is the cached 4-bit mask derived at topology-change time

**Invariants:**
- Ghost preview uses the **exact same sprite selection** as commit.
- No runtime neighbor inspection occurs during render.
- Cached connectivity is the **single source of truth** for visuals.
- If a sprite is incorrect, the defect is in connectivity derivation, not rendering.

This contract must never be bypassed or duplicated.

---

Within a lane:

- North–South and East–West pipe segments are distinct sprites
- Junctions (corners, T, cross) are visually explicit
- Orientation changes never cause cross-lane overlap

Pipes do not “snap” visually to other lanes.

---

## 4. Connector Grounding & Contact

Connectors visually “touch the ground” in the same lane as the resource
they provide or consume.

Connector alignment follows the same screen-space anchoring rules as pipes.

- A connector’s visual ground contact point is offset horizontally according
  to its resource lane.
- When multiple connectors exist in the same tile (e.g., multiple valves),
  they must appear **horizontally adjacent** rather than stacked or overlapped.
- Visual alignment must never imply cross-resource connectivity.

### 4.1 Ground Contact Rules

- A connector’s ground contact point aligns with its resource lane
- Connectors must not visually bridge lanes unless they are explicit transformers (e.g., pumps)
- Pumps visually expose:
  - Intake contact in the Pumpable Water lane
  - Output contact in the Water lane

This makes transformation obvious and inspectable at a glance.

---

## 5. Multiple Pipes per Tile

Multiple pipes may coexist in the same tile provided they:
- Belong to different resource lanes
- Are rendered at distinct vertical offsets

This enables dense infrastructure without ambiguity.

---

## 6. Rendering Strategy


Sprites must not be positioned using offsets from the tile center.

Center-based offsets produce diagonal drift in isometric projection and
result in ambiguous visual connections. All offsets must be derived from
the defined screen-space anchor points instead.

---

### 6.X Sprite Authority Invariant (Authoritative)

**All sprite selection and application is owned exclusively by topology entities.**

- UI code **must never** choose, derive, or apply sprites.
- Controllers **must never** apply sprites.
- Placement preview **may display** sprite keys, but may not apply them.
- The renderer **only displays** what the entity has already derived.

The only valid place where a sprite may be applied to a world object is:

```
Entity:updateSpritesFromConnectivity()
```

This invariant ensures:
- Preview parity with commit
- No visual drift between UI and world state
- No duplicated sprite logic
- Deterministic adjacency updates

If a sprite is wrong, the bug is **always** in topology derivation, never in UI or rendering.

---

### 6.1 Chosen Strategy: Pre-Drawn Sprites per Resource

The system uses **pre-drawn sprites** for each resource and orientation.

For each resource type, sprites are authored for:
- Straight (N–S, E–W)
- Corner
- T-junction
- Cross
- End-cap / connector interface
- Valves

Each sprite is pre-baked with:
- Correct lane offset
- Correct shading
- Correct ground alignment

At runtime:
- One sprite is rendered per resource per tile
- The renderer stacks sprites in fixed order by lane
- No dynamic sprite composition occurs per frame

---

### 6.2 Why Not Dynamic Layering (Option B)

Dynamic sprite layering or runtime composition is explicitly avoided because it:
- Increases per-frame draw and sort cost
- Makes Z-order bugs more likely
- Is harder to cache and reason about
- Becomes fragile as tile density increases

Pre-drawn sprites provide predictable performance and visual stability.

---

### 6.3 Why Not Combinatorial “Combo Sprites”

Pre-drawing sprites for every combination of resources (e.g., Water + Propane)
is avoided due to combinatorial explosion.

The lane model makes such sprites unnecessary:
- Each resource renders independently
- Visual clarity is preserved without special cases

---

## 7. Valves & Visual State

Valves are rendered as part of their resource lane.

- Open vs closed state is visually distinct
- Default-open state is reflected immediately on placement
- Closed valves visibly interrupt the pipe segment in that lane only

Valve visuals must not affect other lanes.

---

## 8. Performance Characteristics

The rendering cost scales with:
- Number of occupied tiles
- Number of distinct resources per tile

It does **not** scale with:
- Network size
- Number of connections
- Runtime composition complexity

This ensures stable performance even in dense bases.

---

## 9. UX Philosophy Summary

- The world explains itself visually
- Players infer connectivity from layout and alignment
- Inspection augments understanding but is not required
- Visual grammar prevents incorrect assumptions

If a player believes two things are connected, the system must agree.

---

## 10. Future Extensions

The lane model supports:
- Additional resource types
- New connector classes
- Visual debugging overlays (optional)

without requiring changes to existing sprites or rules.


## 11. Preparing Pipe Assets

This section provides **practical, implementation-ready guidance** for authoring
pipe and connector sprites that conform to the visual grammar and rendering rules
defined above.

The intent is to remove ambiguity before asset creation begins.

---

### 11.1 Coordinate & Tile Reality

- Project Zomboid tiles use an isometric diamond with a **64×32 px footprint**.
- Sprites are anchored relative to the tile origin (bottom-center of the diamond),
  but **visual alignment must be reasoned in screen space**, not tile-center space.
- Sprites may extend beyond the 64×32 diamond (e.g., 64×48 or 64×64 canvases) to
  accommodate vertical detail; this is normal and supported.

---

### 11.2 Sprite Resolution & Scale

- Author sprites at **native (1×) resolution**.
- Use **integer pixel alignment only** (no fractional pixels).
- Avoid upscaling/downscaling during authoring; draw at final size.
- Prefer clean silhouettes over heavy detail to preserve clarity at zoom levels.

---

### 11.3 File Format & Alpha Discipline

- Use **PNG (RGBA)** with transparent backgrounds.
- Avoid premultiplied alpha.
- Keep edges crisp; avoid fuzzy transparency on pipe edges.
- Do not bake heavy shadows into sprites; rely on engine lighting.

---

### 11.4 Screen-Space Anchoring While Drawing

- Do **not** draw sprites centered in the tile diamond.
- Draw sprites **offset from a consistent screen-space anchor** derived from the
  isometric diamond’s left edges, per the Screen-Space Anchoring rules.
- Lane offsets must move sprites **horizontally across the screen**.

**Recommended authoring workflow:**
1. Draw the 64×32 isometric diamond as a locked guide layer.
2. Draw vertical guide lines representing each resource lane
   (Pumpable Water, Water, Fuel, Propane).
3. Draw each sprite so its “ground contact” aligns with its lane guide.
4. Never allow sprites to drift diagonally relative to lane guides.

---

### 11.5 Sprite Sets Per Resource (Minimum)

For each resource type, author a complete, self-contained sprite set:

- Straight pipe (North–South)
- Straight pipe (East–West)
- Corners (NE, NW, SE, SW)
- T-junctions (NES, NEW, NSW, ESW)
- Cross junction
- End-cap / connector interface
- Valve (open)
- Valve (closed)

Sprites must be **pre-offset** to the correct resource lane.
No runtime offsetting or composition is expected.

---

### 11.6 Connectors & Ground Contact

- Connector sprites terminate visually in the same lane as their resource.
- Valves visually interrupt only their own lane.
- Pumps may visually span lanes but must expose:
  - Intake contact in the Pumpable Water lane
  - Output contact in the Water lane

No connector sprite may imply cross-resource connectivity unless it is an explicit
transformer.

---

### 11.7 Naming & Organization

Use resource-first, orientation-explicit naming to simplify selection and debugging.

Example:
- `pipe_water_ns.png`
- `pipe_water_cross.png`
- `pipe_propane_valve_open.png`

Avoid numeric or ambiguous naming schemes.

---

### 11.8 Performance Expectations

- One sprite is rendered per resource per tile.
- Sprites are static and highly reusable.
- No dynamic sprite composition or per-frame layout math is required.

This approach scales predictably in dense bases and aligns with vanilla rendering
patterns.

---

### 11.9 Authoring Checklist

Before considering a sprite set complete, verify:

- Sprites align horizontally across lanes on screen
- Crosses and valves line up side-by-side when co-located
- No sprite implies a connection it does not actually make
- Lane offsets are consistent across all orientations
- Alpha edges are clean and stable under lighting