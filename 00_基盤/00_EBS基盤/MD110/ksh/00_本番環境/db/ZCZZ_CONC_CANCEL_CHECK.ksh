#!/bin/ksh

################################################################################
##                                                                            ##
##   [�t�@�C����]                                                             ##
##      ZCZZ_CONC_CANCEL_CHECK.ksh                                            ##
##                                                                            ##
##   [�T�v]                                                                   ##
##      ����σR���J�����g(���������[�U�Ŏ��s���ꂽ����)�������Ώۊ��ԓ���    ##
##      ���݂��Ȃ����`�F�b�N���܂��B                                          ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCSK �k��             2016/01/21 1.0.0                 ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      $1 : �����Ώۊ���                                                     ##
##            ALL(�S���ԑΏ�)                                                 ##
##            NIGHT(TE_ZCZZCONC_TO_JIKOKU��TE_ZCZZCONC_KIKAN�Ōv�Z��������)   ##
##            ���l(���͂��ꂽ���l���A�ߋ��ɑk��������)                        ##
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

### ���̓p�����[�^�m�F ###
L_rogushuturyoku "���̓p�����[�^�m�F �J�n(���̓p�����[�^�F"${L_hikisu}")"

### ���̓p�����[�^�L���m�F ###
if [ -z "${L_hikisu}" ]
then
   L_rogushuturyoku "${TE_ZCZZ01901}"
   echo "${TE_ZCZZ01901}" 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
else
   ### ���̓p�����[�^��ALL�̏ꍇ ###
   if [ "${L_hikisu}" = "ALL" ]
   then
      ### �����σ��[�U�Ŏ��s���ꂽ�v����S�Ď擾����ׁA�󔒂ł͂Ȃ��_�~�[������ǉ� ###
      L_tsuikajouken="AND 1 = 1"
   ### ���̓p�����[�^��NIGHT�̏ꍇ
   elif [ "${L_hikisu}" = "NIGHT" ]
   then
      ### �I�����C����~�O����I�����C���J�n�܂łɎ����σ��[�U�Ŏ��s���ꂽ�v�����擾���������ǉ� ###
      L_tsuikajouken="AND fcr.requested_start_date >= TRUNC(SYSDATE) + (${TE_ZCZZCONC_TO_JIKOKU} * 1/24/60) - (${TE_ZCZZCONC_KIKAN} * 1/24/60) \
                      AND fcr.requested_start_date <  TRUNC(SYSDATE) + (${TE_ZCZZCONC_TO_JIKOKU} * 1/24/60)"
   ### ���̓p�����[�^��ALL�ANIGHT�ȊO�̏ꍇ ###
   else
      ### ���̓p�����[�^���l�m�F(���Z) ###
      L_amari=`expr ${L_hikisu} % ${TE_ZCZZCONC_BAISU}`
      ### ���Z���ʔ��� ###
      if [ $? -ge 2 ]
      then
         L_rogushuturyoku "${TE_ZCZZ01902}"
         echo "${TE_ZCZZ01902}" 1>&2
         echo "���̓p�����[�^�F${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      ### ���̓p�����[�^0�m�F ###
      elif [ ${L_hikisu} -eq 0 ]
      then 
         L_rogushuturyoku "${TE_ZCZZ01902}"
         echo "${TE_ZCZZ01902}" 1>&2
         echo "���̓p�����[�^�F${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      ### ���̓p�����[�^�{���m�F ###
      elif [ ${L_amari} -ne 0 ]
      then
         L_rogushuturyoku "${TE_ZCZZ01903}"
         echo "${TE_ZCZZ01903}" 1>&2
         echo "���̓p�����[�^�F${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      ### ���̓p�����[�^�͈͊m�F ###
      elif [ ${L_hikisu} -lt ${TE_ZCZZCONC_KANKAKUSAISYO} -o ${L_hikisu} -gt ${TE_ZCZZCONC_KANKAKUSAIDAI} ]
      then
         L_rogushuturyoku "${TE_ZCZZ01904}"
         echo "${TE_ZCZZ01904}" 1>&2
         echo "���̓p�����[�^�F${L_hikisu}" | /usr/bin/tee -a ${L_rogumei} 1>&2
         L_shuryo ${TE_ZCZZIJOUSHURYO}
      fi
      ### ���̓p�����[�^�����l�̏ꍇ�A���̓p�����[�^�l�͈̔͂��������������ǉ� ###
      L_tsuikajouken="AND fcr.requested_start_date >= TO_DATE(SUBSTRB('${L_jikan}',1,11)||'0','YYYYMMDDHH24MI') - (${L_hikisu} * 1/24/60) \
                      AND fcr.requested_start_date <  TO_DATE(SUBSTRB('${L_jikan}',1,11)||'0','YYYYMMDDHH24MI')"
   fi
fi

### ����σR���J�����g�ꗗ�擾 ###
${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF >> ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SET LINES 200
SET PAGES 500
SET HEAD OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_LANGUAGE='Japanese';

  SELECT  /*+
            LEADING(FCR)
            INDEX(FCR FND_CONCURRENT_REQUESTS_N7)
          */
          fcr.completion_text || '(' || fcpv.user_concurrent_program_name || ')' AS CANCELED_REQUEST
    FROM  apps.fnd_concurrent_requests     fcr
         ,apps.fnd_concurrent_programs_vl  fcpv
   WHERE  fcr.concurrent_program_id     = fcpv.concurrent_program_id
     AND  fcr.program_application_id    = fcpv.application_id
     AND  fcr.phase_code                = 'C' --�t�F�[�Y�F����
     AND  fcr.status_code               = 'D' --�X�e�[�^�X�F�����
     AND  fcr.completion_text        like '%expired%' || fcr.request_id || '.'
     ${L_tsuikajouken}
ORDER BY  fcr.request_id
;

exit
EOF

### SQL �I������ ###
if [ $? -ne 0 ]
then
   L_rogushuturyoku "${TE_ZCZZ01905}"
   echo "${TE_ZCZZ01905}" 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} ${TE_ZCZZHYOUJUNERA} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### ����σR���J�����g���݃`�F�b�N ###
if [ `/usr/bin/cat "${TE_ZCZZHYOUJUNSHUTURYOKU}" | wc -l` -ne 0 ]
then
   L_rogushuturyoku "${TE_ZCZZ01906}"
   echo "${TE_ZCZZ01906}" 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
