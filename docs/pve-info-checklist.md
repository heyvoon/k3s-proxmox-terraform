# Proxmox VE Information Gathering Checklist for K3s Deployment

## ☐ Step 1: Basic Connection Information

### Manual Input Required:
- [x] **PVE Hostname/IP**: proxmox / 192.168.1.200
- [x] **PVE Web Interface Port** (usually 8006): 8006
- [x] **Authentication Method** (API Token / Username+Password): _____________________

### Commands to Run:
```bash
# Get PVE version
pveversion
```
**Output:**
```
pve-manager/8.4.14/b502d23c55afcba1 (running kernel: 6.8.12-15-pve)
```

---

## ☐ Step 2: Node Information

### Commands to Run:
```bash
# Get all nodes in the cluster
pvesh get /nodes --output-format json
```
**Output:**
```json
[{"cpu":0.00286640079760718,"disk":12836159488,"id":"node/proxmox","level":"p","maxcpu":8,"maxdisk":13471539200,"maxmem":33537990656,"mem":1818017792,"node":"proxmox","ssl_fingerprint":"10:94:FF:EE:95:B2:AF:57:C6:A9:2B:C7:E1:0E:F9:A2:33:64:13:D4:AB:9F:C2:BD:74:44:88:67:A2:5A:D8:3A","status":"online","type":"node","uptime":22924}]
```

```bash
# Get your hostname (for single node setups)
hostname
```
**Output:**
```
proxmox
```

---

## ☐ Step 3: Storage Information

### Commands to Run:
```bash
# Get all storage configurations
pvesh get /storage --output-format json
```
**Output:**
```json
[{"content":"rootdir,images","digest":"6b907c7fee9a470a2b0d52bf736f5f1a0c75c47c","mountpoint":"/gaia-pool-01","pool":"gaia-pool-01","sparse":0,"storage":"local-zfs","type":"zfspool"},{"content":"snippets,vztmpl,iso","digest":"6b907c7fee9a470a2b0d52bf736f5f1a0c75c47c","is_mountpoint":"1","nodes":"proxmox","path":"/mnt/pve/usb-storage-01","shared":0,"storage":"usb-storage-01","type":"dir"},{"content":"import","digest":"6b907c7fee9a470a2b0d52bf736f5f1a0c75c47c","disable":1,"path":"/var/lib/vz","shared":0,"storage":"local","type":"dir"}]
```

```bash
# Get storage status with more details
pvesm status
```
**Output:**
```
Name                  Type     Status           Total            Used       Available        %
local                  dir   disabled               0               0               0      N/A
local-zfs          zfspool     active      1394081792        87896381      1306185410    6.30%
usb-storage-01         dir     active        30246892         8094128        22152764   26.76%
```

```bash
# List content on each storage (we'll check manually)
# Replace <storage-name> with actual storage names from pvesm status output
# pvesm list <storage-name>
```
**Output:**
```
root in ~ at proxmox …
➜ pvesm list local
storage 'local' is disabled

root in ~ at proxmox …
➜ pvesm list local-zfs
Volid                          Format  Type             Size VMID
local-zfs:base-9100-disk-0     raw     images    10737418240 9100
local-zfs:base-9200-disk-0     raw     images    10737418240 9200
local-zfs:subvol-1000-disk-0   subvol  rootdir    2147483648 1000
local-zfs:subvol-10000-disk-0  subvol  rootdir   12884901888 10000
local-zfs:subvol-100000-disk-0 subvol  rootdir    4294967296 100000
local-zfs:subvol-2000-disk-0   subvol  rootdir    8589934592 2000
local-zfs:subvol-20000-disk-0  subvol  rootdir    8589934592 20000
local-zfs:subvol-3000-disk-0   subvol  rootdir    8589934592 3000
local-zfs:subvol-3010-disk-0   subvol  rootdir    4294967296 3010
local-zfs:subvol-3020-disk-0   subvol  rootdir    8589934592 3020
local-zfs:subvol-3306-disk-0   subvol  rootdir    4294967296 3306
local-zfs:subvol-5005-disk-0   subvol  rootdir    8589934592 5005
local-zfs:subvol-9000-disk-0   subvol  rootdir    8589934592 9000
local-zfs:vm-100-disk-0        raw     images    25769803776 100
local-zfs:vm-101-disk-0        raw     images    25769803776 101
local-zfs:vm-9100-cloudinit    raw     images        4194304 9100
local-zfs:vm-9200-cloudinit    raw     images        4194304 9200

root in ~ at proxmox …
➜ pvesm list usb-storage-01
Volid                                                             Format  Type            Size VMID
usb-storage-01:iso/debian-12.8.0-amd64-netinst.iso                iso     iso        661651456
usb-storage-01:iso/jammy-server-cloudimg-amd64-disk-kvm.img       iso     iso        635305984
usb-storage-01:iso/jammy-server-cloudimg-amd64.img                iso     iso        667044352
usb-storage-01:iso/rancheros-proxmox.iso                          iso     iso        162529280
usb-storage-01:iso/ubuntu-22.04.5-live-server-amd64.iso           iso     iso       2136926208
usb-storage-01:iso/ubuntu-24.04-live-server-amd64.iso             iso     iso       2754981888
usb-storage-01:iso/ubuntu-24.04-server-cloudimg-amd64.img         iso     iso        618925568
usb-storage-01:snippets/ci-dev-sshpass.yaml                       snippet snippets         194
usb-storage-01:snippets/ci-ssh-pwauth.yaml                        snippet snippets          31
usb-storage-01:snippets/ci-user-apply-proxmox.yaml                snippet snippets         209
usb-storage-01:snippets/ci-user-explicit.yaml                     snippet snippets         205
usb-storage-01:snippets/ci-user-zsh-p10k-9200.yaml                snippet snippets        1569
usb-storage-01:snippets/ci-vendor-sshpass-only.yaml               snippet snippets         325
usb-storage-01:snippets/ci-vendor-sshpass.yaml                    snippet snippets          31
usb-storage-01:snippets/k8s-cloud-init.yaml                       snippet snippets         357
usb-storage-01:snippets/userdata-dev-enforced.yaml                snippet snippets         752
usb-storage-01:snippets/userdata-dev-sshpass.yaml                 snippet snippets         693
usb-storage-01:vztmpl/alpine-3.22-default_20250617_amd64.tar.xz   txz     vztmpl       3271244
usb-storage-01:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst     tzst    vztmpl     126515062
usb-storage-01:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst     tzst    vztmpl     129710398
usb-storage-01:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst tzst    vztmpl     141589318
```

---

## ☐ Step 4: Network Configuration

### Commands to Run:
```bash
# Show network interfaces configuration
cat /etc/network/interfaces
```
**Output:**
```
➜ cat /etc/network/interfaces
# network interface settings; autogenerated
# Please do NOT modify this file directly, unless you know what
# you're doing.
#
# If you want to manage parts of the network configuration manually,
# please utilize the 'source' or 'source-directory' directives to do
# so.
# PVE will preserve these directives, but will NOT read its network
# configuration from sourced files, so do not attempt to move any of
# the PVE managed interfaces into external files!

auto lo
iface lo inet loopback

iface eno1 inet manual

auto vmbr0
iface vmbr0 inet static
        address 192.168.1.200/24
        gateway 192.168.1.1
        bridge-ports eno1
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-vids 2-4094

source /etc/network/interfaces.d/*
```

```bash
# Show available bridges
ip link show type bridge
```
**Output:**
```
3: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether e0:4f:43:24:09:de brd ff:ff:ff:ff:ff:ff
```

```bash
# Show IP addresses assigned to interfaces
ip addr show
```
**Output:**
```
➜ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master vmbr0 state UP group default qlen 1000
    link/ether e0:4f:43:24:09:de brd ff:ff:ff:ff:ff:ff
    altname enp0s31f6
3: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether e0:4f:43:24:09:de brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.200/24 scope global vmbr0
       valid_lft forever preferred_lft forever
    inet6 fe80::e24f:43ff:fe24:9de/64 scope link
       valid_lft forever preferred_lft forever
```

---

## ☐ Step 5: Available Resources

### Commands to Run:
```bash
# Get node status (CPU, Memory, Storage)
pvesh get /nodes/$(hostname)/status --output-format json
```
**Output:**
```json
{"boot-info":{"mode":"legacy-bios"},"cpu":0,"cpuinfo":{"cores":4,"cpus":8,"flags":"fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb pti ssbd ibrs ibpb stibp tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi md_clear flush_l1d arch_capabilities ibpb_exit_to_user","hvm":"1","mhz":"800.000","model":"Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz","sockets":1,"user_hz":100},"current-kernel":{"machine":"x86_64","release":"6.8.12-15-pve","sysname":"Linux","version":"#1 SMP PREEMPT_DYNAMIC PMX 6.8.12-15 (2025-09-12T11:02Z)"},"idle":0,"ksm":{"shared":0},"kversion":"Linux 6.8.12-15-pve #1 SMP PREEMPT_DYNAMIC PMX 6.8.12-15 (2025-09-12T11:02Z)","loadavg":["0.16","0.10","0.02"],"memory":{"free":31460552704,"total":33537990656,"used":1952485376},"pveversion":"pve-manager/8.4.14/b502d23c55afcba1","rootfs":{"avail":1564672,"free":635187200,"total":13471539200,"used":12836352000},"swap":{"free":1073737728,"total":1073737728,"used":0},"uptime":23433,"wait":0}
```

```bash
# CPU details
lscpu | grep -E "^CPU\(s\)|^Model name|^Thread|^Core"
```
**Output:**
```
CPU(s):                               8
Model name:                           Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz
Thread(s) per core:                   2
Core(s) per socket:                   4
CPU(s) scaling MHz:                   76%
```

```bash
# Memory details
free -h
```
**Output:**
```
               total        used        free      shared  buff/cache   available
Mem:            31Gi       1.7Gi        29Gi        47Mi       540Mi        29Gi
Swap:          1.0Gi          0B       1.0Gi
```

---

## ☐ Step 6: Network Planning (To be filled after review)

### K3s Cluster Network Details:
- [x] **Number of control plane nodes**: 3
- [x] **Number of worker nodes**: 3
- [x] **IP range for K3s VMs** (e.g., 192.168.1.100-110): 192.168.1.180-190
- [x] **Gateway IP**: 192.168.1.1
- [x] **DNS Server(s)**: 192.168.1.1
- [x] **Network Bridge to use** (e.g., vmbr0): vmbr0

---

## ☐ Step 7: VM Template/Image Information

### Commands to Run:
```bash
# Check if cloud-init images exist
ls -lh /var/lib/vz/template/iso/ | grep -i cloud

# Or check in your configured template storage
pvesm list <your-storage-name> --content vztmpl,iso
```
**Output:**
```
➜ pvesm list local-zfs --content images
Volid                       Format  Type             Size VMID
local-zfs:base-9100-disk-0  raw     images    10737418240 9100
local-zfs:base-9200-disk-0  raw     images    10737418240 9200
local-zfs:vm-100-disk-0     raw     images    25769803776 100
local-zfs:vm-101-disk-0     raw     images    25769803776 101
local-zfs:vm-9100-cloudinit raw     images        4194304 9100
local-zfs:vm-9200-cloudinit raw     images        4194304 9200
```

### Template Decision:
- [x] **Use existing template** (Template ID: 9100)
- [ ] **Download Ubuntu Cloud Image** (we'll do this together)
- [ ] **Download Debian Cloud Image** (we'll do this together)

---

## ☐ Step 8: API Token Setup (if not already configured)

### Commands to Run:
```bash
# List existing API tokens
pvesh get /access/users/<username>/token --output-format json

# Example: pvesh get /access/users/root@pam/token --output-format json
```
**Output:**
```json
➜ pvesh get /access/users/root@pam/token --output-format json
[{"expire":0,"privsep":1,"tokenid":"pveexporter"},{"expire":0,"privsep":0,"tokenid":"homarr"},{"comment":"Terraform User","expire":0,"privsep":0,"tokenid":"terraform"}]
```

### If creating new token:
- [ ] **Token ID**: _____________________
- [ ] **Token Secret**: _____________________ (save this securely!)

---

## ☐ Step 9: SSH Key (for K3s nodes)

### Commands to Run on WSL:
```bash
# Check if you have an SSH key
ls -la ~/.ssh/id_*.pub

# If not, generate one:
ssh-keygen -t ed25519 -C "k3s-cluster"
```
**Output:**
```
-rw-r--r-- 1 dev dev 107 Oct 29 00:08 /home/dev/.ssh/id_ed25519.pub

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKdSE8dhEHhDNpMC20mLDMful5dwSOnxpswCtUFQUX7 victus laptop primary key
```

---

## ☐ Step 10: Terraform & Tools Verification (WSL)

### Commands to Run on WSL:
```bash
# Check Terraform version
terraform version

# Check if terraform is installed, if not:
# wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
# sudo apt update && sudo apt install terraform
```
**Output:**
```
Terraform v1.13.5
on linux_amd64
```

---

## Summary Checklist

Before proceeding to Terraform configuration, ensure you have:

- [x] PVE connection details (IP, credentials/token)
- [x] Node information and hostname
- [x] Storage backend identified (for VM disks and ISOs)
- [x] Network bridge identified
- [x] IP addressing scheme planned
- [x] Available resources confirmed (sufficient CPU/RAM)
- [x] Cloud-init image or template ready
- [x] API token created (if using token auth)
- [x] SSH public key ready
- [x] Terraform installed on WSL

---

**Once you've completed this checklist, we'll proceed to create the Terraform configuration!**