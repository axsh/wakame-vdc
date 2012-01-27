Feature: Network API

  Scenario: Create and delete a random network
    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description   |
      | 10.1.2.0 | 10.1.2.1 |     20 | "test create" |
    Then the previous api call should be successful
      # And the previous api call should have the key uuid with /^nw-*/
      And from the previous api call save to registry uuid the value for key uuid
    When we make an api get call to networks/<registry:uuid> with no options
      Then the previous api call should be successful
    When we make an api delete call to networks/<registry:uuid> with no options
      Then the previous api call should be successful
    When we make an api get call to networks/<registry:uuid> with no options
      Then the previous api call should not be successful


  Scenario: Create and delete a named network
    # Make sure the network name doesn't exist in the database...

    # When we make an api create call to networks with the following options
    #   |  network |       gw | prefix | description   |
    #   | 10.1.2.0 | 10.1.2.1 |     20 | "test create" |
    # Then the previous api call should be successful
    # # And the previous api call should have the key uuid with /^nw-*/
    # And from the previous api call save to registry uuid the value for key uuid


  Scenario: Fail to create a duplicate named network


  Scenario: Verify network values after creation
    # Test both random network name and nw-test1.
    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description          |
      | 10.1.2.0 | 10.1.2.1 |     20 | "test create values" |
      Then the previous api call should be successful
      And the previous api call should have the key ipv4_network with 10.1.2.0
      And the previous api call should have the key ipv4_gw with 10.1.2.1
      And the previous api call should have the key prefix with 20
      And the previous api call should have the key description with "test create values"
      # Save to registry
      And from the previous api call save to registry uuid the value for key uuid

    # Verify with get call.
    When we make an api get call to networks/<registry:uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have the key uuid with <registry:uuid>
      And the previous api call should have the key ipv4_network with 10.1.2.0
      And the previous api call should have the key ipv4_gw with 10.1.2.1
      And the previous api call should have the key prefix with 20
      And the previous api call should have the key description with "test create values"

    When we make an api delete call to networks/<registry:uuid> with no options
      Then the previous api call should be successful

  Scenario: Fail to create a network through the core API
    When we make an api create call to networks with the following options
      |   network |       gw | prefix | description |
      | 256.1.2.0 | 10.1.2.1 |     20 | "test fail" |
      Then the previous api call should not be successful

    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description |
      | 10.1.2.0 | 10.1.2.a |     20 | "test fail" |
      Then the previous api call should not be successful

    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description |
      | 10.1.2.0 | 10.1.2.1 |     33 | "test fail" |
      Then the previous api call should not be successful


  Scenario: Reserve IP addresses
    Given a new network with its uuid in registry uuid
    
    When we make an api put call to networks/<registry:uuid>/reserve with the following options
      |    ipaddr |
      | 10.1.2.10 |
      Then the previous api call should be successful

    # Release IP addresses

    # Retrieve reserved IP addresses
