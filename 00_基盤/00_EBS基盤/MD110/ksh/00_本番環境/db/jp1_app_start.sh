#!/bin/ksh

################################################################################
# �V�F���@�\:JP1/Base,JP1/AJS2 �N��ShellScript �N���X�^�_���z�X�g(bebsjp00�j
# �V�F����  :jp1_app_start.sh
# �߂�l    : 0=�m�F���ʐ���
#             0�ȊO=�m�F���ʈُ�
# �X�V����  :2008.04.04�V�K�쐬
#			 2014.04.16 �n�[�h���v���[�X�Ή�
# �X�V�Җ�  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################
#jp1_clusterhost=pebsjp00			# JP1�N���X�^�z�X�g���̐ݒ�
#jp1_clusterhost=aebsjp00			# JP1�N���X�^�z�X�g���̐ݒ� (2014.04.16�C��)
jp1_clusterhost=bebsjp00			# JP1�N���X�^�z�X�g���̐ݒ� (2021.12.23�C��)
command1=/etc/opt/jp1base/jbs_start.cluster	# JP1/Base�N���R�}���h
command2=/etc/opt/jp1ajs2/jajs_start.cluster	# JP1/AJS2�N���R�}���h
#bootipaddr=`lsattr -El en6 -a netaddr | cut -d ' ' -f 2` # bootip

#ifconfig en6 alias ${bootipaddr} netmask 255.255.255.0 firstalias

# JP1/Base���N��
$command1 $jp1_clusterhost
if [ $? -ne 0 ] ; then
  exit $?
fi

# JP1/AJS2���N��
$command2 $jp1_clusterhost
if [ $? -ne 0 ] ; then
  exit $?
fi

exit 0
