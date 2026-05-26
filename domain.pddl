; Domain: Single Robot Rescue (Classical PDDL / STRIPS)
;
; Models a mobile robot operating in a building represented as a graph of rooms.
; The robot must navigate to an injured victim, stabilize them, carry them to a
; safe exit room, and drop them there.
;
; Design rationale:
;   - Actions are kept deliberately fine-grained (move, stabilize, pickup, drop)
;     rather than collapsed into a single "rescue" action. This ensures the correct
;     task ordering emerges from preconditions alone, making the domain general
;     for any room layout and victim placement.
;   - Victim state is represented as a pair of predicates (injured / stabilized).
;     A victim starts injured; stabilize transitions them to stabilized; pickup
;     requires stabilized. This chain enforces the medically correct sequence
;     without explicitly encoding ordering constraints.
;   - No time or numeric fluents are used. All actions are instantaneous.
;     See Domain_pddl_pluss.pddl for a time-aware extension.

(define (domain rescue_single_robot)

(:requirements :strips :typing)

(:types robot room victim)

(:predicates

    ; --- Spatial state ---
    (at ?r - robot ?loc - room)           ; robot is in room ?loc
    (connected ?from ?to - room)          ; direct passage exists between rooms

    ; --- Victim state ---
    (victim-at ?v - victim ?loc - room)   ; victim is in room ?loc
    (injured ?v - victim)                 ; victim needs stabilization
    (stabilized ?v - victim)              ; victim has been stabilized; safe to carry

    ; --- Transport state ---
    (carrying ?r - robot ?v - victim)     ; robot is carrying the victim
    (safe ?loc - room)                    ; room is a valid drop-off / exit point
)

; ---------------------------------------------------------------------------
; ACTION: move
; Move the robot one step along a connected edge in the room graph.
; Precondition: robot is at the source room and the edge exists.
; Effect:       robot is now at the destination (removed from source).
; Note: movement is instantaneous in this model; see PDDL+ domain for
;       time-aware movement with genuine duration.
; ---------------------------------------------------------------------------
(:action move
    :parameters (?r - robot ?from ?to - room)
    :precondition (and
        (at ?r ?from)
        (connected ?from ?to)
    )
    :effect (and
        (not (at ?r ?from))
        (at ?r ?to)
    )
)

; ---------------------------------------------------------------------------
; ACTION: stabilize
; Robot performs on-site medical stabilization of the victim.
; Precondition: robot and victim are co-located; victim is still injured.
; Effect:       victim transitions from injured to stabilized.
; Note: must precede pickup — an unstabilized victim cannot be safely carried.
; ---------------------------------------------------------------------------
(:action stabilize
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (victim-at ?v ?loc)
        (injured ?v)
    )
    :effect (and
        (not (injured ?v))
        (stabilized ?v)
    )
)

; ---------------------------------------------------------------------------
; ACTION: pickup
; Robot lifts the stabilized victim to carry them.
; Precondition: robot and victim co-located; victim must be stabilized.
; Effect:       robot carries the victim; victim leaves their current room.
; Note: the stabilized precondition enforces the stabilize-before-pickup order.
; ---------------------------------------------------------------------------
(:action pickup
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (victim-at ?v ?loc)
        (stabilized ?v)
    )
    :effect (and
        (carrying ?r ?v)
        (not (victim-at ?v ?loc))
    )
)

; ---------------------------------------------------------------------------
; ACTION: drop
; Robot places the victim at the current location (must be a safe room).
; Precondition: robot is carrying the victim and is in a safe room.
; Effect:       victim is placed in the safe room; robot no longer carries them.
; Note: the safe precondition prevents dropping the victim in a hazardous room.
; ---------------------------------------------------------------------------
(:action drop
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (carrying ?r ?v)
        (safe ?loc)
    )
    :effect (and
        (not (carrying ?r ?v))
        (victim-at ?v ?loc)
    )
)

)
