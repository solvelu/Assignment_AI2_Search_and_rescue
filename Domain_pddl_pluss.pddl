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
    (at ?r - robot ?loc - room)
    (connected ?from - room ?to - room)
    (victim-at ?v - victim ?loc - room)
    (stabilized ?v - victim)            
    (alive ?v - victim)
    (victim-dead ?v - victim)            

    (carrying ?r - robot ?v - victim)
    (safe ?loc - room)

    (moving ?r - robot)
    (stabilizing ?r - robot)
    (move-dest ?r - robot ?loc - room)
    (stabilize-target ?r - robot ?v - victim)

(:functions
    (health ?v - victim)
    (move-progress ?r - robot)
    (stabilize-progress ?r - robot)
    (move-duration)
    (stabilize-duration)
)

(:process health-decay
    :parameters (?v - victim)
    :precondition (and
        (alive ?v)
        (not (stabilized ?v))
        (not (victim-dead ?v))
    )
    :effect (decrease (health ?v) (* #t 1.0))
)

(:process moving-progress
    :parameters (?r - robot ?v - victim)
    :precondition (and
        (moving ?r)
        (not (victim-dead ?v))
    )
    :effect (increase (move-progress ?r) (* #t 1.0))
)


(:process stabilizing-progress
    :parameters (?r - robot ?v - victim)
    :precondition (and
        (stabilizing ?r)
        (not (victim-dead ?v))
    )
    :effect (increase (stabilize-progress ?r) (* #t 1.0))
)


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
