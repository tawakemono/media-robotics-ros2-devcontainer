# Raspberry Pi Mouseとの通信

この手順は現地での検証用です。現在はRaspberry Pi・Macとの双方向通信を検証していません。自動テストはロボットを操作しません。

## 前提とチーム設定

実験指導書のRaspberry Pi 4 / Ubuntu 22.04 / ROS 2 Humble / Raspberry Pi Mouse V3を使用し、PCとPiを通信が許可された同一ネットワークへ接続します。ドライバ・モータ制御ノードはPi側の既存環境で起動します。Piの設定やソフトウェアを無断で変更しないでください。

チームに割り当てられた `ROS_DOMAIN_ID` を確認します。この環境ではLinuxのDDSポート競合を避けやすい0〜101に制限しています。以下の `1` は例で、実際のチームIDへ置き換えます。

PCの各コンテナターミナルで実行します。

```bash
source .devcontainer/scripts/use-robot-network.sh 1
```

切替前・切替後のROS daemonを停止し、`ROS_DOMAIN_ID=1`、`ROS_LOCALHOST_ONLY=0` に設定します。既に起動しているノードの環境は変わらないため、ノードを停止して同じターミナルから起動し直します。

Pi側では既存のセットアップを読み込み、チームの運用手順に従って確認します。

```bash
printenv ROS_DISTRO ROS_DOMAIN_ID ROS_LOCALHOST_ONLY RMW_IMPLEMENTATION
```

PCは `rmw_fastrtps_cpp` を使用します。Pi側で未設定なら既定RMWを確認し、異なるRMWの場合は互換性を実測してください。ドメインと外部通信設定を合わせる場合は、運用上の許可を得たターミナルだけで次を実行します。

```bash
export ROS_DOMAIN_ID=1
export ROS_LOCALHOST_ONLY=0
ros2 daemon stop
```

ローカル演習へ戻す場合は、各ターミナルで次を実行します。

```bash
ros2 daemon stop
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=1
ros2 daemon stop
```

## 双方向の文字列通信

まずPi側で送信します。

```bash
ros2 topic pub -r 1 /test_topic std_msgs/msg/String '{data: hello_pi}'
```

PC側で受信します。30秒以内に `hello_pi` が表示されることを確認します。

```bash
timeout 30 ros2 topic echo /test_topic std_msgs/msg/String --once
```

送信側を `Ctrl+C` で停止してから、PC側で送信します。

```bash
ros2 topic pub -r 1 /test_topic std_msgs/msg/String '{data: hello_pc}'
```

Pi側で受信します。

```bash
timeout 30 ros2 topic echo /test_topic std_msgs/msg/String --once
```

`hello_pc` が表示されることを確認し、PC側の送信も停止します。両方向で内容が一致した場合だけPASSです。ノード・トピックの列挙だけ、片方向だけの受信は合格ではありません。

## センサ・画像・制御

Pi側で既存のraspimouseノードを起動した状態で確認します。

```bash
ros2 node list
ros2 node info /raspimouse
ros2 interface show raspimouse_msgs/msg/LightSensors
timeout 30 ros2 topic echo /light_sensors
ros2 topic list -t
ros2 topic info /joy --verbose
ros2 topic info /cmd_vel --verbose
```

実際のノード名・トピック名が異なる場合は列挙結果に従います。LightSensorsの値が対象物や明るさに応じて変化することを確認します。`/joy` が配信されていれば `timeout 30 ros2 topic echo /joy` で値の変化も確認します。`/cmd_vel` は実際の型を記録し、演習ノードが使う型と一致させます。

カメラ画像のトピック名と型を確認し、`ros2 run rqt_image_view rqt_image_view` を起動してnoVNC上で選択します。画像データが届き、更新されることを確認してください。

モータ制御は、指導者の許可、安全な設置、他PCからの操作停止、緊急停止手段の確認を終えてから現地で行います。このリポジトリにはモータを自動駆動する試験は含めません。PC側へGPIOやモータデバイスをマウントする必要はありません。

## 通信できないときの切り分け

次の順番で確認します。ファイアウォールを無条件で無効化しないでください。

1. PCとPiが同一の通信可能ネットワークか。ゲストWi-FiやAP isolationがないか。
2. ホストから実際のPiのIPへ `ping -c 3 <PiのIP>` が通るか。ICMPが禁止されている場合は管理者に許可された通信方法を確認する。
3. 両側の `printenv ROS_DOMAIN_ID ROS_LOCALHOST_ONLY RMW_IMPLEMENTATION` が想定どおりか。
4. 設定後にdaemonと対象ノードを再起動したか。
5. MacではDesktop 4.34以降でHost Networkingが有効か。
6. VPN・ファイアウォール・Wi-Fi機器でDDSのUDP / マルチキャストが妨げられていないか。
7. `ros2 multicast receive` と対向側の `ros2 multicast send` で探索経路を確認できるか。逆方向も試す。
8. 探索できてもデータ用UDPが双方向に届くか。必要なら管理者と許可範囲・パケット記録を確認する。

Discovery Serverによるユニキャスト探索は候補ですが、アドレス到達性やデータUDPの問題を自動解決するものではありません。未検証の固定設定は配布しません。Macで成立しない場合は[Remote-SSH / Linux VMの候補](setup-macos.md#raspberry-piとの通信は別途確認)を検討し、実際に成功した構成を[検証記録](verification.md)へ残します。
