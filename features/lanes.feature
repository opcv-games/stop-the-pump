Feature: Lanes, cars and the station's name
  # #24. One lane per pump; cars drive in at the top right and out at the bottom left.

  Scenario: One lane per pump
    Given the station has 2 pumps
    Then the world shows 2 lanes, each with an island and a pump
    When the player builds pump 3
    Then a third lane with its pump appears

  Scenario: Footprint expansion
    Given the station has 3 pumps
    When the player buys "Expand the footprint"
    Then the vacant lot and its LOT FOR SALE sign are replaced by new concrete
    And pumps 4 and 5 can now be built

  Scenario: Cars come and go
    When a customer arrives at pump 2
    Then a car in the customer's colour drives in from the top right and stops at pump 2
    When the customer is served
    Then the car drives off to the bottom left and disappears

  Scenario: A pouring pump glows
    When the player pours pump 1
    Then pump 1's globe glows brighter

  Scenario: Name your station
    Given a new run starts
    Then the player is asked to name the station, prefilled with the last name
    When they type a name and press Enter
    Then the name appears on the pylon and the day begins
