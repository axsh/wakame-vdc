Feature: Network Port Attachments API

  Scenario: Attachment lifecycle
    Given a new network with its uuid in <registry:network_uuid>
    And a new port in <registry:network_uuid> with its uuid in <registry:port_uuid>

    
