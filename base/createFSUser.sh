#!/bin/bash -e
ceph auth get-or-create client.erix osd 'allow rw' mon 'allow r' > keyring.erix
echo "Got-or-Created Key for Erix"
cat keyring.erix

echo "NFS Mount\nsudo mount -t ceph ceph-monitor.skydns.local:6789:/ /mnt/mycephfs -o name=erix,secret=xxx"
echo "OR\n"
echo "NFS Mount\nsudo mount -t ceph ceph-monitor.skydns.local:6789:/ /mnt/mycephfs -o name=erix,secretfile=keyring.erix"