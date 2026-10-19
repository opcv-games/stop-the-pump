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

  Scenario: Serve only parked cars (#27)
    Given a customer's car is still driving in
    Then the pump's card says "arriving..." and its key does nothing
    When the car parks at the pump
    Then the order appears and the pump can be poured

  Scenario: Cars drive smoothly (#27)
    Then cars round their corners, slow into turns and ease to a stop at the pump

  Scenario: Fuel sounds (#27)
    When a pump pours
    Then it glugs, and the counter goes crick, crack, crock each dollar

  Scenario: New pumps pop in (#27)
    Given the player built a pump in the night shop
    When the next day opens
    Then the pump rises from the ground and pops out with a puff of dust

  Scenario Outline: Every upgrade shows on the station (#28)
    Given the player buys <upgrade> in the night shop
    When the next day opens
    Then <prop> pops out of the ground

    Examples:
      | upgrade         | prop                        |
      | Bigger tank     | a white fuel tank           |
      | Flyers          | a sandwich board            |
      | Billboard       | a billboard with the name   |
      | Jukebox         | a glowing jukebox           |
      | Self-service    | a blue card reader on it    |

  Scenario: Eviction clears the props (#28)
    Given the player owns upgrades with props
    When the player is evicted and a new run starts
    Then the station is back to its run-down self
