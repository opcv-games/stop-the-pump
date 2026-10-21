Feature: God-pump prototype  (#36)
  As a player, I want to hold a giant nozzle over my lot and pour gas straight onto the cars below
  so that filling several moving cars at once becomes a juggling hand skill (serves: Mastery, Comedy).

  Background:
    Given a top-down lot beside a road, and a giant nozzle that follows the mouse

  Scenario: Cars flow along the road; some pull in
    When the round runs
    Then cars drive along the road
    And some turn into the lot and move in a readable pattern (loop, shuttle, or park-and-go)

  Scenario: Pouring fills the car under the stream
    Given a car under the nozzle
    When I hold the mouse button
    Then that car's meter climbs at the pump's flow rate

  Scenario: A car leaves once it is 80% full
    Given a car that wants $20
    When the stream leaves it at $15 (75%)
    Then it keeps moving, $15 in its tank
    When the stream leaves it at $17 (85%)
    Then it pays, shows its fill and tip, and drives away

  Scenario: Tips grow toward 100%
    Then a car left at 95% tips more than one left at 85%
    And a car topped off to 100% without spilling tips the most

  Scenario: Overflow is wasted gas
    Given a full car
    When I keep pouring on it
    Then the extra spills on the ground as gold puddles and counts as wasted

  Scenario: The gas decides how long the round lasts
    Given the round starts with a tank of gas
    When the tank runs dry
    Then the round ends
    And a clock ends it anyway if I stop playing
