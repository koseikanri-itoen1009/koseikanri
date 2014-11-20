CREATE OR REPLACE PACKAGE BODY APPS.xxcso_019003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Function Name    : xxcso_019003j_pkg(BODY)
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
    gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_019003j_pkg';   -- �p�b�P�[�W��
   /**********************************************************************************
   * Function Name    : set_dept_monthly_plans
   * Description      : ���_�ʌ��ʌv��e�[�u���o�^�p�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE set_dept_monthly_plans(
    iv_base_code                 IN  VARCHAR2,           -- ���_CD
    iv_year_month                IN  VARCHAR2,           -- �N��
    in_dept_monthly_plan_id      IN  NUMBER,             -- ���_�ʌ��ʌv��ID
    iv_sales_plan_rel_div        IN  VARCHAR2            -- ����v��J���敪
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)   := 'set_dept_monthly_plans';
    --WHO�J����
    cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
    cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
    cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
    cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
    cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_dept_monthly_plan_id            NUMBER(15);
    lv_fiscal_year                     VARCHAR2(4);
  BEGIN
--
    BEGIN
      SELECT dept_monthly_plan_id
      INTO   ln_dept_monthly_plan_id
      FROM   xxcso_dept_monthly_plans
      WHERE  base_code  = iv_base_code
      AND    year_month = iv_year_month;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ln_dept_monthly_plan_id := NULL;
    END;
--
    IF  ln_dept_monthly_plan_id IS NULL THEN
      /* ���_�ʌ��ʌv��ID�擾���� */
      BEGIN
        SELECT xxcso_dept_monthly_plans_s01.nextval AS nextval
        INTO   ln_dept_monthly_plan_id
        FROM   DUAL;
      END;
--
      /* �N�x�擾���� */
      BEGIN
        SELECT xxcso_util_common_pkg.get_business_year(iv_year_month)
        INTO   lv_fiscal_year
        FROM   DUAL;
      END;
--
      /* INSERT���� */
      INSERT INTO
        xxcso_dept_monthly_plans(
            dept_monthly_plan_id
           ,base_code
           ,year_month
           ,fiscal_year
           ,sales_plan_rel_div
           ,created_by
           ,creation_date
           ,last_updated_by
           ,last_update_date
           ,last_update_login)
      VALUES(
            ln_dept_monthly_plan_id
           ,iv_base_code
           ,iv_year_month
           ,lv_fiscal_year
           ,iv_sales_plan_rel_div
           ,cn_created_by
           ,cd_creation_date
           ,cn_last_updated_by
           ,cd_last_update_date
           ,cn_last_update_login
           );
    ELSE
      UPDATE xxcso_dept_monthly_plans
        SET
          sales_plan_rel_div       = iv_sales_plan_rel_div
         ,last_updated_by          = cn_last_updated_by
         ,last_update_date         = cd_last_update_date
         ,last_update_login        = cn_last_update_login
       WHERE dept_monthly_plan_id  = ln_dept_monthly_plan_id;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
  WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_dept_monthly_plans;
END xxcso_019003j_pkg;
/
