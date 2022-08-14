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

# all-in-one mining functions
# invoked by "monero-bash <cmd> all"

mine_Start()
{
	missing_Monero
	missing_XMRig
	missing_P2Pool
	if [[ "$MINE_UNCONFIGURED" = "true" ]]; then
		printf "%s\n" "First time detected! Entering configure mode."
		mine_Config
	else
		[[ $AUTO_HUGEPAGES = "true" ]] && mine_Hugepages
		define_Monero;process_Start
		define_P2Pool;process_Start
		define_XMRig;process_Start
		printf "Watch with: "
		$bwhite; echo "[monero-bash watch <monero/p2pool/xmrig>]" ;$off
	fi
}

mine_Stop()
{
	prompt_Sudo;error_Sudo
	define_Monero;process_Stop
	define_P2Pool;process_Stop
	define_XMRig;process_Stop
}

mine_Restart()
{
	prompt_Sudo;error_Sudo
	define_Monero;process_Restart
	define_P2Pool;process_Restart
	define_XMRig;process_Restart
}

mine_Kill()
{
	prompt_Sudo;error_Sudo
	define_Monero;process_Kill
	define_P2Pool;process_Kill
	define_XMRig;process_Kill
}

mine_Hugepages()
{
    # set default if not specified in monero-bash.conf
    [[ -z $HUGEPAGES ]] && HUGEPAGES="3072"
    $bwhite; echo "Setting hugepage: $HUGEPAGES" ;$off
    sudo sysctl vm.nr_hugepages="$HUGEPAGES" > /dev/null
    error_Continue "Could not set hugepages..."
}

mine_Config()
{
	while :; do
    $bred; echo "#-----------------------------------------#"
    $bred; echo "#   P2Pool & XMRig mining configuration   #"
    $bred; echo "#-----------------------------------------#"

	# wallet + daemon ip + pool ip + mini config
	unset -v WALLET_INTERACTIVE IP RPC ZMQ POOL MINI LOG
	$bwhite; printf "WALLET ADDRESS: " ;$off
	read -r WALLET_INTERACTIVE
	echo

	$byellow; printf "%s\n" "Hit [enter] to select the [default]" "if you don't know what to input."
	$bwhite; printf "MONERO NODE IP [default: 127.0.0.1]: " ;$off
	read -r IP
	$bwhite; printf "MONERO RPC PORT [default: 18081]: " ;$off
	read -r RPC
	$bwhite; printf "MONERO ZMQ PORT [default: 18083]: " ;$off
	read -r ZMQ
	$bwhite; printf "POOL IP [default: 127.0.0.1:3333]: " ;$off
	read -r POOL
	$bwhite; printf "P2Pool Log Level (0-6) [default - 1]: " ;$off
	read -r LOG
	$bwhite; printf "Use P2Pool Mini-Pool? (Y/n): " ;$off
	Yes(){ MINI="true" ;}
	No(){ MINI="false" ;}
	prompt_YESno
	echo

	# repeat & confirm user input
	$bblue; printf "WALLET ADDRESS   | " ;$off; echo "$WALLET_INTERACTIVE"

	$bblue; printf "MONERO NODE IP   | " ;$off
	[[ $IP ]] || IP="127.0.0.1"
	echo "$IP"

	$bblue; printf "MONERO RPC PORT  | " ;$off
	[[ $RPC ]] || RPC="18081"
	echo "$RPC"

	$bblue; printf "MONERO ZMQ PORT  | " ;$off
	[[ $ZMQ ]] || ZMQ="18083"
	echo "$ZMQ"

	$bblue; printf "POOL IP          | " ;$off
	[[ $POOL ]] || POOL="127.0.0.1:3333"
	echo "$POOL"

	$bblue; printf "P2POOL LOG LEVEL | " ;$off
	[[ $LOG ]] || LOG="1"
	echo "$LOG"

	$bblue; printf "P2POOL MINI      | " ;$off; echo "$MINI"

	$bwhite; printf "Use these settings? (Y/n) "

	# set user input if yes, repeat if no
	Yes()
	{
		prompt_Sudo ; error_Sudo
		safety_HashList
		trap "" 1 2 3 6 15

		# monero-bash.conf
		echo "Editing monero-bash.conf..."
		sudo -u "$USER" sed \
				-i -e "s/^DAEMON_IP=.*$/DAEMON_IP=${IP}/" "$config/monero-bash.conf" \
				-i -e "s/^DAEMON_RPC=.*$/DAEMON_RPC=${RPC}/" "$config/monero-bash.conf" \
				-i -e "s/^DAEMON_ZMQ=.*$/DAEMON_ZMQ=${ZMQ}/" "$config/monero-bash.conf" \
				-i -e "s/^WALLET=.*$/WALLET=${WALLET_INTERACTIVE}/" "$config/monero-bash.conf" \
				-i -e "s/^LOG_LEVEL=.*$/LOG_LEVEL=${LOG}/" "$config/monero-bash.conf"

		# p2pool.json
		echo "Editing p2pool.json..."
		if [[ $MINI = true ]]; then
			sudo -u "$USER" sed -i "s@\"name\":.*@\"name\": \"mini\",@" "$p2poolConf"
		else
			sudo -u "$USER" sed -i "s@\"name\":.*@\"name\": \"default\",@" "$p2poolConf"
		fi
		systemd_P2Pool

		# xmrig.json
		echo "Editing xmrig.json..."
		sudo -u "$USER" sed \
			-i -e "s@\"user\":.*@\"user\": \"${WALLET_INTERACTIVE}\",@" "$xmrigConf" \
			-i -e "s@\"url\":.*@\"url\": \"${POOL}\",@" "$xmrigConf"

		# state file
		sudo -u "$USER" sed -i "s@.*MINE_UNCONFIGURED.*@MINE_UNCONFIGURED=false@" "$state"
		PRODUCE_HASH_LIST
		echo
		$bgreen; echo "Mining configuration complete!"
		$white; echo -n "To get started: "
		$bwhite; echo "[monero-bash start all]"
	}
	No(){ :; }
	local yn
    read yn
    if [[ $yn = "" || $yn = "y" || $yn = "Y" ||$yn = "yes" || $yn = "Yes" ]]; then
        Yes
        break
    else
        No
    fi
	done
}
