#!/bin/ksh
################################################################################
##                                                                            ##
##    [概要]                                                                  ##
##        T-Fresh FTP送信(出荷依頼)用スクリプト                               ##
##                                                                            ##
##    [作成／更新履歴]                                                        ##
##        作成者  ：  Oracle    鈴木 雄大    2008/05/01 1.0.1                 ##
##        更新履歴：  Oracle    鈴木 雄大    2008/05/01 1.0.1                 ##
##                        初版                                                ##
##                                                                            ##
##    [戻り値]                                                                ##
##        0     正常                                                          ##
##        8     異常                                                          ##
##                                                                            ##
##    [パラメータ]                                                            ##
##        なし                                                                ##
##                                                                            ##
##     Copyright  株式会社伊藤園 U5000プロジェクト 2007-2009                  ##
################################################################################
################################################################################
##                                 変数定義                                   ##
################################################################################

## 変数定義
L_shellpath="/uspg/jp1/dx/shl/TEBS02"
L_logpath="/var/tmp/jp1/log"

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d"`
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"
L_envfile=${L_cmddir}/DXZZAPPS.env

L_exit_norm=0
L_exit_eror=8

################################################################################
##                                 関数定義                                   ##
################################################################################

### ログ出力処理 ###
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}

### 終了処理 ###
shell_end()
{
  L_retcode=${1:-0}
  output_log "`/bin/basename ${0}` END  END_CD="${L_retcode}
  exit ${L_retcode}
}

################################################################################
##                                   Main                                     ##
################################################################################

### Put log ###
touch ${L_logfile}
output_log "`/bin/basename ${0}` START"

### Read Shell Env File ###
output_log "Reading Shell Env File START"

if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading Shell Env File was Completed"
else
  output_log "Reading Shell Env File was Failed"
  echo "Reading Shell Env File was Failed" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Reading Shell Env File END"

### Check Local Dir ###
output_log "Check Local Dir START"

if [ ! -d ${L_local_path01} ]
then
  output_log "Local Dir is none"
  echo "${L_local_path01} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check Local Dir END"

### Check file ###
output_log "Check File START"

if [ ! -e ${L_local_path01}/${L_local_file01} ]
then
  output_log "Backup File is none"
  echo "${L_local_file01} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check File END"

### Check End File Dir ###
output_log "Check End File Dir START"

if [ ! -d ${L_local_epath01} ]
then
  output_log "End File Dir is none"
  echo "${L_local_epath01} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check End File Dir END"

### Check End file ###
output_log "Check End File START"

if [ ! -e ${L_local_epath01}/${L_local_efile01} ]
then
  output_log "End File is none"
  echo "${L_local_efile01} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check End File END"

### Execute FTP ###
output_log "FTP START"

${L_ftp} ${L_ftp_option} ${L_remote_host01} << __END__>> $L_logfile
user ${L_remote_user01} ${L_remote_pswd01}
cd ${L_remote_path01}
lcd ${L_local_path01}
ascii
put ${L_local_file01}
lcd ${L_local_epath01}
ascii
put ${L_local_efile01}
bye
__END__

output_log "FTP END"

### Shell end ###
shell_end $L_exit_norm
