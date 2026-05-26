; Problem: Complex Rescue (classical PDDL)
; Domain:  rescue_single_robot (domain.pddl)
;
; Scenario:
;   Four rooms arranged in a linear chain: roomA – roomB – roomC – roomD.
;   The robot starts in roomA (the safe exit). The victim is in roomD,
;   the room furthest from the exit. The robot must traverse three corridor
;   segments to reach the victim and three more to return — nine actions total.
;
; This instance tests that the planner can handle a longer navigation path
; and still correctly interleave stabilization and transport at the
; victim's location before returning to the safe exit.
;
; Room layout:
;   roomA <--> roomB <--> roomC <--> roomD
;   (safe)                            (victim)
;
; Expected plan:
;   0.000: (move r1 roomA roomB)
;   0.001: (move r1 roomB roomC)
;   0.002: (move r1 roomC roomD)
;   0.003: (stabilize r1 v1 roomD)
;   0.004: (pickup r1 v1 roomD)
;   0.005: (move r1 roomD roomC)
;   0.006: (move r1 roomC roomB)
;   0.007: (move r1 roomB roomA)
;   0.008: (drop r1 v1 roomA)

(define (problem complex_rescue)
(:domain rescue_single_robot)

(:objects
    r1                          - robot
    v1                          - victim
    roomA roomB roomC roomD     - room
)

(:init
    ; Robot starts at the safe exit
    (at r1 roomA)

    ; Linear corridor chain (bidirectional)
    (connected roomA roomB)
    (connected roomB roomC)
    (connected roomC roomD)
    (connected roomD roomC)
    (connected roomC roomB)
    (connected roomB roomA)

    ; Victim is at the far end of the corridor
    (victim-at v1 roomD)
    (injured v1)

    ; Only roomA is a safe drop-off point
    (safe roomA)
)

(:goal (and
    (victim-at v1 roomA)    ; victim delivered to safe exit
    (stabilized v1)         ; victim was stabilized before transport
))

)
