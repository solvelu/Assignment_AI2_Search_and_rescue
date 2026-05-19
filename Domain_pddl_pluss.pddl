;Domain: Time-critical Rescue (PDDL+)

;Description: A single rescue robot operates in a known building with connected rooms and one injured victim.
;Victim health decreases in discrete time steps, and a death event is triggered when health reaches zero.

;The robot must plan a sequence of actions that finishes rescue before the victim becomes unrecoverable.

;Key concepts: 
; - discrete health decay when actions or wait steps occur
; - event 'victim-death' represents critical failure
; - timing affects rescue feasibility because actions consume health

(define (domain rescue_time)

(:requirements :strips :durative-actions :fluents :typing :negative-preconditions :continuous-effects)

(:types robot room victim)

(:predicates 
    (at ?r - robot ?loc - room)
    (connected ?from - room ?to - room)
    (victim-at ?v - victim ?loc - room)
    (stabilized ?v - victim)
    (carrying ?r - robot ?v - victim)
    (safe ?loc - room)
    (alive ?v - victim)
)

(:functions 
    (health ?v - victim)
)

;Process: health decreases
(:process health-decay
    :parameters (?v - victim)
    :precondition (and 
        (alive ?v) 
        (not (stabilized ?v)))
    :effect (decrease 
        (health ?v) 
        (* 1 #t))
)

;Event: victim dies
(:event victim-death
    :parameters (?v - victim)
    :precondition (and 
        (alive ?v) 
        (<= (health ?v) 0))
    :effect (not (alive ?v))
)

(:action stabilize
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (victim-at ?v ?loc)
        (alive ?v))
    :effect (and
        (stabilized ?v))
)

(:action move
    :parameters (?r - robot ?from ?to - room ?v - victim)
    :precondition (and 
        (at ?r ?from) 
        (connected ?from ?to)
        (alive ?v))
    :effect (and 
        (not (at ?r ?from)) 
        (at ?r ?to)
        (decrease (health ?v) 1))
)

(:action pickup
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (victim-at ?v ?loc)
        (alive ?v)
        (stabilized ?v))
    :effect (and 
        (carrying ?r ?v)
        (not (victim-at ?v ?loc))
        (decrease (health ?v) 1))
)

(:action drop
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
        (at ?r ?loc)
        (carrying ?r ?v)
        (safe ?loc)
        (alive ?v))
    :effect (and
        (victim-at ?v ?loc)
        (decrease (health ?v) 1))
)
)