# Tess2ラボ6（バックアップ、別リージョンでのリカバリ）:
#
# シンガポールでAMIから立ち上げた直後のEC2上のWordPressは下記の状態で稼働している
#
# ・HTMLはシンガポールのEC2
# ・JSやCSSなどのアセットは東京のELB
# ・画像は東京のS3バケットから持ってきている
#
# したがって、完全にシンガポールリージョンだけで稼働させるにはさらに下記の処理が必要
# 
# ・RDS内部に記録された「サイトURL」「ホーム」をシンガポールのEC2のURLに更新
# ・シンガポールにS3バケットを作り、東京のS3バケットの中身を全部コピーし、公開状態にする
# ・S3プラグインが使用するバケットをシンガポールのバケットに変更

# 東京リージョンのリージョン名、バケット名
source_region=ap-northeast-1
source_bucket=wp-xxxxxxxxxxx

# シンガポールリージョンのリージョン名、バケット名
target_region=ap-southeast-1
target_bucket=wp-yyyyyyyyyyy

# シンガポールリージョンのEC2インスタンスのURL(「http://ipアドレス」の形式であること！）
target_ec2_url=http://18.136.101.106

# シンガポールにバケットを作成
aws s3 mb s3://$target_bucket --region $target_region

# 東京のバケットの内容をすべてシンガポールのバケットにコピー
aws s3 cp --recursive s3://$source_bucket s3://$target_bucket

# バケット内のオブジェクトをすべて公開
aws s3 ls --recursive s3://$target_bucket/ \
 | awk '{print $4}' \
 | xargs -I{} aws s3api put-object-acl --acl public-read --bucket $target_bucket --key "{}"

# DB内のリージョン名を書き換え
sudo -u apache /usr/local/bin/wp search-replace \
--path=/var/www/html \
"$source_region" "$target_region"

# DB内のバケット名を書き換え
sudo -u apache /usr/local/bin/wp search-replace \
--path=/var/www/html \
"$source_bucket" "$target_bucket"

# サイトURLを書き換え
sudo -u apache /usr/local/bin/wp option set \
--path=/var/www/html \
siteurl $target_ec2_url

# ホームURLを書き換え
sudo -u apache /usr/local/bin/wp option set \
--path=/var/www/html \
home $target_ec2_url

# TODO: プラグインの画面で、アップロード先のS3バケットを
# シンガポールのバケットに変更する。
