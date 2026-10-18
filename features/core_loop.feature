Feature: Core micro loop - pour and stop
  # Maps to BACKLOG.md "Now" items 1 and 2. Each scenario maps to at least one GUT test in tests/.

  Scenario: Amount climbs while the key is held
    Given a customer asks for $20.00
    And the pump is idle
    When the player holds the pour key
    Then the displayed amount climbs continuously

  Scenario: Releasing stops the pump after the lever delay
    Given the lever delay is 0.4 seconds
    And the player is pouring
    When the player releases the key at $19.50
    Then the pump keeps pouring for 0.4 seconds
    And the final amount is higher than $19.50

  Scenario Outline: Stop is scored by distance from the target
    Given a customer asks for $20.00
    When the final amount is <final>
    Then the result is <tier>

    Examples:
      | final  | tier    |
      | 20.05  | Perfect |
      | 19.70  | Good    |
      | 19.20  | OK      |
      | 17.00  | Miss    |

  Scenario: Overshoot is paid only up to the requested amount
    Given a customer asks for $20.00
    When the final amount is $21.00
    Then the customer pays for $20.00
    And the player absorbs the cost of $1.00 of fuel
