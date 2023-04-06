#!/bin/ksh

################################################################################
# �V�F���@�\:�N���X�^�pHULFT ��~ShellScript(bebshf00)
# �V�F����  :hulft_app_stop.sh
# �߂�l    : 0=�m�F���ʐ���
#             0�ȊO=�m�F���ʈُ�
# �X�V����  :2008.04.04�V�K�쐬
#			 2014.04.16 �n�[�h���v���[�X�Ή�
# �X�V�Җ�  :HITACHI.TAMURA
#			 HITACHI.YOKOUCHI(2014.04.16)
################################################################################

command1="/usr/local/HULFT/bin/hulclustersnd -stop -t -m"     # �z�M�f�[�����I������
command2="/usr/local/HULFT/bin/hulclustersnd -stop -f -m"     # �z�M�f�[���������I��
command3="/usr/local/HULFT/bin/hulclusterrcv -stop -t -m"     # �W�M�f�[�����I������
command4="/usr/local/HULFT/bin/hulclusterrcv -stop -f -m"     # �W�M�f�[���������I��
command5="/usr/local/HULFT/bin/hulclusterobs -stop -t -m"     # �v����t�f�[�����I������
command6="/usr/local/HULFT/bin/hulclusterobs -stop -f -m"     # �v����t�f�[���������I��
command7=/etc/opt/jp1ajs2/jajs_stop.cluster                   # JP1/AJS2��~�R�}���h
command8=/etc/opt/jp1ajs2/jajs_killall.cluster                # JP1/AJS2������~�R�}���h
command9=/etc/opt/jp1base/jbs_stop.cluster                    # JP1/Base��~�R�}���h
command10=/etc/opt/jp1base/jbs_killall.cluster                # JP1/Base������~�R�}���h

# ���ϐ��ݒ�
HULPATH=/hulft/etc/
HULEXEP=/usr/local/HULFT/bin/
export HULPATH
export HULEXEP
#jp1_clusterhost=pebshf00                        # JP1�N���X�^�z�X�g���̐ݒ�
#jp1_clusterhost=aebshf00                        # JP1�N���X�^�z�X�g���̐ݒ� (2014.04.16�C��)
jp1_clusterhost=bebshf00                        # JP1�N���X�^�z�X�g���̐ݒ� (2021.12.23�C��)

# �z�M�f�[�����I���������[�e�B���e�B
$command1
if [ $? -ne 0 ] ; then
  # �z�M�f�[���������I�����[�e�B���e�B
  $command2
fi

# �W�M�f�[�����I���������[�e�B���e�B
$command3
if [ $? -ne 0 ] ; then
  # �W�M�f�[���������I�����[�e�B���e�B
  $command4
fi

# �v����t�f�[�����I���������[�e�B���e�B
$command5
if [ $? -ne 0 ] ; then
  # �v����t�f�[���������I�����[�e�B���e�B
  $command6
fi

# JP1/AJS2���~
$command7 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/AJS2��������~
  $command2 $jp1_clusterhost
  goto base_stop
fi

# JP1/Base���~
$command9 $jp1_clusterhost
rc=$?
if [ $rc -ne 0 ] ; then
  # JP1/Base��������~
  $command4 $jp1_clusterhost
  goto end
fi

exit 0
