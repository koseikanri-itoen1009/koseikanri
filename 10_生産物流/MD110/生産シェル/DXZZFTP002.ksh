#!/bin/ksh
################################################################################
##                                                                            ##
##    [�T�v]                                                                  ##
##        T-Fresh FTP���M(�o�׎���)�p�X�N���v�g                               ##
##                                                                            ##
##    [�쐬�^�X�V����]                                                        ##
##        �쐬��  �F  Oracle    ��� �Y��    2008/05/01 1.0.1                 ##
##        �X�V�����F  Oracle    ��� �Y��    2008/05/01 1.0.1                 ##
##                        ����                                                ##
##                                                                            ##
##    [�߂�l]                                                                ##
##        0     ����                                                          ##
##        8     �ُ�                                                          ##
##                                                                            ##
##    [�p�����[�^]                                                            ##
##        �Ȃ�                                                                ##
##                                                                            ##
##     Copyright  ������Јɓ��� U5000�v���W�F�N�g 2007-2009                  ##
################################################################################
################################################################################
##                                 �ϐ���`                                   ##
################################################################################

## �ϐ���`
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
##                                 �֐���`                                   ##
################################################################################

### ���O�o�͏��� ###
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}

### �I������ ###
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

if [ ! -d ${L_local_path02} ]
then
  output_log "Local Dir is none"
  echo "${L_local_path02} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check Local Dir END"

### Check file ###
output_log "Check File START"

if [ ! -e ${L_local_path02}/${L_local_file02} ]
then
  output_log "Backup File is none"
  echo "${L_local_file02} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check File END"

### Check End File Dir ###
output_log "Check End File Dir START"

if [ ! -d ${L_local_epath02} ]
then
  output_log "End File Dir is none"
  echo "${L_local_epath02} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check End File Dir END"

### Check End file ###
output_log "Check End File START"

if [ ! -e ${L_local_epath02}/${L_local_efile02} ]
then
  output_log "End File is none"
  echo "${L_local_efile02} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check End File END"

### Execute FTP ###
output_log "FTP START"

${L_ftp} ${L_ftp_option} ${L_remote_host02} << __END__>> $L_logfile
user ${L_remote_user02} ${L_remote_pswd02}
cd ${L_remote_path02}
lcd ${L_local_path02}
ascii
put ${L_local_file02}
lcd ${L_local_epath02}
ascii
put ${L_local_efile02}
bye
__END__

output_log "FTP END"

### Shell end ###
shell_end $L_exit_norm
