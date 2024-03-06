#!/bin/ksh
#
##############################################################################
##                                                                          ##
##    [概要]                                                                ##
##        HULFT受信後ファイル移動シェル                                     ##
##        （ローカル→NFS ファイル移動スクリプト）                          ##
##                                                                          ##
##    [作成／更新履歴]                                                      ##
##        作成者  ：  日立 佐藤雅丈          2008/07/09 1.0                 ##
##        更新履歴：  日立 佐藤雅丈          2008/07/09 1.0                 ##
##                    初版                                                  ##
##                                                                          ##
##    [戻り値]                                                              ##
##        0     正常                                                        ##
##        -     警告                                                        ##
##        8     異常                                                        ##
##                                                                          ##
##    [パーミッション] :755                                                 ##
##                                                                          ##
##    [パラメータ] :%1=ファイル名（サブディレクトリ含む）                   ##
##                                                                          ##
##    [実行ユーザ] :ジョブ制御の設定に依存                                  ##
##                                                                          ##
##    [実行サーバ] :pebsdbXX                                                ##
##                 :tebsdbXX                                                ##
##                                                                          ##
##    [参照ファイル] :ローカルディレクトリ内の引数に指定されたファイル      ##
##                                                                          ##
##    [実行ファイル] :無し                                                  ##
##                                                                          ##
##    [出力ファイル] :NFSディレクトリ内の引数に指定されたファイル           ##
##                                                                          ##
##     Copyright  株式会社伊藤園 U5000プロジェクト 2007-2009                ##
##############################################################################

# default setting
EXIT_NORMAL=0
EXIT_ERROR=8

# initializing DIRECTORY_PATH
#ディレクトリ修正 -- 20081117
# 本番環境
#LOC_DIR=/var/hulft/snd/inbound
LOC_DIR=/paasif/hulft/inbound
#NFS_DIR=/ebst/tebs04/ebsif/inbound
NFS_DIR=/paasif/inbound

# parameter check
if [ $# -ne 1 ];then
    echo "parameter error." 1>&2
    exit $EXIT_ERROR
fi

echo $1 | grep -e "*" -e "?"
paramcheck=$?
if [ ${paramcheck} -ne 1 ];then
        echo "parameter error(* or ?)." 1>&2
        exit $EXIT_ERROR
fi

if [ -f ${NFS_DIR}/$1 ];then
        echo ${NFS_DIR}/$1 "already exists." 1>&2
        exit $EXIT_ERROR
fi

# FILE MOVE start process
cp -p ${LOC_DIR}/$1 ${NFS_DIR}/$1 1>&2
rc=$?
if [ $rc -ne 0 ] ; then
        echo "cp  command err ReturnCode=($rc)." 1>&2
        exit ${EXIT_ERROR}
  exit $rc
fi
echo "cp  command OK ReturnCode=($rc)." 1>&2

cmp ${LOC_DIR}/$1 ${NFS_DIR}/$1 1>&2 1>&2
rc=$?
if [ $rc -ne 0 ] ; then
        echo "cmp command err ReturnCode=($rc)." 1>&2
        exit ${EXIT_ERROR}
  exit $rc
fi
echo "cmp command OK ReturnCode=($rc)." 1>&2

rm -f ${LOC_DIR}/$1 1>&2
rc=$?
if [ $rc -ne 0 ] ; then
        echo "rm  command err ReturnCode=($rc)." 1>&2
        exit ${EXIT_ERROR}
  exit $rc
fi
echo "rm  command OK ReturnCode=($rc)." 1>&2

exit ${EXIT_NORMAL}
