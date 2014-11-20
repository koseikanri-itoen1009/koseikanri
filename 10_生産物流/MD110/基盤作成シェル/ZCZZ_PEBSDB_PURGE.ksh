#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_PEBSDB_PURGE.ksh                                                 ##
##                                                                            ##
##   [ジョブ名]                                                               ##
##      データベースデータパージジョブ                                        ##
##                                                                            ##
##   [概要]                                                                   ##
##      データベースの監査データの削除を実施する。                            ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/03/31 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/03/31 1.0.1                 ##
##                       初版                                                 ##
##        更新履歴：   Oracle 吉野           2008/10/30 1.0.3                 ##
##                      購買オープン・インタフェースで処理されたデータのパージ##
##                      を追加                                                ##
##        更新履歴：   SCS    長濱           2009/07/05 1.0.4                 ##
##        更新履歴：   SCS    北河           2010/01/08 1.0.5                 ##
##                      デバッグ・ログおよびシステム・アラートのパージを追加  ##
##        更新履歴：   SCS    川田           2010/02/16 1.0.6                 ##
##                      ページアクセストラッキングデータのパージを削除        ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##    Copyright 株式会社伊藤園 U5000プロジェクト 2007-2009                    ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #ログパス
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名


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
   if [ -f ${TE_ZCZZHYOUJUNSHUTURYOKU} ]
   then
      L_rogushuturyoku "標準出力一時ファイル削除実行"
      rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
   fi
   if [ -f ${TE_ZCZZHYOUJUNERA} ]
   then
      L_rogushuturyoku "標準エラー一時ファイル削除実行"
      rm ${TE_ZCZZHYOUJUNERA}
   fi
   
   L_modorichi=${1:-0}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了  END_CD="${L_modorichi}
   exit ${L_modorichi}
}

### 実行ステータス確認 ###
L_jyoutaikakunin()
{
   #実行ステータス取得
   L_konkarento_jyoutai=`awk 'NR==4 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
   L_rogushuturyoku "STATUS_CD="${L_konkarento_jyoutai}

   #実行ステータス判定
   if [ "${L_konkarento_jyoutai}" != 'C' ]     #C:正常
   then
      echo ${L_era_messeige} "STATUS_CD="${L_konkarento_jyoutai} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
      /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
      L_shuryo ${TE_ZCZZIJOUSHURYO}
   fi

   L_rogushuturyoku "実行ステータス確認 終了"
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

### 基盤共通環境変数 ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

### コンカレント環境設定 ###
if [ -r ${TE_ZCZZCONC} ]
then
   . ${TE_ZCZZCONC}
else
   echo "ZCZZ00003:[Error] ZCZZCONC.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "環境設定ファイル読込み 終了"


### データパージ ###
L_rogushuturyoku "データパージ 開始"

#コンカレント要求やマネージャ・データのパージ
L_rogushuturyoku "コンカレント要求やマネージャ・データのパージ 開始"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"                      #職責の名称
L_yuzamei="SYSADMIN"                                       #ユーザ名
L_konkarento_app_tansyukumei="FND"                         #プログラムアプリケーション短縮名
L_konkarentomei="FNDCPPUR"                                 #プログラムアプリケーション名

L_hikisu01="ALL"                                           #Entity
L_hikisu02="Age"                                           #Mode
L_hikisu03=`expr ${TE_ZCZZHOZONKIKAN_DATAPURGE} \* 30`     #Mode Value
L_hikisu04='""'                                            #Oracle ID
L_hikisu05='""'                                            #User Name
L_hikisu06='""'                                            #Responsibility Application
L_hikisu07='""'                                            #Responsibility
L_hikisu08='""'                                            #Program Application
L_hikisu09='""'                                            #Program
L_hikisu10='""'                                            #Manager Application
L_hikisu11='""'                                            #Manager
L_hikisu12='YES'                                           #Report
L_hikisu13='YES'                                           #Purge Other

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}
echo "L_hikisu02="${L_hikisu02}                                     >> ${L_rogumei}
echo "L_hikisu03="${L_hikisu03}                                     >> ${L_rogumei}
echo "L_hikisu04="${L_hikisu04}                                     >> ${L_rogumei}
echo "L_hikisu05="${L_hikisu05}                                     >> ${L_rogumei}
echo "L_hikisu06="${L_hikisu06}                                     >> ${L_rogumei}
echo "L_hikisu07="${L_hikisu07}                                     >> ${L_rogumei}
echo "L_hikisu08="${L_hikisu08}                                     >> ${L_rogumei}
echo "L_hikisu09="${L_hikisu09}                                     >> ${L_rogumei}
echo "L_hikisu10="${L_hikisu10}                                     >> ${L_rogumei}
echo "L_hikisu11="${L_hikisu11}                                     >> ${L_rogumei}
echo "L_hikisu12="${L_hikisu12}                                     >> ${L_rogumei}
echo "L_hikisu13="${L_hikisu13}                                     >> ${L_rogumei}

#コンカレント実行
echo ""
L_rogushuturyoku "コンカレント実行"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       "${L_hikisu02}" \
                       "${L_hikisu03}" \
                       "${L_hikisu04}" \
                       "${L_hikisu05}" \
                       "${L_hikisu06}" \
                       "${L_hikisu07}" \
                       "${L_hikisu08}" \
                       "${L_hikisu09}" \
                       "${L_hikisu10}" \
                       "${L_hikisu11}" \
                       "${L_hikisu12}" \
                       "${L_hikisu13}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01100} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01101}

#実行ステータス確認
L_rogushuturyoku "実行ステータス確認 開始"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "コンカレント要求やマネージャ・データのパージ 終了"


### サインオン監査データのパージ ###
L_rogushuturyoku "サインオン監査データのパージ 開始"

L_hozonkikan=TE_ZCZZ_HOZONKIKAN_KANSA      #保存期間

L_app_syokuseki_tansyukumei="SYSADMIN"     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"      #職責の名称
L_yuzamei="SYSADMIN"                       #ユーザ名
L_konkarento_app_tansyukumei="FND"         #プログラムアプリケーション短縮名
L_konkarentomei="FNDSCPRG"                 #プログラムアプリケーション名

#日付取得
L_jikan=`expr ${TE_ZCZZHOZONKIKAN_KANSA} \* 30 \* 24 - 9`
L_hikisu01=`env TZ=JST+${L_jikan} date +%Y-%m-%d`                #Audit date YYYY-MM-DD

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}

#コンカレント実行
echo ""
L_rogushuturyoku "コンカレント実行"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01102} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01103}

#実行ステータス確認
L_rogushuturyoku "実行ステータス確認 開始"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "サインオン監査データのパージ 終了"

### ページ・アクセス追跡データのパージ ###
##2010/02/16 T.Kawata delete

### Oracle GL Web Inquiryアクセス／検索ログ削除 ###
L_rogushuturyoku "Oracle GL Web Inquiryアクセス／検索ログ削除 開始"


L_app_syokuseki_tansyukumei="SYSADMIN"     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"      #職責の名称
L_yuzamei="SYSADMIN"                       #ユーザ名
L_konkarento_app_tansyukumei="XGV"         #プログラムアプリケーション短縮名
L_konkarentomei="XGVALD"                   #プログラムアプリケーション名

L_hikisu01=`expr ${TE_ZCZZHOZONKIKAN_INQ} \* 30`    #P_DAYS

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}

#コンカレント実行
echo ""
L_rogushuturyoku "コンカレント実行"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01106} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}

L_era_messeige=${TE_ZCZZ01107}

#実行ステータス確認
L_rogushuturyoku "実行ステータス確認 開始"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "Oracle GL Web Inquiryアクセス／検索ログ削除 終了"


### 廃止ワークフロー・ランタイム・データのパージ ###
L_rogushuturyoku "廃止ワークフロー・ランタイム・データのパージ 開始"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"                      #職責の名称
L_yuzamei="SYSADMIN"                                       #ユーザ名
L_konkarento_app_tansyukumei="FND"                         #プログラムアプリケーション短縮名
L_konkarentomei="FNDWFPR"                                  #プログラムアプリケーション名

L_hikisu01='""'                                            #Item Type
L_hikisu02='""'                                            #Item Key
L_hikisu03=`expr ${TE_ZCZZHOZONKIKAN_HAISIWF} \* 30`       #Age
L_hikisu04='TEMP'                                          #Persistence Type
L_hikisu05='Y'                                             #Core Workflow Only
L_hikisu06='500'                                           #Commit Frequency
L_hikisu07='N'                                             #PurgeSigs

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}
echo "L_hikisu02="${L_hikisu02}                                     >> ${L_rogumei}
echo "L_hikisu03="${L_hikisu03}                                     >> ${L_rogumei}
echo "L_hikisu04="${L_hikisu04}                                     >> ${L_rogumei}
echo "L_hikisu05="${L_hikisu05}                                     >> ${L_rogumei}
echo "L_hikisu06="${L_hikisu06}                                     >> ${L_rogumei}
echo "L_hikisu07="${L_hikisu07}                                     >> ${L_rogumei}

#コンカレント実行
echo ""
L_rogushuturyoku "コンカレント実行"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       "${L_hikisu02}" \
                       "${L_hikisu03}" \
                       "${L_hikisu04}" \
                       "${L_hikisu05}" \
                       "${L_hikisu06}" \
                       "${L_hikisu07}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01109} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01110}

#実行ステータス確認
L_rogushuturyoku "実行ステータス確認 開始"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "廃止ワークフロー・ランタイム・データのパージ 終了"


### 廃止された一般ファイル・マネージャ・データのパージ ###
L_rogushuturyoku "廃止された一般ファイル・マネージャ・データのパージ 開始"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"                      #職責の名称
L_yuzamei="SYSADMIN"                                       #ユーザ名
L_konkarento_app_tansyukumei="FND"                         #プログラムアプリケーション短縮名
L_konkarentomei="FNDGFMPR"                                 #プログラムアプリケーション名

L_hikisu01='Yes'                                           #Expired
L_hikisu02='""'                                            #Program Name
L_hikisu03='""'                                            #Program Tag

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}
echo "L_hikisu02="${L_hikisu02}                                     >> ${L_rogumei}
echo "L_hikisu03="${L_hikisu03}                                     >> ${L_rogumei}

#コンカレント実行
echo ""
L_rogushuturyoku "コンカレント実行"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       "${L_hikisu02}" \
                       "${L_hikisu03}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01111} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01112}

#実行ステータス確認
L_rogushuturyoku "実行ステータス確認 開始"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "廃止された一般ファイル・マネージャ・データのパージ 終了"

### 購買オープン・インタフェースで処理されたデータのパージ ###
L_rogushuturyoku "購買オープン・インタフェースで処理されたデータのパージ 開始"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"                      #職責の名称
L_yuzamei="SYSADMIN"                                       #ユーザ名
L_konkarento_app_tansyukumei="PO"                          #プログラムアプリケーション短縮名
L_konkarentomei="POXPOIPR"                                 #プログラムアプリケーション名

L_hikisu01='""'                                            #Document Type
L_hikisu02='""'                                            #Document SubType
L_hikisu03='Y'                                             #Purge Accepted Data
L_hikisu04='N'                                             #Purge Rejected Data
L_hikisu05='""'                                            #Start Date
L_hikisu06='""'                                            #End Date
L_hikisu07='""'                                            #Batch id


echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}
echo "L_hikisu02="${L_hikisu02}                                     >> ${L_rogumei}
echo "L_hikisu03="${L_hikisu03}                                     >> ${L_rogumei}
echo "L_hikisu04="${L_hikisu04}                                     >> ${L_rogumei}
echo "L_hikisu05="${L_hikisu05}                                     >> ${L_rogumei}
echo "L_hikisu06="${L_hikisu06}                                     >> ${L_rogumei}
echo "L_hikisu07="${L_hikisu07}                                     >> ${L_rogumei}

#コンカレント実行
echo ""
L_rogushuturyoku "コンカレント実行"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       "${L_hikisu02}" \
                       "${L_hikisu03}" \
                       "${L_hikisu04}" \
                       "${L_hikisu05}" \
                       "${L_hikisu06}" \
                       "${L_hikisu07}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01113} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01114}

#実行ステータス確認
L_rogushuturyoku "実行ステータス確認 開始"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "購買オープン・インタフェースで処理されたデータのパージ 終了"

##2010/01/08 T.Kitagawa Add Start
### デバッグ・ログおよびシステム・アラートのパージ ###
L_rogushuturyoku "デバッグ・ログおよびシステム・アラートのパージ 開始"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"                      #職責の名称
L_yuzamei="SYSADMIN"                                       #ユーザ名
L_konkarento_app_tansyukumei="FND"                         #プログラムアプリケーション短縮名
L_konkarentomei="FNDLGPRG"                                 #プログラムアプリケーション名

#日付計算
L_jikan=`expr ${TE_ZCZZHOZONKIKAN_DSP} \* 30 \* 24 + 24 - 9`
L_hikisu01=`env TZ=JST+${L_jikan} date +%Y/%m/%d`   #Last Purge Date  YYYY/MM/DD

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}

#コンカレント実行
echo ""
L_rogushuturyoku "コンカレント実行"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#コンカレント実行判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01117} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01118}

#実行ステータス確認
L_rogushuturyoku "実行ステータス確認 開始"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "デバッグ・ログおよびシステム・アラートのパージ 終了"
##2010/01/08 T.Kitagawa Add End

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
