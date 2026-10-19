Feature: The upgrade tree
  # #15 (replaces the random shop of #14). After each day (if not evicted) the player spends cash on a
  # Bills-style tree of 5 branches. Upgrades cost cash only: no gameplay downside (design rule 1).
  # They last for the run and are lost on eviction.

  Scenario: The tree opens after a day
    Given the day ended and the player was not evicted
    When the player presses Enter on the summary
    Then the tree shows 5 branches, each with its next upgrade and price

  Scenario: Buying the next upgrade in a branch
    Given the player has enough cash
    When the player presses the branch's number
    Then its price is paid, its effect applies, and the branch moves on to its next upgrade

  Scenario: Not enough cash
    Given the next upgrade in a branch costs more than the player's cash
    When the player presses the branch's number
    Then nothing is bought

  Scenario: A finished branch
    Given every upgrade in a branch is owned
    Then the branch shows it is complete and its number does nothing

  Scenario: Eviction resets the tree
    Given the player owns upgrades
    When the player is evicted and a new run starts
    Then the station is back to its starting setup and the tree is empty

  Scenario Outline: Branches
    Then branch <n> is <branch>: <upgrades>

    Examples:
      | n | branch    | upgrades                                                                                     |
      | 1 | Marketing | Flyers (cars 20% sooner), Radio ad (20% sooner), Billboard ($50 and $60 orders)              |
      | 2 | Pumps     | Pump 3, Pump 4, Pump 5 (each pump then has its own tree on the Your pumps page)               |
      | 3 | Tank      | +100 L, +100 L, +100 L                                                                       |
      | 4 | Service   | Squeegee (cleaning 2 s), Tip jar (+$2 on Good or better), Pressure washer (cleaning 1 s)     |
      | 5 | Vibe      | Bluesy radio (max combo +1), Jukebox (max combo +1)                                          |
