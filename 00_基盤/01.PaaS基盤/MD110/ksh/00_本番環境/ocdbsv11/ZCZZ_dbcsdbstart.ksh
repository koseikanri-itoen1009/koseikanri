#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBオンライン・サービス起動処理                                    ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   日立製作所　藤井      2022/10/31 1.0.0                 ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/exec/ZCZZ_dbcsdbstart.ksh                            ##
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

### 実行ユーザ確認
if [ `whoami` != "oracle" ]; then
    # L_rogushuturyoku "[Error] 実行権限がありません。oracleユーザで実行してください."
    L_rogushuturyoku "[Error] It cannot be executed because there is no authority. Please run with the oracle user."
    L_shuryo ${TE_ZCZZERROR}
fi

### データベース開始 ###
# L_rogushuturyoku "[Info] データベース起動 開始"
L_rogushuturyoku "[Info] Database instance start process is started."

# インスタンス開始
if [ "$TE_ZCZZKANKYO" = "dev" ]; then
    srvctl start database -db ${ORACLE_UNQNAME}
else
    srvctl start instance -db ${ORACLE_UNQNAME} -i $ORACLE_SID
fi
L_RC=$?
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] データベースの開始に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Database instance start process is failed. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

## データベース起動確認
# L_rogushuturyoku "[Info] データベース起動確認"
L_rogushuturyoku "[Info] Database instance startup check."
if [ "$TE_ZCZZKANKYO" = "dev" ]; then
    L_RTN=`srvctl status database -db ${ORACLE_UNQNAME} | grep "is running" | wc -l`
else
    L_RTN=`srvctl status instance -db ${ORACLE_UNQNAME} -i $ORACLE_SID | grep "is running" | wc -l`
fi
if [ $L_RTN -eq 0 ]; then
    # L_rogushuturyoku "[Error] データベースの起動中に、エラーが発生しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Database instance start process is failed. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
else
    # L_rogushuturyoku "[Info] データベースの開始を確認しました。"
    L_rogushuturyoku "[Info] Confirmed starting the database instance."
fi

# L_rogushuturyoku "[Info] データベース起動 終了"
L_rogushuturyoku "[Info] Database instance start process is ended."

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSUCCESS}
