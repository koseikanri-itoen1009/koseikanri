#!/bin/ksh

################################################################################
# �V�F���@�\:�N���X�^�pHULFT �Ď�ShellScript(bebshf00)
# �V�F����  :hulft_app_check.sh
# �߂�l    : 0=�m�F���ʐ���
#             0�ȊO=�m�F���ʈُ�
# �X�V����  :2008.04.04�V�K�쐬
#			:2009.7.14 �L���[���X�Ď��ǉ�
#			 2014.04.16 �n�[�h���v���[�X�Ή�
# �X�V�Җ�  :HITACHI.TAMURA�i2008.4.4�j
#			:HITACHI.MURAOKA�i2009.7.14�j
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################
HULEXEP=/usr/local/HULFT/bin;export HULEXEP
HULPATH=/hulft/etc;export HULPATH

#jp1_clusterhost=pebshf00							# JP1�N���X�^�z�X�g���̐ݒ�
#jp1_clusterhost=aebshf00							# JP1�N���X�^�z�X�g���̐ݒ� (2014.04.16�C��)
jp1_clusterhost=bebshf00							# JP1�N���X�^�z�X�g���̐ݒ� (2021.12.23�C��)
command1="/opt/jp1base/bin/jbs_spmd_status"			# JP1/Base�N���m�F�R�}���h
command1_timeout=5									#�R�}���h�^�C���A�E�g���ԁi�b�j
command1_retry_interval=1							# �X�e�[�^�X�擾���s���̃��g���C�Ԋu�i�b�j
command1_retry_count=2								# �X�e�[�^�X�擾���s���̃��g���C��

command2="/opt/jp1base/bin/jevstat"					# JP1/Base�C�x���g�T�[�r�X�N���m�F�R�}���h
command2_timeout=5									#�R�}���h�^�C���A�E�g���ԁi�b�j

command3="/opt/jp1ajs2/bin/jajs_spmd_status"		# JP1/AJS2�N���m�F�R�}���h
command3_timeout=5									#�R�}���h�^�C���A�E�g���ԁi�b�j
command3_retry_interval=1							# �X�e�[�^�X�擾���s���̃��g���C�Ԋu�i�b�j
command3_retry_count=2								# �X�e�[�^�X�擾���s���̃��g���C��
command3_Queueless="/opt/jp1ajs2/bin/ajsqlstatus"	#JP1�L���[���X�G�[�W�F���g�T�[�r�X�N���m�F�R�}���h�i2009.7.14�ǉ��j

command4="/usr/local/HULFT/bin/hulclustersnd -status -m"	# �z�M�f�[���������m�F
command5="/usr/local/HULFT/bin/hulclusterrcv -status -m"	# �W�M�f�[���������m�F
command6="/usr/local/HULFT/bin/hulclusterobs -status -m"	# �v����t�f�[���������m�F

# JP1/Base�̋N���m�F
$command1 -h $jp1_clusterhost
rc=$?
case $rc in
# ���^�[���R�[�h��0�̏ꍇ�C�x���g�T�[�r�X�̋N���m�F��
0)
  ;;
# ���^�[���R�[�h��12�̏ꍇ�C�x���g�T�[�r�X�̋N���m�F��
12)
#  flg1 = 0�i2009.7.14�C���j
  flg1=0
#  i = 0
  i=0
#  while [ $rc -eq 12 -a $i < $command1_retry_count ] -a [ $flg1 = 0 ]�i2009.7.14�C���j
  while [ $rc -eq 12 -a $i -lt $command1_retry_count -a $flg1 -eq 0 ]
  do
    sleep $command1_retry_interval
    $command1 -h $jp1_clusterhost -t $command1_timeout
    rc=$?
    case $rc in
    0)
#      flg1 = 1;;�i2009.7.14�C���j
      flg1=1;;
    12)
      i=$(($i+1));;
    *)
      exit $rc;;
   esac
#  done;;�i2009.7.14�C���j
   done
# �ȉ�4�s�i2009.7.14�ǉ��j
   if [ $rc -eq 12 -a $flg1 -eq 0 -a $i -eq $command1_retry_count ]
   then
     exit 12
   fi;;
# ���^�[���R�[�h��0,12�ȊO�̏ꍇ�ُ�I��
*)
  exit $rc;;
esac

# JP1/Base �C�x���g�T�[�r�X�̋N���m�F
$command2 $jp1_clusterhost -t $command2_timeout
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

# JP1/AJS2�T�[�r�X�̋N���m�F
$command3 -h $jp1_clusterhost
rc=$?
case $rc in
# ���^�[���R�[�h��0�̏ꍇ�z�M�f�[���������m�F���[�e�B���e�B��
0)
#  exit 0;;�i2009.7.14�C���j
  ;;
# ���^�[���R�[�h��12�̏ꍇ�w��񐔃��g���C
12)
#  flg2 = 0�i2009.7.14�C���j
  flg2=0
#  i = 0�i2009.7.14�C���j
  i=0
#  while [ $rc -eq 12 -a $i < $command3_retry_count ] -a [ $flg2 = 0 ]�i2009.7.14�C���j
  while [ $rc -eq 12 -a $i -lt $command3_retry_count -a $flg2 -eq 0 ]
  do
    sleep $command3_retry_interval
    $command3 -t $command3_timeout
    rc=$?
    case $rc in
    0)
#      flg2 = 1;;�i2009.7.14�C���j
      flg2=1;;
    12)
      i=$(($i+1));;
    *)
      exit $rc;;
    esac
#  done;;�i2009.7.14�C���j
  done
# �ȉ�4�s�i2009.7.14�ǉ��j
  if [ $rc -eq 12 -a $flg2 -eq 0 -a $i -eq $command3_retry_count ]
  then
    exit 12
  fi;;
*)
  exit $rc;;
esac

# �z�M�f�[���������m�F���[�e�B���e�B
$command4
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

# �W�M�f�[���������m�F���[�e�B���e�B
$command5
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

# �v����t�f�[���������m�F���[�e�B���e�B
$command6
rc=$?
if [ $rc -ne 0 ] ; then
  exit $rc
fi

###################################################################
# �ȉ��L���[���X�G�[�W�F���g�T�[�r�X�N���m�F�i2009.7.14�ǉ��jbegin#
###################################################################
# JP1�L���[���X�G�[�W�F���g�T�[�r�X�N���m�F
unset LANG
  flg3=0
$command3_Queueless -h $jp1_clusterhost | grep 'Queueless agent service' | grep ' active'
rc=$?
case $rc in
# ���^�[���R�[�h��0�̏ꍇ����I��
0)
  flg3=1
  ;;
# ���^�[���R�[�h��1�̏ꍇ�ُ�I��
1)
  i=0
  while [ $rc -eq 1 -a $i -lt $command3_retry_count -a $flg3 -eq 0 ]
  do
    sleep $command3_retry_interval
    $command3_Queueless -h $jp1_clusterhost | grep 'Queueless agent service' | grep ' active'
    rc=$?
    case $rc in
    0)
      flg3=1;;
    1)
      i=$(($i+1));;
    *)
      exit $rc;;
    esac
  done;;
*)
  exit $rc;;
esac
if [ $flg3 -eq 0 ];then
exit 1
fi
#################################################################
# �ȉ��L���[���X�G�[�W�F���g�T�[�r�X�N���m�F�i2009.7.14�ǉ��jend#
#################################################################

#################################################################
# �ȉ��L���[���X�}�l�[�W���T�[�r�X�N���m�F�i2009.7.14�ǉ��jbegin#
#################################################################

# JP1�L���[���X�}�l�[�W���T�[�r�X�N���m�F
#  flg4=0
#$command3_Queueless -h $jp1_clusterhost | grep 'Queueless file transfer service' | grep 'active'
#rc=$?
#case $rc in
# ���^�[���R�[�h��0�̏ꍇ����I��
#0)
#  ;;
# ���^�[���R�[�h��1�̏ꍇ�ُ�I��
#1)
#  i=0
#  while [ $rc -eq 12 -a $i -lt $command3_retry_count -a $flg4 -eq 0 ]
#  do
#    sleep $command3_retry_interval
#    $command3_Queueless -h $jp1_clusterhost | grep 'Queueless file transfer service' | grep 'active'
#    rc=$?
#    case $rc in
#    0)
#      flg4=1;;
#    1)
#      i=$(($i+1));;
#    *)
#      exit $rc;;
#    esac
#  done;;
#*)
#  exit $rc;;
#esac
#if [ flg4 -eq 0 ];then
#exit 1
#fi
###############################################################
# �ȉ��L���[���X�}�l�[�W���T�[�r�X�N���m�F�i2009.7.14�ǉ��jend#
###############################################################

exit 0

