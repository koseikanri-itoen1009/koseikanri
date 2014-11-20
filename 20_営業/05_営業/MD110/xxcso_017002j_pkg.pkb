CREATE OR REPLACE PACKAGE BODY APPS.xxcso_017002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Function Name    : xxcso_017002j_pkg(BODY)
 * Description      : 見積明細登録
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  set_quote_lines             P          見積明細登録用プロシージャ
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   R.Oikawa          新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
    gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_017002j_pkg';   -- パッケージ名
   /**********************************************************************************
   * Function Name    : set_quote_lines
   * Description      : 見積明細登録用プロシージャ
   ***********************************************************************************/
  PROCEDURE set_quote_lines(
    iv_select_flg                   IN  VARCHAR2,           -- 選択
    in_quote_line_id                IN  NUMBER,             -- 見積明細ＩＤ
    in_reference_quote_line_id      IN  NUMBER,             -- 参照用見積明細ＩＤ
    iv_quotation_price              IN  VARCHAR2,           -- 建値
    iv_sales_discount_price         IN  VARCHAR2,           -- 売上値引
    iv_usuall_net_price             IN  VARCHAR2,           -- 通常ＮＥＴ価格
    iv_this_time_net_price          IN  VARCHAR2,           -- 今回ＮＥＴ価格
    iv_amount_of_margin             IN  VARCHAR2,           -- マージン額
    iv_margin_rate                  IN  VARCHAR2,           -- マージン率
    id_quote_start_date             IN  DATE,               -- 期間（開始）
    iv_remarks                      IN  VARCHAR2,           -- 備考
    iv_line_order                   IN  VARCHAR2,           -- 並び順
    in_quote_header_id              IN  NUMBER              -- 見積ヘッダーＩＤ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)   := 'set_quote_lines';
    --WHOカラム
    cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
    cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
    cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
    cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
    cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_quote_line_id                   NUMBER(15);
  BEGIN
--

    IF  iv_select_flg = 'N'
    AND in_reference_quote_line_id IS NOT NULL THEN
      BEGIN
        SELECT quote_line_id
        INTO   ln_quote_line_id
        FROM   xxcso_quote_lines
        WHERE quote_line_id = in_quote_line_id;

        /* DELETE処理 */
        DELETE xxcso_quote_lines 
          WHERE quote_line_id = in_quote_line_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_quote_line_id := NULL;
      END;
    ELSIF  iv_select_flg = 'Y' THEN
      /* INSERT処理 */
      BEGIN
        INSERT INTO
          xxcso_quote_lines(
              quote_line_id
             ,quote_header_id
             ,reference_quote_line_id
             ,inventory_item_id
             ,quote_div
             ,usually_deliv_price
             ,usually_store_sale_price
             ,this_time_deliv_price
             ,this_time_store_sale_price
             ,quotation_price 
             ,sales_discount_price
             ,usuall_net_price
             ,this_time_net_price
             ,amount_of_margin
             ,margin_rate
             ,quote_start_date
             ,quote_end_date
             ,remarks
             ,line_order
             ,business_price
             ,created_by
             ,creation_date
             ,last_updated_by
             ,last_update_date
             ,last_update_login)
        SELECT
              in_quote_line_id
             ,in_quote_header_id
             ,in_reference_quote_line_id
             ,inventory_item_id
             ,quote_div
             ,usually_deliv_price
             ,''                                             -- usually_store_sale_price
             ,this_time_deliv_price
             ,''                                             -- this_time_store_sale_price
             ,TO_NUMBER(REPLACE(iv_quotation_price,','))
             ,TO_NUMBER(REPLACE(iv_sales_discount_price,','))
             ,TO_NUMBER(REPLACE(iv_usuall_net_price,','))
             ,TO_NUMBER(REPLACE(iv_this_time_net_price,','))
             ,TO_NUMBER(REPLACE(iv_amount_of_margin,','))
             ,TO_NUMBER(REPLACE(iv_margin_rate,'%'))
             ,TO_DATE(id_quote_start_date,'YYYY-MM-DD')
             ,quote_end_date
             ,iv_remarks
             ,iv_line_order
             ,business_price
             ,cn_created_by
             ,cd_creation_date
             ,cn_last_updated_by
             ,cd_last_update_date
             ,cn_last_update_login
        FROM  xxcso_quote_lines
        WHERE quote_line_id = in_reference_quote_line_id;
      EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        UPDATE xxcso_quote_lines
          SET
            quote_header_id      = in_quote_header_id
           ,quotation_price      = TO_NUMBER(REPLACE(iv_quotation_price,','))
           ,sales_discount_price = TO_NUMBER(REPLACE(iv_sales_discount_price,','))
           ,usuall_net_price     = TO_NUMBER(REPLACE(iv_usuall_net_price,','))
           ,this_time_net_price  = TO_NUMBER(REPLACE(iv_this_time_net_price,','))
           ,amount_of_margin     = TO_NUMBER(REPLACE(iv_amount_of_margin,','))
           ,margin_rate          = TO_NUMBER(REPLACE(iv_margin_rate,'%'))
           ,quote_start_date     = TO_DATE(id_quote_start_date,'YYYY-MM-DD')
           ,remarks              = iv_remarks
           ,line_order           = iv_line_order
           ,last_updated_by      = cn_last_updated_by
           ,last_update_date     = cd_last_update_date
           ,last_update_login    = cn_last_update_login
         WHERE quote_line_id     = in_quote_line_id;
      END;
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
  END set_quote_lines;
--
   /**********************************************************************************
   * Function Name    : set_sales_status
   * Description      : 販売用見積のステータス更新用プロシージャ
   ***********************************************************************************/
  PROCEDURE set_sales_status(
    in_reference_quote_header_id      IN  NUMBER             -- 参照用見積ヘッダーＩＤ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)   := 'set_sales_status';
    cv_quote_input            CONSTANT VARCHAR2(1)     := '1';
    cv_quote_fixation         CONSTANT VARCHAR2(1)     := '2';
    --WHOカラム
    cn_created_by             CONSTANT NUMBER          := fnd_global.user_id;         --CREATED_BY
    cd_creation_date          CONSTANT DATE            := SYSDATE;                    --CREATION_DATE
    cn_last_updated_by        CONSTANT NUMBER          := fnd_global.user_id;         --LAST_UPDATED_BY
    cd_last_update_date       CONSTANT DATE            := SYSDATE;                    --LAST_UPDATE_DATE
    cn_last_update_login      CONSTANT NUMBER          := fnd_global.login_id;        --LAST_UPDATE_LOGIN
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_status                          VARCHAR2(1);
  BEGIN
--
    SELECT status
    INTO   lv_status
    FROM   xxcso_quote_headers
    WHERE  quote_header_id = in_reference_quote_header_id;
--
    IF lv_status = cv_quote_input THEN
      UPDATE xxcso_quote_headers
        SET
          status              = cv_quote_fixation
         ,last_updated_by     = cn_last_updated_by
         ,last_update_date    = cd_last_update_date
         ,last_update_login   = cn_last_update_login
        WHERE quote_header_id = in_reference_quote_header_id;
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
  END set_sales_status;
END xxcso_017002j_pkg;
/
