;Domain: Time-critical Rescue (planner-friendly durative model)

;Description: A single rescue robot operates in a known building with connected rooms and one injured victim.
;Victim health is modeled as a numeric resource that decreases when actions take time.
;This model removes the PDDL+ process/event pair to make the domain easier for common planners.

(define (domain rescue_time_solver)

(:requirements :strips :durative-actions :fluents :typing :negative-preconditions)

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

(:durative-action stabilize
    :parameters (?r - robot ?v - victim ?loc - room)
    :duration (= ?duration 2)
    :condition (and
        (at start (at ?r ?loc))
        (at start (victim-at ?v ?loc))
        (at start (alive ?v))
        (over all (> (health ?v) 0)))
    :effect (and
        (at end (stabilized ?v))
        (at end (decrease (health ?v) 2)))
)

(:durative-action move
    :parameters (?r - robot ?from ?to - room ?v - victim)
    :duration (= ?duration 1)
    :condition (and
        (at start (at ?r ?from))
        (at start (connected ?from ?to))
        (at start (alive ?v))
        (over all (> (health ?v) 0)))
    :effect (and 
        (at start (not (at ?r ?from))) 
        (at end (at ?r ?to))
        (at end (decrease (health ?v) 1)))
)

(:durative-action pickup
    :parameters (?r - robot ?v - victim ?loc - room)
    :duration (= ?duration 1)
    :condition (and
        (at start (at ?r ?loc))
        (at start (victim-at ?v ?loc))
        (at start (alive ?v))
        (at start (stabilized ?v))
        (over all (> (health ?v) 0)))
    :effect (and 
        (at end (carrying ?r ?v))
        (at end (not (victim-at ?v ?loc)))
        (at end (decrease (health ?v) 1)))
)

(:durative-action drop
    :parameters (?r - robot ?v - victim ?loc - room)
    :duration (= ?duration 1)
    :condition (and
        (at start (at ?r ?loc))
        (at start (carrying ?r ?v))
        (at start (safe ?loc))
        (at start (alive ?v))
        (over all (> (health ?v) 0)))
    :effect (and
        (at end (victim-at ?v ?loc))
        (at end (decrease (health ?v) 1)))
)
)
