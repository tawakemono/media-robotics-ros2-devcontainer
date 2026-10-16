#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=scripts/test-common.sh
source "$(dirname "$0")/test-common.sh"
echo '[1/4] GUI起動・再実行'
timeout --kill-after=5 60 bash "$repo/.devcontainer/scripts/start-gui.sh"
state="/tmp/ros2-gui-$(id -u)"
before=$(cat "$state"/*.pid)
timeout --kill-after=5 60 bash "$repo/.devcontainer/scripts/start-gui.sh"
[[ $before == "$(cat "$state"/*.pid)" ]]
export DISPLAY=:99
echo '[2/4] 仮想ディスプレイとHTTP'
pgrep -u "$(id -u)" -x Xvfb
timeout 10 xdpyinfo -display :99 >"$work/display.log"
curl --fail --silent --max-time 10 http://127.0.0.1:6080/vnc.html >"$work/novnc.log"
# VNCとWebSocketのlisten先がloopbackだけであることも確認する。
python3 - <<'PY'
import subprocess
for port in (5900, 6080):
    lines = subprocess.check_output(['ss', '-H', '-ltn', f'sport = :{port}'], text=True).splitlines()
    assert lines, f'{port}: listenerなし'
    assert all(line.split()[3] == f'127.0.0.1:{port}' for line in lines), lines
print('loopback bind OK')
PY
echo '[3/4] rqt_graph / rqt_image_viewとデータ送信'
start_node gui-talker ros2 run demo_nodes_cpp talker --ros-args -r "__ns:=$namespace"
start_node gui-image python3 "$repo/tests/publish-image.py"
start_node rqt-graph ros2 run rqt_graph rqt_graph
start_node rqt-image ros2 run rqt_image_view rqt_image_view /test_image
# QtウィンドウがXサーバーに登録されるまで最大30秒待機。
for ((attempt=0; attempt<150; attempt++)); do
    for pid in "${groups[@]}"; do kill -0 "$pid"; done
    xwininfo -root -tree >"$work/windows.log"
    if grep -qi 'rqt_graph' "$work/windows.log" && grep -qi 'rqt_image_view' "$work/windows.log"; then break; fi
    sleep 0.2
done
grep -qi 'rqt_graph' "$work/windows.log"
grep -qi 'rqt_image_view' "$work/windows.log"
echo '[4/4] 起動後の生存とQtエラー確認'
sleep 3
for pid in "${groups[@]}"; do kill -0 "$pid"; done
if grep -Ei 'Traceback|could not connect to display|could not (load|find).*plugin|ModuleNotFoundError|ImportError|Segmentation fault' "$work"/rqt-*.log; then
    exit 1
fi
echo 'PASS: test-gui（ブラウザでの表示・操作は別途手動確認）'
