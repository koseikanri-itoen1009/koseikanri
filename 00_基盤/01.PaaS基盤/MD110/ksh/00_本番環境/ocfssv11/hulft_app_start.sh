#!/bin/ksh

################################################################################
# シェル機能:HULFT 起動ShellScript クラスタ論理ホスト(ocfssvhf00)）
# シェル名  :hulft_app_start.sh
# 戻り値    : 0=確認結果正常
#             0以外=確認結果異常
# 更新履歴  :2008.04.04新規作成
#			 2014.04.16 ハードリプレース対応
# 更新者名  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################
#jp1_clusterhost=aebshf00                        # JP1クラスタホスト名の設定 (2014.04.16修正)
jp1_clusterhost=ocfssvhf00                        # JP1クラスタホスト名の設定 (2021.12.23修正)
command1=/etc/opt/jp1base/jbs_start.cluster     # JP1/Base起動コマンド
command2=/etc/opt/jp1ajs2/jajs_start.cluster    # JP1/AJS2起動コマンド
command3="/usr/local/HULFT/bin/hulclustersnd -start -m"	# 配信デーモン起動(起動同期モード)
command4="/usr/local/HULFT/bin/hulclusterrcv -start -m"	# 集信デーモン起動(起動同期モード)	
command5="/usr/local/HULFT/bin/hulclusterobs -start -m"	# 要求受付デーモン起動(起動同期モード)
#bootipaddr=`lsattr -El en6 -a netaddr | cut -d ' ' -f 2` # bootip

# 環境変数設定
PATH=/usr/local/HULFT/bin:/uspg/jp1/za/shl/prodoicuser:$PATH
HULPATH=/paasif/hulft/etc
HULEXEP=/usr/local/HULFT/bin
export PATH
export HULPATH
export HULEXEP

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

# 配信デーモン起動同期(起動同期モード)ユーティリティ
$command3
if [ $? -ne 0 ] ; then
  exit $?
fi

# 集信デーモン起動同期(起動同期モード)ユーティリティ
$command4
if [ $? -ne 0 ] ; then
  exit $?
fi

# 要求受付デーモン起動同期(起動同期モード)ユーティリティ
$command5
if [ $? -ne 0 ] ; then
  exit $?
fi

exit 0
