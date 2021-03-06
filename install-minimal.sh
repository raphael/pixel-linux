#!/bin/bash

target_disk=""
ubuntu_arch="amd64"
ubuntu_metapackage="ubuntu-minimal"
ubuntu_version="latest"

target_disk="`rootdev -d -s`"
echo "Target disk is $target_disk ..."

if [ "$ubuntu_version" = "lts" ]
then
  ubuntu_version=`wget --quiet -O - http://changelogs.ubuntu.com/meta-release | grep "^Version:" | grep "LTS" | tail -1 | sed -r 's/^Version: ([^ ]+)( LTS)?$/\1/'`
  tar_file_name="ubuntu-core-$ubuntu_version-core-$ubuntu_arch.tar.gz"
  tar_file="http://cdimage.ubuntu.com/ubuntu-core/releases/$ubuntu_version/release/$tar_file_name"
elif [ "$ubuntu_version" = "latest" ]
then
  ubuntu_version=`wget --quiet -O - http://changelogs.ubuntu.com/meta-release | grep "^Version: " | tail -1 | sed -r 's/^Version: ([^ ]+)( LTS)?$/\1/'`
  tar_file_name="ubuntu-core-$ubuntu_version-core-$ubuntu_arch.tar.gz"
  tar_file="http://cdimage.ubuntu.com/ubuntu-core/releases/$ubuntu_version/release/$tar_file_name"
elif [ $ubuntu_version = "dev" ]
then
  ubuntu_version=`wget --quiet -O - http://changelogs.ubuntu.com/meta-release-development | grep "^Version: " | tail -1 | sed -r 's/^Version: ([^ ]+)( LTS)?$/\1/'`
  ubuntu_animal=`wget --quiet -O - http://changelogs.ubuntu.com/meta-release-development | grep "^Dist: " | tail -1 | sed -r 's/^Dist: (.*)$/\1/'`
  tar_file_name="$ubuntu_animal-core-$ubuntu_arch.tar.gz"
  tar_file="http://cdimage.ubuntu.com/ubuntu-core/daily/current/$tar_file_name"
else
  tar_file_name="ubuntu-core-$ubuntu_version-core-$ubuntu_arch.tar.gz"
  tar_file="http://cdimage.ubuntu.com/ubuntu-core/releases/$ubuntu_version/release/$tar_file_name"
fi

echo "Installing Ubuntu ${ubuntu_version} with metapackage ${ubuntu_metapackage}"
echo "Installing Ubuntu Arch: $ubuntu_arch"

read -p "Press [Enter] to continue..."

rootfs="/tmp/ubuntu-temp-root"

if [ ! -d $rootfs ]
then
  mkdir $rootfs
fi
if [ -e /home/chronos/user/Downloads/$tar_file_name ]
then
  cp /home/chronos/user/Downloads/$tar_file_name .
fi
if [ ! -e $tar_file_name ]
then
  wget -O - $tar_file > $tar_file_name
  cp $tar_file_name /home/chronos/user/Downloads
fi
tar xzpf $tar_file_name -C $rootfs/


cp scripts/install-ubuntu.sh $rootfs

cd $rootfs
echo 'nameserver 8.8.8.8' > etc/resolv.conf

mount -o bind /proc $rootfs/proc
mount -o bind /dev $rootfs/dev
mount -o bind /dev/pts $rootfs/dev/pts
mount -o bind /sys $rootfs/sys

cat > usr/sbin/policy-rc.d << EOF
#!/bin/sh
exit 101
EOF
chmod a+x usr/sbin/policy-rc.d

# Make /tmp location usable for chroot.
mount -o remount exec,suid,dev /tmp

# Chroot.
chmod a+x install-ubuntu.sh
chroot $rootfs /bin/bash -c /install-ubuntu.sh

# Make sure everything can boot.
crossystem dev_boot_legacy=1 dev_boot_signed_only=1

echo -e "
Installation is complete! On reboot at the dev mode screen, you can press
CTRL+L to boot Ubuntu or CTRL+D to boot Chrome OS. The Ubuntu login is:

  Username:  user
  Password:  user

Enjoy!
"