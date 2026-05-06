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
