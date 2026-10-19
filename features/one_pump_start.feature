Feature: The run starts with one pump  (#30)
  As a new player, I want to start with a single pump
  so that I learn hold-and-release before juggling (serves: Mastery, Advancement).

  Scenario: Day 1 has one pump
    Given a new run
    Then the station has 1 pump
    And keys 1 starts it

  Scenario: The second pump is the first PUMPS upgrade
    Given a new run and enough cash
    When I buy the first PUMPS upgrade
    Then the station has 2 pumps the next day

  Scenario: Pumps 4 and 5 still need the footprint expansion
    Given the station has 3 pumps
    Then the next PUMPS upgrade is "Expand the footprint"
