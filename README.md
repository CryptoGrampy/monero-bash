# monero-bash
>a wrapper for Monero written in Bash, for Linux

![monero-bash](https://user-images.githubusercontent.com/101352116/183257273-6224fa0d-cb10-4a3f-bb5d-057df7c0e18e.jpg)

## Contents
* [About](#About)
* [Features](#Features)
* [Distro Coverage](#Distro-Coverage)
* [Install](#Install)
* [Usage](#Usage)
	- [Wallet](#Wallet)
	- [Config](#Config)
	- [P2Pool Mining](#p2pool-mining)
	- [Full vs Start](#full-vs-start)
	- [Commands](#Commands)
* [FAQ](#FAQ)

## About
**monero-bash is a Linux CLI wrapper/manager for: [`Monero`](https://github.com/monero-project/monero) | [`P2Pool`](https://github.com/SChernykh/p2pool) | [`XMRig`](https://github.com/xmrig/xmrig)**

***Package manager:***

***Wallet menu:***

***P2Pool & XMRig mining:***

[This project was funded by the Monero Community via the CCS, thanks to all who donated!](https://ccs.getmonero.org/proposals/monero-bash.html)

## Features
* 📦 **`PKG MANAGER`** Manage the download/verification/upgrading of packages
* 💵 **`WALLET MENU`** Interactive menu for selecting/creating wallets
* 👺 **`SYSTEMD`** Control ***monerod/p2pool/xmrig*** as background processes
* ⛏️ **`MINING`** Interactive mining configuration, ***built for P2Pool***
* 👁️ **`WATCH`** Switch between normal terminal and live output of ***monerod/p2pool/xmrig***
* 📈 **`STATS`** Display statistics (CPU usage, P2Pool shares, etc)
* 📋 **`RPC`** Interact with the ***monerod*** JSON-RPC interface
* 🔒 **`GPG`** Encrypt and backup your wallets

## Distro Coverage
| Linux Distribution        | Version            | Status | Info |
|---------------------------|--------------------|--------|------|
| Debian                    | 11, 10             | ✅     |
| Ubuntu                    | LTS 22.04, 20.04   | ✅     |
| Pop!\_OS                  | LTS 22.04, 20.04   | ✅     |
| Linux Mint                | 21, 20.03          | ✅     |
| Fedora                    | Workstation 36, 35 | ❌     | SELinux disables `systemd` functionality
| Arch Linux                |                    | ⚠️      | `wget` must be installed
| Manjaro                   | 21.3.6             | ✅     |
| Gentoo                    |                    | ❌     | `wget` & `systemd` must be installed

***✅ = Works out the box***  
***⚠️ = Small issues***  
***❌ = Big issues***  

## Install
[**To install: download the latest release here, extract and run monero-bash**](https://github.com/hinto-janaiyo/monero-bash/releases/latest)
```
tar -xf monero-bash-v1.7.1.tar
cd monero-bash
./monero-bash
```
This will start the interactive install process into `/usr/local/share/monero-bash`

It is recommended to verify the hash and PGP signature before installation.  
Download the [`SHA256SUM`](https://github.com/hinto-janaiyo/monero-bash/releases/latest) file, download and import my [`PGP key`](https://github.com/hinto-janaiyo/monero-bash/blob/main/gpg/hinto-janaiyo.asc), and verify:
```
sha256sum -c SHA256SUM
gpg --import hinto-janaiyo.asc
gpg --verify SHA256SUM
```

---

**To install with git:**
```
git clone https://github.com/hinto-janaiyo/monero-bash
cd monero-bash
./monero-bash
```
ALWAYS clone the main branch, the other branches are not tested

---

**To uninstall:**
```
monero-bash uninstall
```
 Or manually remove everything:
```
rm -r $HOME/.monero-bash
sudo rm /usr/local/bin/monero-bash
sudo rm -r /usr/local/share/monero-bash
sudo rm /etc/systemd/system/monero-bash*
```
THIS WILL DELETE YOUR WALLETS - remember to move them before uninstalling!

## Usage
### Config
Config files for all packages are in: `~/.monero-bash/config`.

monero-bash comes with pre-configured/optimized configuration files:
* [`monero-bash.conf`](https://github.com/hinto-janaiyo/monero-bash/blob/main/config/monero-bash.conf)
* [`monerod.conf`](https://github.com/hinto-janaiyo/monero-bash/blob/main/config/monerod.conf)
* [`monero-wallet-cli.conf`](https://github.com/hinto-janaiyo/monero-bash/blob/main/config/monero-wallet-cli.conf)
* [`xmrig.json`](https://github.com/hinto-janaiyo/monero-bash/blob/main/config/xmrig.json)

P2Pool does not currently support config files, so its options are found in: `monero-bash.conf`.You can also use the interactive `monero-bash config` command to quickly setup P2Pool+XMRig mining.

### P2Pool Mining
***Warning:***
* Wallet addresses are public on P2Pool! It is recommended to create a seperate mining wallet.
* You are using your own nodes to mine. Both the Monero & P2Pool nodes have to be fully synced!

To start mining on P2Pool:
1. Install all the packages: `monero-bash install all`
2. Configure basic mining settings: `monero-bash config`
3. You can then start all processes in the background: `monero-bash start all`
4. And watch them live with: `monero-bash watch <monero/p2pool/xmrig>`

If you have something like `screen` or `tmux` you can open multiple terminals and:
```
monero-bash full monero
monero-bash full p2pool
monero-bash full xmrig
```
Instead of running of them in the background.

### Command Usage
```
monero-bash usage: monero-bash <option> <more options>

monero-bash                              open wallet menu
uninstall                                uninstall ALL OF monero-bash
rpc                                      send a JSON RPC call to monerod

install <all/pkg>                        install <all> or a specific package
install <all/pkg> verbose                print detailed download information
remove  <all/pkg>                        remove <all> or a specific package

update                                   CHECK for updates
upgrade                                  upgrade all packages
upgrade <pkg>                            upgrade a specific package
upgrade <all/pkg> force                  forcefully upgrade packages
upgrade <all/pkg> verbose                print detailed download information
version                                  print installed package versions

config                                   configure MINING settings
start   <all/monero/xmrig/p2pool>        start process detached (background)
stop    <all/monero/xmrig/p2pool>        gracefully stop the process
kill    <all/monero/xmrig/p2pool>        forcefully kill the process
restart <all/monero/xmrig/p2pool>        restart the process
full    <monero/xmrig/p2pool>            start the process attached (foreground)
watch   <monero/xmrig/p2pool>            watch live output of process
edit    <monero/xmrig/p2pool>            edit systemd service file
reset   <bash/monero/xmrig/p2pool>       reset your configs/systemd to default

backup                                   encrypt and backup your /wallets/
decrypt                                  decrypt backup.tar.gpg

status                                   print status of all running processes
seed                                     generate random 25-word Monero seed
list                                     list wallets
size                                     show size of monero-bash folders
price                                    fetch price data from cryptocompare.com API
integrity                                check hash integrity of monero-bash

help                                     show this help message
```

## FAQ
<details>
<summary>Where does monero-bash download packages from?</summary>

---

[The latest versions are downloaded using the GitHub API.](https://github.com/hinto-janaiyo/monero-bash/blob/main/src/func/download)

* Monero [`https://downloads.getmonero.org/cli/linux64`](https://downloads.getmonero.org/cli/linux64)
* monero-bash [`https://github.com/hinto-janaiyo/monero-bash`](https://github.com/hinto-janaiyo/monero-bash)
* XMRig [`https://github.com/xmrig/xmrig`](https://github.com/xmrig/xmrig)
* P2Pool [`https://github.com/SChernykh/p2pool`](https://github.com/SChernykh/p2pool)

VPN/Tor connections are often rate-limited by the API, if so, monero-bash will find the download link by filtering the HTML of the package's `/releases/latest/` GitHub page.

Hashes for Monero are found here: [`https://www.getmonero.org/downloads/hashes.txt`](https://www.getmonero.org/downloads/hashes.txt)

[Every other package hash is found on its GitHub page.](https://github.com/hinto-janaiyo/monero-bash/blob/main/src/func/verify)

---

</details>

<details>
<summary>Where are PGP keys downloaded from?</summary>

---

Keys are pre-downloaded in: `gpg/` [**HOWEVER, they are checked against the online versions before getting imported.**](https://github.com/hinto-janaiyo/monero-bash/blob/main/src/func/gpg) If a difference is found, you'll be dropped into a selection menu to pick which key to trust. If this happens, please search around to see what caused the difference.

* monero-bash `21958EE945980282FCB849C8D7483F6CA27D1B1D` -> [hinto-janaiyo](https://raw.githubusercontent.com/hinto-janaiyo/monero-bash/main/pgp/hinto-janaiyo.asc)
* Monero `81AC591FE9C4B65C5806AFC3F0AF4D462A0BDF92` -> [binaryFate](https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc)
* P2Pool `1FCAAB4D3DC3310D16CBD508C47F82B54DA87ADF` -> [SChernykh](https://raw.githubusercontent.com/monero-project/gitian.sigs/master/gitian-pubkeys/SChernykh.asc)
* XMRig `9AC4CEA8E66E35A5C7CDDC1B446A53638BE94409` -> [XMRig](https://raw.githubusercontent.com/xmrig/xmrig/master/doc/gpg_keys/xmrig.asc)

---

</details>

<details>
<summary>How does monero-bash upgrade packages?</summary>

---

[Click here for an explanation on how monero-bash upgrades packages](https://github.com/hinto-janaiyo/monero-bash/blob/main/docs/upgrade_explanation.md)

To see detailed output when installing/upgrading, type:
```
monero-bash install/upgrade <package> verbose
```

---

</details>

<details>
<summary>I can't upgrade?</summary>

---

```
monero-bash upgrade <package> force
```
Will forcefully upgrade, even if up to date

OR

```
monero-bash remove <package> &&
monero-bash install <package>
```

---
</details>

<details>
<summary>Can I cancel mid-upgrade?</summary>

---

**Yes**

monero-bash uses temporary folders until it's ready to swap binaries:
```
/tmp/monero-bash.XXXXXXXXX
```

If you cancel ***right*** as the software is being upgraded, monero-bash will swap back your old binaries, and clean up temporary files.

If you cancel ***after*** software is installed, but before the local state is updated, monero-bash will force update it and clean up.

---

</details>

<details>
<summary>Where is monero-bash installed?</summary>

---

Installation path:
```
/usr/local/share/monero-bash
```
PATH symlink:
```
/usr/local/bin/monero-bash
```
User folder:
```
/home/user/.monero-bash
```
`systemd` files:
```bash
/etc/systemd/systemd/monero-bash-$PACKAGE_NAME.service
```

---
</details>

<details>
<summary>Where are packages installed?</summary>

---

```
/usr/local/share/monero-bash/bin/
```

---
</details>

<details>
<summary>Where are the config files?</summary>

---

```
$HOME/.monero-bash/config
```

---

</details>

<details>
<summary>Where are the wallets?</summary>

---

```
$HOME/.monero-bash/wallets
```

---

</details>

<details>
<summary>Where are the systemd files?</summary>

---

```
/etc/systemd/system/
├─ monero-bash-monerod.service
├─ monero-bash-p2pool.service
├─ monero-bash-xmrig.service
```

---

</details>

<details>
<summary>Does monero-bash have dependencies?</summary>

---

**No**

If you have a mainstream Linux distro you already have everything needed:

* `bash v5+`
* `wget`
* `systemd`
* `GNU core utilities`
* `Linux core utilities (util-linux)`

See [Distro Coverage](#Distro-Coverage) for more info.

---

</details>
