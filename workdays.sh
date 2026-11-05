#!/usr/bin/env bash
#
# workdays_nav.sh — Interactive calendar navigator.
#   ← / → : previous / next month
#   ↑ / ↓ : previous / next year
#   q     : quit
#
# Shows a Monday-first calendar grid for the selected month/year and
# live-updates the working-day (Mon-Fri) count as you navigate.
#
# Pure bash + coreutils `date` — no whiptail/dialog/ncal needed.
#
# Usage: ./workdays_nav.sh
#

set -euo pipefail

MONTH=$(date +%-m)
YEAR=$(date +%Y)

MONTH_NAMES=("" "January" "February" "March" "April" "May" "June" "July" \
             "August" "September" "October" "November" "December")

# ---- terminal setup -------------------------------------------------------
cleanup() {
    tput cnorm 2>/dev/null || true   # restore cursor
    stty sane 2>/dev/null || true
    clear
}
trap cleanup EXIT

tput civis 2>/dev/null || true       # hide cursor

# ---- helpers ---------------------------------------------------------------
days_in_month() {
    # $1 = year, $2 = month (1-12)
    date -d "${1}-$(printf "%02d" "$2")-01 +1 month -1 day" +%d
}

first_weekday() {
    # ISO weekday of the 1st of the month: 1=Mon ... 7=Sun
    date -d "${1}-$(printf "%02d" "$2")-01" +%u
}

render() {
    clear
    local dim total_days first_dow workdays=0

    total_days=$(days_in_month "$YEAR" "$MONTH")
    first_dow=$(first_weekday "$YEAR" "$MONTH")

    local title="${MONTH_NAMES[$MONTH]} ${YEAR}"
    local pad=$(( (20 - ${#title}) / 2 ))
    printf "\n%*s%s\n" "$pad" "" "$title"
    echo "Mo  Tu  We  Th  Fr  Sa  Su"
    echo "---------------------------"

    # leading blanks (Mon-first grid, first_dow is 1..7 with 1=Mon)
    local blanks=$(( first_dow - 1 ))
    printf "%*s" "$((blanks * 4))" ""

    local col=$blanks
    for day in $(seq 1 "$total_days"); do
        local dow=$(( (blanks + day - 1) % 7 + 1 ))   # 1=Mon...7=Sun for this cell
        if [ "$dow" -le 5 ]; then
            workdays=$((workdays + 1))
        fi

        # highlight today
        if [ "$day" -eq "$(date +%-d)" ] && [ "$MONTH" -eq "$(date +%-m)" ] && [ "$YEAR" -eq "$(date +%Y)" ]; then
            printf "\e[7m%2d\e[0m  " "$day"
        else
            printf "%2d  " "$day"
        fi

        col=$((col + 1))
        if [ "$col" -eq 7 ]; then
            echo
            col=0
        fi
    done
    echo -e "\n"
    echo "Total days   : $total_days"
    echo "Working days : $workdays  (Mon-Fri)"
    echo
    echo "← prev month   → next month   ↑ prev year   ↓ next year   q quit"
}

# ---- main loop ---------------------------------------------------------------
stty -echo -icanon time 0 min 0

while true; do
    render
    key=""
    IFS= read -rsn1 key
    if [ "$key" = $'\x1b' ]; then
        read -rsn2 -t 0.01 key2 || true
        key="$key$key2"
    fi

    case "$key" in
        $'\x1b[C')  # right arrow -> next month
            MONTH=$((MONTH + 1))
            if [ "$MONTH" -gt 12 ]; then MONTH=1; YEAR=$((YEAR + 1)); fi
            ;;
        $'\x1b[D')  # left arrow -> prev month
            MONTH=$((MONTH - 1))
            if [ "$MONTH" -lt 1 ]; then MONTH=12; YEAR=$((YEAR - 1)); fi
            ;;
        $'\x1b[A')  # up arrow -> prev year
            YEAR=$((YEAR - 1))
            ;;
        $'\x1b[B')  # down arrow -> next year
            YEAR=$((YEAR + 1))
            ;;
        q|Q)
            break
            ;;
        *)
            ;;
    esac
done
