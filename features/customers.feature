Feature: Customers with rules
  # #5. Design rule 2: every customer changes one variable of the micro loop. Dialogue is flavour on top.
  # Grey visuals: a small car in front of each pump (colour = type) and a speech bubble.

  # Retired after playtest 15 (everyone pays cash); kept for reference and its tests.
  Scenario: The $20 Guy pays exactly twenty
    Given a $20 Guy at pump 1
    When the pump stops at $22.00
    Then he pays $20.00
    And the $2.00 over comes out of the player's own cash

  Scenario: The Confused Grandpa changes his mind once
    Given Grandpa asked for $30.00
    When the pour passes $18.00
    Then his order changes to an amount at least $3.00 above the meter
    And it never changes again for that car

  Scenario: The Impatient Businessman drives off
    Given a Businessman pulls in
    When 4 seconds pass and the player hasn't started pouring
    Then he drives off, there is no sale, and the combo breaks

  Scenario: Starting in time keeps the Businessman
    Given a Businessman pulls in
    When the player starts pouring within 4 seconds
    Then he stays

  Scenario: Cars and speech bubbles
    Given a customer at a pump
    Then a car sits in front of the pump and the customer says something
    When the pump has no customer
    Then there is no car

  Scenario: Self-service pumps only get regular customers
    Given pump 3 is self-service
    Then its customers are always Regulars
