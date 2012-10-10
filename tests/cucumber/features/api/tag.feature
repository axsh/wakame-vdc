@api_from_v12.03
Feature: Tag (resource groups)

  Scenario Outline: Create, show and delete
    When we make a successful api create call to <api_name> with the following options
      | account_id | name                |
      | a-shpoolxx | cucumber test group |
    Then the previous api call should be successful
    And from the previous api call take {"id":} and save it to <registry:id>

    When we make an api get call to <api_name>/<registry:id> with no options
    Then the previous api call should be successful
      And the previous api call should have {"account_id":} equal to "a-shpoolxx"
      And the previous api call should have {"name":} equal to "cucumber test group"

    When we make an api delete call to <api_name>/<registry:id> with no options
    Then the previous api call should be successful

    When we make an api get call to <api_name>/<registry:id> with no options
    Then the previous api call should not be successful

    Examples:
      | api_name            |
      | host_node_groups    |
      | storage_node_groups |
      | network_groups      |

  Scenario Outline: Map and unmap a resource
    When we make a successful api create call to <api_name> with the following options
      | account_id | name                |
      | a-shpoolxx | cucumber test group |
    Then the previous api call should be successful
    And from the previous api call take {"id":} and save it to <registry:id>

    When we make a successful api put call to <api_name>/<registry:id> with the following options
    | <mapped_resource> |
    | <resource_id>     |
    Then the previous api call should be successful

    And we make a successful api put call to <api_name>/<registry:id> with no options
    Then the previous api call should be successful
    And the previous api call should have {"mapped_uuids":} equal to ["<resource_id>"]

    When we make a successful api put call to <api_name>/<registry:id> with the following options
    | <mapped_resource> |
    |                   |
    Then the previous api call should be successful

    And we make a successful api put call to <api_name>/<registry:id> with no options
    Then the previous api call should be successful
    And the previous api call should have {"mapped_uuids":} equal to []

    When we make an api delete call to <api_name>/<registry:id> with no options
    Then the previous api call should be successful

    Examples:
      | api_name              | mapped_resource | resource_id |
      | host_node_groups      | host_nodes      | hn-demo1    |
      | storage_node_groups   | storage_nodes   | sn-demo1    |
      | network_groups        | networks        | nw-demo1    |
