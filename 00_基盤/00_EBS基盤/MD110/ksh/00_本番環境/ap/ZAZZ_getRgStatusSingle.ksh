#!/bin/ksh

###############################################################################
##                                                                           ##
##    [概要]                                                                 ##
##       HAモニタ状態確認シェル                                              ##
##                                                                           ##
##    [作成／更新履歴]                                                       ##
##        作成者  ：  日立                   2022/07/05 1.0.0                ##
##                                                                           ##
##    [スクリプトID] :ZAZZ_getRgStatusSingle.ksh                             ##
##                                                                           ##
##    [戻り値]                                                               ##
##        0     正常終了（全て起動）                                         ##
##        1     異常終了（一部または全て未起動）                             ##
##                                                                           ##
##    [パーミッション] :744                                                  ##
##                                                                           ##
##    [パラメータ] :arg1 [ONL|SBY]                                           ##
##                 :arg2 [リソースグループ名]                                ##
##                 :arg3 [ホスト名]                                          ##
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

# リターンコード: 正常終了 
RET_SUCCESS=0

# リターンコード: 状態NG
RET_FAIL_INVALID_STATUS=252

# リターンコード: コマンド無し
RET_FAIL_NO_EXIST_COMMAND=254

# リターンコード: リソース不正
RET_FAIL_INVALID_RESOCE=253

# リターンコード: 引数不正
RET_FAIL_INVALID_ARGUMENTS=255

## 標準出力用日時定義
stddate="eval date '+%Y/%m/%d %H:%M:%S'"

CMD_PATH="/opt/hitachi/HAmon/bin"
CMD_MONSHOW="$CMD_PATH/monshow"

###############################################################################
## main
###############################################################################
### Check Number of Parameter

if [ $# -ge 4 -o $# -le 2 ]; then
  echo invalid arguments.
  echo "usage:ZAZZ_getRgStatusSingle.ksh [ONL|SBY] [HA Server Name] [Hostname]"
  exit ${RET_FAIL_INVALID_ARGUMENTS}
fi

CHK_IDX=0
TMP_LANG=${LANG}
export LANG=C

ISVSTATUS=$1
IRESOURCEN=$2
IHOSTNAME=$3

# Check input Status Code

if [ $ISVSTATUS != "ONL" -a $ISVSTATUS != "SBY" ]; then
  echo invalid arguments.
  echo "Please Input Status [ONL or SBY]"
  exit ${RET_FAIL_INVALID_ARGUMENTS}
fi


# Get local hostname

LOCALFQDNNAME=`hostname`
LOCALHOSTNAME=`echo $LOCALFQDNNAME | awk '{ gsub(".itoen.master", "", $1);print($1) }'`


# Check Cluster condition

if [ ! -d $CMD_PATH ];then
  echo "";echo "*** [$LOCALFQDNNAME]はHAモニタクラスタを構成していません。"
  echo "";exit ${RET_SUCCESS}
fi

#debug echo ""; echo "### Cluster Information"
#debug echo ""; ${CMD_MONSHOW}
#debug echo ""

# Check Input HA Server Name 

RESOURCEENT=`${CMD_MONSHOW} | grep $IRESOURCEN`

if [ -z $RESOURCEENT ]; then
  echo "Invalid HA Server Name[$IRESOURCEN]."
  exit ${RET_FAIL_INVALID_RESOCE}
fi
OwnRESOURCEN=`echo $RESOURCEENT | cut -d ' ' -f1 `
OwnSTATUS=`echo $RESOURCEENT | cut -d ' ' -f2 `
PairSTATUS=`echo $RESOURCEENT | cut -d ' ' -f3 `
PairHOSTNAME=`echo $RESOURCEENT | cut -d ' ' -f4 `


# Check Own Server Name 

if [ $IRESOURCEN != $OwnRESOURCEN ]; then
   echo "Invalid HA Server Name[$IRESOURCEN]."
   exit ${RET_FAIL_INVALID_RESOCE}
fi


# Processing "bebsconXX"

case $LOCALHOSTNAME in
bebscon31)
  CONRESOURCEENT=`${CMD_MONSHOW} | grep bebscon11 | grep -v "KAMN213-I" `
  CON31STATUS=`echo $CONRESOURCEENT | cut -d ' ' -f1 `
  CON31PairHOSTNAME=`echo $CONRESOURCEENT | cut -d ' ' -f2 `
  ;;
bebscon*)
  CONRESOURCEENT=`${CMD_MONSHOW} | grep bebscon31 | grep -v "KAMN213-I" `
  CON31STATUS=`echo $CONRESOURCEENT | cut -d ' ' -f1 `
  CON31PairHOSTNAME=`echo $CONRESOURCEENT | cut -d ' ' -f2 `
  ;;
esac


# Check status 

case $IHOSTNAME in
# For Own servers
$LOCALHOSTNAME)
  if [ ${ISVSTATUS} = ${OwnSTATUS} ]; then
    CHK_IDX=1
  fi
  ;;
# For Pair servers
$PairHOSTNAME)
  if [ $ISVSTATUS = $PairSTATUS ]; then
    CHK_IDX=1
  fi
  ;;
# For bebscon31
bebscon31)
  if [ $ISVSTATUS = $CON31STATUS ]; then
    CHK_IDX=1
  fi
  ;;
# For bebscon11 on bebscon31
bebscon11)
  if [ $ISVSTATUS = $CON31STATUS ]; then
    CHK_IDX=1
  fi
  ;;
esac


if [ CHK_IDX -eq 0 ]; then
  echo "`$stddate` status invalid." 1>&2
  exit ${RET_FAIL_INVALID_STATUS}
fi

echo "`$stddate` status ok." 1>&2
exit ${RET_SUCCESS}

###############################################################################
## end of script.
###############################################################################
