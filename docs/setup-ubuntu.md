# Ubuntuのセットアップ

対象はUbuntu 22.04 / 24.04のamd64ホストです。以下は新規環境用です。既存のDockerがある場合はまず `docker version` を確認し、正常ならインストールを省略します。競合パッケージがある場合は[Docker公式手順](https://docs.docker.com/engine/install/ubuntu/)を確認して整理してください。

## OS・Docker Engine

```bash
cat /etc/os-release
uname -m
```

期待値はUbuntu 22.04または24.04、`x86_64` です。

公式APTリポジトリから導入します。

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
systemctl is-active docker
sudo docker run --rm hello-world
```

`active` と `Hello from Docker!` を確認します。

VS CodeからDockerを操作するため、所属グループを設定します。**dockerグループはroot相当の強いホスト権限を持ちます。** 管理者の運用方針に従って設定してください。

```bash
sudo usermod -aG docker "$USER"
```

一度ログアウト・ログインしてから新しいターミナルで確認します。

```bash
id -nG
docker version
docker run --rm hello-world
```

`docker` グループ、Client / Serverの両方、成功メッセージが表示されれば準備完了です。

## VS CodeとDev Containers

[VS Code公式ダウンロード](https://code.visualstudio.com/download)からLinux `.deb` を取得し、ダウンロードした実際のファイル名でインストールします。デスクトップ版Ubuntuでsnapが利用できる場合は次の方法も使えます。

```bash
sudo snap install code --classic
code --version
code --install-extension ms-vscode-remote.remote-containers
code --list-extensions
```

バージョン番号と `ms-vscode-remote.remote-containers` が表示されることを確認します。

```bash
git clone https://github.com/tawakemono/media-robotics-ros2-devcontainer.git
cd media-robotics-ros2-devcontainer
code .
```

コマンドパレット（`Ctrl+Shift+P`）から **Dev Containers: Reopen in Container** を選びます。初回ビルド終了後、左下にコンテナ名が表示されることを確認し、新しいコンテナターミナルで実行します。

```bash
whoami
pwd
cat /etc/os-release
python3 --version
echo "$ROS_DISTRO"
ros2 --help
bash scripts/test-local.sh
bash scripts/test-gui.sh
```

期待値は `student`、`/home/student/ros2_ws`、Ubuntu 22.04、Python 3.10、`humble`、各テストの `PASS` です。

## ブラウザ・演習・共有ファイル

ホストのブラウザで <http://localhost:6080/vnc.html> を開きConnectを押します。コンテナターミナルを3つ使い、次をそれぞれ起動します。

```bash
ros2 run demo_nodes_cpp talker
```

```bash
ros2 run demo_nodes_py listener
```

```bash
ros2 run rqt_graph rqt_graph
```

listenerの受信ログと、rqt_graphの更新ボタンで表示されるtalker / listener / chatterを確認します。画像確認は別ターミナルで `python3 tests/publish-image.py` を起動してから `ros2 run rqt_image_view rqt_image_view` を起動し、`/test_image` を選び、緑色の画像を確認します。

Pythonパッケージの練習例は次のとおりです。

```bash
cd /home/student/ros2_ws
ros2 pkg create --build-type ament_python --dependencies rclpy std_msgs -- my_experiment
mv my_experiment src/
colcon build --symlink-install
source install/setup.bash
```

ノード本体と `setup.py` のconsole_scriptsを作成してから `ros2 run my_experiment <実行名>` で起動します。完成した最小例は `tests/fixtures/hello/` を参照してください。

コンテナで `touch src/share-check.txt` を実行し、ホストのリポジトリから同じファイルを編集できることを確認します。確認後 `rm src/share-check.txt` で削除します。UID/GIDはDev Containersがホストユーザーに合わせます。

## 終了・再起動・再ビルド

ノードは `Ctrl+C` で終了します。VS Codeの **Dev Containers: Reopen Folder Locally** でホストに戻り、**Dev Containers: Stop Container** が利用できる場合は実行します。CLIでは次で対象のコンテナIDを確認して停止できます。

```bash
docker ps --filter label=devcontainer.local_folder="$PWD"
```

確認したIDに対して `docker stop <コンテナID>` を実行します。次回は **Reopen in Container** を選びます。設定更新後は **Dev Containers: Rebuild Container** を使い、上記テストとブラウザ表示を再確認します。学生のソースはbind mountでホスト側に残ります。
