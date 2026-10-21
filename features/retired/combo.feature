Feature: Combo multiplier
  # Hypothesis #7: chained good stops give every stop stakes (Mastery).
  # Each scenario maps to at least one GUT test in tests/unit/test_combo_component.gd.

  Scenario: A good stop pays at the current multiplier, then grows it
    Given the combo is x3
    When the player stops with Good
    Then the stop's tip is paid at x3
    And the combo becomes x4

  Scenario: An OK or Miss breaks the chain
    Given the combo is x3
    When the player stops with OK
    Then the stop's tip is paid at x1
    And the combo resets to x1

  Scenario: The multiplier is capped
    Given the combo is at the maximum
    When the player stops with Perfect
    Then the combo stays at the maximum
