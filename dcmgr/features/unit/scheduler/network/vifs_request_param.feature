Feature: Vifs request param scheduler

  Scenario: Happy paths
    Given the following Network exist in the database
    | test_name      | ipv4_network | prefix | account_id | display_name  | network_mode   |
    | test-network1  | 192.168.2.0  | 24     | a-shpoolxx | test_network1 | securitygroup  |
    | test-network2  | 10.100.0.0   | 24     | a-shpoolxx | test_network2 | securitygroup  |
    | test-network3  | 10.101.0.0   | 24     | a-shpoolxx | test_network3 | securitygroup  |

    And Network test-network1 has the following dhcp range
    | range_begin | range_end     |
    | 192.168.2.1 | 192.168.2.254 |

    And Network test-network2 has the following dhcp range
    | range_begin | range_end     |
    | 10.100.0.1  | 10.100.0.254  |

    And Network test-network3 has the following dhcp range
    | range_begin | range_end     |
    | 10.101.0.1  | 10.101.0.254  |

    And the following MacRange exists in the database
    | test_name | vendor_id | range_begin | range_end |
    | demomacs  | 5395456   | 1           | 16777215  |

    And the following configuration is placed in dcmgr.conf
    """
    service_type("std", "StdServiceType") {
        network_scheduler :VifsRequestParam
    }
    """

    When an instance inst1 is scheduled with the following vifs parameter
    """
    { "eth0" => {"index" => 0, "network"=>"<test-network1.canonical_uuid>", "security_groups"=>[]}, "eth1" => {"index" => 1,"network" => "<test-network2.canonical_uuid>", "security_groups"=>[]} }
    """

    Then instance inst1 should have 2 vnics in total
    And instance inst1 should have 1 vnic in network test-network1
    And instance inst1 should have 1 vnic in network test-network2

    When an instance inst2 is scheduled with the following vifs parameter
    """
    { "eth0" => {"index" => 0, "network"=>"<test-network3.canonical_uuid>", "security_groups"=>[]}, "eth1" => {"index" => 1, "security_groups"=>[]} }
    """

    Then instance inst2 should have 2 vnic in total
    And instance inst2 should have 1 vnic in network test-network3
    And instance inst2 should have 1 vnic not in any network

  Scenario: Empty security groups string
    Given the following Network exist in the database
    | test_name      | ipv4_network | prefix | account_id | display_name  | network_mode   |
    | test-network1  | 192.168.2.0  | 24     | a-shpoolxx | test_network1 | securitygroup  |
    | test-network2  | 10.100.0.0   | 24     | a-shpoolxx | test_network2 | securitygroup  |
    | test-network3  | 10.101.0.0   | 24     | a-shpoolxx | test_network3 | securitygroup  |

    And Network test-network1 has the following dhcp range
    | range_begin | range_end     |
    | 192.168.2.1 | 192.168.2.254 |

    And Network test-network2 has the following dhcp range
    | range_begin | range_end     |
    | 10.100.0.1  | 10.100.0.254  |

    And Network test-network3 has the following dhcp range
    | range_begin | range_end     |
    | 10.101.0.1  | 10.101.0.254  |

    And the following MacRange exists in the database
    | test_name | vendor_id | range_begin | range_end |
    | demomacs  | 5395456   | 1           | 16777215  |


    And the following configuration is placed in dcmgr.conf
    """
    service_type("std", "StdServiceType") {
        network_scheduler :VifsRequestParam
    }
    """

    When an instance inst1 is scheduled with the following vifs parameter
    """
    { "eth0" => {"index" => 0, "network"=>"<test-network1.canonical_uuid>", "security_groups"=>""} }
    """

    Then instance inst1 should have 1 vnics in total