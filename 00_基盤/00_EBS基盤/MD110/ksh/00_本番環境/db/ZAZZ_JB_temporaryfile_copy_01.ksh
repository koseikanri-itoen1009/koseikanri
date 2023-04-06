#!/bin/ksh
#
##############################################################################
##                                                                          ##
##    [概要]                                                                ##
##        一時出力先フォルダからJP1/AJS2,JP1/Base定義ファイルをコピー       ##
##                                                                          ##
##    [作成／更新履歴]                                                      ##
##        作成者  ：  日立製作所 影林幸子    2008/09/05 1.0                 ##
##        更新履歴：                                                        ##
##                                                                          ##
##                                                                          ##
##    [戻り値]                                                              ##
##        正常：0                                                           ##
##        異常：8～12                                                       ##
##                                                                          ##
##                                                                          ##
##    [パーミッション] :750                                                 ##
##                                                                          ##
##    [パラメータ] :第1引数：コピーＩＤ                                     ##
##                                                                          ##
##    [実行ユーザ] :JP1/AJS2ジョブにて指定の所有ユーザに                    ##
##                    マッピングされたOSユーザ                              ##
##                                                                          ##
##    [実行サーバ] :JP1/AJS2導入の各サーバ                                  ##
##                                                                          ##
##    [参照ファイル] :ディレクトリ参照先ファイル                            ##
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
DR_FILE="/uspg/jp1/za/shl/exec/ZAZZinit_tmpfilecopy_01.txt" 
LOG_FILE="/uspg/jp1/za/shl/exec/logs/RC_STDERR_ZAZZ_jp1backup.log"

DATE=`date '+%Y%m%d'`
WEEK=`date '+%w'`

#引数（コピーＩＤ）有無のチェック
if [ $# -lt 1 ];then
        print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "第１引数（コピーＩＤ）の指定がありません" >> $LOG_FILE
        exit 9        
    else
	print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "コピーＩＤ："$@"にてコピーします" >> $LOG_FILE	
fi

#ディレクトリ参照ファイル有無のチェック
find $DR_FILE
if [ $? -ne 0 ];then
   print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "ディレクトリ参照先ファイルが見つかりません" >> $LOG_FILE
   exit 10
fi

#ディレクトリ参照ファイルの読み込み
COPY_DIR=`cat $DR_FILE | grep "$1"`
if [[ -z $COPY_DIR ]]
 then
   print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "該当するコピーＩＤが参照ファイルにありません" >> $LOG_FILE
   exit 11
 else
   COPY_IN=`echo $COPY_DIR | awk '{print $2}'` 
   COPY_OUT=`echo $COPY_DIR | awk '{print $3}'` 
   print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "コピー元（"$COPY_IN"）からコピー先（"$COPY_OUT$WEEK/$DATE"）にコピー開始" >> $LOG_FILE
fi

#コピー元ファイルの存在チェック
find $COPY_IN
if [ $? -ne 0 ];then
   print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "コピー元ファイルが見つかりません" >> $LOG_FILE
   exit 12
fi

#ディレクトリ作成
find $COPY_OUT$WEEK
if [[ $? -ne 0 ]]
 then
   mkdir $COPY_OUT$WEEK
   mkdir $COPY_OUT$WEEK/$DATE
 else
   find $COPY_OUT$WEEK/$DATE
   if [[ $? -ne 0 ]]
    then
      mkdir $COPY_OUT$WEEK/$DATE
   fi
fi

#コピー処理
cp -r $COPY_IN $COPY_OUT$WEEK/$DATE
if(( "$?" == 0 ))
 then
   print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "コピーＩＤ："$@"のコピーが完了しました" >> $LOG_FILE
   exit 0
 else
   print ${AJSJOBNAME}  `date '+%Y/%m/%d %H:%M:%S'`  "コピーＩＤ："$@"のコピーに失敗しました" >> $LOG_FILE
   exit 8
fi
