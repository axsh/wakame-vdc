Feature: SecurityGroup API

  Scenario: Invalid Rule Syntax

    When we make an api create call to security_groups with the following options
      | account_id  | uuid    | rule                   | description   |
      | a-shpoolxx  |sg-test1 | "ucp,ip4,192.168.0.1"  | "test create" |
    Then the previous api call should fail with the HTTP code 400
    And the previous api call should not make the entry for the uuid sg-test1
