Feature: Random car arrivals and the chord progression
  # Hypothesis #10: an unpredictable arrival rhythm keeps the player alert (Mastery).
  # Juice, judged with M: good stops walk C-G-Am-F; a broken chain falls apart.

  Scenario: Cars arrive after a random wait
    Given arrivals take between 1 and 5 seconds
    When a pump finishes a customer
    Then the next car arrives after a wait between 1 and 5 seconds
    And the waits are not all the same

  Scenario: Each good stop plays the next chord
    Given a chain of 5 good stops
    Then the chords played are C, G, Am, F, C

  Scenario: A broken chain restarts the progression
    Given a chain of 3 good stops
    When the next stop is a Miss
    Then the next good stop plays C again
