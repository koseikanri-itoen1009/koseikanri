#!/bin/ksh
################################################################################
##                                                                            ##
##    [概要]                                                                  ##
##        HULFT起動用スクリプト(バックアップシェル起動:入出庫配送計画)        ##
##                                                                            ##
##    [作成／更新履歴]                                                        ##
##        作成者  ：  Oracle    鈴木 雄大    2008/07/16 1.0.1                 ##
##        更新履歴：  Oracle    鈴木 雄大    2008/07/16 1.0.1                 ##
##                        初版                                                ##
##                    SCSK内田 2014/08/13 [HWリプレイス対応]環境依存値の修正  ##
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
#2014/08/13 ADD START
L_envname=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #シェルの格納ディレクトリ
#2014/08/13 ADD END

#2014/08/13 MOD START
#L_shellpath="/uspg/jp1/dx/shl/PEBSITO"
#L_logpath="/var/EBS/jp1/PEBSITO/log"
#L_shellname="/uspg/jp1/zb/shl/PEBSITO/ZBZZIFFILE_BACKUP.ksh"
L_shellpath="/uspg/jp1/dx/shl/${L_envname}"
L_logpath="/var/EBS/jp1/${L_envname}/log"
L_shellname="/uspg/jp1/zb/shl/${L_envname}/ZBZZIFFILE_BACKUP.ksh"
#2014/08/13 MOD END
L_bkfilename="/hulft/outbound/TDXFAT_DST/TDXFAT_DST.csv"
L_bkfirname="/ebsif/outbound/TDXFAT_DST/backup"

L_execcmd="${L_shellname} ${L_bkfilename} ${L_bkfirname} 10"

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d"`
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"

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

### Check BackUp Shell ###
output_log "Check BackUp Shell START"

if [ ! -e ${L_shellname} ]
then
  output_log "Backup Shell is none"
  echo "${L_shellname} is not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check BackUp Shell END"

### Execute BackUp Shell ###
output_log "Execute BackUp Shell START"

${L_execcmd}

output_log "Execute BackUp Shell END"

### Shell end ###
shell_end $L_exit_norm
