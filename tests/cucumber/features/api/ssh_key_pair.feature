Feature: SshKeyPair API

  Scenario: Create, update and delete for new ssh key pair with UUID

  Scenario: Create, update and delete for new ssh key pair
    When we make an api create call to ssh_key_pairs with the following options
      | description |
      | "test key1" |
    Then the previous api call should be successful
    And from the previous api call save to registry uuid the value for key uuid

    When we make an api update call to ssh_key_pairs/<registry:uuid> with the following options
      | description     |
      | "test key key1" |
    Then the previous api call should be successful

    When we make an api get call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful
    And the single result from the previous api call should contain the key description with "test key key1"
    And the single result from the previous api call should have the key finger_print

    When we make an api delete call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful

  Scenario: Create new ssh key pair and fail to duplicate delete
    When we make an api create call to ssh_key_pairs with no options
    Then the previous api call should be successful
    And from the previous api call save to registry uuid the value for key uuid

    # First deletion
    When we make an api delete call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful

    # Second deletion
    When we make an api delete call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should not be successful

  Scenario: List ssh key pairs
    When we make an api create call to ssh_key_pairs with the following options
      | description |
      | "test key1" |
    And we make an api create call to ssh_key_pairs with the following options
      | description |
      | "test key2" |
    Then the previous api call should be successful
    When we make an api get call to ssh_key_pairs with no options
    Then the previous api call should be successful

  Scenario: Fail to create ssh key pair using duplicate uuid
    #When we make an api create call to ssh_key_pairs with the following options
    #  |  uuid        | description |
    #  | ssh-testkey1 | "test key1" |
    #And we make an api create call to ssh_key_pairs with the following options
    #  |  uuid        | description |
    #  | ssh-testkey1 | "test key1" |
    #Then the previous api call should not be successful
