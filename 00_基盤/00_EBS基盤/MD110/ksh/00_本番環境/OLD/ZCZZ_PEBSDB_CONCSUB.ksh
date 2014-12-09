#!/bin/ksh

################################################################################
##                                                                            ##
##   [�t�@�C����]                                                             ##
##      ZCZZ_PEBSDB_CONCSUB.ksh                                               ##
##                                                                            ##
##   [�T�v]                                                                   ##
##      �R���J�����g�v�����s�@�\(SYSADMIN�p)                                  ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCS �k��              2010/03/27 1.0.0                 ##
##        �X�V��  �F   SCS �k��              2010/03/27 1.0.0                 ##
##                       ����                                                 ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      $1       �R���J�����g�A�v���P�[�V�����Z�k��                           ##
##      $2       �R���J�����g�v���O������                                     ##
##      $3�`     �R���J�����g�p�����[�^                                       ##
##                                                                            ##
##    Copyright ������Јɓ��� U5000�v���W�F�N�g 2007-2009                    ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hiduke=`/bin/date "+%y%m%d`            #���t
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #���O�p�X
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${2}${L_hiduke}.log"                   #���O��
L_hyoujunshuturyoku="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${2}${L_hiduke}_std_out.tmp" #�W���o�͈ꎞ�t�@�C��
L_hyoujunera="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${2}${L_hiduke}_std_err.tmp"        #�W���G���[�ꎞ�t�@�C��
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����
L_apps='APPS/APPS'                       #�R�}���h���s���[�U��
L_app_syokuseki_tansyukumei='SYSADMIN'   #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"    #�E�ӂ̖���
L_yuzamei='SYSADMIN'                     #���[�U��
L_wait='WAIT=1'                          #�����I���ҋ@�t���O
L_flag='CONCURRENT'                      #�K�{�t���O
L_hikisu="${L_apps} ${L_app_syokuseki_tansyukumei} \"${L_syokusekimei}\" ${L_yuzamei} ${L_wait} ${L_flag}"        #CONCSUB�p����


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
   if [ -f ${L_hyoujunshuturyoku} ]
   then
      L_rogushuturyoku "�W���o�͈ꎞ�t�@�C���폜���s"
      rm ${L_hyoujunshuturyoku}
   fi
   if [ -f ${L_hyoujunera} ]
   then
      L_rogushuturyoku "�W���G���[�ꎞ�t�@�C���폜���s"
      rm ${L_hyoujunera}
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

#��Ջ��ʊ��ϐ�
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi

#�R���J�����g���ݒ�
if [ -r ${TE_ZCZZCONC} ]
then
   . ${TE_ZCZZCONC}
else
   echo "ZCZZ00003:[Error] ZCZZCONC.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �I��"

### ���̓p�����[�^�ݒ� ###
L_rogushuturyoku "���̓p�����[�^�ݒ� �J�n"

if [ ${#} -lt 2 ]
then
   echo "ZCZZ00004:[Error] ���̓p�����[�^��2��菭�Ȃ��ł��B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_cnt=0
   for i in ${@}
   do
      L_cnt=`expr ${L_cnt} + 1`
      echo "���̓p�����[�^${L_cnt}�F${i}" \
           | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   done
   L_shuryo ${TE_ZCZZIJOUSHURYO}
else
   L_cnt=0
   for i in ${@}
   do
      L_cnt=`expr ${L_cnt} + 1`
      if [ "$(echo ${i} | egrep 'hiduke')" ]
      then
         if [ "$(echo ${i} | egrep 'hiduke[1-9]')" ]
         then
            L_tmp=${i#hiduke}                                                 #hiduke������폜
            L_hojikikan=${L_tmp%+*}                                           #���t����������폜
            L_jikan=`expr ${L_hojikikan} \* 30 \* 24 - 9`                     #�ێ����Ԍv�Z
            L_hiduke=`env TZ=JST+${L_jikan} date ${L_tmp#${L_hojikikan}}`     #�Ώۓ��v�Z
            L_rogushuturyoku "���̓p�����[�^${L_cnt}�F${L_hiduke}"
            L_hikisu="${L_hikisu} ${L_hiduke}"
         else
            echo "ZCZZ00005:[Error] ���t�p�����[�^���Ԉ���Ă��܂��B HOST=${L_hosutomei}" \
                 | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
            echo "���̓p�����[�^${L_cnt}�F${i}" \
                 | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
            L_shuryo ${TE_ZCZZIJOUSHURYO}
         fi
      else
         L_rogushuturyoku "���̓p�����[�^${L_cnt}�F${i}"
         L_hikisu="${L_hikisu} ${i}"
      fi
   done
fi

L_rogushuturyoku "���̓p�����[�^�ݒ� �I��"

### �R���J�����g�v���̔��s ###
echo ""
L_rogushuturyoku "�R���J�����g�v���̔��s �J�n"

${FND_TOP}/bin/CONCSUB ${L_hikisu} > ${L_hyoujunshuturyoku} 2> ${L_hyoujunera}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo "ZCZZ00006:[Error] CONCSUB�̎��s�Ɏ��s���܂����B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   /usr/bin/cat ${L_hyoujunera} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### �v��ID�擾 ###
L_rogushuturyoku "�v��ID�擾 �J�n"

L_yokyu_id=`awk 'NR==1 {print $3}' ${L_hyoujunshuturyoku}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}

#�v��ID�擾����
if [ "$(echo ${L_yokyu_id} | egrep '^[0-9]+$')" = "" ]
then
   echo "ZCZZ00007:[Error] �v��ID�擾�Ɏ��s���܂����B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   /usr/bin/cat ${L_hyoujunera} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "�v��ID�擾 �I��"

### ���s�X�e�[�^�X�m�F ###
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

#���s�X�e�[�^�X�m�FSQL
${ORACLE_HOME}/bin/sqlplus -s ${L_apps} << EOF > ${L_hyoujunshuturyoku} 2> ${L_hyoujunera}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

ALTER SESSION SET NLS_LANGUAGE='Japanese';
SET LINESIZE 200

COLUMN ph FORMAT A2
COLUMN st FORMAT A2
COLUMN concurrent_name FORMAT A100
SELECT fcrs.request_id  reqid
      ,fcrs.phase_code  ph
      ,fcrs.status_code st
      ,fcrs.user_concurrent_program_name concurrent_name
FROM   fnd_conc_req_summary_v fcrs
WHERE  fcrs.request_id='${L_yokyu_id}';
exit
EOF

#SQL���s����
if [ $? -ne 0 ]
then
   echo "ZCZZ00008:[Error] SQL*Plus�̎��s�Ɏ��s���܂����B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   /usr/bin/cat ${L_hyoujunera} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#���s�X�e�[�^�X�擾
L_konkarento_jyoutai=`awk 'NR==7 {print $3}' ${L_hyoujunshuturyoku}`
L_konkarentomei=`awk 'NR==7 {for(i=4;i<=NF;i++) print $i}' ${L_hyoujunshuturyoku}`
L_rogushuturyoku "�R���J�����g����="${L_konkarentomei}
L_rogushuturyoku "STATUS_CD="${L_konkarento_jyoutai}

#���s�X�e�[�^�X����
if [ "${L_konkarento_jyoutai}" != 'C' ]     #C:����
then
   echo "ZCZZ00009:[Error] ${L_konkarentomei} STATUS_CD=${L_konkarento_jyoutai}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${L_hyoujunshuturyoku} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "���s�X�e�[�^�X�m�F �I��"

L_rogushuturyoku "�R���J�����g�v���̔��s �I��"

### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
