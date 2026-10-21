Feature: Short days and opening hours  (#35)
  As a player, I want short, dense days that grow as my station grows
  so that every day is tense and the early game isn't tedious (serves: Mastery, Advancement).
  Story: Dad only opened mornings. After 11 he went fishing. You keep his hours until you can do better.

  Scenario: Day 1 is a short morning
    Given a new run
    Then the station opens at 7 AM and closes at 11 AM
    And the day lasts 15 seconds

  Scenario: The HOURS branch keeps the station open longer
    When I buy "Thermos of coffee"
    Then the next day closes at 1 PM and lasts longer
    When I buy every HOURS upgrade
    Then the station closes at 11 PM and a day lasts 60 seconds

  Scenario: The clock keeps its pace
    Then one game hour always lasts the same real time

  Scenario: The sign shows the hours
    Then the pylon reads "OPEN 7 AM – 11 AM"
    And it updates when the hours grow

  Scenario: Eviction resets the hours
    Given I bought HOURS upgrades
    When a new run starts
    Then the station closes at 11 AM again
