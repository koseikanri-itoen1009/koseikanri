#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##      日次で保存期間を過ぎたDBサーバのローカルに出力されたアーカイブ        ##
##      ログファイルの削除を実施する。                                        ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK   髙橋           2014/07/31 2.0.0                 ##
##        更新履歴：   SCSK   髙橋           2014/07/31 2.0.0                 ##
##                       初版(リプレース_00007)                               ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_DB_LOGMNG_ARC_LOCAL.ksh            ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################


## 環境依存値
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名

## ディレクトリ定義
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##ログファイル格納ディレクトリ

## 変数定義
L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_lhizuke=`/bin/date "+%Y%m%d"`          #ログ日付
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn="`/bin/dirname $0`/ZCZZCOMN.env"     #共通環境変数ファイル名


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

### 削除対象ログファイル存在確認および削除 ###
L_rogushuturyoku "削除対象ログファイル存在確認および削除 開始"

#ファイル読み込みチェック
if [ ! -r ${TE_ZCZZDBDELFILEARCLOCAL} ]
then
   echo "ZCZZ00003:[Error] ZCZZDBDELFILEARCLOCAL.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_zczzdbdelarclocvalue=${TE_ZCZZTENPUPASU}/`/bin/basename ${L_sherumei} .ksh`".tmp"
cat ${TE_ZCZZDBDELFILEARCLOCAL} | sed -e "s/<HOSTNAME>/${L_hosutomei}/g" > ${L_zczzdbdelarclocvalue}

#L_direkutori 削除ログパス
#L_fmei       削除ログ名
#L_fmeisyo    ログ名称
#L_hozonkikan ログ保存期間

while read L_direkutori L_fmei L_fmeisyo L_hozonkikan
do
   L_moji=`echo ${L_direkutori} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
   then
      echo "### ${L_fmeisyo} ログファイル ###" >> ${L_rogumei}
      /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mmin +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
      L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
      if [ ${L_kensu} -ne 0 ]
      then
         /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
         /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mmin +${L_hozonkikan} -exec rm {} \;
      else
         echo ${TE_ZCZZ01000} >> ${L_rogumei}
      fi
   fi
done < ${L_zczzdbdelarclocvalue}

if [ -f ${L_zczzdbdelarclocvalue} ]
then
  rm ${L_zczzdbdelarclocvalue}
fi

L_rogushuturyoku "削除対象ログファイル存在確認および削除 終了"


### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
