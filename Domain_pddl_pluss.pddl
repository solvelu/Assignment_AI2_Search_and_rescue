(define (domain rescue_time)

;remove requirements that are not needed
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

  ;Actions (same as before, shortened) 
(:action stabilize
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
      (at ?r ?loc)
      (victim-at ?v ?loc)
      (alive ?v))
    :effect (stabilized ?v)
)

(:action move
    :parameters (?r - robot ?from ?to - room)
    :precondition (and 
        (at ?r ?from) 
        (connected ?from ?to))
    :effect (and 
        (not (at ?r ?from)) 
        (at ?r ?to))
)

(:action pickup
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
      (at ?r ?loc)
      (victim-at ?v ?loc)
      (stabilized ?v))
    :effect (and 
        (carrying ?r ?v)
        (not (victim-at ?v ?loc)))
)

(:action drop
    :parameters (?r - robot ?v - victim ?loc - room)
    :precondition (and
      (at ?r ?loc)
      (carrying ?r ?v)
      (safe ?loc))
    :effect (victim-at ?v ?loc)
)
)

