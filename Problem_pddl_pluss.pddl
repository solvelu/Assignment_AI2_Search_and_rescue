; Simple rescue — FEASIBLE (health = 20)
;
; Health budget (decays 1.0/sec while not stabilized):
;   t=0  start-move
;   t=3  move-complete  -> health = 20 - 3 = 17
;   t=3  start-stabilize
;   t=7  stabilize-complete -> health = 17 - 4 = 13  (decay stops)
;   t=7  pickup
;   t=7  start-move
;   t=10 move-complete  -> health = 13  (no decay, already stabilized)
;   t=10 drop           -> RESCUED, health = 13  ALIVE ✓
;
; To make INFEASIBLE: change health to 6.0
;   t=3  move-complete -> health = 3
;   t=7  stabilize would finish but health hits 0 at t=6 -> death event fires
;   -> victim-dead blocks all actions -> planner reports unsolvable

(define (problem simple_rescue_plus)
(:domain rescue_time)

(:objects
    r1 - robot
    v1 - victim
    roomA roomD - room
)

(:init
    (at r1 roomA)
    (connected roomA roomD)
    (connected roomD roomA)
    (victim-at v1 roomD)
    (alive v1)
    (safe roomA)

    (= (health v1)              8.0)
    (= (move-progress r1)        0.0)
    (= (stabilize-progress r1)   0.0)
    (= (move-duration)           3.0)
    (= (stabilize-duration)      4.0)
)

(:goal (and
    (victim-at v1 roomA)
    (stabilized v1)
    (alive v1)
))

)
