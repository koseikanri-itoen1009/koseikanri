#!/bin/ksh

################################################################################
##                                                                            ##
##   [�t�@�C����]                                                             ##
##      ZCZZ_PEBSAP_LOGMNG_DAILY.ksh                                          ##
##                                                                            ##
##   [�W���u��]                                                               ##
##      ����AP�T�[�o���O�t�@�C���폜                                          ##
##                                                                            ##
##   [�T�v]                                                                   ##
##      �����ŕۑ����Ԃ��߂���AP�T�[�o�̃��O�t�@�C���̍폜�����{����B        ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCS ���_              2009/07/06 1.0.1                 ##
##        �X�V�����F   SCS ���_              2009/07/06 1.0.1                 ##
##                       ����                                                 ##
##                     SCS    ��c           2009/11/26 1.0.2                 ##
##                                                                            ##
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
L_lhizuke=`/bin/date "+%Y%m%d"`          #���O���t
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #���O�p�X
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn="`/bin/dirname $0`/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����


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
if [ ! -r ${TE_ZCZZAPDELFILEDAILY} ]
then
   echo "ZCZZ00003:[Error] ZCZZAPDELFILEDAILY.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

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
         /usr/bin/gzip ${L_direkutori}/${L_fmei}.${L_lhizuke} 2> ${TE_ZCZZHYOUJUNERA}
         /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
      fi
   fi
done < ${TE_ZCZZAPDELFILEDAILY}

L_rogushuturyoku "���O�t�@�C�����̕ύX �I��"


### �폜�Ώۃ��O�t�@�C�����݊m�F����э폜 ###
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
done < ${TE_ZCZZAPDELFILEDAILY}


L_rogushuturyoku "�폜�Ώۃ��O�t�@�C�����݊m�F����э폜 �I��"


### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
