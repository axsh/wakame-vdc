@api_from_v11.12
Feature: Network API

  Scenario: Create and delete a random network
    Given a managed network with the following options
      |  network |       gw | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     20 | test create | passthru     | network1     |
      Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      # And the previous api call should have {"uuid":} equal to /^nw-*/
    When we make an api get call to networks/<registry:uuid> with no options
      Then the previous api call should be successful
    When we make an api delete call to networks/<registry:uuid> with no options
      Then the previous api call should be successful
    When we make an api get call to networks/<registry:uuid> with no options
      Then the previous api call should not be successful


  Scenario: Create and delete a named network
    # Make sure the network name doesn't exist in the database...

    # When we make an api create call to networks with the following options
    #   |  network |       gw | prefix | description | display_name |
    #   | 10.1.2.0 | 10.1.2.1 |     20 | test create | network1     |
    # Then the previous api call should be successful
    # # And the previous api call should have {"uuid":} equal to /^nw-*/
    # And from the previous api call save to registry uuid the value for key uuid

  @api_from_v12.03
  Scenario: Update network information
    Given a managed network with the following options
      |  network |       gw | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     20 | test create | passthru     | network1     |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When we make an api update call to networks/<registry:id> with the following options
      | display_name |
      | network2     |
    Then the previous api call should be successful

    When we make an api get call to networks/<registry:id> with no options
    Then the previous api call should be successful
    And the previous api call should have {"display_name":} equal to "network2"

  Scenario: Get index of networks
    When we make an api get call to networks with no options
      Then the previous api call should be successful

    Given a managed network with the following options
      |  network |       gw | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     20 | test create | passthru     | network1     |

    When we make an api get call to networks with no options
      Then the previous api call should be successful
      And the previous api call should not have [{"results":}] with a size of 0


  Scenario: Fail to create a duplicate named network

  @api_from_v12.03
  Scenario: Verify network values after creation
    # Test both random network name and nw-test1.
    Given a managed network with the following options
      |  network |       gw | prefix | description        | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     20 | test create values | passthru     | network1     |
      And the previous api call should have {"ipv4_network":} equal to "10.1.2.0"
      And the previous api call should have {"ipv4_gw":} equal to "10.1.2.1"
      And the previous api call should have {"prefix":} equal to 20
      And the previous api call should have {"description":} equal to "test create values"
      And the previous api call should have {"display_name":} equal to "network1"
      # Save to registry
      And from the previous api call take {"uuid":} and save it to <registry:uuid>

    # Verify with get call.
    When we make an api get call to networks/<registry:uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have {"uuid":} equal to <registry:uuid>
      And the previous api call should have {"ipv4_network":} equal to "10.1.2.0"
      And the previous api call should have {"ipv4_gw":} equal to "10.1.2.1"
      And the previous api call should have {"prefix":} equal to 20
      And the previous api call should have {"description":} equal to "test create values"
      And the previous api call should have {"display_name":} equal to "network1"

    When we make an api delete call to networks/<registry:uuid> with no options
      Then the previous api call should be successful

  Scenario: Fail to create a network through the core API
    When we make an api create call to networks with the following options
      |   network |       gw | prefix | description | network_mode | display_name |
      | 256.1.2.0 | 10.1.2.1 |     20 | test fail   | passthru     | network1     |
    Then the previous api call should not be successful

    When we make an api create call to networks with the following options
      |  network | gw       | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.a |     20 | test fail   | passthru     | network1     |
    Then the previous api call should not be successful

    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     33 | test fail   | passthru     | network1     |
    Then the previous api call should not be successful


  Scenario: Reserve IP addresses
    Given a new network with its uuid in <registry:uuid>

    # When we make an api put call to networks/<registry:uuid>/reserve with the following options
    #   |    ipaddr |
    #   | 10.1.2.10 |
    #   Then the previous api call should be successful

    # Release IP addresses

    # Retrieve reserved IP addresses


  @api_until_v11.12
  Scenario: Pool lifecycle for a network
    Given a new network with its uuid in <registry:uuid>

    When we make an api get call to networks/<registry:uuid>/get_pool with no options
      Then the previous api call should be successful
      And the previous api call should have [] with a size of 0

    When we make an api put call to networks/<registry:uuid>/add_pool with the following options
      | name             |
      | poll lifecycle 1 |
      Then the previous api call should be successful
      # Currently the uuid isn't returned...
      # And from the previous api call take {"uuid":} and save it to <registry:pool_uuid>

    When we make an api get call to networks/<registry:uuid>/get_pool with no options
      Then the previous api call should be successful
      And the previous api call should have [] with a size of 1
      And the previous api call should have [...,{"name":},...] equal to "poll lifecycle 1"
      # And the previous api call should have [...,{"uuid":},...] equal to <registry:pool_uuid>

    When we make an api put call to networks/<registry:uuid>/del_pool with the following options
      | name             |
      | poll lifecycle 1 |
      Then the previous api call should be successful

    When we make an api get call to networks/<registry:uuid>/get_pool with no options
      Then the previous api call should be successful
      And the previous api call should have [] with a size of 0

  Scenario: List networks with filter options
    Given a managed network with the following options
      |  network |       gw | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     20 | test create | passthru     | network1     |
    Given a managed network with the following options
      |  network |       gw | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     20 | test create | passthru     | network2     |
    When we make an api get call to networks with the following options
      |account_id|
      |a-shpoolxx|
    Then the previous api call should be successful
    When we make an api get call to networks with the following options
      |created_since            |
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
    When we make an api get call to networks with the following options
      |service_type             |
      |std                      |
    Then the previous api call should be successful
    When we make an api get call to networks with the following options
      |display_name             |
      |network1                 |
    Then the previous api call should be successful


  Scenario: Add dhcp ranges to network
    Given a managed network with the following options
      |  network |       gw | prefix | description | network_mode | display_name |
      | 10.1.2.0 | 10.1.2.1 |     24 | test dhcp   | passthru     | network_dhcp |
      Then from the previous api call take {"uuid":} and save it to <registry:uuid>
    When we make an api get call to networks/<registry:uuid>/dhcp_ranges with no options
      Then the previous api call should be successful
      And the previous api call should have [] with a size of 0
    When we make an api put call to networks/<registry:uuid>/dhcp_ranges with the following options
      | range_begin | range_end |
      |   10.1.2.10 | 10.1.2.20 |
      Then the previous api call should be successful
      And the previous api call should have {} with a size of 0
    When we make an api get call to networks/<registry:uuid>/dhcp_ranges with no options
      Then the previous api call should be successful
      And the previous api call should have [] with a size of 1
      And the previous api call should have [[]] with a size of 2
      And the previous api call should have [[]] equal to ["10.1.2.10","10.1.2.20"]

