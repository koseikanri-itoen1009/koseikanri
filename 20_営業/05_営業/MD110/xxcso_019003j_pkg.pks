CREATE OR REPLACE PACKAGE APPS.xxcso_019003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_019003j_pkg(SPEC)
 * Description      : ���_�ʌ��ʌv��e�[�u���o�^
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  set_dept_monthly_plans     P          ���_�ʌ��ʌv��e�[�u���o�^�p�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/28    1.0   R.Oikawa          �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
   -- ���_�ʌ��ʌv��e�[�u���o�^�p�v���V�[�W��
  PROCEDURE set_dept_monthly_plans(
    iv_base_code                 IN  VARCHAR2,           -- ���_CD
    iv_year_month                IN  VARCHAR2,           -- �N��
    in_dept_monthly_plan_id      IN  NUMBER,             -- ���_�ʌ��ʌv��ID
    iv_sales_plan_rel_div        IN  VARCHAR2            -- ����v��J���敪
  );
--
END xxcso_019003j_pkg;
/
