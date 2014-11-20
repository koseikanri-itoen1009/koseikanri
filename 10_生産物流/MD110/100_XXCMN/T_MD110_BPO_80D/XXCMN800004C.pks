CREATE OR REPLACE PACKAGE xxcmn800004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800004c(spec)
 * Description      : �i�ڃ}�X�^�C���^�[�t�F�[�X(Outbound)
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �i�ڃ}�X�^�C���^�t�F�[�X T_MD070_BPO_80D
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_item_mst           �i�ڃ}�X�^�擾�v���V�[�W�� (D-1)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W�� (D-2)
 *  upd_last_update        �ŏI�X�V�����t�@�C���X�V�v���V�[�W�� (D-3)
 *  wf_notif               Workflow�ʒm�v���V�[�W�� (D-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/11/26    1.0  Oracle �Ŗ� ���\  ����쐬
 *  2008/05/08    1.1  Oracle �Ŗ� ���\  �ύX�v��#11�Ή�
 *  2008/06/12    1.2  Oracle �ۉ�       ���t���ڏ����ύX
 *  2008/07/11    1.3  Oracle �Ŗ� ���\  �d�l�s����Q#I_S_001.2�Ή�
 *                                       �d�l�s����Q#I_S_192.1.2�Ή�
 *  2008/09/18    1.4  Oracle �R�� ��_  T_S_460,T_S_453,T_S_575,T_S_559,�ύX#232�Ή�
 *  2008/10/08    1.5  Oracle �Ŗ� ���\  I_S_328�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode             OUT NOCOPY VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_wf_ope_div       IN  VARCHAR2,            -- �����敪
    iv_wf_class         IN  VARCHAR2,            -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,            -- ����
    iv_last_update      IN  VARCHAR2,            -- �ŏI�X�V����
    iv_syohin           IN  VARCHAR2,            -- ���i�敪
    iv_item             IN  VARCHAR2             -- �i�ڋ敪
  );
END xxcmn800004c;
/