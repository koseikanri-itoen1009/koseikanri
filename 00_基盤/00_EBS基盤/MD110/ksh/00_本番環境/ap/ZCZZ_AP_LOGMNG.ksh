#!/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##      保存期間を過ぎたAPサーバのログファイルの削除を実施する。              ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 堀井           2008/03/24 1.0.1                 ##
##        更新履歴：   Oracle 堀井           2008/03/24 1.0.1                 ##
##                       初版                                                 ##
##                     SCS    川田           2009/11/26 1.0.2                 ##
##                     SCS    川田           2009/12/01 1.0.3                 ##
##                     SCS    北河           2010/01/08 1.0.4                 ##
##                       /tmp配下をユーザの条件付で削除対象に追加             ##
##                     SCSK   野口           2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・ローカル変数L_rogupasuの値を変更                 ##
##                         ・ENVファイル内ホスト名動的取得変更                ##
##                         ・シェル名変更                                     ##
##                     SCSK 山田             2022/01/12 3.0.0                 ##
##                       E_本稼動_17512対応                                   ##
##                         ・基幹システムリフト対応                           ##
##                         ・ホスト名取得引数追加                             ##
##                         ・コマンドのパス変更                               ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_AP_LOGMNG.ksh                      ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

##2014/07/31 S.Noguchi Add Start
## 環境依存値
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名
##2014/07/31 S.Noguchi Add End

L_sherumei=`/bin/basename $0`            #シェル名

##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#L_hosutomei=`/bin/hostname`              #ホスト名
L_hosutomei=`/bin/hostname -s`           #ホスト名
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応

L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_lhizuke=`/bin/date "+%Y%m%d"`          #ログ日付
##2014/07/31 S.Noguchi Mod Start
#L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #ログパス
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"   #ログパス
##2014/07/31 S.Noguchi Mod End
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名

##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
##L_zczzcomn="`/bin/dirname $0`/ZCZZCOMN.env"     #共通環境変数ファイル名
L_zczzcomn="`dirname $0`/ZCZZCOMN.env"     #共通環境変数ファイル名
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応

##2010/01/08 T.Kitagawa Add Start
L_tmpdir="/tmp"                          #/tmpパス
L_tmptypef="f"                           #ファイルの種類：通常ファイル
L_tmptyped="d"                           #ファイルの種類：ディレクトリ
##2014/07/31 S.Noguchi Mod Start
#L_tmpuser="pebsito"                      #ユーザ名
L_tmpuser=`whoami`                       #ユーザ名
##2014/07/31 S.Noguchi Mod End
L_tmphozonkikan="30"                     #/tmpディレクトリ配下の保存期間
##2010/01/08 T.Kitagawa Add End


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
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
##  if [ -f ${TE_ZCZZHYOUJUNSHUTURYOKU} ]
  if [ -f "${TE_ZCZZHYOUJUNSHUTURYOKU}" ]
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
   then
      L_rogushuturyoku "標準出力一時ファイル削除実行"
      rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
   fi

##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
##   if [ -f ${TE_ZCZZHYOUJUNERA} ]
   if [ -f "${TE_ZCZZHYOUJUNERA}" ]
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
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
if [ ! -r ${TE_ZCZZAPDELFILE} ]
then
   echo "ZCZZ00003:[Error] ZCZZAPDELFILE.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

##2014/07/31 S.Noguchi Add Start
L_zczzapdelfilevalue=${TE_ZCZZTENPUPASU}/`/bin/basename ${L_sherumei} .ksh`".tmp"
cat ${TE_ZCZZAPDELFILE} | sed -e "s/<HOSTNAME>/${L_hosutomei}/g" > ${L_zczzapdelfilevalue}
##2014/07/31 S.Noguchi Add End

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
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#         /usr/bin/gzip ${L_direkutori}/${L_fmei}.${L_lhizuke} 2> ${TE_ZCZZHYOUJUNERA}
#         /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
         /bin/gzip ${L_direkutori}/${L_fmei}.${L_lhizuke} 2> ${TE_ZCZZHYOUJUNERA}
         /bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
      fi
   fi
##2014/07/31 S.Noguchi Mod Start
#done < ${TE_ZCZZAPDELFILE}
done < ${L_zczzapdelfilevalue}
##2014/07/31 S.Noguchi Mod End

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
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
         L_kensu=`/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
         if [ ${L_kensu} -ne 0 ]
         then
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
            /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
            /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -exec rm {} \;
            if [ ${L_fmei} = "access_log.*" ]
            then
##2022/01/12 S.Yamada Mod Start
#               /usr/bin/find ${L_direkutori} -name "access_log.*" -mtime 1 -exec /usr/bin/gzip {} \;
               /usr/bin/find ${L_direkutori} -name "access_log.*" -mtime 1 -exec /bin/gzip {} \;
##2022/01/12 S.Yamada Mod End
            fi
         else
            echo ${TE_ZCZZ00700} >> ${L_rogumei}
         fi
      else
         /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
         L_kensu=`/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
         if [ ${L_kensu} -ne 0 ]
         then
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
            /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
            /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -exec rm {} \;
         else
            echo ${TE_ZCZZ00700} >> ${L_rogumei}
         fi
      fi
   fi
##2014/07/31 S.Noguchi Mod Start
#done < ${TE_ZCZZAPDELFILE}
done < ${L_zczzapdelfilevalue}
##2014/07/31 S.Noguchi Mod End

##2010/01/08 T.Kitagawa Add Start
#通常ファイルの削除（/tmp配下）
#L_hyoujunshuturyoku 削除ファイル一覧
echo "### ${L_tmpdir} ログファイル ###" >> ${L_rogumei}
/usr/bin/find ${L_tmpdir} -type ${L_tmptypef} -user ${L_tmpuser} -mtime +${L_tmphozonkikan} -print | sort -r > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
L_kensu=`/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
if [ ${L_kensu} -ne 0 ]
then
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
   while rdead L_hyoujunshuturyoku
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
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
L_kensu=`/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
if [ ${L_kensu} -ne 0 ]
then
##2022/01/12 S.Yamada Mod Start       ※E_本稼動_17512対応
#   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
##2022/01/12 S.Yamada Mod End         ※E_本稼動_17512対応
   while read L_hyoujunshuturyoku
   do
      rmdir ${L_hyoujunshuturyoku}
   done < ${TE_ZCZZHYOUJUNSHUTURYOKU}
else
   echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi
##2010/01/08 T.Kitagawa Add End

##2014/07/31 S.Noguchi Add Start
if [ -f ${L_zczzapdelfilevalue} ]
then
  rm ${L_zczzapdelfilevalue}
fi
##2014/07/31 S.Noguchi Add End

L_rogushuturyoku "削除対象ログファイル存在確認および削除 終了"


### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
