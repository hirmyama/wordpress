#!/bin/bash

# ============================================================================
# Tess2用スクリプト　
# hirm@amazon.co.jp
#
# ■特徴
# ・Amazon Linux 2用
# ・WordPressのDB設定・インストール・S3プラグイン導入までスクリプト化済み
# ・日本語の投稿タイトルに対応
# ・PHP 7.2対応
# ・WP CLIを利用
# ・（おまけ）faviconを設置（AWSのサイトと同じもの）
#
# ■使い方
# ・冒頭のRDSエンドポイントのみ変更が必要です
# ・SSH接続してひとかたまりずつ実行してもOK
# ・ユーザーデータにまるごと貼り付けてもOK
# ・WordPressのユーザー名「admin」パスワード「admin」サイト名「AWS」(設定画面から変更可能)
# ・S3バケットを作り、インスタンスにIAMロール（AmazonS3FullAccess）を付け、プラグイン設定
#   （設定＞Offload Media＞Browse existing buckets＞バケットを選択）を行えば、
#    それ以降のメディアアップロードにS3を利用するようになります
#
# ■S3プラグインについて
# ・tantanではなく「WP Offload Media Lite」
# 　（https://wordpress.org/plugins/amazon-s3-and-cloudfront/）を使用
# ============================================================================


# 【要変更】RDSのエンドポイントを設定してください
# 例: dbhost=wordpress2.cicpolo4kgrl.ap-northeast-1.rds.amazonaws.com
db_host=wordpress2.cicpolo4kgrl.ap-northeast-1.rds.amazonaws.com

# 【オプション】RDSのテーブルプレフィックスを変更できます。
# 例: wp_
db_prefix=wp_

# PHP 7.2をインストール
sudo amazon-linux-extras install -y php7.2

# WordPressプラグインの動作に必要なライブラリをインストール
sudo yum install -y php-devel php-gd php-mbstring php-xml

# WordPress CLIをインストール
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# Webサーバー, DBクライアントをインストール
sudo yum -y install httpd mariadb

# ドキュメントルート以下をapache所有に変更
sudo chown apache:apache -R /var/www/html

# Webサーバーを起動
sudo systemctl enable httpd.service
sudo systemctl start httpd.service

# WordPressをダウンロード
sudo -u apache /usr/local/bin/wp core download \
--path=/var/www/html \
--locale=ja

# WordPressのDBをセットアップ
sudo -u apache /usr/local/bin/wp config create \
--path=/var/www/html \
--force \
--dbname=wordpress \
--dbuser=wpuser \
--dbpass=wppassword \
--dbprefix="$db_prefix" \
--dbhost="$db_host"

# ホストのパブリックIPアドレスを取得
host=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# WordPressをインストール
sudo -u apache /usr/local/bin/wp core install \
--path=/var/www/html \
--title=AWS \
--admin_user=admin \
--admin_password=admin \
--admin_email=admin@example.com \
--url=$host \
--skip-email

# 検索エンジンがサイトをインデックスしないようにする
sudo -u apache /usr/local/bin/wp option update \
--path=/var/www/html \
blog_public 0

# パーマリンク形式を変更(日本語タイトルの投稿に対応)
sudo -u apache /usr/local/bin/wp option update \
--path=/var/www/html \
permalink_structure '?p=%post_id%'

# S3プラグインをインストール
sudo -u apache /usr/local/bin/wp plugin install \
--path=/var/www/html \
--activate \
https://downloads.wordpress.org/plugin/amazon-s3-and-cloudfront.2.0.zip

# S3プラグインの設定：IAMロールを使用する
echo "define( 'AS3CF_AWS_USE_EC2_IAM_ROLE', true );" |
sudo -u apache tee -a /var/www/html/wp-config.php

# faviconを設置
sudo -u apache curl -s -L \
-o /var/www/html/favicon.ico \
aws.amazon.com/favicon.ico
