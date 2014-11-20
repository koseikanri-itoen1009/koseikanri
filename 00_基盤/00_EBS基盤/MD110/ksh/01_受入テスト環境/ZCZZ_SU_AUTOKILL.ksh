#!/bin/ksh
################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##      �ꎞ�\�̈��1���Ԉȏ�g�p���Ă��鉺�L�@�\�̃v���Z�X��kill����(T4�p)   ##
##          1:�N�C�b�N��(OEXOETEL)                                          ##
##          2:AR����(ARXRWMAI)                                                ##
##          3:AR���(ARXTWMAI)                                                ##
##          4:AR���(ARXCWMAI)                                                ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCS �g��              2011/07/13 1.0.0                 ##
##        �X�V�����F                                                          ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      ZCZZ_SU_AUTOKILL.ksh                                                  ##
##                                                                            ##
##    Copyright ������Јɓ��� U5000�v���W�F�N�g 2007-2009                    ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t
L_rogupasu="/var/log/jp1/T4"             #���O�p�X
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .sh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����

##�V�F���ŗL���ϐ�
KILL_PID_LIST=/var/tmp/ZCZZ_kill_pid_list_temp.lst    #kill�Ώ�PID���X�g�ꎞ�t�@�C��

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
   
   L_modorichi=${1:-0}
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
   echo "ZCZZ00003:[Error] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I��"
   L_shuryo 8
fi

### DB���ݒ� ###
if [ -r ${TE_ZCZZDB} ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[Error] ZCZZDB.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I��"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

###�ꎞ�\�̈� kill�Ώ�PID�擾
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> /dev/null
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 120
set pages 500
col name format a50
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set head off
set feedback off
spool ${KILL_PID_LIST}

SELECT s.module
      ,p.spid
      ,s.sql_id
      ,MAX(s.seconds_in_wait) seconds_in_wait
FROM   v\$sort_usage su
      ,v\$session    s
      ,v\$process    p
      ,fnd_lookup_values_vl lvvl
WHERE  su.session_addr = s.saddr
AND    s.paddr         = p.addr
AND    s.status        = 'ACTIVE'
AND    s.module        = lvvl.meaning
AND    lvvl.lookup_type  = 'XXCCP1_SU_KILL_MODULE'
AND    lvvl.enabled_flag = 'Y'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
                          AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
AND    s.seconds_in_wait >= 3600
GROUP BY s.module
        ,p.spid
        ,s.sql_id;

spool off
exit
EOF

### SQL �I������ ###

if [ $? != 0 ]
then
   echo "[ERROR]:kill�Ώ�PID�擾�Ɏ��s���܂���" >> ${L_rogumei}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I��"
   exit 8
fi

### �v���Z�Xkill ###
while read L_MODULE L_KILL_PID L_SQL_ID L_SESSION_IN_WAIT
do 
   if [ -n "${L_KILL_PID}" ] #�󔒍s����ispool�t�@�C����1�s�ڂ����s�݂̂̂��߁j
   then
       L_rogushuturyoku "kill MODULE : ${L_MODULE} PID : ${L_KILL_PID} SQL_ID : ${L_SQL_ID} SESSION_IN_WAIT : ${L_SESSION_IN_WAIT}"
       kill -9 ${L_KILL_PID}
   fi
   sleep 1

done < ${KILL_PID_LIST}

### ���X�g�t�@�C���폜 ###
rm -f ${KILL_PID_LIST} >> ${L_rogumei}

### �����J�n�o�� ###
L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I��"

L_shuryo ${TE_ZCZZSEIJOUSHURYO}
