#!/usr/bin/env bash
# 必ず source で呼び出し、現在のシェルに設定する。
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    echo '使い方: source .devcontainer/scripts/use-robot-network.sh <ROS_DOMAIN_ID: 0..101>' >&2
    exit 1
fi

use_robot_network() {
    if [[ $# != 1 || ! $1 =~ ^(0|[1-9][0-9]?)$|^10[01]$ ]]; then
        echo 'ROS_DOMAIN_ID は 0..101 の整数を指定してください（Linuxの安全なポート範囲）。' >&2
        return 1
    fi
    if ! command -v ros2 >/dev/null; then
        echo '先に source /opt/ros/humble/setup.bash を実行してください。' >&2
        return 1
    fi
    # daemonはドメインごとに存在するため、切替前と切替後の両方を停止する。
    timeout 10 ros2 daemon status || return 1
    timeout 10 ros2 daemon stop || return 1
    export ROS_DOMAIN_ID=$1
    export ROS_LOCALHOST_ONLY=0
    timeout 10 ros2 daemon stop || return 1
    printf 'ROS_DOMAIN_ID=%s ROS_LOCALHOST_ONLY=%s RMW_IMPLEMENTATION=%s\n' \
        "$ROS_DOMAIN_ID" "$ROS_LOCALHOST_ONLY" "${RMW_IMPLEMENTATION:-既定値}"
    echo 'このターミナルで設定しました。ほかのターミナルでも同じコマンドを実行してください。'
}
use_robot_network "$@"
