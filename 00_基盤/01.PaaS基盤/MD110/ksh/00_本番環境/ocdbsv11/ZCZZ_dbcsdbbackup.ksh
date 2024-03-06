#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          データベースのバックアップを取得する                              ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   日立製作所　藤井      2022/10/31 1.0.0                 ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/exec/ZCZZ_dbcsdbbackup.ksh                           ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################
L_ShellDir=`/usr/bin/dirname $0`         ## 実行シェルのディレクトリ
L_ShellName=`/bin/basename $0`           ## 実行シェル名

L_CommEnvFile=${L_ShellDir}/ZCZZ_dbcscomn.env ## 共通環境変数ファイル名
L_DBEnvFile=${L_ShellDir}/ZCZZ_dbcsdb.env     ## DB環境設定ファイル名

################################################################################
##                      環境設定環境変数ファイル読み込み                      ##
################################################################################
. ${L_CommEnvFile}
. ${L_DBEnvFile}

################################################################################
##                                 関数定義                                   ##
################################################################################
### ログ出力処理 ###
L_rogushuturyoku() {
    echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@}
}

### 終了処理 ###
L_shuryo() {
    L_modorichi=${1:-0}
    # L_rogushuturyoku "[Info] ${L_ShellName} 終了  END_CD="${L_modorichi}
    L_rogushuturyoku "[Info] ${L_ShellName} Ended.  END_CD="${L_modorichi}
    exit ${L_modorichi}
}

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                 メイン                                     ##
################################################################################
### 処理開始出力 ###
# L_rogushuturyoku "[Info] ${L_ShellName} 開始"
L_rogushuturyoku "[Info] ${L_ShellName} Start."

### DBバックアップ開始 ###
# L_rogushuturyoku "[Info] データベースバックアップ 開始"
L_rogushuturyoku "[Info] Database Backup proccess is started."

#DB起動
# L_rogushuturyoku "[Info] DB起動(マウントモード) 開始"
L_rogushuturyoku "[Info] Database start (mount mode) process is started."
$ORACLE_HOME/bin/sqlplus -L -S / as sysdba <<EOF
whenever oserror exit failure
whenever sqlerror exit failure
startup mount
exit
EOF

L_RC=$?
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] DBをマウントモードでの開始に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Database start (mount mode) process is failed. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

#バックアップ開始
# L_rogushuturyoku "[Info] DBバックアップ(RMAN) 開始"
L_rogushuturyoku "[Info] Database backup (RMAN) process is started."
$ORACLE_HOME/bin/rman target / <<EOF
run {
    backup as compressed backupset ( database format 'db_%I_%Y%M%D_%s_%p.bk' ) plus archivelog delete all input ;
    crosscheck backupset device type 'SBT_TAPE';
    delete noprompt obsolete device type 'SBT_TAPE';
}
exit
EOF

L_RC=$?
if [ $L_RC -ne 0 ]; then
#    L_rogushuturyoku "[Error] データベースのバックアップに失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Database backup (RMAN) process is failed. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

#DB停止
# L_rogushuturyoku "[Info] DB停止 開始"
L_rogushuturyoku "[Info] Database shutdown process is started."
sqlplus -L -S / as sysdba <<EOF
whenever oserror exit failure
whenever sqlerror continue
shutdown immediate
exit
EOF

L_RC=$?
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] DBを停止に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Database shutdown process is failed. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

# L_rogushuturyoku "[Info] [Info] データベースバックアップ 終了"
L_rogushuturyoku "[Info] [Info] Database Backup proccess is ended."

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSUCCESS}
