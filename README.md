# openwrt / sort uci static DHCP v4 lease.

Sort openwrt dhcp-static-lease-hosts.

No v6 available.
if you uci have a v6 static lease dhcp , this script will disrupt uci.

# how to use 

Copy file into OpenWrt.  Run by Lua

```
lua uci-sort-dhcp-hosts.lua
```


# what does this script do.

- Backup dhcp.@host to /tmp
- uci show dhcp and eval dhcp.@host to lua
- sort dhcp.hosts by ip addr 
- remove exists by `uci del dhcp.host..`
- add sorted by `uci add dhcp.host `
- and commit `uci commit dhcp`

# how to sort ip address 

sort interger by castin ipv4 to Int.

# uci dhcp sample 


```sh

### get current dhcp hosts
uci show dhcp

### revert changes 
uci revert dhcp 

### commit dhcp
uci commit dhcp 

### remove all exist dhcp.hosts
while uci del dhcp.@host[-1] ; do : ;  done;

### add a new dhcp.host
uci add dhcp host
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='dc:a6:32:dd:23:c6'
uci set dhcp.@host[-1].ip='192.168.1.22'
uci set dhcp.@host[-1].leasetime='86400'
uci set dhcp.@host[-1].name='raspi-ubuntu'

```

# uci show dhcp via ssh 

if you are using ruby or python or JavaScript(node), you can rewrie via ssh.

### sample
```
ssh root@192.168.1.1 'uci show dhcp' \
  | \grep dhcp.@host | sed -E 's/@//' | sed -E 's/=host/={}/' >> dhcp.rb

```
