Feature: Network API

  Scenario: Create a network through the core API
    # Test both random network name and nw-test1.
    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description   |
      | 10.1.2.0 | 10.1.2.1 |     20 | "test create" |
    Then the previous api call should be successful
    # And the previous api call should have the key uuid with /^nw-*/
    And the previous api call should have the key ipv4_network with 10.1.2.0
    And the previous api call should have the key ipv4_gw with 10.1.2.1
    And the previous api call should have the key prefix with 20
    And the previous api call should have the key description with "test create"

  Scenario: Fail to create a network through the core API
    When we make an api create call to networks with the following options
      |   network |       gw | prefix | description |
      | 256.1.2.0 | 10.1.2.1 |     20 | "test fail" |
    Then the previous api call should not be successful

  Scenario: Show 2 networks through the core API
    Given the following records exist in Network
      | account_id | uuid     | prefix | ipv4_network | domain_name | description      |
      | a-shpoolxx | nw-test1 |     24 |     10.0.0.0 | vdc.local   | "test network 1" |
      | a-shpoolxx | nw-test2 |     16 |   172.16.0.0 | domein      | "test network 2" |
    
    When we make an api get call to networks with no options
    Then the previous api call should be successful
    And the previous api call results should contain the key uuid with nw-test1
    And the previous api call results should contain the key ipv4_network with 10.0.0.0
    And the previous api call results should contain the key ipv4_network with 172.16.0.0
    
    When we make an api get call to networks/nw-test1 with no options
    Then the previous api call should be successful
    And the previous api call should not have the key ipv4_network with 172.16.0.0
    And the previous api call should have the key ipv4_network with 10.0.0.0
    And the previous api call should have the key prefix with 24
    And the previous api call should have the key description with "test network 1"
