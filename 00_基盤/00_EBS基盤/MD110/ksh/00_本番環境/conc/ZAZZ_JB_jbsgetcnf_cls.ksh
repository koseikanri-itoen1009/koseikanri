#!/bin/ksh
#
##############################################################################
##                                                                          ##
##    [概要]                                                                ##
##        JP1/Base共通定義出力スクリプト                                    ##
##                                                                          ##
##    [作成／更新履歴]                                                      ##
##        作成者  ：  日立製作所 影林幸子    2008/06/20 1.0                 ##
##        更新履歴：                                                        ##
##                                                                          ##
##                                                                          ##
##    [戻り値]                                                              ##
##        正常：0                                                           ##
##        異常：8～10                                                       ##
##                                                                          ##
##                                                                          ##
##    [パーミッション] :750                                                 ##
##                                                                          ##
##    [パラメータ] :第1引数（実行ホスト名 ）                                ##
##                                                                          ##                                                                        ##
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
HOST_NM="$1"

#処理開始メッセージの出力
PARM="`echo $#`"
echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "ホスト名："$HOST_NM"のJP1/Base・JP1/IM - Console・JP1/AJS2の定義情報出力を開始します" >> $LOG_FILE

#引数のチェック
if(( $PARM != 1 ))
  then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "引数が""$PARM""個指定されています。引数には１つの論理ホスト名を指定して下さい" >> $LOG_FILE
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
#TEIGI_FILENM="$TEIGI_DIR_LOGI""$HOST_NM"_jbsgetcnf_"$DATE".txt
TEIGI_FILENM="$TEIGI_DIR_LOGI""$HOST_NM"_jbsgetcnf.txt

#定義ファイル出力
/opt/jp1base/bin/jbsgetcnf -h $HOST_NM > $TEIGI_FILENM
RC="`echo $?`"
if(( "$RC" == 0 ))
  then
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "定義ファイル"$TEIGI_FILENM"の出力が完了しました" >> $LOG_FILE
   exit 0
 else
   echo ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "定義ファイル"$TEIGI_FILENM"の出力に失敗しました《リターンコード：""$RC""》" >> $LOG_FILE
   exit 8
fi
