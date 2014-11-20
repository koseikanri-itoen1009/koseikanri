#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          DB�I�����C���E�R���J�����g�N������                                ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/05/22 1.0.1                 ##
##        �X�V�����F   Oracle �x��           2008/05/22 1.0.1                 ##
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
##      ZCZZ_PEBSCONC_START.ksh                                               ##
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
  L_rogushuturyoku "ZCZZ00002:${L_sherumei} �J�n"


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


## �R�}���h�ݒ�
  L_konkarentokaisi="${TE_ZCZZAPKOMANDOPASU}/adcmctl.sh start apps/apps"             ##�R���J�����g�J�n�R�}���h


### �R���J�����g�}�l�[�W���N�� ###

  L_rogushuturyoku "�R���J�����g�}�l�[�W�����N�����܂��B"

  ${L_konkarentokaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Aadcmctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01500}"
  else
      L_rogushuturyoku "${TE_ZCZZ01501}"
      echo "${TE_ZCZZ01501}" 1>&2
      L_shuryo ${L_ijou}
  fi


## �R���J�����g�}�l�[�W���N���m�F
  L_rogushuturyoku "�R���J�����g�}�l�[�W���N���m�F"
  L_rogushuturyoku "�R���J�����g�}�l�[�W���̋N����҂��Ă��܂��B"
  sleep ${TE_ZCZZCONCTAIKI}

  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep FNDLIBR | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01501}"
      echo "${TE_ZCZZ01501}" 1>&2
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "�R���J�����g�}�l�[�W���̋N�����m�F���܂����B"
  L_rogushuturyoku "�R���J�����g�}�l�[�W�����N�����܂����B"


### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
