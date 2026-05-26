# Assignment D4-V1 - Search and Rescue: Single Robot, Known Environment

## Scenario

A mobile rescue robot operates in a partially damaged building whose layout is fully known, including all rooms and connections between them. One victim is located at a known position. The robot must:

1. Navigate to the victim's location.
2. Stabilize the victim on-site.
3. Transport the victim to a designated safe exit room.

The environment is static and no hazards evolve over time (in the classical model). The PDDL+ extension introduces continuous health decay, making timing a critical factor.

---

## Repository Structure

```
.
+-- domain.pddl                  # Classical STRIPS domain (Q1)
+-- problem_simple_rescue.pddl   # Q1 - simple instance (2 rooms, direct path)
+-- problem_complex_rescue.pddl  # Q1 - complex instance (4 rooms, longer path)
+-- Domain_pddl_pluss.pddl       # PDDL+ domain with processes and events (Q2)
+-- Problem_pddl_pluss.pddl      # Q2 - time-critical instance with health decay
+-- README.md
```

---

## Q1 - Classical PDDL Model

### Domain design (`domain.pddl`)

The domain models four actions that must be composed in a specific order. That order is **not hard-coded** -- it emerges naturally from the preconditions of each action:

| Action | Key preconditions | Key effects |
|---|---|---|
| `move` | robot at `from`, rooms connected | robot moves to `to` |
| `stabilize` | robot and victim co-located, victim injured | victim becomes `stabilized`, no longer `injured` |
| `pickup` | robot and victim co-located, victim `stabilized` | robot carries victim |
| `drop` | robot carrying victim, current room is `safe` | victim placed at safe location |

This structure ensures that the planner cannot, for example, pick up a victim before stabilizing them, or drop a victim in an unsafe room. The rescue sequence is the only valid one, but the planner discovers it rather than being told it explicitly.

**Types used:** `robot`, `room`, `victim`  
**Key predicates:** `at`, `connected`, `victim-at`, `injured`, `stabilized`, `carrying`, `safe`

### Problem instances

#### Simple rescue (`problem_simple_rescue.pddl`)

Two rooms (`roomA`, `roomB`). Robot starts in `roomA`, victim is in `roomB`, safe exit is `roomA`.

**Resulting plan:**
```
0.000: (move r1 roomA roomB)
0.001: (stabilize r1 v1 roomB)
0.002: (pickup r1 v1 roomB)
0.003: (move r1 roomB roomA)
0.004: (drop r1 v1 roomA)
```

#### Complex rescue (`problem_complex_rescue.pddl`)

Four rooms in a linear chain: `roomA - roomB - roomC - roomD`. The victim is in `roomD`, the safe exit is `roomA`. The robot must traverse three corridor segments in each direction.

**Resulting plan:**
```
0.000: (move r1 roomA roomB)
0.001: (move r1 roomB roomC)
0.002: (move r1 roomC roomD)
0.003: (stabilize r1 v1 roomD)
0.004: (pickup r1 v1 roomD)
0.005: (move r1 roomD roomC)
0.006: (move r1 roomC roomB)
0.007: (move r1 roomB roomA)
0.008: (drop r1 v1 roomA)
```

---

## Q2 - PDDL+ Model with Temporal Dynamics

### Domain design (`Domain_pddl_pluss.pddl`)

The PDDL+ domain augments the classical model with **processes** (continuous change over time) and **events** (instantaneous state changes triggered by conditions). Actions that were atomic in Q1 are split into a start action and a completion event, so they genuinely occupy time and allow other continuous changes to interleave.

#### Processes

| Process | Trigger | Effect |
|---|---|---|
| `health-decay` | victim alive and not stabilized | `health` decreases at 1.0 units/second |
| `moving-progress` | robot is moving | `move-progress` increases at 1.0/second |
| `stabilizing-progress` | robot is stabilizing | `stabilize-progress` increases at 1.0/second |

#### Events (instantaneous, condition-triggered)

| Event | Trigger | Effect |
|---|---|---|
| `move-complete` | `move-progress >= move-duration` | robot arrives at destination, progress reset |
| `stabilize-complete` | `stabilize-progress >= stabilize-duration` | victim marked stabilized, health decay stops |
| `victim-death` | `health <= 0.5` | victim marked dead, `victim-dead` flag set |

The `victim-dead` flag is checked as a negative precondition on every action. Once it is set, no further action can be applied, forcing the planner to treat that branch as a dead end.

#### Numeric functions

- `health` -- victim's remaining survivability (decays continuously)
- `move-progress` / `stabilize-progress` -- internal clocks for in-progress tasks
- `move-duration` / `stabilize-duration` -- configurable task durations (set in the problem file)

### Problem instance (`Problem_pddl_pluss.pddl`)

Two rooms (`roomA`, `roomD`). Durations: move = 3 s, stabilize = 4 s.

**Health budget analysis:**

| Time | Event | Health remaining |
|---|---|---|
| t = 0 | `start-move` | 8.0 |
| t = 3 | `move-complete` | 5.0 (decayed 3.0) |
| t = 3 | `start-stabilize` | 5.0 |
| t = 7 | `stabilize-complete` | 1.0 (decayed 4.0 more) |
| t = 7 | `pickup` + `start-move` | 1.0 (decay stopped) |
| t = 10 | `move-complete` + `drop` | 1.0 -- RESCUED |

The victim survives with health = 1.0. Setting the initial health to 6.0 causes death at t = 6 (before stabilization completes), making the problem unsolvable.

**Resulting plan:**
```
0.0:  (start-move r1 roomA roomD v1)
      ----- waiting 3.0 s -----
3.0:  (start-stabilize r1 v1 roomD)
      ----- waiting 4.0 s -----
7.0:  (pickup r1 v1 roomD)
7.0:  (start-move r1 roomD roomA v1)
      ----- waiting 3.0 s -----
10.0: (drop r1 v1 roomA)
```

### How to run (PDDL+)

```bash
java -jar enhsp-20.jar -o Domain_pddl_pluss.pddl -f Problem_pddl_pluss.pddl -planner opt-blind -delta 0.5
```

---

## Discussion

### Modelling choices and abstractions

The domain deliberately separates navigation, stabilization, and transport into distinct actions rather than collapsing them into a single "rescue" action. This separation means the task ordering constraint -- stabilize before pickup, co-location required for stabilization -- is expressed entirely through preconditions. The planner discovers the correct sequence rather than being given it, making the model general for any room layout and victim placement.

The choice to model victim state as a pair of predicates (`injured` / `stabilized` in Q1; `alive` / `victim-dead` in Q2) rather than a single multi-valued fluent keeps the representation simple and compatible with standard STRIPS planners. It does however mean that partial states (e.g. a victim mid-stabilization) cannot be represented in Q1 -- this is one of the abstractions discussed below.

---

### Discussion point 1: Differences between discrete and continuous energy (health) modelling

In the **classical Q1 model**, victim health is implicit. The victim is either `injured` or `stabilized`, and there is no health value that changes over time. The planner reasons purely over discrete state transitions, and any valid sequence of actions that achieves the goal is acceptable regardless of how long it takes. A plan requiring 100 moves is treated identically to one requiring 3 -- time has no cost.

In the **PDDL+ Q2 model**, health is an explicit numeric fluent that decreases continuously via a process running in parallel with the robot's actions. This changes the nature of planning fundamentally:

- **Time is a resource.** Every second the robot spends moving costs the victim health. The planner must find not just a logically correct sequence but a fast enough one.
- **Plans can become invalid mid-execution.** A plan that is valid at t = 0 may be invalidated at t = 6 if the robot has not yet stabilized the victim. The `victim-death` event represents this continuous invalidation risk.
- **Some logically valid plans are physically infeasible.** With health = 6.0, the sequence move -> stabilize -> pickup -> move -> drop is logically correct but infeasible because the victim dies before stabilization completes. The classical model cannot distinguish this case; the PDDL+ model correctly identifies it as unsolvable.
- **Processes run independently of the robot.** Health decays whether or not the robot is doing anything useful. This models the real-world property that a victim's condition does not pause while the robot is navigating.

---

### Discussion point 2: Modelling temporal urgency and differences between static and time-critical planning

**In the classical model**, the environment is static and only the discrete ordering of actions matters. There is no pressure to act quickly -- the planner can insert arbitrary delays between actions without any consequence to the goal. Temporal urgency simply cannot be expressed.

**In the PDDL+ model**, temporal urgency is modelled through two mechanisms working together:

1. The `health-decay` process creates a continuous deadline -- every second of delay directly reduces the victim's survivability.
2. The `victim-death` event acts as a hard cutoff -- once health reaches zero, the `victim-dead` flag blocks all further actions and the plan is declared unsolvable.

This combination means the planner is forced to find a solution that is both logically correct and time-bounded. The feasibility boundary is concrete and demonstrable: with move-duration = 3 s and stabilize-duration = 4 s, a starting health of 8.0 is feasible (1.0 health unit remaining at rescue) while 6.0 is not (victim dies at t = 6, before stabilization at t = 7 completes).

The structural difference between the two planning paradigms is therefore:

| | Static planning (Q1) | Time-critical planning (Q2) |
|---|---|---|
| Environment | Fixed, discrete | Continuously changing |
| Goal validity | Depends only on action order | Depends on action order AND timing |
| Failure mode | No valid action sequence exists | Valid sequence exists but takes too long |
| Planner requirement | Logical search over states | Reasoning over continuous numeric change |

---

### Limitations of the abstractions

**Q1 (classical model):**
- **No time or urgency.** All actions are instantaneous. This is appropriate for correctness checking but not real deployment.
- **Single victim, single robot.** The domain does not scale without significant extension.
- **Binary victim state.** No representation of deterioration during rescue, partial stabilization, or re-injury.
- **No partial observability.** The room graph and victim location are fully known at planning time, which does not reflect real disaster environments.

**Q2 (PDDL+ model):**
- **Simplified health model.** Health decays linearly at a fixed rate. Real physiological deterioration is non-linear and depends on injury type and environment.
- **Fixed task durations.** Travel time and stabilization time are constants. In reality both depend on terrain, distance, and injury severity.
- **Death is a hard threshold.** There is no modelling of a critical-but-survivable intermediate state between healthy and dead.
- **No robot resource constraints.** The robot can act indefinitely without recharging or resupply.
- **Discrete time steps.** ENHSP operates with a configurable delta (here 0.5 s). Events that should fire between steps may fire slightly late, introducing small numeric errors. A smaller delta increases accuracy at the cost of computation time.
