#!/bin/ksh
##################################################################################
## Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved. ##
##                                                                              ##
## Program Name     : ZBZZBUCKUPFILE                                            ##
## Description      : I/F�t�@�C���o�b�N�A�b�v�@�\                               ##
## MD.070           : MD070_IPO_CCP_�V�F��                                      ##
## Version          : 1.0                                                       ##
##                                                                              ##
## Parameter List                                                               ##
## -------- ----------------------------------------------------------          ##
##  No.     Description                                                         ##
## -------- ----------------------------------------------------------          ##
##  $1       �t�@�C����                                                         ##
##  $2       �o�b�N�A�b�v���f�B���N�g��                                         ##
##  $3       �o�b�N�A�b�v��f�B���N�g��                                         ##
##  $4       ���㐔                                                             ##
##                                                                              ##
## Change Record                                                                ##
## ------------- ----- ---------------- ----------------------------------------##
##  Date          Ver.  Editor           Description                            ##
## ------------- ----- ---------------- ----------------------------------------##
##  2009/01/08    1.0   Masayuki.Sano    �V�K�쐬                               ##
##                                                                              ##
##################################################################################
                                                                                  
#���{�ԃv���O����

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

C_appl_name="XXCCP"                    #�A�v���P�[�V�����Z�k��
C_program_id="ZBZZESCAPEFILE"          #�v���O����ID
C_return_norm=0                        #����I��
C_return_error=7                       #�ُ�I��
C_date_format="+%Y%m%d%H%M%S"          #�����t�H�[�}�b�g(YYYYMMDDH24MISS)

################################################################################
##                                   Main                                     ##
################################################################################

#1.�����`�F�b�N
if [ ${#} -ne 4 ]
then
  exit ${C_return_error}
fi

#2.���㐔�`�F�b�N
#(���l���ǂ����`�F�b�N)
if [ "$(echo ${4} | egrep '^[0-9]+$')" -eq "" ]
then
  exit ${C_return_error}
fi
#(1�ȉ����ǂ����`�F�b�N)
if [ ${4} -lt 1 ]
then
  exit ${C_return_error}
fi

#3.�x�[�X���A�g���q�A�����������擾
L_base=$(echo "${1}" | sed -e 's/\.[^\.]*$//')        #���̓t�@�C���̃x�[�X��
L_exte=$(echo "${1}" | sed -e 's/^'"${L_base}"'\.//') #���̓t�@�C���̊g���q
L_date=$(date "${C_date_format}")                     #��������

#4.�w�肵���t�@�C�����o�b�N�A�b�v������o�b�N�A�b�v��փR�s�[
#(�p�X�����擾)
L_in_file_path="${2}/${1}"                            #�o�b�N�A�b�v���t�@�C���p�X
L_ou_file_path="${3}/${L_base}_${L_date}.${L_exte}"   #�o�b�N�A�b�v��t�@�C���p�X
#(�R�s�[)
cp -pf "${L_in_file_path}" "${L_ou_file_path}"
L_ret_code=${?}
if [ ${L_ret_code} -ne 0 ]
then
  exit ${C_return_error}
fi

#5.�o�b�N�A�b�v�������㐔�𒴂��Ă��镪�����t�@�C�����폜
#(�����ݒ�)
let L_cnt=0
#(����)
for L_file in $(ls -1r "${3}" | egrep -x "${L_base}_[0-9]{14}\.${L_exte}")
do
  let L_cnt=${L_cnt}+1
  if [ ${4} -lt ${L_cnt} ]
  then
    rm -f "${3}/${L_file}"
    L_ret_code=${?}
    if [ ${L_ret_code} -ne 0 ]
    then
      exit ${C_return_error}
    fi
  fi
done

exit ${C_return_norm}
