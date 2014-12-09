#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##      �����ŕۑ����Ԃ��߂���DB�T�[�o�̃��[�J���ɏo�͂��ꂽ�A�[�J�C�u        ##
##      ���O�t�@�C���̍폜�����{����B                                        ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   SCSK   ����           2014/07/31 2.0.0                 ##
##        �X�V�����F   SCSK   ����           2014/07/31 2.0.0                 ##
##                       ����(���v���[�X_00007)                               ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_DB_LOGMNG_ARC_LOCAL.ksh            ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################


## ���ˑ��l
  L_kankyoumei=`dirname $0 | sed -e "s/.*\///"` ##�ŉ��w�̃J�����g�f�B���N�g����

## �f�B���N�g����`
  L_rogupasu="/var/EBS/jp1/${L_kankyoumei}/log"      ##���O�t�@�C���i�[�f�B���N�g��

## �ϐ���`
L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t
L_lhizuke=`/bin/date "+%Y%m%d"`          #���O���t
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

### �폜�Ώۃ��O�t�@�C�����݊m�F����э폜 ###
L_rogushuturyoku "�폜�Ώۃ��O�t�@�C�����݊m�F����э폜 �J�n"

#�t�@�C���ǂݍ��݃`�F�b�N
if [ ! -r ${TE_ZCZZDBDELFILEARCLOCAL} ]
then
   echo "ZCZZ00003:[Error] ZCZZDBDELFILEARCLOCAL.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_zczzdbdelarclocvalue=${TE_ZCZZTENPUPASU}/`/bin/basename ${L_sherumei} .ksh`".tmp"
cat ${TE_ZCZZDBDELFILEARCLOCAL} | sed -e "s/<HOSTNAME>/${L_hosutomei}/g" > ${L_zczzdbdelarclocvalue}

#L_direkutori �폜���O�p�X
#L_fmei       �폜���O��
#L_fmeisyo    ���O����
#L_hozonkikan ���O�ۑ�����

while read L_direkutori L_fmei L_fmeisyo L_hozonkikan
do
   L_moji=`echo ${L_direkutori} | cut -c 1`
   if [ ${L_moji:-#} != "#" ]           # �R�����g�s���ǂ����m�F
   then
      echo "### ${L_fmeisyo} ���O�t�@�C�� ###" >> ${L_rogumei}
      /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mmin +${L_hozonkikan} -print > ${TE_ZCZZHYOUJUNSHUTURYOKU}
      L_kensu=`/usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} | /usr/bin/wc -l`
      if [ ${L_kensu} -ne 0 ]
      then
         /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
         /usr/bin/find ${L_direkutori} -name "${L_fmei}" -mmin +${L_hozonkikan} -exec rm {} \;
      else
         echo ${TE_ZCZZ01000} >> ${L_rogumei}
      fi
   fi
done < ${L_zczzdbdelarclocvalue}

if [ -f ${L_zczzdbdelarclocvalue} ]
then
  rm ${L_zczzdbdelarclocvalue}
fi

L_rogushuturyoku "�폜�Ώۃ��O�t�@�C�����݊m�F����э폜 �I��"


### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
