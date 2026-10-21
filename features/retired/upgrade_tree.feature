Feature: Bills-style upgrade tree  (#31)
  As a player, I want the night upgrades laid out as one beautiful tree growing from my station
  so that I can see where my station can go and plan a route (serves: Advancement, Discovery).

  Scenario: One tree grows from the station in the centre
    Given the night shop is open
    Then the station sits in the centre of the tree
    And MARKETING, TANK, SERVICE, VIBE and PUMPS branch out in different directions
    And each pump's own tree hangs off its pump node

  Scenario: Node states read at a glance
    Given the night shop is open
    Then owned nodes are tinted and linked in gold
    And nodes I can buy next glow
    And nodes further along are dim

  Scenario: Click a node to buy it
    Given a glowing node I can afford
    When I click it
    Then it is bought and its children start to glow

  Scenario: Hovering explains a node
    When I hover a node
    Then I see its name, what it does and its price

  Scenario: Nodes show what they add
    Then every node shows an icon of the prop it adds to the station
