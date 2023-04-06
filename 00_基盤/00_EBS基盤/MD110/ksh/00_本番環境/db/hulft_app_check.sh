#!/bin/ksh

################################################################################
# シェル機能:クラスタ用HULFT 監視ShellScript(bebshf00)
# シェル名  :hulft_app_check.sh
# 戻り値    : 0=確認結果正常
#             0以外=確認結果異常
# 更新履歴  :2008.04.04新規作成
#			:2009.7.14 キューレス監視追加
#			 2014.04.16 ハードリプレース対応
# 更新者名  :HITACHI.TAMURA（2008.4.4）
#			:HITACHI.MURAOKA（2009.7.14）
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################
HULEXEP=/usr/local/HULFT/bin;export HULEXEP
HULPATH=/hulft/etc;export HULPATH

#jp1_clusterhost=pebshf00							# JP1クラスタホスト名の設定
#jp1_clusterhost=aebshf00							# JP1クラスタホスト名の設定 (2014.04.16修正)
jp1_clusterhost=bebshf00							# JP1クラスタホスト名の設定 (2021.12.23修正)
command1="/opt/jp1base/bin/jbs_spmd_status"			# JP1/Base起動確認コマンド
command1_timeout=5									#コマンドタイムアウト時間（秒）
command1_retry_interval=1							# ステータス取得失敗時のリトライ間隔（秒）
command1_retry_count=2								# ステータス取得失敗時のリトライ回数

command2="/opt/jp1base/bin/jevstat"					# JP1/Baseイベントサービス起動確認コマンド
command2_timeout=5									#コマンドタイムアウト時間（秒）

command3="/opt/jp1ajs2/bin/jajs_spmd_status"		# JP1/AJS2起動確認コマンド
command3_timeout=5									#コマンドタイムアウト時間（秒）
command3_retry_interval=1							# ステータス取得失敗時のリトライ間隔（秒）
command3_retry_count=2								# ステータス取得失敗時のリトライ回数
command3_Queueless="/opt/jp1ajs2/bin/ajsqlstatus"	#JP1キューレスエージェントサービス起動確認コマンド（2009.7.14追加）

command4="/usr/local/HULFT/bin/hulclustersnd -status -m"	# 配信デーモン生存確認
command5="/usr/local/HULFT/bin/hulclusterrcv -status -m"	# 集信デーモン生存確認
command6="/usr/local/HULFT/bin/hulclusterobs -status -m"	# 要求受付デーモン生存確認

# JP1/Baseの起動確認
$command1 -h $jp1_clusterhost
rc=$?
case $rc in
# リターンコードが0の場合イベントサービスの起動確認へ
0)
  ;;
# リターンコードが12の場合イベントサービスの起動確認へ
12)
#  flg1 = 0（2009.7.14修正）
  flg1=0
#  i = 0
  i=0
#  while [ $rc -eq 12 -a $i < $command1_retry_count ] -a [ $flg1 = 0 ]（2009.7.14修正）
  while [ $rc -eq 12 -a $i -lt $command1_retry_count -a $flg1 -eq 0 ]
  do
    sleep $command1_retry_interval
    $command1 -h $jp1_clusterhost -t $command1_timeout
    rc=$?
    case $rc in
    0)
#      flg1 = 1;;（2009.7.14修正）
      flg1=1;;
    12)
      i=$(($i+1));;
    *)
      exit $rc;;
   esac
#  done;;（2009.7.14修正）
   done
# 以下4行（2009.7.14追加）
   if [ $rc -eq 12 -a $flg1 -eq 0 -a $i -eq $command1_retry_count ]
   then
     exit 12
   fi;;
# リターンコードが0,12以外の場合異常終了
*)
  exit $rc;;
esac

# JP1/Base イベントサービスの起動確認
$command2 $jp1_clusterhost -t $command2_timeout
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

# JP1/AJS2サービスの起動確認
$command3 -h $jp1_clusterhost
rc=$?
case $rc in
# リターンコードが0の場合配信デーモン生存確認ユーティリティへ
0)
#  exit 0;;（2009.7.14修正）
  ;;
# リターンコードが12の場合指定回数リトライ
12)
#  flg2 = 0（2009.7.14修正）
  flg2=0
#  i = 0（2009.7.14修正）
  i=0
#  while [ $rc -eq 12 -a $i < $command3_retry_count ] -a [ $flg2 = 0 ]（2009.7.14修正）
  while [ $rc -eq 12 -a $i -lt $command3_retry_count -a $flg2 -eq 0 ]
  do
    sleep $command3_retry_interval
    $command3 -t $command3_timeout
    rc=$?
    case $rc in
    0)
#      flg2 = 1;;（2009.7.14修正）
      flg2=1;;
    12)
      i=$(($i+1));;
    *)
      exit $rc;;
    esac
#  done;;（2009.7.14修正）
  done
# 以下4行（2009.7.14追加）
  if [ $rc -eq 12 -a $flg2 -eq 0 -a $i -eq $command3_retry_count ]
  then
    exit 12
  fi;;
*)
  exit $rc;;
esac

# 配信デーモン生存確認ユーティリティ
$command4
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

# 集信デーモン生存確認ユーティリティ
$command5
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

# 要求受付デーモン生存確認ユーティリティ
$command6
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

###################################################################
# 以下キューレスエージェントサービス起動確認（2009.7.14追加）begin#
###################################################################
# JP1キューレスエージェントサービス起動確認
unset LANG
  flg3=0
$command3_Queueless -h $jp1_clusterhost | grep 'Queueless agent service' | grep ' active'
rc=$?
case $rc in
# リターンコードが0の場合正常終了
0)
  flg3=1
  ;;
# リターンコードが1の場合異常終了
1)
  i=0
  while [ $rc -eq 1 -a $i -lt $command3_retry_count -a $flg3 -eq 0 ]
  do
    sleep $command3_retry_interval
    $command3_Queueless -h $jp1_clusterhost | grep 'Queueless agent service' | grep ' active'
    rc=$?
    case $rc in
    0)
      flg3=1;;
    1)
      i=$(($i+1));;
    *)
      exit $rc;;
    esac
  done;;
*)
  exit $rc;;
esac
if [ $flg3 -eq 0 ];then
exit 1
fi
#################################################################
# 以下キューレスエージェントサービス起動確認（2009.7.14追加）end#
#################################################################

#################################################################
# 以下キューレスマネージャサービス起動確認（2009.7.14追加）begin#
#################################################################

# JP1キューレスマネージャサービス起動確認
#  flg4=0
#$command3_Queueless -h $jp1_clusterhost | grep 'Queueless file transfer service' | grep 'active'
#rc=$?
#case $rc in
# リターンコードが0の場合正常終了
#0)
#  ;;
# リターンコードが1の場合異常終了
#1)
#  i=0
#  while [ $rc -eq 12 -a $i -lt $command3_retry_count -a $flg4 -eq 0 ]
#  do
#    sleep $command3_retry_interval
#    $command3_Queueless -h $jp1_clusterhost | grep 'Queueless file transfer service' | grep 'active'
#    rc=$?
#    case $rc in
#    0)
#      flg4=1;;
#    1)
#      i=$(($i+1));;
#    *)
#      exit $rc;;
#    esac
#  done;;
#*)
#  exit $rc;;
#esac
#if [ flg4 -eq 0 ];then
#exit 1
#fi
###############################################################
# 以下キューレスマネージャサービス起動確認（2009.7.14追加）end#
###############################################################

exit 0

