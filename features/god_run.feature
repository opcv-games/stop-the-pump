Feature: A GOD PUMP run  (#37, docs/GOD_PUMP_PLAN.md)
  As a player, I want each night to choose between investing in the shop and calling the fuel truck
  so that the run builds tension and choices (serves: Advancement, Mastery).

  Scenario: The tank starts full and drains over days
    Given a new run
    Then the tank is full
    When a day uses $150 of gas
    Then the tank holds $150 less

  Scenario: The fuel truck is the bill
    Given a half-empty tank and enough cash
    When I call the truck
    Then it fills the tank for the wholesale price of the missing gas
    And the gas price rises 12% for the next delivery
    And I choose 1 of 3 cards

  Scenario: Bankrupt
    Given an empty tank and too little cash for a delivery
    Then the run is over

  Scenario: Day 50
    When day 50 ends
    Then the run is won (Dad drives in)

  Scenario: Papa's Garage
    Given XP
    When I buy a nozzle, a bling and a perk
    Then they apply to every run
    And they are saved

  Scenario: No dead end when I forget the truck  (playtest 7)
    Given the tank won't last tomorrow
    Then the night shows a red warning to call the truck
    And buying an upgrade that leaves too little for the truck asks me to click again
    When I can't afford a full delivery but have at least $20
    Then the truck brings as much gas as my cash buys
    And a partial delivery under half a tank deals no cards
    And the run is only over when the tank is dry and I have under $20

  Scenario: Day 50 needs about two hours of Papa's Garage  (playtest 7)
    Given a fresh save
    Then the gas price climbs 25% a delivery and no run reaches day 50
    When I own the supplier's contract (prices rise 20% slower a tier)
    And premium gas (every sale pays 10% more a tier)
    Then day 50 is within reach (balance bot: about 2 h of XP, then the winning run)
