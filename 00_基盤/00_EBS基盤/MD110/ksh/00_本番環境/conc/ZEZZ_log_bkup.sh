#!/bin/bash
#
#
##############################################################################
##                                                                          ##
##    [概要]                                                                ##
##        SVF for Oracle E-Business Suite UNIX Connectログ退避シェル        ##
##                                                                          ##
##    [作成／更新履歴]                                                      ##
##        作成者  ：  日立製作所 後藤大作    2009/02/22 1.0                 ##
##        更新履歴：  日立製作所 木村彩乃    2021/07/26 2.0                 ##
##                                                                          ##
##                                                                          ##
##    [戻り値]                                                              ##
##        正常：0                                                           ##
##        異常：8～10                                                       ##
##                                                                          ##
##                                                                          ##
##    [パーミッション] :750                                                 ##
##                                                                          ##
##    [パラメータ] :なし                                                    ##
##                                                                          ##
##    [実行ユーザ] :JP1/AJS3ジョブにて指定の所有ユーザに                    ##
##                    マッピングされたOSユーザ                              ##
##                                                                          ##
##    [実行サーバ] :SVF for Oracle E-Business Suite UNIX Connect            ##
##                     導入の各サーバ                                       ##
##    [参照ファイル] :なし                                                  ##
##                                                                          ##
##    [入力ファイル] :/var/log/svf/インスタンス名/YYYYMMDD.log              ##
##                                                                          ##
##    [サブルーチン] :なし                                                  ##
##                                                                          ##
##    [出力ファイル] :/backup/svf_bk/svf_log.tar.Z                          ##
##                                                                          ##
##   ［備考欄］                                                             ##
##                                                                          ##
##     Copyright  株式会社伊藤園 U5000プロジェクト 2007-2009                ##
##############################################################################

#初期設定
RC=0
LOG_FILE="/uspg/jp1/ze/shl/exec/logs/RC_STDERR_ZEZZ_log_bkup.log"

#引数チェック
if [ $# -lt 1 ];then
        echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  MSG0101-E 引数が不足しています。処理を終了します。>> $LOG_FILE
    exit 8
fi


#ディレクトリの存在チェック
find /var/log/svf/$1
RC=$?
if [ $RC -ne 0 ];then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'` MSG0102-E 削除指定ディレクトリが見つかりません。処理を終了します。 >> $LOG_FILE
         exit 9
fi

#ディレクトリ配下のファイルチェック
find /var/log/svf/$1/*.*
RC=$?
if [ $RC -ne 0 ];then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'` MSG0103-E 削除指定ディレクトリ下にファイルが存在しません。処理を終了します。 >> $LOG_FILE
         exit 4
fi


#ワーク領域のクリア
rm -f /var/log/svf/$1/work/*.* >&2
RC=$?
if [ $RC -ne 0 ]; then
         exit 10
fi

#SVFログをワーク領域に移動
mv /var/log/svf/$1/*.log /var/log/svf/$1/work/. >&2
RC=$?
if [ $RC -ne 0 ]; then
         exit 11
fi

#アーカイブ処理
cd /var/log/svf/$1/work/
tar cvf $1_svf_log.tar ./*.log >&2
RC=$?
if [ $RC -ne 0 ]; then
         exit 12
fi

#圧縮処理
cd /var/log/svf/$1/work/
compress $1_svf_log.tar >&2
RC=$?

if [ $RC -ne 0 ]; then
         exit 13
fi

#アーカイブファイルをバックアップ領域へ
mv /var/log/svf/$1/work/$1_svf_log.tar.Z  /backup/job_bk/svf_bk/$1_svf_log.tar.Z >&2
RC=$?
if [ $RC -ne 0 ]; then
         exit 14
fi

exit 0
