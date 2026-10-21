Feature: God-pump prototype  (#36)
  As a player, I want to hold a giant nozzle over my lot and pour gas straight onto the cars below
  so that stopping on the dollar becomes a moving, juggling hand skill (serves: Mastery, Comedy).

  Background:
    Given a top-down lot beside a road, and a giant nozzle that follows the mouse

  Scenario: Cars flow along the road; some pull in
    When the round runs
    Then cars drive along the road
    And some turn into the lot and drive around it with an order over their roof

  Scenario: Pouring fills the car under the stream
    Given a car under the nozzle
    When I hold the mouse button
    Then that car's meter climbs at the pump's flow rate

  Scenario: You can only overfill
    Given a car that wants $20
    When the stream leaves it at $15
    Then it keeps driving around the lot, $15 in its tank
    When the stream leaves it at $20.02
    Then it scores Super Perfect, plays its Super Perfect animation, pays and drives away

  Scenario Outline: The overshoot decides the tier and the animation
    When the stream leaves a $20 car at <amount>
    Then it scores <tier>
    Examples:
      | amount | tier          |
      | 20.00  | Super Perfect |
      | 20.08  | Perfect       |
      | 20.40  | Good          |
      | 20.90  | OK            |
      | 22.00  | Miss          |

  Scenario: Gas on the floor is wasted
    When I pour where there is no car
    Then a gold puddle spreads on the ground
    And the wasted fuel is counted against the round

  Scenario: The round ends
    Given a 15-second round
    When time runs out
    Then the cars still in the lot leave, paying only for what they got
