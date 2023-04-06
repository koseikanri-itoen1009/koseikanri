#!/bin/ksh

###############################################################################
##                                                                           ##
##    [概要]                                                                 ##
##       HAモニタ状態確認シェル                                              ##
##                                                                           ##
##    [作成／更新履歴]                                                       ##
##        作成者  ：  日立                   2022/07/05 1.0.0                ##
##                                                                           ##
##    [スクリプトID] :ZAZZ_monchk.ksh                                        ##
##                                                                           ##
##    [戻り値]                                                               ##
##        0     正常終了（全て起動）                                         ##
##        1     異常終了（一部または全て未起動）                             ##
##                                                                           ##
##    [パーミッション] :744                                                  ##
##                                                                           ##
##    [パラメータ] :none                                                     ##
##                                                                           ##
##    [実行ユーザ] :root                                                     ##
##                                                                           ##
##    [実行サーバ] :bebsdb* | bebscon* | bebsfssv*                           ##
##                 :xebsdb* | xebscon*                                       ##
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

# リターンコード: 異常終了
RET_FAIL_ERROR=1

# リターンコード: 正常終了 
RET_SUCCESS=0

CMD_PATH="/opt/hitachi/HAmon/bin"
CMD_MONSHOW="$CMD_PATH/monshow -c"

###############################################################################
## main
###############################################################################
CHK_IDX=0
TMP_LANG=${LANG}
export LANG=C


  

LOCALFQDNNAME=`hostname`
LOCALHOSTNAME=`echo $LOCALFQDNNAME | awk '{ gsub(".itoen.master", "", $1);print($1) }'`

echo ""; echo "### Cluster Information"

if [ ! -d $CMD_PATH ];then
  echo "";echo "*** [$LOCALFQDNNAME]はHAモニタクラスタを構成していません。"
  echo "";exit ${RET_SUCCESS}
fi

echo ""; ${CMD_MONSHOW}
echo ""

for ELEMENT in `${CMD_MONSHOW} | grep $LOCALHOSTNAME`
do 
  if [[ ${ELEMENT} = ${LOCALHOSTNAME} ]]; then
    CHK_IDX=1
  fi 
done

export LANG=${TMP_LANG}

if [[ ${CHK_IDX} = 0 ]]; then
  echo "*** [$LOCALFQDNNAME]はHAモニタクラスタに属していせん。"
  echo "";exit ${RET_FAIL_ERROR}
fi

echo "*** [$LOCALFQDNNAME]はHAモニタクラスタに属しています。"
echo "";exit ${RET_SUCCESS}

###############################################################################
## end of script.
###############################################################################
