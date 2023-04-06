#!/bin/ksh

################################################################################
# シェル機能:NFS 起動ShellScript クラスタ論理ホスト(bebsfssv00)）
# シェル名  :fsnfsjp1_app_start.sh
# 戻り値    : 0=確認結果正常
#             0以外=確認結果異常
# 更新履歴  :2008.04.04新規作成
#			 2014.04.16 ハードリプレース対応
#			 2022.02.21 システムリフト対応
# 更新者名  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
#			 HITACHI.YONENO(2022.02.21)
################################################################################
#jp1_clusterhost=aebshf00                        # JP1クラスタホスト名の設定 (2014.04.16修正)
jp1_clusterhost=bebsfssv00                       # JP1クラスタホスト名の設定 (2022.2.21修正)
command1=/etc/opt/jp1base/jbs_start.cluster     # JP1/Base起動コマンド
command2=/etc/opt/jp1ajs2/jajs_start.cluster    # JP1/AJS2起動コマンド
command3="/sbin/service portmap start"	        # portmap起動コマンド
command4="/sbin/service rpcidmapd start"	    # rpcidmapd起動コマンド
command5="/sbin/service nfs start"	            # NFSサーバ起動コマンド
command6="/sbin/service nfslock start"	        # nfslock起動コマンド
#bootipaddr=`lsattr -El en6 -a netaddr | cut -d ' ' -f 2` # bootip

# 環境変数設定
#PATH=/usr/local/HULFT/bin:/uspg/jp1/za/shl/XEBSITO:$PATH
#HULPATH=/hulft/etc
#HULEXEP=/usr/local/HULFT/bin
#export PATH
#export HULPATH
#export HULEXEP

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

# portmap起動
$command3
if [ $? -ne 0 ] ; then
  exit $?
fi

# rpcidmapd起動
$command4
if [ $? -ne 0 ] ; then
  exit $?
fi

# NFSサーバ起動
$command5
if [ $? -ne 0 ] ; then
  exit $?
fi

# nfslock起動
$command6
if [ $? -ne 0 ] ; then
  exit $?
fi

exit 0
