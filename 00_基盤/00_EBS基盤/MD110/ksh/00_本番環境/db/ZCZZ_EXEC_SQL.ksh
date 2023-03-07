#!/bin/ksh
################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_EXEC_SQL.ksh                                                     ##
##                                                                            ##
##   [概要]                                                                   ##
##      引数で指定したSQLファイルをsqlplusから実行する。                      ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK 飯塚             2023/01/11 1.0.0                 ##
##        更新履歴：   SCSK 飯塚             2023/01/11 1.0.0                 ##
##                       E_本稼動_19004対応                                   ##
##                           初版                                             ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      $1       実行するSQLファイル                                          ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_EXEC_SQL.ksh <SQLファイル>         ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

# 環境依存値

##環境依存値
L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名

L_sherumei=`/bin/basename $0`            #シェル名

L_sqlfairumei=`/bin/basename $1`            #SQLファイル名

L_hosutomei=`/bin/hostname -s`           #ホスト名

L_hizuke=`/bin/date "+%y%m%d"`           #日付

L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"    #ログファイル格納ディレクトリ

L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`_`/bin/basename ${L_sqlfairumei} .sql`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn=`/usr/bin/dirname $0`"/ZCZZCOMN.env"     #共通環境変数ファイル名



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
  
  L_Modorichi=${1:-0}
  exit ${L_Modorichi}
}

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

#===============================================================================
#                                   Main                                     
#===============================================================================
### 処理開始出力 ###
L_rogushuturyoku "ZCZZ00001:${L_sherumei} 開始"

### 環境設定ファイル読込み ###
### 基盤共通環境変数 ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
  echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei} STATUS:8" \
       | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
  L_shuryo 8
fi

### DB環境設定 ###
if [ -r ${TE_ZCZZDB} ]
then
  . ${TE_ZCZZDB}
else

  echo "ZCZZ00003:[Error] ZCZZDB.env が存在しない、または見つかりません。 HOST=${L_hosutomei} STATUS:${TE_ZCZZIJOUSHURYO}" \
       | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2

  L_shuryo ${TE_ZCZZIJOUSHURYO}

fi





### 引数チェック ###
if [ ! -r ${1} ]
then
  L_sqlfairu=`/usr/bin/dirname $0`"/${1}"
  if [ ! -r ${L_sqlfairu} ]
  then
    echo "ZCZZ00004:[Error] SQLファイル(${1}) が存在しない、または見つかりません。 HOST=${L_hosutomei} STATUS:${TE_ZCZZIJOUSHURYO}" \
       | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
    L_shuryo ${TE_ZCZZIJOUSHURYO}
  fi
else
  L_sqlfairu=${1}
fi

### SQL実行 ###
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> ${L_rogumei} 2>&1
set lines 200
set pages 2000
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

@${L_sqlfairu}

exit
EOF

L_sqlplus_rc=${?}

### SQL 終了判定 ###

if [ ${L_sqlplus_rc} -ne 0 ]
then
  echo "ZCZZ00005:[Error] SQLの実行に失敗しました(sqlplus=${L_sqlplus_rc})。 HOST=${L_hosutomei} STATUS:${TE_ZCZZIJOUSHURYO}" >> ${L_rogumei} \
     | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
  L_shuryo ${TE_ZCZZIJOUSHURYO}

fi

### 処理終了出力（正常） ###
L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了 STATUS:${TE_ZCZZSEIJOUSHURYO}"
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
