Feature: Balance simulator (bot harness)  (#6)
  As the designer, I want bots to play thousands of runs headless with different buying strategies
  so that I can see which strategies win and tune the economy (serves: balance for Advancement).

  Background:
    Given a bot that lands Super Perfect, Perfect, Good, OK and Miss equally often
    And the game's real prices, upgrades, rent and customer rules

  Scenario: A day is played
    When the bot plays one day with one pump
    Then cars are served, fuel leaves the tank and cash comes in

  Scenario: Tiers are evenly split
    When the bot plays many days
    Then each tier makes up about a fifth of the stops

  Scenario: The tank caps the day
    Given an almost empty tank
    When the bot plays a day
    Then the day ends when the tank runs dry

  Scenario: Rent can evict
    Given a station with no cash and no customers
    When the day closes
    Then the run ends in eviction

  Scenario: Strategies are compared
    When every strategy plays thousands of seeded runs
    Then a report ranks them by survival and final cash
