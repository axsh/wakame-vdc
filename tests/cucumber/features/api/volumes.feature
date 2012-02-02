Feature: Volume API

  Scenario: Create and delete new volume
    When we make an api create call to volumes with the following options
      | volume_size |
      | 10          |
    Then the previous api call should be successful
    And from the previous api call take {"uuid":} and save it to <registry:uuid>
    Then the created volumes should reach state available in 60 seconds or less
    
    When we make an api delete call to volumes/<registry:uuid> with no options
    Then the previous api call should be successful  
    
  Scenario: Create blank volume less than minimum size
    When we make an api create call to volumes with the following options
      | volume_size |
      | 9           |
    Then the previous api call should not be successful

  Scenario: Create minimum size blank volume
    When we make an api create call to volumes with the following options
      | volume_size |
      | 10          |
    Then the previous api call should be successful 

  Scenario: Create blank volume more than maximum size
    When we make an api create call to volumes with the following options
      | volume_size |
      | 3001        |
    Then the previous api call should not be successful
  
  Scenario: Create maximum size blank volume
    When we make an api create call to volumes with the following options
      | volume_size |
      | 3000        |
    Then the previous api call should be successful

