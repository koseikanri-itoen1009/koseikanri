#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          �A�[�J�C�u���O�t�@�C���E���[�J���o�͊Ď�                          ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCSK   ����           2014/07/31 2.0.0                 ##
##        �X�V�����F   SCSK   ����           2014/07/31 2.0.0                 ##
##                       ����/HW���v���[�X�Ή�(���v���[�X_00007)              ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_DB_CHECK_ARCLOCAL.ksh              ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

## ���ˑ��l
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##�ŉ��w�̃J�����g�f�B���N�g����

## �f�B���N�g����`
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##���O�t�@�C���i�[�f�B���N�g��

## �ϐ���`
  L_hizuke=`/bin/date "+%y%m%d"`     ##�V�F�����s���t
  L_sherumei=`/bin/basename $0`      ##���s�V�F����
  L_hosutomei=`/bin/hostname`        ##���s�z�X�g��
  L_enbufairumei="ZCZZCOMN.env"      ##��Ջ��ʊ��ϐ��t�@�C����
  L_ijou=8                           ##�V�F���ُ�I�����̃��^�[���R�[�h

## �t�@�C����`
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##���O�t�@�C��(�t���p�X)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)


################################################################################
##                                 �֐���`                                   ##
################################################################################


### ���O�o�͏��� ###

  L_rogushuturyoku()
  {
    echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@} | /usr/bin/fold -w 78 >> ${L_rogumei}
  }


### �I������ ###

  L_shuryo()
  {
    L_modorichi=${1:-0}
    L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I��  END_CD="${L_modorichi}
    exit ${L_modorichi}
  }

### trap ���� ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                 ���C��                                     ##
################################################################################



### �����J�n�o�� ###

  touch ${L_rogumei}
  L_rogushuturyoku "ZCZZ00001:${L_sherumei} �J�n"


### ���ݒ���ϐ��t�@�C���ǂݍ��� ###

## ��Ջ��ʃt�@�C���ǂݍ���
  L_rogushuturyoku "��Ջ��ʊ��ϐ��t�@�C����ǂݍ��݂܂��B"

  if [ -r "${L_enbufairu}" ]
    then
      . ${L_enbufairu}
      L_rogushuturyoku "��Ջ��ʊ��ϐ��t�@�C����ǂݍ��݂܂����B"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_enbufairu}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_enbufairu}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}" 1>&2
      L_shuryo ${L_ijou}
  fi

## ���[�J���f�B�X�N�ɏo�͂���Ă���A�[�J�C�u���O�t�@�C���̐��`�F�b�N(���C��)
  L_archfilesu=`/usr/bin/ls -l ${TE_ZCZZLOCALARCHPASU}/thread* | /usr/bin/wc -l`
 
  if [ ${L_archfilesu} -ge ${TE_ZCZZLOCALARCHMAXCNT} ]
    then
      L_message="${L_hosutomei} [${TE_ZCZZLOCALARCHPASU}] more than ${TE_ZCZZLOCALARCHMAXCNT} files are stored at `date +'%a %b %d %I:%M:%S %Y'`"
      /opt/jp1base/bin/jevsend -i ${TE_ZCZZLOCALARCH_EVENTID} -m "${L_message}" -e SEVERITY=Warning
  fi
  
## ���[�J���f�B�X�N�ɏo�͂���Ă���A�[�J�C�u���O�t�@�C���̐��`�F�b�N(�~���[)
  L_archfilesu=`/usr/bin/ls -l ${TE_ZCZZLOCALARCHMPASU}/thread* | /usr/bin/wc -l`
 
  if [ ${L_archfilesu} -ge ${TE_ZCZZLOCALARCHMAXCNT} ]
    then
      L_message="${L_hosutomei} [${TE_ZCZZLOCALARCHMPASU}] more than ${TE_ZCZZLOCALARCHMAXCNT} files are stored at `date +'%a %b %d %I:%M:%S %Y'`"
      /opt/jp1base/bin/jevsend -i ${TE_ZCZZLOCALARCH_EVENTID} -m "${L_message}" -e SEVERITY=Warning
  fi
  
### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
