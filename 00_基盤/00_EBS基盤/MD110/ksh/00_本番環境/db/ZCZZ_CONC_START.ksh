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
##                     SCSK ����             2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �E���ˑ��l�̕ϐ���                               ##
##                         �E�R���J�����g���ϐ��̓ǂݍ��݂�ǉ�             ##
##                         �Ecmclean�̏�����ǉ�                              ##
##                         �E�V�F�����ύX                                     ##
##                         �E�J�n���b�Z�[�WID�ύX                             ##
##                         �EZCZZCONC.env�ǂݍ��ݒǉ�                         ##
##                         �E�v���Z�X�m�F�����ύX                             ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_CONC_START.ksh                     ##
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
##2014/07/31 S.Takahashi Add Start
  L_kurinfairumei="ZCZZ_CMCLEAN.sql" ##�R���J�����g�}�l�[�W���Ǘ��\�̃N���[���A�b�v�X�N���v�g��
  L_apps='APPS/APPS'                 ##�R�}���h���s���[�U��
##2014/07/31 S.Takahashi Add End
  L_ijou=8                           ##�V�F���ُ�I�����̃��^�[���R�[�h

## �t�@�C����`
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##���O�t�@�C��(�t���p�X)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)
##2014/07/31 S.Takahashi Add Start
  L_kurinfairu=`/usr/bin/dirname $0`"/${L_kurinfairumei}"                                           ##�R���J�����g�}�l�[�W���Ǘ��\�̃N���[���A�b�v�X�N���v�g��(�t���p�X)
##2014/07/31 S.Takahashi Add End

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
##2014/07/31 S.Takahashi Mod Start
#  L_rogushuturyoku "ZCZZ00002:${L_sherumei} �J�n"
  L_rogushuturyoku "ZCZZ00001:${L_sherumei} �J�n"
##2014/07/31 S.Takahashi Mod End


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

##2014/07/31 S.Takahashi Add Start
#�R���J�����g���ݒ�
  if [ -r ${TE_ZCZZCONC} ]
  then
     . ${TE_ZCZZCONC}
  else
     echo "ZCZZ00003:[Error] ZCZZCONC.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
          | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
     L_shuryo ${TE_ZCZZIJOUSHURYO}
  fi

  L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �I��"
##2014/07/31 S.Takahashi Add End

## �R�}���h�ݒ�
  L_konkarentokaisi="${TE_ZCZZAPKOMANDOPASU}/adcmctl.sh start apps/apps"             ##�R���J�����g�J�n�R�}���h

##2014/07/31 S.Takahashi Add Start
###�R���J�����g�}�l�[�W���Ǘ��\�̃N���[���A�b�v
  L_rogushuturyoku "�R���J�����g�}�l�[�W���Ǘ��\�̃N���[���A�b�v���������s���܂��B"
  sqlplus -s ${L_apps} << EOF >> ${L_rogumei}
  set echo on;
  @${L_kurinfairu}
  commit;
  EXIT;
EOF
  L_rogushuturyoku "${TE_ZCZZ01502}"
##2014/07/31 S.Takahashi Add End

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
##2014/07/31 S.Takahashi Mod Start
#  sleep ${TE_ZCZZCONCTAIKI}

#  /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/grep FNDLIBR | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ01501}"
#      echo "${TE_ZCZZ01501}" 1>&2
#      L_shuryo ${L_ijou}
#  fi
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZ_WAITCNT}" ]
  do
    sleep ${TE_ZCZZCONCTAIKI}
    /usr/bin/ps -ef | grep `/usr/bin/whoami` | /usr/bin/egrep "FNDLIBR|FNDSM|FNDIMON" | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
    if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -lt 3 ]
      then
        if [ "$cnt" -eq "${TE_ZCZZ_WAITCNT}" ]
          then
            L_rogushuturyoku "${TE_ZCZZ01501}"
            echo "${TE_ZCZZ01501}" 1>&2
            L_shuryo ${L_ijou}
        fi
     else
        break;
     fi
     let cnt=cnt+1
  done
##2014/07/31 S.Takahashi Mod End

  L_rogushuturyoku "�R���J�����g�}�l�[�W���̋N�����m�F���܂����B"
  L_rogushuturyoku "�R���J�����g�}�l�[�W�����N�����܂����B"


### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
