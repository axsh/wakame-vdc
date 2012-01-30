Feature: Network Ports API

  Scenario: Port lifecycle
    Given a new network with its uuid in registry uuid
    
    # Make dedicated function for getting list size...
    When we make an api get call to networks/<registry:uuid>/ports_index with no options
      Then the previous api call should be successful
      And the previous api call results should have 0 entries

      # Use PUT here...
    When we make an api post call to networks/<registry:uuid>/ports_create with no options
      Then the previous api call should be successful
      # Check returned values

    When we make an api get call to networks/<registry:uuid>/ports_index with no options
      Then the previous api call should be successful
      And the previous api call results should have 1 entries
      # Check returned values

    When we make an api delete call to ports/<registry:uuid> with no options
      Then the previous api call should be successful

    When we make an api get call to networks/<registry:uuid>/ports_index with no options
      Then the previous api call should be successful
      And the previous api call results should have 0 entries
      # Check returned values
