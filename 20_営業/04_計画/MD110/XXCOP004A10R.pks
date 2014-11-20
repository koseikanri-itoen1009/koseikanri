CREATE OR REPLACE PACKAGE APPS.XXCOP004A10R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A10R(spec)
 * Description      : ����v����ёΔ�\
 * MD.050           : MD050_COP_004_A10_����v����ёΔ�\
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
 *  2013/11/18    1.0   S.Niki            main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf    OUT VARCHAR2  -- �G���[���b�Z�[�W #�Œ�#
    , retcode   OUT VARCHAR2  -- �G���[�R�[�h     #�Œ�#
    , iv_target_month      IN  VARCHAR2         -- 1.�Ώ۔N��
    , iv_forecast_type     IN  VARCHAR2         -- 2.�v��敪
    , iv_prod_class_code   IN  VARCHAR2         -- 3.���i�敪
    , iv_base_code         IN  VARCHAR2         -- 4.���_
    , iv_crowd_class_code  IN  VARCHAR2         -- 5.����Q�R�[�h
    , iv_item_code         IN  VARCHAR2         -- 6.�i�ڃR�[�h
  );
END XXCOP004A10R;
/
