#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          DB�I�����C���E�R���J�����g��~����                                ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/05/22 1.0.1                 ##
##        �X�V�����F   Oracle ����           2008/10/02 1.1.0                 ##
##                       1.1��                                                ##
##                     SCSK ����             2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �E���ˑ��l�̕ϐ���                               ##
##                         �E���[�J���ϐ�(L_�ȍ~)���������ɕύX               ##
##                         �E�v���Z�X��~�m�F���̑Ώۂ�ύX                   ##
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
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_CONC_STOP.ksh                      ##
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
# L_ROGUPASU="/var/EBS/jp1/PEBSITO/log"      ##���O�t�@�C���i�[�f�B���N�g��
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##���O�t�@�C���i�[�f�B���N�g��
##2014/07/31 S.Takahashi Mod End

## �ϐ���`
  L_hizuke=`/bin/date "+%y%m%d"`     ##�V�F�����s���t
  L_sherumei=`/bin/basename $0`      ##���s�V�F����
  L_hosutomei=`/bin/hostname`        ##���s�z�X�g��
  L_enbufairumei="ZCZZCOMN.env"      ##��Պ����ϐ��t�@�C����
  L_ijou=8                           ##�V�F���ُ�I�����̖߂�l

## �t�@�C����`
##2014/07/31 S.Takahashi Mod Start
#  L_rogumei="${L_ROGUPASU}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##���O�t�@�C��(�t���p�X)
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"     ##���O�t�@�C��(�t���p�X
##2014/07/31 S.Takahashi Mod End

  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                           ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)


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

## �R�}���h�ݒ�
  L_konkarentoteisi="${TE_ZCZZAPKOMANDOPASU}/adcmctl.sh abort apps/apps"                        ##�R���J�����g�}�l�[�W����~�R�}���h

### �R���J�����g�}�l�[�W����~ ###

  L_rogushuturyoku "�R���J�����g�}�l�[�W�����~���܂��B"

  ${L_konkarentoteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Aadcmctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01600}"
  else
      L_rogushuturyoku "${TE_ZCZZ01601}"
      echo "${TE_ZCZZ01601}" 1>&2
      L_shuryo ${L_ijou}
  fi


## �R���J�����g�}�l�[�W����~�m�F
  L_rogushuturyoku "�R���J�����g�}�l�[�W����~�m�F"
  L_rogushuturyoku "�R���J�����g�}�l�[�W���̒�~��҂��Ă��܂��B"
  
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZ_WAITCNT}" ]
  do  
  sleep ${TE_ZCZZCONCTAIKI}
##2014/07/31 S.Takahashi Mod Start  
#  /usr/bin/ps -ef | grep `/usr/bin/whoami` |/usr/bin/egrep "FNDLIBR |FNDSM" | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
  /usr/bin/ps -ef | grep `/usr/bin/whoami` |/usr/bin/egrep "FNDLIBR|FNDSM|FNDIMON" | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
##2014/07/31 S.Takahashi Mod End
     if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
       then
        if [ "$cnt" -eq "${TE_ZCZZ_WAITCNT}" ]
         then
           L_rogushuturyoku "${TE_ZCZZ01601}"
           echo "${TE_ZCZZ01601}" 1>&2
            L_shuryo ${L_ijou}
        fi
     
     else
        break;
     fi

     let cnt=cnt+1
  done

  L_rogushuturyoku "�R���J�����g�}�l�[�W���̒�~���m�F���܂����B"


### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
