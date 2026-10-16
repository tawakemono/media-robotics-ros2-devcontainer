# メディア・ロボット情報学実験 ROS 2 Humble

実験で配布されるWindows WSL2環境と同じUbuntu 22.04 / ROS 2 Humble / Python 3.10を、DockerとVS Code Dev Containersで利用するための環境です。ホストにROSをインストールする必要はありません。学生のプログラムは `src/` に作成します。

## 対応対象

| ホストOS | CPU | Docker |
|---|---|---|
| Ubuntu 22.04 / 24.04 | amd64 | Docker Engine |
| macOS（Docker Desktopが対応するバージョン） | Apple Silicon arm64 / Intel amd64 | Docker Desktop 4.34以降、Host Networkingを有効化 |

上記は設計上の対象です。Macでの動作・実機通信は未検証です。Linux arm64 CIとMac実機検証を区別した[検証記録](docs/verification.md)を参照してください。

必要なソフトウェアはGit、Docker、VS Code、Dev Containers拡張機能です。GUIはブラウザで開くため、XQuartzやホスト側のX11設定は不要です。

## セットアップと初回起動

最初にOS別手順で必要なソフトウェアを導入してください。

- [Ubuntuのセットアップ](docs/setup-ubuntu.md)
- [macOSのセットアップ](docs/setup-macos.md)

```bash
git clone https://github.com/tawakemono/media-robotics-ros2-devcontainer.git
cd media-robotics-ros2-devcontainer
code .
```

VS Codeのコマンドパレットで **Dev Containers: Reopen in Container** を実行します。初回はイメージのダウンロードとビルドに時間がかかります。完了後、新しいターミナルで次を確認します。

```bash
whoami                 # student
python3 --version      # Python 3.10.x
echo "$ROS_DISTRO"     # humble
ros2 --help
bash scripts/test-local.sh
```

## ROS 2とGUIの確認

コンテナのターミナルを2つ開き、各ターミナルで実行します。

```bash
ros2 run demo_nodes_cpp talker
```

```bash
ros2 run demo_nodes_py listener
```

listenerに `I heard: [Hello World: ...]` が出れば通信成功です。停止は各ターミナルで `Ctrl+C` です。

ホストのブラウザで [noVNC](http://localhost:6080/vnc.html) を開いてConnectを押します。追加のコンテナターミナルでGUIを起動します。

```bash
ros2 run rqt_graph rqt_graph
ros2 run rqt_image_view rqt_image_view
```

rqt_graphで更新ボタンを押し、talker / listener / chatterを確認します。rqt_image_viewは画像トピックが配信されているときに選択して表示します。実機なしで画像を確認する場合は `python3 tests/publish-image.py` を起動し、`/test_image` を選びます。

```bash
bash scripts/test-gui.sh
```

自動GUIテストは仮想ディスプレイとウィンドウ生成を確認します。ブラウザでの表示・操作は各ホスト上で確認してください。GUIサービスは127.0.0.1だけで待ち受けます。同一ホストでは5900・6080番ポートを使うコンテナを同時起動しないでください。

## Raspberry Piとの通信

初期値は `ROS_DOMAIN_ID=0`、`ROS_LOCALHOST_ONLY=1` で、外部ロボットとの通信は無効です。[実機ネットワーク手順](docs/robot-network.md)でチームのドメインへ切り替え、文字列の双方向通信から確認してください。ロボットのドライバはRaspberry Pi側で起動します。

## 問題が起きたとき

[トラブルシューティング](docs/troubleshooting.md)でDocker、ビルド、権限、GUI、DDS通信の問題を確認できます。[検証結果](docs/verification.md)には成功した確認と未検証項目を記録しています。

## 実験指導書との対応

| 演習内容 | この環境で使うもの |
|---|---|
| ROSコマンド・ノード通信 | `ros2`、demo talker / listener |
| ノードとトピックの可視化 | noVNC + rqt_graph |
| 第5〜6章: Pythonパッケージ、Publisher / Subscriber | `src/`、`colcon build`、`tests/fixtures/hello/` の最小例 |
| Launchによる起動 | `hello/launch/hello.launch.py` |
| グループ通信 | `source .devcontainer/scripts/use-robot-network.sh <チームID>` |
| Mouseセンサ・画像・制御 | raspimouse_msgs、rqt_image_view、[現地での実機確認](docs/robot-network.md) |

学生のワークスペースでは `colcon build --symlink-install` 後に `source install/setup.bash` を実行します。次回の新しいターミナルからは作成済みoverlayを自動で読み込みます。テスト用fixtureは自動テストが一時ディレクトリへコピーしてビルドするため、通常の演習ワークスペースには追加されません。
