#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZEXINBOUND                                             ##
## Description      : EDI�V�X�e���pI/F�A�g�@�\�iINBOUND)                        ##
## MD.070           : MD070_IPO_CCP_�V�F��                                      ##
## Version          : 1.10                                                      ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1       �f�[�^��R�[�h                                                     ##
##  $2�`36   �R���J�����g����1�`35                                              ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/27    1.0   Masayuki.Sano    �V�K�쐬                               ##
##  2009/02/18    1.1   Masayuki.Sano    �����e�X�g����s���Ή�                 ##
##                                       �NAS�T�[�o�f�B���N�g���擾���@�ύX     ##
##                                        �ɔ����Ή�                            ##
##  2009/02/23    1.2   Masayuki.Sano    �����e�X�g����s���Ή�                 ##
##                                       ��p�����[�^�̃t�@�C���˃t���p�X�֕ύX  ##
##  2009/02/27    1.3   Masayuki.Sano    �����e�X�g����s���Ή�                 ##
##                                       �ESQL Loader��p�����ꍇ��             ##
##                                         �Ɩ��R���J�����g�̃p�����[�^�́@�@�@ ##
##                                         �t�@�C�����Ƀt���p�X���w��@�@�@�@�@ ##
##                                       �ESQL Loader��p�Ȃ��ꍇ�́@�@�@�@�@�@ ##
##                                         �Ɩ��R���J�����g�̃p�����[�^�́@�@�@ ##
##                                         �t�@�C�����̂ݎw��        �@�@�@�@�@ ##
##  2009/04/03    1.4   Masayuki.Sano    ��Q�ԍ�[T1-0286]                      ##
##                                       �E�����J�n����"AZBZZAPPS.env"�� �@�@�@ ##
##                                         �ǂݍ��ނ悤�ɏC���B                 ##
##  2009/04/06    1.5   Masayuki.Sano    ��Q�ԍ�[T1-0312]                      ##
##                                       �E�x���I����"4"�A�ُ�I����"8"�ɕύX   ##
##  2009/04/07    1.6   Masayuki.Sano    ��Q�ԍ�[T1-0377]                      ##
##                                       �E�N���ΏۃR���J�����g�̈�����ύX     ##
##  2009/04/15    1.7   Masayuki.Sano    ��Q�ԍ�[T1-0522]                      ##
##                                       �E�v��ID�̎擾���@�ύX                 ##
##                                       �E�v��ID�̎擾���s���A�ُ폈����ǉ�   ##
##  2009/06/17    1.8   Shigeto.Niki     ��Q�ԍ�[E_PT_00001]                   ##
##                                         CONCSUB�v���҂����ԕύX              ##
##                                           (�f�t�H���g60�b��1�b)              ##
##  2009/07/17    1.9   Shigeto.Niki     ��Q�ԍ�[E_T3_00341]                   ##
##                                         ���{��̃p�X�����擾����悤�C��   ##
##  2009/08/19    1.10  Masayuki.Sano    ��Q�ԍ�[0000835]                      ##
##                                         �ꎞ�t�@�C�����ύX                   ##
##                                                                              ##
##################################################################################
                                                                                
#���{�ԃv���O����

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

C_appl_name="XXCCP"           #�A�v���P�[�V�����Z�k��
C_program_id="ZBZZEXINBOUND"  #�v���O����ID
L_logpath="/var/log/jp1/T3"   #���O�t�@�C���p�X[���ˑ��l]
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
L_tmppath="/var/tmp"          #�ꎞ�t�@�C���p�X[���ˑ��l]
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START

# �߂�l
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 Start
C_ret_code_norm=0     #����I��
#C_ret_code_warn=3     #�x���I��
#C_ret_code_eror=7     #�ُ�I��
C_ret_code_warn=4     #�x���I��
C_ret_code_eror=8     #�ُ�I��
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 End

# ����
C_date=$(/bin/date "+%Y%m%d%H%M%S") #��������
L_execdate=`/bin/date "+%Y%m%d"`    #������

# �v���O�������
L_cmd=${0}
L_cmdname=`/bin/basename ${L_cmd}`
L_cmddir=`/bin/dirname ${L_cmd}`
L_hostname=`/bin/hostname`

#�O���V�F��(�ݒ�֘A)�p�X
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#L_envfile=${L_cmddir}/AZBZZAPPS.env
L_envfile=${L_cmddir}/ZBZZAPPS2.env
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

#���O�t�@�C���֘A
L_logfile="${L_logpath}/"`/bin/basename ${L_cmdname} .ksh`"_${L_hostname}_${L_execdate}.log"

# 2009/08/19 Ver1.10 Mod START
##�ꎞ�t�@�C��
##2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
##L_tmpbase=/var/tmp/${L_cmdname}.$$
#L_tmpbase="${L_tmppath}/${L_cmdname}.$$"
##2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
#L_std_out=${L_tmpbase}.stdout
#L_err_out=${L_tmpbase}.errout
#L_path_ou_sldr="${L_tmpbase}.${C_date}.ctl"
#L_path_sql_log="${L_tmpbase}.${C_date}.log"
##2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
##SQL-Loader���O�t�@�C���p�X
#L_path_log_sldr="/var/tmp/`/bin/basename ${L_cmdname} .ksh`_$$_${C_date}.log"
#�ꎞ�t�@�C���ꗗ
L_tmpbase="${L_cmdname}.${C_date}.$$"
L_std_out=${L_tmppath}/${L_tmpbase}.stdout.tmp        #�ꎞ�t�@�C���i����j
L_err_out=${L_tmppath}/${L_tmpbase}.errout.tmp        #�ꎞ�t�@�C���i�ُ�j
L_path_sql_log="${L_tmppath}/${L_tmpbase}.log.tmp"    #�ꎞ�t�@�C���iSQL�֘A)
L_path_ou_sldr="${L_tmppath}/${L_tmpbase}.ctl.tmp"    #SQL-Loader����t�@�C��
# 2009/08/19 Ver1.10 Mod End
#�G���[���b�Z�[�W�ꗗ
C_log_msg_00001="Parameter Error"
C_log_msg_00002="�ݒ���̒l���s���ł��B�i�A�v���P�[�V�����Z�k��(�E��)�j"
C_log_msg_00003="�ݒ���̒l���s���ł��B�i�E�Ӗ��j"
C_log_msg_00004="�ݒ���̒l���s���ł��B�i���[�U���j"
C_log_msg_00005="�ݒ���̒l���s���ł��B�i�A�v���P�[�V�����Z�k��(�R���J�����g)�j"
C_log_msg_00006="�ݒ���̒l���s���ł��B�i�R���J�����g�Z�k���j"
C_log_msg_00007="�ݒ���̒l���s���ł��B�i�I�u�W�F�N�g�f�B���N�g����(NAS�T�[�o)�j"
C_log_msg_00008="�ݒ���̒l���s���ł��B�i���[�J���T�[�o�f�B���N�g���p�X�j"
C_log_msg_00009="�ݒ���̒l���s���ł��B�i�ޔ��f�B���N�g���p�X�j"
C_log_msg_00010="�ݒ���̒l���s���ł��B�i���㐔�j"
C_log_msg_00011="�ݒ���̒l���s���ł��B�iSQL���s�t���O�j"
C_log_msg_00012="�ݒ���̒l���s���ł��B�iSQL-Loader����t�@�C���p�X�j"
C_log_msg_00013="�ݒ���̒l���s���ł��B�i���[�N�e�[�u�����j"
C_log_msg_00014="�ݒ���̒l���s���ł��B�i�폜SQL�����敪�j"
C_log_msg_00015="NAS�T�[�o�f�B�����N�g���p�X���擾�ł��܂���ł����B"
C_log_msg_00016="NAS�T�[�o�Ɏ��s�Ώۂ̃t�@�C�������݂��܂��B"
C_log_msg_00017="NAS�T�[�o�ւ�I/F�t�@�C���̃R�s�[�Ɏ��s���܂����B"
C_log_msg_00018="���[�J���T�[�o����I/F�t�@�C���̍폜�Ɏ��s���܂����B"
C_log_msg_00019="SQL-Loader�̎��s�Ɏ��s���܂����B"
C_log_msg_00020="NAS�T�[�o����I/F�t�@�C���̍폜�Ɏ��s���܂����B"
C_log_msg_00021="���[�N�e�[�u���̃f�[�^�폜�Ɏ��s���܂����B"
C_log_msg_00022="IF�t�@�C���ޔ��f�B���N�g���ւ̈ړ��Ɏ��s���܂����B"
C_log_msg_00023="�ޔ��f�B���N�g�����̃o�b�N�A�b�v�t�@�C���̍폜�Ɏ��s���܂����B"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START

################################################################################
##                                 �֐���`                                   ##
################################################################################

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
# Description : �I������
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       ���^�[���E�R�[�h
#===============================================================================
shell_end()
{
  if [ -f ${L_std_out} ]
  then
    rm ${L_std_out}
  fi
  if [ -f ${L_err_out} ]
  then
    rm ${L_err_out}
  fi
  L_retcode=${1:-0}
  output_log "`/bin/basename ${0}` END  END_CD="${L_retcode}
  return ${L_retcode}
}

#===============================================================================
# Description : EBS�R���J�����g���N������B
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       �E�ӃA�v���P�[�V�����Z�k��
#  $2       �E�Ӗ�
#  $3       APPS���[�U��
#  $4       �R���J�����g�A�v���P�[�V�����Z�k��
#  $5       �R���J�����g�v���O������
#  $6�`$41  �R���J�����g�p�����[�^ ���ő�35��
#===============================================================================
AZBZZEXECONCSUB()
{
#2009/04/03 DELETE BY Masayuki.Sano Ver.1.4 Start
#  #���O�t�@�C���̍ŏI�A�N�Z�X�����ƍŏI�X�V�������������ɍX�V
#  touch ${L_logfile}
#  output_log "`/bin/basename ${0}` START"
#
#  #----------------------------------------------------------------------------
#  #EBS�֘A�̒�`�����擾
#  #----------------------------------------------------------------------------
#  #�E�ӂȂǂ̃f�t�H���g�l���擾
#  #�E���s�t�@�C�������݂��Ȃ��˖߂�l(7)���Z�b�g���ď����I��
#  output_log "Reading Shell Env File START"
#  if [ -r ${L_envfile} ]
#  then
#    . ${L_envfile}
#    output_log "Reading Shell Env File was Completed"
#  else
#    output_log "Reading Shell Env File was Failed"
#    shell_end ${C_ret_code_eror}
#    return ${?}
#  fi
#  output_log "Reading Shell Env File END"
#
#  #EBS�֘A�̒�`�����擾
#  #�E���s�t�@�C�������݂��Ȃ��˖߂�l(7)���Z�b�g���ď����I��
#  output_log "Reading APPS Env File START"
#  if [ -r ${L_appsora} ]
#  then
#    . ${L_appsora}
#    output_log "Reading APPS Env File was Completed"
#  else
#    output_log "Reading APPS Env File was Failed"
#    shell_end ${C_ret_code_eror}
#    return ${?}
#  fi
#  output_log "Reading APPS Env File END"
#2009/04/03 DELETE BY Masayuki.Sano Ver.1.4 End

  #----------------------------------------------------------------------------
  #�R���J�����g�iI/F�t�@�C���̃w�b�_�E�t�b�^�폜�A�Ɩ��p�R���J�����g�j�����s
  #----------------------------------------------------------------------------
  #�p�����[�^�����`�F�b�N
  #�E5�����ˈُ�I���̖߂�l�i7�j���Z�b�g���āA�����I��
  L_paracount=${#}

  if [ $L_paracount -lt 5 ]
  then
    output_log "Parameter Error"
    /usr/bin/cat <<-EOF 1>&2
    ${L_cmdname}
    Responsibility_Application_Short_Name
    Responsibility_Name
    User_name
    Concurrent_Program_Application_Short_Name
    Concurrent_Program_Name
    [Concurrent_Program_Arguments]
EOF
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    shell_end ${C_ret_code_eror}
#    return ${?}
    return ${C_ret_code_eror}
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano END
  fi

  #���̓p�����[�^����R���J�����g�����擾
  L_para_appl=${1}  # �E�ӂ̃A�v���P�[�V�����Z�k��
  L_para_resp=${2}  # �E�Ӗ�
  L_para_user=${3}  # APP���[�U��
  L_conc_appl=${4}  # �R���J�����g�̃A�v���P�[�V�����Z�k��
  L_conc_name=${5}  # �R���J�����g�Z�k��
  shift 5

  #�E�ӂ̃A�v���P�[�V�����Z�k���A�E�Ӗ��AAPP���[�U���������͂̏ꍇ�A�f�t�H���g�l��ݒ�
  #(�E�ӂ̃A�v���P�[�V�����Z�k��)
  if [ "${L_para_appl}" != \"\" ]
  then
    L_resp_appl=${L_para_appl}
  else
    L_resp_appl=${L_def_appl}
  fi
  #(�E�Ӗ�)
  if [ "${L_para_resp}" != \"\" ]
  then
    L_resp_name=${L_para_resp}
  else
    L_resp_name=${L_def_resp}
  fi
  #(APP���[�U��)
  if [ "${L_para_user}" != \"\" ]
  then
    L_user_name=${L_para_user}
  else
    L_user_name=${L_def_user}
  fi

  #SUBCONC�����{���邽�߂̃p�����[�^���Z�b�g����B
  L_conc_args="APPS/APPS"
  L_conc_args="${L_conc_args} \"${L_resp_appl}\""
  L_conc_args="${L_conc_args} \"${L_resp_name}\""
  L_conc_args="${L_conc_args} \"${L_user_name}\""

  # 2009/06/17 Ver.1.8 Shigeto.Niki mod START
  #L_conc_args="${L_conc_args} WAIT=Y CONCURRENT"
  L_conc_args="${L_conc_args} WAIT=1 CONCURRENT"
  # 2009/06/17 Ver.1.8 Shigeto.Niki mod END

  L_conc_args="${L_conc_args} \"${L_conc_appl}\""
  L_conc_args="${L_conc_args} \"${L_conc_name}\""

  #����R�[�h����{��ɕύX
  NLS_LANG=Japanese_Japan.JA16SJIS
  export NLS_LANG

  #SUBCONC(EBS�R���J�����g���N�����邽�߂̃v���O����)���N��
  #�E�p�����[�^�s���ɂ��ُ�I���ˈُ�I���̖߂�l�i7�j���Z�b�g���āA�����I��
  output_log "Execute CONCSUB START"
  ${FND_TOP}/bin/CONCSUB ${L_conc_args} ${@+"$@"} >${L_std_out} 2>${L_err_out}

  L_return_code=${?}

  if [ ${L_return_code} -ne 0 ]
  then
    output_log "Executing CONCSUB was Failed"
    /usr/bin/cat <<-EOF 1>&2
    ${L_cmdname} SYSTEM ERROR. CONCSUB ABORT.
    Return Code: ${L_return_code}
EOF
    /usr/bin/cat ${L_std_out} ${L_err_out} 1>&2
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    shell_end ${C_ret_code_eror}
#    return ${?}
    return ${C_ret_code_eror}
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano END
  fi

  #----------------------------------------------------------------------------
  #SUBCONC�̕W���o�͂���A�v��ID���擾
  #----------------------------------------------------------------------------
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#  if [ $L_paracount = 5 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $5}' ${L_std_out}`   # �R���J�����g�p�����[�^���F0
#  elif [ $L_paracount = 6 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $6}' ${L_std_out}`   # �R���J�����g�p�����[�^���F1
#  elif [ $L_paracount = 7 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $7}' ${L_std_out}`   # �R���J�����g�p�����[�^���F2
#  elif [ $L_paracount = 8 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $8}' ${L_std_out}`   # �R���J�����g�p�����[�^���F3
#  elif [ $L_paracount = 9 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $9}' ${L_std_out}`   # �R���J�����g�p�����[�^���F4
#  elif [ $L_paracount = 10 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $10}' ${L_std_out}`  # �R���J�����g�p�����[�^���F5
#  elif [ $L_paracount = 11 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $11}' ${L_std_out}`  # �R���J�����g�p�����[�^���F6
#  elif [ $L_paracount = 12 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $12}' ${L_std_out}`  # �R���J�����g�p�����[�^���F7
#  elif [ $L_paracount = 13 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $13}' ${L_std_out}`  # �R���J�����g�p�����[�^���F8
#  elif [ $L_paracount = 14 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $14}' ${L_std_out}`  # �R���J�����g�p�����[�^���F9
#  elif [ $L_paracount = 15 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $15}' ${L_std_out}`  # �R���J�����g�p�����[�^���F10
#  elif [ $L_paracount = 16 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $16}' ${L_std_out}`  # �R���J�����g�p�����[�^���F11
#  elif [ $L_paracount = 17 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $17}' ${L_std_out}`  # �R���J�����g�p�����[�^���F12
#  elif [ $L_paracount = 18 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $18}' ${L_std_out}`  # �R���J�����g�p�����[�^���F13
#  elif [ $L_paracount = 19 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $19}' ${L_std_out}`  # �R���J�����g�p�����[�^���F14
#  elif [ $L_paracount = 20 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $20}' ${L_std_out}`  # �R���J�����g�p�����[�^���F15
#  elif [ $L_paracount = 21 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $21}' ${L_std_out}`  # �R���J�����g�p�����[�^���F16
#  elif [ $L_paracount = 22 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $22}' ${L_std_out}`  # �R���J�����g�p�����[�^���F17
#  elif [ $L_paracount = 23 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $23}' ${L_std_out}`  # �R���J�����g�p�����[�^���F18
#  elif [ $L_paracount = 24 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $24}' ${L_std_out}`  # �R���J�����g�p�����[�^���F19
#  elif [ $L_paracount = 25 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $25}' ${L_std_out}`  # �R���J�����g�p�����[�^���F20
#  elif [ $L_paracount = 26 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $26}' ${L_std_out}`  # �R���J�����g�p�����[�^���F21
#  elif [ $L_paracount = 27 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $27}' ${L_std_out}`  # �R���J�����g�p�����[�^���F22
#  elif [ $L_paracount = 28 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $28}' ${L_std_out}`  # �R���J�����g�p�����[�^���F23
#  elif [ $L_paracount = 29 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $29}' ${L_std_out}`  # �R���J�����g�p�����[�^���F24
#  elif [ $L_paracount = 30 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $30}' ${L_std_out}`  # �R���J�����g�p�����[�^���F25
#  elif [ $L_paracount = 31 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $31}' ${L_std_out}`  # �R���J�����g�p�����[�^���F26
#  elif [ $L_paracount = 32 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $32}' ${L_std_out}`  # �R���J�����g�p�����[�^���F27
#  elif [ $L_paracount = 33 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $33}' ${L_std_out}`  # �R���J�����g�p�����[�^���F28
#  elif [ $L_paracount = 34 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $34}' ${L_std_out}`  # �R���J�����g�p�����[�^���F29
#  elif [ $L_paracount = 35 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $35}' ${L_std_out}`  # �R���J�����g�p�����[�^���F30
#  elif [ $L_paracount = 36 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $36}' ${L_std_out}`  # �R���J�����g�p�����[�^���F31
#  elif [ $L_paracount = 37 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $37}' ${L_std_out}`  # �R���J�����g�p�����[�^���F32
#  elif [ $L_paracount = 38 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $38}' ${L_std_out}`  # �R���J�����g�p�����[�^���F33
#  elif [ $L_paracount = 39 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $39}' ${L_std_out}`  # �R���J�����g�p�����[�^���F34
#  elif [ $L_paracount = 40 ]
#  then
#    L_reqid=`/usr/bin/awk 'NR==1 {print $40}' ${L_std_out}`  # �R���J�����g�p�����[�^���F35
#  else
#    L_reqid=""
#  fi
  # �v��ID�̎擾
  L_reqid=`/usr/bin/awk 'NR==1 {print $3}' ${L_std_out}`
  # �v��ID�̃`�F�b�N
  if [ "$(echo ${L_reqid} | egrep '^[0-9]+$')" = "" ]
  then
    output_log "Getting RequestID was Failed(RequestID : ${L_reqid} )"
    return ${C_ret_code_eror}
  fi
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

  L_out_all=`/usr/bin/awk '{print $0}' ${L_std_out}`
  output_log "RequestID : ${L_reqid}"

  output_log "Execute CONCSUB END"

  #----------------------------------------------------------------------------
  #�v��ID���L�[��"�X�e�[�^�X�E�R�[�h"���擾
  #�X�e�[�^�X�E�R�[�h���`�F�b�N("C":���� "G":�x�� "���L�ȊO"�F�ُ�)
  #----------------------------------------------------------------------------
  #�R���J�����g�̏ڍ׏��i�X�e�[�^�X�R�[�h��)���擾����SQL�̎��s(�L�[:�v��ID)
# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END
  output_log "Getting Concurrent Status START"
  sqlplus -s apps/apps <<SQLEND >${L_std_out}
  SET HEADING OFF
  SELECT request_id, phase_code, status_code
  FROM fnd_concurrent_requests
  WHERE request_id = '${L_reqid}';
  EXIT
SQLEND
  #���s���ʂ���R���J�����g�̏ڍ׏��i�X�e�[�^�X�R�[�h��)���擾
  L_get_req_id=`/usr/bin/awk '( $0 != "" ){print $1}' ${L_std_out}`
  L_phase_code=`/usr/bin/awk '( $0 != "" ){print $2}' ${L_std_out}`
  L_status_code=`/usr/bin/awk '( $0 != "" ){print $3}' ${L_std_out}`

  output_log RequestID : $L_get_req_id Phase_Code : $L_phase_code Status Code : $L_status_code

  output_log "Getting Concurrent Status END"

  #�X�e�[�^�X�E�R�[�h���`�F�b�N
  #     "C"�F����(Normal)
  #�@�@ "G"�F�x��(Warning)
  #��L�ȊO�F�ُ�(Other(Error/Unknown))
  case ${L_status_code} in
  C)
    # Normal
    output_log "Concurrent Status was normal"
    L_exit_status=$C_ret_code_norm
    ;;
  G)
    # Warning
    output_log "Concurrent Status was warning"
    L_exit_status=$C_ret_code_warn
    ;;
  *)
    # Other(Error/Unknown)
    output_log "Concurrent Status was error"
    L_exit_status=$C_ret_code_eror
    ;;
  esac

  ### Shell end ###
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#  shell_end $L_exit_status
#  return ${?}
  return ${L_exit_status}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

}
#===============================================================================
# Description : �ݒ���̎擾(�f�[�^�x�[�X����ݒ�����擾��A
#             : �������l���`�F�b�N���s���B
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.      Description
# -------- ----------------------------------------------------------
#   $1     �f�[�^��R�[�h
#===============================================================================
FLEX_VALUES_GET()
{
  #----------------------------------------------------------------------------
  # 1) �{�V�F���Ŏg�p����ݒ�����擾���܂��B
  #----------------------------------------------------------------------------
# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END
  sqlplus -s apps/apps <<GETSQL > ${L_std_out}
    SET HEADING OFF
    SET TRIMSPOOL ON
    SET FEEDBACK OFF
    SELECT ffva.flex_value || ',' || ffva.description
    FROM   fnd_flex_values_vl ffva
          ,fnd_flex_vset_v    ffvs
    WHERE  ffvs.flex_value_set_id = ffva.flex_value_set_id  
    AND    ffvs.parent_value_set_name = 'XXCCP1_IF_CONF_PARA'
    AND    ffva.flex_value IN ('${1}_arg_001','${1}_arg_002','${1}_arg_003',
                               '${1}_arg_004','${1}_arg_005','${1}_arg_006',
                               '${1}_arg_007','${1}_arg_008','${1}_arg_009',
                               '${1}_arg_010','${1}_arg_011','${1}_arg_012',
                               '${1}_arg_013')
    AND    SYSDATE BETWEEN NVL(ffva.start_date_active, SYSDATE)
                       AND NVL(ffva.end_date_active,   TO_DATE('9999/12/31','YYYY/MM/DD'))
    AND    ffva.enabled_flag='Y'
    ;
    EXIT
GETSQL

  #----------------------------------------------------------------------------
  #2) ��LSQL�̎��s���ʂ���V�F���̐ݒ�����擾���܂��B
  #----------------------------------------------------------------------------
  G_resp_app_name=`sed -n "s/${1}_arg_001,//p" "${L_std_out}"`          #�E�ӃA�v���P�[�V�����Z�k��
  G_resp_name=`sed -n "s/${1}_arg_002,//p" "${L_std_out}"`              #�E�Ӗ�
  G_user_name=`sed -n "s/${1}_arg_003,//p" "${L_std_out}"`              #APPS���[�U��
  G_con_app_name=`sed -n "s/${1}_arg_004,//p" "${L_std_out}"`           #�R���J�����g�A�v���P�[�V�����Z�k��
  G_con_name=`sed -n "s/${1}_arg_005,//p" "${L_std_out}"`               #�R���J�����g��
#2009/02/18 UPDATE BY M.Sano �����e�X�g����s���Ή� START
#  G_dire_nas=`sed -n "s/${1}_arg_006,//p" "${L_std_out}"`               #NAS�T�[�o�f�B���N�g��
  G_dir_name_nas=`sed -n "s/${1}_arg_006,//p" "${L_std_out}"`           #�I�u�W�F�N�g�f�B���N�g����(NAS�T�[�o)
#2009/02/18 UPDATE BY M.Sano �����e�X�g����s���Ή� END
  G_dire_san=`sed -n "s/${1}_arg_007,//p" "${L_std_out}"`               #SAN�T�[�o�f�B���N�g��
  G_drie_esc=`sed -n "s/${1}_arg_008,//p" "${L_std_out}"`               #�ޔ�p�f�B���N�g��
  G_gene_num=`sed -n "s/${1}_arg_009,//p" "${L_std_out}"`               #���㐔
  G_flag_sldr=`sed -n "s/${1}_arg_010,//p" "${L_std_out}"`              #SQL���s�t���O
  G_path_sldr=`sed -n "s/${1}_arg_011,//p" "${L_std_out}"`              #SQL-Loader����t�@�C���p�X
  G_del_tbl_name=`sed -n "s/${1}_arg_012,//p" "${L_std_out}"`           #���[�N�e�[�u����
  G_del_sql_type=`sed -n "s/${1}_arg_013,//p" "${L_std_out}"`           #�폜SQL�����敪

  #----------------------------------------------------------------------------
  #3) �ꎞ�t�@�C�����폜
  #----------------------------------------------------------------------------
  rm -f "${L_std_out}"

  #----------------------------------------------------------------------------
  #4) �擾�����f�[�^�����������͂��`�F�b�N���܂��B
  #----------------------------------------------------------------------------
  #�E�ӃA�v���P�[�V�����Z�k���̃`�F�b�N(�K�{�`�F�b�N)
  if [ "${G_resp_app_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00002}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #�E�Ӗ��̃`�F�b�N(�K�{�`�F�b�N)
  if [ "${G_resp_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00003}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #APPS���[�U���̃`�F�b�N(�K�{�`�F�b�N)
  if [ "${G_user_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00004}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #�R���J�����g�A�v���P�[�V�����Z�k���̃`�F�b�N(�K�{�`�F�b�N)
  if [ "${G_con_app_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00005}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #�R���J�����g���̃`�F�b�N(�K�{�`�F�b�N)
  if [ "${G_con_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00006}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
#2009/02/18 UPDATE BY M.Sano �����e�X�g����s���Ή� START
#  #NAS�T�[�o�f�B���N�g���̃`�F�b�N(�f�B���N�g�����݃`�F�b�N)
#  if [ ! -d "${G_dire_nas}" ]
#  then
#    return ${C_ret_code_eror}
#  fi
  #�I�u�W�F�N�g�f�B���N�g����(NAS�T�[�o)�̃`�F�b�N(�K�{�`�F�b�N)
  if [ "${G_dir_name_nas}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00007}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
#2009/02/18 ADD BY M.Sano �����e�X�g����s���Ή� END

  #SAN�T�[�o�f�B���N�g���̃`�F�b�N(�f�B���N�g�����݃`�F�b�N)
  if [ ! -d "${G_dire_san}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00008}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #�ޔ�p�f�B���N�g���̃`�F�b�N(�f�B���N�g�����݃`�F�b�N)
  if [ ! -d "${G_drie_esc}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00009}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #���㐔�̃`�F�b�N(���l�L���`�F�b�N)
  if [ "$(echo ${G_gene_num} | egrep '^[0-9]+$')" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00010}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #���㐔�̃`�F�b�N(�͈̓`�F�b�N)
  if [ ${G_gene_num} -lt 1 ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00010}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi
  #SQL���s�t���O�̃`�F�b�N("0"�܂���"1")
  if [ "${G_flag_sldr}" = "1" ] || [ "${G_flag_sldr}" = "0" ]
  then
  :
  else
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00011}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #SQL-Loader����t�@�C���p�X�̃`�F�b�N(�K�{�`�F�b�N ��SQL���s�t���O="1"�̏ꍇ�̂�)
  if [ "${G_flag_sldr}" = "1" ] && [ ! -f "${G_path_sldr}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00012}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #���[�N�e�[�u�����̃`�F�b�N(�K�{�`�F�b�N ��SQL���s�t���O="1"�̏ꍇ�̂�)
  if [ "${G_flag_sldr}" = "1" ] && [ "${G_del_tbl_name}" = "" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00013}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #�폜SQL�����敪�̃`�F�b�N("0"�܂���"1"  ��SQL���s�t���O="1"�̏ꍇ�̂�)
  if [ "${G_flag_sldr}" = "1" ]
  then
    if [ "${G_del_sql_type}" != "1" ] && [ "${G_del_sql_type}" != "0" ]
    then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
      output_log "${C_log_msg_00014}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      return ${C_ret_code_eror}
    fi
  fi

#2009/02/18 ADD BY M.Sano �����e�X�g����s���Ή� START

# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END
  #----------------------------------------------------------------------------
  #5) �{�V�F���Ŏg�p����f�B���N�g�������擾���܂��B
  #----------------------------------------------------------------------------
  #SQL�̎��s
  sqlplus -s apps/apps <<GETSQL >> ${L_std_out}
    SET HEADING OFF
    SET TRIMSPOOL ON
    SET FEEDBACK OFF
    SELECT 'nas_directory_path,' || adir.directory_path
    FROM   all_directories adir
    WHERE  adir.directory_name = '${G_dir_name_nas}'
    ;
    EXIT
GETSQL
  #NAS�T�[�o�f�B���N�g���̎擾
  G_dire_nas=`sed -n "s/nas_directory_path,//p" "${L_std_out}"`
  #�ꎞ�t�@�C���폜
  rm -f "${L_std_out}"

  #----------------------------------------------------------------------------
  #6) �擾�����f�B���N�g�������݂���f�B���N�g�����ǂ����`�F�b�N���s���܂��B
  #----------------------------------------------------------------------------
  if [ ! -d "${G_dire_nas}" ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.SanoSTART
    output_log "${C_log_msg_00015}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

#2009/02/18 ADD BY M.Sano �����e�X�g����s���Ή� END

  return ${C_ret_code_norm}
}
#===============================================================================
# Description : I/F�A�g�w�b�_�[�t�b�^�[�폜�R���J�����g���N��
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#   $1     �t�@�C����
#   $2     �V�X�e����
#   $3     �I�u�W�F�N�g�f�B���N�g����
#===============================================================================
XXCCP005A01C_EXECUTE()
{
  #�f�B���N�g�������擾����B
#2009/02/18 DELETE BY M.Sano �����e�X�g����s���Ή� START
#  L_nas_dir_name=`echo "${3}" | sed -e 's/^.*\///' | tr [a-z] [A-Z]`
#2009/02/18 DELETE BY M.Sano �����e�X�g����s���Ή� START

  #�������쐬
  L_ksh_para="${G_resp_app_name}"                   #�A�v���P�[�V�����Z�k��(�E��)
  L_ksh_para="${L_ksh_para} ${G_resp_name}"         #�E�Ӗ�
  L_ksh_para="${L_ksh_para} ${G_user_name}"         #���[�U��
  L_ksh_para="${L_ksh_para} XXCCP"                  #�A�v���P�[�V�����Z�k��(�R���J�����g)
  L_ksh_para="${L_ksh_para} XXCCP005A01C"           #�R���J�����g�Z�k��
  L_ksh_para="${L_ksh_para} \"${1}\""               #�t�@�C����
  L_ksh_para="${L_ksh_para} \"${2}\""               #�V�X�e����
#2009/02/18 UPDATE BY M.Sano �����e�X�g����s���Ή� START
#  L_ksh_para="${L_ksh_para} \"${L_nas_dir_name}\""  #�폜�f�B���N�g����
  L_ksh_para="${L_ksh_para} \"${3}\""               #�폜�f�B���N�g����
#2009/02/18 UPDATE BY M.Sano �����e�X�g����s���Ή� END
  #EBS���ʃR���J�����g�N���V�F���o�R�Ńw�b�_�[�t�b�^�[�폜�R���J�����g���s
  AZBZZEXECONCSUB ${L_ksh_para}
  return ${?}

}

#===============================================================================
# Description : SQL-Loader�����s����B(�Ώۃf�[�^�FI/F�t�@�C��(NAS))
#===============================================================================
SQL_LOADER_EXECUTE()
{
  #"???????????"��I/F�t�@�C���p�X�֒u�� ���ʂ͈ꎞ�t�@�C���֊i�[
  G_path_nas_tmp=`echo "${G_path_nas}" | sed 's/\\//\\\\\\//g'`
  sed -e 's/\?\?\?\?\?\?\?\?\?\?\?/'"${G_path_nas_tmp}"'/g' "${G_path_sldr}" > "${L_path_ou_sldr}"

# 2009/08/19 Ver1.10 Add START
  #SQL-Loader���s���O�̃p�X���擾
  L_path_log_sldr="${L_tmppath}/${G_base_if}_${C_date}_$$.log.tmp"
# 2009/08/19 Ver1.10 Add End

  #SQL-Loader���s
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#  sqlldr userid=apps/apps control="${L_path_ou_sldr}" errors=0 > "${L_path_sql_log}"
#  L_ret_code=${?}
# 2009/08/19 Ver1.10 Del START
#  #(SQL-Loader���s���O�̃p�X���擾)
#  L_path_log_sldr="${L_tmppath}/${G_base_if}_${C_date}.log"
# 2009/08/19 Ver1.10 Del END
  sqlldr userid=apps/apps control="${L_path_ou_sldr}" log="${L_path_log_sldr}" errors=0 > ${L_path_sql_log} 2>${L_err_out}
  L_ret_code=${?}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END

#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  #SQL-Loader�������������ǂ����`�F�b�N���s�Ȃ��B
  #������ �� SQL-Loader���O�t�@�C�����폜
  #���s�� �� ���O�t�@�C���ɃG���[���b�Z�[�W���o�́B
  if [ ${L_ret_code} -eq 0 ]
  then
    rm -f "${L_path_log_sldr}"
  else
    output_log "${C_log_msg_00019}"
  fi
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END

  #�ꎞ�t�@�C�����폜
  rm -f "${L_path_ou_sldr}"
  rm -f "${L_path_sql_log}"

  return ${L_ret_code}
}

#===============================================================================
# Description : �Ɩ��p�R���J�����g���N��
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       �f�[�^��R�[�h
#  $2�`$36  �R���J�����g����
#===============================================================================
#CONCURRENT_EXECUTE()
#{
#  #�p�����[�^���쐬����
#  L_ksh_para="${G_resp_app_name}"                 #�A�v���P�[�V�����Z�k��(�E��)
#  L_ksh_para="${L_ksh_para} ${G_resp_name}"       #�E�Ӗ�
#  L_ksh_para="${L_ksh_para} ${G_user_name}"       #���[�U��
#  L_ksh_para="${L_ksh_para} ${G_con_app_name}"    #�A�v���P�[�V�����Z�k��(�R���J�����g)
#  L_ksh_para="${L_ksh_para} ${G_con_name}"        #�R���J�����g�Z�k��
#  L_set_para_flag=0
#  for L_file in "${@}"
#  do
##2009/02/23 UPDATE BY M.Sano �����e�X�g����s���Ή� START
##    if [ L_set_para_flag -eq 1 ]
##    then
##      L_ksh_para="${L_ksh_para} \"${L_file}\""      #�R���J�����g�p�����[�^
##    fi
##    L_set_para_flag=1
#    if [ L_set_para_flag -eq 0 ]
#    then
#      L_set_para_flag=1
#    elif [ L_set_para_flag -eq 1 ]
#    then
#      L_ksh_para="${L_ksh_para} \"${G_path_nas}\""            #I/F�t�@�C���p�X(NAS�T�[�o)
#      L_set_para_flag=2
#    else
#      L_ksh_para="${L_ksh_para} \"${L_file}\""                #�R���J�����g�p�����[�^
#    fi
##2009/02/23 UPDATE BY M.Sano �����e�X�g����s���Ή� START
#  done
#  #EBS���ʃR���J�����g�N���V�F���o�R�ŋƖ��R���J�����g���s����
#  AZBZZEXECONCSUB ${L_ksh_para}
#  return ${?}
#}

#===============================================================================
# Description : SQL-Loader�ɂĊi�[�����f�[�^���폜����B
#
# Parameter List
# -------- ----------------------------------------------------------
#  No.     Description
# -------- ----------------------------------------------------------
#  $1       �f�[�^��R�[�h
#===============================================================================
SQL_LOADER_DELETE()
{
# 2009/07/17 Ver.1.9 Shigeto.Niki add START
export NLS_LANG=JAPANESE_JAPAN.JA16SJIS
# 2009/07/17 Ver.1.9 Shigeto.Niki add END

  #SQL Loader��荞�݃f�[�^�폜(�폜SQL�����敪��"1")
  if [ ${G_del_sql_type} = "1" ]
  then
    sqlplus -s apps/apps <<DELSQL1 >${L_path_sql_log}
      WHENEVER SQLERROR EXIT FAILURE ROLLBACK
      DELETE
      FROM   ${G_del_tbl_name}
      WHERE  if_file_name='${1}'
      AND    err_status='0'
      ;
      COMMIT;
      EXIT 0
DELSQL1
    L_ret_code=${?}
  #SQL Loader��荞�݃f�[�^�폜(�폜SQL�����敪��"1")
  else
    sqlplus -s apps/apps <<DELSQL2 >${L_path_sql_log}
      WHENEVER SQLERROR EXIT FAILURE ROLLBACK
      DELETE
      FROM   ${G_del_tbl_name}
      WHERE  if_file_name='${1}'
      ;
      COMMIT;
      EXIT 0
DELSQL2
    L_ret_code=${?}
  fi

  #�ꎞ�t�@�C�����폜
  rm -f "${L_path_sql_log}"

  #���s���ʂ̖߂�l��Ԃ�
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 Start
#  return ${L_ret_code}
  if [ ${L_ret_code} -ne 0 ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00021}(${G_del_tbl_name})"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  return ${C_ret_code_norm}
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.5 End
}

#===============================================================================
# Description : I/F�t�@�C����NAS�T�[�o�f�B���N�g��(G_path_nas)����
#             : �ޔ��f�B���N�g��(G_path_esc)�֑ޔ�����
#===============================================================================
FILE_ESCAPE()
{
  L_cnt=0   #�J�E���g�ϐ�

  #�ޔ��f�B���N�g���ֈړ�
  mv -f "${G_path_nas}" "${G_path_esc}"
  L_ret_code=${?}
  if [ ${L_ret_code} -ne 0 ]
  then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    output_log "${C_log_msg_00022}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    return ${C_ret_code_eror}
  fi

  #�o�b�N�A�b�v�t�@�C���̍폜
  for L_file in $(ls -1r "${G_drie_esc}" | egrep -x "${G_base_if}_[0-9]{14}\.${G_exte_if}")
  do
    let L_cnt=${L_cnt}+1
    if [ ${G_gene_num} -lt ${L_cnt} ]
    then
      rm -f "${G_drie_esc}/${L_file}"
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#      L_ret_code=${?}
#      if [ ${L_ret_code} -ne 0 ]
#      then
      if [ -f "${G_drie_esc}/${L_file}" ]
      then
        output_log "${C_log_msg_00023}"
        return ${C_ret_code_eror}
      fi
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
    fi
  done
  return ${C_ret_code_norm}
}

################################################################################
##                                   Main                                     ##
################################################################################

#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
touch ${L_logfile}
output_log "`/bin/basename ${0}` START"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
#===============================================================================
#1.���̓p�����[�^���̃`�F�b�N
#===============================================================================
# 1) ���̓p�����[�^���`�F�b�N
if [ ${#} -lt 2 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  output_log "${C_log_msg_00001}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
# 2) ���̓p�����[�^�����O�t�@�C���֏o��
output_log "Input Parameter"
let L_cnt=0
for L_para in ${@}
do
  let L_cnt=${L_cnt}+1
  output_log '$'"${L_cnt} : ${L_para}"
done
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END

#2009/04/03 ADD BY Masayuki.Sano Ver.1.4 Start
#===============================================================================
#1-1.�O���ݒ�t�@�C��(AZBZZAPPS.env)�Ǎ�����
#===============================================================================
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano START
##���O�t�@�C���̍ŏI�A�N�Z�X�����ƍŏI�X�V�������������ɍX�V
#touch ${L_logfile}
#output_log "`/bin/basename ${0}` START"
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano END
#"AZBZZAPPS.env"�����s
#�E"AZBZZAPPS.env"���Ȃ��˖߂�l(7)���Z�b�g���ď����I��
output_log "Reading Shell Env File START"
if [ -r ${L_envfile} ]
then
  . ${L_envfile}
  output_log "Reading Shell Env File was Completed"
else
  output_log "Reading Shell Env File was Failed"
  shell_end ${C_ret_code_eror}
  return ${?}
fi
output_log "Reading Shell Env File END"

#"APPSORA.env"�����s
#�E"APPSORA.env"���Ȃ��˖߂�l(7)���Z�b�g���ď����I��
output_log "Reading APPS Env File START"
if [ -r ${L_appsora} ]
then
  . ${L_appsora}
  output_log "Reading APPS Env File was Completed"
else
  output_log "Reading APPS Env File was Failed"
  shell_end ${C_ret_code_eror}
  return ${?}
fi
output_log "Reading APPS Env File END"
#2009/04/03 ADD BY Masayuki.Sano Ver.1.4 End

#===============================================================================
#2.�ݒ���̎擾
#===============================================================================
#�l�Z�b�g�e�[�u������f�[�^��R�[�h�ɕR�Â��f�[�^���擾
#�E�ُ�I���˖߂�l(7)���Z�b�g���ď����I��
FLEX_VALUES_GET "${1}"
L_ret_code=${?}
if [ ${L_ret_code} -ne 0 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#3.�f�[�^�̍쐬
#���f�[�^�F���̓p�����[�^�A�Q�Ŏ擾�����ݒ���
#===============================================================================
#(�t�@�C�������擾)
G_base_if=$(echo "${2}" | sed -e 's/\.[^.]*$//')                #I/F�t�@�C���̃x�[�X��
G_exte_if=$(echo "${2}" | sed -e 's/^'"${G_base_if}"'\.//')     #I/F�t�@�C���̊g���q��
G_path_san="${G_dire_san}/${2}"                                 #I/F�t�@�C��(SAN�T�[�o)�p�X
G_path_nas="${G_dire_nas}/${2}"                                 #I/F�t�@�C��(NAS�T�[�o)�p�X
G_path_esc="${G_drie_esc}/${G_base_if}_${C_date}.${G_exte_if}"  #I/F�t�@�C��(�ޔ�p)�p�X

#===============================================================================
#4.I/F�t�@�C���iNAS�T�[�o�j�̑��݃`�F�b�N
#===============================================================================
#SNAS�T�[�o��I/F�t�@�C�������݂��邩�`�F�b�N����
#�E���݂���˖߂�l(7)���Z�b�g���ď����I��
if [ -f "${G_path_nas}" ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  output_log "${C_log_msg_00016}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#5.I/F�t�@�C���iNAS�T�[�o�j�ւ̃R�s�[
#===============================================================================
#SAN�T�[�o������NAS�T�[�o��I/F�t�@�C�����R�s�[
#�E�ُ�I���˖߂�l(7)���Z�b�g���ď����I��
cp -pf "${G_path_san}" "${G_path_nas}"
L_ret_code=${?}
if [ ${L_ret_code} -ne 0 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  output_log "${C_log_msg_00017}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#6.I/F�t�@�C���iSAN�T�[�o�j�̍폜
#===============================================================================
#SAN�T�[�o����I/F�t�@�C�����폜
#�E�ُ�I���˖߂�l(7)���Z�b�g���ď����I��
rm -f "${G_path_san}"
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
#L_ret_code=${?}
#if [ ${L_ret_code} -ne 0 ]
#then
if [ -f "${G_path_san}" ]
then
  output_log "${C_log_msg_00018}"
  shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${C_ret_code_eror}
fi

#===============================================================================
#7.I/F�A�g�w�b�_�[�t�b�^�[�폜�R���J�����g�N��
#===============================================================================
#I/F�A�g�w�b�_�[�t�b�^�[�폜�R���J�����g�N��
#�E�ُ�I����EBS���ʃR���J�����g�N���V�F���̖߂�l���Z�b�g���ď����I��
#2009/02/18 UPDATE BY M.Sano �����e�X�g����s���Ή� START
#XXCCP005A01C_EXECUTE "${2}" "EDI" "${G_dire_nas}"
#L_exit_code=${?}
XXCCP005A01C_EXECUTE "${2}" "EDI" "${G_dir_name_nas}"
L_exit_code=${?}
#2009/02/18 UPDATE BY M.Sano �����e�X�g����s���Ή� END
if [ ${L_exit_code} -ne 0 ]
then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
  shell_end ${L_exit_code}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
  exit ${L_exit_code}
fi

#===============================================================================
#8.�Ɩ��R���J�����g�N���iSQL Loader�g�p�j
#  �����s�����FSQL-Loader���s�t���O��"1"
#===============================================================================
if [ "${G_flag_sldr}" = "1" ]
then
  #----------------------------------------------------------------------------
  #�ySQL Loader�����z
  #----------------------------------------------------------------------------
  SQL_LOADER_EXECUTE
  L_ret_code=${?}

  #----------------------------------------------------------------------------
  #�ySQL Loader�����z������ɏ����ł����ꍇ
  #----------------------------------------------------------------------------
  if [ ${L_ret_code} -eq 0 ]
  then
    #NAS�T�[�o�f�B���N�g�����̃t�@�C���폜
    #�E�ُ�I�����߂�l(7)���Z�b�g���ď����I��
    rm -f "${G_path_nas}"
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    L_ret_code=${?}
#    if [ ${L_ret_code} -ne 0 ]
#    then
    if [ -f "${G_path_nas}" ]
    then
      output_log "${C_log_msg_00020}"
      shell_end ${C_ret_code_eror}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

#2009/02/27 UPDATE BY M.Sano �����e�X�g����s���Ή� START
#    #�Ɩ��R���J�����g�N��
#    #�E�ُ�I����EBS���ʃR���J�����g�N���V�F���̖߂�l���Z�b�g���ď����I��
#    CONCURRENT_EXECUTE "${@}"
#    L_exit_code=${?}
#    if [ ${L_exit_code} -ne 0 ]
#    then
#      exit ${L_exit_code}
#    fi
    #�Ɩ��R���J�����g�p�p�����[�^���쐬����
    L_ksh_para="${G_resp_app_name}"                 #�A�v���P�[�V�����Z�k��(�E��)
    L_ksh_para="${L_ksh_para} ${G_resp_name}"       #�E�Ӗ�
    L_ksh_para="${L_ksh_para} ${G_user_name}"       #���[�U��
    L_ksh_para="${L_ksh_para} ${G_con_app_name}"    #�A�v���P�[�V�����Z�k��(�R���J�����g)
    L_ksh_para="${L_ksh_para} ${G_con_name}"        #�R���J�����g�Z�k��
    L_set_para_flag=0
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#    for L_file in "${@}"
    for L_file in ${@+"$@"}
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
    do
      if [ L_set_para_flag -eq 0 ]
      then
        L_set_para_flag=1
      elif [ L_set_para_flag -eq 1 ]
      then
        L_ksh_para="${L_ksh_para} \"${G_path_nas}\""            #I/F�t�@�C���p�X(NAS�T�[�o)
        L_set_para_flag=2
      else
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#        L_ksh_para="${L_ksh_para} \"${L_file}\""               #�R���J�����g�p�����[�^
        #���̓p�����[�^2�ȍ~�́A�R���J�����g�����ƂȂ�
        #��CONCSUB���s�t�@���N�V�����̈����ɒǉ�����B
        if [ -z "${L_file}" ]
        then
          #�R���J�����g������""�̏ꍇ�A�ŏ��ƍŌ�Ƀ_�u���N�H�[�g��ǉ�
          L_ksh_para="${L_ksh_para} \"${L_file}\""
        else
          #�R���J�����g������""�ȊO�̏ꍇ�A���̂܂ܓn���B
          L_ksh_para="${L_ksh_para} ${L_file}"
        fi
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
      fi
    done
    #EBS���ʃR���J�����g�N���V�F���o�R�ŋƖ��R���J�����g���s����
    AZBZZEXECONCSUB ${L_ksh_para}
    L_exit_code=${?}
    if [ ${L_exit_code} -ne 0 ]
    then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
      shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      exit ${L_exit_code}
    fi
#2009/02/27 UPDATE BY M.Sano �����e�X�g����s���Ή� END

  #----------------------------------------------------------------------------
  #�ySQL Loader�����z������ɏ����ł��Ȃ������ꍇ
  #----------------------------------------------------------------------------
  else
    #SQL Loader�ɂĎ�荞�񂾃f�[�^�폜
    #�E�ُ�I�����߂�l(7)���Z�b�g���ď����I��
    SQL_LOADER_DELETE "${2}"
    L_ret_code=${?}
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano START
#    if [ ${L_ret_code} -ne 0 ]
#    then
#      exit ${C_ret_code_eror}
#    fi
#2009/04/15 DELETE Ver.1.7 BY Masayuki.Sano START

    #�t�@�C����ޔ�����B(NAS�T�[�o�f�B���N�g���ˑޔ��f�B���N�g��)
    #�E�ُ�I�����߂�l(7)���Z�b�g���ď����I��
    FILE_ESCAPE
    L_ret_code=${?}
    if [ ${L_ret_code} -ne 0 ]
    then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
      shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

    #�����̏I��(�ُ�I��)
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    exit ${C_ret_code_eror}
  fi
fi

#===============================================================================
#9.�Ɩ��R���J�����g�N���iSQL Loader���g�p�j
#  �����s�����FSQL-Loader���s�t���O��"1"
#===============================================================================
if [ "${G_flag_sldr}" != "1" ]
then
  #----------------------------------------------------------------------------
  #�y�Ɩ��R���J�����g�N�������z
  #----------------------------------------------------------------------------
#2009/02/27 UPDATE BY M.Sano �����e�X�g����s���Ή� START
#  CONCURRENT_EXECUTE "${@}"
#  L_exit_code=${?}
  #�Ɩ��R���J�����g�p�p�����[�^���쐬����
  L_ksh_para="${G_resp_app_name}"                 #�A�v���P�[�V�����Z�k��(�E��)
  L_ksh_para="${L_ksh_para} ${G_resp_name}"       #�E�Ӗ�
  L_ksh_para="${L_ksh_para} ${G_user_name}"       #���[�U��
  L_ksh_para="${L_ksh_para} ${G_con_app_name}"    #�A�v���P�[�V�����Z�k��(�R���J�����g)
  L_ksh_para="${L_ksh_para} ${G_con_name}"        #�R���J�����g�Z�k��
  L_set_para_flag=0
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#  for L_file in "${@}"
  for L_file in ${@+"$@"}
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
  do
    if [ L_set_para_flag -eq 0 ]
    then
      L_set_para_flag=1
    else
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 Start
#      L_ksh_para="${L_ksh_para} \"${L_file}\""    #�R���J�����g�p�����[�^
      #���̓p�����[�^2�ȍ~�́A�R���J�����g�����ƂȂ�
      #��CONCSUB���s�t�@���N�V�����̈����ɒǉ�����B
      if [ -z "${L_file}" ]
      then
        #�R���J�����g������""�̏ꍇ�A�ŏ��ƍŌ�Ƀ_�u���N�H�[�g��ǉ�
        L_ksh_para="${L_ksh_para} \"${L_file}\""
      else
        #�R���J�����g������""�ȊO�̏ꍇ�A���̂܂ܓn���B
        L_ksh_para="${L_ksh_para} ${L_file}"
      fi
#2009/04/07 UPDATE BY Masayuki.Sano Ver.1.6 End
    fi
  done
  #EBS���ʃR���J�����g�N���V�F���o�R�ŋƖ��R���J�����g���s����
  AZBZZEXECONCSUB ${L_ksh_para}
  L_exit_code=${?}
#2009/02/27 UPDATE BY M.Sano �����e�X�g����s���Ή� END

  #----------------------------------------------------------------------------
  #�y�Ɩ��R���J�����g�N�������z������ɏ����ł����ꍇ
  #----------------------------------------------------------------------------
  if [ ${L_exit_code} -eq 0 ]
  then
    #NAS�T�[�o�f�B���N�g�����̃t�@�C���폜�i�@�j
    #�E�ُ�I�����߂�l(7)���Z�b�g���ď����I��
    rm -f "${G_path_nas}"
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano START
#    L_ret_code=${?}
#    if [ ${L_ret_code} -ne 0 ]
#    then
    if [ -f "${G_path_nas}" ]
    then
      output_log "${C_log_msg_00020}"
      shell_end ${C_ret_code_eror}
#2009/04/15 UPDATE Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

  #----------------------------------------------------------------------------
  #�y�Ɩ��R���J�����g�N�������z������ɏ����ł��Ȃ������ꍇ
  #----------------------------------------------------------------------------
  else
    #�t�@�C����ޔ�����B(NAS�T�[�o�f�B���N�g���ˑޔ��f�B���N�g��)�i�@�`�C�j
    #�E�ُ�I�����߂�l(7)���Z�b�g���ď����I��
    FILE_ESCAPE
    L_ret_code=${?}
    if [ ${L_ret_code} -ne 0 ]
    then
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
      shell_end ${C_ret_code_eror}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
      exit ${C_ret_code_eror}
    fi

    #�����̏I��(�Ɩ��R���J�����g���s����)
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
    shell_end ${L_exit_code}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
    exit ${L_exit_code}
  fi
fi

#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano START
shell_end ${C_ret_code_norm}
#2009/04/15 ADD Ver.1.7 BY Masayuki.Sano END
exit ${C_ret_code_norm}
