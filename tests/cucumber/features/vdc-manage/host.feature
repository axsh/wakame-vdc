Feature: vdc-manage host
  CLI operations for hosts

  Scenario: Create an host, delete it
    Given the working directory is dcmgr/bin
    And 1 hosts are created
    When we delete the hosts

  Scenario: Create an host, show it, delete it
    Given the working directory is dcmgr/bin
    And 1 hosts are created
    Then we should be able to show the hosts
    When we delete the hosts

  Scenario: Create an host, delete it and be able to add it again
    Given the working directory is dcmgr/bin
    And 1 hosts are created
    Then we should not be able to create hosts with the same uuids
    When we delete the hosts
