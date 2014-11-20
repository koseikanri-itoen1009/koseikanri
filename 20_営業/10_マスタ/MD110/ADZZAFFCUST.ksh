#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ADZZAFFCUST                                               ##
## Description      : AFF�ڋq�}�X�^�X�V(FND_LOAD)                               ##
## MD.070           : MD050_IPO_CMM_003_A38_AFF�ڋq�}�X�^�X�V�iFND_LOAD�j       ##
## Version          : 1.1                                                       ##
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
if [ ${#} -ne 4 ]
then
  exit ${C_return_error}
fi

#2-1.�t�@�C�����݃`�F�b�N(�\���t�@�C��)
L_compos_file_path="${2}/${1}"
if [ -f "${L_compos_file_path}" ]
then
  #2-2.�t�@�C�����݃`�F�b�N(LDT�t�@�C��)
  L_check_file_path="${4}/${3}"
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
