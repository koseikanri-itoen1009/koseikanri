#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_PEBSDB_STPK_PRG.ksh                                              ##
##                                                                            ##
##   [ジョブ名]                                                               ##
##      STATSPACKデータパージジョブ                                           ##
##                                                                            ##
##   [概要]                                                                   ##
##      データベースの監査データの削除を実施する。                            ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCS 長濱              2009/07/09 1.0.1                 ##
##        更新履歴：   SCS 長濱              2009/07/09 1.0.1                 ##
##                       初版                                                 ##
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


### STATSPACKデータパージ ###
L_rogushuturyoku "STATSPACKデータパージ 開始"

#STATSPACKデータ削除実行
#STATSPACKデータ削除実行
${ORACLE_HOME}/bin/sqlplus -s perfstat/perfstat << EOF >> ${L_rogumei} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

execute statspack.purge(i_purge_before_date=>sysdate - ${TE_ZCZZHOZONKIKAN_STPK} , i_extended_purge => true , i_dbid => 2495813589, i_instance_number => 1);
execute statspack.purge(i_purge_before_date=>sysdate - ${TE_ZCZZHOZONKIKAN_STPK} , i_extended_purge => true , i_dbid => 2495813589, i_instance_number => 2);
execute statspack.purge(i_purge_before_date=>sysdate - ${TE_ZCZZHOZONKIKAN_STPK} , i_extended_purge => true , i_dbid => 2495813589, i_instance_number => 3);
exit
EOF

#実行結果判定
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01108} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "STATSPACKデータパージ 終了"

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
