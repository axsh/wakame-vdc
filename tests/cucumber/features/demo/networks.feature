Feature: Networks
  Networks are the virtual networks that wakame uses
  to start its instances in.

  Scenario: Show 2 networks through the core api
    Given the following records exist in Network
      | account_id | uuid      | prefix   | ipv4_network | domain_name | description      |
      | a-shpoolxx | nw-test1  | 24       | 10.0.0.0     | vdc.local   | "test network 1" |
      | a-shpoolxx | nw-test2  | 16       | 172.16.0.0   | domein      | "test network 2" |
    
    When we make an api show call to networks
    Then the api call should work
    And the results uuid should contain nw-test1
    And the results ipv4_network should contain 10.0.0.0
    And the results ipv4_network should contain 172.16.0.0
    
    When we make an api show call to networks/nw-test1
    Then the result prefix should be 24
    And the result ipv4_netowrk should not be 10.0.0.0
    And the result description should be "test network 1"
