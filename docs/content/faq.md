# F.A.Q.

### What operating system will Wakame-vdc run on?

We are officially supporting Centos 6.6 x86 64 bit. It is possible that it'll run on other operating systems as well but this is the only one we're testing on. All current production environments also run on it.

### Is Wakame-vdc currently being used in production anywhere?

Yes, it is. Check our section on the [homepage](index.md) for references.

### Can I run Wakame-vdc in a virtual machine?

Absolutely. We do it all the time in development.

It works really well when you use OpenVZ as your hypervisor. Since OpenVZ is a container and not full virtualization, it doesn't have the usual overhead that comes with nested virtualization. LXC should work just as well but isn't tested as extensively. Nested KVM also works if the host's cpu supports it but is a lot slower.

Our [VirtualBox demo image](http://wakameusersgroup.org/demo_image.html) implements Wakame-vdc in a virtual machine using OpenVZ and our [installation guide](installation.md) can be used to do the same.

### What Hypervisors does Wakame-vdc support?

Currently the following:

  * [KVM](http://www.linux-kvm.org/page/Main_Page)

  * [OpenVZ](http://openvz.org)

  * [LXC](https://linuxcontainers.org)

  * [VMWare ESXi](http://www.vmware.com/products/esxi-and-esx/overview) (Experimental only)

### What OS can I run on Wakame-vdc's instances?

Depends on which hypervisor you use. If you use a container like OpenVZ or LXC, all instances will use the same kernel as your host OS. Therefore your instances will be running either the same OS as your host or something very close to it.

If you use a full virtualization hypervisor like KVM, you can run any OS that you want in your instances.

