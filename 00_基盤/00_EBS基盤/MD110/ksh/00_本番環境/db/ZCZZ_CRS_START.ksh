#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          DB�I�����C���ECRS�T�[�r�X�N������                                 ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/05/22 1.0.1                 ##
##        �X�V�����F   Oracle �x��           2008/05/22 1.0.1                 ##
##                       ����                                                 ##
##                     SCSK ����             2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �E���ˑ��l�̕ϐ���                               ##
##                         �ECRS�̊��ݒ�t�@�C���̓ǂݍ��݂�ǉ�            ##
##                         �ECRS�N�������̕ύX                                ##
##                         �ECRS�̋N���m�F���̔�����@��ύX                  ##
##                         �E�J�n���b�Z�[�WID�ύX                             ##
##                         �E�V�F�����ύX                                     ##
##                         �ECRS�N����ASM�C���X�^���X�N���܂ł̎��Ԃ��l����   ##
##                           ���[�v������ǉ�                                 ##
##                     SCSK �k��             2015/03/26 2.0.1                 ##
##                       E_�{�ғ�_12712�Ή�                                   ##
##                         �ECRS�N���m�F�����ύX                              ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_CRS_START.ksh                      ##
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
  L_crsfairumei="ZCZZCRS.env"        ##CRS���ݒ�t�@�C����
##2014/07/31 S.Takahashi Add End
  L_ijou=8                           ##�V�F���ُ�I�����̃��^�[���R�[�h

## �t�@�C����`
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##���O�t�@�C��(�t���p�X)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)
##2014/07/31 S.Takahashi Add Start
  L_crsfairu=`/usr/bin/dirname $0`"/${L_crsfairumei}"                                               ##CRS���ݒ�t�@�C��(�t���p�X)
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

    ### �p�[�~�b�V�����ύX ###
    chmod 666 ${L_rogumei}
    
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
## CRS���ݒ�t�@�C���ǂݍ���
  L_rogushuturyoku "CRS���ݒ�t�@�C����ǂݍ��݂܂��B"

  if [ -r "${L_crsfairu}" ]
    then
      . ${L_crsfairu}
      L_rogushuturyoku "CRS���ݒ�t�@�C����ǂݍ��݂܂����B"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_crsfairu}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_crsfairu}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}" 1>&2
      L_shuryo ${L_ijou}
  fi
##2014/07/31 S.Takahashi Add End


## �R�}���h�ݒ�
##2014/07/31 S.Takahashi Mod Start
#  L_crskaisi="/ebsloc/PEBSITO/PEBSITOcrs/10.2.0/bin/crsctl start crs"   ##CRS�N���R�}���h
  L_crskaisi="crsctl start crs"   ##CRS�N���R�}���h
##2014/07/31 S.Takahashi Mod End

### CRS�N�� ###

  L_rogushuturyoku "CRS���N�����܂��B"

  ${L_crskaisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Acrsctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01300}"
  else
    L_rogushuturyoku "${TE_ZCZZ01301}"
    echo "${TE_ZCZZ01301}" 1>&2
    L_shuryo ${L_ijou}
  fi


### CRS�N���m�F ###

  L_rogushuturyoku "CRS�N���m�F"
  L_rogushuturyoku "CRS�̋N����҂��Ă��܂��B"
##2014/07/31 S.Takahashi Mod Start
#  sleep ${TE_ZCZZCRSTAIKI}
#
#  /usr/bin/ps -ef | /usr/bin/grep "ocssd.bin" | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#
#  if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -eq 0 ]
#    then
#      L_rogushuturyoku "${TE_ZCZZ01301}"
#      echo "${TE_ZCZZ01301}" 1>&2
#      L_shuryo ${L_ijou}
#  fi
##2015/03/26 T.Kitagawa Add Start
## �R�}���h�E�ϐ��ݒ�
  L_crschk_cmd="crsctl check crs"                   ##CRS�T�[�r�X�`�F�b�N�R�}���h
  L_crsstat_cmd="crsctl status resource -t -init"   ##CRS���\�[�X�`�F�b�N�R�}���h
  L_crschk_str="online"                             ##CRS�T�[�r�X�̋N������Ώە�����
  L_crsstat_str="ONLINE +ONLINE"                    ##CRS���\�[�X�̋N������Ώە�����(���K�\��)
  L_crschk_num=4                                    ##CRS�T�[�r�X��online�̐�
  L_crsstat_num=12                                  ##CRS���\�[�X��"ONLINE ONLINE"�̐�
##2015/03/26 T.Kitagawa Add End
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZCRS_WAITCNT}" ]
  do  
    sleep ${TE_ZCZZCRSTAIKI}

##2015/03/26 T.Kitagawa Mod Start
#    /usr/bin/ps -ef | /usr/bin/egrep 'ocssd.bin|osysmond.bin|asm_pmon|LISTENER_ASM' | /usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#
#    if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -lt 4 ]
#      then
#        if [ "$cnt" -eq "${TE_ZCZZCRS_WAITCNT}" ]
#         then
#           L_rogushuturyoku "${TE_ZCZZ01301}"
#           echo "${TE_ZCZZ01301}" 1>&2
#           L_shuryo ${L_ijou}
#        fi
#    elif [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ge 4 ]
#      then
#        break;
#    fi
    L_rogushuturyoku "$cnt��ڊm�F"
    L_rogushuturyoku "${L_crschk_cmd} �m�F"

    ##CRS�T�[�r�X�`�F�b�N�R�}���h���ʂ�W���o�́E�G���[�t�@�C���ɏ㏑��
    ${L_crschk_cmd} 1> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

    ##�W���o�̓t�@�C���ɏo�͂���Ă���${L_crschk_str}�̌��̔���
    if [ `/usr/bin/grep ${L_crschk_str} ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l` -eq ${L_crschk_num} ]
      then
        L_rogushuturyoku "${L_crsstat_cmd} �m�F"

        ##CRS���\�[�X�`�F�b�N�R�}���h���ʂ�W���o�́E�G���[�t�@�C���ɒǋL
        ${L_crsstat_cmd} 1>> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2>> ${TE_ZCZZHYOUJUNERA}

        ##�W���o�̓t�@�C���ɏo�͂���Ă���${L_crsstat_str}�̌��̔���
        if [ `/usr/bin/grep -E "${L_crsstat_str}" ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l` -eq ${L_crsstat_num} ]
          then
            ##CRS�N���m�F�I��(���[�v�I��)
            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
            break;
        fi
    fi

    ##����񐔊m�F
    if [ "$cnt" -eq "${TE_ZCZZCRS_WAITCNT}" ]
      then
        ##�`�F�b�N�R�}���h�m�F���w�蔻��񐔈ȓ��Ɋ������Ȃ��ꍇ�G���[
        L_rogushuturyoku "${TE_ZCZZ01301}"
        echo "${TE_ZCZZ01301}" 1>&2
        /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
        L_shuryo ${L_ijou}
    fi
##2015/03/26 T.Kitagawa Mod End

    let cnt=cnt+1
  done
##2014/07/31 S.Takahashi Mod End

  L_rogushuturyoku "CRS�̋N�����m�F���܂����B"


### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
