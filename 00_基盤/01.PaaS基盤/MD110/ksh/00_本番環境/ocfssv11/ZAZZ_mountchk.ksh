#!/bin/ksh

###############################################################################
##                                                                           ##
##    [概要]                                                                 ##
##       mount状態確認シェル                                                 ##
##                                                                           ##
##    [作成／更新履歴]                                                       ##
##        作成者  ：  日立                   2022/07/13 1.0.0                ##
##        作成者  ：  日立                   2023/06/05 1.1.0                ##
##                      RHELv8用に変更                                       ##
##                                                                           ##
##    [スクリプトID] :ZAZZ_mountchk.ksh                                      ##
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
##      ファイル内は /etc/fstab の対象行を流用する                           ##
##                                                                           ##
##    [実行ユーザ] :root                                                     ##
##                                                                           ##
##    [実行サーバ] :bebs* | xebs*                                            ##
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

MOUNTDEFFILE=$1


while read MOUNTENT
do

  if [ ! -z ${MOUNTENT} ] ; then
    MOUNTSOURCE=`echo $MOUNTENT | cut -d ' ' -f1 `
### Comment 1.1.0
#    MOUNTPOINT=`echo $MOUNTENT | cut -d ' ' -f2 `
    MOUNTPOINT=`echo $MOUNTENT | cut -d ' ' -f3 `

    mount | grep ${MOUNTPOINT} | grep -v grep > /dev/null
    RET=$?
    if [ ${RET} -eq 0 ]; then
      echo "マウント中:[$MOUNTPOINT]"
    else
      echo "マウント解除:[$MOUNTPOINT]"
      EXIT_CODE=${RET_FAIL_ERROR}
    fi
  fi

done < $MOUNTDEFFILE


if [ ${EXIT_CODE} -eq ${RET_SUCCESS} ]; then
  echo "***マウントは全て実施しています"
else
  echo "!!!マウントは一部または全て解除しています"
fi


exit ${EXIT_CODE}
