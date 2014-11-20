CREATE OR REPLACE PACKAGE xxcmn800009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800009c(spec)
 * Description      : �����\���}�X�^�C���^�[�t�F�[�X(Outbound)
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �����\���}�X�^�C���^�t�F�[�X T_MD070_BPO_80I
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_logi_mst           �����\���}�X�^�擾�v���V�[�W�� (I-1)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W�� (I-2)
 *  upd_last_update        �ŏI�X�V�����t�@�C���X�V�v���V�[�W�� (I-3)
 *  wf_notif               Workflow�ʒm�v���V�[�W�� (I-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/15    1.0  Oracle �Ŗ� ���\  ����쐬
 *  2008/05/01    1.1  Oracle �Ŗ� ���\  �ύX�v��#11�Ή�
 *  2008/05/15    1.2  Oracle �Ŗ� ���\  �����ύX�v��#62�Ή�
 *  2008/06/12    1.3  Oracle �ۉ�       ���t���ڏ����ύX
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
END xxcmn800009c;
/
