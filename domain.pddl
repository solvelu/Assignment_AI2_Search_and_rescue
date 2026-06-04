; Domain: Single Robot Rescue (Classical PDDL / STRIPS)
;
; Models a mobile robot operating in a building represented as a graph of rooms.
; The robot must navigate to an injured victim, stabilize them, carry them to a
; safe exit room, and drop them there.
;
; Design notes:
;   - Actions are kept deliberately fine-grained (move, stabilize, pickup, drop)
;     rather than collapsed into a single "rescue" action. This ensures the correct
;     task ordering emerges from preconditions alone, making the domain general
;     for any room layout and victim placement.
;   - Victim state is represented as a pair of predicates (injured / stabilized).
;     A victim starts injured; stabilize transitions them to stabilized; pickup
;     requires stabilized. This chain enforces the medically correct sequence
;     without explicitly encoding ordering constraints.


(define (domain rescue_single_robot)

(:requirements :strips :typing)

(:types robot room victim)

(:predicates
    (at ?r - robot ?loc - room)        
    (connected ?from ?to - room)         

    (victim-at ?v - victim ?loc - room)   
    (injured ?v - victim)             
    (stabilized ?v - victim)            
    (carrying ?r - robot ?v - victim)    
    (safe ?loc - room)                   
)

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
