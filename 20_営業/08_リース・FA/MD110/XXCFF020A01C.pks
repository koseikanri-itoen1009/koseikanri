CREATE OR REPLACE PACKAGE XXCFF020A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCFF020A01C(spec)
 * Description      : �o�^�ςݎx���v��̎x�������A�x���񐔂̕ύX
 * MD.050           : MD050_CFF_020_A01_���[�X���ύX�v���O����
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
 *  2018/10/02    1.0   H.Sasaki         �V�K�쐬(E_�{�ғ�_14830)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf            OUT VARCHAR2          --  �G���[���b�Z�[�W #�Œ�#
    , retcode           OUT VARCHAR2          --  �G���[�R�[�h     #�Œ�#
    , iv_object_code    IN  VARCHAR2          --  �����R�[�h
    , iv_new_frequency  IN  VARCHAR2          --  �ύX��x����
    , iv_new_charge     IN  VARCHAR2          --  �ύX�ナ�[�X��
    , iv_new_tax_charge IN  VARCHAR2          --  �ύX��Ŋz
    , iv_new_tax_code   IN  VARCHAR2          --  �ύX��ŃR�[�h
  );
END XXCFF020A01C;
/
