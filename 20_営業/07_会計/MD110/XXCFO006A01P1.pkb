CREATE OR REPLACE PACKAGE BODY XXCFO006A01P1
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name    : XXCFO006A01P1(body)
 * Description     : APWIセキュリティ
 * MD.050          : MD050_CFO_006_A01_APWIセキュリティ
 * MD.070          : MD050_CFO_006_A01_APWIセキュリティ
 * Version         : 1.0
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
    cv_yes_no_y         CONSTANT VARCHAR2(1) := 'Y' ;                                       -- Y
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_where            VARCHAR2(4000) ;                        -- 戻り値用WHERE句
    ln_security         NUMBER(2) ;                             -- 0:拠点・部門/1:財務/2:購買/99:ログインユーザー対象なし
    lv_papf_dff28       PER_ALL_PEOPLE_F.ATTRIBUTE28%TYPE ;     -- ログインユーザーに紐付く所属部門
    ln_set_of_books_id  AP_INVOICES_ALL.SET_OF_BOOKS_ID%TYPE ;  -- 会計帳簿ID
    ln_org_id           AP_INVOICES_ALL.ORG_ID%TYPE ;           -- 組織ID
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
    END IF ;
--
    -- WHERE句追加判定（財務,所属部門なし）
    IF (ln_security IN ( cn_security_1 ,cn_security_99 )) THEN
      NULL ;
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
