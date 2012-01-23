Feature: SSH key pairs
  These are RSA key pairs.
  They take care of authentication for our instances.

  Scenario: Show 4 keys
    * Given the following records exist in SshKeyPair
      | account_id | uuid        | public_key | finger_print  |
      | a-shpoolxx | ssh-demo1   | pubkey1    | fp1           |
      | a-shpoolxx | ssh-demo2   | pubkey2    | fp2           |
      | a-shpoolxx | ssh-demo3   | pubkey3    | fp3           |
      | a-shpoolxx | ssh-demo4   | pubkey4    | fp4           |
    
    * When we make an api show call to ssh_key_pairs
    * Then the api call should work
    * AND the results uuid should contain ssh-demo1
    * AND the results uuid should contain ssh-demo2
    * AND the results uuid should contain ssh-demo3
    * AND the results uuid should contain ssh-demo4
    
    * When we make an api show call to ssh_key_pairs/ssh-demo2
    * Then the api call should work
    * AND the result uuid should not be ssh-demo1
    * AND the result finger_print should be fp2
    * AND the result public_key should not be pubkey4
    
  Scenario: Get rid of the 4 keys
    * Given the following records do not exist in SshKeyPair
      | account_id | uuid        | public_key | finger_print  |
      | a-shpoolxx | ssh-demo1   | pubkey1    | fp1           |
      | a-shpoolxx | ssh-demo2   | pubkey2    | fp2           |
      | a-shpoolxx | ssh-demo3   | pubkey3    | fp3           |
      | a-shpoolxx | ssh-demo4   | pubkey4    | fp4           |

    * When we make an api show call to ssh_key_pairs
    * Then the api call should work
    * AND the results uuid should not contain ssh-demo1
    * AND the results uuid should not contain ssh-demo2
    * AND the results uuid should not contain ssh-demo3
    * AND the results uuid should not contain ssh-demo4

    * When we make an api show call to ssh_key_pairs/ssh-demo1
    * Then the api call should fail
    
    * When we make an api show call to ssh_key_pairs/ssh-demo2
    * Then the api call should fail
    
    * When we make an api show call to ssh_key_pairs/ssh-demo3
    * Then the api call should fail

    * When we make an api show call to ssh_key_pairs/ssh-demo4
      * Then the api call should fail
