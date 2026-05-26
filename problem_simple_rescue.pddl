; Problem: Simple Rescue (classical PDDL)
; Domain:  rescue_single_robot (domain.pddl)
;
; Scenario:
;   The robot starts in roomA. The victim is in roomB, directly adjacent.
;   roomA is the safe exit. The shortest possible rescue path is:
;     move stabilize pickup move drop  (5 actions)
;
; This is the minimal instance: one robot, one victim, two rooms, one edge.
; It is used to verify basic domain correctness and to confirm that the
; task-ordering constraints (stabilize before pickup, safe room for drop)
; are correctly enforced by preconditions alone.
;
; Expected plan:
;   0.000: (move r1 roomA roomB)
;   0.001: (stabilize r1 v1 roomB)
;   0.002: (pickup r1 v1 roomB)
;   0.003: (move r1 roomB roomA)
;   0.004: (drop r1 v1 roomA)

(define (problem simple_rescue)
(:domain rescue_single_robot)

(:objects 
    r1 - robot
    v1 - victim
    roomA roomB - room
)

(:init
    (at r1 roomA)
    (connected roomA roomB)
    (connected roomB roomA)

    (victim-at v1 roomB)
    (injured v1)

    (safe roomA)
)

(:goal (and
    (victim-at v1 roomA)    
    (stabilized v1)   
))

)
