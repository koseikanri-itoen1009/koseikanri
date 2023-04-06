#!/bin/ksh

###############################################################################
##                                                                           ##
##    [概要]                                                                 ##
##       JP1状態確認シェル                                                   ##
##                                                                           ##
##    [作成／更新履歴]                                                       ##
##        作成者  ：  日立 横内              2009/09/10 1.0.0                ##
##        更新者  ：  日立 横内              2009/11/29 1.0.1                ##
##                       JP1/PFM用ログ監視プロセスの確認を追加               ##
##                                                                           ##
##                ：  日立 横内              2014/07/18 1.0.2                ##
##                       名称変更に伴う修正                                  ##
##        更新者  ：  日立 白鳥              2022/06/30 2.0.0                ##
##                       RHEL対応に伴う修正                                  ##
##                                                                           ##
##    [スクリプトID] :ZAZZ_jp1chk.ksh                                        ##
##                                                                           ##
##    [戻り値]                                                               ##
##        0     正常終了（全て起動）                                         ##
##        1     異常終了（一部または全て未起動）                             ##
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

CMD_RESOURCE="/usr/es/sbin/cluster/utilities/clRGinfo -s"
CMD_JP1BASE="/opt/jp1base/bin/jbs_spmd_status "
CMD_JP1BASE_EVENT="/opt/jp1base/bin/jevstat "
CMD_JP1AJS="/opt/jp1ajs2/bin/jajs_spmd_status "
CMD_JP1PFM="/opt/jp1pc/tools/jpcctrl list "
CMD_HFT_SND="/usr/local/HULFT/bin/hulclustersnd -status -m"
CMD_HFT_RCV="/usr/local/HULFT/bin/hulclusterrcv -status -m"
CMD_HFT_OBS="/usr/local/HULFT/bin/hulclusterobs -status -m"
CMD_JP1CM2="/usr/CM2/ESA/bin/snmpcheck "
CMD_JP1LOGTRAP=/opt/jp1base/bin/jevlogdstat

CMD_JP1AJS_QLESS="/opt/jp1ajs2/bin/ajsqlstatus "

EXEC_LOGICAL_PARAM="-h "
EXEC_LOGICAL_PARAM_FOR_PFM=" lhost=ajobsv00 "

RGROUP_JP1="_jp1_"
RGROUP_HFT="_hulft_"
LOCALHOSTNAME=`hostname`
RSTATE_ONLINE="ONLINE"
RSTATE_OFFLINE="OFFLINE"

REAL_MODE=1
VIRTUAL_MODE=2

EXIT_CODE=${RET_SUCCESS}

set -A ARRY_CM2PROC "aixmibd" "hostmibd" "hp_unixagt" "htc_monagt1" "htc_unixagt1" "htc_unixagt3" "naaagt" "snmpd" "snmpdm" "snmpmibd" "trapdestagt"

###############################################################################
## main
###############################################################################
if [ $# -ge 2 ]; then
  echo invalid arguments.
  exit ${RET_FAIL_INVALID_ARGUMENTS}
fi

if [ $# -eq 0 ]; then
  MODE=${REAL_MODE}
else
  MODE=${VIRTUAL_MODE}
fi

if [ ${MODE} -eq ${REAL_MODE} ]; then

  # JP1/Base 物理サービスの確認
  ${CMD_JP1BASE}
  RET=$?
  if [ ${RET} -ne 0 ]; then
    echo "*** JP1/Base 物理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo

  # JP1/Base イベントサービス 物理サービスの確認
  ${CMD_JP1BASE_EVENT}
  RET=$?
  if [ ${RET} -ne 0 ]; then
    echo "*** JP1/Base イベントサービス 物理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo

  # JP1/AJS2 物理サービスの確認
  ${CMD_JP1AJS}
  RET=$?
  if [ ${RET} -ne 0 ]; then
    echo "*** JP1/AJS2 物理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo

  # JP1/AJS2キューレス 物理サービスの確認
  TMP_LANG=${LANG}
  export LANG=C
  # JP1/AJS2キューレスエージェント 物理サービスの確認
  ${CMD_JP1AJS_QLESS} | grep 'Queueless agent service' | grep ' active' 
  RET=$?
  if [ ${RET} -ne 0 ]; then
    export LANG=${TMP_LANG}
    ${CMD_JP1AJS_QLESS}
    echo "*** JP1/AJS2キューレスエージェント 物理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo
  export LANG=${TMP_LANG}

### Comment v2.0.0
#
#  case ${LOCALHOSTNAME} in
#    "ajobsv11"|"ajobsv21")
#    TMP_LANG=${LANG}
#    export LANG=C
#    # JP1/AJS2キューレスファイル転送サービス 物理サービスの確認
#    ${CMD_JP1AJS_QLESS} | grep 'Queueless file transfer service' | grep ' active'
#    RET=$?
#    if [ ${RET} -ne 0 ]; then
#      export LANG=${TMP_LANG}
#      ${CMD_JP1AJS_QLESS}
#      echo "*** JP1/AJS2キューレスファイル転送サービス 物理サービスが稼動していません"
#      EXIT_CODE=${RET_FAIL_ERROR}
#    fi
#    echo
#    export LANG=${TMP_LANG}
#      ;;
#    *)
#      ;;
#  esac

### Comment v2.0.0
#  # JP1/CM2 サービスの確認
#  ARRY_IDX=0
#  for ELEMENT in `${CMD_JP1CM2} | grep "pid" | cut -f 1 | sort`
#  do
#    if [[ ${ELEMENT} != ${ARRY_CM2PROC[${ARRY_IDX}]} ]]; then
#      ${CMD_JP1CM2}
#      echo "*** JP1/CM2 サービスが稼動していません"
#      EXIT_CODE=${RET_FAIL_ERROR}
#      exit for
#    fi
#    ARRY_IDX=$((${ARRY_IDX} + 1))
#  done

  # JP1/PFM 物理サービスの確認
  ${CMD_JP1PFM} "*" 
  echo
  ${CMD_JP1PFM} "*" | sed 1,3d |  sed "s/ ¥{2,¥}/ /g" | awk '{if($7 != ""){print $7} else {print $5}}' | sed "/^$/d" | grep -v Active
  RET=$?
  if [ ${RET} -eq 0 ]; then
    ${CMD_JP1PFM} "*"
    echo "*** JP1/PFM 物理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi

  # ログファイルトラップ確認
### Comment v2.0.0
#  # syslog.out
#  RET=`ps -ef | grep syslog.out | grep trap | grep -v grep | wc -l`
#  if [ ${RET} -ne 1 ]; then
#    echo "*** ログファイルトラップが稼動していません"
#    EXIT_CODE=${RET_FAIL_ERROR}
#  fi
  ${CMD_JP1LOGTRAP}
  RET=$?
  if [ ${RET} -ne 0 ]; then
    echo "*** JP1 ログファイルトラップ管理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo

  # alert.log
### Comment v2.0.0
#  if [ ${LOCALHOSTNAME} = "aebsdb11" -o ${LOCALHOSTNAME} = "aebsdb21" -o ${LOCALHOSTNAME} = "aebsdb31" ]; then
#    RET=`ps -ef | egrep alert_AEBSITO[1-3]¥.log | grep trap | grep -v grep | wc -l`
  if [ ${LOCALHOSTNAME} = "bebsdb11" -o ${LOCALHOSTNAME} = "bebsdb21" ]; then
    RET=`ps -ef | egrep alert_BEBSITO[1-3]¥.log | grep trap | grep -v grep | wc -l`
    if [ ${RET} -ne 1 ]; then
      echo "*** ログファイルトラップが稼動していません"
      EXIT_CODE=${RET_FAIL_ERROR}
    fi
  fi

#######################################
## 2009/11/29 追加(begin)
#######################################
  # jp1/pfmlog
#  if [ ${LOCALHOSTNAME} != "pjobsv11" -a ${LOCALHOSTNAME} != "pjobsv21" ]; then
#    RET=`ps -ef | grep jpclog01 | grep LOGTRAP | grep -v grep | wc -l`
#    if [ ${RET} -ne 1 ]; then
#      echo "*** ログファイルトラップが稼動していません"
#      EXIT_CODE=${RET_FAIL_ERROR}
#    fi
#  fi
#######################################
## 2009/11/29 追加(end)
#######################################

elif [ ${MODE} -eq ${VIRTUAL_MODE} ]; then

  # JP1/Base 論理サービスの確認
  ${CMD_JP1BASE} ${EXEC_LOGICAL_PARAM} $1
  RET=$?
  if [ ${RET} -ne 0 ]; then
    echo "*** JP1/Base 論理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo

  # JP1/Base イベントサービス 論理サービスの確認
  ${CMD_JP1BASE_EVENT} $1
  RET=$?
  if [ ${RET} -ne 0 ]; then
    echo "*** JP1/Base イベントサービス 論理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo

  # JP1/AJS2 論理サービスの確認
  ${CMD_JP1AJS} ${EXEC_LOGICAL_PARAM} $1
  RET=$?
  if [ ${RET} -ne 0 ]; then
    echo "*** JP1/AJS2 論理サービスが稼動していません"
    EXIT_CODE=${RET_FAIL_ERROR}
  fi
  echo

  # JP1/AJS2キューレス 論理サービスの確認
  case ${LOCALHOSTNAME} in
### Comment v2.0.0
#    "ajobsv11"|"ajobsv21"|"aebsdb11"|"aebsdb21"|"aebsdb31")
    "bebsdb11"|"bebsdb21")
      TMP_LANG=${LANG}
      export LANG=C
      # JP1/AJS2キューレスエージェント 論理サービスの確認
      ${CMD_JP1AJS_QLESS} ${EXEC_LOGICAL_PARAM} $1 | grep 'Queueless agent service' | grep ' active' 
      RET=$?
      if [ ${RET} -ne 0 ]; then
        export LANG=${TMP_LANG}
        ${CMD_JP1AJS_QLESS} ${EXEC_LOGICAL_PARAM} $1
        echo "*** JP1/AJS2キューレスエージェント 論理サービスが稼動していません"
        EXIT_CODE=${RET_FAIL_ERROR}
        export LANG=C
      fi
      echo

      # JP1/AJS2キューレスファイル転送サービス 論理サービスの確認
      if [ ${LOCALHOSTNAME} = "ajobsv11" -o ${LOCALHOSTNAME} = "ajobsv21" ]; then
        ${CMD_JP1AJS_QLESS} ${EXEC_LOGICAL_PARAM} $1 | grep 'Queueless file transfer service' | grep ' active'
        RET=$?
        if [ ${RET} -ne 0 ]; then
          export LANG=${TMP_LANG}
          ${CMD_JP1AJS_QLESS} ${EXEC_LOGICAL_PARAM} $1
          echo "*** JP1/AJS2キューレスファイル転送サービス 論理サービスが稼動していません"
          EXIT_CODE=${RET_FAIL_ERROR}
          export LANG=C
        fi
        echo
      fi
      export LANG=${TMP_LANG}
      ;;
    *)
      ;;
  esac

  # HULFT論理サービスの確認（EBS本番DBのみ）
### Comment v2.0.0
#  if [ ${LOCALHOSTNAME} = "aebsdb11" -o ${LOCALHOSTNAME} = "aebsdb21" -o ${LOCALHOSTNAME} = "aebsdb31" ]; then
#    if [ $1 = "aebshf00" ]; then
  if [ ${LOCALHOSTNAME} = "bebsdb11" -o ${LOCALHOSTNAME} = "bebsdb21" ]; then
    if [ $1 = "bebshf00" ]; then
      # HULFT配信サービスの確認
      ${CMD_HFT_SND}
      RET=$?
      if [ ${RET} -ne 0 ]; then
        echo "*** HULFT配信サービスが稼動していません"
        EXIT_CODE=${RET_FAIL_ERROR}
      fi

      # HULFT集信サービスの確認
      ${CMD_HFT_RCV}
      RET=$?
      if [ ${RET} -ne 0 ]; then
        echo "*** HULF集信サービスが稼動していません"
        EXIT_CODE=${RET_FAIL_ERROR}
      fi

      # HULFT要求受付サービスの確認
      ${CMD_HFT_OBS}
      RET=$?
      if [ ${RET} -ne 0 ]; then
        echo "*** HULF要求受付サービスが稼動していません"
        EXIT_CODE=${RET_FAIL_ERROR}
      fi
      echo
    fi
  fi

  # JP1/PFM 論理サービスの確認(ジョブ制御本番機のみ)
#  if [ ${LOCALHOSTNAME} = "ajobsv11" -o ${LOCALHOSTNAME} = "ajobsv21" ]; then
#    ${CMD_JP1PFM} "*" ${EXEC_LOGICAL_PARAM_FOR_PFM} | sed 1,3d |  sed "s/ ¥{2,¥}/ /g" | awk '{if($7 != ""){print $7} else {print $5}}' | sed "/^$/d" | grep -v Active
#    RET=$?
#    if [ ${RET} -eq 0 ]; then
#      ${CMD_JP1PFM} "*" ${EXEC_LOGICAL_PARAM_FOR_PFM}
#      echo "*** JP1/PFM 論理サービスが稼動していません"
#      EXIT_CODE=${RET_FAIL_ERROR}
#    fi
#    echo
#  fi
fi

if [ ${EXIT_CODE} -eq ${RET_SUCCESS} ]; then
  if [ ${MODE} -eq ${REAL_MODE} ]; then
    echo "*** 全ての物理サービスは稼動しています"
  else
    echo "*** 全ての論理サービスは稼動しています"
  fi
else
  if [ ${MODE} -eq ${REAL_MODE} ]; then
    echo "*** 全てまたは一部の物理サービスは稼動していません"
  else
    echo "*** 全てまたは一部の論理サービスは稼動していません"
  fi
fi

exit ${EXIT_CODE}
###############################################################################
## end of script.
###############################################################################
