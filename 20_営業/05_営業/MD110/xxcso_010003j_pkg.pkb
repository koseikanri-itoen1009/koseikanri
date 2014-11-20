CREATE OR REPLACE PACKAGE BODY APPS.xxcso_010003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010003j_pkg(BODY)
 * Description      : 自動販売機設置契約情報登録更新_共通関数
 * MD.050/070       : 
 * Version          : 1.7
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  decode_bm_info            F    V      BM情報分岐取得
 *  get_base_leader_name      F    V      発行元所属長取得
 *  get_base_leader_pos_name  F    V      発行元所属長職位名取得
 *  chk_double_byte_kana      F    V      全角カナチェック（共通関数ラッピング）
 *  chk_tel_format            F    V      電話番号チェック（共通関数ラッピング）
 *  chk_duplicate_vendor_name F    V      送付先名重複チェック
 *  get_authority             F    V      権限判定関数
 *  chk_bfa_single_byte_kana  F    V      半角カナチェック（BFA関数ラッピング）
 *  decode_cont_manage_info   F    V      契約管理情報分岐取得
 *  get_sales_charge          F    V      販売手数料発生可否判別
 *  chk_double_byte           F    V      全角文字チェック（共通関数ラッピング）
 *  chk_single_byte_kana      F    V      半角カナチェック（共通関数ラッピング）
 *  chk_cooperate_wait        F    V      マスタ連携待ちチェック
 *  reflect_contract_status   P    -      契約書確定情報反映処理
 *  chk_validate_db           P    -      ＤＢ更新判定チェック
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   H.Ogawa          新規作成
 *  2009/02/16    1.0   N.Yanagitaira    [UT後修正]chk_bfa_single_byte_kana追加
 *  2009/02/17    1.1   N.Yanagitaira    [CT1-012]decode_cont_manage_info追加
 *  2009/02/23    1.1   N.Yanagitaira    [内部障害-028]全角カナチェック処理不正修正
 *  2009/03/12    1.1   N.Yanagitaira    [CT2-058]get_sales_charge追加
 *  2009/04/03    1.2   N.Yanagitaira    [ST障害T1_0223]chk_duplicate_vendor_name修正
 *  2009/04/27    1.3   N.Yanagitaira    [ST障害T1_0708]入力項目チェック処理統一修正
 *                                                      chk_double_byte
 *                                                      chk_single_byte_kana
 *  2009/05/01    1.4   T.Mori           [ST障害T1_0897]スキーマ名設定
 *  2009/06/05    1.5   N.Yanagitaira    [ST障害T1_1307]chk_single_byte_kana修正
 *  2009/09/09    1.6   Daisuke.Abe      統合テスト障害対応(0001323)
 *  2010/02/10    1.7   D.Abe            E_本稼動_01538対応
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_010003j_pkg';   -- パッケージ名
--
  /**********************************************************************************
   * Function Name    : decode_bm_info
   * Description      : BM情報分岐取得
   ***********************************************************************************/
  FUNCTION decode_bm_info(
    in_customer_id              NUMBER
   ,iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'decode_bm_info';
    cv_contract_status_input     CONSTANT VARCHAR2(1)     := '0';
    cv_cooperate_none            CONSTANT VARCHAR2(1)     := '0';
    cv_batch_proc_status_normal  CONSTANT VARCHAR2(1)     := '0';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    IF ( in_customer_id IS NULL ) THEN
--
      lv_return_value := iv_transaction_value;
--
    ELSE
--
      IF ( iv_contract_status = cv_contract_status_input ) THEN
--
        lv_return_value := iv_transaction_value;
--
      ELSE
--
        IF ( iv_cooperate_flag = cv_cooperate_none ) THEN
--
          lv_return_value := iv_transaction_value;
--
        ELSE
--
          lv_return_value := iv_master_value;
--
        END IF;
--
      END IF;
--
    END IF;
--
    RETURN lv_return_value;
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
  END decode_bm_info;
--
  /**********************************************************************************
   * Function Name    : get_base_leader_name
   * Description      : 発行元所属長取得
   ***********************************************************************************/
  FUNCTION get_base_leader_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_base_leader_name';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_leader_name               xxcso_employees_v2.full_name%TYPE;
--
  BEGIN
--
    BEGIN
--
      SELECT  xev.full_name
      INTO    lv_leader_name
      FROM    xxcso_employees_v2  xev
      WHERE   (
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_new = iv_base_code)
                AND
                (xev.position_code_new  = '002')
               )
               OR
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_old = iv_base_code)
                AND
                (xev.position_code_old  = '002')
               )
              )
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF ( lv_leader_name IS NULL ) THEN
--
      BEGIN
--
        SELECT  xev.full_name
        INTO    lv_leader_name
        FROM    xxcso_employees_v2  xev
        WHERE   (
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_new = iv_base_code)
                  AND
                  (xev.position_code_new  = '003')
                 )
                 OR
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_old = iv_base_code)
                  AND
                  (xev.position_code_old  = '003')
                 )
                )
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
    END IF;
--
    RETURN lv_leader_name;
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
--
  END get_base_leader_name;
--
  /**********************************************************************************
   * Function Name    : get_base_leader_pos_name
   * Description      : 発行元所属長職位名取得
   ***********************************************************************************/
  FUNCTION get_base_leader_pos_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_base_leader_pos_name';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_position_name             xxcso_employees_v2.position_name_new%TYPE;
--
  BEGIN
--
    BEGIN
--
      SELECT  xxcso_util_common_pkg.get_emp_parameter(
                xev.position_name_new
               ,xev.position_name_old
               ,xev.issue_date
               ,xxcso_util_common_pkg.get_online_sysdate
              )
      INTO    lv_position_name
      FROM    xxcso_employees_v2  xev
      WHERE   (
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_new = iv_base_code)
                AND
                (xev.position_code_new  = '002')
               )
               OR
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_old = iv_base_code)
                AND
                (xev.position_code_old  = '002')
               )
              )
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF ( lv_position_name IS NULL ) THEN
--
      BEGIN
--
        SELECT  xxcso_util_common_pkg.get_emp_parameter(
                  xev.position_name_new
                 ,xev.position_name_old
                 ,xev.issue_date
                 ,xxcso_util_common_pkg.get_online_sysdate
                )
        INTO    lv_position_name
        FROM    xxcso_employees_v2  xev
        WHERE   (
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_new = iv_base_code)
                  AND
                  (xev.position_code_new  = '003')
                 )
                 OR
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_old = iv_base_code)
                  AND
                  (xev.position_code_old  = '003')
                 )
                )
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
    END IF;
--
    RETURN lv_position_name;
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
--
  END get_base_leader_pos_name;
--
  /**********************************************************************************
   * Function Name    : chk_double_byte_kana
   * Description      : 全角カナチェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_double_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte_kana';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
    ln_length                    NUMBER;
--
  BEGIN
--
    lv_return_value := '1';
    ln_length := LENGTH(iv_value);
--
    << dobule_byte_check_loop >>
    FOR idx IN 1..ln_length
    LOOP
--
      lb_return_value := xxccp_common_pkg.chk_double_byte_kana(SUBSTR(iv_value, idx, 1));
--
      IF NOT ( lb_return_value ) THEN
--
        lv_return_value := '0';
        EXIT dobule_byte_check_loop;
--
      END IF;
--
    END LOOP dobule_byte_check_loop;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_double_byte_kana;
--
  /**********************************************************************************
   * Function Name    : chk_tel_format
   * Description      : 電話番号チェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_tel_format(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_tel_format';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lb_return_value := xxccp_common_pkg.chk_tel_format(iv_value);
--
    IF ( lb_return_value ) THEN
--
      lv_return_value := '1';
--
    ELSE
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_tel_format;
--
  /**********************************************************************************
   * Function Name    : chk_duplicate_vendor_name
   * Description      : 送付先名重複チェック
   ***********************************************************************************/
-- 20090408_N.Yanagitaira T1_0364 Mod START
--  FUNCTION chk_duplicate_vendor_name(
--    iv_dm1_vendor_name             IN  VARCHAR2
--   ,iv_dm2_vendor_name             IN  VARCHAR2
--   ,iv_dm3_vendor_name             IN  VARCHAR2
--   ,in_contract_management_id      IN  NUMBER
--   ,in_dm1_supplier_id             IN  NUMBER
--   ,in_dm2_supplier_id             IN  NUMBER
--   ,in_dm3_supplier_id             IN  NUMBER
--
--  ) RETURN VARCHAR2
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_duplicate_vendor_name';
--    -- ===============================
--    -- ローカル変数
--    -- ===============================
--    lv_return_value              VARCHAR2(1);
--    ln_cnt                       NUMBER;
----
--  BEGIN
----
--    lv_return_value := 0;
----
--    ln_cnt := 0;
----
--    BEGIN
----
--      -- 送付先テーブル重複チェック
--      SELECT    COUNT(delivery_id)
--      INTO      ln_cnt
--      FROM      xxcso_destinations xd
--      WHERE     xd.payment_name IN (iv_dm1_vendor_name, iv_dm2_vendor_name, iv_dm3_vendor_name)
---- 20090403_N.Yanagitaira T1_0223 Mod START
----        AND     xd.supplier_id NOT IN (in_dm1_supplier_id, in_dm2_supplier_id, in_dm3_supplier_id)
----        AND     (
----                  (
----                    ( in_contract_management_id IS NOT NULL ) AND (xd.contract_management_id <> in_contract_management_id)
----                  )
----                  OR
----                  (
----                    ( in_contract_management_id IS NULL) AND (1 = 1)
----                  )
----                )
--        AND     NOT EXISTS
--                (
--                  SELECT  1
--                  FROM    xxcso_destinations xd2
--                  WHERE   xd2.contract_management_id = xd.contract_management_id
--                    AND   xd2.contract_management_id = NVL(in_contract_management_id, fnd_api.g_miss_num)
--                )
--        AND     NOT EXISTS
--                (
--                  SELECT  1
--                  FROM    xxcso_destinations xd2
--                  WHERE   xd2.contract_management_id = xd.contract_management_id
--                    AND   xd2.supplier_id IN
--                            (
--                              NVL(in_dm1_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm2_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm3_supplier_id, fnd_api.g_miss_num)
--                            )
--                )
---- 20090403_N.Yanagitaira T1_0223 Mod END
--        AND      ROWNUM = 1
--      ;
----
--      IF ( ln_cnt <> 0) THEN
--        lv_return_value := '1';
--        RETURN lv_return_value;
--      END IF;
----
--    END;
----
--    ln_cnt := 0;
----
--    BEGIN
----
--      -- 仕入先マスタ重複チェック
--      SELECT    COUNT(vendor_id)
--      INTO      ln_cnt
--      FROM      po_vendors pv
--      WHERE     pv.vendor_name IN (iv_dm1_vendor_name, iv_dm2_vendor_name, iv_dm3_vendor_name)
---- 20090403_N.Yanagitaira T1_0223 Mod START
----        AND     pv.vendor_id NOT IN (in_dm1_supplier_id, in_dm2_supplier_id, in_dm3_supplier_id)
--        AND     NOT EXISTS
--                (
--                  SELECT  1
--                  FROM    po_vendors pv2
--                  WHERE   pv2.vendor_id = pv.vendor_id
--                    AND   pv2.vendor_id IN
--                            (
--                              NVL(in_dm1_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm2_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm3_supplier_id, fnd_api.g_miss_num)
--                            )
--                )
---- 20090403_N.Yanagitaira T1_0223 Mod END
--        AND     ROWNUM = 1
--      ;
----
--      IF ( ln_cnt <> 0) THEN
--        lv_return_value := '1';
--        RETURN lv_return_value;
--      END IF;
----
--    END;
----
--    RETURN lv_return_value;
----
  PROCEDURE chk_duplicate_vendor_name(
    iv_bm1_vendor_name             IN  VARCHAR2
   ,iv_bm2_vendor_name             IN  VARCHAR2
   ,iv_bm3_vendor_name             IN  VARCHAR2
   ,in_bm1_supplier_id             IN  NUMBER
   ,in_bm2_supplier_id             IN  NUMBER
   ,in_bm3_supplier_id             IN  NUMBER
   ,iv_operation_mode              IN  VARCHAR2
   ,on_bm1_dup_count               OUT NUMBER
   ,on_bm2_dup_count               OUT NUMBER
   ,on_bm3_dup_count               OUT NUMBER
   ,ov_bm1_contract_number         OUT VARCHAR2
   ,ov_bm2_contract_number         OUT VARCHAR2
   ,ov_bm3_contract_number         OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_duplicate_vendor_name';
    cv_operation_apply           CONSTANT VARCHAR2(30)    := 'APPLY';
    cv_operation_submit          CONSTANT VARCHAR2(30)    := 'SUBMIT';
    cv_contract_status_submit    CONSTANT VARCHAR2(1)     := '1';
    cv_cooperate_none            CONSTANT VARCHAR2(1)     := '0';
    cv_err_vendor_duplicate      CONSTANT VARCHAR2(1)     := '1';
    cv_err_cooperate             CONSTANT VARCHAR2(1)     := '2';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_bm1_dup_count             NUMBER;
    ln_bm2_dup_count             NUMBER;
    ln_bm3_dup_count             NUMBER;
    lv_bm1_contract_number       xxcso_contract_managements.contract_number%TYPE;
    lv_bm2_contract_number       xxcso_contract_managements.contract_number%TYPE;
    lv_bm3_contract_number       xxcso_contract_managements.contract_number%TYPE;
--
  BEGIN
--
    -- 初期化
    ln_bm1_dup_count       := 0;
    ln_bm2_dup_count       := 0;
    ln_bm3_dup_count       := 0;
    lv_bm1_contract_number := NULL;
    lv_bm2_contract_number := NULL;
    lv_bm3_contract_number := NULL;
    on_bm1_dup_count       := 0;
    on_bm2_dup_count       := 0;
    on_bm3_dup_count       := 0;
    ov_bm1_contract_number := NULL;
    ov_bm2_contract_number := NULL;
    ov_bm3_contract_number := NULL;
    ov_retcode             := xxcso_common_pkg.gv_status_normal;
    ov_errbuf              := NULL;
    ov_errmsg              := NULL;
--
    BEGIN
--
      -- 仕入先マスタ重複チェック
      SELECT   (
                 SELECT    COUNT('X')
                 FROM      po_vendors pv
                 WHERE     pv.vendor_name = iv_bm1_vendor_name
                 AND       NOT EXISTS
                           (
                             SELECT  1
                             FROM    po_vendors pv1
                             WHERE   pv1.vendor_id = pv.vendor_id
                               AND   pv1.vendor_id = NVL(in_bm1_supplier_id, fnd_api.g_miss_num)
                           )
                 AND       ROWNUM = 1
               ) AS bm1_count
              ,(
                 SELECT    COUNT('X')
                 FROM      po_vendors pv
                 WHERE     pv.vendor_name = iv_bm2_vendor_name
                 AND       NOT EXISTS
                           (
                             SELECT  1
                             FROM    po_vendors pv2
                             WHERE   pv2.vendor_id = pv.vendor_id
                               AND   pv2.vendor_id = NVL(in_bm2_supplier_id, fnd_api.g_miss_num)
                           )
                 AND       ROWNUM = 1
               ) AS bm2_count
              ,(
                 SELECT    COUNT('X')
                 FROM      po_vendors pv
                 WHERE     pv.vendor_name = iv_bm3_vendor_name
                 AND       NOT EXISTS
                           (
                             SELECT  1
                             FROM    po_vendors pv3
                             WHERE   pv3.vendor_id = pv.vendor_id
                               AND   pv3.vendor_id = NVL(in_bm3_supplier_id, fnd_api.g_miss_num)
                           )
                 AND       ROWNUM = 1
               ) AS bm3_count
      INTO     ln_bm1_dup_count
              ,ln_bm2_dup_count
              ,ln_bm3_dup_count
      FROM     DUAL
      ;
    END;
--
    -- 重複チェック判定 BM1～3に1件でも存在する場合はエラーとする
    IF ( ( ln_bm1_dup_count <> 0) OR ( ln_bm2_dup_count <> 0) OR ( ln_bm3_dup_count <> 0) ) THEN
        on_bm1_dup_count := ln_bm1_dup_count;
        on_bm2_dup_count := ln_bm2_dup_count;
        on_bm3_dup_count := ln_bm3_dup_count;
        ov_retcode       := cv_err_vendor_duplicate;
      RETURN;
    END IF;
--
    -- 確定ボタンの場合のみチェック
    IF ( iv_operation_mode = cv_operation_submit ) THEN
--
      ln_bm1_dup_count := 0;
      ln_bm2_dup_count := 0;
      ln_bm3_dup_count := 0;
--
      BEGIN
--
        -- 送付先テーブル重複チェック
        SELECT    (
                    SELECT    xcm.contract_number
                    FROM      xxcso_contract_managements xcm
                             ,xxcso_destinations xd
                    WHERE     xcm.status                 = cv_contract_status_submit
                    AND       xcm.cooperate_flag         = cv_cooperate_none
                    AND       xd.contract_management_id  = xcm.contract_management_id
                    AND       xd.payment_name            = iv_bm1_vendor_name
                    AND       NOT EXISTS
                              (
                                SELECT  1
                                FROM    xxcso_destinations xd1
                                WHERE   xd1.contract_management_id = xd.contract_management_id
                                  AND   xd1.supplier_id            = NVL(in_bm1_supplier_id, fnd_api.g_miss_num)
                              )
                    AND       ROWNUM = 1
                  ) AS bm1_dup_number
                 ,(
                    SELECT    xcm.contract_number
                    FROM      xxcso_contract_managements xcm
                             ,xxcso_destinations xd
                    WHERE     xcm.status                 = cv_contract_status_submit
                    AND       xcm.cooperate_flag         = cv_cooperate_none
                    AND       xd.contract_management_id  = xcm.contract_management_id
                    AND       xd.payment_name            = iv_bm2_vendor_name
                    AND       NOT EXISTS
                              (
                                SELECT  1
                                FROM    xxcso_destinations xd2
                                WHERE   xd2.contract_management_id = xd.contract_management_id
                                  AND   xd2.supplier_id            = NVL(in_bm2_supplier_id, fnd_api.g_miss_num)
                              )
                    AND       ROWNUM = 1
                  ) AS bm2_dup_number
                 ,(
                    SELECT    xcm.contract_number
                    FROM      xxcso_contract_managements xcm
                             ,xxcso_destinations xd
                    WHERE     xcm.status                 = cv_contract_status_submit
                    AND       xcm.cooperate_flag         = cv_cooperate_none
                    AND       xd.contract_management_id  = xcm.contract_management_id
                    AND       xd.payment_name            = iv_bm3_vendor_name
                    AND       NOT EXISTS
                              (
                                SELECT  1
                                FROM    xxcso_destinations xd3
                                WHERE   xd3.contract_management_id = xd.contract_management_id
                                  AND   xd3.supplier_id            = NVL(in_bm3_supplier_id, fnd_api.g_miss_num)
                              )
                    AND       ROWNUM = 1
                  ) AS bm3_dup_number
        INTO      lv_bm1_contract_number
                 ,lv_bm2_contract_number
                 ,lv_bm3_contract_number
        FROM      DUAL
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm1_contract_number := NULL;
          lv_bm2_contract_number := NULL;
          lv_bm3_contract_number := NULL;
      END;
--
      -- 画面でのBM1～3判定のため件数の設定
      IF ( lv_bm1_contract_number IS NOT NULL) THEN
        ln_bm1_dup_count := 1;
      END IF;
      IF ( lv_bm2_contract_number IS NOT NULL) THEN
        ln_bm2_dup_count := 1;
      END IF;
      IF ( lv_bm3_contract_number IS NOT NULL) THEN
        ln_bm3_dup_count := 1;
      END IF;
--
      -- 重複チェック判定 BM1～3に1件でも存在する場合はエラーとする
      IF (    ( lv_bm1_contract_number IS NOT NULL )
           OR ( lv_bm2_contract_number IS NOT NULL )
           OR ( lv_bm3_contract_number IS NOT NULL )
         ) THEN
         on_bm1_dup_count         := ln_bm1_dup_count;
         on_bm2_dup_count         := ln_bm2_dup_count;
         on_bm3_dup_count         := ln_bm3_dup_count;
         ov_bm1_contract_number   := lv_bm1_contract_number;
         ov_bm2_contract_number   := lv_bm2_contract_number;
         ov_bm3_contract_number   := lv_bm3_contract_number;
         ov_retcode               := cv_err_cooperate;
        RETURN;
      END IF;
--
    END IF;
--
-- 20090408_N.Yanagitaira T1_0364 Mod End
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_duplicate_vendor_name;
--
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
    lv_login_user_id           VARCHAR2(30);        -- ログインユーザー
    lv_sales_employee_number   VARCHAR2(30);        -- 売上担当営業員 従業員番号
    lv_base_code               VARCHAR2(150);       -- 売上担当営業員 勤務地拠点コード
    lv_leader_employee_number  VARCHAR2(30);        -- 売上担当営業員上長 従業員番号
    lv_employee_number         VARCHAR2(30);        -- 従業員番号
    ln_sp_decision_header_id   NUMBER;              -- SP専決ヘッダID
    lv_return_cd               VARCHAR2(1) := '0';  -- リターンコード(0:権限無し, 1:営業員権限, 2:拠点長権限)
  BEGIN
--
    -- ログインユーザーのユーザーIDを取得
    SELECT FND_GLOBAL.USER_ID
    INTO   lv_login_user_id
    FROM   DUAL;
--
    -- ************************
    -- 売上担当営業員取得
    -- ************************
    BEGIN
      SELECT   xev.employee_number
      INTO     lv_sales_employee_number
      FROM     xxcso_sp_decision_headers xsdh
              ,xxcso_sp_decision_custs xsdc
              ,xxcso_cust_accounts_v xcav
              ,xxcso_cust_resources_v2 xcrv
              ,xxcso_employees_v2 xev
      WHERE    xsdh.sp_decision_header_id      = iv_sp_decision_header_id
        AND    xsdc.sp_decision_customer_class = '1'
        AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
        AND    xcav.cust_account_id            = xsdc.customer_id
        AND    xcrv.cust_account_id            = xcav.cust_account_id
        AND    xev.employee_number             = xcrv.employee_number
        ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lv_sales_employee_number := NULL;
    WHEN TOO_MANY_ROWS THEN
        lv_sales_employee_number := NULL;
    END;
--
    -- ************************
    -- 売上担当営業員チェック
    -- ************************
    BEGIN
      SELECT   xev.employee_number
      INTO     lv_employee_number
      FROM     xxcso_employees_v2 xev
      WHERE    xev.user_id         = lv_login_user_id
        AND    xev.employee_number = lv_sales_employee_number
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_employee_number := NULL;
    END;
--
    -- *******************************************
    -- 獲得営業員チェック
    -- *******************************************
    BEGIN
      SELECT   xsdh.sp_decision_header_id
      INTO     ln_sp_decision_header_id
      FROM     xxcso_sp_decision_headers xsdh
              ,xxcso_sp_decision_custs xsdc
              ,xxcso_employees_v2 xev
              ,xxcso_cust_accounts_v xcav
      WHERE    xsdh.sp_decision_header_id      = iv_sp_decision_header_id
        AND    xev.user_id                     = lv_login_user_id
        AND    xsdc.sp_decision_customer_class = '1'
        AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
        AND    xcav.cust_account_id            = xsdc.customer_id
        AND    xcav.cnvs_business_person       = xev.employee_number
        ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       ln_sp_decision_header_id := NULL;
    END;
--
    -- ログインユーザーの担当営業員、獲得営業員チェック
    IF ( ln_sp_decision_header_id IS NOT NULL ) OR ( lv_employee_number IS NOT NULL ) THEN
       lv_return_cd := '1';
    END IF;
--
    -- 売上担当営業員が設定されている場合のみ上長チェック実施
    IF ( lv_sales_employee_number IS NOT NULL ) THEN
--
      -- ************************
      -- 担当営業員の上長チェック
      -- ************************
      BEGIN
        -- ログインユーザーの上長チェック、拠点取得
        SELECT   (
                   CASE
                     WHEN xev.issue_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                       xev.work_base_code_new
                     WHEN xev.issue_date > TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                       xev.work_base_code_old
                   END
                 ) AS base_code
        INTO     lv_base_code
        /* 2009.09.09 D.Abe 0001323対応 START */
        --FROM     xxcso_employees_v xev
        FROM     xxcso_employees_v2 xev
        /* 2009.09.09 D.Abe 0001323対応 END */
                ,fnd_lookup_values_vl flvv
        WHERE    flvv.lookup_type      = cv_lookup_type
          AND    flvv.attribute2       = 'Y'
          AND    NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND    NVL(flvv.end_date_active,   TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND    xev.user_id           = lv_login_user_id
          AND    (
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
                 )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN lv_return_cd;
      END;
--
      -- 拠点コード取得時のみ売上担当営業員の上長チェック実施
      BEGIN
        SELECT   xev.employee_number
        INTO     lv_employee_number
        /* 2009.09.09 D.Abe 0001323対応 START */
        --FROM     xxcso_employees_v xev
        FROM     xxcso_employees_v2 xev
        /* 2009.09.09 D.Abe 0001323対応 END */
        WHERE    xev.employee_number   = lv_sales_employee_number
          AND    (
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
                 )
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN lv_return_cd;
      END;
--
      -- 上長と判断できた場合
      IF (lv_employee_number IS NOT NULL) THEN
        lv_return_cd := '2';
      END IF;
--
    END IF;
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
--
  /**********************************************************************************
   * Function Name    : chk_bfa_single_byte_kana
   * Description      : 半角カナチェック（BFA関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_bfa_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_bfa_single_byte_kana';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lb_return_value := xx03_chk_kana_pkg.chk_kana(iv_value);
--
    IF ( lb_return_value ) THEN
--
      lv_return_value := '1';
--
    ELSE
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_bfa_single_byte_kana;
--
  /**********************************************************************************
   * Function Name    : decode_cont_manage_info
   * Description      : 契約管理情報分岐取得
   ***********************************************************************************/
  FUNCTION decode_cont_manage_info(
    iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'decode_cont_manage_info';
    cv_contract_status_input     CONSTANT VARCHAR2(1)     := '0';
    cv_cooperate_none            CONSTANT VARCHAR2(1)     := '0';
    cv_batch_proc_status_normal  CONSTANT VARCHAR2(1)     := '0';
    cv_batch_proc_status_link    CONSTANT VARCHAR2(1)     := '1';
    cv_batch_proc_status_error   CONSTANT VARCHAR2(1)     := '2';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    IF ( iv_contract_status = cv_contract_status_input ) THEN
--
      lv_return_value := iv_transaction_value;
--
    ELSE
--
      IF ( iv_cooperate_flag = cv_cooperate_none ) THEN
--
        lv_return_value := iv_transaction_value;
--
      ELSE
--
        IF ( iv_batch_proc_status = cv_batch_proc_status_link ) THEN
--
          lv_return_value := iv_master_value;
--
        ELSE
--
          lv_return_value := iv_transaction_value;
--
        END IF;
--
      END IF;
--
    END IF;
--
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END decode_cont_manage_info;
--
  /**********************************************************************************
   * Function Name    : get_sales_charge
   * Description      : 販売手数料発生可否判別
   ***********************************************************************************/
  FUNCTION get_sales_charge(
    in_sp_decision_header_id    NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_sales_charge';
    cv_electricity_type_flat     CONSTANT VARCHAR2(1)     := '1';
    cv_electricity_type_change   CONSTANT VARCHAR2(1)     := '2';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_electricity_type          xxcso_sp_decision_headers.electricity_type%TYPE;
    ln_count                     NUMBER;
--
  BEGIN
--
    -- リターン値を初期化
    lv_return_value := '0';
--
    BEGIN
      -- 電気代区分の取得
      SELECT xsdh.electricity_type
      INTO   lv_electricity_type
      FROM   xxcso_sp_decision_headers xsdh
      WHERE  xsdh.sp_decision_header_id = in_sp_decision_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_return_value := '1';
    END;
--
    -- 電気代区分=定額の場合は販売手数料が発生
    IF ( lv_electricity_type = cv_electricity_type_flat ) THEN
       lv_return_value := '1';
    END IF;
--
    -- BM1～BM3の率・金額が入力されているか
    BEGIN
      SELECT COUNT('x')
      INTO   ln_count
      FROM   xxcso_sp_decision_lines xsdl
      WHERE  xsdl.sp_decision_header_id = in_sp_decision_header_id
      AND    (
               (NVL(xsdl.bm1_bm_rate, 0) <> 0)
               OR
               (NVL(xsdl.bm2_bm_rate, 0) <> 0)
               OR
               (NVL(xsdl.bm3_bm_rate, 0) <> 0)
               OR
               (NVL(xsdl.bm1_bm_amount, 0) <> 0)
               OR
               (NVL(xsdl.bm2_bm_amount, 0) <> 0)
               OR
               (NVL(xsdl.bm3_bm_amount, 0) <> 0)
             )
      AND    ROWNUM = 1
      ;
    END;
--
    -- 1件でも入力されている場合は販売手数料発生
    IF ( ln_count > 0 ) THEN
       lv_return_value := '1';
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_sales_charge;
--
-- 20090427_N.Yanagitaira T1_0708 Add START
  /**********************************************************************************
   * Function Name    : chk_double_byte
   * Description      : 全角文字チェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_double_byte(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
    lb_return_value := xxccp_common_pkg.chk_double_byte(iv_value);
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_double_byte;
--
  /**********************************************************************************
   * Function Name    : chk_single_byte_kana
   * Description      : 半角カナチェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_single_byte_kana';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
-- 20090605_N.Yanagitaira T1_1307 Mod START
--    lb_return_value := xxccp_common_pkg.chk_single_byte_kana(iv_value);
    -- 共通関数の半角文字チェックを行う
    lb_return_value := xxccp_common_pkg.chk_single_byte(iv_value);
-- 20090605_N.Yanagitaira T1_1307 Mod END
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_single_byte_kana;
--
-- 20090427_N.Yanagitaira T1_0708 Add END
/* 2010.02.10 D.Abe E_本稼動_01538対応 START */
   /**********************************************************************************
   * Function Name    : chk_cooperate_wait
   * Description      : マスタ連携待ちチェック
   ***********************************************************************************/
  FUNCTION chk_cooperate_wait(
    iv_account_number             IN  VARCHAR2         -- 顧客コード
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_cooperate_wait';
    cv_contract_status_submit    CONSTANT VARCHAR2(1)     := '1';  -- ステータス＝確定済
    cv_un_cooperate              CONSTANT VARCHAR2(1)     := '0';  -- マスタ連携フラグ＝未連携
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_contract_number       xxcso_contract_managements.contract_number%TYPE;
  BEGIN
--
    lv_contract_number := NULL;

    -- マスタ連携待ちのチェック
    BEGIN
      -- マスタ連携待ちの契約書を取得
      SELECT xcm1.contract_number
      INTO   lv_contract_number
      FROM   xxcso_contract_managements xcm1
      WHERE  xcm1.contract_management_id IN
            (
             SELECT MAX(xcm2.contract_management_id)
             FROM   xxcso.xxcso_contract_managements xcm2
             WHERE  xcm2.install_account_number = iv_account_number --顧客コード
             AND    xcm2.status            = cv_contract_status_submit
             AND    xcm2.cooperate_flag    = cv_un_cooperate
             AND    xcm2.batch_proc_status IS NULL
            )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_contract_number := NULL;
    END;
    --
    RETURN lv_contract_number;
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
  END chk_cooperate_wait;
--
   /**********************************************************************************
   * Function Name    : reflect_contract_status
   * Description      : 契約書確定情報反映処理
   ***********************************************************************************/
  PROCEDURE reflect_contract_status(
    iv_contract_management_id     IN  VARCHAR2         -- 契約書ID
   ,iv_account_number             IN  VARCHAR2         -- 顧客コード
   ,iv_status                     IN  VARCHAR2         -- ステータス
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'reflect_contract_status';
    cv_contract_status_apply  CONSTANT VARCHAR2(1)   := '0'; -- ステータス＝入力中
    cv_contract_status_submit CONSTANT VARCHAR2(1)   := '1'; -- ステータス＝確定済
    cv_contract_status_cancel CONSTANT VARCHAR2(1)   := '9'; -- ステータス＝取消済
    cv_un_cooperate           CONSTANT VARCHAR2(1)   := '0'; -- マスタ連携フラグ＝未連携
    cv_finish_cooperate       CONSTANT VARCHAR2(1)   := '1'; -- マスタ連携フラグ＝連携済
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_contract_number       xxcso_contract_managements.contract_number%TYPE;
    ln_count                 NUMBER;
    ld_sysdate       DATE;
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ld_sysdate := SYSDATE;

    -- 確定済みの場合
    IF (iv_status = cv_contract_status_submit) THEN
      -- マスタ連携待ちの契約書を更新
      UPDATE  xxcso_contract_managements xcm
      SET     xcm.status            = cv_contract_status_cancel
             ,xcm.last_updated_by   = fnd_global.user_id
             ,xcm.last_update_date  = ld_sysdate
             ,xcm.last_update_login = fnd_global.login_id
      WHERE  xcm.install_account_number = iv_account_number --顧客コード
      AND    xcm.status             = cv_contract_status_submit
      AND    xcm.cooperate_flag     = cv_un_cooperate
      AND    xcm.batch_proc_status IS NULL
      AND    xcm.contract_management_id <> TO_NUMBER(iv_contract_management_id)
      ;
      
      -- 作成中の契約書を更新
      UPDATE  xxcso_contract_managements xcm
      SET     xcm.status            = cv_contract_status_cancel
             ,xcm.last_updated_by   = fnd_global.user_id
             ,xcm.last_update_date  = ld_sysdate
             ,xcm.last_update_login = fnd_global.login_id
      WHERE  xcm.install_account_number = iv_account_number --顧客コード
      AND    xcm.status             = cv_contract_status_apply
      ;
    
    END IF;

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
  END reflect_contract_status;
--
  /**********************************************************************************
   * Function Name    : chk_validate_db
   * Description      : ＤＢ更新判定チェック
   ***********************************************************************************/
  PROCEDURE chk_validate_db(
    iv_contract_number            IN  VARCHAR2         -- 契約書番号
   ,id_last_update_date           IN  DATE
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_validate_db';

    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_last_update_date          DATE;
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    lb_return_value := FALSE;

    SELECT  xcm.last_update_date
    INTO    ld_last_update_date
    FROM    xxcso_contract_managements  xcm
    WHERE   xcm.contract_number = iv_contract_number
    ;

    IF ( id_last_update_date < ld_last_update_date ) THEN
      lb_return_value := TRUE;
    END IF;

    IF (lb_return_value) THEN
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
    --
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_validate_db;
--

/* 2010.02.10 D.Abe E_本稼動_01538対応 END */
--
END xxcso_010003j_pkg;
/
