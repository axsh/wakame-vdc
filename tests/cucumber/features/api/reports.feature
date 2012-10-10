@api_from_v11.12
Feature: Report API
  Scenario: GET index of reports
    Given a new instance with its uuid in <instance:uuid>
    When we make an api get call to reports with no options
    Then the previos report api call should be successful with resource_type "Instance"
    And the following values exists:
      |     value|
      |      init|
      |scheduling|
      |   pending|
      |  starting|
      |   running|
#    And the JSON should be a hash
#    And the JSON response at "uuid" should match "i-*"
#    And the JSON response at "resource_type" should be "Instance"
#    And the JSON response at "event_type" should be "state"
#    And the JSON response at "value" should be "<value>"
#    And the JSON response at "time" should match format "ISO8601"

    Given a new volume with its uuid in <volume:uuid>
    When we make an api get call to reports with no options
    Then the previos report api call should be successful with resource_type "Volume"
    And the following values exists:
      |      value|
      |initialized|
      |    pending|
      |   creating|
      |  available|
#    And the JSON should be a hash
#    And the JSON response at "uuid" should match "v-*"
#    And the JSON response at "resource_type" should be "Instance"
#    And the JSON response at "event_type" should be "state"
#    And the JSON response at "value" should be "terminating"
#    And the JSON response at "time" should match format "ISO8601"
