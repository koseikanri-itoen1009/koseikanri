#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZCOPYFILE                                              ##
## Description      : I/F�t�@�C���R�s�[�@�\                                     ##
## MD.070           : MD070_IPO_CCP_�V�F��                                      ##
## Version          : 1.2                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
## $1       �t�@�C����                                                          ##
## $2       �R�s�[���f�B���N�g��                                                ##
## $3       �R�s�[��f�B���N�g��                                                ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/08    1.0   Masayuki.Sano    �V�K�쐬                               ##
##  2009/05/07    1.1   Masayuki.Sano    ��Q�ԍ�T1_0917�Ή�                    ##
##                                       �E�ُ�I��(7��8)�֏C��                 ##
##  2009/05/18    1.2   Masayuki.Sano    ��Q�ԍ�T1_1006�Ή�                    ##
##                                       �E���C���h�J�[�h�g�p�Ή�             ##
##                                                                              ##
##################################################################################
                                                                                
#���{�ԃv���O����

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

C_appl_name="XXCCP"                    #�A�v���P�[�V�����Z�k��
C_program_id="ZBZZCOPYFILE "           #�v���O����ID
C_return_norm=0                        #����I��
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.1 Start
#C_return_error=7                       #�ُ�I��
C_return_error=8                       #�ُ�I��
#2009/04/06 UPDATE BY Masayuki.Sano Ver.1.1 End

################################################################################
##                                   Main                                     ##
################################################################################

#1.�����`�F�b�N
if [ ${#} -ne 3 ]
then
  exit ${C_return_error}
fi

#2.�w�肵���t�@�C�����R�s�[������R�s�[��փR�s�[
#2009/05/18 UPDATE BY Masayuki.Sano Ver.1.2 Start
##(�p�X�����擾)
#L_in_file_path="${2}/${1}"    #�R�s�[���t�@�C���p�X
#L_ou_file_path="${3}/${1}"    #�R�s�[��t�@�C���p�X
##(�R�s�[)
#cp -pf "${L_in_file_path}" "${L_ou_file_path}"
#L_ret_code=${?}
cp -pf ${2}/${1} ${3}
L_ret_code=${?}
#2009/05/18 UPDATE BY Masayuki.Sano Ver.1.2 End
if [ ${L_ret_code} -ne 0 ]
then
  exit ${C_return_error}
fi

exit ${C_return_norm}
