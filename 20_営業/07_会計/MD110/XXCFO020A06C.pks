CREATE OR REPLACE PACKAGE APPS.XXCFO020A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A06C (spec)
 * Description      : ���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\
 * MD.050           : ���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\ (MD050_CFO_020A06)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/09/26    1.0   T.Kobori         �V�K�쐬
 *
 *****************************************************************************************/
--
  --���ǉ�v�d��Ȗڃ}�b�s���O���ʋ@�\
  PROCEDURE get_siwake_account_title(
    ov_retcode                OUT    VARCHAR2      -- ���^�[���R�[�h
   ,ov_errbuf                 OUT    VARCHAR2      -- �G���[���b�Z�[�W
   ,ov_errmsg                 OUT    VARCHAR2      -- ���[�U�[�E�G���[���b�Z�[�W
   ,ov_company_code           OUT    VARCHAR2      -- 1.���
   ,ov_department_code        OUT    VARCHAR2      -- 2.����
   ,ov_account_title          OUT    VARCHAR2      -- 3.����Ȗ�
   ,ov_account_subsidiary     OUT    VARCHAR2      -- 4.�⏕�Ȗ�
   ,ov_description            OUT    VARCHAR2      -- 5.�E�v
   ,iv_report                 IN     VARCHAR2      -- 6.���[
   ,iv_class_code             IN     VARCHAR2      -- 7.�i�ڋ敪
   ,iv_prod_class             IN     VARCHAR2      -- 8.���i�敪
   ,iv_reason_code            IN     VARCHAR2      -- 9.���R�R�[�h
   ,iv_ptn_siwake             IN     VARCHAR2      -- 10.�d��p�^�[��
   ,iv_line_no                IN     VARCHAR2      -- 11.�s�ԍ�
   ,iv_gloif_dr_cr            IN     VARCHAR2      -- 12.�ؕ��E�ݕ�
   ,iv_warehouse_code         IN     VARCHAR2      -- 13.�q�ɃR�[�h
  );
END XXCFO020A06C;
/
