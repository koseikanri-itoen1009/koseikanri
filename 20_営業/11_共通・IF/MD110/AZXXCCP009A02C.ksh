#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : AZXXCCP009A02C                                            ##
## Description      : �Ό��V�X�e���W���u�󋵍X�V����                            ##
## MD.050           : �Ό��V�X�e���W���u�󋵍X�V���� <MD050_CCP_009_A02>        ##
## Version          : 1.5                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
## $1       �������t�v��ID                                                      ##
## $2       �X�V�X�e�[�^�X                                                      ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/05    1.0   Koji.Oomata      �V�K�쐬                               ##
##  2009/03/04    1.1   Koji.Oomata      [��QCOS_138]                          ##
##                                         APPSORA.env�Ǎ������ǉ�              ##
##                                         CONCSUB�v���҂����ԕύX              ##
##                                           (�f�t�H���g60�b��15�b)             ##
##                                         ���O�o�͕��@�ύX                     ##
##                                         ���̓p�����[�^�K�{�`�F�b�N�ǉ�       ##
##                                         �t�@�C�����ύX (AXXXCCP009A02C.sh    ##
##                                                         ��AZXXCCP009A02C.ksh)##
##                                         �ύX�����̃t�H�[�}�b�g�ύX           ##
##  2009/04/01    1.2   Masayuki.Sano    ��ʋN���W���u�l�b�g�̑��d����Ή�     ##
##                                         �O���V�F�����ύX�Ή�                 ##
##  2009/06/17    1.3   Shigeto.Niki     [PT�P�̐��\�t�B�[�h�o�b�N]             ##
##                                         CONCSUB�v���҂����ԕύX              ##
##                                           (�f�t�H���g15�b��1�b)              ##
##  2009/11/23    1.4   Shigeto.Niki     ���O�o�͐�C��                         ##
##  2014/08/05    1.5   Shota.Takahashi  ���v���[�X_00004�Ή�                   ##
##################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################
L_resp_appl="XXCCP"                  #�E�ӁF�A�v���P�[�V�����Z�k��
L_resp_name="JP1SALES"               #�E�Ӗ�
L_user_name="JP1SALES"               #���[�U��
L_conc_appl="XXCCP"                  #�R���J�����g�F�A�v���P�[�V�����Z�k��
L_conc_name="XXCCP009A02C"           #�R���J�����g�F�v���O�����Z�k��
# 2009/03/04 Ver.1.1 Koji.Oomata add START

# 2014/08/05 Ver.1.5 Shota.Takahashi add START
L_envname=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #�V�F���̊i�[�f�B���N�g��
# 2014/08/05 Ver.1.5 Shota.Takahashi add END

# 2009/11/23 Ver.1.4 Shigeto.Niki mod START
#L_logpath="/var/tmp/jp1/log"
# 2014/08/05 Ver.1.5 Shota.Takahashi mod START
#L_logpath="/var/log/jp1/PEBSITO"
L_logpath="/var/log/jp1/${L_envname}"                             #���O�t�@�C���p�X
# 2014/08/05 Ver.1.5 Shota.Takahashi mod END
# 2009/11/23 Ver.1.4 Shigeto.Niki mod END

L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`
L_execdate=`/bin/date "+%Y%m%d%H%M%S"`

#���O�t�@�C�� (������I���̏ꍇ �폜)
# �t�@�C����: AZXXCCP009A02C_(�z�X�g��)_(�������t�v��ID)_yyyymmddhh24miss_(�v���Z�XID).log
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${1}_${L_execdate}_$$.log"

#�O���V�F��
# 2009/03/04 Ver.1.2 Masayuki.Sano add START
#L_envfile=${L_cmddir}/AZBZZAPPS.env
L_envfile=${L_cmddir}/AZZZAPPS.env
# 2009/03/04 Ver.1.2 Masayuki.Sano add END
#�I���X�e�[�^�X
C_ret_code_err=8
C_ret_code_normal=0

################################################################################
##                                 �֐���`                                   ##
################################################################################
### ���O�폜���� ###
log_delete()
{
  if [ -f ${L_logfile} ]
  then
    rm ${L_logfile}
  fi
}

### ���O�o�͏��� ###
output_log()
{
  echo `date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_logfile}
}

################################################################################
##                                   Main                                     ##
################################################################################
#���̓p�����[�^�`�F�b�N
if [ -z "${1}" ]
then
  output_log "Parameter Error  parameter1:${1} / parameter2:${2}"
  exit ${C_ret_code_err}
fi
if [ -z "${2}" ]
then
  output_log "Parameter Error  parameter1:${1} / parameter2:${2}"
  exit ${C_ret_code_err}
fi

#�O���V�F���̓Ǎ���
output_log "Reading Shell Env File START"

if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading Shell Env File was Completed"
else
  output_log "Reading Shell Env File was Failed (${L_envfile})"
  exit ${C_ret_code_err}
fi

output_log "Reading Shell Env File END"

#ENV�t�@�C���̓Ǎ���
output_log "Reading APPS Env File START"

if [ -r ${L_appsora} ]
then
  . ${L_appsora}
  output_log "Reading APPS Env File was Completed"
else
  output_log "Reading APPS Env File was Failed (${L_appsora})"
  exit ${C_ret_code_err}
fi

output_log "Reading APPS Env File END"

# 2009/03/04 Ver.1.1 Koji.Oomata add END

L_pk_request_id_val=$1               #�������t�v��ID
L_status_code=$2                     #�X�V�X�e�[�^�X

#concsub�p�����[�^�ҏW
L_conc_args="APPS/APPS"
L_conc_args="${L_conc_args} \"${L_resp_appl}\""
L_conc_args="${L_conc_args} \"${L_resp_name}\""
L_conc_args="${L_conc_args} \"${L_user_name}\""

# 2009/06/17 Ver.1.3 Shigeto.Niki mod START
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
#L_conc_args="${L_conc_args} WAIT=15 CONCURRENT"
L_conc_args="${L_conc_args} WAIT=1 CONCURRENT"
# 2009/03/04 Ver.1.1 Koji.Oomata mod END
# 2009/06/17 Ver.1.3 Shigeto.Niki mod END

L_conc_args="${L_conc_args} \"${L_conc_appl}\""
L_conc_args="${L_conc_args} \"${L_conc_name}\""

NLS_LANG=Japanese_Japan.JA16SJIS
export NLS_LANG

#�N���ΏۃR���J�����g�̃p�����[�^�ҏW
L_param_args="\"${L_pk_request_id_val}\" \"${L_status_code}\""

#�R���J�����g�N��
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#${FND_TOP}/bin/CONCSUB ${L_conc_args} ${L_param_args}
output_log "Execute CONCSUB START"
${FND_TOP}/bin/CONCSUB ${L_conc_args} ${L_param_args} >>${L_logfile}

# 2009/03/04 Ver.1.1 Koji.Oomata mod END
L_return_code=${?}
if [ ${L_return_code} -ne 0 ]
then
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#  echo "Executing CONCSUB was Failed"
#  L_return_code=8
  output_log "Executing CONCSUB was Failed"
  exit ${C_ret_code_err}
# 2009/03/04 Ver.1.1 Koji.Oomata mod END
fi
# 2009/03/04 Ver.1.1 Koji.Oomata mod START
#echo "Execute CONCSUB END"
#exit ${L_return_code}
log_delete
exit ${C_ret_code_normal}
# 2009/03/04 Ver.1.1 Koji.Oomata mod END
