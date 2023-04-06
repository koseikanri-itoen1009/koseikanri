#!/bin/ksh

################################################################################
# シェル機能:JP1/Base,JP1/AJS2 起動ShellScript クラスタ論理ホスト(bebsjp00）
# シェル名  :jp1_app_start.sh
# 戻り値    : 0=確認結果正常
#             0以外=確認結果異常
# 更新履歴  :2008.04.04新規作成
#			 2014.04.16 ハードリプレース対応
# 更新者名  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################
#jp1_clusterhost=pebsjp00			# JP1クラスタホスト名の設定
#jp1_clusterhost=aebsjp00			# JP1クラスタホスト名の設定 (2014.04.16修正)
jp1_clusterhost=bebsjp00			# JP1クラスタホスト名の設定 (2021.12.23修正)
command1=/etc/opt/jp1base/jbs_start.cluster	# JP1/Base起動コマンド
command2=/etc/opt/jp1ajs2/jajs_start.cluster	# JP1/AJS2起動コマンド
#bootipaddr=`lsattr -El en6 -a netaddr | cut -d ' ' -f 2` # bootip

#ifconfig en6 alias ${bootipaddr} netmask 255.255.255.0 firstalias

# JP1/Baseを起動
$command1 $jp1_clusterhost
if [ $? -ne 0 ] ; then
  exit $?
fi

# JP1/AJS2を起動
$command2 $jp1_clusterhost
if [ $? -ne 0 ] ; then
  exit $?
fi

exit 0
