#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_LOG_REPL.ksh                                                     ##
##                                                                            ##
##   [概要]                                                                   ##
##      ログファイルのリプレースを実施する。                                  ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   SCSK 飯塚             2023/04/20 1.0.0                 ##
##        更新履歴：   SCSK 飯塚             2023/04/27 1.0.0                 ##
##                       E_本稼動_19165対応                                   ##
##                           初版                                             ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      4 : 警告                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_LOG_REPL.ksh                       ##
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

L_log_dir=""/var/EBS/jp1/${L_env_name}/log""            ##ログファイル格納ディレクトリ
L_log_file="${L_log_dir}/"`/bin/basename ${L_shell_file_name} .ksh`"${L_host_name}${L_date}.log"   #ログ

L_zczzcomn="${L_shell_dir_path}/ZCZZCOMN.env"   #共通環境変数ファイル

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


### 変数変換
TE_ZCZZ_EXIT_NORMAL=${TE_ZCZZSEIJOUSHURYO}
TE_ZCZZ_EXIT_WARNING=${TE_ZCZZKEIKOKUSHOURYO}
TE_ZCZZ_EXIT_ERROR=${TE_ZCZZIJOUSHURYO}
TE_ZCZZ_TEMP_STDOUT=${TE_ZCZZHYOUJUNSHUTURYOKU}
TE_ZCZZ_TEMP_STDERR=${TE_ZCZZHYOUJUNERA}

L_exit_code=${TE_ZCZZ_EXIT_NORMAL}

#リプレース対象ログファイルを指定
L_zczz_log_repl_list="${L_shell_dir_path}/ZCZZ_LOG_REPL_LIST.env"

#ファイル読み込みチェック
if [ ! -r ${L_zczz_log_repl_list} ]
then
   echo "ZCZZ00003:[Error] ZCZZ_LOG_REPL_LIST.env が存在しない、または見つかりません。 HOST=${L_host_name}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_log_file} 1>&2
   L_shuryo ${TE_ZCZZ_EXIT_ERROR}
fi


### 削除対象ログファイル存在確認および削除 ###
L_rogushuturyoku "削除対象ログファイル存在確認および削除 開始"

#L_wr_dir         リプレース対象ログファイル格納ディレクトリ
#L_wr_filename    リプレース対象ログファイル名
#L_wr_backup_dir  バックアップ先ディレクトリ
#L_wr_retention   バックアップ先での拡張子
#L_wr_filename_op ログ名
while read L_wr_dir L_wr_filename L_wr_backup_dir L_wr_extension L_wr_filename_op
do
   L_first_letter=`echo ${L_wr_dir} | cut -c 1`
   if [ ${L_first_letter:-#} != "#" ]           # コメント行かどうか確認
   then
      echo "### ${L_wr_filename_op} ログファイル ###" >> ${L_log_file}
      /usr/bin/find ${L_wr_dir} -name "${L_wr_filename}" -print > ${TE_ZCZZ_TEMP_STDOUT}

      L_kensu=`/bin/cat ${TE_ZCZZ_TEMP_STDOUT} | /usr/bin/wc -l`

      if [ ${L_kensu} -ne 0 ]
      then

         /bin/cat ${TE_ZCZZ_TEMP_STDOUT} >> ${L_log_file}

         while read L_wr_replace_file
         do

            L_repl_fn=`basename ${L_wr_replace_file}`

            cp -p ${L_wr_replace_file} ${L_wr_backup_dir}/${L_repl_fn%.*}_${L_host_name}_${L_date}.${L_wr_extension} \
                 && echo -n "" > ${L_wr_replace_file} 
            
            if [ "${?}" -ne 0 ]
            then
               # リプレースに失敗したら、メッセージ出力し、処理は継続。終了時は警告終了
               echo "ZCZZ00004:[Warning] ${L_wr_replace_file} のリプレースが正常に処理できませんでした。 HOST=${L_host_name}" \
                    | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_log_file} 1>&2
            
               L_exit_code=${TE_ZCZZ_EXIT_WARNING}
            
            fi
            
         done < ${TE_ZCZZ_TEMP_STDOUT}

      else
         echo ${TE_ZCZZ01200} >> ${L_log_file}
      fi
   fi
done < ${L_zczz_log_repl_list}

L_rogushuturyoku "削除対象ログファイル存在確認および削除 終了"


### 処理終了出力 ###
L_shuryo ${L_exit_code}
