CREATE OR REPLACE PACKAGE BODY apps.xxcso_010001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Function Name    : xxcso_010001j_pkg(BODY)
 * Description      : 権限判定関数(XXCSOユーティリティ）
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_authority               F    V     権限判定関数
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   R.Oikawa          新規作成
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_y                CONSTANT VARCHAR2(1)   := 'Y';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_010001j_pkg';   -- パッケージ名
   /**********************************************************************************
   * Function Name    : get_Authority
   * Description      : 権限判定関数
   ***********************************************************************************/
  FUNCTION get_authority(
    iv_sp_decision_header_id      IN  NUMBER           -- SP専決ヘッダID
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_authority';
    cv_lookup_type               CONSTANT VARCHAR2(100)   := 'XXCSO1_POSITION_SECURITY';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_sales_person_cd         VARCHAR2(5);         -- 担当営業員
    ln_sp_decision_header_id   NUMBER;              -- SP専決ヘッダID
    lv_employee_number         VARCHAR2(30);        -- 従業員番号
    lv_return_cd               VARCHAR2(1) := '0';  -- リターンコード(0:権限無し,1:権限有り)
    lv_base_code               VARCHAR2(150);       -- 勤務地拠点コード
    lv_login_user_id           VARCHAR2(30);        -- ログインユーザー
  BEGIN
--
    /*ログインユーザーIDを取得*/
    SELECT FND_GLOBAL.USER_ID
    INTO   lv_login_user_id
    FROM   DUAL;
--
    /*担当営業員取得*/
    BEGIN
--      SELECT xxcso_route_common_pkg.get_sales_person_cd(xcav.account_number,sysdate)
      SELECT xcrv.employee_number
      INTO   lv_sales_person_cd
      FROM   xxcso_sp_decision_headers xsdh
            ,xxcso_sp_decision_custs xsdc
            ,xxcso_cust_accounts_v xcav
            ,xxcso_cust_resources_v2 xcrv
      WHERE  xsdh.sp_decision_header_id = iv_sp_decision_header_id
        AND  xsdc.sp_decision_customer_class = '1'
        AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
        AND  xcav.cust_account_id       = xsdc.customer_id
        AND  xcrv.cust_account_id       = xcav.cust_account_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lv_sales_person_cd := NULL;
    WHEN TOO_MANY_ROWS THEN
        lv_sales_person_cd := NULL;
    END;
--
   /*獲得営業員チェック*/
    BEGIN
      SELECT xsdh.sp_decision_header_id
      INTO   ln_sp_decision_header_id
      FROM   xxcso_sp_decision_headers xsdh
            ,xxcso_sp_decision_custs xsdc
            ,xxcso_employees_v2 xev
            ,xxcso_cust_accounts_v xcav
      WHERE  xsdh.sp_decision_header_id = iv_sp_decision_header_id
        AND  xev.user_id                = lv_login_user_id
        AND  xsdc.sp_decision_customer_class = '1'
        AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
        AND  xcav.cust_account_id       = xsdc.customer_id
        AND  xcav.cnvs_business_person  = xev.employee_number;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       ln_sp_decision_header_id := NULL;
--
       /*担当営業員チェック*/
       BEGIN
         SELECT xev.employee_number
         INTO   lv_employee_number
         FROM   xxcso_employees_v2 xev
         WHERE  xev.user_id         = lv_login_user_id
           AND  xev.employee_number = lv_sales_person_cd;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          lv_employee_number := NULL;
       END;
    END;
--
    IF ln_sp_decision_header_id IS NOT NULL
    OR lv_employee_number IS NOT NULL THEN
       lv_return_cd := '1';
--
    ELSE
     /*担当営業員の上長チェック*/
     BEGIN
        SELECT CASE
                 WHEN xev.issue_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                    xev.work_base_code_new
                 WHEN xev.issue_date > TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                    xev.work_base_code_old
               END
        INTO   lv_base_code
        FROM   xxcso_employees_v xev
              ,fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type      = cv_lookup_type
          AND  flvv.attribute2       = gv_y
          AND  NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND  NVL(flvv.end_date_active,   TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND  xev.user_id           = lv_login_user_id
          AND  (
                (
                 xev.issue_date        <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                 AND
                 xev.position_code_new = flvv.lookup_code
                )
                OR
                (
                 xev.issue_date        > TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                 AND
                 xev.position_code_old = flvv.lookup_code
                )
               );
        BEGIN
           SELECT xev.employee_number
           INTO   lv_employee_number
           FROM   xxcso_employees_v xev
           WHERE  xev.employee_number   = lv_sales_person_cd
             AND  (
                   (
                    xev.issue_date        <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                    AND
                    xev.work_base_code_new = lv_base_code
                   )
                   OR
                   (
                    xev.issue_date        > TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                    AND
                    xev.work_base_code_old = lv_base_code
                   )
                  );
           /*上長と判断できた場合*/
           lv_return_cd := '1';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_return_cd := '0';
        END;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
       lv_return_cd := '0';
     END;
--
    END IF;
--
--lv_return_cd := '1';  -- テスト
--
    RETURN lv_return_cd;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
  WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
--
  END get_authority;
END xxcso_010001j_pkg;
/
