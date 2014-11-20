CREATE OR REPLACE PACKAGE apps.xxcso_007003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_007003j_pkg(SPEC)
 * Description      : 商談決定情報入力
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  request_sales_approval    P    -     商談決定情報入力承認依頼
 *  get_quotation_price       F    N     建値取得
 *  get_baseline_base_code    F    V     承認者検索ベース組織取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Ogawa          新規作成
 *
 *****************************************************************************************/
--
  -- 商談決定情報入力承認依頼
  PROCEDURE request_sales_approval(
    ov_errbuf       OUT VARCHAR2
   ,ov_retcode      OUT VARCHAR2
   ,ov_errmsg       OUT VARCHAR2
  );
--
  -- 建値取得
  FUNCTION get_quotation_price(
    in_ref_quote_line_id       IN  NUMBER
  ) RETURN NUMBER;
--
  -- 承認者検索ベース組織取得
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2;
--
  FUNCTION get_baseline_base_code(
    iv_base_code               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
END xxcso_007003j_pkg;
/
