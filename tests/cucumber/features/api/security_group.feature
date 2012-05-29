@api_from_v11.12
Feature: SecurityGroup API

  Scenario: Security group lifecycle
    # Given the uuid doesn't exist.

    Given a managed security_group with the following options
      | account_id | rule                      | description    | display_name |
      | a-shpoolxx | tcp:22,22,ip4:192.168.0.1 | test lifecycle | group1       | 
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the previous api call should have {"description":} equal to "test lifecycle"
      
    When we make an api get call to security_groups with no options
      Then the previous api call should be successful
      And the previous api call should have [{"results":[...,{"uuid":},...]}] equal to <registry:uuid>
      And the previous api call should have [{"results":[...,{"description":},...]}] equal to "test lifecycle"
      And the previous api call should have [{"results":[...,{"display_name":},...]}] equal to "group1"
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
      | account_id | uuid     | rule                | description | display_name |
      | a-shpoolxx | sg-test1 | ucp,ip4,192.168.0.1 | test create | group1       |
    Then the previous api call should fail with the HTTP code 400
      And the previous api call should not make the entry for the uuid sg-test1

  @api_from_12.03
  Scenario: List security groups with filter options
    Given a managed security_group with the following options
      | account_id | rule                      | description    | service_type | display_name |
      | a-shpoolxx | tcp:22,22,ip4:192.168.0.1 | test lifecycle | std          | group1       |
    Given a managed security_group with the following options
      | account_id | rule                      | description    | service_type | display_name |
      | a-shpoolxx | tcp:22,22,ip4:192.168.0.1 | test lifecycle | std          | group2       |
    When we make an api get call to security_groups with the following options
      |account_id|
      |a-shpoolxx|
    Then the previous api call should be successful
    When we make an api get call to security_groups with the following options
      |created_since            |
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
    When we make an api get call to security_groups with the following options
      |service_type             |
      |std                      |
    Then the previous api call should be successful
    When we make an api get call to security_groups with the following options
      |display_name             |
      |group1                   |
    Then the previous api call should be successful
