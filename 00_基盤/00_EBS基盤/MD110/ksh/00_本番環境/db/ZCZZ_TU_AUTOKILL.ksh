#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##      一時表領域を指定サイズ以上使用しているセッションをkillする            ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK 廣守             2019/09/26 1.0.0                 ##
##        更新履歴：                                                          ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      1 : 容量(GB)                                                          ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_TU_AUTOKILL.ksh                    ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

##環境依存値
L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名
L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"    #ログファイル格納ディレクトリ
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .sh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名

### INパラメータ取得 ###
## 閾値をGB単位で指定
if [ ${1} -ge 0 ]
then
   GSIZE=${1}
else
   GSIZE=30
fi

##シェル固有環境変数
KILL_SID_LIST=/uspg/jp1/zc/shl/tmp/ZCZZ_kill_sid_list_temp.lst    #kill対象SIDリスト一時ファイル
KILL_SID_LIST2=/uspg/jp1/zc/shl/tmp/ZCZZ_kill_sid_list_temp2.lst    #kill対象SIDリスト一時ファイル

################################################################################
##                                 関数定義                                   ##
################################################################################

### ログ出力処理 ###
L_rogushuturyoku()
{
   echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_rogumei}
}

### 終了処理 ###
L_shuryo()
{
   
   L_modorichi=${1:-0}
   exit ${L_modorichi}
}

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                   Main                                     ##
################################################################################

### 処理開始出力 ###
L_rogushuturyoku "ZCZZ00001:${L_sherumei} 開始"

### 環境設定ファイル読込み ###

### 基盤共通環境変数 ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 (${TE_ZCZZIJOUSHURYO})"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### DB環境設定 ###
if [ -r ${TE_ZCZZDB} ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[Error] ZCZZDB.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 (${TE_ZCZZIJOUSHURYO})"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### 一時表領域 kill対象確認 ###
${ORACLE_HOME}/bin/sqlplus -s system/ito\#en03<< EOF1 >> /dev/null
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 500
set pages 500
col name format a50
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set head off
set feedback off
set trim on
set trims on
set colsep ','
spool ${KILL_SID_LIST}

select
    sample_time
   ,session_id
   ,session_serial#
   ,seq#
   ,user_id
   ,sql_id
   ,top_level_sql_id
   ,event
   ,session_state
   ,program
   ,machine
   ,temp_space_allocated / 1024 / 1024 / 1024 temp_alloc_gb
from
    v\$active_session_history
where
    (temp_space_allocated / 1024 / 1024 / 1024) > ${GSIZE}
    and sql_id in('12wxxxpfgfq49', '8wt3rn9z02c0k', 'b5juyc9qavq7y')
    and sample_time > to_timestamp (sysdate - 2/1440, 'YYYY/MM/DD HH24:MI:SS') 
    and sample_time = (select max(sample_time)
                       from v\$active_session_history
                       where (temp_space_allocated / 1024 / 1024 / 1024) > ${GSIZE}
                             and sample_time > to_timestamp (sysdate - 2/1440, 'YYYY/MM/DD HH24:MI:SS'))
/

spool off
exit
EOF1

### SQL 終了判定 ###

if [ $? != 0 ]
then
   echo "[ERROR]:kill対象SID取得に失敗しました" >> ${L_rogumei}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 (${TE_ZCZZIJOUSHURYO})"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### Active Session 確認 ###
while IFS=, read L_TIME L_SID L_SERIAL L_SEQ L_USER L_SQL_ID L_TSQL_ID L_EVENT L_STATE L_PROGRAM L_MACHINE L_TEMP
do 
   if [ -n "${L_SQL_ID}" ] #空白行判定（spoolファイルの1行目が改行のみのため）
   then
      L_SQL_ID=`echo ${L_SQL_ID} | tr -d " "`

      ${ORACLE_HOME}/bin/sqlplus -s system/ito\#en03 << EOF2 >> /dev/null
      WHENEVER OSERROR EXIT FAILURE
      WHENEVER SQLERROR EXIT FAILURE

      set lines 2000
      set pages 500
      col name format a50
      alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
      set head off
      set feedback off
      set trim on
      set trims on
      set colsep ','
      spool ${KILL_SID_LIST2}

      SELECT
           ss.sid
          ,ss.serial#
          ,ss.seq#
          ,ss.username
          ,tu.tablespace
          ,SUM(tu.blocks) * 8 / 1024 / 1024 used_gb
          ,ss.process
          ,ss.sql_id
          ,sq.sql_text
      FROM
          v\$tempseg_usage tu
          ,v\$session ss
          ,v\$sql sq
      WHERE
          tu.session_addr = ss.saddr
      AND ss.sql_id = sq.sql_id
      and ss.sql_id = '${L_SQL_ID}'
      GROUP BY
           ss.sid
          ,ss.serial#
          ,ss.seq#
          ,ss.username
          ,tu.tablespace
          ,ss.process
          ,ss.sql_id
          ,sq.sql_text
      ORDER BY
          ss.sid
      /

      spool off
      exit
EOF2

### SQL 終了判定 ###

      if [ $? != 0 ]
      then
         echo "[ERROR]:kill対象SID取得2に失敗しました" >> ${L_rogumei}
         L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 (${TE_ZCZZIJOUSHURYO})"
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      fi

### セッションkill ###
###   セッションを強制終了するとSQLエラーになるため、実行時のSQLエラーは無視する ###
      while IFS=, read L_SID2 L_SERIAL2 L_SEQ2 L_USER2 L_TBS L_BLOCK L_PROCESS L_SQL_ID2 L_SQL_TEXT
      do 
         if [ -n "${L_SQL_ID2}" ] #空白行判定（spoolファイルの1行目が改行のみのため）
         then
             L_SID2=`echo ${L_SID2} | tr -d " "`
             L_SERIAL2=`echo ${L_SERIAL2} | tr -d " "`

             L_rogushuturyoku "kill Session SID : ${L_SID2} SERIAL# : ${L_SERIAL2} TEMP_USED(GB) : ${L_TEMP}"
             L_rogushuturyoku "     USER : ${L_USER} PROCESS : ${L_PROCESS} PROGRAM : ${L_PROGRAM} MACHINE : ${L_MACHINE} SQL_ID : ${L_SQL_ID}"
             L_rogushuturyoku "     SQL_TEXT : ${L_SQL_TEXT}"

            ${ORACLE_HOME}/bin/sqlplus -s system/ito\#en03 << EOF3 >> /dev/null
            WHENEVER OSERROR EXIT FAILURE
----            WHENEVER SQLERROR EXIT SQL.SQLCODE

            set head off
            set feedback off
            alter system kill session '${L_SID2}, ${L_SERIAL2}' IMMEDIATE;
            exit
EOF3

### SQL 終了判定 ###

            if [ $? != 0 ] && [ $? != 31 ]
            then
               echo "[ERROR]:セッションの kill に失敗しました" >> ${L_rogumei}
               L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 (${TE_ZCZZIJOUSHURYO})"
               exit ${TE_ZCZZIJOUSHURYO}
            fi

         fi
         sleep 1
      done < ${KILL_SID_LIST2}

   fi
   sleep 1
done < ${KILL_SID_LIST}

### リストファイル削除 ###
rm -f ${KILL_SID_LIST} >> ${L_rogumei}
rm -f ${KILL_SID_LIST2} >> ${L_rogumei}

### 処理開始出力 ###
L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 (${TE_ZCZZSEIJOUSHURYO})"

L_shuryo ${TE_ZCZZSEIJOUSHURYO}
