#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          DBCS運用シェル起動                                                ##
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
##      /uspg/jp1/zc/shl/exec/ZCZZ_dbcsmain.ksh                               ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################
L_ShellDir=`/usr/bin/dirname $0`         ## 実行シェルのディレクトリ

################################################################################
##                                 メイン                                     ##
################################################################################
L_RC=0
L_Params=$1
case "$L_Params" in

"AWR" )
    sudo su - oracle -c "$L_ShellDir/ZCZZ_dbcsawr.ksh"
    L_RC=$?;;
"DBSTART" )
    sudo su - oracle -c "$L_ShellDir/ZCZZ_dbcsdbstart.ksh"
    L_RC=$?;;
"DBSTOP"  )
    sudo su - oracle -c "$L_ShellDir/ZCZZ_dbcsdbstop.ksh"
    L_RC=$?;;
"DBBACKUP"  )
    sudo su - oracle -c "$L_ShellDir/ZCZZ_dbcsdbbackup.ksh"
    L_RC=$?;;
"FILEBACKUP"  )
    sudo su - oracle -c "$L_ShellDir/ZCZZ_dbcsfilebackup.ksh"
    L_RC=$?;;
*  )
    # echo "[Error] パラメータの指定が正しくありません。[$L_Params]"
    echo "[Error] Invalid parameter. [$L_Params]"
    L_RC=8;;

esac

exit $L_RC
