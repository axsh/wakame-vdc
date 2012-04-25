@api_from_v12.03
Feature: Network Services API

  Scenario: Verify default services for nw-demo6

    When we make an api get call to networks/nw-demo6 with no options
     And the previous api call should be successful

    Then from the previous api call take {"network_services":[...,,...]} and save it to <service:gateway> for {"name":} equal to "gateway"
     And from the previous api call take {"network_services":[...,,...]} and save it to <service:dhcp>    for {"name":} equal to "dhcp"
     And from the previous api call take {"network_services":[...,,...]} and save it to <service:dns>     for {"name":} equal to "dns"

    Then <service:gateway> should have {"name":} equal to "gateway"

    Then <service:gateway> should have {"address":} equal to "10.102.0.1"
     And <service:dhcp>    should have {"address":} equal to "10.102.0.2"
     And <service:dns>     should have {"address":} equal to "10.102.0.2"
     And <service:gateway> should have {"instance_uuid":} equal to nil
     And <service:dhcp>    should have {"instance_uuid":} equal to nil
     And <service:dns>     should have {"instance_uuid":} equal to nil

    Then <service:gateway> should have {"mac_addr":} unequal to nil
     And <service:dhcp>    should have {"mac_addr":} unequal to nil
     And <service:dns>     should have {"mac_addr":} unequal to nil

    Then from <service:dhcp> take {"mac_addr":} and save it to <service:dhcp:mac_addr>
     And <service:dns>       should have {"mac_addr":} equal to <service:dhcp:mac_addr>
     And <service:gateway>   should have {"mac_addr":} unequal to <service:dhcp:mac_addr>
