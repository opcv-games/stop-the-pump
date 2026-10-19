Feature: Self-service pumps
  # #17 (replaces the Turbo nozzle). A converted pump serves customers without the player.
  # Guardrails (design rule 1): it earns less than a played pump and never feeds combo or XP.

  Scenario: A self-service customer
    Given pump 3 is self-service
    When a car arrives asking for $20.00
    Then the customer fumbles with the card for a few seconds
    And pumps exactly $20.00 at half speed
    And takes 2 seconds to pay

  Scenario: Self-service money
    Given a self-service sale of $20.00 and a 3% card fee
    Then cash gets $19.40
    And there is no tip, no combo change and no XP

  Scenario: The player can't pour a self-service pump
    Given pump 3 is self-service
    When the player presses 3
    Then nothing happens

  Scenario: Each pump has its own tree (#18)
    Given the night shop's "Your pumps" page (Tab)
    When the player buys pump 3's Self-service, then Faster self-serve, then Card deal
    Then pump 3 serves itself, pours 50% faster, and pays a 1.5% card fee
    And the other pumps are unchanged

  Scenario: The player keeps at least one pump
    Given pump 2 is the only pump the player still pours
    When the player tries to convert pump 2
    Then nothing is bought
