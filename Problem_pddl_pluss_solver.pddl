(define (problem simple_rescue_pluss_solver)
(:domain rescue_time_solver)
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

    (= (health v1) 6)
)

(:metric minimize (total-time))

(:goal (and
    (victim-at v1 roomA)
    (stabilized v1)
))
)
