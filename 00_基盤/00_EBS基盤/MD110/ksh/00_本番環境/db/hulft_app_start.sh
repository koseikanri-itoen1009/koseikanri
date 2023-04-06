#!/bin/ksh

################################################################################
# �V�F���@�\:HULFT �N��ShellScript �N���X�^�_���z�X�g(bebshf00)�j
# �V�F����  :hulft_app_start.sh
# �߂�l    : 0=�m�F���ʐ���
#             0�ȊO=�m�F���ʈُ�
# �X�V����  :2008.04.04�V�K�쐬
#			 2014.04.16 �n�[�h���v���[�X�Ή�
# �X�V�Җ�  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################
#jp1_clusterhost=aebshf00                        # JP1�N���X�^�z�X�g���̐ݒ� (2014.04.16�C��)
jp1_clusterhost=bebshf00                        # JP1�N���X�^�z�X�g���̐ݒ� (2021.12.23�C��)
command1=/etc/opt/jp1base/jbs_start.cluster     # JP1/Base�N���R�}���h
command2=/etc/opt/jp1ajs2/jajs_start.cluster    # JP1/AJS2�N���R�}���h
command3="/usr/local/HULFT/bin/hulclustersnd -start -m"	# �z�M�f�[�����N��(�N���������[�h)
command4="/usr/local/HULFT/bin/hulclusterrcv -start -m"	# �W�M�f�[�����N��(�N���������[�h)	
command5="/usr/local/HULFT/bin/hulclusterobs -start -m"	# �v����t�f�[�����N��(�N���������[�h)
#bootipaddr=`lsattr -El en6 -a netaddr | cut -d ' ' -f 2` # bootip

# ���ϐ��ݒ�
PATH=/usr/local/HULFT/bin:/uspg/jp1/za/shl/BEBSITO:$PATH
HULPATH=/hulft/etc
HULEXEP=/usr/local/HULFT/bin
export PATH
export HULPATH
export HULEXEP

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

# �z�M�f�[�����N������(�N���������[�h)���[�e�B���e�B
$command3
if [ $? -ne 0 ] ; then
  exit $?
fi

# �W�M�f�[�����N������(�N���������[�h)���[�e�B���e�B
$command4
if [ $? -ne 0 ] ; then
  exit $?
fi

# �v����t�f�[�����N������(�N���������[�h)���[�e�B���e�B
$command5
if [ $? -ne 0 ] ; then
  exit $?
fi

exit 0
