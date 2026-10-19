Feature: Random car arrivals
  # Hypothesis #10: an unpredictable arrival rhythm keeps the player alert (Mastery).

  Scenario: Cars arrive after a random wait
    Given arrivals take between 1 and 5 seconds
    When a pump finishes a customer
    Then the next car arrives after a wait between 1 and 5 seconds
    And the waits are not all the same

