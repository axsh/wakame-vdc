@api_from_v11.12
Feature: SshKeyPair API

  Scenario: Create, update and delete for new ssh key pair with UUID

  Scenario: Create and delete for new ssh key pair
    Given a managed ssh_key_pair with the following options
      | description | display_name |
      | test key1   | sshkey1     |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api delete call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful

  @api_until_v11.12
  Scenario: Update ssh key pair
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

  @api_from_v12.03
  Scenario: Update ssh key pair
    Given a managed ssh_key_pair with the following options
      | description | display_name |
      | test key1   | sshkey1     |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api update call to ssh_key_pairs/<registry:uuid> with the following options
      | description   | display_name |
      | test key key1 | sshkey2      |
    Then the previous api call should be successful

    When we make an api get call to ssh_key_pairs/<registry:uuid> with no options
    Then the previous api call should be successful
    And the previous api call should have {"description":} equal to "test key key1"
    And the previous api call should have {"display_name":} equal to "sshkey2"
    And the previous api call should have {} with the key "finger_print"

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
      | description | display_name |
      | test key1   | sshkey1     |
    Given a managed ssh_key_pair with the following options
      | description | display_name |
      | test key2   | sshkey2     |
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

  @api_from_12.03
  Scenario: List ssh key pairs with filter options
    Given a managed ssh_key_pair with the following options
      | description | service_type | display_name |
      | test key1   | std          | sshkey1     |
    Given a managed ssh_key_pair with the following options
      | description | service_type | display_name |
      | test key2   | std          | sshkey2     |
    When we make an api get call to ssh_key_pairs with the following options
      |account_id|
      |a-shpoolxx|
    Then the previous api call should be successful
    When we make an api get call to ssh_key_pairs with the following options
      |created_since            |
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
    When we make an api get call to ssh_key_pairs with the following options
      |service_type             |
      |std                      |
    Then the previous api call should be successful
    When we make an api get call to ssh_key_pairs with the following options
      |display_name             |
      |sshkey1                  |
    Then the previous api call should be successful

