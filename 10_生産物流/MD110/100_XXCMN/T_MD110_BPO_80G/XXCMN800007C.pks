CREATE OR REPLACE PACKAGE xxcmn800007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800007c(spec)
 * Description      : �q�Ƀ}�X�^�C���^�[�t�F�[�X(Outbound)
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �q�Ƀ}�X�^�C���^�t�F�[�X T_MD070_BPO_80G
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_ware_mst           �q�Ƀ}�X�^�擾�v���V�[�W�� (G-1)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W�� (G-2)
 *  upd_last_update        �ŏI�X�V�����t�@�C���X�V�v���V�[�W�� (G-3)
 *  wf_notif               Workflow�ʒm�v���V�[�W�� (G-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/26    1.0  Oracle �Ŗ� ���\  ����쐬
 *  2008/05/02    1.1  Oracle �Ŗ� ���\  �ύX�v��#11������ύX�v��#62�Ή�
 *  2008/06/12    1.2  Oracle �ۉ�       ���t���ڏ����ύX
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
    iv_deli_type        IN  VARCHAR2             -- �o�׊Ǘ����敪
  );
END xxcmn800007c;
/
