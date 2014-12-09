#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_PEBSDB_PAT_PURGE.ksh                                             ##
##                                                                            ##
##   [ジョブ名]                                                               ##
##      ZC_PATデータパージ_01                                                 ##
##                                                                            ##
##   [概要]                                                                   ##
##      ページアクセストラッキングデータの削除を実施する。                    ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCS 川田           2010/02/16 1.0.0                    ##
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

### ページ・アクセス追跡データのパージ ###
L_rogushuturyoku "ページ・アクセス追跡データのパージ 開始"

L_hozonkikan=TE_ZCZZHOZONKIKAN_PAT         #保存期間

L_app_syokuseki_tansyukumei="SYSADMIN"     #職責のアプリケーション短縮名
L_syokusekimei="System Administrator"      #職責の名称
L_yuzamei="SYSADMIN"                       #ユーザ名
L_konkarento_app_tansyukumei="JTF"         #プログラムアプリケーション短縮名
L_konkarentomei="PATPURGE"                 #プログラムアプリケーション名

#日付計算
L_jikan=`expr ${TE_ZCZZHOZONKIKAN_PAT} \* 30 \* 24 - 9`
L_hikisu01=`env TZ=JST+${L_jikan} date +%d-%h-%Y`   #start_date  DD-MON-YYYY

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
   echo ${TE_ZCZZ01104} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#要求ID取得
L_rogushuturyoku "要求ID取得"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "要求ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01105}

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
L_rogushuturyoku "ページ・アクセス追跡データのパージ 終了"

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
