@multiple @openflow
Feature: Virtual Network Tests

  Scenario: Ping from one instance to another over a virtual network
    Given a new instance with its uuid in <instance_1:uuid>
    And a new instance with its uuid in <instance_2:uuid>
    And the instance <instance_1:uuid> enables all network interfaces
    And the instance <instance_2:uuid> enables all network interfaces

    When we ping from instance <instance_1:uuid> to <instance_2:uuid> over the network "nw-demo2"
