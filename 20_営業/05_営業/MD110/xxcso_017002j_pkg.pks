CREATE OR REPLACE PACKAGE apps.xxcso_017002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_017002j_pkg(SPEC)
 * Description      : 見積明細登録
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  set_quote_lines             P          見積明細登録用プロシージャ
 *  set_sales_status            P          販売用見積のステータス更新用プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   R.Oikawa          新規作成
 *
 *****************************************************************************************/
--
   -- 見積明細登録用プロシージャ
  PROCEDURE set_quote_lines(
    iv_select_flg                 IN  VARCHAR2,           -- 選択
    in_quote_line_id              IN  NUMBER,             -- 見積明細ＩＤ
    in_reference_quote_line_id    IN  NUMBER,             -- 参照用見積明細ＩＤ
    iv_quotation_price            IN  VARCHAR2,           -- 建値
    iv_sales_discount_price       IN  VARCHAR2,           -- 売上値引
    iv_usuall_net_price           IN  VARCHAR2,           -- 通常ＮＥＴ価格
    iv_this_time_net_price        IN  VARCHAR2,           -- 今回ＮＥＴ価格
    iv_amount_of_margin           IN  VARCHAR2,           -- マージン額
    iv_margin_rate                IN  VARCHAR2,           -- マージン率
    id_quote_start_date           IN  DATE,               -- 期間（開始）
    iv_remarks                    IN  VARCHAR2,           -- 備考
    iv_line_order                 IN  VARCHAR2,           -- 並び順
    in_quote_header_id            IN  NUMBER              -- 見積ヘッダーＩＤ
  );
--
   -- 販売用見積のステータス更新用プロシージャ
  PROCEDURE set_sales_status(
    in_reference_quote_header_id    IN  NUMBER            -- 参照用見積ヘッダーＩＤ
  );
--
END xxcso_017002j_pkg;
/
