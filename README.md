# autoInstallLinux
Linuxの自作インストーラーです

## 説明
これはLinuxを自動でインストールできるスクリプトです。

## 対応OS（起動方法）
- Ubuntu (BIOS)

## 準備するもの
- インストールに使用するLinux（インストーラーISOなどでOK）
- インストール先のストレージ

## 使い方
### 1. スクリプトをダウンロード
```bash
wget https://raw.githubusercontent.com/takpika/autoInstallLinux/master/ubuntu/legacy/install.sh
```
### 2. 必要に応じてスクリプト内の設定を変更
OSのバージョンやホスト名（PC名）など必要に応じて設定をテキストエディタを使って変更してください。

設定箇所はスクリプトの上部にあります。
### 3. インストール
```bash
sh install.sh ユーザー名 パスワード
```
ユーザー名とパスワードを入力して実行すると、インストール作業が開始されます。

インストールが終了すると自動で再起動が始まります。
