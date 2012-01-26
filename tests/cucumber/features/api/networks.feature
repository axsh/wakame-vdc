Feature: Network API

  Scenario: Create a network through the core API
    Given the following records do not exist in Network
      | account_id | uuid      |
      | a-shpoolxx | nw-test1  |

    # This isn't compatible with the new calls......

    When we make an api get call to networks with no options
    Then the get call to the networks api should be successful
    # And the results uuid should not contain nw-test1

    # Test both random network name and nw-test1.
    When we make an api create call to networks with the following options
      | network  | gw       | prefix | description   |
      | 10.1.2.0 | 10.1.2.1 | 20     | "test create" |
    Then the create call to the networks api should be successful
    # And the result uuid should be /^nw-*/
    And the result ipv4_network of create to networks should be 10.1.2.0
    And the result ipv4_gw of create to networks should be 10.1.2.1
    And the result prefix of create to networks should be 20
    And the result description of create to networks should be "test create"

    # Test invalid parameters.

  Scenario: Show 2 networks through the core api
    Given the following records exist in Network
      | account_id | uuid      | prefix   | ipv4_network | domain_name | description      |
      | a-shpoolxx | nw-test1  | 24       | 10.0.0.0     | vdc.local   | "test network 1" |
      | a-shpoolxx | nw-test2  | 16       | 172.16.0.0   | domein      | "test network 2" |
    
    When we make an api get call to networks with no options
    Then the get call to the networks api should be successful
    # And the results uuid should contain nw-test1
    # And the results ipv4_network should contain 10.0.0.0
    # And the results ipv4_network should contain 172.16.0.0
    
    When we make an api get call to networks/nw-test1 with no options
    Then the get call to the networks api should be successful
    # Then the result prefix of get to networks should be 24
    # And the result ipv4_netowrk should not be 10.0.0.0
    # And the result description should be "test network 1"
