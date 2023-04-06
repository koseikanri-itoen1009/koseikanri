#!/bin/ksh

################################################################################
# �V�F���@�\:�N���X�^�pNFS ��~ShellScript(bebsfssv00)
# �V�F����  :fsnfsjp1_app_stop.sh
# �߂�l    : 0=�m�F���ʐ���
#             0�ȊO=�m�F���ʈُ�
# �X�V����  :2008.04.04�V�K�쐬
#			 2014.04.16 �n�[�h���v���[�X�Ή�
#			 2022.02.21 �V�X�e�����t�g�Ή�
# �X�V�Җ�  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
#			 HITACHI.YONENO(2022.02.21)
################################################################################

command1="/sbin/service nfslock stop"                    # nfslock��~�R�}���h
command2="/sbin/service nfs stop"                        # NFS�T�[�o��~�R�}���h
command3="/sbin/service rpcidmapd stop"                  # rpcidmapd��~�R�}���h
command4="/sbin/service portmap stop"                    # portmap��~�R�}���h
command5=/etc/opt/jp1ajs2/jajs_stop.cluster              # JP1/AJS2��~�R�}���h
command6=/etc/opt/jp1ajs2/jajs_killall.cluster           # JP1/AJS2������~�R�}���h
command7=/etc/opt/jp1base/jbs_stop.cluster               # JP1/Base��~�R�}���h
command8=/etc/opt/jp1base/jbs_killall.cluster            # JP1/Base������~�R�}���h

# ���ϐ��ݒ�
#HULPATH=/hulft/etc/
#HULEXEP=/usr/local/HULFT/bin/
#export HULPATH
#export HULEXEP
#jp1_clusterhost=pebshf00                        # JP1�N���X�^�z�X�g���̐ݒ�
#jp1_clusterhost=aebshf00                        # JP1�N���X�^�z�X�g���̐ݒ� (2014.04.16�C��)
jp1_clusterhost=bebsfssv00                        # JP1�N���X�^�z�X�g���̐ݒ� (2022.02.21�C��)

# nfslock��~
$command1
if [ $? -ne 0 ] ; then
  exit $?
fi

# NFS�T�[�o��~
$command2
if [ $? -ne 0 ] ; then
  exit $?
fi

# rpcidmapd��~
$command3
if [ $? -ne 0 ] ; then
  exit $?
fi

# portmap��~
$command4
if [ $? -ne 0 ] ; then
  exit $?
fi

# JP1/AJS2���~
$command5 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/AJS2��������~
  $command6 $jp1_clusterhost
  goto base_stop
fi

# JP1/Base���~
$command6 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/Base��������~
  $command8 $jp1_clusterhost
  goto end
fi

exit 0
