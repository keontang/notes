##### ubuntu 14.04搭建wifi  
- ubuntu 14.04中已经有支持TL-WDN4800无线网卡的驱动：ath9k  
- 查看无线网卡状态  
```sh
root@ubuntu-server-1:/home/caicloud# lshw -C network
*-network UNCLAIMED               
  description: Wireless interface
```
如出现 `UNCLAIMED` 则进行如下操作：  
```sh
echo "options ath9k nohwcrypt=1" | sudo tee -a /etc/modprobe.d/ath9k.conf
sudo modprobe -rfv ath9k
sudo modprobe -v ath9k
```
- 配置wifi  
```sh
root@ubuntu-server-1:/home/caicloud# iwconfig 
wlan0     IEEE 802.11abgn 
          Mode:Managed  Frequency:5.745 GHz  Access Point: 28:C6:8E:9A:D0:20   
          Bit Rate=90 Mb/s   Tx-Power=20 dBm   
          Retry short limit:7   RTS thr:off   Fragment thr:off
          Encryption key:off
          Power Management:off
          Link Quality=58/70  Signal level=-52 dBm  
          Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
          Tx excessive retries:0  Invalid misc:10   Missed beacon:0
```
添加wifi网络ID和密码，让系统启动时自动连接wifi:  
```sh
root@ubuntu-server-1:/home/caicloud# cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto p2p1
iface p2p1 inet dhcp

auto wlan0
iface wlan0 inet dhcp
wpa-ssid xxxx
wpa-psk xxxx
```
- 重启wifi  
```sh
sudo ifdown wlan0 && sudo ifup -v wlan0
```
