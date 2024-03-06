#!/bin/ksh

###############################################################################
##                                                                           ##
##    [概要]                                                                 ##
##       時刻同期状態確認シェル                                              ##
##                                                                           ##
##    [作成／更新履歴]                                                       ##
##        作成者  ：  日立 横内              2009/09/24 1.0.0                ##
##                ：  RHEL用に変更           2022/06/29 2.0.0                ##
##                ：  RHELv8用に変更         2023/06/06 3.0.0                ##
##                                                                           ##
##    [スクリプトID] :ZAZZ_ntpchk.ksh                                        ##
##                                                                           ##
##    [戻り値]                                                               ##
##        0     正常終了（同期処理正常状態）                                 ##
##        1     異常終了（同期処理異常状態）                                 ##
##                                                                           ##
##    [パーミッション] :744                                                  ##
##                                                                           ##
##    [パラメータ] :none                                                     ##
##                                                                           ##
##    [実行ユーザ] :root                                                     ##
##                                                                           ##
##    [実行サーバ] :pebs* | pjob* | pextap*                                  ##
##                                                                           ##
##    [参照ファイル] :none                                                   ##
##                                                                           ##
##    [入力ファイル] :none                                                   ##
##                                                                           ##
##    [サブルーチン] :none                                                   ##
##                                                                           ##
##    [出力ファイル] :none                                                   ##
##                                                                           ##
##    [備考欄]                                                               ##
##                                                                           ##
##     Copyright  株式会社伊藤園 U5000プロジェクト 2007-2009                 ##
###############################################################################


# リターンコード: 異常終了
RET_FAIL_ERROR=1

# リターンコード: 正常終了 
RET_SUCCESS=0

# chronyc tracking のステータス値
NORMAL_ST="Normal"
ERR_ST=" Not synchronized"

### Comment v3.0.0
#CHK_STATUS=`ntpq -p | egrep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed "s/ \{2,\}/ /g"`
#VALUE_WHEN=`echo ${CHK_STATUS} | cut -f 5 -d ' '`
#VALUE_POLL=`echo ${CHK_STATUS} | cut -f 6 -d ' '`

CHK_STATUS=`chronyc tracking | grep "Leap status" | cut -f 2 -d ":"`
LEAP_ST=`echo $CHK_STATUS | cut -f 1 -d " "`

# 画面表示用
### Comment v3.0.0
#ntpq -p
chronyc tracking
echo

### Comment v3.0.0
#if [ ${VALUE_WHEN} -gt ${VALUE_POLL} ]; then

if [ $LEAP_ST != $NORMAL_ST ]; then
  echo "*** 時刻同期状態は異常です"
  echo
  exit ${RET_FAIL_ERROR}
fi

echo "*** 時刻同期状態は正常です"
echo
exit ${RET_SUCCESS}
