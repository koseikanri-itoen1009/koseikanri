#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          データベースのAWRを実行する。DB停止直前、起動直後に実行され、     ##
##          異常終了した場合は戻り値を5として後続のジョブを実行する。         ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   日立製作所　藤井      2022/10/31 1.0.0                 ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      5 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/exec/ZCZZ_dbcsawr.ksh                                ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################
L_ShellDir=`/usr/bin/dirname $0`         ## 実行シェルのディレクトリ
L_ShellName=`/bin/basename $0`           ## 実行シェル名

L_CommEnvFile=${L_ShellDir}/ZCZZ_dbcscomn.env ## 共通環境変数ファイル名
L_DBEnvFile=${L_ShellDir}/ZCZZ_dbcsdb.env     ## CRS環境設定ファイル名

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
trap 'L_shuryo 5' 1 2 3 15

################################################################################
##                                 メイン                                     ##
################################################################################
### 処理開始出力 ###
# L_rogushuturyoku "[Info] ${L_ShellName} 開始"
L_rogushuturyoku "[Info] ${L_ShellName} Start."

### 実行ユーザ確認
if [ `whoami` != "oracle" ]; then
    # L_rogushuturyoku "[Error] 実行権限がありません。oracleユーザで実行してください."
    L_rogushuturyoku "[Error] It cannot be executed because there is no authority. Please run with the oracle user."
    L_shuryo ${TE_ZCZZWARNING}
fi

### AWR取得 ###
# L_rogushuturyoku "[Info] AWR取得 開始"
L_rogushuturyoku "[Info] AWR snapshot starts acquiring."

#AWR実行
$ORACLE_HOME/bin/sqlplus -S / as sysdba << EOF
whenever oserror exit failure
whenever sqlerror exit failure
execute dbms_workload_repository.create_snapshot(flush_level => 'TYPICAL');
exit
EOF

L_RC=$?
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] AWRスナップショットの取得に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Failed to get AWR snapshot. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZWARNING}
fi

# L_rogushuturyoku "[Info] AWR取得 終了"
L_rogushuturyoku "[Info] AWR snapshot acquisition end."

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSUCCESS}
