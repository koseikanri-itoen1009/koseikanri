#!/usr/bin/ksh

################################################################################
##                                                                            ##
##   [�T�v]                                                                   ##
##          �T�[�r�X�N���E��~�m�F                                            ##
##                                                                            ##
##   [�쐬/�X�V����]                                                          ##
##        �쐬��  �F   Oracle �x��           2008/05/14 1.0.1                 ##
##        �X�V�����F   Oracle �x��           2008/05/14 1.0.1                 ##
##                       ����                                                 ##
##                     SCSK ����             2014/07/31 2.0.0                 ##
##                       HW���v���[�X�Ή�(���v���[�X_00007)                   ##
##                         �ECopyright�̍폜                                  ##
##                         �ETNS���X�i�[�̋N���m�F�Ώۃv���Z�X��ύX          ##
##                                                                            ##
##   [�߂�l]                                                                 ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�p�����[�^]                                                             ##
##      �Ȃ�                                                                  ##
##                                                                            ##
##   [�g�p���@]                                                               ##
##      /uspg/jp1/zc/shl/<���ˑ��l>/ZCZZ_PROCESS_CHECK.ksh                  ##
##                                                                            ##
################################################################################

################################################################################
##                                 �ϐ���`                                   ##
################################################################################


## �ϐ���`
L_hosutomei=`/bin/hostname`        ##���s�z�X�g��
L_uzamei=`/bin/whoami`             ##���s���[�U��
L_web_f=""                         ##Web�T�[�o�m�F�p�t���O
L_apps_f=""                        ##AP�T�[�o�m�F�p�t���O
L_tns_f=""                         ##TNS���X�i�[�m�F�p�t���O
L_db_f=""                          ##DB�T�[�o�m�F�p�t���O


################################################################################
##                                 �֐���`                                   ##
################################################################################


## �`�o�T�[�o�m�F
L_ap_kakunin()
{
   # Web�T�[�o�N���m�F
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep iAS | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_web_f=0            # Web�T�[�o��~�ς�
   else
      L_web_f=1
   fi
   
   # APPS���X�i�[�N���m�F
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_apps_f=0           # APPS���X�i�[��~�ς�
   else
      L_apps_f=1
   fi

   # ����
   if [ "${L_web_f}" -eq 0 -a "${L_apps_f}" -eq 0 ]
   then
      echo "${L_hosutomei}�T�[�o��EBS�v���Z�X�͒�~���Ă��܂�"
   elif [ "${L_web_f}" -eq 1 -a "${L_apps_f}" -eq 1 ]
   then
      echo "${L_hosutomei}�T�[�o��EBS�v���Z�X�͋N�����Ă��܂�"
   else
      echo "EBS�v���Z�X�N���ُ�"
   fi
}

## �c�a�T�[�o�m�F
L_db_kakunin()
{
   # APPS���X�i�[�N���m�F
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep APPS | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_apps_f=0      # APPS���X�i�[��~�ς�
   else
      L_apps_f=1
   fi

   # TNS���X�i�[�N���m�F
##2014/07/31 S.Takahashi Mod Start
#   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep "10.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep "11.2.0" | /usr/bin/grep inherit | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
##2014/07/31 S.Takahashi Mod End
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_tns_f=0       # TNS���X�i�[��~�ς�
   else
      L_tns_f=1
   fi

   # �f�[�^�x�[�X�N���m�F
   L_purosesu=`/usr/bin/ps -ef | grep ${L_uzamei} | /usr/bin/grep ora_pmon | /usr/bin/grep -v "grep" | /usr/bin/wc -l`
   if [ "${L_purosesu}" -eq 0 ]
   then
      L_db_f=0        # �f�[�^�x�[�X��~�ς�
   else
      L_db_f=1
   fi

   # ����
   if [ "${L_apps_f}" -eq 0 -a "${L_tns_f}" -eq 0 -a "${L_db_f}" -eq 0 ]
   then
      echo "${L_hosutomei}�T�[�o��EBS�v���Z�X�͒�~���Ă��܂�"
   elif [ "${L_apps_f}" -eq 1 -a "${L_tns_f}" -eq 1 -a "${L_db_f}" -eq 1 ]
   then
      echo "${L_hosutomei}�T�[�o��EBS�v���Z�X�͋N�����Ă��܂�"
   else
      echo "EBS�v���Z�X�N���ُ�"
   fi
}


################################################################################
##                                 ���C��                                     ##
################################################################################

L_ap_db_hantei=`echo ${L_hosutomei} | /usr/bin/cut -c 5-6`


case ${L_ap_db_hantei} in
   "ap")   L_ap_kakunin
           ;;
   "db")   L_db_kakunin
           ;;
   *)      echo "����Ɏ��s���܂���"
           ;;
esac


