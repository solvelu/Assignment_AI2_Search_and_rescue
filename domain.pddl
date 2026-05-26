;Domain: Single robot rescue
;Description: Search and rescue domain for a single robot operating in a building
;composed of connected rooms. The robot can move between rooms, stabilize injured
;victims, pick them up once stabilized and drop them off at a safe location. 

;Key concepts: 
; - robot location and room connectivity
; - victim location, injury status and stabilization
; - carrying victims and dropping them off at safe rooms

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

; Navigation
(:action move
    :parameters (?r - robot ?from ?to - room)
    :precondition (and 
        (at ?r ?from)
        (connected ?from ?to)
    )
    :effect(and 
        (not (at ?r ?from))
        (at ?r ?to)
    )
)

; Stabilization
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

; Pick up victim
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

; Drop at safe location
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