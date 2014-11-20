CREATE OR REPLACE PACKAGE BODY APPS.xxcso_007003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_007003j_pkg(BODY)
 * Description      : 商談決定情報入力
 * MD.050/070       : 
 * Version          : 1.2
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  request_sales_approval    P    -     商談決定情報入力承認依頼
 *  get_quotation_price       F    -     建値取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Ogawa          新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2012/09/06    1.2   M.Nagai          E_本稼動_09618対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_007003j_pkg';   -- パッケージ名
--
  /**********************************************************************************
   * Function Name    : request_sales_approval
   * Description      : 商談決定情報入力承認依頼
   ***********************************************************************************/
  PROCEDURE request_sales_approval(
    ov_errbuf       OUT VARCHAR2
   ,ov_retcode      OUT VARCHAR2
   ,ov_errmsg       OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'request_sales_approval';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_header_history_id         NUMBER;
    ln_lead_id                   NUMBER;
    lv_notify_subject            xxcso_tmp_sales_request.notify_subject%TYPE;
    lv_notify_comment            xxcso_tmp_sales_request.notify_comment%TYPE;
    lv_appr_user_name            fnd_user.user_name%TYPE;
    lv_appr_emp_number           xxcso_sales_headers_hist.approval_employee_number%TYPE;
    lv_appr_name                 xxcso_sales_headers_hist.approval_name%TYPE;
    lv_itemtype                  VARCHAR2(8);
    lv_itemkey                   VARCHAR2(100);
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- 承認依頼情報を取得
    SELECT  xtsr.header_history_id
           ,xtsr.lead_id
           ,xtsr.notify_subject
           ,xtsr.notify_comment
           ,xtsr.approval_user_name
    INTO    ln_header_history_id
           ,ln_lead_id
           ,lv_notify_subject
           ,lv_notify_comment
           ,lv_appr_user_name
    FROM    xxcso_tmp_sales_request  xtsr
    ;
--
    SELECT  xev.employee_number
           ,xev.full_name
    INTO    lv_appr_emp_number
           ,lv_appr_name
    FROM    xxcso_employees_v2  xev
    WHERE   xev.user_name = lv_appr_user_name
    ;
--
    -- 商談決定情報履歴ヘッダ作成
    INSERT INTO     xxcso_sales_headers_hist(
                      header_history_id
                     ,lead_id
                     ,lead_number
                     ,lead_description
                     ,party_name
                     ,other_content
                     ,approval_employee_number
                     ,approval_name
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                   )
           SELECT  ln_header_history_id
                  ,xsh.lead_id
                  ,ala.lead_number
                  ,ala.description
                  ,hp.party_name
                  ,xsh.other_content
                  ,lv_appr_emp_number
                  ,lv_appr_name
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.login_id
           FROM    xxcso_sales_headers  xsh
                  ,as_leads_all         ala
                  ,hz_parties           hp
           WHERE   xsh.lead_id            = ln_lead_id
             AND   ala.lead_id            = xsh.lead_id
             AND   hp.party_id            = ala.customer_id
    ;
--
    -- 商談決定情報履歴明細作成
    INSERT INTO    xxcso_sales_lines_hist(
                     line_history_id
                    ,header_history_id
                    ,quote_number
                    ,quote_revision_number
                    ,inventory_item_id
                    ,sales_class_code
                    ,sales_adopt_class_code
                    ,sales_area_code
                    ,sales_schedule_date
                    ,deliv_price
                    ,store_sales_price
                    ,store_sales_price_inc_tax
                    ,quotation_price
                    ,introduce_terms
                    ,sales_line_id
                    ,notified_flag
                    ,created_by
                    ,creation_date
                    ,last_updated_by
                    ,last_update_date
                    ,last_update_login
                   )
           SELECT  xxcso_sales_lines_hist_s01.nextval
                  ,ln_header_history_id
                  ,xsl.quote_number
                  ,xsl.quote_revision_number
                  ,xsl.inventory_item_id
                  ,xsl.sales_class_code
                  ,xsl.sales_adopt_class_code
                  ,xsl.sales_area_code
                  ,xsl.sales_schedule_date
                  ,xsl.deliv_price
                  ,xsl.store_sales_price
                  ,xsl.store_sales_price_inc_tax
                  ,xsl.quotation_price
                  ,xsl.introduce_terms
                  ,xsl.sales_line_id
                  ,'N'
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.login_id
           FROM    xxcso_sales_headers   xsh
                  ,xxcso_sales_lines     xsl
           WHERE   xsh.lead_id            = ln_lead_id
             AND   xsl.sales_header_id    = xsh.sales_header_id
             AND   xsl.notify_flag        = 'Y'
    ;
--
    -- 商談決定情報明細の通知フラグを'N'に戻す
    UPDATE xxcso_sales_lines
    SET    notify_flag = 'N'
    WHERE  sales_header_id = (SELECT  xsh.sales_header_id
                              FROM    xxcso_sales_headers   xsh
                              WHERE   xsh.lead_id = ln_lead_id
                             )
    ;
    -- 商談決定情報通知者リストの通知済フラグを'N'に戻す
    UPDATE xxcso_sales_notifies
    SET    notified_flag = 'N'
    WHERE  header_history_id = ln_header_history_id
    ;
--
    -- 商談決定情報通知ワークフローを起動する
    lv_itemtype := 'XXCSO007';
    lv_itemkey  := 'XXCSO007' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || ln_lead_id;
--
    wf_engine.createprocess(
      itemtype   => lv_itemtype
     ,itemkey    => lv_itemkey
     ,process    => 'XXCSO007002P01'
     ,owner_role => fnd_global.user_name
    );
    --
    wf_engine.setitemattrnumber(
      itemtype   => lv_itemtype
     ,itemkey    => lv_itemkey
     ,aname      => 'XXCSO_NOTIFY_HEADER_ID'
     ,avalue     => ln_header_history_id
    );
    --
    wf_engine.setitemattrtext(
      itemtype   => lv_itemtype
     ,itemkey    => lv_itemkey
     ,aname      => 'XXCSO_NOTIFY_APPR_USER_NAME'
     ,avalue     => lv_appr_user_name
    );
    --
    wf_engine.setitemattrtext(
      itemtype   => lv_itemtype
     ,itemkey    => lv_itemkey
     ,aname      => 'XXCSO_REQUEST_APPR_USER_NAME'
     ,avalue     => fnd_global.user_name
    );
    --
    wf_engine.setitemattrtext(
      itemtype   => lv_itemtype
     ,itemkey    => lv_itemkey
     ,aname      => 'XXCSO_NOTIFY_SUBJECT'
     ,avalue     => lv_notify_subject
    );
    --
    wf_engine.setitemattrtext(
      itemtype   => lv_itemtype
     ,itemkey    => lv_itemkey
     ,aname      => 'XXCSO_NOTIFY_COMMENT'
     ,avalue     => lv_notify_comment
    );
    --
    wf_engine.startprocess(
      itemtype   => lv_itemtype
     ,itemkey    => lv_itemkey
    );
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END request_sales_approval;
--
  /**********************************************************************************
   * Function Name    : get_quotation_price
   * Description      : 建値取得
   ***********************************************************************************/
  FUNCTION get_quotation_price(
    in_ref_quote_line_id       IN  NUMBER
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_quotation_price';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_quote_line_id         NUMBER;
    ln_quotation_price       NUMBER;
--
  BEGIN
--
    SELECT  MAX(xql.quote_line_id)
    INTO    ln_quote_line_id
    FROM    xxcso_quote_lines     xql
           ,xxcso_quote_headers   xqh
    WHERE   xql.reference_quote_line_id = in_ref_quote_line_id
      AND   xqh.quote_header_id         = xql.quote_header_id
      AND   xqh.status                  = '2'
    ;
--
    IF ( ln_quote_line_id IS NOT NULL ) THEN
--
      SELECT  xql.quotation_price
      INTO    ln_quotation_price
      FROM    xxcso_quote_lines     xql
      WHERE   xql.quote_line_id     = ln_quote_line_id
      ;
    END IF;
--
    RETURN ln_quotation_price;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_quotation_price;
--
  /**********************************************************************************
   * Function Name    : get_baseline_base_code
   * Description      : 承認者検索ベース組織取得
   ***********************************************************************************/
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_baseline_base_code';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_baseline_base_code        fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR root_base_data_cur IS
    SELECT  LEVEL
           ,xablv.base_code       AS base_code
           ,xablv.child_base_code AS child_base_code
    FROM    xxcso_aff_base_level_v2 xablv
    START WITH
            xablv.child_base_code = 
              (SELECT xxcso_util_common_pkg.get_emp_parameter(
                        xev.work_base_code_new
                       ,xev.work_base_code_old
                       ,xev.issue_date
                       ,xxcso_util_common_pkg.get_online_sysdate
                      ) base_code
               FROM   xxcso_employees_v2 xev
               WHERE  xev.user_id = fnd_global.user_id
              )
    CONNECT BY NOCYCLE PRIOR
            xablv.base_code = xablv.child_base_code
    ORDER BY LEVEL DESC
    ;
--
  -- 検索基準拠点コード取得
  BEGIN
--
    lv_baseline_base_code := NULL;
--
    <<root_base_data_rec>>
    FOR root_base_data_rec IN root_base_data_cur
    LOOP
      -- child_base_codeの2番目が常にL3の第3階層
      IF (root_base_data_cur%ROWCOUNT = 2) THEN
        lv_baseline_base_code := root_base_data_rec.child_base_code;
        EXIT;
      END IF;
    END LOOP root_base_data_rec;
--
    RETURN lv_baseline_base_code;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_baseline_base_code;
--
  /**********************************************************************************
   * Function Name    : get_baseline_base_code
   * Description      : 承認者ベース組織取得
   ***********************************************************************************/
  FUNCTION get_baseline_base_code(
    iv_base_code               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_baseline_base_code';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_baseline_base_code        fnd_flex_values.flex_value%TYPE;
    TYPE base_code_tbl IS TABLE OF fnd_flex_values.flex_value%TYPE INDEX BY BINARY_INTEGER;
    lt_base_code_tbl   base_code_tbl;
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 ADD START */
    ln_aff             NUMBER;
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 ADD END */
--
  -- 検索基準拠点コード取得
  BEGIN
--
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 ADD START */
    --プロファイル取得
    ln_aff := TO_NUMBER(fnd_profile.value('XXCSO1_SALES_APPLY_AFF'));--★プロファイル・オプション名
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 ADD END */
    lv_baseline_base_code := iv_base_code;
--
    lt_base_code_tbl(lt_base_code_tbl.COUNT + 1) := lv_baseline_base_code;
--
    << base_code_loop >>
    LOOP
--
      BEGIN
--
        SELECT  xablv.base_code AS child_base_code
        INTO    lv_baseline_base_code
        FROM    xxcso_aff_base_level_v2 xablv
        WHERE   xablv.child_base_code = lv_baseline_base_code
        ;
--
        lt_base_code_tbl(lt_base_code_tbl.COUNT + 1) := lv_baseline_base_code;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_baseline_base_code := NULL;
          EXIT base_code_loop;
      END;
    END LOOP base_code_loop;
--
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 MOD START */
--    IF ( lt_base_code_tbl.COUNT >= 3 ) THEN
    --プロファイルに設定されている階層以上の場合
    IF ( lt_base_code_tbl.COUNT >= ln_aff ) THEN
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 MOD END */
--
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 MOD START */
--      lv_baseline_base_code := lt_base_code_tbl(lt_base_code_tbl.COUNT - 2);
      lv_baseline_base_code := lt_base_code_tbl(lt_base_code_tbl.COUNT - ( ln_aff - 1 ) );
/* 2012/09/06 Ver1.2 M.Nagai E_本稼動_09618対応 MOD END */
--
    END IF;
--
    RETURN lv_baseline_base_code;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_baseline_base_code;
--
END xxcso_007003j_pkg;
/
