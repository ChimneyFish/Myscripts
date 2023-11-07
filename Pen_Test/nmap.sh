#!/bin/bash/

/bash/...

# nmap script

read -p "Put in the target subnet, domain, or a single IP address ___::" target
TARGET=$target
FILE=/home/NmapResults
sudo mkdir $FILE
sudo nmap -Pn -O --badsum -oG $FILE/nmap_TCPIP_Port_$TARGET.md -v -A $TARGET
wait
sudo nmap -Pn -A -oG $FILEnmap_TCPIP_Port_NO-BAD_$TARGET.md -v $TARGET
wait
sudo nmap -Pn -sV -sO -oG $FILEnmap_IP_Prot_$TARGET.md -v $TARGET
wait
sudo nmap -Pn -sF -oG $FILEnmap_Fin_Scan_$TARGET.md -v $TARGET
wait
sudo nmap -Pn -sX -oG $FILEnmap_Xmas_Scan_$TARGET.md -v $TARGET
wait
sudo nmap -pN -sN -oG  $FILEnmap_TCP-NULL_Scan_$TARGET.md -v $TARGET
wait
sudo nmap -pN -sY -oG  $FILEnmap_Sctp-INIT_$TARGET.md  -v $TARGET
wait
sudo nmap -pN -sZ -oG  $FILEnmap_Cookie-Echo_$TARGET.md  -v $TARGET
