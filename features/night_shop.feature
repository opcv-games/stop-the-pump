Feature: The night shop
  # #14: after each day (if not evicted), 3 random upgrades bought with cash. Each helps and costs
  # something (design rule 1). Upgrades last for the run and are lost on eviction.

  Scenario: The shop opens after a day
    Given the day ended and the player was not evicted
    When the player presses Enter on the summary
    Then the night shop shows 3 different upgrades with prices

  Scenario: Buying an upgrade
    Given the player has enough cash
    When the player presses the upgrade's number
    Then its price is paid and its effect and downside apply

  Scenario: Not enough cash
    Given the player cannot afford an upgrade
    When the player presses its number
    Then nothing is bought

  Scenario: Rerolling
    When the player presses R
    Then the reroll price is paid and 3 new upgrades are offered

  Scenario: Eviction wipes the run's upgrades
    Given the player owns upgrades
    When the player is evicted and a new run starts
    Then the station is back to its starting setup

  Scenario Outline: Each upgrade's effect and downside
    When the player buys <upgrade>
    Then <effect>
    And <downside>

    Examples:
      | upgrade      | effect                                  | downside                              |
      | Bigger tank  | the tank holds 100 L more               | rent is $20 more per day              |
      | Turbo nozzle | one pump pours 30% faster               | that pump is harder to stop precisely |
      | Flyers       | cars arrive 30% sooner                  | $50 and $60 orders join the mix       |
      | Extra pump   | the station has one more pump           | rent is $40 more per day              |
      | Squeegee     | car cleaning takes 2 s                  | each cleaning costs $5                |
      | Tip jar      | Good or better earns $2 more            | OK or Miss costs $2                   |
      | Bluesy radio | the combo can go one higher             | the Good window is 10% narrower       |
