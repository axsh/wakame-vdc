Feature: Network group scheduler

  Scenario: Network group with vifs parameter
    Given the following Network exist in the database
    | test_name      | ipv4_network | prefix | account_id | display_name  | network_mode   |
    | test-network1  | 192.168.2.0  | 24     | a-shpoolxx | test_network1 | securitygroup  |
    | test-network2  | 10.100.0.0   | 24     | a-shpoolxx | test_network2 | securitygroup  |
    | test-network3  | 10.101.0.0   | 24     | a-shpoolxx | test_network3 | securitygroup  |
    | test-network4  | 10.102.0.0   | 24     | a-shpoolxx | test_network4 | securitygroup  |

    And Network test-network1 has the following dhcp range
    | range_begin | range_end     |
    | 192.168.2.1 | 192.168.2.254 |

    And Network test-network2 has the following dhcp range
    | range_begin | range_end     |
    | 10.100.0.1  | 10.100.0.254  |

    And Network test-network3 has the following dhcp range
    | range_begin | range_end     |
    | 10.101.0.1  | 10.101.0.254  |

    And Network test-network4 has the following dhcp range
    | range_begin | range_end     |
    | 10.102.0.1  | 10.102.0.254  |

    And a NetworkGroup group1 exists with the following mapped resources
    | mapped_resources |
    | test-network1    |
    | test-network2    |
    And a NetworkGroup group2 exists with the following mapped resources
    | mapped_resources |
    | test-network3    |
    And a NetworkGroup default_group exists with the following mapped resources
    | mapped_resources |
    | test-network4    |

    And the following MacRange exists in the database
    | test_name | vendor_id | range_begin | range_end |
    | demomacs  | 5395456   | 1           | 16777215  |

    And the following configuration is placed in dcmgr.conf
    """
    service_type("std", "StdServiceType") {
        network_scheduler :NetworkGroup do
          network_group_id '<default_group.canonical_uuid>'
        end
    }
    """

    When an instance inst1 is scheduled with the following vifs parameter
    """
    { "eth0" => {"index" => 0, "network"=>"<group1.canonical_uuid>", "security_groups"=>[]}, "eth1" => {"index" => 1,"network" => "<group2.canonical_uuid>", "security_groups"=>[]} }
    """

    Then instance inst1 should have 2 vnics in total
    And instance inst1 should have 1 vnic in a network from group group1
    And instance inst1 should have 1 vnic in a network from group group2

    When an instance inst2 is scheduled with the following vifs parameter
    """
    { "eth0" => {"index" => 0, "security_groups"=>[]}, "eth1" => {"index" => 1, "security_groups"=>[]} }
    """

    Then instance inst2 should have 2 vnics in total
    And instance inst2 should have 2 vnics in a network from group default_group

    When an instance inst3 is scheduled with no vifs parameter
    Then instance inst3 should have 1 vnic in total
    And instance inst3 should have 1 vnic in a network from group default_group
