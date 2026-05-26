; Domain: Time-critical Rescue (PDDL+)
;
; Move and stabilize are modelled as process+event pairs so they
; genuinely consume time and allow health-decay to run between actions.
; Pickup and drop are instantaneous.
;
; The death event fires when health <= 0, setting (victim-dead)
; which blocks all further actions — forcing the planner to declare
; the branch a dead end rather than searching forever.

(define (domain rescue_time)

(:requirements :strips :fluents :typing :negative-preconditions)

(:types robot room victim)

(:predicates
    (at ?r - robot ?loc - room)
    (connected ?from - room ?to - room)
    (victim-at ?v - victim ?loc - room)
    (stabilized ?v - victim)
    (carrying ?r - robot ?v - victim)
    (safe ?loc - room)
    (alive ?v - victim)
    (victim-dead ?v - victim)    ; set by death event, blocks all actions

    (moving ?r - robot)
    (stabilizing ?r - robot)
    (move-dest ?r - robot ?loc - room)
    (stabilize-target ?r - robot ?v - victim)
)

(:functions
    (health ?v - victim)
    (move-progress ?r - robot)
    (stabilize-progress ?r - robot)
    (move-duration)
    (stabilize-duration)
)

;------------------------------------------------------------------
; PROCESS: health decays while victim is injured and alive
;------------------------------------------------------------------
(:process health-decay
    :parameters (?v - victim)
    :precondition (and
        (alive ?v)
        (not (stabilized ?v))
        (not (victim-dead ?v))
    )
    :effect (decrease (health ?v) (* #t 1.0))
)

;------------------------------------------------------------------
; PROCESS: move-progress ticks while robot is moving
;------------------------------------------------------------------
(:process moving-progress
    :parameters (?r - robot ?v - victim)
    :precondition (and 
        (moving ?r)
        (not(victim-dead ?v))
    )
    :effect (increase (move-progress ?r) (* #t 1.0))
)

;------------------------------------------------------------------
; PROCESS: stabilize-progress ticks while robot is stabilizing
;------------------------------------------------------------------
(:process stabilizing-progress
    :parameters ( ?r - robot ?v - victim)
    :precondition (and (stabilizing ?r) (not (victim-dead ?v)))
    :effect (increase (stabilize-progress ?r) (* #t 1.0))
)

;------------------------------------------------------------------
; EVENT: move completes when progress >= duration
;------------------------------------------------------------------
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

;------------------------------------------------------------------
; EVENT: stabilize completes when progress >= duration
;------------------------------------------------------------------
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

;------------------------------------------------------------------
; EVENT: victim dies — sets victim-dead to block all further actions
;------------------------------------------------------------------
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

;------------------------------------------------------------------
; ACTION: start-move
;------------------------------------------------------------------
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

;------------------------------------------------------------------
; ACTION: start-stabilize
;------------------------------------------------------------------
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

;------------------------------------------------------------------
; ACTION: pickup (instantaneous)
;------------------------------------------------------------------
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

;------------------------------------------------------------------
; ACTION: drop (instantaneous)
;------------------------------------------------------------------
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
