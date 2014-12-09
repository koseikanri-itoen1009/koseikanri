#!/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##      �ۑ����Ԃ��߂����O��AP�T�[�o�̃��O�t�@�C���̍폜�����{����B          ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/03/17 1.0.1                 ##
##        �X�V�����F   Oracle �x��           2008/03/17 1.0.1                 ##
##                       ����                                                 ##
##                     SCS    �k��           2010/01/08 1.0.2                 ##
##                       /tmp�z�������[�U�̏����t�ō폜�Ώۂɒǉ�             ##
##                     SCSK   ���           2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �E���ˑ��l�̕ϐ���                               ##
##                         �E���[�J���ϐ�L_rogupasu�̒l��ύX                 ##
##                         �EENV�t�@�C�����z�X�g�����I�擾�ύX                ##
##                         �E�V�F�����ύX                                     ##
##                         �EZCZZEXPDELFILE.env�̖��̏C��                     ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_EXP_LOGMNG.ksh                     ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

##2014/07/31 S.Noguchi Add Start
## ���ˑ��l
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##�ŉ��w�̃J�����g�f�B���N�g����
##2014/07/31 S.Noguchi Add End

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t
L_lhizuke=`/bin/date "+%Y%m%d"`          #���O���t
##2014/07/31 S.Noguchi Mod Start
#L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #���O�p�X
L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"   #���O�p�X
##2014/07/31 S.Noguchi Mod End
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn="`/bin/dirname $0`/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����
##2010/01/08 T.Kitagawa Add Start
L_tmpdir="/tmp"                          #/tmp�p�X
L_tmptypef="f"                           #�t�@�C���̎�ށF�ʏ�t�@�C��
L_tmptyped="d"                           #�t�@�C���̎�ށF�f�B���N�g��
##2014/07/31 S.Noguchi Mod Start
#L_tmpuser="pebsito"                      #���[�U��
L_tmpuser=`whoami`                       #���[�U��
##2014/07/31 S.Noguchi Mod End
L_tmphozonkikan="30"                     #/tmp�f�B���N�g���z���̕ۑ�����
##2010/01/08 T.Kitagawa Add End


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


### ���O�t�@�C�����̕ύX ###
L_rogushuturyoku "���O�t�@�C�����̕ύX �J�n"

#�t�@�C���ǂݍ��݃`�F�b�N
if [ ! -r ${TE_ZCZZEXTAPDELFILE} ]
then
##2014/07/31 S.Noguchi Mod Start
#   echo "ZCZZ00003:[Error] ZCZZEXTAPDELFILE.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
   echo "ZCZZ00003:[Error] ZCZZEXPDELFILE.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
##2014/07/31 S.Noguchi Mod End
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

##2014/07/31 S.Noguchi Add Start
L_zczzexpdelfilevalue=${TE_ZCZZTENPUPASU}/`/bin/basename ${L_sherumei} .ksh`".tmp"
cat ${TE_ZCZZEXTAPDELFILE} | sed -e "s/<HOSTNAME>/${L_hosutomei}/g" > ${L_zczzexpdelfilevalue}
##2014/07/31 S.Noguchi Add End

#L_direkutori �폜���O�p�X
#L_fmei       �폜���O��
#L_furagu=1   �t�@�C�����̕ύX�s�v
#L_furagu=2   �t�@�C�����̕ύX�K�v
#L_fmeisyo    ���O����
#L_hozonkikan ���O�ۑ�����
while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
do
   L_moji=`echo ${L_direkutori} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # �R�����g�s���ǂ����m�F
   then
      if [ ${L_furagu} = "2" ]
      then
         /bin/mv ${L_direkutori}/${L_fmei} ${L_direkutori}/${L_fmei}.${L_lhizuke} 2> ${TE_ZCZZHYOUJUNERA}
         /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
      fi
   fi
##2014/07/31 S.Noguchi Mod Start
#done < ${TE_ZCZZEXTAPDELFILE}
done < ${L_zczzexpdelfilevalue}
##2014/07/31 S.Noguchi Mod End

L_rogushuturyoku "���O�t�@�C�����̕ύX �I��"


### �폜�Ώۃ��O�t�@�C�����݃`�F�b�N����э폜 ###
L_rogushuturyoku "�폜�Ώۃ��O�t�@�C�����݊m�F����э폜 �J�n"

while read L_direkutori L_fmei L_furagu L_fmeisyo L_hozonkikan
do
   L_moji=`echo ${L_direkutori} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # �R�����g�s���ǂ����m�F
   then
      echo "### ${L_fmeisyo} ���O�t�@�C�� ###" >> ${L_rogumei}
      if [ ${L_furagu} = "1" ]
      then
         /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
         if [ ${L_kensu} -ne 0 ]
         then
            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
            /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mtime +${L_hozonkikan} -exec rm {} \;
         else
            echo ${TE_ZCZZ00700} >> ${L_rogumei}
         fi
      else
         /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
         L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
         if [ ${L_kensu} -ne 0 ]
         then
            /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
            /usr/bin/find ${L_direkutori} -name "${L_fmei}.*" -mtime +${L_hozonkikan} -exec rm {} \;
         else
            echo ${TE_ZCZZ00700} >> ${L_rogumei}
         fi
      fi
   fi
##2014/07/31 S.Noguchi Mod Start
#done < ${TE_ZCZZEXTAPDELFILE}
done < ${L_zczzexpdelfilevalue}
##2014/07/31 S.Noguchi Mod End

##2010/01/08 T.Kitagawa Add Start
#�ʏ�t�@�C���̍폜�i/tmp�z���j
#L_hyoujunshuturyoku �폜�t�@�C���ꗗ
echo "### ${L_tmpdir} ���O�t�@�C�� ###" >> ${L_rogumei}
/usr/bin/find ${L_tmpdir} -type ${L_tmptypef} -user ${L_tmpuser} -mtime +${L_tmphozonkikan} -print | sort -r > ${TE_ZCZZHYOUJUNSHUTURYOKU}
L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
if [ ${L_kensu} -ne 0 ]
then
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   while read L_hyoujunshuturyoku
   do
      rm ${L_hyoujunshuturyoku}
   done < ${TE_ZCZZHYOUJUNSHUTURYOKU}
else
   echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi

#�f�B���N�g���̍폜�i/tmp�z���j
#L_hyoujunshuturyoku �폜�f�B���N�g���ꗗ
echo "### ${L_tmpdir} ���O�f�B���N�g�� ###" >> ${L_rogumei}
/usr/bin/find ${L_tmpdir} -type ${L_tmptyped} -user ${L_tmpuser} -mtime +${L_tmphozonkikan} -print | sort -r > ${TE_ZCZZHYOUJUNSHUTURYOKU}
L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
if [ ${L_kensu} -ne 0 ]
then
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   while read L_hyoujunshuturyoku
   do
      rmdir ${L_hyoujunshuturyoku}
   done < ${TE_ZCZZHYOUJUNSHUTURYOKU}
else
   echo ${TE_ZCZZ01000} >> ${L_rogumei}
fi
##2010/01/08 T.Kitagawa Add End

##2014/07/31 S.Noguchi Add Start
if [ -f ${L_zczzexpdelfilevalue} ]
then
  rm ${L_zczzexpdelfilevalue}
fi
##2014/07/31 S.Noguchi Add End

L_rogushuturyoku "�폜�Ώۃ��O�t�@�C�����݊m�F����э폜 �I��"


### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
