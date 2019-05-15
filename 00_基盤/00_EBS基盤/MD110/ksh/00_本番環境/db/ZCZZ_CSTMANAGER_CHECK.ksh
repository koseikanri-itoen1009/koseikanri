#!/bin/ksh

################################################################################
##                                                                            ##
##   [�t�@�C����]                                                             ##
##      ZCZZ_CSTMANAGER_CHECK.ksh                                             ##
##                                                                            ##
##   [�T�v]                                                                   ##
##      �ŐV�̃R�X�g�}�l�[�W�����G���[�ƂȂ��Ă��Ȃ����Ƃ��`�F�b�N���܂�      ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCSK ���R             2019/05/14 1.0.0                 ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_CONC_CANCEL_CHECK.ksh              ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

L_kankyoumei=`echo $(cd $(dirname $0) && pwd)|sed -e "s/.*\///"`     #�ŉ��w�̃J�����g�f�B���N�g����
L_sherumei=`/bin/basename $0`                   #�V�F����
L_hosutomei=`/bin/hostname`                     #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`                  #���t
L_jikan=`/bin/date "+%Y%m%d%H%M"`               #���t+���ݎ���
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"   #���O�t�@�C���i�[�f�B���N�g��
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����
L_hikisu=`echo ${1} | tr [a-z] [A-Z]`           #����(all�Anight�A���l)
L_amari=0                                       #�ϐ���{���Ŋ��������̗]��(������)
L_tsuikajouken=""                               #SQL�̒ǉ�����(������)

### ���ϐ��ݒ� ###
export NLS_LANG=American_America.JA16SJIS       #SQL�̌��ʂ𕶎����������Ȃ��ݒ�

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
   if [ -f "${TE_ZCZZHYOUJUNSHUTURYOKU}" ]
   then
      L_rogushuturyoku "�W���o�͈ꎞ�t�@�C���폜���s"
      rm ${TE_ZCZZHYOUJUNSHUTURYOKU}
   fi
   if [ -f "${TE_ZCZZHYOUJUNERA}" ]
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
##                                   Main                                     ##
################################################################################

### �����J�n�o�� ###
L_rogushuturyoku "ZCZZ00001:${L_sherumei} �J�n"

### ���ݒ�t�@�C���Ǎ��� ###
L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �J�n"

### ��Ջ��ʊ��ϐ� ###
if [ -r "${L_zczzcomn}" ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[�G���[] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

### ���DB���ϐ� ###
if [ -r "${TE_ZCZZDB}" ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[�G���[] ZCZZDB.env �����݂��Ȃ��A�܂��͌�����܂���B  HOST=${L_hosutomei}" | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### �R�X�g�}�l�[�W�����s�m�F ###
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SET LINES 200
SET PAGES 500
SET HEAD OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_LANGUAGE='Japanese';

SELECT fcr.request_id RequestId,
       fcr.request_date RequestDt,
       fcr.phase_code Phase,
       fcr.status_code Status,
       fcr.last_update_date
       FROM
       apps.fnd_concurrent_requests fcr,
       apps.fnd_concurrent_programs fcp
       WHERE fcp.application_id = 702
       AND fcp.concurrent_program_name = 'CMCTCM'
       AND fcr.concurrent_program_id = fcp.concurrent_program_id
       AND fcr.phase_code = 'C'
       AND fcr.REQUEST_ID =  (SELECT max(fcr2.request_id)
                                FROM apps.fnd_concurrent_requests fcr2,
                                     apps.fnd_concurrent_programs fcp2
                               WHERE fcp2.application_id = 702
                                 AND fcp2.concurrent_program_name = 'CMCTCM'
                                 AND fcr2.concurrent_program_id = fcp2.concurrent_program_id )
;

exit
EOF

### SQL �I������ ###
if [ $? -ne 0 ]
then
##   L_rogushuturyoku "${TE_ZCZZ02101}"
##   echo "${TE_ZCZZ02101}" 1>&2
##   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "�R�X�g�}�l�[�W���ғ��󋵎擾�ŃG���[����"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### ���s���R�X�g�}�l�[�W�����݃`�F�b�N ###
if [ `/usr/bin/cat "${TE_ZCZZHYOUJUNSHUTURYOKU}" | wc -l` -ne 0 ]
then
##   L_rogushuturyoku "${TE_ZCZZ02102}"
##   echo "${TE_ZCZZ02102}" 1>&2
##   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "�R�X�g�}�l�[�W�����ғ����Ă��܂���B"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
