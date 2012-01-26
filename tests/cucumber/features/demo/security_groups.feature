Feature: Security Groups
  Security groups are user definable firewalls

  Scenario: Show individual security groups
    Given the following records exist in SecurityGroup
      | account_id | uuid      | description |
      | a-shpoolxx | sg-joske  | josgroep    |
      | a-shpoolxx | sg-jefke  | jefgroep    |
      | a-shpoolxx | sg-jantje | jangroep    |
    And the following records do not exist in SecurityGroup
      | account_id | uuid         | description  |
      | a-shpoolxx | sg-blowfish  | nothing here |
      
    When we make an api show call to security_groups/sg-joske
    Then the api call should work
    And the result uuid should be sg-joske
    And the result description should be josgroep
    
    When we make an api show call to security_groups/sg-jefke
    Then the api call should work
    And the result uuid should be sg-jefke
    And the result description should be jefgroep
    
    When we make an api show call to security_groups/sg-jantje
    Then the api call should work
    And the result uuid should be sg-jantje
    And the result description should be jangroep
    
    When we make an api show call to security_groups/sg-blowfish
    Then the api call should fail
    

  Scenario: Show all security groups
    Given the following records exist in SecurityGroup
      | account_id | uuid       | description |
      | a-shpoolxx | sg-hoge    | juij        |
      | a-shpoolxx | sg-foobar  | laal        |
      | a-shpoolxx | sg-ventje  | niksken     |
    And the following records do not exist in SecurityGroup
      | account_id | uuid         | description  |
      | a-shpoolxx | sg-nothing   | not here     |
    When we make an api show call to security_groups
    Then the api call should work
    And the results uuid should contain sg-hoge
    And the results uuid should contain sg-foobar
    And the results uuid should contain sg-ventje
    And the results uuid should not contain sg-nothing

  Scenario: Single security group negative test
    Given the following records do not exist in SecurityGroup
      | account_id | uuid         | description  |
      | a-shpoolxx | sg-nothing   | not here     |
      When we make an api show call to security_groups/sg-nothing
      Then the api call should fail
