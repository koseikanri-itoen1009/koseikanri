CREATE OR REPLACE PACKAGE BODY XXCFO006A01P1
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name    : XXCFO006A01P1(body)
 * Description     : APWIセキュリティ
 * MD.050          : MD050_CFO_006_A01_APWIセキュリティ
 * MD.070          : MD050_CFO_006_A01_APWIセキュリティ
 * Version         : 1.1
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  get_policy_condition      F    VAR    WHERE句（所属部門権限判定によるセキュリティ設定）
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05   1.0    SCS 嵐田 勇人    初回作成
 *  2015-12-02   1.1    SCSK小路 恭弘    E_本稼動_13393対応
 *  2016-01-26   1.2    SCSK小路 恭弘    E_本稼動_13393対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
--
--
--################################  固定部 END   ##################################
--
  /**********************************************************************************
   * Function Name    : get_policy_condition
   * Description      : ログインユーザ所属部門取得関数
   ***********************************************************************************/
  FUNCTION get_policy_condition(
    p1 IN VARCHAR2
   ,p2 IN VARCHAR2)
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'XXCFO006A01P1.get_policy_condition';     -- プログラム名
    cv_profile_user_id  CONSTANT VARCHAR2(7) := 'USER_ID' ;                                 -- ユーザーID
    cn_security_0       CONSTANT NUMBER(2) := 0 ;                                           -- 拠点・部門
    cn_security_1       CONSTANT NUMBER(2) := 1 ;                                           -- 財務
    cn_security_2       CONSTANT NUMBER(2) := 2 ;                                           -- 購買
    cn_security_99      CONSTANT NUMBER(2) := 99 ;                                          -- ログインユーザー対象なし
-- 2015.12.02 Ver1.1 Add Start
    cn_security_3       CONSTANT NUMBER(2) := 3 ;                                           -- 損益照会/経費精算発生事由データ出力
    cn_appli_id_101     CONSTANT NUMBER(3) := 101 ;                                         -- アプリケーションID:101
-- 2016.01.26 Ver1.2 Add Start
    cn_program_id       CONSTANT NUMBER    := fnd_global.conc_program_id;                   -- コンカレントプログラムID
    cn_prog_appl_id     CONSTANT NUMBER    := fnd_global.prog_appl_id;                      -- コンカレント・プログラム・アプリケーションID
    cv_conc_name        CONSTANT VARCHAR2(12) := 'XXCCP007A08C';                            -- 経費精算発生事由データ出力
-- 2016.01.26 Ver1.2 Add End
    cv_dept_user        CONSTANT VARCHAR2(13) := 'XXCFO%DPT_USR';                           -- 職責：損益照会
    cv_profile_resp_id  CONSTANT VARCHAR2(7)  := 'RESP_ID';                                 -- 職責ID
    cv_xx03_department  CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT';                         -- 部門
-- 2015.12.02 Ver1.1 Add End
    cv_yes_no_y         CONSTANT VARCHAR2(1) := 'Y' ;                                       -- Y
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_where            VARCHAR2(4000) ;                        -- 戻り値用WHERE句
    ln_security         NUMBER(2) ;                             -- 0:拠点・部門/1:財務/2:購買/99:ログインユーザー対象なし
    lv_papf_dff28       PER_ALL_PEOPLE_F.ATTRIBUTE28%TYPE ;     -- ログインユーザーに紐付く所属部門
    ln_set_of_books_id  AP_INVOICES_ALL.SET_OF_BOOKS_ID%TYPE ;  -- 会計帳簿ID
    ln_org_id           AP_INVOICES_ALL.ORG_ID%TYPE ;           -- 組織ID
-- 2015.12.02 Ver1.1 Add Start
    lt_resp_id          fnd_responsibility.responsibility_key%TYPE ; -- 職責ID
-- 2015.12.02 Ver1.1 Add End
-- 2016.01.26 Ver1.2 Add Start
    lt_program_id       fnd_concurrent_programs.concurrent_program_id%TYPE ; -- コンカレントプログラムID
-- 2016.01.26 Ver1.2 Add End
--
  BEGIN
--
    -- ====================================================
    -- ログインユーザー部門設定判定
    -- ===================================================
--
    -- 所属部門を取得
    BEGIN
      SELECT cn_security_0                              cn_security_0,          -- 拠点・部門
             ppf.attribute28                            attribute28,            -- 所属部門
             fnd_profile.value( 'GL_SET_OF_BKS_ID' )    gl_set_of_bks_id,       -- 会計帳簿ID
             fnd_profile.value( 'ORG_ID' )              org_id                 -- 組織ID
      INTO   ln_security,
             lv_papf_dff28,
             ln_set_of_books_id,
             ln_org_id
      FROM   per_all_people_f ppf,
             fnd_user fu
      WHERE  fu.employee_id = ppf.person_id
      AND    ppf.current_employee_flag = cv_yes_no_y
      AND    TRUNC( SYSDATE ) BETWEEN ppf.effective_start_date
                              AND     ppf.effective_end_date
      AND    fu.user_id = fnd_profile.value( cv_profile_user_id )
      AND    ppf.attribute28 IS NOT NULL ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_security := cn_security_99 ;
--
    END ;
--
    -- ログインユーザーに紐付く所属部門が存在した場合
    IF (ln_security = cn_security_0) THEN
      BEGIN
        -- ====================================================
        -- 財務経理判定
        -- ===================================================
        SELECT cn_security_1    cn_security_1         -- 財務
        INTO   ln_security
        FROM   xxcfo_security_zaimu_v xszv
        WHERE  xszv.lookup_code = lv_papf_dff28 ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL ;
--
      END ;
    END IF ;
--
-- 2016.01.26 Ver1.2 Add Start
    IF (ln_security = cn_security_0) THEN
      BEGIN
        -- ====================================================
        -- 職責：SALES_XXXX_損益照会_会計の判定
        -- ===================================================
        SELECT fnd_profile.value(cv_profile_resp_id)  resp_id        -- 職責ID
        INTO   lt_resp_id
        FROM   fnd_responsibility fr   -- 職責
        WHERE  fr.application_id     = cn_appli_id_101
        AND    fr.responsibility_key LIKE cv_dept_user
        AND    fr.responsibility_id  = fnd_profile.value(cv_profile_resp_id) ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
      -- 職責：SALES_XXXX_損益照会_会計の場合
      IF ( lt_resp_id IS NOT NULL ) THEN
        BEGIN
          -- ====================================================
          -- 経費精算発生事由データ出力の判定
          -- ===================================================
          SELECT fcp.concurrent_program_id  program_id
          INTO   lt_program_id
          FROM   fnd_concurrent_programs fcp
          WHERE  fcp.application_id          = cn_prog_appl_id
          AND    fcp.concurrent_program_name = cv_conc_name
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- 経費精算発生事由データ出力の場合
        IF ( lt_program_id = cn_program_id ) THEN
          ln_security := cn_security_3;  -- 損益照会/経費精算発生事由データ出力
        END IF;
      END IF;
    END IF;
--
-- 2016.01.26 Ver1.2 Add End
    -- 拠点の場合
    IF (ln_security = cn_security_0) THEN
      BEGIN
        -- ====================================================
        -- 購買関連判定
        -- ===================================================
        SELECT cn_security_2    cn_security_2         -- 購買
        INTO   ln_security
        FROM   xxcfo_security_koubai_v xskv
        WHERE  xskv.lookup_code = lv_papf_dff28 ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL ;
      END ;
-- 2016.01.26 Ver1.2 Del Start
-- 2015.12.02 Ver1.1 Add Start
--      BEGIN
--        -- ====================================================
--        -- 職責：SALES_XXXX_損益照会_会計の判定
--        -- ===================================================
--        SELECT cn_security_3    cn_security_3                  -- 損益照会
--              ,fnd_profile.value(cv_profile_resp_id)  resp_id  -- 職責ID
--        INTO   ln_security
--              ,lt_resp_id
--        FROM   fnd_responsibility fr   -- 職責
--        WHERE  fr.application_id     = cn_appli_id_101
--        AND    fr.responsibility_key LIKE cv_dept_user
--        AND    fr.responsibility_id  = fnd_profile.value(cv_profile_resp_id) ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--      END;
-- 2015.12.02 Ver1.1 Add End
-- 2016.01.26 Ver1.2 Del End
    END IF ;
--
    -- WHERE句追加判定（財務,所属部門なし）
    IF (ln_security IN ( cn_security_1 ,cn_security_99 )) THEN
      NULL ;
-- 2015.12.02 Ver1.1 Add Start
    -- 損益照会/経費精算発生事由データ出力の場合
    ELSIF (ln_security = cn_security_3) THEN
      -- ====================================================
      -- 階層部門起票分
      -- ===================================================
      lv_where := ' ( EXISTS (  SELECT 1 ' ;
      lv_where := lv_where || ' FROM   apps.fnd_flex_value_rule_usages   ffvru';  -- セキュリティルール割当
      lv_where := lv_where || '       ,apps.fnd_flex_value_rules         ffvr';   -- セキュリティルール
      lv_where := lv_where || '       ,apps.fnd_flex_value_sets          ffvs';   -- セキュリティルールセット
      lv_where := lv_where || '       ,apps.fnd_flex_value_rule_lines    ffvrl';  -- セキュリティルール要素
      lv_where := lv_where || ' WHERE  ffvru.application_id              = ' || cn_appli_id_101 || ' ' ;
      lv_where := lv_where || ' AND    ffvs.flex_value_set_name          = ' || '''' || cv_xx03_department || '''' || ' ' ;
      lv_where := lv_where || ' AND    ffvr.flex_value_set_id            = ffvs.flex_value_set_id ' ;
      lv_where := lv_where || ' AND    ffvru.flex_value_rule_id          = ffvr.flex_value_rule_id ' ;
      lv_where := lv_where || ' AND    ffvru.flex_value_set_id           = ffvr.flex_value_set_id ' ;
      lv_where := lv_where || ' AND    ffvrl.flex_value_rule_id          = ffvr.flex_value_rule_id ' ;
      lv_where := lv_where || ' AND    ffvrl.flex_value_set_id           = ffvr.flex_value_set_id ' ;
      lv_where := lv_where || ' AND    ffvrl.flex_value_low              = ap_invoices_all.attribute3 ' ;
      lv_where := lv_where || ' AND    ap_invoices_all.set_of_books_id   = ' || ln_set_of_books_id || ' ' ;
      lv_where := lv_where || ' AND    ap_invoices_all.org_id            = ' || ln_org_id || ' ' ;
      lv_where := lv_where || ' AND    ffvru.responsibility_id           = ' || lt_resp_id || ' ) ) ' ;
-- 2015.12.02 Ver1.1 Add End
    ELSE
      -- ====================================================
      -- 各拠点・部門/購買関連共通設定
      -- ===================================================
      -- ====================================================
      -- 自拠点・部門起票分
      -- ===================================================
      lv_where := '(( EXISTS ( SELECT 1 ' ;
      lv_where := lv_where || 'FROM dual ' ;
      lv_where := lv_where || 'WHERE ap_invoices_all.attribute3 = ' || '''' || lv_papf_dff28 || '''' || ' ' ;
      lv_where := lv_where || 'AND ap_invoices_all.set_of_books_id = ' || ln_set_of_books_id || ' ' ;
      lv_where := lv_where || 'AND ap_invoices_all.org_id = ' || ln_org_id || ' ) ' ;
--
      -- ====================================================
      -- 自拠点・部門支払分
      -- ===================================================
      lv_where := lv_where || 'OR EXISTS ( SELECT 1 ' ;
      lv_where := lv_where || 'FROM xxcfo_pay_group_v xpgv ' ;
      lv_where := lv_where || 'WHERE xpgv.attribute2 = ' || '''' || lv_papf_dff28 || '''' || ' '  ;
      lv_where := lv_where || 'AND ap_invoices_all.pay_group_lookup_code = xpgv.lookup_code ' ;
      lv_where := lv_where || 'AND ap_invoices_all.set_of_books_id = ' || ln_set_of_books_id || ' ' ;
      lv_where := lv_where || 'AND ap_invoices_all.org_id = ' || ln_org_id || ' )) ' ;
--
      -- ====================================================
      -- 購買関連
      -- ===================================================
      IF (ln_security = cn_security_2) THEN
        lv_where := lv_where || 'OR EXISTS ( SELECT 1 ' ;
        lv_where := lv_where || 'FROM po_vendor_sites_all pvsa ' ;
        lv_where := lv_where || 'WHERE pvsa.org_id = ' || ln_org_id || ' ' ;
        lv_where := lv_where || 'AND pvsa.purchasing_site_flag = '|| '''' || cv_yes_no_y || '''' || ' ' ;
        lv_where := lv_where || 'AND pvsa.vendor_site_id = ap_invoices_all.vendor_site_id ' ;
        lv_where := lv_where || 'AND ap_invoices_all.set_of_books_id = ' || ln_set_of_books_id || ' ' ;
        lv_where := lv_where || 'AND pvsa.org_id = ap_invoices_all.org_id ' ;
        lv_where := lv_where || ')) ' ;
--
      ELSE
      -- ====================================================
      -- 購買関連以外
      -- ===================================================
        lv_where := lv_where || ') ' ;
      END IF ;
    END IF ;
--
    RETURN lv_where ;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_policy_condition;
--
--
END XXCFO006A01P1;
/
