#!/bin/ksh

################################################################################
##                                                                            ##
##   [�g�p���@]                                                               ##
##      ZCZZ_DB_LOGMNG_ARC.ksh                                                ##
##                                                                            ##
##   [�W���u��]                                                               ##
##      ����DB�T�[�o�A�[�J�C�u���O�t�@�C���폜                                ##
##                                                                            ##
##   [�T�v]                                                                   ##
##      �����ŕۑ����Ԃ��߂���DB�T�[�o�̃A�[�J�C�u���O�t�@�C����              ##
##      �폜�����{����B                                                      ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCS ���_              2009/07/06 1.0.1                 ##
##        �X�V�����F   SCS ���_              2009/07/06 1.0.1                 ##
##                       ����                                                 ##
##                     SCSK ����             2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �E���ˑ��l�̕ϐ���                               ##
##                         �E�g�p���@�̒ǉ�                                   ##
##                         �E�V�F�����ύX                                     ##
##                         �EGRID���ݒ�t�@�C���̓ǂݍ��ݏ�����ǉ�         ##
##                         �E�폜�Ώۃt�@�C���̎擾���@�̕ύX                 ##
##                         �E�A�[�J�C�u���O�̍폜���@��ύX                   ##
##                         �ESQL�̎��s���菈����ǉ�                          ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_DB_LOGMNG_ARC.ksh                  ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

##2014/07/31 S.Takahashi Add Start
##���ˑ��l
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##�ŉ��w�̃J�����g�f�B���N�g����
##2014/07/31 S.Takahashi Add End

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t
L_lhizuke=`/bin/date "+%Y%m%d"`          #���O���t
##2014/07/31 S.Takahashi Mod Start
#L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #���O�p�X
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"    #���O�p�X
##2014/07/31 S.Takahashi Mod End
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn="`/bin/dirname $0`/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����

##2014/07/31 S.Takahashi Add Start
L_zczzgrid="`/bin/dirname $0`/ZCZZGRID.env"                                                   #GRID���ϐ��t�@�C����

##�V�F���ŗL���ϐ�
L_rogurisuto="`/bin/dirname $0`/tmp/"`/bin/basename ${L_sherumei} .ksh`".lst"                 #SQL�ꎞ�t�@�C��
##2014/07/31 S.Takahashi Add End

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

##2014/07/31 S.Takahashi Add Start
   ### SQL�ꎞ�t�@�C���폜 ###
   if [ -f ${L_rogurisuto} ]
   then
      L_rogushuturyoku "SQL�ꎞ�t�@�C���폜���s"
      rm ${L_rogurisuto}
   fi
##2014/07/31 S.Takahashi Add End

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
if [ -r ${L_zczzcomn} ]
then
   . ${L_zczzcomn}
else
   echo "ZCZZ00003:[Error] ZCZZCOMN.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo 8
fi
L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �I��"

##2014/07/31 S.Takahashi Add Start
## GRID���ݒ�t�@�C���ǂݍ���
  L_rogushuturyoku "GRID���ݒ�t�@�C����ǂݍ��݂܂��B"

  if [ -r "${L_zczzgrid}" ]
    then
      . ${L_zczzgrid}
      L_rogushuturyoku "GRID���ݒ�t�@�C����ǂݍ��݂܂����B"
  else
      L_rogushuturyoku "ZCZZ00003:[Error] `/bin/basename ${L_zczzgrid}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}"
      echo "ZCZZ00003:[Error] `/bin/basename ${L_zczzgrid}` �����݂��Ȃ��A�܂��͌�����܂���B   HOST=${L_hosutomei}" 1>&2
      L_shuryo 8
  fi
##2014/07/31 S.Takahashi Add End


##2014/07/31 S.Takahashi Del Start  
#### ���O�t�@�C�����̕ύX ###
#L_rogushuturyoku "���O�t�@�C�����̕ύX �J�n"
#
##�t�@�C���ǂݍ��݃`�F�b�N
#if [ ! -r ${TE_ZCZZDBDELFILEARC} ]
#then
#   echo "ZCZZ00003:[Error] ZCZZDBDELFILEARC.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
#        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
#   L_shuryo ${TE_ZCZZIJOUSHURYO}
#fi
#
##L_direkutori �폜���O�p�X
##L_fmei       �폜���O��
##L_furagu=1   �t�@�C�����̕ύX�s�v
##L_furagu=2   �t�@�C�����̕ύX�K�v
##L_fmeisyo    ���O����
##L_hozonkikan ���O�ۑ�����
#while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
#do
#   L_moji=`echo ${L_direkutori} | cut -c 1`
#   if [ ${L_moji:-#} != "#" ]           # �R�����g�s���ǂ����m�F
#   then
#      if [ ${L_furagu} = "2" ]
#      then
#         /bin/mv ${L_direkutori}/${L_fmei} ${L_direkutori}/${L_fmei}.${L_lhizuke} 2> ${TE_ZCZZHYOUJUNERA}
#         /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
#      fi
#   fi
#done < ${TE_ZCZZDBDELFILEARC}
#
#L_rogushuturyoku "���O�t�@�C�����̕ύX �I��"
#
#
#### �폜�Ώۃ��O�t�@�C�����݊m�F����э폜 ###
#L_rogushuturyoku "�폜�Ώۃ��O�t�@�C�����݊m�F����э폜 �J�n"
#
#while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
#do
#   L_moji=`echo ${L_direkutori} | cut -c 1`
#   if [ ${L_moji:-#} != "#" ]           # �R�����g�s���ǂ����m�F
#   then
#      echo "### ${L_fmeisyo} ���O�t�@�C�� ###" >> ${L_rogumei}
#      if [ ${L_furagu} = "1" ]
#      then
#         /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
#         if [ ${L_kensu} -ne 0 ]
#         then
#            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
#            /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -exec rm {} \;
#         else
#            echo ${TE_ZCZZ01000} >> ${L_rogumei}
#         fi
#      else
#         /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
#         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
#         if [ ${L_kensu} -ne 0 ]
#         then
#            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
#            /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -exec rm {} \;
#         else
#            echo ${TE_ZCZZ01000} >> ${L_rogumei}
#         fi
#      fi
#   fi
#done < ${TE_ZCZZDBDELFILEARC}
##2014/07/31 S.Takahashi Del End


##2014/07/31 S.Takahashi Add Start
### �폜�ΏۃA�[�J�C�u���O�t�@�C���̎擾 ###
L_rogushuturyoku "�폜�ΏۃA�[�J�C�u���O�t�@�C���̎擾 �J�n"

sqlplus -s / as sysasm << EOF >> ${L_rogumei} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

set lines 120
set pages 500
set head off
set feedback off
set trimspool on
spool ${L_rogurisuto}
SELECT full_alias_path from
     (SELECT concat('+'||gname, sys_connect_by_path(aname, '/')) full_alias_path,fmdate
       FROM (SELECT g.name gname, a.parent_index pindex,a.name aname, a.reference_index rindex,f.MODIFICATION_DATE fmdate
               FROM v\$asm_alias a, v\$asm_diskgroup g, v\$asm_file f
              WHERE a.group_number = g.group_number
              and a.file_number = f.file_number(+)
              and a.group_number = f.group_number(+))
     START WITH (mod(pindex, power(2, 24))) = 0
     CONNECT BY PRIOR rindex = pindex
     )
     where full_alias_path like '%thread%'
     and fmdate < sysdate -(2/24)
     order by 1;
spool off
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

L_rogushuturyoku "�폜�ΏۃA�[�J�C�u���O�t�@�C���̎擾 �I��"


### �A�[�J�C�u���O�t�@�C���̍폜 ###
L_rogushuturyoku "�A�[�J�C�u���O�t�@�C���폜 �J�n"


#L_fmei �폜���O��

let cnt_err=0
L_kensu=`/usr/bin/cat ${L_rogurisuto} | /usr/bin/wc -l | awk '{print $1}'`
if [ ${L_kensu} -ne 0 ]
then
  while read L_fmei 
  do
    if [ "X" != "${L_fmei}X" ]
    then
      L_rogushuturyoku "## �폜�Ώۃt�@�C��(${L_fmei})"
      asmcmd rm ${L_fmei}
      asmcmd ls ${L_fmei}
      L_risutostat=$?
      if [ ${L_risutostat} -ne 0 ]
      then
        L_rogushuturyoku "�폜����"
      else
        L_rogushuturyoku "�폜���s"
        let cnt_err=cnt_err+1
      fi
    fi
  done < ${L_rogurisuto}
else
  echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi

#�A�[�J�C�u���O�t�@�C���폜����
if [ "$cnt_err" -ne 0 ]
then
   echo "ZCZZ00009:[Error] �A�[�J�C�u���O�t�@�C���̍폜�Ɏ��s���܂����B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi
##2014/07/31 S.Takahashi Add End


L_rogushuturyoku "�폜�Ώۃ��O�t�@�C�����݊m�F����э폜 �I��"


### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
