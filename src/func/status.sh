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


# status function, prints multiple helpful stats

status_All()
{
	print_MoneroBashTitle
	print_Version
	status_System
	[[ $MONERO_VER != "" ]]&& status_Monero
	[[ $P2POOL_VER != "" ]]&& status_P2Pool
	[[ $XMRIG_VER != "" ]]&& status_XMRig
	exit 0
}

status_System()
{
	$bblue; printf "System      | "
	$iwhite; echo "$(uptime -p)"
	echo
}

status_Template()
{
	$bwhite; printf "[${NAME_PRETTY}] " ;$off
	if pgrep $DIRECTORY/$PROCESS -f &>/dev/null ;then
		$bgreen; echo "ONLINE" ;$off

		# ps stats
		ps -o "| %C | %t |" -p $(pgrep $DIRECTORY/$PROCESS -f)
		echo "----------------------"
		# process specific stats
		EXTRA_STATS
		echo
	else
		$bred; echo "OFFLINE" ;$off
		echo
	fi
}

status_Monero()
{
	define_Monero
	EXTRA_STATS()
	{
		# Get into memory so we can split it
		# (the regular output is ugly long)
		local STATUS="$($binMonero/monerod status)"
		# Split per newline
		local IFS=$'\n' LINE l=0
		for i in $STATUS; do
			LINE[$l]="$i"
			((l++))
		done
		# This removes the ANSI color codes in monerod output
		LINE[0]="$(echo "${LINE[0]}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g; s/[^[:print:]]//g')"
		printf "\e[0;96m%s\e[0m\n" "${LINE[0]}"

		# Split this line into 2
		LINE[1]="$(echo "${LINE[1]}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g; s/[^[:print:]]//g; s/, net hash/\nnet hash/')"
		# Replace ',' with '|' and add color
		echo -e "\e[0;92m${LINE[1]//, /\\e[0;97m | \\e[0;92m}\e[0m"
	}
	status_Template
}

status_P2Pool()
{
	define_P2Pool
	EXTRA_STATS()
	{
		$bwhite; printf "Wallet        | "
		$white; echo "${WALLET:0:6}...${WALLET: -6}"

		# Get p2pool.log into memory.
		# Also ONLY look for logs after
		# p2pool is fully synced.
		local LOG="$(tac $DIRECTORY/p2pool.log | grep -m1 "SideChain SYNCHRONIZED")"
		# Get time of sync (read wall of text for reason)
		local SYNC_DAY="$(echo "$LOG" | grep -o "..-..-..-")"
		local SYNC_TIME="$(echo "$LOG" | grep -o "..:..:..")"

		# Return error if P2Pool is not synced yet.
		if [[ $LOG != *"SideChain SYNCHRONIZED"* ]]; then
			$bred; printf "%s\n" "Warning       | P2Pool is not fully synced yet"
			return 1
		# Return error if ZMQ error message is found
		elif ZMQ_LOG=$(echo "$LOG" | grep -o "ZMQReader failed to connect to.*$"); then
			$bred; printf "%s\n" "Warning       | P2Pool failed to connect to [monerod]'s ZMQ server!"
			$bred; printf "%s\n" "Warning       | "
			return 1
		else
			LOG="$(sed -n "/$LOG/,/*/p" $DIRECTORY/p2pool.log)"
		fi

		# P2POOL ALLOWING MINER CONNECTIONS DURING SYNC CAUSES FAKE STATS
		# ---------------------------------------------------------------
		# If you have miners already pointed at p2pool while it's syncing,
		# it will send jobs to those miners, even though it's still syncing.
		# This is a big issue because it causes fake stats.
		# (e.g.: SHARE FOUND message on a fake job).
		#
		# P2Pool doesn't COMPLETELY KILL the old jobs EVEN AFTER SYNCING.
		# So if you get unlucky and get an accepted share within the same
		# milliseconds as syncing (which is easy since you're the only
		# miner on your fake chain), you'll get something like this:
		#
		# 2022-08-14 15:58:09.2753 SideChain SYNCHRONIZED           <--- okay, we're synced? time to parse from here!
		# 2022-08-14 15:58:09.3276 SHARE FOUND: mainchain ...       <--- wow! these have to be real shares we found
		# 2022-08-14 15:58:09.3315 SHARE FOUND: mainchain ...            since we synced already, right...? RIGHT SCHERNYKH...!?
		#
		# How the hell am I supposed to know if these shares are real or not?
		# They _ARE_ after the "SYNCHRONIZED" message but they aren't real.
		# Even P2Pool itself is fooled when you type 'status', it'll show them as
		# 100% real mainchain shares you found. I think this awkward print order
		# is because the miner job is multi-threaded, so it returns at uneven timings.
		#
		# P2Pool also has other issues like printing "SYNCHRONIZED" multiple
		# times which will temporarily allow for invalid parsing, this is fine
		# though because it'll eventually print "SYNCHRONIZED" again and it'll be fixed.
		#
		# The fake share parsing fix:
		# 1. Parse the time of the SYNCHRONIZED msg
		# 2. Get the NEXT second after that initial time
		# 3. Account for any time overflows (23:59:59 -> 00:00:00)
		# 4. Delete any lines that contain those (2 second) timestamps
		#
		# 2 seconds should be a big enough margin to delete the fake shares,
		# and small enough to not clobber any real shares found.
		#
		# $SYNC_TIME   = intial sync timestamp
		# $SYNC_TIME_2 = 1 second after

		# 22:22:22 -> 22 22 22
		SYNC_SPACE=(${SYNC_DAY//-/ } ${SYNC_TIME//:/ })
		# Back into string because it's easier to read
		local SYNC_YEAR=${SYNC_SPACE[0]}
		local SYNC_MONTH=${SYNC_SPACE[1]}
		local SYNC_DAY=${SYNC_SPACE[2]}
        local SYNC_HOUR=${SYNC_SPACE[3]}
        local SYNC_MINUTE=${SYNC_SPACE[4]}
        local SYNC_SECOND=${SYNC_SPACE[5]}

        # Account for overflow (23:59:59 -> 00:00:00)
		# Second
        if [[ $SYNC_SECOND = 59 ]]; then
            SYNC_SECOND=00
            # Bash ((n++)) doesn't like leading 0's so use AWK
            SYNC_MINUTE=$(echo "$SYNC_MINUTE" | awk '{print $1 + 1}')
            # Add back leading 0's (awk strips them)
            [[ ${#SYNC_MINUTE} = 1 ]] && SYNC_MINUTE="0${SYNC_MINUTE}"
        else
            SYNC_SECOND=$(echo "$SYNC_SECOND" | awk '{print $1 + 1}')
            [[ ${#SYNC_SECOND} = 1 ]] && SYNC_SECOND="0${SYNC_SECOND}"
        fi
		# Minute
        if [[ $SYNC_MINUTE = 60 ]]; then
            SYNC_MINUTE=00
            SYNC_HOUR=$(echo "$SYNC_HOUR" | awk '{print $1 + 1}')
        fi
		# Hour
        if [[ $SYNC_HOUR = 24 ]]; then
            SYNC_HOUR=00
            SYNC_DAY=$(echo "$SYNC_DAY" | awk '{print $1 + 1}')
		fi
		# Days
		# Yes, I realize some months are less than 31 days.
		# I'm not going write code to figure that out,
		# the overflow reaching all the way here probably
		# won't happen that often enough anyway :)
		if [[ $SYNC_DAY = 32 ]]; then
			SYNC_DAY=01
			SYNC_MONTH=$(echo "$SYNC_MONTH" | awk '{print $1 + 1}')
		fi
		# Months
		if [[ $SYNC_MONTH = 13 ]]; then
			SYNC_MONTH=01
			SYNC_YEAR=$(echo "$SYNC_YEAR" | awk '{print $1 + 1}')
		fi

		# Our 2nd date+time we will use.
		SYNC_DAY_2="${SYNC_YEAR}-${SYNC_HOUR}-${SYNC_DAY}"
		SYNC_TIME_2="${SYNC_HOUR}:${SYNC_MINUTE}:${SYNC_SECOND}"

		# Delete all lines within 2 seconds of initial SYNC
		LOG="$(echo "$LOG" | sed "/${SYNC_DAY} ${SYNC_TIME}/d; /${SYNC_DAY_2} ${SYNC_TIME_2}/d")"

		# Okay, we're good.
		# Hopefully we can parse properly now.
		#
		# Reminder: all of this breaks down if
		# Mr. Chernykh decides to change any
		# keywords or the 24h timing scheme.




		# SHARE OUTPUT VARIABLE
		local shareOutput="$(echo "$LOG" | grep "SHARE FOUND")"

		# SHARES PER HOUR
		if [[ -z $shareOutput ]]; then
			local sharesFound="0"
		else
			local sharesFound="$(echo "$shareOutput" | wc -l)"
		fi
		local processUnixTime="$(ps -p $(pgrep $DIRECTORY/$PROCESS -f) -o etimes=)"
		local processHours="$(($processUnixTime / 60 / 60))"
		[[ $processHours = 0 ]] && processHours="1"

		# SHARES PER DAY (not floating, 47 hours = 1 day)
		if [[ $processHours -lt 24 ]]; then
			local processDays="1"
		else
			local processDays="$(($processHours / 24))"
		fi

		# SHARES/hour & SHARES/day WITH FLOATING POINT
		local sharesPerHour="$(printf %.2f\\n "$((1000000000 * $sharesFound / $processHours ))e-9")"
		local sharesPerDay="$(printf %.2f\\n "$((1000000000 * $sharesFound / $processDays ))e-9")"

		# SHARES FOUND
		$bpurple; printf "Shares found  | "
		$off; echo "$sharesFound ($sharesPerHour per hour / $sharesPerDay per day)"

		# LATEST SHARE
		$bblue; printf "Latest share  | "
		$white; echo "$(echo "$shareOutput" | tail -1 | sed 's/mainchain //g; s/NOTICE .\|Stratum.*: //g; s/, diff .*, c/ c/; s/user.*, //')"

		# LATEST PAYOUT
		$byellow; printf "Latest payout | "
		$white; echo "$(echo "$LOG" | grep -m1 "payout" | sed 's/NOTICE  //; s/P2Pool //')"
	}
	status_Template
}

status_XMRig()
{
	define_XMRig
	EXTRA_STATS()
	{
		# WALLET (in xmrig.json)
		$bwhite; printf "Wallet       | " ;$off
		local wallet="$(grep -m1 "\"user\":" "$xmrigConf" | awk '{print $2}' | tr -d '","')"
		[[ -z $wallet ]] && echo || echo "${wallet:0:6}...${wallet: -6}"

		# POOL
		$bpurple; printf "Pool         | " ;$off
		grep -m1 "\"url\":" "$xmrigConf" | awk '{print $2}' | tr -d '","'

		# SHARES
		local shares="$(tac "$binXMRig/xmrig-log" | grep -m1 "accepted")"
		$bblue; printf "Latest share | "
		$white; echo "$shares"

		# HASHRATE
		local hashrate="$(tac "$binXMRig/xmrig-log" | grep -m1 "speed" | sed "s/].*miner.*speed/] speed/")"
		$byellow; printf "Hashrate     | "
		$white; echo "$hashrate"
	}
	status_Template
}
