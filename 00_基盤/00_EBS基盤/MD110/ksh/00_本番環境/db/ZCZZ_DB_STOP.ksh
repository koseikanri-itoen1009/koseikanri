#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          DB�I�����C���E�T�[�r�X��~����                                    ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle ���R           2008/03/27 1.0.1                 ##
##        �X�V�����F   Oracle ���R           2008/03/27 1.0.1                 ##
##                       ����                                                 ##
##                     SCSK ����             2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �E���ˑ��l�̕ϐ���                               ##
##                         �E���[�J���ϐ�(L_�ȍ~)���������ɕύX               ##
##                         �EAPPS���X�i�[�̒�~�E�m�F�������폜               ##
##                         �EDB��~�R�}���h�̕ύX                             ##
##                         �ETNS���X�i�[�v���Z�X�̊Ď��Ώۂ̕ύX              ##
##                         �E�V�F�����ύX                                     ##
##                     SCSK   �A��           2017/12/06 2.0.1                 ##
##                       E_�{�ғ�_14688�Ή�                                   ##
##                         �ETNS�G���[���b�Z�[�W�ύX                          ##
##                             TE_ZCZZ00504 -> TE_ZCZZ00506                   ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_DB_STOP.ksh                        ##
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
#  L_ROGUPASU="/var/EBS/jp1/PEBSITO/log"      ##���O�t�@�C���i�[�f�B���N�g��
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##���O�t�@�C���i�[�f�B���N�g��
#2014/07/31 S.Takahashi Mod End

## �ϐ���`
  L_hizuke=`/bin/date "+%y%m%d"`     ##�V�F�����s���t
  L_sherumei=`/bin/basename $0`      ##���s�V�F����
  L_hosutomei=`/bin/hostname`        ##���s�z�X�g��
  L_enbufairumei="ZCZZCOMN.env"      ##��Պ����ϐ��t�@�C����
  L_dbfairumei="ZCZZDB.env"          ##DB���ݒ�t�@�C����
  L_ijou=8                           ##�V�F���ُ�I�����̖߂�l

## �t�@�C����`
##2014/07/31 S.Takahashi Mod Start
#  L_rogumei="${L_ROGUPASU}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##���O�t�@�C��(�t���p�X)
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##���O�t�@�C��(�t���p�X)
##2014/07/31 S.Takahashi Mod End

  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                           ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)
  L_dbfairu=`/usr/bin/dirname $0`"/${L_dbfairumei}"                                               ##DB���ݒ�t�@�C��(�t���p�X)


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


### ���ʃt�@�C���ǂݍ��� ###

## ��Ջ��ʊ��ϐ��t�@�C���ǂݍ���
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

## DB���ݒ�t�@�C���ǂݍ���
  L_rogushuturyoku "DB���ݒ�t�@�C����ǂݍ��݂܂��B"

  if [ -r "${L_dbfairu}" ]
    then
      . ${L_dbfairu}
      L_rogushuturyoku "DB���ݒ�t�@�C����ǂݍ��݂܂����B"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_dbfairu}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_dbfairu}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}" 1>&2
      L_shuryo ${L_ijou}
  fi

## �R�}���h�ݒ�
##2014/07/31 S.Takahashi Del Start
#  L_appsteisi="${TE_ZCZZAPKOMANDOPASU}/adalnctl.sh stop"                                        ##APPS���X�i�[��~�R�}���h
##2014/07/31 S.Takahashi Del End

##2014/07/31 S.Takahashi Mod Start
#  L_dbteisi="${ORACLE_HOME}/bin/srvctl stop instance -d PEBSITO -i ${ORACLE_SID} -o immediate"  ##�f�[�^�x�[�X��~�R�}���h
  L_dbteisi="${ORACLE_HOME}/bin/srvctl stop instance -d ${DATABASE_NAME} -i ${ORACLE_SID} -o immediate"  ##�f�[�^�x�[�X��~�R�}���h
##2014/07/31 S.Takahashi Mod End

  L_risunateisi="${ORACLE_HOME}/bin/srvctl stop listener -n ${TE_ZCZZHOSUTOMEI} -l ${LISTENER_NAME}" ##TNS���X�i�[��~�R�}���h

##2014/07/31 S.Takahashi Del Start
### APPS���X�i�[��~ ###

#  L_rogushuturyoku "APPS���X�i�[���~���܂��B"

#  ${L_appsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
#  L_dashutu=${?}
#  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Aadalnctl�̓���𔻒�
#  if [ ${L_dashutu} -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00501}"
#  elif [ ${L_dashutu} -eq 2 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00500}"
#  else
#      L_rogushuturyoku "${TE_ZCZZ00502}"
#      echo "${TE_ZCZZ00502}" 1>&2
#      L_shuryo ${L_ijou}
#  fi


### AP�w��~�m�F ###

#  L_rogushuturyoku "AP�w��~�m�F"
#  L_rogushuturyoku "AP�w�̒�~��҂��Ă��܂��B"
#  sleep ${TE_ZCZZTAIKI}

## APPS���X�i�[��~�m�F
#  L_rogushuturyoku "APPS���X�i�[��~�m�F"
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ00502}"
#      echo "${TE_ZCZZ00502}" 1>&2
#      L_shuryo ${L_ijou}
#  fi

#  L_rogushuturyoku "APPS���X�i�[�̒�~���m�F���܂����B"
##2014/07/31 S.Takahashi Del End


### �f�[�^�x�[�X��~ ###

  L_rogushuturyoku "�f�[�^�x�[�X���~���܂��B"

  ${L_dbteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Asrvctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00503}"
  else
      L_rogushuturyoku "${TE_ZCZZ00504}"
      echo "${TE_ZCZZ00504}" 1>&2
      L_shuryo ${L_ijou}
  fi


### TNS���X�i�[��~ ###

  L_rogushuturyoku "TNS���X�i�[���~���܂��B"

  ${L_risunateisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Asrvctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00505}"
  else
##2017/12/06 S.Hiromori Message Change Start TE_ZCZZ00504 -> TE_ZCZZ00506
#      L_rogushuturyoku "${TE_ZCZZ00504}"
#      echo "${TE_ZCZZ00504}" 1>&2
      L_rogushuturyoku "${TE_ZCZZ00506}"
      echo "${TE_ZCZZ00506}" 1>&2
##2017/12/06 S.Hiromori Message Change END
      L_shuryo ${L_ijou}
  fi


### DB�T�[�o��~�m�F ###

  L_rogushuturyoku "DB�T�[�o��~�m�F"
  L_rogushuturyoku "DB�w�̒�~��҂��Ă��܂��B"
  sleep ${TE_ZCZZTAIKI}

## TNS���X�i�[��~�m�F
  L_rogushuturyoku "TNS���X�i�[��~�m�F"
##2014/07/31 S.Takahashi Mod Start  
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep "10.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep "11.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2014/07/31 S.Takahashi Mod End

  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
##2017/12/06 S.Hiromori Message Change Start TE_ZCZZ00504 -> TE_ZCZZ00506
#      L_rogushuturyoku "${TE_ZCZZ00504}"
#      echo "${TE_ZCZZ00504}" 1>&2
      L_rogushuturyoku "${TE_ZCZZ00506}"
      echo "${TE_ZCZZ00506}" 1>&2
##2017/12/06 S.Hiromori Message Change End
      L_shuryo ${L_ijou}
  fi

  L_rogushuturyoku "TNS���X�i�[�̒�~���m�F���܂����B"

## �f�[�^�x�[�X��~�m�F
  L_rogushuturyoku "�f�[�^�x�[�X��~�m�F"
  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep ora_pmon | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ00504}"
      echo "${TE_ZCZZ00504}" 1>&2
      L_shuryo ${L_ijou}
  fi

 L_rogushuturyoku "�f�[�^�x�[�X�̒�~���m�F���܂����B"
 L_rogushuturyoku "DB�T�[�o���~���܂����B"


### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
