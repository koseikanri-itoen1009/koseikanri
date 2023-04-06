#!/bin/ksh


################################################################################
# �V�F���@�\:JP1/Base,JP1/AJS2 ��~ShellScript �N���X�^�_���z�X�g(bebsjp00�j
# �V�F����  :jp1_app_stop.sh
# �߂�l    : 0=�m�F���ʐ���
#             0�ȊO=�m�F���ʈُ�
# �X�V����  :2008.04.04�V�K�쐬
#			 2014.04.16 �n�[�h���v���[�X�Ή�
# �X�V�Җ�  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################

#jp1_clusterhost=pebsjp00			# JP1�N���X�^�z�X�g���̐ݒ�
#jp1_clusterhost=aebsjp00			# JP1�N���X�^�z�X�g���̐ݒ�(2014.04.16�C��)
jp1_clusterhost=bebsjp00			# JP1�N���X�^�z�X�g���̐ݒ�(2021.12.23�C��)
command1=/etc/opt/jp1ajs2/jajs_stop.cluster	# JP1/AJS2��~�R�}���h
command2=/etc/opt/jp1ajs2/jajs_killall.cluster	# JP1/AJS2������~�R�}���h
command3=/etc/opt/jp1base/jbs_stop.cluster	# JP1/Base��~�R�}���h
command4=/etc/opt/jp1base/jbs_killall.cluster	# JP1/Base������~�R�}���h

# JP1/AJS2���~
$command1 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/AJS2��������~
  $command2 $jp1_clusterhost
  goto base_stop
fi

# JP1/Base���~
$command3 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/Base��������~
  $command4 $jp1_clusterhost
  goto end
fi

exit 0

