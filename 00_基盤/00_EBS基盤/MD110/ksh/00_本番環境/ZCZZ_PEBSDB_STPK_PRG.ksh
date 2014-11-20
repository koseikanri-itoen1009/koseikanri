#!/bin/ksh

################################################################################
##                                                                            ##
##   [�t�@�C����]                                                             ##
##      ZCZZ_PEBSDB_STPK_PRG.ksh                                              ##
##                                                                            ##
##   [�W���u��]                                                               ##
##      STATSPACK�f�[�^�p�[�W�W���u                                           ##
##                                                                            ##
##   [�T�v]                                                                   ##
##      �f�[�^�x�[�X�̊č��f�[�^�̍폜�����{����B                            ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCS ���_              2009/07/09 1.0.1                 ##
##        �X�V�����F   SCS ���_              2009/07/09 1.0.1                 ##
##                       ����                                                 ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##    Copyright ������Јɓ��� U5000�v���W�F�N�g 2007-2009                    ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #���O�p�X
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����


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

### ���s�X�e�[�^�X�m�F ###
L_jyoutaikakunin()
{
   #���s�X�e�[�^�X�擾
   L_konkarento_jyoutai=`awk 'NR==4 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
   L_rogushuturyoku "STATUS_CD="${L_konkarento_jyoutai}

   #���s�X�e�[�^�X����
   if [ "${L_konkarento_jyoutai}" != 'C' ]     #C:����
   then
      echo ${L_era_messeige} "STATUS_CD="${L_konkarento_jyoutai} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
      /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
      L_shuryo ${TE_ZCZZIJOUSHURYO}
   fi

   L_rogushuturyoku "���s�X�e�[�^�X�m�F �I��"
}

### trap ���� ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                   Main                                     ##
################################################################################

### �����J�n�o�� ###
L_rogushuturyoku "ZCZZ00001:${L_sherumei} �J�n"


### ���ݒ�t�@�C���Ǎ��� ###
L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �J�n"

### ��Ջ��ʊ��ϐ� ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

### �R���J�����g���ݒ� ###
if [ -r ${TE_ZCZZCONC} ]
then
   . ${TE_ZCZZCONC}
else
   echo "ZCZZ00003:[Error] ZCZZCONC.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �I��"


### STATSPACK�f�[�^�p�[�W ###
L_rogushuturyoku "STATSPACK�f�[�^�p�[�W �J�n"

#STATSPACK�f�[�^�폜���s
#STATSPACK�f�[�^�폜���s
${ORACLE_HOME}/bin/sqlplus -s perfstat/perfstat << EOF >> ${L_rogumei} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

execute statspack.purge(i_purge_before_date=>sysdate - ${TE_ZCZZHOZONKIKAN_STPK} , i_extended_purge => true , i_dbid => 2495813589, i_instance_number => 1);
execute statspack.purge(i_purge_before_date=>sysdate - ${TE_ZCZZHOZONKIKAN_STPK} , i_extended_purge => true , i_dbid => 2495813589, i_instance_number => 2);
execute statspack.purge(i_purge_before_date=>sysdate - ${TE_ZCZZHOZONKIKAN_STPK} , i_extended_purge => true , i_dbid => 2495813589, i_instance_number => 3);
exit
EOF

#���s���ʔ���
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01108} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "STATSPACK�f�[�^�p�[�W �I��"

### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
