(define (problem simple_rescue_pluss) 
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

    (= (health v1) 10)
    
)

(:goal (and
    (victim-at v1 roomA)
    (stabilized v1)
))

)
