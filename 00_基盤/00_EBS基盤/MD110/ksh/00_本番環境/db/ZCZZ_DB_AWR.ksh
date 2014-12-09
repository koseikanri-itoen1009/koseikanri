#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          �f�[�^�x�[�X��AWR�����s����BEBS��~���O�A�N������Ɏ��s����A    ##
##          �ُ�I�������ꍇ�͖߂�l��5�Ƃ��Č㑱�̃W���u�����s����B         ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCSK   ���           2014/07/31 2.0.0                 ##
##        �X�V�����F   SCSK   ���           2014/07/31 2.0.0                 ##
##                       ����/HW���v���[�X�Ή�(���v���[�X_00007)              ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      5 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_DB_AWR.ksh                         ##
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
  L_keikokushuryo="5"                ##�x���I���R�[�h

## �t�@�C����`
  L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"       ##���O�t�@�C��(�t���p�X)
  L_enbufairu=`/usr/bin/dirname $0`"/${L_enbufairumei}"                                             ##��Ջ��ʊ��ϐ��t�@�C��(�t���p�X)



################################################################################
##                                 �֐���`                                   ##
################################################################################

### ���O�o�͏��� ###
L_rogushuturyoku()
{
   echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@} >> ${L_rogumei}
}

### �I������ ###
L_shuryo()
{
   ### �ꎞ�t�@�C���폜 ###
   if [ -f ${TE_ZCZZHYOUJUNERA} ]
   then
      L_rogushuturyoku "�ꎞ�t�@�C���폜���s"
      rm ${TE_ZCZZHYOUJUNERA}
   fi
   
   L_modorichi=${1:-0}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I��  END_CD="${L_modorichi}
   exit ${L_modorichi}
}

### trap ���� ###
trap 'L_shuryo 5' 1 2 3 15

################################################################################
##                                   Main                                     ##
################################################################################

### �����J�n�o�� ###
L_rogushuturyoku "ZCZZ00001:${L_sherumei} �J�n"


### ���ݒ�t�@�C���Ǎ��� ###
L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �J�n"

### ��Ջ��ʊ��ϐ� ###
if [ -r ${L_enbufairu} ]
then
   . ${L_enbufairu}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 5
fi

### DB���ݒ� ###
if [ -r ${TE_ZCZZDB} ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[Error] ZCZZDB.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${L_keikokushuryo}
fi

L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �I��"


### AWR�擾 ###
L_rogushuturyoku "AWR�擾 �J�n"

#AWR���s
${ORACLE_HOME}/bin/sqlplus -s / as sysdba  << EOF >> ${L_rogumei} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

execute dbms_workload_repository.create_snapshot(flush_level => 'TYPICAL');
exit
EOF

#���s���ʔ���
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01800} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${L_keikokushuryo}
fi

L_rogushuturyoku "AWR�擾 �I��"


### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
