Feature: A GOD PUMP day  (#37, docs/GOD_PUMP_PLAN.md)
  As a player, I want everything I own to shape the day, and a cast of cars that each play differently
  so that every run feels different (serves: Mastery, Advancement, Comedy).

  Scenario: The clock limits the day
    Given the store closes at 13 h
    Then the day lasts 27 seconds
    And the clock reads 7 h at the start

  Scenario: Marketing queues cars at opening
    Given 3 cars of queue
    When the day opens
    Then 3 customers are already waiting in the lot

  Scenario: Auto-aim bends the stream
    Given auto-aim
    When I pour just beside a car
    Then the car fills

  Scenario: Drone nozzles fill cars on their own
    Given a drone nozzle and a waiting car
    When time passes
    Then the drone fills and settles the car

  Scenario Outline: Car types
    Given a <car>
    Then <rule>
    Examples:
      | car      | rule                                          |
      | pickup   | it pays 80% of its sale                       |
      | bazou    | its tank takes fuel slower                    |
      | thief    | it siphons gas from customers; pouring scares it |
      | electric | pouring on it costs a $10 fine                |
      | sweeper  | it cleans the puddles it drives over          |
      | clumsy   | cars it bumps spill some of their gas         |

  Scenario: Patience
    Given a car left waiting past its patience
    Then it drives off and counts as unserved

  Scenario: The day report  (playtest 8: Misses split in two)
    When the day ends
    Then the report has loot, gas left, XP, cars, grades, accuracy and best combo
    And the grades are Super, Perfect, Good, OK, Overfilled and Unserved
    And a car that left under 80% (patience or closing) is Unserved: it isn't a car fueled,
      doesn't count against accuracy and earns no XP
