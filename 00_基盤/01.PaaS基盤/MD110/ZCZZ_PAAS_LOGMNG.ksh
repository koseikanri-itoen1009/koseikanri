#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_PAAS_LOGMNG.ksh                                                  ##
##                                                                            ##
##   [概要]                                                                   ##
##      保存期間を過ぎたPaaSサーバのログファイルの削除を実施する。            ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 飯塚           2023/03/16 1.0.0                 ##
##        更新履歴：   Oracle 飯塚           2023/04/05 1.0.0                 ##
##                       初版                                                 ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_PAAS_LOGMNG.ksh                    ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################


L_shell_file_name=`/bin/basename $0`            #シェル名
L_shell_dir_path=`dirname $(readlink -f $0)`            #シェル格納DIRパス

## 環境依存値
L_env_name=`echo ${L_shell_dir_path} | sed -e "s/.*\///"` ##最下層のカレントディレクトリ名

L_host_name=`/bin/hostname -s`           #ホスト名

L_date=`/bin/date "+%y%m%d"`           #日付
L_ldate=`/bin/date "+%Y%m%d"`          #ログ日付

L_log_dir="${L_shell_dir_path}/log"            ##ログファイル格納ディレクトリ
L_log_file="${L_log_dir}/"`/bin/basename ${L_shell_file_name} .ksh`"${L_host_name}${L_date}.log"   #ログ

L_zczzcomn="${L_shell_dir_path}/ZCZZCOMN.env"   #共通環境変数ファイル

L_zczzmsg="${L_shell_dir_path}/ZCZZMSG.env"     #共通メッセージファイル


################################################################################
##                                 関数定義                                   ##
################################################################################

### ログ出力処理 ###
L_rogushuturyoku()
{
   echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_log_file}
}

### 終了処理 ###
L_shuryo()
{
   ### 一時ファイル削除 ###
   if [ -f "${TE_ZCZZ_TEMP_STDOUT}" ]
   then
      L_rogushuturyoku "標準出力一時ファイル削除実行"
      rm ${TE_ZCZZ_TEMP_STDOUT}
   fi

   if [ -f "${TE_ZCZZ_TEMP_STDERR}" ]
   then
      L_rogushuturyoku "標準エラー一時ファイル削除実行"
      rm ${TE_ZCZZ_TEMP_STDERR}
   fi

   L_return_num=${1:-0}
   L_rogushuturyoku "ZCZZ00002:${L_shell_file_name} 終了  END_CD="${L_return_num}
   exit ${L_return_num}
}

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                   Main                                     ##
################################################################################

### 処理開始出力 ###
L_rogushuturyoku "ZCZZ00001:${L_shell_file_name} 開始"


### 環境設定ファイル読込み ###
L_rogushuturyoku "環境設定ファイル読込み 開始"

### 基盤共通環境変数 ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env が存在しない、または見つかりません。 HOST=${L_host_name}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_log_file} 1>&2
   L_shuryo 8
fi
L_rogushuturyoku "環境設定ファイル読込み 終了"


### メッセージファイル読込み ###
L_rogushuturyoku "メッセージファイル読込み 開始"

### 基盤共通メッセージ ###
if [ -r ${L_zczzmsg} ]
then
   . ${L_zczzmsg}
else
   echo "ZCZZ00003:[Error] ZCZZMSG.env が存在しない、または見つかりません。 HOST=${L_host_name}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_log_file} 1>&2
   L_shuryo 8
fi
L_rogushuturyoku "メッセージファイル読込み 終了"


#PaaSサーバ削除対象ファイルを指定
L_zczzpaasdelfile="${L_shell_dir_path}/ZCZZPAASDELFILE.env"


### 対象ログファイルのリネーム(flag=2) ###
L_rogushuturyoku "ログファイルリネーム 開始"

#ファイル読み込みチェック
if [ ! -r ${L_zczzpaasdelfile} ]
then
   echo "ZCZZ00003:[Error] ZCZZPAASDELFILE.env が存在しない、または見つかりません。 HOST=${L_host_name}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_log_file} 1>&2
   L_shuryo ${TE_ZCZZ_EXIT_ERROR}
fi

#L_wr_dir 削除ログパス
#L_wr_filename       削除ログ名
#L_wr_flag=1   ファイルリネーム不要
#L_wr_flag=2   ファイルリネーム必要
#L_wr_filename_op    ログ名称
#L_wr_retention ログ保存期間
while read L_wr_dir L_wr_filename L_wr_flag L_wr_filename_op L_wr_retention
do
   L_moji=`echo ${L_wr_dir} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
   then
      if [ ${L_wr_flag} = "2" ]
      then

         L_furupasufilelist=`find ${L_wr_dir} -name "${L_wr_filename}" -print`
         for L_furupasufilemei in `echo ${L_furupasufilelist}`
         do
            /bin/mv ${L_furupasufilemei} ${L_furupasufilemei}.${L_ldate} 2> ${TE_ZCZZ_TEMP_STDERR}

            /bin/cat ${TE_ZCZZ_TEMP_STDERR} >> ${L_log_file}

         done
      fi
   fi
done < ${L_zczzpaasdelfile}

L_rogushuturyoku "対象ログファイルのリネーム 終了"


### 削除対象ログファイル存在確認および削除 ###
L_rogushuturyoku "削除対象ログファイル存在確認および削除 開始"

while read L_wr_dir L_wr_filename L_wr_flag L_wr_filename_op L_wr_retention
do
   L_moji=`echo ${L_wr_dir} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # コメント行かどうか確認
   then
      echo "### ${L_wr_filename_op} ログファイル ###" >> ${L_log_file}
      if [ ${L_wr_flag} = "1" ]
      then
         /usr/bin/find ${L_wr_dir} -name "${L_wr_filename}" -mtime +${L_wr_retention} -print > ${TE_ZCZZ_TEMP_STDOUT}

         L_kensu=`/bin/cat ${TE_ZCZZ_TEMP_STDOUT} | /usr/bin/wc -l`

         if [ ${L_kensu} -ne 0 ]
         then

            /bin/cat ${TE_ZCZZ_TEMP_STDOUT} >> ${L_log_file}

            /usr/bin/find ${L_wr_dir} -name "${L_wr_filename}" -mtime +${L_wr_retention} -exec rm {} \;
         else
            echo ${TE_ZCZZ01200} >> ${L_log_file}
         fi
      else
         /usr/bin/find ${L_wr_dir} -name "${L_wr_filename}.*" -mtime +${L_wr_retention} -print > ${TE_ZCZZ_TEMP_STDOUT}

         L_kensu=`/bin/cat ${TE_ZCZZ_TEMP_STDOUT} | /usr/bin/wc -l`

         if [ ${L_kensu} -ne 0 ]
         then

            /bin/cat ${TE_ZCZZ_TEMP_STDOUT} >> ${L_log_file}

            /usr/bin/find ${L_wr_dir} -name "${L_wr_filename}.*" -mtime +${L_wr_retention} -exec rm {} \;
         else
            echo ${TE_ZCZZ01200} >> ${L_log_file}
         fi
      fi
   fi
done < ${L_zczzpaasdelfile}

L_rogushuturyoku "削除対象ログファイル存在確認および削除 終了"


### 処理終了出力 ###
L_shuryo ${TE_ZCZZ_EXIT_NORMAL}
