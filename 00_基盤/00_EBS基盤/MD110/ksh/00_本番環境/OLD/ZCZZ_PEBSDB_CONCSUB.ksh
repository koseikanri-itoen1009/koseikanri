#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_PEBSDB_CONCSUB.ksh                                               ##
##                                                                            ##
##   [概要]                                                                   ##
##      コンカレント要求発行機能(SYSADMIN用)                                  ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCS 北河              2010/03/27 1.0.0                 ##
##        更新者  ：   SCS 北河              2010/03/27 1.0.0                 ##
##                       初版                                                 ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      $1       コンカレントアプリケーション短縮名                           ##
##      $2       コンカレントプログラム名                                     ##
##      $3～     コンカレントパラメータ                                       ##
##                                                                            ##
##    Copyright 株式会社伊藤園 U5000プロジェクト 2007-2009                    ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hiduke=`/bin/date "+%y%m%d`            #日付
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #ログパス
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${2}${L_hiduke}.log"                   #ログ名
L_hyoujunshuturyoku="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${2}${L_hiduke}_std_out.tmp" #標準出力一時ファイル
L_hyoujunera="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${2}${L_hiduke}_std_err.tmp"        #標準エラー一時ファイル
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名
L_apps='APPS/APPS'                       #コマンド実行ユーザ名
L_app_syokuseki_tansyukumei='SYSADMIN'   #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"    #職責の名称
L_yuzamei='SYSADMIN'                     #ユーザ名
L_wait='WAIT=1'                          #処理終了待機フラグ
L_flag='CONCURRENT'                      #必須フラグ
L_hikisu="${L_apps} ${L_app_syokuseki_tansyukumei} \"${L_syokusekimei}\" ${L_yuzamei} ${L_wait} ${L_flag}"        #CONCSUB用引数


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
   ### 一時ファイル削除 ###
   if [ -f ${L_hyoujunshuturyoku} ]
   then
      L_rogushuturyoku "標準出力一時ファイル削除実行"
      rm ${L_hyoujunshuturyoku}
   fi
   if [ -f ${L_hyoujunera} ]
   then
      L_rogushuturyoku "標準エラー一時ファイル削除実行"
      rm ${L_hyoujunera}
   fi
   
   L_modorichi=${1:-0}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了  END_CD="${L_modorichi}
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
L_rogushuturyoku "環境設定ファイル読込み 開始"

#基盤共通環境変数
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

#コンカレント環境設定
if [ -r ${TE_ZCZZCONC} ]
then
   . ${TE_ZCZZCONC}
else
   echo "ZCZZ00003:[Error] ZCZZCONC.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "環境設定ファイル読込み 終了"

### 入力パラメータ設定 ###
L_rogushuturyoku "入力パラメータ設定 開始"

if [ ${#} -lt 2 ]
then
   echo "ZCZZ00004:[Error] 入力パラメータが2個より少ないです。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_cnt=0
   for i in ${@}
   do
      L_cnt=`expr ${L_cnt} + 1`
      echo "入力パラメータ${L_cnt}：${i}" \
           | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   done
   L_shuryo ${TE_ZCZZIJOUSHURYO}
else
   L_cnt=0
   for i in ${@}
   do
      L_cnt=`expr ${L_cnt} + 1`
      if [ "$(echo ${i} | egrep 'hiduke')" ]
      then
         if [ "$(echo ${i} | egrep 'hiduke[1-9]')" ]
         then
            L_tmp=${i#hiduke}                                                 #hiduke文字列削除
            L_hojikikan=${L_tmp%+*}                                           #日付書式文字列削除
            L_jikan=`expr ${L_hojikikan} \* 30 \* 24 - 9`                     #保持時間計算
            L_hiduke=`env TZ=JST+${L_jikan} date ${L_tmp#${L_hojikikan}}`     #対象日計算
            L_rogushuturyoku "入力パラメータ${L_cnt}：${L_hiduke}"
            L_hikisu="${L_hikisu} ${L_hiduke}"
         else
            echo "ZCZZ00005:[Error] 日付パラメータが間違っています。 HOST=${L_hosutomei}" \
                 | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
            echo "入力パラメータ${L_cnt}：${i}" \
                 | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
            L_shuryo ${TE_ZCZZIJOUSHURYO}
         fi
      else
         L_rogushuturyoku "入力パラメータ${L_cnt}：${i}"
         L_hikisu="${L_hikisu} ${i}"
      fi
   done
fi

L_rogushuturyoku "入力パラメータ設定 終了"

### コンカレント要求の発行 ###
echo ""
L_rogushuturyoku "コンカレント要求の発行 開始"

${FND_TOP}/bin/CONCSUB ${L_hikisu} > ${L_hyoujunshuturyoku} 2> ${L_hyoujunera}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo "ZCZZ00006:[Error] CONCSUBの実行に失敗しました。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   /usr/bin/cat ${L_hyoujunera} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### 要求ID取得 ###
L_rogushuturyoku "要求ID取得 開始"

L_yokyu_id=`awk 'NR==1 {print $3}' ${L_hyoujunshuturyoku}`
L_rogushuturyoku "要求ID="${L_yokyu_id}

#要求ID取得判定
if [ "$(echo ${L_yokyu_id} | egrep '^[0-9]+$')" = "" ]
then
   echo "ZCZZ00007:[Error] 要求ID取得に失敗しました。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   /usr/bin/cat ${L_hyoujunera} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "要求ID取得 終了"

### 実行ステータス確認 ###
L_rogushuturyoku "実行ステータス確認 開始"

#実行ステータス確認SQL
${ORACLE_HOME}/bin/sqlplus -s ${L_apps} << EOF > ${L_hyoujunshuturyoku} 2> ${L_hyoujunera}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

ALTER SESSION SET NLS_LANGUAGE='Japanese';
SET LINESIZE 200

COLUMN ph FORMAT A2
COLUMN st FORMAT A2
COLUMN concurrent_name FORMAT A100
SELECT fcrs.request_id  reqid
      ,fcrs.phase_code  ph
      ,fcrs.status_code st
      ,fcrs.user_concurrent_program_name concurrent_name
FROM   fnd_conc_req_summary_v fcrs
WHERE  fcrs.request_id='${L_yokyu_id}';
exit
EOF

#SQL実行判定
if [ $? -ne 0 ]
then
   echo "ZCZZ00008:[Error] SQL*Plusの実行に失敗しました。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   /usr/bin/cat ${L_hyoujunera} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#実行ステータス取得
L_konkarento_jyoutai=`awk 'NR==7 {print $3}' ${L_hyoujunshuturyoku}`
L_konkarentomei=`awk 'NR==7 {for(i=4;i<=NF;i++) print $i}' ${L_hyoujunshuturyoku}`
L_rogushuturyoku "コンカレント名称="${L_konkarentomei}
L_rogushuturyoku "STATUS_CD="${L_konkarento_jyoutai}

#実行ステータス判定
if [ "${L_konkarento_jyoutai}" != 'C' ]     #C:正常
then
   echo "ZCZZ00009:[Error] ${L_konkarentomei} STATUS_CD=${L_konkarento_jyoutai}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "実行ステータス確認 終了"

L_rogushuturyoku "コンカレント要求の発行 終了"

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
