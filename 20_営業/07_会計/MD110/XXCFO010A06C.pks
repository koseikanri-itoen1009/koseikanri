CREATE OR REPLACE PACKAGE APPS.XXCFO010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO010A06C(spec)
 * Description      : GLOIF�d��̓]�����o
 * MD.050           : T_MD050_CFO_010_A06_GLOIF�d��̓]�����o_EBS�R���J�����g
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
 *  2022-12-09    1.0   K.Tomie          �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf              OUT VARCHAR2    -- �G���[���b�Z�[�W # �Œ� #
    , retcode             OUT VARCHAR2    -- �G���[�R�[�h     # �Œ� #
    , iv_execute_kbn      IN  VARCHAR2    -- ���s�敪
    , in_set_of_books_id  IN  NUMBER      -- ����ID
    , iv_je_source_name   IN  VARCHAR2    -- �d��\�[�X
    , iv_je_category_name IN  VARCHAR2    -- �d��J�e�S��
  );
END XXCFO010A06C;
/