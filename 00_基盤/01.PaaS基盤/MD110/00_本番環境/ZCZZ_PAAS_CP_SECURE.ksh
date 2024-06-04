#!/bin/ksh

################################################################################
##                                                                            ##
##   [ファイル名]                                                             ##
##      ZCZZ_PAAS_CP_SECURE.ksh                                               ##
##                                                                            ##
##   [概要]                                                                   ##
##      /var/log/secureファイルをユーザーが参照できるように指定した           ##
##      ディレクトリへコピーし、権限の変更を行う。                            ##
##                                                                            ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   Oracle 飯塚           2023/10/27 1.0.0                 ##
##        更新履歴：   Oracle 飯塚           2023/10/27 1.0.0                 ##
##                       初版                                                 ##
##                     Oracle 飯塚           2024/02/15 1.0.1                 ##
##                       コメント部分を修正                                   ##
##                                                                            ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      $1 : secureファイルのコピー先ディレクトリパス                         ##
##                                                                            ##
##   [使用方法]                                                               ##
##      ・rootユーザーにて、cronから実行する                                  ##
##                                                                            ##
##      /uspg/jp1/zc/shl/<環境依存値>/ZCZZ_PAAS_CP_SECURE.ksh <$1のパラメータ>##
##                                                                            ##
##   [備考]                                                                   ##
##      ・設計書は無し                                                        ##
##                                                                            ##
################################################################################

################################################################################
##                                 変数定義                                   ##
################################################################################


L_shell_file_name=`/bin/basename $0`            #シェル名
L_shell_dir_path=`dirname $(readlink -f $0)`    #シェル格納DIRパス

L_host_name=`/bin/hostname -s`                  #ホスト名

L_date=`/bin/date "+%y%m%d"`                    #日付
L_ldate=`/bin/date "+%Y%m%d"`                   #ログ日付

L_log_dir="${L_shell_dir_path}/log"             #ログファイル格納ディレクトリ
L_log_file="${L_log_dir}/"`/bin/basename ${L_shell_file_name} .ksh`"_${L_host_name}_${L_date}.log"   #ログ


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

   L_return_num=${1:-0}
   L_rogushuturyoku "${L_shell_file_name} 終了  END_CD="${L_return_num}
   exit ${L_return_num}
}

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                   Main                                     ##
################################################################################

### 処理開始出力 ###
L_rogushuturyoku "${L_shell_file_name} 開始"

### $1ディレクトリ存在確認 ###
if [ ! -d $1 ]
then
   echo "[Error] $1 が存在しない、または見つかりません。 HOST=${L_host_name}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_log_file} 1>&2
   L_shuryo 8
fi

### secure ファイルのコピー ###


### 1.コピー先ディレクトリ内に日付(YYYYMMDD)ディレクトリを作成
### 2.secure ファイルを 作成したディレクトリへコピー
### 3.コピーしたsecureファイルのパーミッションを変更
mkdir -m 777 $1/${L_ldate} && cp -p /var/log/secure* $1/${L_ldate}/ && chmod 666 $1/${L_ldate}/secure*

if [ $? -ne 0 ]
then
   echo "[Error] secureファイルのコピーに失敗しました。HOST=${L_host_name}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_log_file} 1>&2
   L_shuryo 8
fi

L_rogushuturyoku "secure ファイルをコピーしました"


### 処理終了出力 ###
L_shuryo 0