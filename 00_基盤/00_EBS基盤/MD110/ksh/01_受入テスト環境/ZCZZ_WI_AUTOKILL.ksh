#!/bin/ksh
################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##      PGA��臒l�ȏ�g�p���Ă���Z�b�V������kill����(T4�p)                   ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCS ��c              2010/02/22 1.0.0                 ##
##        �X�V�����F   SCS ��c              2010/02/22 1.0.0                 ##
##        �X�V�����F   SCS �k��              2010/03/23 1.0.1                 ##
##                       臒l��2GB����1GB�ɕύX                               ##
##        �X�V�����F   SCS �g��              2011/10/04 1.0.2                 ##
##                       臒l�ɐ�L���Ԃ�ǉ�                                 ##
##                       �Ώۋ@�\���Q�ƃ^�C�v��`�ɕύX                       ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      1 : �e��(MB)                                                          ##
##      2 : ����(�b)                                                          ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      ZCZZ_WI_AUTOKILL.ksh                                                  ##
##                                                                            ##
##    Copyright ������Јɓ��� U5000�v���W�F�N�g 2007-2009                    ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t
L_rogupasu="/var/log/jp1/T4"    #���O�p�X
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .sh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����

##�V�F���ŗL���ϐ�
KILL_PID_LIST=/var/tmp/ZCZZ_kill_pid_list_temp2.lst    #kill�Ώ�PID���X�g�ꎞ�t�@�C��

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
  
  L_Modorichi=${1:-0}
  exit ${L_Modorichi}
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
## 2011/10/04 t.yoshimoto Mod Start E_�{�ғ�_07971
##   echo "ZCZZ00003:[Error] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
  echo "ZCZZ00003:[Error] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei} STATUS:8" \
       | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
## 2011/10/04 t.yoshimoto Mod End E_�{�ғ�_07971
  L_shuryo 8
fi

### DB���ݒ� ###
if [ -r ${TE_ZCZZDB} ]
then
  . ${TE_ZCZZDB}
else
## 2011/10/04 t.yoshimoto Mod Start E_�{�ғ�_07971
##   echo "ZCZZ00003:[Error] ZCZZDB.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
  echo "ZCZZ00003:[Error] ZCZZDB.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei} STATUS:${TE_ZCZZIJOUSHURYO}" \
       | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
##   L_shuryo ${TE_ZCZZKEIKOKUSHURYO}
  L_shuryo ${TE_ZCZZIJOUSHURYO}
## 2011/10/04 t.yoshimoto Mod End E_�{�ғ�_07971
fi

## 2011/10/04 t.yoshimoto Add Start E_�{�ғ�_07971
### IN�p�����[�^�擾 ###
L_para1=${1}
L_para2=${2}
## 2011/10/04 t.yoshimoto Add End E_�{�ғ�_07971

### kill�Ώ�PID�擾 ###
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
-- 2011/10/04 t.yoshimoto Mod Start E_�{�ғ�_07971
--select p.spid, s.SQL_ID, round(p.PGA_USED_MEM/1024/1024) PGA_MG
--from v\$session s, v\$process p
--where s.paddr = p.addr and status = 'ACTIVE' and Module is not null and round(p.PGA_USED_MEM/1024/1024) > 1000
--and s.Module in ('ARWI', 'GLWI');
SELECT p.spid
      ,s.sql_id
      ,ROUND(p.pga_used_mem / 1024 / 1024) pga_mg
      ,s.seconds_in_wait
FROM v\$session s
    ,v\$process p
    ,fnd_lookup_values_vl lvvl
WHERE s.paddr           = p.addr
AND   s.status          = 'ACTIVE'
AND   s.module          = lvvl.meaning
AND   lvvl.lookup_type  = 'XXCCP1_WI_KILL_MODULE'
AND   lvvl.enabled_flag = 'Y'
AND   TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
                         AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
AND   ((ROUND(p.pga_used_mem / 1024 / 1024) > ${L_para1} )
  OR   (s.seconds_in_wait >= ${L_para2}));
-- 2011/10/04 t.yoshimoto Mod End E_�{�ғ�_07971
spool off
exit
EOF

### SQL �I������ ###

if [ $? != 0 ]
then
## 2011/10/04 t.yoshimoto Mod Start E_�{�ғ�_07971
##   echo "[ERROR]:kill�Ώ�PID�擾�Ɏ��s���܂���" >> ${L_rogumei}
##   exit 8
  echo "[ERROR]:kill�Ώ�PID�擾�Ɏ��s���܂����B STATUS:${TE_ZCZZIJOUSHURYO}" >> ${L_rogumei}
  exit ${TE_ZCZZIJOUSHURYO}
## 2011/10/04 t.yoshimoto Mod Start E_�{�ғ�_07971
fi

### webInquiry�v���Z�Xkill ###
## 2011/10/04 t.yoshimoto Mod Start E_�{�ғ�_07971
##while read L_KILL_PID L_SQL_ID L_PGA_SIZE
while read L_KILL_PID L_SQL_ID L_PGA_SIZE L_SESSION_IN_WAIT
## 2011/10/04 t.yoshimoto Mod End E_�{�ғ�_07971
do 
  if [ -n "${L_KILL_PID}" ] #�󔒍s����ispool�t�@�C����1�s�ڂ����s�݂̂̂��߁j
  then
## 2011/10/04 t.yoshimoto Mod Start E_�{�ғ�_07971
##       L_rogushuturyoku "kill PID : ${L_KILL_PID} SQL_ID : ${L_SQL_ID} PGA_SIZE : ${L_PGA_SIZE}"
    L_rogushuturyoku "kill PID : ${L_KILL_PID} SQL_ID : ${L_SQL_ID} PGA_SIZE : ${L_PGA_SIZE} SESSION_IN_WAIT : ${L_SESSION_IN_WAIT}"
## 2011/10/04 t.yoshimoto Mod End E_�{�ғ�_07971
    kill -9 ${L_KILL_PID}

  fi
  sleep 1

done < ${KILL_PID_LIST}

### ���X�g�t�@�C���폜 ###
rm -f ${KILL_PID_LIST} >> ${L_rogumei}

## 2011/10/04 t.yoshimoto Add Start E_�{�ғ�_07971
### �����I���o�́i����j ###
L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I�� STATUS:${TE_ZCZZSEIJOUSHURYO}"
## 2011/10/04 t.yoshimoto Add End E_�{�ғ�_07971
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
