#!/bin/ksh
################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##      �Ď��Ώۋ@�\�������ԑ��s�y�і�ԃo�b�`�J�n���Ԏ��_�Ŏ��s����Ă��Ȃ���##
##      �`�F�b�N���܂��B                                                      ##
##          �Ď��Ώۋ@�\�͎Q�ƃ^�C�v�ɂĐݒ�                                  ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCSK ���R             2015/06/12 1.0.0                 ##
##        �X�V��  �F   SCSK ���R             2016/06/21 1.0.1                 ##
##                  E_�{�ғ�_13681�Ή� �Ď��Ώۃ��[�U���w��Ή�               ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_CONC_CHECK.ksh                     ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

##���ˑ��l
L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##�ŉ��w�̃J�����g�f�B���N�g����

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t

L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"    #���O�t�@�C���i�[�f�B���N�g��
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����

##�V�F���ŗL���ϐ��p
LIMIT_OVER_LIST=/uspg/jp1/zc/shl/${L_kankyoumei}/tmp/ZCZZ_CONC_CHECK_temp.lst    #�Ώۃ��X�g�ꎞ�t�@�C��

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
   ### ���X�g�t�@�C���폜 ###
   if [ -f ${LIMIT_OVER_LIST} ]; then
     rm ${LIMIT_OVER_LIST}
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

### ��Ջ��ʊ��ϐ� ###
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env ��������܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

### DB���ݒ� ###
if [ -r ${TE_ZCZZDB} ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[Error] ZCZZDB.env ��������܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

###�����ԑ��s�R���J�����g�擾
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> /dev/null
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 200
set pages 500
col name format a50
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set head off
set feedback off
spool ${LIMIT_OVER_LIST}

SELECT
       fcpv.user_concurrent_program_name                                     || '  ' ||
       '�������ԑ��s���Ă��܂��B'                                            || '  ' ||
       '�v��ID:' || request_id                                               || '  ' ||
       '�X�e�[�^�X:' || decode(fcr.phase_code,'P','�ۗ�','R','���s��')       || '  ' ||
       '�J�n(���s)����:' || TO_CHAR(NVL(fcr.actual_start_date,fcr.requested_start_date),'YYYY/MM/DD HH24:MI:SS') || '  ' ||
       '���s(�ۗ�)����:' || TRUNC( TO_NUMBER( SYSDATE - NVL(fcr.actual_start_date,fcr.requested_start_date)) * 86400 )
FROM   apps.fnd_lookup_values           flv
      ,apps.fnd_concurrent_programs_vl  fcpv
      ,apps.fnd_concurrent_requests     fcr
      ,apps.fnd_user                    fu
WHERE  flv.lookup_type     = 'XXCCP_CONCURRENT_LIMIT_TIME'
AND    TRUNC(SYSDATE)  BETWEEN NVL(flv.start_date_active,TRUNC(SYSDATE))
                          AND  NVL(flv.end_date_active,  TRUNC(SYSDATE))
AND    flv.enabled_flag    = 'Y'
AND    flv.language        = userenv('LANG')
AND    flv.lookup_code     = fcpv.concurrent_program_name
AND    fcpv.concurrent_program_id = fcr.concurrent_program_id
AND    fcpv.application_id = fcr.program_application_id
AND    fcr.phase_code     in ('R','P')
-- Ver1.0.1 2016-06-21 MOD Start
-- AND    flv.attribute3,fu.user_name      = fu.user_name
AND    NVL(flv.attribute3,fu.user_name) = fu.user_name
-- Ver1.0.1 2016-06-21 MOD End
AND    fu.user_id          = fcr.requested_by
AND   (
        ( TRUNC(SYSDATE,'MI') >= TO_DATE(TO_CHAR(SYSDATE,'YYYY/MM/DD')||' ' ||flv.attribute2,'YYYY/MM/DD HH24:MI'))
        OR
        ( TRUNC( TO_NUMBER( SYSDATE - NVL(fcr.actual_start_date,fcr.requested_start_date)) * 86400 ) >= TO_NUMBER( flv.attribute1 ) ) 
       );

spool off
exit
EOF

### SQL �I������ ###

if [ $? != 0 ]
then
   echo "[ERROR]:�����ԑ��s�R���J�����g�擾�Ɏ��s���܂���" | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### �G���[�ΏۗL������ ###
if [ -s ${LIMIT_OVER_LIST} ]; then
  echo "�Ώۂ���" | /usr/bin/tee -a ${L_rogumei} 1>&2
else
  echo "�ΏۂȂ�" | /usr/bin/tee -a ${L_rogumei} 1>&2
  L_shuryo ${TE_ZCZZSEIJOUSHURYO}
fi

### �G���[�o�� ###
while read L_MESSAGE
do 
   if [ -n "${L_MESSAGE}" ] #�󔒍s����ispool�t�@�C����1�s�ڂ����s�݂̂̂��߁j
   then
       L_rogushuturyoku "ZCZZ00004:${L_MESSAGE}"
   fi

done < ${LIMIT_OVER_LIST}

L_shuryo ${TE_ZCZZIJOUSHURYO}

