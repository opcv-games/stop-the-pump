Feature: Fuel economy for one stop
  # Hypothesis #3: real money from margin + tips makes precision and volume both pay (Advancement).
  # Wholesale fuel costs 80% of the pump price. Tips: Perfect $5, Good $2, OK $0. The combo multiplies tips.
  # Maps to tests/unit/test_fuel_economy.gd.

  Scenario: An exact stop earns the margin and the tip
    Given a customer asks for $20.00
    When the pump stops at $20.00 with a Perfect at combo x1
    Then the sale is $20.00, fuel costs $16.00, the tip is $5.00
    And the profit is $9.00

  Scenario: Overshoot is paid only up to the requested amount
    Given a customer asks for $20.00
    When the pump stops at $21.00
    Then the customer pays for $20.00
    And the player pays for $21.00 of fuel at wholesale

  Scenario: Stopping short earns no tip unless it is Perfect
    Given a customer asks for $20.00
    When the pump stops at $19.70 with a Good
    Then the sale is $19.70 and there is no tip

  Scenario: The combo multiplies the tip
    Given a customer asks for $20.00
    When the pump stops at $20.30 with a Good at combo x3
    Then the tip is $6.00
