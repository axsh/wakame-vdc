Feature: gui-manage user/account associate
  CLI operations that allow users to be associated with account and vice versa

  Scenario: Create 1 user, create 2 accounts and associate the user with each account
    Given the working directory is frontend/dcmgr_gui/bin
    And 1 users are created
    And 2 accounts are created
    Then we should be able to associate the users with the accounts

  Scenario: Create 2 accounts, create 3 users and associate the accounts with each user
    Given the working directory is frontend/dcmgr_gui/bin
    And 2 accounts are created
    And 3 users are created
    Then we should be able to associate the accounts with the users
