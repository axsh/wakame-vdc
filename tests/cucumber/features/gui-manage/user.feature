Feature: gui-manage user
  CLI operations for users

  Scenario: Create a user, delete it and be able to readd it
    * Given the working directory is frontend/dcmgr_gui/bin
    * And 1 users are created
    * Then we should not be able to create users with the same uuids
    * When we delete the users
    * Then we should be able to create users with the same uuids
