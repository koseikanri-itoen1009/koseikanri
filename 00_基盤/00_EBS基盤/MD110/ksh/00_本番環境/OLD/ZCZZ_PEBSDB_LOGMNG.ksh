#!/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##      保存期間を過ぎたDBサーバのログファイルの削除を実施する。              ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/03/24 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/03/24 1.0.1                 ##
##                       初版                                                 ##
##                     SCS    北河           2010/01/08 1.0.2                 ##
##                       /tmp配下をユーザの条件付で削除対象に追加             ##
##                     SCSK   戸谷田         2012/04/23 1.0.3                 ##
##                       /ebsdblog/PEBSITO/bdump配下の一時ディレクトリを      ##
##                       削除対象に追加                                       ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      ZCZZ_PEBSDB_LOGMNG.ksh                                                ##
##                                                                            ##
##    Copyright 株式会社伊藤園 U5000プロジェクト 2007-2009                    ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_lhizuke=`/bin/date "+%Y%m%d"`          #ログ日付
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #ログパス
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn="`/bin/dirname $0`/ZCZZCOMN.env"     #共通環境変数ファイル名
##2010/01/08 T.Kitagawa Add Start
L_tmpdir="/tmp"                          #/tmpパス
L_tmptypef="f"                           #ファイルの種類：通常ファイル
L_tmptyped="d"                           #ファイルの種類：ディレクトリ
L_tmpuser="pebsito"                      #ユーザ名
L_tmphozonkikan="30"                     #/tmpディレクトリ配下の保存期間
##2010/01/08 T.Kitagawa Add End
##2012/04/23 D.Toyata Add Start
L_cdmpdir="/ebsdblog/PEBSITO/bdump"
L_cdmpdirmei="cdmp_"
L_cdmphozonkikan="14"
##2012/04/23 D.Toyata Add End

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
   ### 一時ファイル削除 ###
   if [ -f ${TE_ZCZZHYOUJUNSHUTURYOKU} ]
   then
      L_rogushuturyoku "標準出力一時ファイル削除実行"
      rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
   fi

   if [ -f ${TE_ZCZZHYOUJUNERA} ]
   then
      L_rogushuturyoku "標準エラー一時ファイル削除実行"
      rm ${TE_ZCZZHYOUJUNERA}
   fi

   L_modorichi=${1:-0}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} 終了  END_CD="${L_modorichi}
   exit ${L_modorichi}
}

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                   Main                                     ##
################################################################################

### 処理開始出力 ###
L_rogushuturyoku "ZCZZ00001:${L_sherumei} 開始"


### 環境設定ファイル読込み ###
L_rogushuturyoku "環境設定ファイル読込み 開始"

### 基盤共通環境変数 ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi
L_rogushuturyoku "環境設定ファイル読込み 終了"


### ログファイル名称変更 ###
L_rogushuturyoku "ログファイル名称変更 開始"

#ファイル読み込みチェック
if [ ! -r ${TE_ZCZZDBDELFILE} ]
then
   echo "ZCZZ00003:[Error] ZCZZDBDELFILE.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#L_direkutori 削除ログパス
#L_fmei       削除ログ名
#L_furagu=1   ファイル名称変更不要
#L_furagu=2   ファイル名称変更必要
#L_fmeisyo    ログ名称
#L_hozonkikan ログ保存期間
while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
do
   L_moji=`echo ${L_direkutori} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
   then
      if [ ${L_furagu} = "2" ]
      then
         /bin/mv ${L_direkutori}/${L_fmei} ${L_direkutori}/${L_fmei}.${L_lhizuke} 2> ${TE_ZCZZHYOUJUNERA}
         /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
      fi
   fi
done < ${TE_ZCZZDBDELFILE}

L_rogushuturyoku "ログファイル名称変更 終了"


### 削除対象ログファイル存在確認および削除 ###
L_rogushuturyoku "削除対象ログファイル存在確認および削除 開始"

while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
do
   L_moji=`echo ${L_direkutori} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
   then
      echo "### ${L_fmeisyo} ログファイル ###" >> ${L_rogumei}
      if [ ${L_furagu} = "1" ]
      then
         /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
         if [ ${L_kensu} -ne 0 ]
         then
            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
            /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -exec rm {} \;
         else
            echo ${TE_ZCZZ01000} >> ${L_rogumei}
         fi
      else
         /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
         if [ ${L_kensu} -ne 0 ]
         then
            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
            /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -exec rm {} \;
         else
            echo ${TE_ZCZZ01000} >> ${L_rogumei}
         fi
      fi
   fi
done < ${TE_ZCZZDBDELFILE}

##2010/01/08 T.Kitagawa Add Start
#通常ファイルの削除（/tmp配下）
#L_hyoujunshuturyoku 削除ファイル一覧
echo "### ${L_tmpdir} ログファイル ###" >> ${L_rogumei}
/usr/bin/find ${L_tmpdir} -type ${L_tmptypef} -user ${L_tmpuser} -mtime +${L_tmphozonkikan} -print | sort -r > ${TE_ZCZZHYOUJUNSHUTURYOKU}
L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
if [ ${L_kensu} -ne 0 ]
then
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   while read L_hyoujunshuturyoku
   do
      rm ${L_hyoujunshuturyoku}
   done < ${TE_ZCZZHYOUJUNSHUTURYOKU}
else
   echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi

#ディレクトリの削除（/tmp配下）
#L_hyoujunshuturyoku 削除ディレクトリ一覧
echo "### ${L_tmpdir} ログディレクトリ ###" >> ${L_rogumei}
/usr/bin/find ${L_tmpdir} -type ${L_tmptyped} -user ${L_tmpuser} -mtime +${L_tmphozonkikan} -print | sort -r > ${TE_ZCZZHYOUJUNSHUTURYOKU}
L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
if [ ${L_kensu} -ne 0 ]
then
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   while read L_hyoujunshuturyoku
   do
      rmdir ${L_hyoujunshuturyoku}
   done < ${TE_ZCZZHYOUJUNSHUTURYOKU}
else
   echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi
##2010/01/08 T.Kitagawa Add End

##2012/04/23 D.Toyata Add Start
#ディレクトリの削除（/ebsdblog/PEBSITO/bdump/配下のcdmp〜ディレクトリ）
#L_hyoujunshuturyoku 削除ディレクトリ一覧
echo "### ${L_cdmpdir} ログディレクトリ ###" >> ${L_rogumei}
/usr/bin/find ${L_cdmpdir} -type ${L_tmptyped} -name "${L_cdmpdirmei}*" -mtime +${L_cdmphozonkikan} -print | sort -r > ${TE_ZCZZHYOUJUNSHUTURYOKU}
L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
if [ ${L_kensu} -ne 0 ]
then
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   while read L_hyoujunshuturyoku
   do
      rm -Rf ${L_hyoujunshuturyoku}
   done < ${TE_ZCZZHYOUJUNSHUTURYOKU}
else
   echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi
##2012/04/23 D.Toyata Add End

L_rogushuturyoku "削除対象ログファイル存在確認および削除 終了"


### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
