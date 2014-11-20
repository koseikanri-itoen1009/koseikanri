CREATE OR REPLACE PACKAGE xxwsh930007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930007c(spec)
 * Description      : �O���q�ɓ��o�Ɏ��уC���^�t�F�[�X���b�s���O�v���O����
 * MD.050           : �o�ׁE�ړ��C���^�t�F�[�X                             T_MD050_BPO_930
 * MD.070           : �O���q�ɓ��o�Ɏ��уC���^�t�F�[�X���b�s���O�v���O���� T_MD070_BPO_93G
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/09    1.0   Y.Suzuki         �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode                OUT VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_process_object_info IN  VARCHAR2          -- �����Ώۏ��
   ,iv_report_post         IN  VARCHAR2          -- �񍐕���
   ,iv_object_warehouse    IN  VARCHAR2          -- �Ώۑq��
  );
END xxwsh930007c;
/
