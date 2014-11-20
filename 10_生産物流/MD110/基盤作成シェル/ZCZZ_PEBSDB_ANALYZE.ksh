#!/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##      �f�[�^�x�[�X�̓��v���̎擾�����{����B                              ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/03/25 1.0.1                 ##
##        �X�V�����F   Oracle �x��           2008/03/25 1.0.1                 ##
##                       ����                                                 ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      0 : ����                                                              ##
##      8 : �ُ�                                                              ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      ZCZZ_PEBSDB_ANALYZE.ksh                                               ##
##                                                                            ##
##    Copyright ������Јɓ��� U5000�v���W�F�N�g 2007-2009                    ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################

L_sherumei=`/bin/basename $0`            #�V�F����
L_hosutomei=`/bin/hostname`              #�z�X�g��
L_hizuke=`/bin/date "+%y%m%d"`           #���t
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #���O�p�X
L_rogumei="${L_rogupasu}/ZCZZ_DB_ANALYZE${L_hosutomei}${L_hizuke}.log"   #���O��
L_zczzcomn=`/bin/dirname $0`"/ZCZZCOMN.env"     #���ʊ��ϐ��t�@�C����


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

### �R���J�����g���ݒ� ###
if [ -r ${TE_ZCZZCONC} ]
then
   . ${TE_ZCZZCONC}
else
   echo "ZCZZ00003:[Error] ZCZZCONC.env �����݂��Ȃ��A�܂��͌�����܂���B HOST=${L_hosutomei}" \
        | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "���ݒ�t�@�C���Ǎ��� �I��"


### ���v���擾 ###
L_rogushuturyoku "���v���擾 �J�n"

L_app_syokuseki_tansyukumei="SYSADMIN"     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                       #���[�U��
L_konkarento_app_tansyukumei="FND"         #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="FNDGSCST"                 #�v���O�����A�v���P�[�V������

L_hikisu01="ALL"          #�X�L�[�}��
L_hikisu02="10"           #�]����
L_hikisu03='""'           #����x
L_hikisu04="NOBACKUP"     #�����t���O
L_hikisu05='""'           #�v��ID�̍ċN��
L_hikisu06="LASTRUN"      #�������[�h
L_hikisu07="GATHER"       #���W�I�v�V����
L_hikisu08='""'           #�ύX������
L_hikisu09="Y"            #�ˑ��J�[�\���̖�����

L_rogushuturyoku "�p�����[�^�[�l"
echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}
echo "L_hikisu02="${L_hikisu02}                                     >> ${L_rogumei}
echo "L_hikisu03="${L_hikisu03}                                     >> ${L_rogumei}
echo "L_hikisu04="${L_hikisu04}                                     >> ${L_rogumei}
echo "L_hikisu05="${L_hikisu05}                                     >> ${L_rogumei}
echo "L_hikisu06="${L_hikisu06}                                     >> ${L_rogumei}
echo "L_hikisu07="${L_hikisu07}                                     >> ${L_rogumei}
echo "L_hikisu08="${L_hikisu08}                                     >> ${L_rogumei}
echo "L_hikisu09="${L_hikisu09}                                     >> ${L_rogumei}

#�R���J�����g���s
echo ""
L_rogushuturyoku "�R���J�����g���s"
${FND_TOP}/bin/CONCSUB apps/apps \
                       "${L_app_syokuseki_tansyukumei}" \
                       "${L_syokusekimei}" \
                       "${L_yuzamei}" \
                       WAIT=Y \
                       CONCURRENT \
                       "${L_konkarento_app_tansyukumei}" \
                       "${L_konkarentomei}" \
                       "${L_hikisu01}" \
                       "${L_hikisu02}" \
                       "${L_hikisu03}" \
                       "${L_hikisu04}" \
                       "${L_hikisu05}" \
                       "${L_hikisu06}" \
                       "${L_hikisu07}" \
                       "${L_hikisu08}" \
                       "${L_hikisu09}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ00800} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}
L_rogushuturyoku "���v���擾 �I��"


### ���s�X�e�[�^�X�m�F ###
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ00801} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#���s�X�e�[�^�X�擾
L_konkarento_jyoutai=`awk 'NR==4 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "STATUS_CD="${L_konkarento_jyoutai}

#���s�X�e�[�^�X����
if [ "${L_konkarento_jyoutai}" != 'C' ]     #C:����
then
   echo ${TE_ZCZZ00801} "STATUS_CD="${L_konkarento_jyoutai} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_rogushuturyoku "���s�X�e�[�^�X�m�F �I��"


### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
