#!/usr/bin/env bash
set -Eeuo pipefail
export DISPLAY=:99
state="/tmp/ros2-gui-$(id -u)"
mkdir -p "$state"
chmod 700 "$state"
exec 9>"$state/start.lock"
flock -w 30 9 || { echo 'GUI起動ロックの取得がタイムアウトしました。' >&2; exit 1; }
started=()
fail() {
    local status=$?
    trap - ERR
    echo "GUIの起動に失敗しました (status=$status)。ログ: $state" >&2
    for log in "$state"/*.log; do
        [[ -f $log ]] || continue
        echo "=== $log ===" >&2
        tail -n 30 "$log" >&2
    done
    for pid in "${started[@]}"; do kill "$pid" 2>/dev/null || true; done
    exit "$status"
}
trap fail ERR

alive() {
    local name=$1 pid args
    [[ -f $state/$name.pid ]] || return 1
    read -r pid < "$state/$name.pid"
    [[ $pid =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    args=$(ps -p "$pid" -o args=)
    [[ $args == *"$name"* ]]
}
start() {
    local name=$1
    shift
    if alive "$name"; then return; fi
    nohup "$@" >"$state/$name.log" 2>&1 9>&- < /dev/null &
    local pid=$!
    started+=("$pid")
    echo "$pid" > "$state/$name.pid"
}
wait_ready() {
    local name=$1
    shift
    for ((i=0; i<50; i++)); do
        alive "$name" || { echo "$name が終了しました。" >&2; return 1; }
        if "$@" >/dev/null 2>&1; then return; fi
        sleep 0.2
    done
    echo "$name の準備がタイムアウトしました。" >&2
    return 1
}

if ! alive Xvfb && xdpyinfo -display :99 >/dev/null 2>&1; then
    echo '別のXサーバーが :99 を使用しています。' >&2
    false
fi
start Xvfb Xvfb :99 -screen 0 1280x800x24 -nolisten tcp
wait_ready Xvfb xdpyinfo -display :99
cp /etc/X11/fluxbox/init "$state/fluxbox-init"
printf 'background: unset\n' > "$state/fluxbox-overlay"
printf '\nsession.styleOverlay: %s/fluxbox-overlay\n' "$state" >> "$state/fluxbox-init"
start fluxbox fluxbox -rc "$state/fluxbox-init"
wait_ready fluxbox xprop -root _NET_SUPPORTING_WM_CHECK
start x11vnc x11vnc -display :99 -forever -shared -nopw -listen 127.0.0.1 -no6 -noipv6 -rfbportv6 -1 -rfbport 5900
wait_ready x11vnc python3 -c 'import socket; s=socket.create_connection(("127.0.0.1",5900),1); assert s.recv(12).startswith(b"RFB "); s.close()'
start websockify websockify --web=/usr/share/novnc 127.0.0.1:6080 127.0.0.1:5900
wait_ready websockify curl --fail --silent --max-time 2 http://127.0.0.1:6080/vnc.html
# 起動直後のポート競合による終了も検出する。
sleep 0.3
for name in Xvfb fluxbox x11vnc websockify; do alive "$name"; done
echo "GUI ready: http://localhost:6080/vnc.html (ログ: $state)"
