#!/bin/bash


USER=jackmehoff
if  ["echo "$USER"" -e root]; then
  echo "Will Not work as ROOT";
else
(
sudo apt update
sudo apt upgrade -y
sudo curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
cat > /etc/apt/sources.list > EOF
"# Ubuntu repository
deb http://archive.ubuntu.com/ubuntu jammy multiverse
deb http://archive.ubuntu.com/ubuntu jammy universe"
EOF
sudo apt-get update && sudo apt-get install spotify-client -y
#
sudo apt install btrfs-progs exfatprogs e2fsprogs hfsprogs e2fsprogs-l10n f2fs-tools dosfstools mtools hfsutils jfsutils util-linux cryptsetup dmsetup lvm2 libguestfs-nilfs nilfs-tools ntfs-3g ntfs2btrfs ntfs-3g-dev reiser4progs reiserfsprogs udftools xfsprogs xfsdump tor torbrowser-launcher build-essential automake cmake autoconf alsa* balena-etcher cpu-checker cpu-x cpu cpufrequtils cpuid cpuidtool cpuinfo cpulimit cpuset cpustat cputool kate npm

sudo npm i -g bash-language-server

sudo wget -P /home/jackmehoff/Downloads https://installers.privateinternetaccess.com/download/pia-linux-3.3.1-06924.run
sudo chmod +x /home/jackmehoff/Downloads/pia-linux-3.3.1-06924.run
sh /home/jackmehoff/Downloads/pia-linux-3.3.1-06924.run --accept
sudo mkdir /home/jackmehoff/pialogin

echo "
p2575044
iCbX4VxMvY
" | sudo tee /home/jackmehoff/pialogin/piacred.txt
#
sudo piactl login /home/jackmehoff/pialogin/piacreds.txt
)
fi
