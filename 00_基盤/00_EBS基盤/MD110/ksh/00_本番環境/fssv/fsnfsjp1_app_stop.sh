#!/bin/ksh

################################################################################
# シェル機能:クラスタ用NFS 停止ShellScript(bebsfssv00)
# シェル名  :fsnfsjp1_app_stop.sh
# 戻り値    : 0=確認結果正常
#             0以外=確認結果異常
# 更新履歴  :2008.04.04新規作成
#			 2014.04.16 ハードリプレース対応
#			 2022.02.21 システムリフト対応
# 更新者名  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
#			 HITACHI.YONENO(2022.02.21)
################################################################################

command1="/sbin/service nfslock stop"                    # nfslock停止コマンド
command2="/sbin/service nfs stop"                        # NFSサーバ停止コマンド
command3="/sbin/service rpcidmapd stop"                  # rpcidmapd停止コマンド
command4="/sbin/service portmap stop"                    # portmap停止コマンド
command5=/etc/opt/jp1ajs2/jajs_stop.cluster              # JP1/AJS2停止コマンド
command6=/etc/opt/jp1ajs2/jajs_killall.cluster           # JP1/AJS2強制停止コマンド
command7=/etc/opt/jp1base/jbs_stop.cluster               # JP1/Base停止コマンド
command8=/etc/opt/jp1base/jbs_killall.cluster            # JP1/Base強制停止コマンド

# 環境変数設定
#HULPATH=/hulft/etc/
#HULEXEP=/usr/local/HULFT/bin/
#export HULPATH
#export HULEXEP
#jp1_clusterhost=pebshf00                        # JP1クラスタホスト名の設定
#jp1_clusterhost=aebshf00                        # JP1クラスタホスト名の設定 (2014.04.16修正)
jp1_clusterhost=bebsfssv00                        # JP1クラスタホスト名の設定 (2022.02.21修正)

# nfslock停止
$command1
if [ $? -ne 0 ] ; then
  exit $?
fi

# NFSサーバ停止
$command2
if [ $? -ne 0 ] ; then
  exit $?
fi

# rpcidmapd停止
$command3
if [ $? -ne 0 ] ; then
  exit $?
fi

# portmap停止
$command4
if [ $? -ne 0 ] ; then
  exit $?
fi

# JP1/AJS2を停止
$command5 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/AJS2を強制停止
  $command6 $jp1_clusterhost
  goto base_stop
fi

# JP1/Baseを停止
$command6 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/Baseを強制停止
  $command8 $jp1_clusterhost
  goto end
fi

exit 0
