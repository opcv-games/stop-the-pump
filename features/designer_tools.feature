Feature: Designer tools
  # #13: test outcomes and tune numbers without waiting for a build.

  Scenario Outline: Dev mode forces a stop
    Given dev mode is on (F1) and pump 1 has a customer
    When the designer presses <key>
    Then pump 1 stops with <result>

    Examples:
      | key | result              |
      | Q   | Super Perfect       |
      | W   | Perfect             |
      | E   | Good                |
      | R   | OK                  |
      | T   | a Miss $10 short    |
      | Y   | a Miss $10 over     |

  Scenario: A tuning slider applies at once and is remembered
    Given the tuning panel is open (F2)
    When the designer sets the flow rate to $6/s
    Then every pump pours at $6/s
    And the value is still $6/s next session
