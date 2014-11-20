#!/bin/ksh

################################################################################
##                                                                            ##
##   [�t�@�C����]                                                             ##
##      ZCZZ_PEBSDB_PURGE.ksh                                                 ##
##                                                                            ##
##   [�W���u��]                                                               ##
##      �f�[�^�x�[�X�f�[�^�p�[�W�W���u                                        ##
##                                                                            ##
##   [�T�v]                                                                   ##
##      �f�[�^�x�[�X�̊č��f�[�^�̍폜�����{����B                            ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/03/31 1.0.1                 ##
##        �X�V�����F   Oracle �x��           2008/03/31 1.0.1                 ##
##                       ����                                                 ##
##        �X�V�����F   Oracle �g��           2008/10/30 1.0.3                 ##
##                      �w���I�[�v���E�C���^�t�F�[�X�ŏ������ꂽ�f�[�^�̃p�[�W##
##                      ��ǉ�                                                ##
##        �X�V�����F   SCS    ���_           2009/07/05 1.0.4                 ##
##        �X�V�����F   SCS    �k��           2010/01/08 1.0.5                 ##
##                      �f�o�b�O�E���O����уV�X�e���E�A���[�g�̃p�[�W��ǉ�  ##
##        �X�V�����F   SCS    ��c           2010/02/16 1.0.6                 ##
##                      �y�[�W�A�N�Z�X�g���b�L���O�f�[�^�̃p�[�W���폜        ##
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
L_rogupasu="/var/EBS/jp1/PEBSITO/log"    #���O�p�X
L_rogumei="${L_rogupasu}/"`/bin/basename ${L_sherumei} .ksh`"${L_hosutomei}${L_hizuke}.log"   #���O��
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

### ���s�X�e�[�^�X�m�F ###
L_jyoutaikakunin()
{
   #���s�X�e�[�^�X�擾
   L_konkarento_jyoutai=`awk 'NR==4 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
   L_rogushuturyoku "STATUS_CD="${L_konkarento_jyoutai}

   #���s�X�e�[�^�X����
   if [ "${L_konkarento_jyoutai}" != 'C' ]     #C:����
   then
      echo ${L_era_messeige} "STATUS_CD="${L_konkarento_jyoutai} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
      /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
      L_shuryo ${TE_ZCZZIJOUSHURYO}
   fi

   L_rogushuturyoku "���s�X�e�[�^�X�m�F �I��"
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


### �f�[�^�p�[�W ###
L_rogushuturyoku "�f�[�^�p�[�W �J�n"

#�R���J�����g�v����}�l�[�W���E�f�[�^�̃p�[�W
L_rogushuturyoku "�R���J�����g�v����}�l�[�W���E�f�[�^�̃p�[�W �J�n"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"                      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                                       #���[�U��
L_konkarento_app_tansyukumei="FND"                         #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="FNDCPPUR"                                 #�v���O�����A�v���P�[�V������

L_hikisu01="ALL"                                           #Entity
L_hikisu02="Age"                                           #Mode
L_hikisu03=`expr ${TE_ZCZZHOZONKIKAN_DATAPURGE} \* 30`     #Mode Value
L_hikisu04='""'                                            #Oracle ID
L_hikisu05='""'                                            #User Name
L_hikisu06='""'                                            #Responsibility Application
L_hikisu07='""'                                            #Responsibility
L_hikisu08='""'                                            #Program Application
L_hikisu09='""'                                            #Program
L_hikisu10='""'                                            #Manager Application
L_hikisu11='""'                                            #Manager
L_hikisu12='YES'                                           #Report
L_hikisu13='YES'                                           #Purge Other

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
echo "L_hikisu10="${L_hikisu10}                                     >> ${L_rogumei}
echo "L_hikisu11="${L_hikisu11}                                     >> ${L_rogumei}
echo "L_hikisu12="${L_hikisu12}                                     >> ${L_rogumei}
echo "L_hikisu13="${L_hikisu13}                                     >> ${L_rogumei}

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
                       "${L_hikisu10}" \
                       "${L_hikisu11}" \
                       "${L_hikisu12}" \
                       "${L_hikisu13}" \
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01100} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01101}

#���s�X�e�[�^�X�m�F
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "�R���J�����g�v����}�l�[�W���E�f�[�^�̃p�[�W �I��"


### �T�C���I���č��f�[�^�̃p�[�W ###
L_rogushuturyoku "�T�C���I���č��f�[�^�̃p�[�W �J�n"

L_hozonkikan=TE_ZCZZ_HOZONKIKAN_KANSA      #�ۑ�����

L_app_syokuseki_tansyukumei="SYSADMIN"     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                       #���[�U��
L_konkarento_app_tansyukumei="FND"         #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="FNDSCPRG"                 #�v���O�����A�v���P�[�V������

#���t�擾
L_jikan=`expr ${TE_ZCZZHOZONKIKAN_KANSA} \* 30 \* 24 - 9`
L_hikisu01=`env TZ=JST+${L_jikan} date +%Y-%m-%d`                #Audit date YYYY-MM-DD

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}

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
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01102} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01103}

#���s�X�e�[�^�X�m�F
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "�T�C���I���č��f�[�^�̃p�[�W �I��"

### �y�[�W�E�A�N�Z�X�ǐՃf�[�^�̃p�[�W ###
##2010/02/16 T.Kawata delete

### Oracle GL Web Inquiry�A�N�Z�X�^�������O�폜 ###
L_rogushuturyoku "Oracle GL Web Inquiry�A�N�Z�X�^�������O�폜 �J�n"


L_app_syokuseki_tansyukumei="SYSADMIN"     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                       #���[�U��
L_konkarento_app_tansyukumei="XGV"         #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="XGVALD"                   #�v���O�����A�v���P�[�V������

L_hikisu01=`expr ${TE_ZCZZHOZONKIKAN_INQ} \* 30`    #P_DAYS

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}

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
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01106} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}

L_era_messeige=${TE_ZCZZ01107}

#���s�X�e�[�^�X�m�F
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "Oracle GL Web Inquiry�A�N�Z�X�^�������O�폜 �I��"


### �p�~���[�N�t���[�E�����^�C���E�f�[�^�̃p�[�W ###
L_rogushuturyoku "�p�~���[�N�t���[�E�����^�C���E�f�[�^�̃p�[�W �J�n"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"                      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                                       #���[�U��
L_konkarento_app_tansyukumei="FND"                         #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="FNDWFPR"                                  #�v���O�����A�v���P�[�V������

L_hikisu01='""'                                            #Item Type
L_hikisu02='""'                                            #Item Key
L_hikisu03=`expr ${TE_ZCZZHOZONKIKAN_HAISIWF} \* 30`       #Age
L_hikisu04='TEMP'                                          #Persistence Type
L_hikisu05='Y'                                             #Core Workflow Only
L_hikisu06='500'                                           #Commit Frequency
L_hikisu07='N'                                             #PurgeSigs

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
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01109} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01110}

#���s�X�e�[�^�X�m�F
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "�p�~���[�N�t���[�E�����^�C���E�f�[�^�̃p�[�W �I��"


### �p�~���ꂽ��ʃt�@�C���E�}�l�[�W���E�f�[�^�̃p�[�W ###
L_rogushuturyoku "�p�~���ꂽ��ʃt�@�C���E�}�l�[�W���E�f�[�^�̃p�[�W �J�n"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"                      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                                       #���[�U��
L_konkarento_app_tansyukumei="FND"                         #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="FNDGFMPR"                                 #�v���O�����A�v���P�[�V������

L_hikisu01='Yes'                                           #Expired
L_hikisu02='""'                                            #Program Name
L_hikisu03='""'                                            #Program Tag

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}
echo "L_hikisu02="${L_hikisu02}                                     >> ${L_rogumei}
echo "L_hikisu03="${L_hikisu03}                                     >> ${L_rogumei}

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
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01111} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01112}

#���s�X�e�[�^�X�m�F
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "�p�~���ꂽ��ʃt�@�C���E�}�l�[�W���E�f�[�^�̃p�[�W �I��"

### �w���I�[�v���E�C���^�t�F�[�X�ŏ������ꂽ�f�[�^�̃p�[�W ###
L_rogushuturyoku "�w���I�[�v���E�C���^�t�F�[�X�ŏ������ꂽ�f�[�^�̃p�[�W �J�n"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"                      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                                       #���[�U��
L_konkarento_app_tansyukumei="PO"                          #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="POXPOIPR"                                 #�v���O�����A�v���P�[�V������

L_hikisu01='""'                                            #Document Type
L_hikisu02='""'                                            #Document SubType
L_hikisu03='Y'                                             #Purge Accepted Data
L_hikisu04='N'                                             #Purge Rejected Data
L_hikisu05='""'                                            #Start Date
L_hikisu06='""'                                            #End Date
L_hikisu07='""'                                            #Batch id


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
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01113} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01114}

#���s�X�e�[�^�X�m�F
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "�w���I�[�v���E�C���^�t�F�[�X�ŏ������ꂽ�f�[�^�̃p�[�W �I��"

##2010/01/08 T.Kitagawa Add Start
### �f�o�b�O�E���O����уV�X�e���E�A���[�g�̃p�[�W ###
L_rogushuturyoku "�f�o�b�O�E���O����уV�X�e���E�A���[�g�̃p�[�W �J�n"

L_app_syokuseki_tansyukumei="SYSADMIN"                     #�E�ӂ̃A�v���P�[�V�����Z�k��
L_syokusekimei="System Administrator"                      #�E�ӂ̖���
L_yuzamei="SYSADMIN"                                       #���[�U��
L_konkarento_app_tansyukumei="FND"                         #�v���O�����A�v���P�[�V�����Z�k��
L_konkarentomei="FNDLGPRG"                                 #�v���O�����A�v���P�[�V������

#���t�v�Z
L_jikan=`expr ${TE_ZCZZHOZONKIKAN_DSP} \* 30 \* 24 + 24 - 9`
L_hikisu01=`env TZ=JST+${L_jikan} date +%Y/%m/%d`   #Last Purge Date  YYYY/MM/DD

echo "L_app_syokuseki_tansyukumei="${L_app_syokuseki_tansyukumei}   >> ${L_rogumei}
echo "L_syokusekimei="${L_syokusekimei}                             >> ${L_rogumei}
echo "L_yuzamei="${L_yuzamei}                                       >> ${L_rogumei}
echo "L_konkarento_app_tansyukumei="${L_konkarento_app_tansyukumei} >> ${L_rogumei}
echo "L_konkarentomei="${L_konkarentomei}                           >> ${L_rogumei}
echo "L_hikisu01="${L_hikisu01}                                     >> ${L_rogumei}

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
                       > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}

#�R���J�����g���s����
if [ $? -ne 0 ]
then
   echo ${TE_ZCZZ01117} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

#�v��ID�擾
L_rogushuturyoku "�v��ID�擾"
L_yokyu_id=`awk 'NR==1 {print $3}' ${TE_ZCZZHYOUJUNSHUTURYOKU}`
L_rogushuturyoku "�v��ID="${L_yokyu_id}
L_era_messeige=${TE_ZCZZ01118}

#���s�X�e�[�^�X�m�F
L_rogushuturyoku "���s�X�e�[�^�X�m�F �J�n"

${ORACLE_HOME}/bin/sqlplus -s apps/apps << EOF > ${TE_ZCZZHYOUJUNSHUTURYOKU} 2> ${TE_ZCZZHYOUJUNERA}
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

SELECT REQUEST_ID, PHASE_CODE, STATUS_CODE FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID='${L_yokyu_id}';
exit
EOF

if [ $? -ne 0 ]
then
   echo ${L_era_messeige} | /usr/bin/fold -w 75 | /usr/bin/tee -a ${L_rogumei} 1>&2
   /usr/bin/cat ${TE_ZCZZHYOUJUNSHUTURYOKU} >> ${L_rogumei}
   /usr/bin/cat ${TE_ZCZZHYOUJUNERA} >> ${L_rogumei}
   L_shuryo ${TE_ZCZZIJOUSHURYO}
fi

L_jyoutaikakunin

L_rogushuturyoku "�f�o�b�O�E���O����уV�X�e���E�A���[�g�̃p�[�W �I��"
##2010/01/08 T.Kitagawa Add End

### �����I���o�� ###
L_shuryo ${TE_ZCZZSEIJOUSHURYO}
