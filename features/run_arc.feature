Feature: The run arc
  # #19, after 9 Kings: manual early, mostly automated by a third of the run; the player sets the tempo.

  Scenario: A run is 10 days
    Given the player survives day 10
    When the day ends
    Then the run-complete screen shows the run's earnings and XP
    And Enter starts a new run on day 1 with XP kept

  Scenario: Days before 10 go to the upgrade tree
    Given the player survives day 3
    When the day ends and they press Enter
    Then the upgrade tree opens

  Scenario Outline: Game speed
    When the player picks <speed>
    Then the whole game runs at <speed>

    Examples:
      | speed |
      | 1x    |
      | 2x    |
      | 3x    |
      | 10x   |

  Scenario: Full automation is allowed
    Given pumps 1 and 2
    When the player converts both to self-service
    Then both are self-service and the station keeps running

  Scenario: Endless mode
    Given the run-complete screen after day 10
    When the player presses E
    Then the night shop opens, day 11 follows, and the run only ends by eviction

  Scenario: Switching a pump between auto and manual
    Given pump 1 owns the Self-service upgrade and runs on auto
    When the player presses Shift+1 (or clicks its AUTO button)
    Then the player pours pump 1 by hand and earns tips, combo and XP
    When the player presses Shift+1 again
    Then pump 1 serves itself again

  Scenario: No switching while a self-service customer pays
    Given pump 1's self-service customer is paying
    When the player tries to switch pump 1 to manual
    Then nothing changes
