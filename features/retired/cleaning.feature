Feature: Car-cleaning delay after a big overshoot
  # Hypothesis #9: overshoot costs time (lost sales under the clock), so it finally feels costly.
  # C toggles the delay during playtests. Maps to tests/integration/test_pump_station.gd, tests/unit/test_pump_bay.gd.

  Scenario: A big overshoot puts the pump out of service
    Given a customer asks for $20.00
    When the pump stops at $23.00
    Then the pump shows CLEANING
    And it takes no customer for 4 seconds

  Scenario: A small overshoot does not
    Given a customer asks for $20.00
    When the pump stops at $20.80
    Then the pump is not cleaning

  Scenario: The delay can be switched off for comparison
    Given cleaning is switched off
    When the pump stops at $23.00
    Then the pump is not cleaning
