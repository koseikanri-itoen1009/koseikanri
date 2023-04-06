#!/bin/ksh

################################################################################
# �V�F���@�\:NFS �N��ShellScript �N���X�^�_���z�X�g(bebsfssv00)�j
# �V�F����  :fsnfsjp1_app_start.sh
# �߂�l    : 0=�m�F���ʐ���
#             0�ȊO=�m�F���ʈُ�
# �X�V����  :2008.04.04�V�K�쐬
#			 2014.04.16 �n�[�h���v���[�X�Ή�
#			 2022.02.21 �V�X�e�����t�g�Ή�
# �X�V�Җ�  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
#			 HITACHI.YONENO(2022.02.21)
################################################################################
#jp1_clusterhost=aebshf00                        # JP1�N���X�^�z�X�g���̐ݒ� (2014.04.16�C��)
jp1_clusterhost=bebsfssv00                       # JP1�N���X�^�z�X�g���̐ݒ� (2022.2.21�C��)
command1=/etc/opt/jp1base/jbs_start.cluster     # JP1/Base�N���R�}���h
command2=/etc/opt/jp1ajs2/jajs_start.cluster    # JP1/AJS2�N���R�}���h
command3="/sbin/service portmap start"	        # portmap�N���R�}���h
command4="/sbin/service rpcidmapd start"	    # rpcidmapd�N���R�}���h
command5="/sbin/service nfs start"	            # NFS�T�[�o�N���R�}���h
command6="/sbin/service nfslock start"	        # nfslock�N���R�}���h
#bootipaddr=`lsattr -El en6 -a netaddr | cut -d ' ' -f 2` # bootip

# ���ϐ��ݒ�
#PATH=/usr/local/HULFT/bin:/uspg/jp1/za/shl/XEBSITO:$PATH
#HULPATH=/hulft/etc
#HULEXEP=/usr/local/HULFT/bin
#export PATH
#export HULPATH
#export HULEXEP

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

# portmap�N��
$command3
if [ $? -ne 0 ] ; then
  exit $?
fi

# rpcidmapd�N��
$command4
if [ $? -ne 0 ] ; then
  exit $?
fi

# NFS�T�[�o�N��
$command5
if [ $? -ne 0 ] ; then
  exit $?
fi

# nfslock�N��
$command6
if [ $? -ne 0 ] ; then
  exit $?
fi

exit 0
