Feature: Network API

  Scenario: Create a network through the core API
    # Test both random network name and nw-test1.
    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description   |
      | 10.1.2.0 | 10.1.2.1 |     20 | "test create" |
    Then the create call to the networks api should be successful
    # And for create on networks the key uuid should be /^nw-*/
    And for create on networks the key ipv4_network should be 10.1.2.0
    And for create on networks the key ipv4_gw should be 10.1.2.1    
    And for create on networks the key prefix should be 20
    And for create on networks the key description should be "test create"

  Scenario: Fail to create a network through the core API
    When we make an api create call to networks with the following options
      |   network |       gw | prefix | description |
      | 256.1.2.0 | 10.1.2.1 |     20 | "test fail" |
    Then the create call to the networks api should not be successful

  Scenario: Show 2 networks through the core API
    Given the following records exist in Network
      | account_id | uuid     | prefix | ipv4_network | domain_name | description      |
      | a-shpoolxx | nw-test1 |     24 |     10.0.0.0 | vdc.local   | "test network 1" |
      | a-shpoolxx | nw-test2 |     16 |   172.16.0.0 | domein      | "test network 2" |
    
    When we make an api get call to networks with no options
    Then the get call to the networks api should be successful
    And for get on networks the results uuid should contain nw-test1
    And for get on networks the results ipv4_network should contain 10.0.0.0
    And for get on networks the results ipv4_network should contain 172.16.0.0
    
    When we make an api get call to networks/nw-test1 with no options
    Then the get call to the networks/nw-test1 api should be successful
    And for get on networks/nw-test1 the key ipv4_network should not be 10.0.0.0
    And for get on networks/nw-test1 the key prefix should be 24
    And for get on networks/nw-test1 the key description should be "test network 1"
