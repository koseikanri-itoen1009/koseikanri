CREATE OR REPLACE PACKAGE xxcmn800005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800005c(spec)
 * Description      : ���_�}�X�^�C���^�[�t�F�[�X(Outbound)
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : ���_�}�X�^�C���^�t�F�[�X T_MD070_BPO_80E
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_str_mst            ���_�}�X�^�擾�v���V�[�W�� (E-1)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W�� (E-2)
 *  upd_last_update        �ŏI�X�V�����t�@�C���X�V�v���V�[�W�� (E-3)
 *  wf_notif               Workflow�ʒm�v���V�[�W�� (E-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/11    1.0  Oracle �Ŗ� ���\  ����쐬
 *  2008/04/30    1.1  Oracle �Ŗ� ���\  �ύX�v��#11�Ή�
 *  2008/05/14    1.2  Oracle �Ŗ� ���\  �����ύX�v��#96�Ή�
 *  2008/06/12    1.3  Oracle �ۉ�       ���t���ڏ����ύX
 *  2008/07/11    1.4  Oracle �Ŗ� ���\  �d�l�s����Q#I_S_192.1.2�Ή�
 *  2008/09/18    1.5  Oracle �R�� ��_  T_S_460,T_S_453,T_S_575,T_S_559�Ή�
 *  2009/10/02    1.6  SCS �ۉ�          �{�ԏ�Q#1648
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
    iv_last_update      IN  VARCHAR2             -- �ŏI�X�V����
  );
END xxcmn800005c;
/
