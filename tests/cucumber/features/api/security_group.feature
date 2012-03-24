@api_from_v11.12
Feature: SecurityGroup API

  Scenario: Security group lifecycle
    # Given the uuid doesn't exist.

    Given a managed security_group with the following options
      | account_id | rule                      | description    |
      | a-shpoolxx | tcp:22,22,ip4:192.168.0.1 | test lifecycle |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the previous api call should have {"description":} equal to "test lifecycle"
      
    When we make an api get call to security_groups with no options
      Then the previous api call should be successful
      And the previous api call should have [{"results":[...,{"uuid":},...]}] equal to <registry:uuid>
      And the previous api call should have [{"results":[...,{"description":},...]}] equal to "test lifecycle"
      # Check values.

    When we make an api delete call to security_groups/<registry:uuid> with no options
      Then the previous api call should be successful

    When we make an api get call to security_groups with no options
      Then the previous api call should be successful
      # Store the value in a registry matching the uuid, and do the
      # checks on that instead
      And the previous api call should not have [{"results":[...,{"uuid":},...]}] equal to <registry:uuid>

  Scenario: Invalid Rule Syntax

    When we make an api create call to security_groups with the following options
      | account_id | uuid     | rule                | description |
      | a-shpoolxx | sg-test1 | ucp,ip4,192.168.0.1 | test create |
    Then the previous api call should fail with the HTTP code 400
      And the previous api call should not make the entry for the uuid sg-test1
