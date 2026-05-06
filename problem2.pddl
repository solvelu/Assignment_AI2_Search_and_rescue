(define (problem complex_rescue)
  (:domain rescue_single_robot)

  (:objects
    r1 - robot
    v1 - victim
    roomA roomB roomC roomD - room
  )

  (:init
    (at r1 roomA)

    (connected roomA roomB)
    (connected roomB roomC)
    (connected roomC roomD)
    (connected roomD roomC)
    (connected roomC roomB)
    (connected roomB roomA)

    (victim-at v1 roomD)
    (injured v1)

    (safe roomA)
  )

  (:goal
    (and
      (victim-at v1 roomA)
      (stabilized v1))
  )
)