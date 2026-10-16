# macOSのセットアップ

Apple Siliconはarm64、Intel Macはamd64をネイティブに使用します。Mac実機の検証はまだ実施していません。以下は構築手順と確認方法で、実機通信の保証ではありません。[検証記録](verification.md)も参照してください。

## OS・Docker Desktop

```bash
sw_vers
uname -m
```

Apple Siliconの期待値は `arm64`、Intelは `x86_64` です。Rosettaで起動したターミナルはCPU判定が異なる場合があるため、通常のネイティブターミナルを使います。

[Docker Desktop公式](https://docs.docker.com/desktop/setup/install/mac-install/)でmacOSの対応バージョンを確認し、CPUに合うインストーラを導入します。アプリを起動して初期設定を完了させます。

Docker Desktop **4.34以降** が必要です。メニューのAboutでアプリのバージョンを確認します。`docker version` のEngineバージョンとは異なります。

[公式Host Networking手順](https://docs.docker.com/engine/network/drivers/host/#docker-desktop)に従い、Dockerアカウントへのサインイン後、**Settings → Resources → Network → Enable host networking → Apply and restart** を実行します。設定が見つからない場合はDesktopのバージョンと設定を確認します。Enhanced Container Isolationとの併用はできません。組織管理の設定は管理者に確認してください。

```bash
docker version
docker run --rm hello-world
```

Client / Server両方の表示と `Hello from Docker!` を確認します。

## VS Code・Git・コンテナ起動

[VS Code公式](https://code.visualstudio.com/download)からMac版をインストールします。コマンドパレットから **Shell Command: Install 'code' command in PATH** を実行します。

```bash
git --version
code --version
code --install-extension ms-vscode-remote.remote-containers
code --list-extensions
```

Gitがなければ `xcode-select --install` でCommand Line Toolsを導入してから再確認します。VS Codeのバージョンと `ms-vscode-remote.remote-containers` の表示を確認します。

```bash
git clone https://github.com/tawakemono/media-robotics-ros2-devcontainer.git
cd media-robotics-ros2-devcontainer
code .
```

`Cmd+Shift+P` → **Dev Containers: Reopen in Container** を実行します。初回はネイティブCPU用イメージがビルドされます。`--platform=linux/amd64` を追加したり `DOCKER_DEFAULT_PLATFORM=linux/amd64` を設定したりしないでください。

新しいコンテナターミナルで実行します。

```bash
uname -m
whoami
python3 --version
echo "$ROS_DISTRO"
ros2 --help
bash scripts/test-local.sh
bash scripts/test-gui.sh
```

期待値はApple Siliconで `aarch64`、Intelで `x86_64`、ユーザー `student`、Python 3.10、ROS `humble`、両テストのPASSです。test-localはPythonパッケージを一時ワークスペースでビルドし、Publisher / Subscriber / Launchを確認します。

## ブラウザでの確認とプログラム作成

ホストのブラウザで <http://localhost:6080/vnc.html> を開いてConnectを押します。コンテナの別々のターミナルで起動します。

```bash
ros2 run demo_nodes_cpp talker
```

```bash
ros2 run demo_nodes_py listener
```

```bash
ros2 run rqt_graph rqt_graph
```

受信ログと、GUI上で更新して表示されるノード・トピックを確認します。`python3 tests/publish-image.py` と `ros2 run rqt_image_view rqt_image_view` もそれぞれ起動して `/test_image` の緑色画像を表示し、ブラウザで操作できることを確認します。

演習用コードは `src/` に作成します。ビルド・実行はコンテナ内で行います。

```bash
colcon build --symlink-install
source install/setup.bash
```

Pythonパッケージの最小例は `tests/fixtures/hello/` を参照してください。停止・再起動・Rebuildと共有ファイルの確認は[Ubuntu手順の終了・再起動](setup-ubuntu.md#終了再起動再ビルド)と同様です。

## Raspberry Piとの通信は別途確認

Host Networkingを有効にしてもDDSの探索とデータ通信が成立するとは限りません。まず[実機ネットワーク手順](robot-network.md)でPi→Mac、Mac→Piの文字列が一致することを確認します。Linux arm64 CIのPASSをこの確認の代わりにしないでください。

失敗した場合は、同一ネットワーク・ドメイン・RMW・VPN・UDP到達性を順に確認します。Discovery Serverで探索が改善してもデータ到達性は別途検証が必要です。

未検証の代替候補は次のとおりです。

- **Remote-SSH**: 別途、Piと通信可能なUbuntuホストが必要です。そのホストにDocker Engineと本リポジトリを用意し、MacのVS CodeのRemote-SSHから接続してDev Containerを開きます。ノードはUbuntu上で動きます。
- **Linux VM**: Mac上のUbuntu VMでDockerを実行し、Piへ双方向通信できるネットワークを用意します。ブリッジ接続可否は仮想化ソフトとネットワーク機器ごとに実測します。

どちらも現時点で本リポジトリの実機検証済み構成ではありません。成功した構成だけを検証記録へ追加してください。
