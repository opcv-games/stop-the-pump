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

  Scenario: Upgrades
    When the player buys Faster self-serve
    Then self-service pumps pour 50% faster
    When the player buys Card deal
    Then the card fee is 1.5%
