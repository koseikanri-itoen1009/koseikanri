#!/bin/ksh
################################################################################
##                                                                            ##
##    [�T�v]                                                                  ##
##        �t�@�C���o�b�N�A�b�v�p�X�N���v�g                                    ##
##                                                                            ##
##    [�쐬�^�X�V����]                                                        ##
##        �쐬��  �F  Oracle    ��� �Y��    2008/04/01 1.0.1                 ##
##        �X�V�����F  Oracle    ��� �Y��    2008/04/01 1.0.1                 ##
##                    Oracle    ��� �Y��    2008/06/24 1.0.2                 ##
##                        ����                                                ##
##                    SCSK      ���� ����    2014/08/05 1.0.3                 ##
##                        ���v���[�X_00004�Ή�                                ##
##                                                                            ##
##    [�߂�l]                                                                ##
##        0     ����                                                          ##
##        8     �ُ�                                                          ##
##                                                                            ##
##    [�p�����[�^]                                                            ##
##        �o�b�N�A�b�v�t�@�C����                                              ##
##        �o�b�N�A�b�v��f�B���N�g����                                        ##
##        �o�b�N�A�b�v���㐔                                                  ##
##        �G���h�t�@�C����                                                    ##
##                                                                            ##
##     Copyright  ������Јɓ��� U5000�v���W�F�N�g 2007-2009                  ##
################################################################################
################################################################################
##                                 �ϐ���`                                   ##
################################################################################

## �ϐ���`
#2014/08/05 ADD Ver.1.0.3 by Shota Takahashi START
L_envname=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #�V�F���̊i�[�f�B���N�g��
#2014/08/05 ADD Ver.1.0.3 by Shota Takahashi END

#2014/08/05 MOD Ver.1.0.3 by Shota Takahashi START
#L_shellpath="/uspg/jp1/zb/shl/PEBSITO"
#L_logpath="/var/EBS/jp1/PEBSITO/log"
L_shellpath="/uspg/jp1/dx/shl/${L_envname}"
L_logpath="/var/EBS/jp1/${L_envname}/log"
#2014/08/05 MOD Ver.1.0.3 by Shota Takahashi END

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d"`
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"

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

### Argument Check ###
L_paracount=${#}

if [ ${#} -lt 3 ]
then
  output_log "Parameter Error"
  /usr/bin/cat <<-EOF 1>&2
  ${L_cmdname}
  MoveFileName
  MoveToFileDirectory
  BackupFileCount
  [EndFileName]
EOF
shell_end ${L_exit_eror}
fi

L_file_name=${1}
L_directory_name=${2}
L_backup_count=${3}
L_endfile_name=${4}

### Check file ###
output_log "Check Backup File START"

if [ ! -e ${L_file_name} ]
then
  output_log "Backup File is none"
  echo "${L_file_name} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check Backup File END"

### Check Backup Dir ###
output_log "Check Backup Dir START"

if [ ! -d ${L_directory_name} ]
then
  output_log "Backup Dir is none"
  echo "${L_directory_name} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check Backup Dir END"

### Check End file ###
output_log "Check End File START"

if [ "${L_endfile_name}" != "" ] && [ ! -e ${L_endfile_name} ]
then
  output_log "End File is none"
  echo "${L_endfile_name} does not exist" 1>&2
  shell_end ${L_exit_eror}
fi

output_log "Check End File END"

### Delete Old File ###
output_log "Deleting File START"

L_count=0

#2008/06/24 y.suzuki Changed
#for L_dirlist in `ls -rl ./backup/ | awk '$9 !~ /aaa/ && $1 ~ /-/ {print $9}'`
for L_dirlist in `ls -rl ${L_directory_name}/ | awk '$9 !~ /aaa/ && $1 ~ /-/ {print $9}'`
do
  L_count=`expr $L_count + 1`
  if [ ${L_count} -ge ${L_backup_count} ]
  then
    output_log "${L_dirlist} was deleted!"
#2008/06/24 y.suzuki Changed
#    rm "./backup/${L_dirlist}"
    rm "${L_directory_name}/${L_dirlist}"
    echo "${L_dirlist} : Delete!"
  fi
done

output_log "Deleting File END"

### Move and Rename File ###
output_log "Move and Rename File START"

L_new_file_name=`date +"%Y%m%d%H%M%S.csv"`
mv ${L_file_name} "${L_directory_name}/${L_new_file_name}"

output_log "Move and Rename File END"

### Delete EOF ###
output_log "Deleting End File START"

if [ "${L_endfile_name}" != "" ]
then
  output_log "${L_endfile_name} was deleted!"
  rm ${L_endfile_name}
  echo "${L_endfile_name} : Delete!"
fi

output_log "Deleting End File END"

### Shell end ###
shell_end $L_exit_norm
