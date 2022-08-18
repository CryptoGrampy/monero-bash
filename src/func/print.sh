# This file is part of [monero-bash]
#
# Copyright (c) 2022 hinto.janaiyo
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Parts of this project are originally:
# Copyright (c) 2019-2022, jtgrassie
# Copyright (c) 2014-2022, The Monero Project

# Print Functions
print_GreenHash()
{
	$bgreen; echo "<######> $1" ;$off
}

print_BlueHash() {
	$bblue; echo "<######> $1" ;$off
}

print_RedHash()
{
	$bred; echo "<######> $1" ;$off
}

print_WhiteHash()
{
	$bwhite; echo "<######> $1" ;$off
}

print_CyanHash()
{
	$bcyan; echo "<######> $1" ;$off
}

print_YellowHash()
{
	$byellow; echo "<######> $1" ;$off
}

print_PurpleHash()
{
	$bpurple; echo "<######> $1" ;$off
}

print_MoneroBashTitle()
{
	$bred; echo "#-------------------------#"
	$bred; echo "#       monero-bash       #"
	$bred; echo "#-------------------------#"
	$off
}

print_Version()
{
	local VERSION_OLD
	$bwhite; echo -n "monero-bash | "
	if [[ "$MONERO_BASH_OLD" = "true" ]]; then
		$bred; echo "$MONERO_BASH_VER"
		VERSION_OLD=true
	else
		$bgreen; echo "$MONERO_BASH_VER"
	fi
	$bwhite; echo -n "Monero      | "
	if [[ $MONERO_VER && "$MONERO_OLD" = "true" ]]; then
		$bred; echo "$MONERO_VER"
		VERSION_OLD=true
	else
		$bgreen; echo "$MONERO_VER"
	fi
	$bwhite; echo -n "XMRig       | "
	if [[ $XMRIG_VER && "$XMRIG_OLD" = "true" ]]; then
		$bred; echo "$XMRIG_VER"
		VERSION_OLD=true
	else
		$bgreen; echo "$XMRIG_VER"
	fi
	$bwhite; echo -n "P2Pool      | "
	if [[ $P2POOL_VER && "$P2POOL_OLD" = "true" ]]; then
		$bred; echo "$P2POOL_VER"
		VERSION_OLD=true
	else
		$bgreen; echo "$P2POOL_VER"
	fi
	[[ $VERSION_OLD = true ]] && return 1 || return 0
}

print_Usage()
{
    $bwhite; echo -n "USAGE: "
    $bred; echo -n "monero-bash "
    $byellow; echo -n "<argument> "
    $bpurple; echo "[optional]" ;$off
    echo
    cat "$installDirectory/src/txt/usage"
}

print_Size()
{
	$off; echo -n "monero-bash install: " ;$byellow
	du -h "$installDirectory"  --exclude="$installDirectory/bin" | tail -n 1 | awk '{print $1}'
	$off; echo -n "/.monero-bash/: " ;$byellow
	du -h "$dotMoneroBash" | tail -n 1 | awk '{print $1}'
	if [[ -d "$bitMonero" ]]; then
		$off; echo -n "$bitMonero/: " ;$byellow
		du -h "$bitMonero" | tail -n 1 | awk '{print $1}'
	fi
	if [[ $MONERO_VER != "" ]]; then
		$off; echo -n "Monero: " ;$byellow
		du -h "$binMonero" | tail -n 1 | awk '{print $1}'
	fi
	if [[ $XMRIG_VER != "" ]]; then
		$off; echo -n "XMRig: " ;$byellow
		du -h "$binXMRig" | tail -n 1 | awk '{print $1}'
	fi
	if [[ $P2POOL_VER != "" ]]; then
		$off; echo -n "P2Pool: " ;$byellow
		du -h "$binP2Pool" | tail -n 1 | awk '{print $1}'
	fi
}

print_Error()
{
	$bred; printf "[monero-bash error] "
	$iwhite; echo "$1"; $off
}

print_Warn()
{
	$byellow; printf "[monero-bash warning] "
	$iwhite; echo "$1"; $off
}

print_Error_Exit()
{
	$bred; printf "[monero-bash error] "
	$iwhite; echo "$1"; $off
	exit 1
}

# used for color coding sha256sum/gpg output (FOR VERIFY FUNCTION)
print_OKFAILED()
{
	if [[ $? = "0" ]]; then
		$off; echo -n "[${HASH:0:4}...${HASH:60:64}] "
		$igreen; echo "HASH OK"
		verifyOK="true"
	else
		$off; echo -n "[${HASH:0:4}...${HASH:60:64}] "
		$bred; echo "HASH FAIL" ;$off
		verifyOK="false"
	fi
}

print_GPG()
{
	if [[ $? = "0" ]]; then
		$off; echo -n "[${FINGERPRINT:0:4}...${FINGERPRINT:36:40}] "
		$igreen; echo "SIGN OK"
		gpgOK="true"
	else
		$off; echo -n "[${FINGERPRINT:0:4}...${FINGERPRINT:36:40}] "
		$bred; echo "SIGN FAIL" ;$off
		gpgOK="false"
	fi
}

print_SeedLanguageList()
{
cat <<EOM
0  : Deutsch
1  : English
2  : Español
3  : Français
4  : Italiano
5  : Nederlands
6  : Português
7  : русский язык
8  : 日本語
9  : 简体中文 (中国)
10 : Esperanto
11 : Lojban
EOM
}

print_Upgrade()
{
	# if any pkgs are installed and old, print them
	if [[ $MONERO_BASH_OLD = "true" \
		|| $MONERO_VER != "" && $MONERO_OLD = "true" \
		|| $XMRIG_VER != "" && $XMRIG_OLD = "true" \
		|| $P2POOL_VER != "" && $P2POOL_OLD = "true" ]]; then
		$bwhite; printf "Packages to upgrade: " ;$off

		[[ $MONERO_BASH_VER != "" && $MONERO_BASH_OLD = "true" ]]&& printf " [monero-bash] "
		[[ $MONERO_VER != "" && $MONERO_OLD = "true" ]]&& printf " [Monero] "
		[[ $XMRIG_VER != "" && $XMRIG_OLD = "true" ]]&& printf " [XMRig] "
		[[ $P2POOL_VER != "" && $P2POOL_OLD = "true" ]]&& printf " [P2Pool] "
		echo;echo
	else
		$bwhite; printf "All packages: "
		$bgreen; echo "up to date"; $off
		exit 1
	fi
}

print_Install()
{
	if [[ $MONERO_VER = "" || $XMRIG_VER = "" || $P2POOL_VER = "" ]]; then
		$bwhite; printf "Packages to install: " ;$off

		[[ $MONERO_VER = "" ]]&& printf " [Monero] "
		[[ $XMRIG_VER = "" ]]&& printf " [XMRig] "
		[[ $P2POOL_VER = "" ]]&& printf " [P2Pool] "
		echo;echo
	else
		$bwhite; printf "All packages: "
		$bgreen; echo "already installed"; $off
		exit 1
	fi
}

print_Remove()
{
		$bwhite; printf "Packages to remove: " ;$off
		[[ $MONERO_VER != "" ]]&& printf " [Monero] "
		[[ $XMRIG_VER != "" ]]&& printf " [XMRig] "
		[[ $P2POOL_VER != "" ]]&& printf " [P2Pool] "
		echo;echo
}

print_rpc_Usage()
{
echo -e "$(cat <<EOF
\033[1;37mUSAGE\033[0m
    monero-bash rpc \033[0;94m[host:port] \033[0;92mmethod \033[0;91m[name:value ...]
\033[1;37mEXAMPLES\033[0m
    monero-bash rpc \033[0;92mget_block\033[0m
    monero-bash rpc \033[0;94mnode.community.rino.io:18081\033[0m \033[0;92mget_block\033[0m
    monero-bash rpc \033[0;94m127.0.0.1:18081\033[0m \033[0;92mget_block\033[0m \033[0;91mheight:123456\033[0m
    monero-bash rpc \033[0;94mlocalhost:18081\033[0m \033[0;92mget_block\033[0m \033[0;91mhash:418015bb9ae982a1975da7d79277c2705727a56894ba0fb246adaabb1f4632e3\033[0m
\033[1;37mSETTINGS\033[0m
    DEFAULT IP/PORT = 127.0.0.1:18081
    CURRENT IP/PORT = $DAEMON_RPC_IP
\033[1;37mJSON RPC Methods\033[0m
    add_aux_pow
    banned
    calc_pow
    flush_cache
    flush_txpool
    generateblocks
    get_alternate_chains
    get_bans
    get_block
    get_block_count
    get_block_header_by_hash
    get_block_header_by_height
    get_block_headers_range
    get_block_template
    get_coinbase_tx_sum
    get_connections
    get_fee_estimate
    get_info
    get_last_block_header
    get_miner_data
    get_output_distribution
    get_output_histogram
    get_txpool_backlog
    get_version
    hard_fork_info
    on_get_block_hash
    on_getblockhash
    prune_blockchain
    relay_tx
    rpc_access_account
    rpc_access_data
    rpc_access_info
    rpc_access_pay
    rpc_access_submit_nonce
    rpc_access_tracking
    set_bans
    submit_block
    sync_info
EOF
)"
}
