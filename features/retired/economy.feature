Feature: Cash and XP for one stop
  # Revised after playtest 5 (#3, #8). Cash = full sale + tier tip; the combo never changes cash.
  # XP = tier points x combo. Tips: Perfect $5, Good $2. XP: Perfect 100, Good 50, OK 10.
  # Maps to tests/unit/test_fuel_economy.gd.

  Scenario: An exact stop earns the full sale and the tip
    Given a customer asks for $20.00
    When the pump stops at $20.00 with a Perfect
    Then the customer pays $20.00 plus a $5.00 tip

  Scenario: Overshoot is paid only up to the requested amount
    Given a customer asks for $20.00
    When the pump stops at $21.00
    Then the customer pays $20.00
    And $1.00 of fuel was given away from the tank

  Scenario: Stopping short earns no tip unless it is Perfect
    Given a customer asks for $20.00
    When the pump stops at $19.70 with a Good
    Then the customer pays $19.70 and there is no tip

  Scenario: The combo multiplies XP, not cash
    Given the combo is x3
    When the pump stops with a Perfect
    Then the player earns 300 XP
    And the tip is still $5.00
