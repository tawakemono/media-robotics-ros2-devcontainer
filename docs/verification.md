# 検証記録

PASSは実測した成功、FAILは実測した失敗、NOT TESTEDは未実施です。イメージビルド、コンテナ自動テスト、VS Code接続、ブラウザ操作、ロボット通信を別々に判定します。

## 現在の検証対象

検証日時: 2026-10-16（JST）

ホストOS: Ubuntu 24.04.4 LTS

CPUアーキテクチャ: amd64 / x86_64

Dockerバージョン: Docker Engine Community 29.8.0

VS Codeバージョン: 1.141.0、Dev Containers 0.469.0

コンテナOS: Ubuntu 22.04.5 LTS、Python 3.10.12

ROS 2: Humble、rmw_fastrtps_cpp

検証項目・実行結果: 下表

問題点: x11vncが `-no6` だけではIPv6 wildcardでも待ち受けた。Fluxboxの壁紙設定が未導入アプリを要求した。Dev Containers CLIの初回ベースイメージ確認が待機した。

対応内容: `-noipv6 -rfbportv6 -1` も指定し、ssでloopback限定を検証。Fluxboxの背景設定を無効化。ホストで `docker pull ros:humble-ros-base-jammy` 後にCLI起動が成功。

最終判定: PASS（Ubuntuコンテナの自動検証範囲。エディタ画面の手動操作・Mac・Piは含まない）

| 検証項目 | 結果 | 証拠・補足 |
|---|---|---|
| Ubuntu amd64 Dockerビルド | PASS | `docker build -t media-robotics-ros2:local -f .devcontainer/Dockerfile .` |
| OS / Python / ROS / メッセージ型 | PASS | `scripts/test-local.sh`、rclpy / QtWidgets / QtSvgもimport成功 |
| talker / listener | PASS | 30秒以内にC++→Pythonの本文を受信 |
| fixtureビルド / ros2 run / Launch | PASS | 一時ワークスペースでビルド・本文の受信。終了後にテストノードなし |
| Xvfb / HTTP / loopback bind / Qtウィンドウ | PASS | `scripts/test-gui.sh`、graphとimage_viewの両方 |
| GUIスクリプト再実行 | PASS | PIDが変わらないことを確認 |
| GUIポート競合 / 失敗後の復旧 | PASS | 別プロセスで6080を使用すると非ゼロ終了と原因ログを出力。競合解消後に再起動成功 |
| ビルド失敗時の後始末 | PASS | colconを終了コード42のモックへ置換し、失敗として終了。talker/listenerが残らないことをpsで確認 |
| Ubuntu Dev Containers CLI起動 / 接続 | PASS | VS Code拡張同梱CLI 0.89.0のup / exec、student UID/GID 1000 |
| 異なるホストUIDからの自動調整 | NOT TESTED | このホストとイメージのUIDは共に1000。設定は有効 |
| VS Codeエディタ画面での手動操作 | NOT TESTED | CLI起動と区別する |
| Ubuntuブラウザの接続 / グラフ / 画像 | PASS | ホストのChromeをPlaywrightで接続し、WebSocket接続・描画をスクリーンショットで確認 |
| 人によるブラウザでの手動操作 | NOT TESTED | 自動ブラウザ検証と区別する |
| コンテナ再起動 / Rebuild | PASS | restart→CLI up→GUIテスト成功。CLI up --remove-existing-container後に両テスト成功 |
| ホスト共有 / 一般ユーザー編集 | PASS | コンテナで生成→ホストで追記→studentで読込・削除。`colcon list` がfixtureを検出しないことも確認 |
| GitHub Actions linux/amd64 | NOT TESTED | Push後に確認 |
| GitHub Actions linux/arm64 | NOT TESTED | Linux上での検証 |
| Mac Apple Silicon | NOT TESTED | 実機を使用しない |
| Mac Intel | NOT TESTED | 実機を使用しない |
| Pi → Dev Container | NOT TESTED | 実機を使用しない |
| Dev Container → Pi | NOT TESTED | 実機を使用しない |
| LightSensors / joy / cmd_vel型 / カメラ | NOT TESTED | 実機を使用しない |
| 現地のモータ制御 | NOT TESTED | 指導者許可のもとで手動実施 |

ユーザー指定により今回の検証は現在のUbuntuとGitHub Actionsに限定します。Mac・Piの実機検証、Remote-SSH・VMによる代替通信は未実施です。これらをサポート確認済みと表記しません。

追加の静的確認: ShellCheck、actionlint、Bash構文、Pythonコンパイル、日本語ドキュメントのローカルリンクがPASS。実機通信切替スクリプトはros2をモックして0 / 1 / 99 / 100 / 101、不正値・範囲外・先頭ゼロ、daemon停止順序を確認したため、実機通信PASSとは扱いません。

初回CIのarm64ではイメージビルド・test-local・test-guiが成功した後、ログのartifactアップロードがFAILになりました。コンテナのstudentとGitHub runnerのUID差により、mktemp由来の0700ディレクトリをrunnerから読めなかったためです。CIのログ収集段階でジョブ専用の `/tmp/ros2-ci-logs` の所有権をrunnerへ移す修正を行い、再実行します。テスト成功とCI全体の成功は分けて判定します。

## 追加検証の記録テンプレート

以下をコピーし、実際に使った機器ごとに追記してください。

```text
検証日時:
ホストOS:
CPUアーキテクチャ:
Dockerバージョン:
VS Codeバージョン:
コンテナOS:
ROS 2:
検証項目:
実行結果: PASS / FAIL / NOT TESTED
問題点:
対応内容:
最終判定: PASS / FAIL / NOT TESTED
```

MacはGUI表示・操作、再起動・Rebuild、ファイル共有、Python実行を確認してください。Pi通信はネットワーク構成・RMW・ドメイン、両方向の文字列、センサ値の変化、画像の更新を記録します。接続先の秘密情報やパスワードは記載しません。
