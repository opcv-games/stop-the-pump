Feature: Story intro — you inherit your late father's gas station  (#29)
  As a new player, I want a short story before day 1
  so that I know why I'm running this sad little station (serves: Comedy, Advancement).

  Scenario: The intro plays before the naming screen
    Given I start a new game
    Then the intro tells me my father passed away and left me a gas station in Québec
    And the last card asks "Are you up to the challenge?"

  Scenario: Accepting the challenge leads to naming the station
    Given the intro is on its last card
    When I press Enter
    Then the naming screen appears

  Scenario: Any key moves the story on, Esc skips it
    Given the intro is playing
    When I press Space
    Then the next card shows
    When I press Esc
    Then the intro jumps to its last card

  Scenario: The intro only plays on the first run of a session
    Given I was evicted and start a new run
    Then the naming screen appears without the intro
