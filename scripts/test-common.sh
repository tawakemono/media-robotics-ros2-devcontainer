#!/usr/bin/env bash
# 共通: プロセスグループ単位の後始末、ログ保存、最大30秒の受信待ち。
set -Eeuo pipefail
# shellcheck disable=SC2034 # 呼び出し元のtest-local/test-guiで使用する。
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d /tmp/ros2-test.XXXXXX)
groups=()
cleanup() {
    local result=$?
    trap - EXIT
    if ((result != 0)); then
        echo "FAIL: ${BASH_SOURCE[1]:-test} (status=$result)" >&2
        for log in "$work"/*.log; do
            [[ -f $log ]] || continue
            echo "=== $log ===" >&2
            tail -n 60 "$log" >&2
        done
    fi
    for pid in "${groups[@]}"; do kill -TERM -- "-$pid" 2>/dev/null || true; done
    sleep 1
    for pid in "${groups[@]}"; do
        kill -KILL -- "-$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    done
    if [[ -n ${TEST_LOG_DIR:-} ]]; then
        mkdir -p "$TEST_LOG_DIR"
        cp -a "$work/." "$TEST_LOG_DIR/"
    fi
    rm -rf "$work"
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# ROSのsetupスクリプトは未定義変数を参照する場合がある。
set +u
# shellcheck source=/dev/null
source /opt/ros/humble/setup.bash
set -u
export ROS_LOCALHOST_ONLY=1 RMW_IMPLEMENTATION=rmw_fastrtps_cpp PYTHONUNBUFFERED=1
export ROS_LOG_DIR="$work/ros-logs"
# 同一ホスト内のテスト同士でドメインを共有しない。
exec 8> /tmp/ros2-test-domain-selector.lock
flock -w 10 8
domain_selected=false
for domain in $(shuf -i 10-99); do
    exec 7>"/tmp/ros2-test-domain-$domain.lock"
    if flock -n 7; then export ROS_DOMAIN_ID=$domain; domain_selected=true; break; fi
done
flock -u 8
$domain_selected || { echo '空きドメインがありません。' >&2; exit 1; }
namespace="/test_$(basename "$work" | tr '.-' '__')"
echo "Test workspace=$work ROS_DOMAIN_ID=$ROS_DOMAIN_ID namespace=$namespace"
start_node() {
    local logfile=$1
    shift
    setsid "$@" >"$work/$logfile.log" 2>&1 7>&- 8>&- &
    groups+=("$!")
}
wait_message() {
    local logfile=$1 pattern=$2
    for ((attempt=0; attempt<150; attempt++)); do
        for pid in "${groups[@]}"; do
            kill -0 "$pid" 2>/dev/null || { echo "プロセス $pid が終了しました。" >&2; return 1; }
        done
        if grep -Fq "$pattern" "$work/$logfile.log"; then return; fi
        sleep 0.2
    done
    echo "30秒以内に受信できませんでした: $pattern" >&2
    return 1
}
