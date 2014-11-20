#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          DB�I�����C���ECRS�T�[�r�X��~����                                 ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/05/22 1.0.1                 ##
##        �X�V�����F   Oracle ����           2008/10/02 1.1.0                 ##
##                     SCS    ��c           2008/11/28 1.2.0                 ##
##                       1.2��                                                ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      ZCZZ_PEBSCRS_STOP.ksh                                                 ##
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
## 2008/11/28 CRS�ϐ���`�ǉ� ��c
  L_crsfairumei="ZCZZCRS.env"        ##CRS���ݒ�t�@�C����
## 2008/11/28 �ǉ�END
  L_ijou=8                           ##�V�F���ُ�I�����̃��^�[���R�[�h

## �t�@�C����`
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##���O�t�@�C��(�t���p�X)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)
## 2008/11/28 CRS�t�@�C����`�ǉ� ��c
  L_crsfairu=`/usr/bin/dirname $0`"/${L_crsfairumei}"                                               ##CRS���ݒ�t�@�C��(�t���p�X)
## 2008/11/28 �ǉ�END


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

## 2008/11/28 �ǉ� ��c
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
## 2008/11/28 �ǉ�END


## �R�}���h�ݒ�

  L_crsteisi="/ebsloc/PEBSITO/PEBSITOcrs/10.2.0/bin/crsctl stop crs"   ##CRS��~�R�}���h

## 2008/11/28 CRS���\�[�X��~�R�}���h�ǉ� ��c
  L_crsappsteisi="/ebsloc/PEBSITO/PEBSITOcrs/10.2.0/bin/srvctl stop nodeapps -n ${L_hosutomei}"
## 2008/11/28 �ǉ�END


### CRS��~ ###

  L_rogushuturyoku "CRS���~���܂��B"

## 2008/11/28 CRS���\�[�X��~�R�}���h�ǉ� ��c
  ${L_crsappsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
## 2008/11/28 �ǉ�END

  ${L_crsteisi} 1>${TE_ZCZZHYOUJUNSHUTURYOKU} 2>${TE_ZCZZHYOUJUNERA}
  L_dashutu=${?}
  /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei} 

## �߂�l����Acrsctl�̓���𔻒�
  if [ ${L_dashutu} -eq 0 ]
    then
      L_rogushuturyoku "${TE_ZCZZ01400}"
  else
    L_rogushuturyoku "${TE_ZCZZ01401}"
    echo "${TE_ZCZZ01401}" 1>&2
    L_shuryo ${L_ijou}
  fi


### CRS��~�m�F ###

  L_rogushuturyoku "CRS��~�m�F"
  L_rogushuturyoku "CRS�̒�~��҂��Ă��܂��B"
  
  let cnt=1
  while [ "$cnt" -le "${TE_ZCZZ_WAITCNT}" ]
  do
     sleep ${TE_ZCZZCRSTAIKI}
     /usr/bin/ps -ef | /usr/bin/egrep "ocssd.bin |evmd.bin |evmlogger.bin |oclsomon.bin |crsd.bin |ons -d |crs/10.2.0/jdk/jre/bin/java" |/usr/bin/grep -v "grep" | /usr/bin/wc -l > ${TE_ZCZZHYOUJUNSHUTURYOKU}
     if [ `/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU}` -ne 0 ]
       then
        if [ "$cnt" -eq "${TE_ZCZZ_WAITCNT}" ]
         then
            L_rogushuturyoku "${TE_ZCZZ01401}"
            echo "${TE_ZCZZ01401}" 1>&2
            L_shuryo ${L_ijou}
        fi
     
     else
        break;
     fi

     let cnt=cnt+1
  done

  L_rogushuturyoku "CRS�̒�~���m�F���܂����B"

### �V�F���̏I�� ###

  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
