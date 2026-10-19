Feature: Super Perfect, sound effects and background music
  # #12 Super Perfect = release on the best possible frame (within 3 cents at $4/s, 60 fps);
  # the display snaps to the exact target. Tip $8, 200 XP.
  # #16 Sound is plain SFX + a looping background track (no music engineering).

  Scenario: Stopping within 3 cents is Super Perfect
    Given a customer asks for $20.00
    When the pump stops at $20.03
    Then the result is Super Perfect
    And the display shows $20.00

  Scenario Outline: Every tier has its own sound effect
    When the player stops with <tier>
    Then the <tier> sound effect plays

    Examples:
      | tier          |
      | Super Perfect |
      | Perfect       |
      | Good          |
      | OK            |
      | Miss          |

  Scenario: A broken combo has its own sound
    Given a combo above x1
    When the chain breaks
    Then the combo-break sound plays

  Scenario: Background music
    Then Roadside At Two loops in the background
