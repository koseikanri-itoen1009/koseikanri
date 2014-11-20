#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ADZZAFFCUST                                               ##
## Description      : AFF�ڋq�}�X�^�X�V(FND_LOAD)                               ##
## MD.070           : MD050_IPO_CMM_003_A38_AFF�ڋq�}�X�^�X�V�iFND_LOAD�j       ##
## Version          : 1.3                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $0       ENV�t�@�C���ǂݍ���                                                ##
##  $1       �����`�F�b�N(A-1)                                                  ##
##  $2       �t�@�C�����݃`�F�b�N(A-2)                                          ##
##  $3       FNDLOAD�N������(A-3)                                               ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/02/16    1.0   Takuya.Kaihara   �V�K�쐬                               ##
##  2009/06/04    1.1   Yutaka.Kuboshima ��QT1_1052�̑Ή�                      ##
##  2009/07/09    1.2   Yutaka.Kuboshima �����e�X�g��Q0000230�̑Ή�            ##
##  2010/01/14    1.3   Shigeto.Niki     ��Q�FE_�{�ғ�_00868�̑Ή�             ##
##                                                                              ##
##################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

C_appl_name="XXCMM"                    #�A�v���P�[�V�����Z�k��
C_program_id="ADZZAFFCUST"             #�v���O����ID
C_return_norm=0                        #����I��
C_return_error=7                       #�ُ�I��

##2009/06/04 Ver1.1 add start by Yutaka.Kuboshima
L_cmd=${0}
L_cmddir=`/bin/dirname ${L_cmd}`

#�O���V�F��
L_envfile=${L_cmddir}/ADZZAPPS.env
##2009/06/04 Ver1.1 add end by Yutaka.Kuboshima

################################################################################
##                                   Main                                     ##
################################################################################

##2009/06/04 Ver1.1 add start by Yutaka.Kuboshima
#0-1.�O���V�F���̓Ǎ���
if [ -r ${L_envfile} ]
then
  . ${L_envfile}
else
  exit ${C_return_error}
fi

#0-2.ENV�t�@�C���̓Ǎ���
if [ -r ${L_appsora} ]
then
  . ${L_appsora}
else
  exit ${C_return_error}
fi

##2009/06/04 Ver1.1 add end by Yutaka.Kuboshima

#1.�����`�F�b�N
##2009/07/09 Ver1.2 delete start by Yutaka.Kuboshima
#if [ ${#} -ne 4 ]
#then
#  exit ${C_return_error}
#fi
##2009/07/09 Ver1.2 delete end by Yutaka.Kuboshima

#2-1.�t�@�C�����݃`�F�b�N(�\���t�@�C��)
##2009/07/09 Ver1.2 modify start by Yutaka.Kuboshima
#L_compos_file_path="${2}/${1}"
L_compos_file_path="${L_load_file_path}/${L_load_file_name}"
##2009/07/09 Ver1.2 modify end by Yutaka.Kuboshima

##2010/01/14 Ver1.3 add start by Shigeto.Niki
#���O�o�̓f�B���N�g���̕ύX
cd "${L_log_file_path}"
##2010/01/14 Ver1.3 add end by Shigeto.Niki

if [ -f "${L_compos_file_path}" ]
then
  #2-2.�t�@�C�����݃`�F�b�N(LDT�t�@�C��
##2009/07/09 Ver1.2 modify start by Yutaka.Kuboshima
#  L_check_file_path="${4}/${3}"
  L_check_file_path="${L_ldt_file_path}/${L_ldt_file_name}"
##2009/07/09 Ver1.2 modify end by Yutaka.Kuboshima
  if [ -f "${L_check_file_path}" ]
  then
    #3.AFF�ڋq�}�X�^�X�V
    FNDLOAD apps/apps 0 Y UPLOAD ${L_compos_file_path} ${L_check_file_path} VALUE_SET
    if [ ${?} != 0 ]
    then
      exit ${C_return_error}
    fi
  else
    exit ${C_return_norm}
  fi
else
  exit ${C_return_error}
fi

exit ${C_return_norm}
