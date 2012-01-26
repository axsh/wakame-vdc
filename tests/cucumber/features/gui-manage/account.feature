Feature: gui-manage account
  CLI operations for accounts

  Scenario: Create an account, delete it and be unable to read it
    Given the working directory is frontend/dcmgr_gui/bin
    And 1 accounts are created
    Then we should not be able to create accounts with the same uuids
    When we delete the accounts
    Then we should not be able to create accounts with the same uuids

  Scenario: Show oauth key for existing account and not for deleted account
    Given the working directory is frontend/dcmgr_gui/bin
    And 1 accounts are created
    Then we should be able to create/show the accounts oauth keys
    When we delete the accounts
    Then we should not be able to create/show the accounts oauth keys
