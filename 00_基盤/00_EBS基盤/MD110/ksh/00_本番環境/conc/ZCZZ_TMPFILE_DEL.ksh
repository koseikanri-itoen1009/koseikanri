#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_TMPFILE_DEL.ksh                                                  ##
##                                                                            ##
##   [概要]                                                                   ##
##      保存期間を過ぎたNASサーバのログファイルの削除を実施する。             ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK 飯塚             2022/12/09 1.0.0                 ##
##        更新履歴：   SCSK 飯塚             2022/12/09 1.0.0                 ##
##                       E_本稼動_18733対応                                   ##
##                           初版                                             ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      $1       ファイルサイズ(GB)                                           ##
##      $2       ファイル保持期限(分)                                         ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_TMPFILE_DEL.ksh                    ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

## 環境依存値
L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名

L_sherumei=`/bin/basename $0`            #シェル名

L_hosutomei=`/bin/hostname -s`           #ホスト名

L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_lhizuke=`/bin/date "+%Y%m%d"`          #ログ日付

L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##ログファイル格納ディレクトリ

L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名

L_zczzcomn="`dirname $0`/ZCZZCOMN.env"   #共通環境変数ファイル名


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

   if [ -f "${TE_ZCZZHYOUJUNSHUTURYOKU}" ]
   then
      L_rogushuturyoku "標準出力一時ファイル削除実行"
      rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
   fi


   if [ -f "${TE_ZCZZHYOUJUNERA}" ]
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
TE_ZCZZTMPDELFILE="${TE_ZCZZSHERUPASU}/ZCZZ_TMPFILE_DEL.env"

if [ ! -r ${TE_ZCZZTMPDELFILE} ]
then
   echo "ZCZZ00003:[Error] ZCZZ_TMPFILE_DEL.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#L_direkutori 削除ログパス
#L_fmei       削除ログ名
#L_fmeisyo    ログ名称
#L_fairusaizu ログのサイズ
#L_hozonkikan ログ保存期間


### 削除対象一時ファイル存在確認および削除 ###
L_rogushuturyoku "削除対象ログファイル存在確認および削除 開始"

while read L_direkutori L_fmei L_fmeisyo L_fairusaizu L_hozonkikan
do
   L_moji=`echo ${L_direkutori} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
   then
      echo "### ${L_fmeisyo} ログファイル ###" >> ${L_rogumei}
      
      if [ $# -ge 2 ]
      then
         # 引数を条件に使用
         L_siyoufairusaizu=$1
         L_siyouhozonkikan=$2
      
      else
         # envファイルの条件を使用
         L_siyoufairusaizu=${L_fairusaizu}
         L_siyouhozonkikan=${L_hozonkikan}
      
      fi
      
      
      # 削除対象ファイルの取得
      /usr/bin/find ${L_direkutori} -name "${L_fmei}" -size +${L_siyoufairusaizu}G -mmin +${L_siyouhozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}


      L_kensu=`/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`

      if [ ${L_kensu} -ne 0 ]
      then
         # 削除対象ファイルが存在すれば削除実施
         /bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}

         /usr/bin/find ${L_direkutori} -name "${L_fmei}" -size +${L_siyoufairusaizu}G -mmin +${L_siyouhozonkikan} -exec rm {} \;
      else
         echo ${TE_ZCZZ01201} >> ${L_rogumei}
      fi
      
   fi
done < ${TE_ZCZZTMPDELFILE}

L_rogushuturyoku "削除対象ログファイル存在確認および削除 終了"


### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
