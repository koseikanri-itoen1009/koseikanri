#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          �O��AP�I�����C���E�T�[�r�X�J�n����                                ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle ���R           2008/03/27 1.0.1                 ##
##        �X�V�����F   Oracle ���R           2008/03/27 1.0.1                 ##
##                       ����                                                 ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      ZCZZ_PEXTAP_START.ksh                                                 ##
##                                                                            ##
##    Copyright ������Јɓ��� U5000�v���W�F�N�g 2007-2009                    ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

## �f�B���N�g����`
  L_rogupasu="/var/EBS/jp1/PEBSITO/log"      ##���O�t�@�C���i�[�f�B���N�g��

## �ϐ���`
  L_hizuke=`/bin/date "+%y%m%d"`     ##�V�F�����s���t
  L_sherumei=`/bin/basename $0`      ##���s�V�F����
  L_hosutomei=`/bin/hostname`        ##���s�z�X�g��
  L_enbufairu="ZCZZCOMN.env"         ##��Ջ��ʊ��ϐ��t�@�C����
  L_ijou=8                           ##�V�F���ُ�I�����̖߂�l

## �t�@�C����`
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##���O�t�@�C��(�t���p�X)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairu}"                                              ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)


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


### Web�T�[�o�N�� ###

  ## �R�}���h�ݒ�
  L_apkaisi="${TE_ZCZZAPKOMANDOPASU}/adapcctl.sh start"       ##Web�T�[�o�N���R�}���h
  L_appskaisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh start"     ##APPS���X�i�[�N���R�}���h

  L_rogushuturyoku "Web�T�[�o���N�����܂��B"

  ${L_apkaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Aadapcctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00300}"
  else
      L_rogushuturyoku "${TE_ZCZZ00302}"
      echo "${TE_ZCZZ00302}" 1>&2
      L_shuryo ${L_ijou}
  fi


### APPS���X�i�[�N�� ###

  L_rogushuturyoku "APPS���X�i�[���N�����܂��B"

  ${L_appskaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Aadalnctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00301}"
  else
      L_rogushuturyoku "${TE_ZCZZ00302}"
      echo "${TE_ZCZZ00302}" 1>&2
      L_shuryo ${L_ijou}
  fi


### �O��AP�T�[�o�N���m�F ###

  L_rogushuturyoku "�O��AP�T�[�o�N���m�F"
  L_rogushuturyoku "�O��AP�T�[�o�̋N����҂��Ă��܂��B"
  sleep ${TE_ZCZZTAIKI}


## Web�T�[�o�N���m�F
  L_rogushuturyoku "Web�T�[�o�N���m�F"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep iAS | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00302}"
      echo "${TE_ZCZZ00302}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "Web�T�[�o�̋N�����m�F���܂����B"

## APPS���X�i�[�N���m�F
  L_rogushuturyoku "APPS���X�i�[�N���m�F"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00302}"
      echo "${TE_ZCZZ00302}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "APPS���X�i�[�̋N�����m�F���܂����B"
  L_rogushuturyoku "�O��AP�T�[�o���N�����܂����B"


### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
