CREATE OR REPLACE PACKAGE APPS.XXCSO005A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO005A02C(spec)
 * Description      : �c�ƈ����\�[�X�`�F�b�NCSV�o��
 * MD.050           : �c�ƈ����\�[�X�`�F�b�NCSV�o�� (MD050_CSO_005A02)
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
 *  2013/10/01    1.0   S.Niki            main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2    --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT    VARCHAR2    --   �G���[�R�[�h     #�Œ�#
   ,iv_base_code  IN     VARCHAR2    -- 1.���_�R�[�h
   ,iv_base_date  IN     VARCHAR2    -- 2.��N����
  );
END XXCSO005A02C;
/
