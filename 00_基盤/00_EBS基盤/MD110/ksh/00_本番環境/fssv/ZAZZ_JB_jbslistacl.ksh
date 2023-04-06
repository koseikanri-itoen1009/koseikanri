#!/bin/ksh
#
##############################################################################
##                                                                          ##
##    [概要]                                                                ##
##        JP1/Base共通定義出力スクリプト                                    ##
##                                                                          ##
##    [作成／更新履歴]                                                      ##
##        作成者  ：  日立製作所 影林幸子    2008/06/20 1.0                 ##
##        更新履歴：  日立製作所 横内徳洋    2014/07/18 1.1                 ##
##                      ホスト名リテラル文字列のコマンド化                  ##
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
##    [実行ユーザ] :JP1/AJS2ジョブにて指定の所有ユーザに                    ##
##                    マッピングされたOSユーザ                              ##
##                                                                          ##
##    [実行サーバ] :JP1/AJS2導入の各サーバ                                  ##
##                                                                          ##
##    [参照ファイル] :"ENV_FILE"にて指定                                    ##
##                                                                          ##
##    [入力ファイル] :なし                                                  ##
##                                                                          ##
##    [サブルーチン] :なし                                                  ##
##                                                                          ##
##    [出力ファイル] :"LOG_FILE"にて指定                                    ##
##                                                                          ##
##   ［備考欄］                                                             ##
##                                                                          ##
##     Copyright  株式会社伊藤園 U5000プロジェクト 2007-2009                ##
##############################################################################

#初期設定
INIT_DIR="/uspg/jp1/za/shl/exec/"
INIT_FILENM="ZAZZ_JB_init.env"
LOG_FILE="/uspg/jp1/za/shl/exec/logs/RC_STDERR_ZAZZ_jp1backup.log"
DATE="`date '+%Y%m%d'`"
HOST_NM="`uname -n`"

#処理開始メッセージの出力
if(( $# == 0 ))
  then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "ホスト名："$HOST_NM"のJP1ユーザーの操作権限の出力を開始します" >> $LOG_FILE
fi

#引数のチェック
if(( $# != 0 ))
  then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "引数の指定は出来ません。処理を終了します" >> $LOG_FILE
   exit 9
fi

#環境変数ファイル有無のチェック
INIT_FILE=$INIT_DIR$INIT_FILENM
find $INIT_FILE
if(( $? != 0 ))
  then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "環境変数ファイル:"$INIT_FILE"が見つかりません" >> $LOG_FILE
   exit 10
fi

#環境変数ファイルの読み込み（変数設定）
. $INIT_FILE
#TEIGI_FILENM="$TEIGI_DIR""$HOST_NM"_jbslistacl_"$DATE".txt
TEIGI_FILENM="$TEIGI_DIR""$HOST_NM"_jbslistacl.txt

#定義ファイル出力
/opt/jp1base/bin/jbslistacl > $TEIGI_FILENM
RC="`echo $?`"
if(( "$RC" == 0 ))
  then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "定義ファイル"$TEIGI_FILENM"の出力が完了しました" >> $LOG_FILE
   exit 0
 else
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "定義ファイル"$TEIGI_FILENM"の出力に失敗しました《リターンコード：""$RC""》" >> $LOG_FILE
   exit 8
fi
