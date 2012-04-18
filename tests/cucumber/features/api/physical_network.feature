@api_from_v12.03
Feature: PhysicalNetwork API

  Scenario: Create, update and delete for new physical network
    Given a managed physical_network with the following options
      | name    | description    |
      | public1 | public network |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api update call to physical_networks/<registry:uuid> with the following options
      | description         |
      | public network test |
    Then the previous api call should be successful

    When we make an api get call to physical_networks/<registry:uuid> with no options
    Then the previous api call should be successful
    And the previous api call should have {"description":} equal to "public network test"
    And the previous api call should have {"bridge_type":} equal to "bridge"
    #And the previous api call should have {} with the key "bridge"

    When we make an api delete call to physical_networks/<registry:uuid> with no options
    Then the previous api call should be successful

  Scenario: Fails to create duplicate name
    Given a managed physical_network with the following options
      | name     | description   |
      | testnet1 | test network1 |
    And from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api create call to physical_networks with the following options
      | name     | description         |
      | testnet1 | public network test |
    Then the previous api call should not be successful

  Scenario: List physical network and filter options
    Given a managed physical_network with the following options
      | name     | description   |
      | testnet1 | test network1 |
    Given a managed physical_network with the following options
      | name     | description   |
      | testnet2 | test network2 |
    When we make an api get call to physical_networks with no options
    Then the previous api call should be successful

    When we make an api get call to physical_networks with the following options
      |created_since|
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
