#!/usr/bin/env bash

declare -A STATUS
declare -A EXIT_CODE
declare -A NAMES
declare -A TIMES

cleanup() {
    # Show cursor + leave alternate screen
    printf '\033[?25h'
    printf '\033[?1049l'
}
trap cleanup EXIT INT TERM

# Enter alternate screen + hide cursor
printf '\033[?1049h'
printf '\033[?25l'

render() {
    # Move cursor home + clear screen
    printf '\033[H\033[2J'

    printf "DOCKER CONTAINER MONITOR\n\n"

    printf "%-20s %-10s %-25s %-15s %-6s\n" \
        "TIME" "STATUS" "CONTAINER" "ID" "EXIT"

    printf "%-20s %-10s %-25s %-15s %-6s\n" \
        "--------------------" \
        "----------" \
        "-------------------------" \
        "---------------" \
        "------"

    for id in "${!STATUS[@]}"; do
        printf "%-20s %-10s %-25s %-15s %-6s\n" \
            "${TIMES[$id]}" \
            "${STATUS[$id]}" \
            "${NAMES[$id]}" \
            "${id:0:12}" \
            "${EXIT_CODE[$id]}"
    done

    printf "\nCtrl+C to quit\n"
}

render

docker events \
    --filter 'type=container' \
    --filter 'event=start' \
    --filter 'event=die' \
    --format '{{.Time}}|{{.Action}}|{{.Actor.Attributes.name}}|{{.Actor.ID}}|{{.Actor.Attributes.exitCode}}' |
while IFS='|' read -r timestamp action name id exit_code; do

    TIMES["$id"]=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
    NAMES["$id"]="$name"

    case "$action" in
        start)
            STATUS["$id"]="RUNNING"
            EXIT_CODE["$id"]="-"
            ;;
        die)
            STATUS["$id"]="EXITED"
            EXIT_CODE["$id"]="${exit_code:--}"
            ;;
    esac

    render
done
