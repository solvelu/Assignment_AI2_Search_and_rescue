; Problem: Time-Critical Rescue (PDDL+)
; Domain:  rescue_time (Domain_pddl_pluss.pddl)
;
; Scenario:
;   Two rooms (roomA, roomD). Robot starts in roomA; victim is in roomD.
;   roomA is the safe exit. move-duration = 3 s, stabilize-duration = 4 s.
;
; Health budget (health decays at 1.0/sec while victim is alive and unstabilized):
;
;   t =  0.0  start-move r1 roomA -> roomD       health = 8.0
;   t =  3.0  move-complete (arrive roomD)        health = 8 - 3 = 5.0
;   t =  3.0  start-stabilize r1 v1              health = 5.0
;   t =  7.0  stabilize-complete                 health = 5 - 4 = 1.0  (decay stops)
;   t =  7.0  pickup r1 v1                       health = 1.0
;   t =  7.0  start-move r1 roomD -> roomA       health = 1.0  (no decay; stabilized)
;   t = 10.0  move-complete (arrive roomA)        health = 1.0
;   t = 10.0  drop r1 v1 roomA                   health = 1.0  RESCUED ✓
;
; The victim survives with exactly 1.0 health unit remaining.
;
; To make the problem INFEASIBLE: set health to 6.0.
;   At t = 3 health = 3.0; stabilization would take until t = 7, but
;   health reaches 0.5 at t ≈ 5.5, so the victim-death event fires first
;   and victim-dead blocks all further actions -> planner reports UNSOLVABLE.
;
; Run command:
;   java -jar enhsp-20.jar \
;        -o Domain_pddl_pluss.pddl \
;        -f Problem_pddl_pluss.pddl \
;        -planner opt-blind \
;        -delta 0.5

(define (problem simple_rescue_plus)
(:domain rescue_time)

(:objects
    r1          - robot
    v1          - victim
    roomA roomD - room
)

(:init
    (at r1 roomA)

    (connected roomA roomD)
    (connected roomD roomA)

    (victim-at v1 roomD)
    (alive v1)

    (safe roomA)
    (= (health v1) 8.0)

    ; Task progress counters start at zero
    (= (move-progress r1) 0.0)
    (= (stabilize-progress r1) 0.0)

    (= (move-duration) 3.0)
    (= (stabilize-duration) 4.0)
)

(:goal (and
    (victim-at v1 roomA)
    (stabilized v1)
    (alive v1)
))

)
