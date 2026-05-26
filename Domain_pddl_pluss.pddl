; Domain: Time-Critical Rescue (PDDL+)
;
; This domain extends the classical rescue model (domain.pddl) with continuous
; time, making victim survival genuinely time-dependent.
;
; Key design decisions:
;
;   1. Move and stabilize are split into a start-action / completion-event pair.
;      The start action launches the task (sets a flag and resets a progress
;      counter); a process increments the counter over time; an event fires when
;      the counter reaches the required duration. This models realistic task
;      duration and allows health decay to run concurrently.
;
;   2. Health decay is a continuous process. While the victim is alive and not
;      yet stabilized, health decreases at 1.0 unit/second. This creates genuine
;      temporal urgency: the longer the robot takes, the closer the victim is to
;      the death threshold.
;
;   3. The victim-death event fires when health <= 0.5. It sets the (victim-dead)
;      flag, which appears as a negative precondition on every action. Once set,
;      no action can be applied and the planner must declare the branch unsolvable.
;      This is preferable to letting the planner search indefinitely in a state
;      where no goal-achieving action remains.
;
;   4. Pickup and drop remain instantaneous (no process/event pair needed).
;
; Timing model summary:
;   - move-duration and stabilize-duration are numeric constants set in the
;     problem file, allowing easy reconfiguration without modifying the domain.
;   - move-progress and stabilize-progress are per-robot counters reset to 0.0
;     at the start of each task and compared against the duration threshold.

(define (domain rescue_time)

(:requirements :strips :fluents :typing :negative-preconditions)

(:types robot room victim)

(:predicates
    ; --- Spatial state ---
    (at ?r - robot ?loc - room)
    (connected ?from - room ?to - room)

    ; --- Victim state ---
    (victim-at ?v - victim ?loc - room)
    (stabilized ?v - victim)             ; health decay stops once stabilized
    (alive ?v - victim)
    (victim-dead ?v - victim)            ; set by victim-death event; blocks all actions

    ; --- Transport state ---
    (carrying ?r - robot ?v - victim)
    (safe ?loc - room)

    ; --- In-progress flags (used by processes and events) ---
    (moving ?r - robot)                          ; move task is in progress
    (stabilizing ?r - robot)                     ; stabilize task is in progress
    (move-dest ?r - robot ?loc - room)           ; intended destination of current move
    (stabilize-target ?r - robot ?v - victim)    ; victim being stabilized
)

(:functions
    (health ?v - victim)            ; victim survivability; decays at 1.0/sec
    (move-progress ?r - robot)      ; seconds elapsed in current move task
    (stabilize-progress ?r - robot) ; seconds elapsed in current stabilize task
    (move-duration)                 ; required seconds to complete a move (constant)
    (stabilize-duration)            ; required seconds to complete stabilization (constant)
)

; ---------------------------------------------------------------------------
; PROCESS: health-decay
; Runs continuously while the victim is alive and not yet stabilized.
; Decrement rate: 1.0 health unit per second.
; Stops automatically once (stabilized ?v) is true (precondition fails).
; ---------------------------------------------------------------------------
(:process health-decay
    :parameters (?v - victim)
    :precondition (and
        (alive ?v)
        (not (stabilized ?v))
        (not (victim-dead ?v))
    )
    :effect (decrease (health ?v) (* #t 1.0))
)

; ---------------------------------------------------------------------------
; PROCESS: moving-progress
; Advances the move timer while a move task is active.
; Rate: 1.0 second of progress per real second elapsed.
; ---------------------------------------------------------------------------
(:process moving-progress
    :parameters (?r - robot ?v - victim)
    :precondition (and
        (moving ?r)
        (not (victim-dead ?v))
    )
    :effect (increase (move-progress ?r) (* #t 1.0))
)

; ---------------------------------------------------------------------------
; PROCESS: stabilizing-progress
; Advances the stabilization timer while a stabilize task is active.
; Rate: 1.0 second of progress per real second elapsed.
; ---------------------------------------------------------------------------
(:process stabilizing-progress
    :parameters (?r - robot ?v - victim)
    :precondition (and
        (stabilizing ?r)
        (not (victim-dead ?v))
    )
    :effect (increase (stabilize-progress ?r) (* #t 1.0))
)

; ---------------------------------------------------------------------------
; EVENT: move-complete
; Fires when move progress reaches the required duration.
; Teleports the robot to its destination, clears the moving flag,
; and resets the progress counter for the next task.
; ---------------------------------------------------------------------------
(:event move-complete
    :parameters (?r - robot ?to - room)
    :precondition (and
        (moving ?r)
        (move-dest ?r ?to)
        (>= (move-progress ?r) (move-duration))
    )
    :effect (and
        (not (moving ?r))
        (not (move-dest ?r ?to))
        (at ?r ?to)
        (assign (move-progress ?r) 0.0)
    )
)

; ---------------------------------------------------------------------------
; EVENT: stabilize-complete
; Fires when stabilization progress reaches the required duration.
; Marks the victim as stabilized (halting health-decay) and resets the counter.
; Requires victim to still be alive — if the victim died mid-stabilization
; (health-decay fired victim-death first), this event never triggers.
; ---------------------------------------------------------------------------
(:event stabilize-complete
    :parameters (?r - robot ?v - victim)
    :precondition (and
        (stabilizing ?r)
        (stabilize-target ?r ?v)
        (>= (stabilize-progress ?r) (stabilize-duration))
        (alive ?v)
    )
    :effect (and
        (not (stabilizing ?r))
        (not (stabilize-target ?r ?v))
        (stabilized ?v)
        (assign (stabilize-progress ?r) 0.0)
    )
)

; ---------------------------------------------------------------------------
; EVENT: victim-death
; Fires when health drops to or below 0.5 (the death threshold).
; Sets victim-dead, which is a negative precondition on every action.
; This forces the planner to treat the current branch as a dead end
; rather than searching indefinitely for an unreachable goal.
;
; The 0.5 threshold (rather than 0.0) guards against floating-point
; under-stepping in the numeric integrator used by ENHSP.
; ---------------------------------------------------------------------------
(:event victim-death
    :parameters (?v - victim)
    :precondition (and
        (alive ?v)
        (<= (health ?v) 0.5)
    )
    :effect (and
        (not (alive ?v))
        (victim-dead ?v)
    )
)

; ---------------------------------------------------------------------------
; ACTION: start-move
; Initiates a move task from ?from toward ?to.
; The robot leaves ?from immediately (it is in transit) but does not arrive
; at ?to until the move-complete event fires after move-duration seconds.
; Preconditions prevent starting a move while already moving or stabilizing.
; ---------------------------------------------------------------------------
(:action start-move
    :parameters (?r - robot ?from ?to - room ?v - victim)
    :precondition (and
        (at ?r ?from)
        (connected ?from ?to)
        (alive ?v)
        (not (victim-dead ?v))
        (not (moving ?r))
        (not (stabilizing ?r))
    )
    :effect (and
        (not (at ?r ?from))
        (moving ?r)
        (move-dest ?r ?to)
        (assign (move-progress ?r) 0.0)
    )
)

; ---------------------------------------------------------------------------
; ACTION: start-stabilize
; Begins stabilizing the victim at the robot's current location.
; Health decay continues during stabilization — if health reaches 0.5
; before stabilize-complete fires, the victim dies and the plan fails.
; ---------------------------------------------------------------------------
(:action start-stabilize
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (victim-at ?v ?loc)
        (alive ?v)
        (not (victim-dead ?v))
        (not (stabilized ?v))
        (not (moving ?r))
        (not (stabilizing ?r))
    )
    :effect (and
        (stabilizing ?r)
        (stabilize-target ?r ?v)
        (assign (stabilize-progress ?r) 0.0)
    )
)

; ---------------------------------------------------------------------------
; ACTION: pickup (instantaneous)
; Robot picks up the stabilized victim. Requires stabilization to be complete
; (health decay has already stopped), so this action does not consume health.
; ---------------------------------------------------------------------------
(:action pickup
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (victim-at ?v ?loc)
        (alive ?v)
        (not (victim-dead ?v))
        (stabilized ?v)
        (not (moving ?r))
        (not (stabilizing ?r))
    )
    :effect (and
        (carrying ?r ?v)
        (not (victim-at ?v ?loc))
    )
)

; ---------------------------------------------------------------------------
; ACTION: drop (instantaneous)
; Robot places the victim at a safe location, completing the rescue.
; Health decay is already stopped (victim is stabilized), so timing of
; this action does not affect survival.
; ---------------------------------------------------------------------------
(:action drop
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (carrying ?r ?v)
        (safe ?loc)
        (alive ?v)
        (not (victim-dead ?v))
        (not (moving ?r))
        (not (stabilizing ?r))
    )
    :effect (and
        (victim-at ?v ?loc)
        (not (carrying ?r ?v))
    )
)

)
