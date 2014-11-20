#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZAFFCUST                                               ##
## Description      : AFF�ڋq�}�X�^�X�V(FND_LOAD)                               ##
## MD.070           : MD050_IPO_CMM_003_A38_AFF�ڋq�}�X�^�X�V�iFND_LOAD�j       ##
## Version          : 1.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1       �����`�F�b�N(A-1)                                                  ##
##  $2       �t�@�C�����݃`�F�b�N(A-2)                                          ##
##  $3       FNDLOAD�N������(A-3)                                               ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/02/16    1.0   Takuya.Kaihara   �V�K�쐬                               ##
##                                                                              ##
##################################################################################
                                                                                  
################################################################################
##                                 �ϐ���`                                   ##
################################################################################

C_appl_name="XXCMM"                    #�A�v���P�[�V�����Z�k��
C_program_id="ZBZZAFFCUST"             #�v���O����ID
C_return_norm=0                        #����I��
C_return_error=7                       #�ُ�I��

################################################################################
##                                   Main                                     ##
################################################################################

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
