SHELL=/bin/sh

all:

clean: clean-hg
	pfexec svcadm restart svc:/network/iscsi/target:default

clean-target:
	pfexec itadm list-target | egrep ^iqn. | awk '{print $$1}' | while read iqn; do echo ... $$iqn; pfexec stmfadm offline-target $$iqn; pfexec itadm delete-target $$iqn; done

clean-lu: clean-target
	pfexec stmfadm list-lu -v |grep ^LU | awk '{print $$3}' | while read line; do echo ... $${line}; pfexec stmfadm delete-lu $${line}; done

clean-tg: clean-lu
	pfexec stmfadm list-tg -v | grep ^Target | awk '{print $$3}' | while read line; do echo ... $${line}; pfexec stmfadm delete-tg $${line}; done

clean-hg: clean-tg
	pfexec stmfadm list-hg | awk '{print $$3}' | while read line; do echo $${line}; pfexec stmfadm delete-hg $${line}; done

show:
	echo --- List View Target Portal Groups ---
	pfexec itadm list-tpg -v
	echo --- List View and Associated Host Groups IQNs ---
	for i in `pfexec stmfadm list-lu | cut -d" " -f3`; do \
	pfexec stmfadm list-view -l $$i; \
	host_group=`pfexec stmfadm list-view -l $$i | grep "Host group" | cut -d: -f 2`; \
	client_iqn=`pfexec stmfadm list-hg -v $$host_group| grep -v "Host Group"`; \
	echo Client IQN $$client_iqn; \
   	echo; \
	done
	echo --- Target group config ----
	pfexec stmfadm list-tg -v
	echo
	echo --- LU List \(verbose\) ---
	pfexec stmfadm list-lu -v

