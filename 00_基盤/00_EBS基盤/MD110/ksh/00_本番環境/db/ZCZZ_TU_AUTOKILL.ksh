#!/bin/ksh
################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##      �ꎞ�\�̈���w��T�C�Y�ȏ�g�p���Ă���Z�b�V������kill����            ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCSK �A��             2019/09/26 1.0.0                 ##
##        �X�V�����F   SCSK �A��             2020/08/07 1.1.0                 ##
##                       E_�{�ғ�_16487�y��Ձz�ꎞ�\�̈�̊g���G���[�����Ή� ##
##                             �E�Ώ�SQL ID���Q�ƃ^�C�v����擾               ##
##                             �E���O�ɎQ�ƃ^�C�v�̑Ώۋ@�\�����o��           ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      1 : �e��(GB)                                                          ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_TU_AUTOKILL.ksh                    ##
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
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O�� E_�{�ғ�_16487�Ή� Rev1.1.0 �g���q�C�� 
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����

### IN�p�����[�^�擾 ###
## 臒l��GB�P�ʂŎw��
if [ ${1} -ge 0 ]
then
   GSIZE=${1}
else
   GSIZE=30
fi

##�V�F���ŗL���ϐ�
KILL_SID_LIST=/uspg/jp1/zc/shl/tmp/ZCZZ_kill_sid_list_temp.lst    #kill�Ώ�SID���X�g�ꎞ�t�@�C��
KILL_SID_LIST2=/uspg/jp1/zc/shl/tmp/ZCZZ_kill_sid_list_temp2.lst    #kill�Ώ�SID���X�g�ꎞ�t�@�C��

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
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I�� (${TE_ZCZZIJOUSHURYO})"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### DB���ݒ� ###
if [ -r ${TE_ZCZZDB} ]
then
   . ${TE_ZCZZDB}
else
   echo "ZCZZ00003:[Error] ZCZZDB.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I�� (${TE_ZCZZIJOUSHURYO})"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### �ꎞ�\�̈� kill�Ώۊm�F ###
${ORACLE_HOME}/bin/sqlplus -s apps/apps<< EOF1 >> /dev/null  # E_�{�ғ�_16487�Ή� Rev1.1.0 ���s�X�L�[�}�ύX
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 500
set pages 500
col name format a50
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set head off
set feedback off
set trim on
set trims on
set colsep ','
spool ${KILL_SID_LIST}

select
    sample_time
   ,session_id
   ,session_serial#
   ,seq#
   ,user_id
   ,sql_id
   ,top_level_sql_id
   ,event
   ,session_state
   ,program
   ,machine
   ,temp_space_allocated / 1024 / 1024 / 1024 temp_alloc_gb
   ,lvvl.DESCRIPTION    -- E_�{�ғ�_16487�Ή� Rev1.1.0 �Q�ƃ^�C�v�E�E�v(�@�\��)�ǉ�
from
    v\$active_session_history
   ,fnd_lookup_values_vl lvvl    -- E_�{�ғ�_16487�Ή� Rev1.1.0 �Q�ƃ^�C�v�ǉ�
where
    (temp_space_allocated / 1024 / 1024 / 1024) > ${GSIZE}
-- E_�{�ғ�_16487�Ή� Rev1.1.0 �C���J�n
--    and sql_id in('12wxxxpfgfq49', '8wt3rn9z02c0k', 'b5juyc9qavq7y')
    and sql_id = lvvl.meaning
    and lvvl.lookup_type  = 'XXCCP1_TU_KILL_MODULE'
    and lvvl.enabled_flag = 'Y'
    and TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
                          AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
-- E_�{�ғ�_16487�Ή� Rev1.1.0 �C���I��
    and sample_time > to_timestamp (sysdate - 2/1440, 'YYYY/MM/DD HH24:MI:SS') 
    and sample_time = (select max(sample_time)
                       from v\$active_session_history
                       where (temp_space_allocated / 1024 / 1024 / 1024) > ${GSIZE}
                             and sample_time > to_timestamp (sysdate - 2/1440, 'YYYY/MM/DD HH24:MI:SS'))
/

spool off
exit
EOF1

### SQL �I������ ###

if [ $? != 0 ]
then
   echo "[ERROR]:kill�Ώ�SID�擾�Ɏ��s���܂���" >> ${L_rogumei}
   L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I�� (${TE_ZCZZIJOUSHURYO})"
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### Active Session �m�F ###
while IFS=, read L_TIME L_SID L_SERIAL L_SEQ L_USER L_SQL_ID L_TSQL_ID L_EVENT L_STATE L_PROGRAM L_MACHINE L_TEMP
do 
   if [ -n "${L_SQL_ID}" ] #�󔒍s����ispool�t�@�C����1�s�ڂ����s�݂̂̂��߁j
   then
      read L_DESC      ### E_�{�ғ�_16487�Ή� Rev1.1.0 �Q�ƃ^�C�v�E�E�v(�@�\��) L_DESC�ǉ�

      L_SQL_ID=`echo ${L_SQL_ID} | tr -d " "`

      ${ORACLE_HOME}/bin/sqlplus -s system/ito\#en03 << EOF2 >> /dev/null
      WHENEVER OSERROR EXIT FAILURE
      WHENEVER SQLERROR EXIT FAILURE

      set lines 2000
      set pages 500
      col name format a50
      alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
      set head off
      set feedback off
      set trim on
      set trims on
      set colsep ','
      spool ${KILL_SID_LIST2}

      SELECT
           ss.sid
          ,ss.serial#
          ,ss.seq#
          ,ss.username
          ,tu.tablespace
          ,SUM(tu.blocks) * 8 / 1024 / 1024 used_gb
          ,ss.process
          ,ss.sql_id
          ,sq.sql_text
      FROM
          v\$tempseg_usage tu
          ,v\$session ss
          ,v\$sql sq
      WHERE
          tu.session_addr = ss.saddr
      AND ss.sql_id = sq.sql_id
      and ss.sql_id = '${L_SQL_ID}'
      GROUP BY
           ss.sid
          ,ss.serial#
          ,ss.seq#
          ,ss.username
          ,tu.tablespace
          ,ss.process
          ,ss.sql_id
          ,sq.sql_text
      ORDER BY
          ss.sid
      /

      spool off
      exit
EOF2

### SQL �I������ ###

      if [ $? != 0 ]
      then
         echo "[ERROR]:kill�Ώ�SID�擾2�Ɏ��s���܂���" >> ${L_rogumei}
         L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I�� (${TE_ZCZZIJOUSHURYO})"
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      fi

### �Z�b�V����kill ###
###   �Z�b�V�����������I�������SQL�G���[�ɂȂ邽�߁A���s����SQL�G���[�͖������� ###
      while IFS=, read L_SID2 L_SERIAL2 L_SEQ2 L_USER2 L_TBS L_BLOCK L_PROCESS L_SQL_ID2 L_SQL_TEXT
      do 
         if [ -n "${L_SQL_ID2}" ] #�󔒍s����ispool�t�@�C����1�s�ڂ����s�݂̂̂��߁j
         then
             L_SID2=`echo ${L_SID2} | tr -d " "`
             L_SERIAL2=`echo ${L_SERIAL2} | tr -d " "`

             L_rogushuturyoku "kill Session SID : ${L_SID2} SERIAL# : ${L_SERIAL2} TEMP_USED(GB) : ${L_TEMP}"
### E_�{�ғ�_16487�Ή� Rev1.1.0 �Q�ƃ^�C�v�E�E�v(�@�\��) L_DESC�ǉ�
#             L_rogushuturyoku "     USER : ${L_USER} PROCESS : ${L_PROCESS} PROGRAM : ${L_PROGRAM} MACHINE : ${L_MACHINE} SQL_ID : ${L_SQL_ID}"
             L_rogushuturyoku "     USER : ${L_USER} PROCESS : ${L_PROCESS} PROGRAM : ${L_PROGRAM} MACHINE : ${L_MACHINE} SQL_ID : ${L_SQL_ID} Function : ${L_DESC}"
             L_rogushuturyoku "     SQL_TEXT : ${L_SQL_TEXT}"

            ${ORACLE_HOME}/bin/sqlplus -s system/ito\#en03 << EOF3 >> /dev/null
            WHENEVER OSERROR EXIT FAILURE
----            WHENEVER SQLERROR EXIT SQL.SQLCODE

            set head off
            set feedback off
            alter system kill session '${L_SID2}, ${L_SERIAL2}' IMMEDIATE;
            exit
EOF3

### SQL �I������ ###

            if [ $? != 0 ] && [ $? != 31 ]
            then
               echo "[ERROR]:�Z�b�V������ kill �Ɏ��s���܂���" >> ${L_rogumei}
               L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I�� (${TE_ZCZZIJOUSHURYO})"
               exit ${TE_ZCZZIJOUSHURYO}
            fi

         fi
         sleep 1
      done < ${KILL_SID_LIST2}

   fi
   sleep 1
done < ${KILL_SID_LIST}

### ���X�g�t�@�C���폜 ###
rm -f ${KILL_SID_LIST} >> ${L_rogumei}
rm -f ${KILL_SID_LIST2} >> ${L_rogumei}

### �����J�n�o�� ###
L_rogushuturyoku "ZCZZ00002:${L_sherumei} �I�� (${TE_ZCZZSEIJOUSHURYO})"

L_shuryo ${TE_ZCZZSEIJOUSHURYO}
