CREATE OR REPLACE PACKAGE xxwsh930001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930001c(spec)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �o�ׁE�ړ��C���^�t�F�[�X         T_MD050_BPO_930
 * MD.070           : �O���q�ɓ��o�Ɏ��уC���^�t�F�[�X T_MD070_BPO_93A
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0  Oracle �V�� �r��  ����쐬
 *  2008/05/19    1.1  Oracle �{�c ���j  �w�E����Seq262�C263
 *  2008/06/05    1.2  Oracle �{�c ���j  �����e�X�g���{�ɔ������C
 *  2008/06/13    1.3  Oracle �{�c ���j  �����e�X�g���{�ɔ������C
 *  2008/06/23    1.4  Oracle �{�c ���j  ST�s�#230�Ή�
 *  2008/06/24    1.5  Oracle �{�c ���j  ST�s�#230�Ή�(2)
 *  2008/06/27    1.6  Oracle �{�c ���j  ST�s�#299�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT NOCOPY VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_process_object_info    IN  VARCHAR2,            -- �����Ώۏ��
    iv_report_post            IN  VARCHAR2,            -- �񍐕���
    iv_object_warehouse       IN  VARCHAR2             -- �Ώۑq��
  );
END xxwsh930001c;
/
