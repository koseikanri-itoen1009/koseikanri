#!/bin/ksh


################################################################################
# シェル機能:JP1/Base,JP1/AJS2 停止ShellScript クラスタ論理ホスト(bebsjp00）
# シェル名  :jp1_app_stop.sh
# 戻り値    : 0=確認結果正常
#             0以外=確認結果異常
# 更新履歴  :2008.04.04新規作成
#			 2014.04.16 ハードリプレース対応
# 更新者名  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################

#jp1_clusterhost=pebsjp00			# JP1クラスタホスト名の設定
#jp1_clusterhost=aebsjp00			# JP1クラスタホスト名の設定(2014.04.16修正)
jp1_clusterhost=bebsjp00			# JP1クラスタホスト名の設定(2021.12.23修正)
command1=/etc/opt/jp1ajs2/jajs_stop.cluster	# JP1/AJS2停止コマンド
command2=/etc/opt/jp1ajs2/jajs_killall.cluster	# JP1/AJS2強制停止コマンド
command3=/etc/opt/jp1base/jbs_stop.cluster	# JP1/Base停止コマンド
command4=/etc/opt/jp1base/jbs_killall.cluster	# JP1/Base強制停止コマンド

# JP1/AJS2を停止
$command1 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/AJS2を強制停止
  $command2 $jp1_clusterhost
  goto base_stop
fi

# JP1/Baseを停止
$command3 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/Baseを強制停止
  $command4 $jp1_clusterhost
  goto end
fi

exit 0

