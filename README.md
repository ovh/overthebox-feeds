# Overthebox

Overthebox is an open source solution developed by OVH to aggregate and encrypt multiple internet connections and terminates it over OVH/Cloud infrastructure which make clients benefit security, reliability, net neutrality, as well as dedicated public IP.

The aggregation is based on MPTCP, which is ISP, WAN type, and latency independent "whether it was Fiber, VDSL, SHDSL, ADSL or even 4G, ", different scenarios can be configured to have either aggregation, load-balancing or failover based on MPTCP or even Openwrt mwan3 package.

The solution takes advantage of the latest Openwrt system, which is user friendly and also the possibility of installing other packages like VPN, QoS, routing protocols, monitoring, etc. through web-interface or terminal.


More information is available here :
[https://www.ovhtelecom.fr/overthebox/](https://www.ovhtelecom.fr/overthebox/)


## Prerequisite

* an x86 machine
* 2Gb of RAM


## Install from pre-compiled images

Guide to install the image is available on (french) :
[https://docs.ovh.com/pages/releaseview.action?pageId=18121070](https://docs.ovh.com/pages/releaseview.action?pageId=18121070)


### image :
[http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-embedded-ext4.img.gz](http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-embedded-ext4.img.gz)


### virtualbox image :
[http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-combined-ext4.vdi](http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-combined-ext4.vdi)


## Compile from source

First, you need to clone our patched version of Openwrt which is available on github: [https://github.com/ovh/overthebox-openwrt](https://github.com/ovh/overthebox-openwrt)


### Preparation

```shell
git clone https://github.com/ovh/overthebox-openwrt.git
cd overthebox-openwrt
cp feeds.conf.default feeds.conf
echo src-git overthebox https://github.com/ovh/overthebox-feeds.git >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a -p overthebox
./scripts/feeds install -p overthebox -f netifd
./scripts/feeds install -p overthebox -f dnsmasq
./scripts/feeds install -a
```


### Compile 

```shell
make -j9 V=s
```


### if compilation fails

it happens :) Please try to recompile with -j1 to see the error.

```shell
make -j1 V=s
```


### Compilation issues encountered 

#### ntpd and libevent 

"OpenWrt-libtool: link: cannot find the library `../sntp/libevent/libevent_core.la' or unhandled argument `../sntp/libevent/libevent_core.la'" 
is due to an error in order of compilation

Fix :

```
    make package/libevent/compile
    make package/ntpd/clean
    make package/ntpd/compile
    make V=s -j9
``` 


#### bmon

From some reason, bmon does not want to compile

Fix:

```
sed -i "s/^CONFIG_PACKAGE_bmon=.*/# CONFIG_PACKAGE_bmon is not set/" .config
```


## Credits

Our solution is mainly based on : 
* Openwrt : [https://openwrt.org](https://openwrt.org)
* Multipath TCP : [https://multipath-tcp.org](https://multipath-tcp.org)


