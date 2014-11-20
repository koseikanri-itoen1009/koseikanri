CREATE OR REPLACE PACKAGE XXCOS017A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS017A01C(spec)
 * Description      : ��U�E�����P���`�F�b�N���W�v
 * MD.050           : ��U�E�����P���`�F�b�N���W�v MD050_COS_017_A01
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
 *  2009/03/17    1.0   T.Nakabayashi    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                        OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode                       OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_years_for_total            IN      VARCHAR2,         --  1.�W�v�Ώ۔N��
    iv_processing_class           IN      VARCHAR2,         --  2.�����敪
    iv_item_code                  IN      VARCHAR2,         --  3.�i�ڃR�[�h
    iv_real_wholesale_unit_price  IN      VARCHAR2          --  4.�����P��
  );
END XXCOS017A01C;
/
