@api_from_v11.12
Feature: Load Balancer API

   Scenario: Create and delete new load balancer
   Given a managed load_balancer with the following options
    | instance_spec_id | protocol | port | instance_protocol | instance_port | balance_name | cookie_name | description | display_name |
    | is-demospec      | http     | 80   | http              | 80            | leastconn    | demo        | demo        | demo         |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created load_balancer has reached the state "running"

    When we make an api delete call to load_balancers/<registry:id> with no options
      Then the previous api call should be successful

