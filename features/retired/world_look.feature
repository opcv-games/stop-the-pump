Feature: The station world (Phase 4)
  # #22. The approved Hopper kit, isometric, painterly, lit by the day clock, with rain cycles.
  # Readability first: the HUD stays crisp on top; the pumps stay the brightest, most saturated things.

  Scenario Outline: The day clock drives the light
    Given the clock reads <time>
    Then the sun is <sun>
    And the night glow (windows, porch, pump globes) is <glow>

    Examples:
      | time  | sun                         | glow   |
      | 8 am  | low and warm, from the east | faint  |
      | 2 pm  | high and white              | faint  |
      | 10 pm | down; moonlight only        | bright |

  Scenario: Rain spells
    Given a day rolls a rain spell
    When the clock enters the spell
    Then rain falls, the light darkens and the road turns wet
    And when the spell ends the rain eases off

  Scenario: Dev rain toggle
    When the designer presses F5
    Then rain starts or stops

  Scenario: The painterly look is on the world only
    Then the world is drawn through the painterly shader
    And the HUD (numbers, orders, buttons) is drawn without it
