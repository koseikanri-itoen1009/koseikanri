#!/bin/ksh

################################################################################
##                                                                            ##
##   [使用方法]                                                               ##
##      ZCZZ_DB_LOGMNG_ARC.ksh                                                ##
##                                                                            ##
##   [ジョブ名]                                                               ##
##      日次DBサーバアーカイブログファイル削除                                ##
##                                                                            ##
##   [概要]                                                                   ##
##      日次で保存期間を過ぎたDBサーバのアーカイブログファイルの              ##
##      削除を実施する。                                                      ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCS 長濱              2009/07/06 1.0.1                 ##
##        更新履歴：   SCS 長濱              2009/07/06 1.0.1                 ##
##                       初版                                                 ##
##                     SCSK 髙橋             2014/07/31 2.0.0                 ##
##                       HWリプレース対応(リプレース_00007)                   ##
##                         ・Copyrightの削除                                  ##
##                         ・環境依存値の変数化                               ##
##                         ・使用方法の追加                                   ##
##                         ・シェル名変更                                     ##
##                         ・GRID環境設定ファイルの読み込み処理を追加         ##
##                         ・削除対象ファイルの取得方法の変更                 ##
##                         ・アーカイブログの削除方法を変更                   ##
##                         ・SQLの実行判定処理を追加                          ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_DB_LOGMNG_ARC.ksh                  ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################

##2014/07/31 S.Takahashi Add Start
##環境依存値
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名
##2014/07/31 S.Takahashi Add End

L_sherumei=`/bin/basename $0`            #シェル名
L_hosutomei=`/bin/hostname`              #ホスト名
L_hizuke=`/bin/date "+%y%m%d"`           #日付
L_lhizuke=`/bin/date "+%Y%m%d"`          #ログ日付
##2014/07/31 S.Takahashi Mod Start
#L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #ログパス
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"    #ログパス
##2014/07/31 S.Takahashi Mod End
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #ログ名
L_zczzcomn="`/bin/dirname $0`/ZCZZCOMN.env"     #共通環境変数ファイル名

##2014/07/31 S.Takahashi Add Start
L_zczzgrid="`/bin/dirname $0`/ZCZZGRID.env"                                                   #GRID環境変数ファイル名

##シェル固有環境変数
L_rogurisuto="`/bin/dirname $0`/tmp/"`/bin/basename ${L_sherumei} .ksh`".lst"                 #SQL一時ファイル
##2014/07/31 S.Takahashi Add End

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

##2014/07/31 S.Takahashi Add Start
   ### SQL一時ファイル削除 ###
   if [ -f ${L_rogurisuto} ]
   then
      L_rogushuturyoku "SQL一時ファイル削除実行"
      rm ${L_rogurisuto}
   fi
##2014/07/31 S.Takahashi Add End

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

##2014/07/31 S.Takahashi Add Start
## GRID環境設定ファイル読み込み
  L_rogushuturyoku "GRID環境設定ファイルを読み込みます。"

  if [ -r "${L_zczzgrid}" ]
    then
      . ${L_zczzgrid}
      L_rogushuturyoku "GRID環境設定ファイルを読み込みました。"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_zczzgrid}` が存在しない、または見つかりません。   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_zczzgrid}` が存在しない、または見つかりません。   HOST=${L_hosutomei}" 1>&2
      L_shuryo 8
  fi
##2014/07/31 S.Takahashi Add End


##2014/07/31 S.Takahashi Del Start  
#### ログファイル名称変更 ###
#L_rogushuturyoku "ログファイル名称変更 開始"
#
##ファイル読み込みチェック
#if [ ! -r ${TE_ZCZZDBDELFILEARC} ]
#then
#   echo "ZCZZ00003:[Error] ZCZZDBDELFILEARC.env が存在しない、または見つかりません。 HOST=${L_hosutomei}" \
#        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
#   L_shuryo ${TE_ZCZZIJOUSHURYO}
#fi
#
##L_direkutori 削除ログパス
##L_fmei       削除ログ名
##L_furagu=1   ファイル名称変更不要
##L_furagu=2   ファイル名称変更必要
##L_fmeisyo    ログ名称
##L_hozonkikan ログ保存期間
#while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
#do
#   L_moji=`echo ${L_direkutori} | cut -c 1`
#   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
#   then
#      if [ ${L_furagu} = "2" ]
#      then
#         /bin/mv ${L_direkutori}/${L_fmei} ${L_direkutori}/${L_fmei}.${L_lhizuke} 2> ${TE_ZCZZHYOUJUNERA}
#         /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
#      fi
#   fi
#done < ${TE_ZCZZDBDELFILEARC}
#
#L_rogushuturyoku "ログファイル名称変更 終了"
#
#
#### 削除対象ログファイル存在確認および削除 ###
#L_rogushuturyoku "削除対象ログファイル存在確認および削除 開始"
#
#while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
#do
#   L_moji=`echo ${L_direkutori} | cut -c 1`
#   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
#   then
#      echo "### ${L_fmeisyo} ログファイル ###" >> ${L_rogumei}
#      if [ ${L_furagu} = "1" ]
#      then
#         /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
#         if [ ${L_kensu} -ne 0 ]
#         then
#            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
#            /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -exec rm {} \;
#         else
#            echo ${TE_ZCZZ01000} >> ${L_rogumei}
#         fi
#      else
#         /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
#         if [ ${L_kensu} -ne 0 ]
#         then
#            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
#            /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -exec rm {} \;
#         else
#            echo ${TE_ZCZZ01000} >> ${L_rogumei}
#         fi
#      fi
#   fi
#done < ${TE_ZCZZDBDELFILEARC}
##2014/07/31 S.Takahashi Del End


##2014/07/31 S.Takahashi Add Start
### 削除対象アーカイブログファイルの取得 ###
L_rogushuturyoku "削除対象アーカイブログファイルの取得 開始"

sqlplus -s / as sysasm << EOF >> ${L_rogumei} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 120
set pages 500
set head off
set feedback off
set trimspool on
spool ${L_rogurisuto}
SELECT full_alias_path from
     (SELECT concat('+'||gname, sys_connect_by_path(aname, '/')) full_alias_path,fmdate
       FROM (SELECT g.name gname, a.parent_index pindex,a.name aname, a.reference_index rindex,f.MODIFICATION_DATE fmdate
               FROM v\$asm_alias a, v\$asm_diskgroup g, v\$asm_file f
              WHERE a.group_number = g.group_number
              and a.file_number = f.file_number(+)
              and a.group_number = f.group_number(+))
     START WITH (mod(pindex, power(2, 24))) = 0
     CONNECT BY PRIOR rindex = pindex
     )
     where full_alias_path like '%thread%'
     and fmdate < sysdate -(2/24)
     order by 1;
spool off
exit
EOF

#SQL実行判定
if [ $? -ne 0 ]
then
   echo "ZCZZ00008:[Error] SQL*Plusの実行に失敗しました。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   /usr/bin/cat ${L_hyoujunera} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "削除対象アーカイブログファイルの取得 終了"


### アーカイブログファイルの削除 ###
L_rogushuturyoku "アーカイブログファイル削除 開始"


#L_fmei 削除ログ名

let cnt_err=0
L_kensu=`/usr/bin/cat ${L_rogurisuto} | /usr/bin/wc -l | awk '{print $1}'`
if [ ${L_kensu} -ne 0 ]
then
  while read L_fmei 
  do
    if [ "X" != "${L_fmei}X" ]
    then
      L_rogushuturyoku "## 削除対象ファイル(${L_fmei})"
      asmcmd rm ${L_fmei}
      asmcmd ls ${L_fmei}
      L_risutostat=$?
      if [ ${L_risutostat} -ne 0 ]
      then
        L_rogushuturyoku "削除成功"
      else
        L_rogushuturyoku "削除失敗"
        let cnt_err=cnt_err+1
      fi
    fi
  done < ${L_rogurisuto}
else
  echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi

#アーカイブログファイル削除判定
if [ "$cnt_err" -ne 0 ]
then
   echo "ZCZZ00009:[Error] アーカイブログファイルの削除に失敗しました。 HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi
##2014/07/31 S.Takahashi Add End


L_rogushuturyoku "削除対象ログファイル存在確認および削除 終了"


### 処理終了出力 ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
