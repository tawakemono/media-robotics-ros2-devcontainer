# トラブルシューティング

コマンドは「ホスト」と明記したもの以外はコンテナで実行します。修正後は対象の確認コマンドと `bash scripts/test-local.sh` または `bash scripts/test-gui.sh` を再実行してください。

## Dockerが起動しない

**症状:** Docker daemonに接続できない。

**確認:** ホストで `docker version`。Ubuntuでは `systemctl is-active docker`、`id -nG`、`docker context show`。MacではDocker Desktopの起動状態。

**原因:** サービス停止、グループ未反映、異なるcontext。

**対処:** Ubuntuは `sudo systemctl start docker`。dockerグループを設定した直後はログアウト・ログイン。MacはDesktop起動完了を待つ。contextは使用するEngineのものを選ぶ。

**再確認:** ホストで `docker run --rm hello-world`。

## Dev Containerのビルドが失敗する

**症状:** APT失敗、ディスク不足、イメージ取得失敗。

**確認:** VS Codeの **Dev Containers: Show Container Log**。ホストで `df -h`、`docker system df`、`docker build --progress=plain -t ros2-lab:debug -f .devcontainer/Dockerfile .`。

**原因:** ネットワーク・ミラーの一時障害、空き容量不足、APTパッケージの欠落。

**対処:** 最初のエラーを確認し、回線・空き容量を修正する。容量整理は所有者が不要と判断したデータだけを対象にする。一時障害なら再ビルドする。

**再確認:** **Rebuild Container** を実行し、テストを通す。

Dev Containersログがベースイメージの確認で長時間止まる場合は、ホストで `docker pull ros:humble-ros-base-jammy` を実行し、取得完了後に再度Reopenしてください。今回のUbuntuではこの方法でCLI起動を確認しています。

## arm64でAPTパッケージを取得できない

**症状:** `Unable to locate package`、`no installation candidate`。

**確認:** ビルドログのパッケージ名、対象アーキテクチャ。利用可能なコンテナ内で `dpkg --print-architecture`、`apt-cache policy ros-humble-raspimouse-msgs`、`ls /etc/apt/sources.list.d`。

**原因:** アーキテクチャの強制指定、APT索引取得失敗、配布側の欠落。

**対処:** ホストの `printenv DOCKER_DEFAULT_PLATFORM` と追加の `--platform` を確認し、Apple Siliconはarm64を使用する。パッケージが本当に欠落する場合は配布元を調査し、必要機能を維持する修正が必要。pipでROSやPyQtを上書きしない。

**再確認:** arm64ネイティブビルドと共通テストを再実行する。結果をMac実機の成功と混同しない。

## VS Codeがコンテナに接続できない

**症状:** Reopen後に接続が終了する。

**確認:** ホストで `docker ps -a`、`docker logs <対象ID>`、Dev Containersログ、`code --list-extensions`。

**原因:** Docker停止、拡張機能未導入、起動処理の失敗。

**対処:** Engineと拡張機能を確認する。GUI起動失敗はGUIログで解決して再接続する。MacではHost Networkingを有効化する。

**再確認:** 新しいターミナルで `whoami` が `student`、`pwd` が `/home/student/ros2_ws`。

## ros2コマンドが認識されない

**症状:** `ros2: command not found`。

**確認:** `pwd`、`echo "$ROS_DISTRO"`、`ls /opt/ros/humble/setup.bash`。

**原因:** ホストのターミナルを使用している、非対話シェルでsetup未読込。

**対処:** コンテナのBashを開き、`source /opt/ros/humble/setup.bash`。自動スクリプトでも明示的に読み込む。

**再確認:** `ros2 --help`。

## Pythonからrclpyをimportできない

**症状:** `ModuleNotFoundError: rclpy`。

**確認:** `which python3`、`python3 --version`、`echo "$PYTHONPATH"`、`printenv VIRTUAL_ENV CONDA_PREFIX`。

**原因:** setup未読込、Conda・venv・別Pythonを使用。

**対処:** コンテナの `/usr/bin/python3`（3.10）を使い、ROS setupを読み込む。必要なvenvは `python3 -m venv --system-site-packages .venv` で作成し、システムライブラリを利用する。

**再確認:** `python3 -c 'import rclpy; print(rclpy.__file__)'`。

## colconでビルドに失敗する

**症状:** パッケージ検出・依存解決・entry pointで失敗。

**確認:** `colcon list`、`cat log/latest_build/*/stderr.log`、対象の `package.xml` / `setup.py` / `setup.cfg`。

**原因:** 依存・console_scripts記載漏れ、Python構文エラー、setup未読込。

**対処:** fixtureの構造と比較し、実験パッケージの記載を修正する。`source /opt/ros/humble/setup.bash` 後に `colcon build --symlink-install`。新規依存は指導者と確認して追加する。

**再確認:** `source install/setup.bash`、`ros2 pkg executables <パッケージ名>`、`ros2 run <パッケージ名> <実行名>`。

## 権限エラーでファイルを編集できない

**症状:** `src/` 等への保存がPermission denied。

**確認:** コンテナとホストで `id`、`ls -ln src`、Dev Containersログ。

**原因:** UID調整未反映、rootで生成した成果物。

**対処:** `updateRemoteUserUID: true` を確認してRebuild。rootで作成したファイルだけを対象に、所有者を確認して必要なファイルの所有権を修正する。ワークスペース全体へ無条件に再帰chownしない。

**再確認:** コンテナで作った確認ファイルをホストの一般ユーザーから編集して削除できる。

## noVNCが表示されない

**症状:** 接続拒否、Connect後に切断。

**確認:** `bash .devcontainer/scripts/start-gui.sh`、`curl -f http://127.0.0.1:6080/vnc.html`、`ss -ltn`、`ls /tmp/ros2-gui-$(id -u)`。

**原因:** 起動失敗、5900/6080の競合、MacのHost Networking無効。

**対処:** 上記ディレクトリのログを確認する。同一ホスト上の別のGUIコンテナが使っているなら、その所有者と調整して停止する。Desktopの設定を確認する。LANへ公開するbind設定には変更しない。

**再確認:** ホストのブラウザで `http://localhost:6080/vnc.html` に接続してConnectを押す。

## rqt_graphが起動しない

**症状:** ウィンドウが出ない、すぐ終了する。

**確認:** `echo "$DISPLAY"`、`xdpyinfo -display :99`、`ros2 run rqt_graph rqt_graph` のログ。

**原因:** GUIサービス停止、DISPLAY違い、Qt依存の不整合。

**対処:** GUIスクリプトを実行して `export DISPLAY=:99`。ノードが出ない場合はGUIの更新ボタンとフィルタも確認する。

**再確認:** `bash scripts/test-gui.sh` とブラウザ上のノード表示。

## Qtプラグイン関連のエラー

**症状:** xcb pluginロード失敗、QtSvgのimport失敗。

**確認:** `python3 -c 'from PyQt5 import QtWidgets, QtSvg'`、`printenv QT_PLUGIN_PATH QT_QPA_PLATFORM_PLUGIN_PATH`、`QT_DEBUG_PLUGINS=1 ros2 run rqt_graph rqt_graph`。

**原因:** pipのPyQt/OpenCV等がAPTライブラリと競合、別環境のプラグインパス。

**対処:** 外部環境のパス設定を外し、システムPythonとAPTのQtを使う。Dockerfileの共通環境からRebuildして再現性を確認する。

**再確認:** importとGUIテスト、rqt_image_viewの画像表示。

## ノードが見えない・ROS_DOMAIN_IDが一致しない

**症状:** `ros2 node list` が空、topic echoが受信しない。

**確認:** 両ターミナルで `printenv ROS_DOMAIN_ID ROS_LOCALHOST_ONLY RMW_IMPLEMENTATION`、`ros2 daemon status`。

**原因:** ドメイン不一致、古いdaemon、ローカル限定、ノード起動前の環境と異なる。

**対処:** ローカルなら両側をdomain 0 / localhost 1に揃える。実機は両側をチームID / localhost 0に揃える。daemonと既存ノードを停止して再起動する。

**再確認:** 文字列を送受信して内容を確認する。ノード列挙だけでは判定しない。

## Raspberry Piと通信できない

**症状:** Piのセンサが受信できない、片方向だけ届く。

**確認:** [実機通信の切り分け](robot-network.md#通信できないときの切り分け)を順に行い、`ros2 topic info <トピック> --verbose` で型とQoSも確認する。

**原因:** ネットワーク分離、RMW/QoS不一致、探索用またはデータ用UDP不達。

**対処:** 許可されたネットワークとポートを管理者に確認する。データがBEST_EFFORTの場合は受信側のQoSを合わせる。Piの既存設定を無断変更しない。

**再確認:** `/test_topic` の両方向受信と、実際のセンサの値の変化。

## Macでトピックを受信できない

**症状:** Host NetworkingでもPiのデータが来ない。

**確認:** DesktopバージョンとHost Networking有効状態、VPN、ファイアウォール、両方向の文字列とUDP到達性。

**原因:** Docker DesktopとLinux Engineのネットワーク差異、マルチキャスト・データ通信経路。

**対処:** [Mac手順の代替候補](setup-macos.md#raspberry-piとの通信は別途確認)を検討する。Discovery Serverは探索用で、データ経路の問題まで自動解決しない。

**再確認:** 実際のMacとPiで両方向の文字列が一致することを記録する。Linux CIをMacでの成功に置き換えない。
