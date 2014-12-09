#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          �O��AP�I�����C���E�T�[�r�X��~����                                ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle ���R           2008/03/27 1.0.1                 ##
##        �X�V�����F   Oracle ���R           2008/03/27 1.0.1                 ##
##                       ����                                                 ##
##                     SCSK ����             2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �E���ˑ��l�̕ϐ���                               ##
##                         �E�V�F�����ύX                                     ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_EXP_STOP.ksh                       ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

##2014/07/31 S.Takahashi Add Start
## ���ˑ��l
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##�ŉ��w�̃J�����g�f�B���N�g����
##2014/07/31 S.Takahashi Add End

## �f�B���N�g����`
##2014/07/31 S.Takahashi Mod Start
#  L_rogupasu="/var/EBS/jp1/PEBSITO/log"      ##���O�t�@�C���i�[�f�B���N�g��
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##���O�t�@�C���i�[�f�B���N�g��
##2014/07/31 S.Takahashi Mod End

## �ϐ���`
  L_hizuke=`/bin/date "+%y%m%d"`     ##�V�F�����s���t
  L_sherumei=`/bin/basename $0`      ##���s�V�F����
  L_hosutomei=`/bin/hostname`        ##���s�z�X�g��
  L_enbufairumei="ZCZZCOMN.env"      ##��Ջ��ʊ��ϐ��t�@�C����
  L_ijou=8                           ##�V�F���ُ�I�����̖߂�l

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
    if [ -f ${TE_ZCZZHYOUJUNSHUTURYOKU} ]
      then
        L_rogushuturyoku "�W���o�͈ꎞ�t�@�C���폜���s"
        rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
    fi

    if [ -f ${TE_ZCZZHYOUJUNERA} ]
      then
        L_rogushuturyoku "�W���G���[�ꎞ�t�@�C���폜���s"
        rm ${TE_ZCZZHYOUJUNERA}
    fi

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


### ��Ջ��ʊ��ϐ��t�@�C���ǂݍ��� ###


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


### APPS���X�i�[��~ ###

  ## �R�}���h�ݒ�
  L_apteisi="${TE_ZCZZAPKOMANDOPASU}/adapcctl.sh stop"       ##Web�T�[�o��~�R�}���h
  L_appsteisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh stop"     ##APPS���X�i�[��~�R�}���h

  L_rogushuturyoku "APPS���X�i�[���~���܂��B"

  ${L_appsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Aadalnctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00101}"
  elif [ ${L_dashutu} -eq 2 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00100}"
  else
      L_rogushuturyoku "${TE_ZCZZ00104}"
      echo "${TE_ZCZZ00104}" 1>&2
      L_shuryo ${L_ijou}
  fi


### Web�T�[�o��~ ###

  L_rogushuturyoku "Web�T�[�o���~���܂��B"

  ${L_apteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Aadapcctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00103}"
  elif [ ${L_dashutu} -eq 2 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00102}"
  else
      L_rogushuturyoku "${TE_ZCZZ00104}"
      echo "${TE_ZCZZ00104}" 1>&2
      L_shuryo ${L_ijou}
  fi


### �O��AP�T�[�o��~�m�F ###

  L_rogushuturyoku "�O��AP�T�[�o��~�m�F"
  L_rogushuturyoku "�O��AP�T�[�o�̒�~��҂��Ă��܂��B"
  sleep ${TE_ZCZZTAIKI}

## APPS���X�i�[��~�m�F
  L_rogushuturyoku "APPS���X�i�[��~�m�F"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00104}"
      echo "${TE_ZCZZ00104}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "APPS���X�i�[�̒�~���m�F���܂����B"

## Web�T�[�o��~�m�F
  L_rogushuturyoku "Web�T�[�o��~�m�F"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep iAS | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00104}"
      echo "${TE_ZCZZ00104}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "Web�T�[�o�̒�~���m�F���܂����B"
  L_rogushuturyoku "�O��AP�T�[�o���~���܂����B"


### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
