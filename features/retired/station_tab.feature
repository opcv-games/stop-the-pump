Feature: "Your station" tab in the night shop  (#33)
  As a player, I want to build and improve pumps right on my station
  so that the tree stays about the station and pumps are bought where they stand (serves: Advancement).

  Scenario: Two tabs at night
    Given the night shop is open
    Then the UPGRADE TREE tab shows the station-wide branches without any pump nodes
    When I press Tab
    Then the YOUR STATION tab shows my station

  Scenario: Each pump carries its own upgrades
    Given the YOUR STATION tab
    Then every pump has a card on it with Self-service, Faster self-serve and Card deal
    When I click the glowing upgrade on pump 1
    Then pump 1 gets it

  Scenario: Building the next pump
    Given one pump
    Then a "Build pump 2" card stands on the next lane with its price
    When I click it
    Then pump 2 is built and a "Build pump 3" card appears

  Scenario: Expanding the lot
    Given three pumps
    Then the next card offers to expand the lot
