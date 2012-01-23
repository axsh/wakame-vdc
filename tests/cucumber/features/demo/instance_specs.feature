Feature: Instance specs
  Instance specs the virtual hardware specifications for instances.
  They include stuff like number of CPU cores, memory size, etc.

  Scenario: Show individual instance specs
    * Given the following records exist in InstanceSpec
      | account_id | uuid      | arch   | cpu_cores | hypervisor | memory_size |
      | a-shpoolxx | is-demo   | x86    | 1         | kvm        | 256         |
      | a-shpoolxx | is-demo2  | x86_64 | 3         | kvm        | 512         |
    * AND the following records do not exist in InstanceSpec
      | account_id | uuid        |
      | a-shpoolxx | is-notthere |
    
    * When we make an api show call to instance_specs/is-demo
    * Then the api call should work
    * AND the result uuid should be is-demo
    * AND the result hypervisor should be kvm
    * AND the result hypervisor should not be hoge
    * AND the result cpu_cores should be 1
    
    * When we make an api show call to instance_specs/is-notthere
    * Then the api call should fail
    
