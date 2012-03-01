@api_from_v11.12
Feature: SshKeyPair API

  Scenario: Create, update and delete for new ssh key pair with UUID

  Scenario: Create, update and delete for new ssh key pair
    Given a managed ssh_key_pair with the following options
      | description |
      | test key1   |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api update call to ssh_key_pairs/<registry:uuid> with the following options
      | description   |
      | test key key1 |
    Then the previous api call should be successful

    When we make an api get call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful
    And the previous api call should have {"description":} equal to "test key key1"
    And the previous api call should have {} with the key "finger_print"

    When we make an api delete call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful

  Scenario: Create new ssh key pair and fail to duplicate delete
    Given a managed ssh_key_pair with no options
    And from the previous api call take {"uuid":} and save it to <registry:uuid>

    # First deletion
    When we make an api delete call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful

    # Second deletion
    When we make an api delete call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should not be successful

  Scenario: List ssh key pairs
    Given a managed ssh_key_pair with the following options
      | description |
      | test key1   |
    Given a managed ssh_key_pair with the following options
      | description |
      | test key2   |
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
