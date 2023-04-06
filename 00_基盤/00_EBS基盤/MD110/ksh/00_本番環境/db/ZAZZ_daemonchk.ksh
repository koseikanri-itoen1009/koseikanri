#!/bin/ksh

###############################################################################
##                                                                           ##
##    [概要]                                                                 ##
##       デーモン起動状態確認シェル                                          ##
##                                                                           ##
##    [作成／更新履歴]                                                       ##
##        作成者  ：  日立                   2022/07/08 1.0.0                ##
##                                                                           ##
##    [スクリプトID] :ZAZZ_daemonchk.ksh                                     ##
##                                                                           ##
##    [戻り値]                                                               ##
##        0     正常終了（全て起動）                                         ##
##        1     異常終了（一部または全て未起動）                             ##
##      254     定義ファイル無し                                             ##
##      255     引数不正                                                     ##
##                                                                           ##
##    [パーミッション] :755                                                  ##
##                                                                           ##
##    [パラメータ] :arg1  定義ファイル                                       ##
##                                                                           ##
##    [実行ユーザ] :root                                                     ##
##                                                                           ##
##    [実行サーバ] :pebs* | pjob*                                            ##
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
##     Copyright  株式会社伊藤園 Iaasプロジェクト 2020-2021                  ##
###############################################################################



# リターンコード: 引数不正
RET_FAIL_INVALID_ARGUMENTS=255

# リターンコード: ファイル無し
RET_FAIL_FILE_NOT_EXIST=254

# リターンコード: 異常終了
RET_FAIL_ERROR=1

# リターンコード: 正常終了 
RET_SUCCESS=0


EXIT_CODE=${RET_SUCCESS}
RET=0

DAEMONNAME=""


###############################################################################
## main
###############################################################################
if [ $# -ne 1 ]; then
  echo invalid arguments.
  exit ${RET_FAIL_INVALID_ARGUMENTS}
fi

if [ ! -f $1 ]; then
  echo file not exist. $1
  exit ${RET_FAIL_FILE_NOT_EXIST}
fi



while read DAEMONNAME
do
  if [ ! -z ${DAEMONNAME} ] ; then

    RET=`ps -ef | grep ${DAEMONNAME} | grep -v grep | wc -l`
    if [ ${RET} -gt 0 ]; then
      echo "稼動中:[$DAEMONNAME]"
    else
      echo "停止中:[$DAEMONNAME]"
      EXIT_CODE=${RET_FAIL_ERROR}
    fi

  fi
done < $1


if [ ${EXIT_CODE} -eq ${RET_SUCCESS} ]; then
  echo "デーモンは全て稼働しています"
else
  echo "デーモンは一部または全て停止しています"
fi

exit ${EXIT_CODE}

###############################################################################
## end of script.
###############################################################################

