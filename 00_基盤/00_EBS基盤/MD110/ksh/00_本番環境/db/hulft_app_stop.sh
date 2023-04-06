#!/bin/ksh

################################################################################
# シェル機能:クラスタ用HULFT 停止ShellScript(bebshf00)
# シェル名  :hulft_app_stop.sh
# 戻り値    : 0=確認結果正常
#             0以外=確認結果異常
# 更新履歴  :2008.04.04新規作成
#			 2014.04.16 ハードリプレース対応
# 更新者名  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################

command1="/usr/local/HULFT/bin/hulclustersnd -stop -t -m"     # 配信デーモン終了同期
command2="/usr/local/HULFT/bin/hulclustersnd -stop -f -m"     # 配信デーモン強制終了
command3="/usr/local/HULFT/bin/hulclusterrcv -stop -t -m"     # 集信デーモン終了同期
command4="/usr/local/HULFT/bin/hulclusterrcv -stop -f -m"     # 集信デーモン強制終了
command5="/usr/local/HULFT/bin/hulclusterobs -stop -t -m"     # 要求受付デーモン終了同期
command6="/usr/local/HULFT/bin/hulclusterobs -stop -f -m"     # 要求受付デーモン強制終了
command7=/etc/opt/jp1ajs2/jajs_stop.cluster                   # JP1/AJS2停止コマンド
command8=/etc/opt/jp1ajs2/jajs_killall.cluster                # JP1/AJS2強制停止コマンド
command9=/etc/opt/jp1base/jbs_stop.cluster                    # JP1/Base停止コマンド
command10=/etc/opt/jp1base/jbs_killall.cluster                # JP1/Base強制停止コマンド

# 環境変数設定
HULPATH=/hulft/etc/
HULEXEP=/usr/local/HULFT/bin/
export HULPATH
export HULEXEP
#jp1_clusterhost=pebshf00                        # JP1クラスタホスト名の設定
#jp1_clusterhost=aebshf00                        # JP1クラスタホスト名の設定 (2014.04.16修正)
jp1_clusterhost=bebshf00                        # JP1クラスタホスト名の設定 (2021.12.23修正)

# 配信デーモン終了同期ユーティリティ
$command1
if [ $? -ne 0 ] ; then
  # 配信デーモン強制終了ユーティリティ
  $command2
fi

# 集信デーモン終了同期ユーティリティ
$command3
if [ $? -ne 0 ] ; then
  # 集信デーモン強制終了ユーティリティ
  $command4
fi

# 要求受付デーモン終了同期ユーティリティ
$command5
if [ $? -ne 0 ] ; then
  # 要求受付デーモン強制終了ユーティリティ
  $command6
fi

# JP1/AJS2を停止
$command7 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/AJS2を強制停止
  $command2 $jp1_clusterhost
  goto base_stop
fi

# JP1/Baseを停止
$command9 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/Baseを強制停止
  $command4 $jp1_clusterhost
  goto end
fi

exit 0
