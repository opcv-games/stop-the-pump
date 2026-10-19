Feature: Juice
  # #26 Phase 4 game feel. Each effect has its own F2 switch; readability first (the HUD never shakes).

  Scenario: Pour stream
    When a pump pours (by hand or self-serve)
    Then fuel droplets stream from the pump to the car
    And they stop when the pour stops

  Scenario Outline: Sparkle on a great stop
    When a pump stops with <tier>
    Then a burst of <colour> stars pops from its globe

    Examples:
      | tier          | colour |
      | Perfect       | green  |
      | Super Perfect | gold   |

  Scenario: Cash pops
    When a stop earns money
    Then "+$" and the amount float up from the pump's card and fade

  Scenario: Cars arrive from the road
    When a customer is on the way to pump 2
    Then their car drives along the road, turns up the entry apron, and into lane 2
    And when served it leaves by the exit apron and back onto the road

  Scenario: Screen shake
    When a stop is a Miss, a customer drives off, or a combo breaks
    Then the world shakes briefly
    And the HUD does not move
