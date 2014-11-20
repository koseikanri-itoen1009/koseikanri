#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : CAZZMVREFRESH                                             ##
## Description      : �}�e���A���C�Y�h�r���[���t���b�V���@�\                    ##
## MD.070           : MD070_IPO_COP_�V�F��                                      ##
## Version          : 1.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1      �}�e���A���C�Y�h�r���[��                                            ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2010/10/13    1.0   S.Niki           �V�K�쐬                               ##
##                                                                              ##
##################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

# ���ˑ��l
L_logpath="/var/log/jp1/T4"                     #���O�t�@�C���p�X

C_return_norm=0                                 #����I��
C_return_error=8                                #�ُ�I��
C_oracle_user="apps"                            #Oracle���[�U
C_oracle_path="apps"                            #Oracle�p�X

# �v���O�������
L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`

# ����
C_date=$(/bin/date "+%Y%m%d%H%M%S") #��������
L_execdate=`/bin/date "+%Y%m%d"`    #������

L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"
L_envfile=${L_cmddir}/CAZZAPPS.env  #CA���ʊ��ݒ�t�@�C��

#===============================================================================
# Description : ���O�o�͏���
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       ���O�t�@�C���֏o�͂�����e
#===============================================================================
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}
#===============================================================================
#                                   Main                                     
#===============================================================================
output_log "Materialized View Refresh Start"

# CA����ENV�t�@�C���ǂݍ���
if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading CA Env File was Completed"
else
  output_log "Reading CA Env File was Failed"
  output_log "Materialized View Refresh Error End"
  exit ${C_return_error}
fi

# �S�̋���ENV�t�@�C���ǂݍ���
if [ -r ${L_appsora} ]
then
  . ${L_appsora}
  output_log "Reading APPS Env File was Completed"
else
  output_log "Reading APPS Env File was Failed"
  output_log "Materialized View Refresh Error End"
  exit ${C_return_error}
fi

#�����`�F�b�N
if [ ${#} -ne 1 ]
then
  output_log "Parameter Error"
  RET_CODE=${C_return_error}
else
  #�}�e���A���C�Y�h�r���[���Z�b�g
  L_materialized_view_name="${1}"    #�`�F�b�N�Ώۂ̃t�@�C���p�X
  
  #���t���b�V��SQL���s
  sqlplus -s ${C_oracle_user}/${C_oracle_path} <<SQLEND >> ${L_logfile}
SET SERVEROUTPUT ON
SET FEEDBACK OFF
VARIABLE refresh_retcode NUMBER;
BEGIN
  DBMS_MVIEW.REFRESH('${L_materialized_view_name}','c');
  :refresh_retcode  := ${C_return_norm};
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE( SQLERRM );
    :refresh_retcode  := ${C_return_error};
END;
/
EXIT :refresh_retcode;
SQLEND

  #SQL�߂�l�Z�b�g
  RET_CODE=`echo $?`
fi

if [ ${RET_CODE} -eq ${C_return_norm} ]
then
  output_log "Materialized View Refresh Normal End"
else
  output_log "Materialized View Refresh Error End"
fi

#�I������
exit ${RET_CODE}

