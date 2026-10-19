Feature: Super Perfect and the backing band
  # #12. Super Perfect = release on the best possible frame (within 3 cents at $4/s, 60 fps);
  # the display snaps to the exact target. Tip $8, 200 XP.
  # Juice (M toggles): a backing band loops a 12-bar blues in A at 90 BPM; stops add melody on top.

  Scenario: Stopping within 3 cents is Super Perfect
    Given a customer asks for $20.00
    When the pump stops at $20.03
    Then the result is Super Perfect
    And the display shows $20.00

  Scenario Outline: Better stops play more notes of the current chord
    When the player stops with <tier>
    Then <notes> notes of the current bar's chord play

    Examples:
      | tier          | notes |
      | Super Perfect | 3     |
      | Perfect       | 2     |
      | Good          | 1     |
      | OK            | 0     |

  Scenario: A miss plays a sour note
    When the player stops with a Miss
    Then a clashing note plays

  Scenario: Melody notes follow the backing band
    Given the backing band is on bar 5
    When the player stops with a Good
    Then one note of D7 plays
