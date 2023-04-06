#!/bin/ksh

###############################################################################
##                                                                           ##
##    [概要]                                                                 ##
##       ネットワークインターフェース状態確認シェル                          ##
##                                                                           ##
##    [作成／更新履歴]                                                       ##
##        作成者  ：  日立 横内              2009/09/24 1.0.0                ##
##                ：  日立                   2022/06/30 2.0.0                ##
##                    RHEL対応                                               ##
##                                                                           ##
##    [スクリプトID] :ZAZZ_netchk.ksh                                        ##
##                                                                           ##
##    [戻り値]                                                               ##
##        0     正常終了（全てup）                                           ##
##        1     異常終了（一部または全てdown）                               ##
##      254     定義ファイル無し                                             ##
##      255     引数不正                                                     ##
##                                                                           ##
##    [パーミッション] :744                                                  ##
##                                                                           ##
##    [パラメータ] :arg1  定義ファイル                                       ##
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

# リターンコード: 引数不正
RET_FAIL_INVALID_ARGUMENTS=255

# リターンコード: ファイル無し
RET_FAIL_FILE_NOT_EXIST=254

# リターンコード: 異常終了
RET_FAIL_ERROR=1

# リターンコード: 正常終了 
RET_SUCCESS=0

if [ $# -ne 1 ]; then
  echo invalid arguments.
  exit ${RET_FAIL_INVALID_ARGUMENTS}
fi

if [ ! -f $1 ]; then
  echo file not exist. $1
  exit ${RET_FAIL_FILE_NOT_EXIST}
fi

set -A ARRY_INTERFACE

LOCALHOSTNAME=`hostname`
ARRY_IDX=0

while read RECORD
do
  if [ ! -z "${RECORD}" ] ; then
    if [[ ${RECORD} = ${LOCALHOSTNAME}* ]] ; then
      ARRY_INTERFACE[${ARRY_IDX}]=`echo ${RECORD} | cut -f 2- -d :`
#      ARRY_INTERFACE[${ARRY_IDX}]=`echo ${RECORD} | cut -f 3 -d ":"`
      ARRY_IDX=$((${ARRY_IDX} + 1))
   fi
  fi
done < $1


MATCH_COUNT=0

for ELEMENT in `ifconfig -a | awk 'BEGIN {group=0; interface=""; adr="";}
                      /eth[0-9]/ {group=1; interface=$1;}
                      /inet/ {if(group==1) {adr=$2; gsub("addr:","",adr); printf("%s,%s\n", interface, adr);};}
                      /lo/ {group=0; internace="";}'`
do
  for INTERFACE in ${ARRY_INTERFACE[@]}
  do
    if [[ ${ELEMENT} = ${INTERFACE} ]] ; then
      MATCH_COUNT=$((${MATCH_COUNT} + 1))
      echo ${ELEMENT}
    fi  
  done
done

if [ ${MATCH_COUNT} -ne ${#ARRY_INTERFACE[@]} ]; then
  echo "*** 全てまたは一部のネットワークインターフェースは稼動していません"
  exit ${RET_FAIL_ERROR}
fi

echo "*** 全てのネットワークインターフェースは稼動しています"

exit ${RET_SUCCESS}
