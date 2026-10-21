Feature: A full day at the station
  # #8: the station is open 7am-11pm (3 real minutes). One 400 L tank feeds every pump at $2/L.
  # Costs land at the end of the day: refill at wholesale (80%) and rent.
  # Maps to tests/unit/test_tank_component.gd, test_day_clock.gd and tests/integration/test_pump_station.gd.

  Scenario: Pumping drains the shared tank
    Given the tank holds 400 L at $2 per litre
    When a pump pours $20.00
    Then the tank holds 390 L

  Scenario: An empty tank stops the pour
    Given the tank holds 1 L
    When a pump pours past $2.00
    Then the pump stops at $2.00

  Scenario: The day ends when the clock runs out
    Given the station opened at 7am
    When 3 minutes pass
    And every pump is idle
    Then the end-of-day screen shows earnings, refill cost, rent and cash

  Scenario: The day ends when the tank is empty
    Given the tank runs empty
    When every pump is idle
    Then the end-of-day screen appears

  Scenario: Unpaid rent ends the run
    Given the costs are more than the player's cash
    When the day ends
    Then the player is evicted and the run is over
