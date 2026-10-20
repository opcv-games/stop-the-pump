Feature: Fuel order between days  (#32)
  As a player, I want to decide each night whether to refill the tank and by how much
  so that fuel competes with upgrades for my cash (serves: Advancement, strategy).

  Scenario: Leftover fuel carries over
    Given the day ends with 150 L left in a 400 L tank
    When the next day opens without ordering fuel
    Then the tank holds 150 L

  Scenario: The night shop orders a fill-up by default
    Given the night shop opens and I can afford it
    Then the fuel order fills the tank
    And its cost is set aside from the cash I can spend on upgrades

  Scenario: Changing the order
    When I lower the fuel order to 100 L
    Then the cost drops and I have more cash for upgrades

  Scenario: The order is paid when the station opens
    Given a fuel order of 100 L
    When I open the station
    Then the cash drops by the wholesale cost of 100 L
    And the tank gains 100 L

  Scenario: The day summary charges rent only
    When a day closes
    Then the summary charges rent and shows the fuel left
