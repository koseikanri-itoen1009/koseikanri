CREATE OR REPLACE PACKAGE XXCMM004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A10C(spec)
 * Description      : �i�ڈꗗ�쐬
 * MD.050           : �i�ڈꗗ�쐬 MD050_CMM_004_A10
 * Version          : Draft2C
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
 *  2008/12/11    1.0   N.Nishimura      main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,    -- �G���[���b�Z�[�W #�Œ�#
    retcode              OUT    VARCHAR2,    -- �G���[�R�[�h     #�Œ�#
    iv_output_div        IN     VARCHAR2,    -- �o�͑Ώېݒ�l
    iv_item_status       IN     VARCHAR2,    -- �i�ڃX�e�[�^�X
    iv_date_from         IN     VARCHAR2,    -- �Ώۊ��ԊJ�n
    iv_date_to           IN     VARCHAR2,    -- �Ώۊ��ԏI��
    iv_item_code_from    IN     VARCHAR2,    -- �i���R�[�h�J�n
    iv_item_code_to      IN     VARCHAR2     -- �i���R�[�h�I��
  );
END XXCMM004A10C;
/
