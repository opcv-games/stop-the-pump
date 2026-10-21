Feature: Several pumps at once
  # Hypothesis #4: juggling pumps creates depth a single pump cannot (Mastery).
  # Maps to tests/integration/test_pump_station.gd.

  Scenario: Pumps pour independently
    Given two customers are waiting at pumps 1 and 2
    When the player holds key 1 and key 2 together
    Then both amounts climb independently

  Scenario: Releasing one pump leaves the other running
    Given pumps 1 and 2 are both pouring
    When the player releases key 1 only
    Then pump 1 stops
    And pump 2 keeps pouring

  Scenario: The combo is shared by the whole station
    Given the combo is x1
    When pump 1 stops Perfect and then pump 2 stops Good
    Then the combo is x3

  Scenario: A bad stop on any pump breaks the shared combo
    Given the combo is x3
    When pump 2 stops with a Miss
    Then the combo resets to x1
