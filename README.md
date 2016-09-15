# OverTheBox

OverTheBox is an open source solution developed by OVH to aggregate and encrypt multiple internet connections and terminates it over OVH/Cloud infrastructure which make clients benefit security, reliability, net neutrality, as well as dedicated public IP.

The aggregation is based on MPTCP, which is ISP, WAN type, and latency independent "whether it was Fiber, VDSL, SHDSL, ADSL or even 4G", different scenarios can be configured to have either aggregation, load-balancing or failover based on MPTCP or even OpenWRT mwan3 package.

The solution takes advantage of the OpenWRT system, which is user friendly and also the possibility of installing other packages like VPN, QoS, routing protocols, monitoring, etc. through web-interface or terminal.


More information is available here :
[https://www.ovhtelecom.fr/overthebox/](https://www.ovhtelecom.fr/overthebox/)


## Prerequisite

* an x86 machine
* 2GiB of RAM


## Install from pre-compiled images

Guide to install the image is available on (french) :
[https://docs.ovh.com/pages/releaseview.action?pageId=18121070](https://docs.ovh.com/pages/releaseview.action?pageId=18121070)


### image :
[http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-embedded-ext4.img.gz](http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-embedded-ext4.img.gz)


### virtualbox image :
[http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-combined-ext4.vdi](http://downloads.overthebox.ovh/trunk/x86/64/openwrt-x86-64-combined-ext4.vdi)


### Prepare

```shell
git clone https://github.com/ovh/overthebox-openwrt.git
cd overthebox-openwrt
cp feeds.conf.default feeds.conf
echo src-git overthebox https://github.com/ovh/overthebox-feeds.git >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a -f -p overthebox
./scripts/feeds install -a
```


### Configure and compile

```shell
make menuconfig
make
```

## Credits

Our solution is mainly based on:

* OpenWRT: [https://openwrt.org](https://openwrt.org)
* MultiPath TCP (MPTCP): [https://multipath-tcp.org](https://multipath-tcp.org)
* Shadowsocks: [https://shadowsocks.org](https://shadowsocks.org)
