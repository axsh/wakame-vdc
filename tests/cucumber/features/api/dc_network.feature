@api_from_v12.03
Feature: DcNetwork API

  Scenario: Create, update and delete for new dc network
    Given a managed dc_network with the following options
      | name    | description    |
      | public1 | public network |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api update call to dc_networks/<registry:uuid> with the following options
      | description         |
      | public network test |
    Then the previous api call should be successful

    When we make an api get call to dc_networks/<registry:uuid> with no options
    Then the previous api call should be successful
    And the previous api call should have {"description":} equal to "public network test"
    # Skip until json_spec is enabled.
    #And the previous api call should have {"offering_network_modes":} equal to "['passthru']"

    When we make an api delete call to dc_networks/<registry:uuid> with no options
    Then the previous api call should be successful

  Scenario: Fails to create duplicate name
    Given a managed dc_network with the following options
      | name     | description   |
      | testnet1 | test network1 |
    And from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api create call to dc_networks with the following options
      | name     | description         |
      | testnet1 | public network test |
    Then the previous api call should not be successful

  Scenario: List dc network and filter options
    Given a managed dc_network with the following options
      | name     | description   |
      | testnet1 | test network1 |
    Given a managed dc_network with the following options
      | name     | description   |
      | testnet2 | test network2 |
    When we make an api get call to dc_networks with no options
    Then the previous api call should be successful

    When we make an api get call to dc_networks with the following options
      |created_since|
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful

  Scenario: Offering network mode
    Given a managed dc_network with the following options
      | name     | description   |
      | testnet1 | test network1 |
    And from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api get call to dc_networks/<registry:uuid>/offering_modes with no options
    Then the previous api call should be successful

    When we make an api put call to dc_networks/<registry:uuid>/offering_modes/add with the following options
      | mode     |
      | passthru |
    Then the previous api call should be successful
    When we make an api put call to dc_networks/<registry:uuid>/offering_modes/delete with the following options
      | mode     |
      | passthru |
    Then the previous api call should be successful
    When we make an api put call to dc_networks/<registry:uuid>/offering_modes/add with the following options
      | mode        |
      | unknownmode |
    Then the previous api call should not be successful
