create or replace FUNCTION xxwsh_loader_id_func(
  iv_head_line_type        IN VARCHAR2,    -- ヘッダ･明細区分
  iv_lines_head_line_type  IN VARCHAR2,    -- ヘッダ･明細区分(明細)
  iv_eos_data_type         IN VARCHAR2,    -- データ種別
  iv_delivery_no           IN VARCHAR2,    -- 配送№
  iv_order_source_ref      IN VARCHAR2     -- 依頼№
  )
  RETURN NUMBER
IS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Proc Name              : xxwsh_loader_id_func
 * Description            : SQL*Loader用ID発行関数
 * MD.070(CMD.050)        : なし
 * Version                : 1.1
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/05/19   1.0   ORACLE 椎名昭圭  新規作成
 *  2008/06/11   1.1   ORACLE 冨田信    LINE時のHEADER_ID取得不具合対応
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー宣言部
  -- ===============================
  -- *** ローカル定数 ***
  cv_headers          VARCHAR2(150)        := 'HEADERS';  -- ヘッダ
  cv_lines            VARCHAR2(150)        := 'LINES';    -- 明細
  cv_delivery_no_null CONSTANT VARCHAR2(1) := 'X';        -- 配送No＝NULL時の変換文字
--
  -- *** ローカル変数 ***
  ln_seq            NUMBER;                               -- 採番番号
--
BEGIN
  -- ヘッダのヘッダIDを取得
  IF (iv_head_line_type = cv_headers) THEN
    SELECT xxwsh_shipping_headers_if_s1.NEXTVAL INTO ln_seq FROM dual;
  -- 明細のヘッダIDを取得
  ELSIF (iv_head_line_type = cv_lines) AND
          (iv_lines_head_line_type = cv_headers) THEN
--    SELECT xxwsh_shipping_headers_if_s1.CURRVAL INTO ln_seq FROM dual;
    SELECT NVL(MAX(header_id),0)              -- MAX関数により、取得できない場合は0を返す
      INTO ln_seq
      FROM XXWSH_SHIPPING_HEADERS_IF
     WHERE EOS_DATA_TYPE = iv_eos_data_type
       AND NVL(DELIVERY_NO,cv_delivery_no_null) = NVL(iv_delivery_no,cv_delivery_no_null)
       AND ORDER_SOURCE_REF = iv_order_source_ref;
-- 明細の明細IDを取得
  ELSIF (iv_head_line_type = cv_lines) AND
          (iv_lines_head_line_type = cv_lines) THEN
    SELECT xxwsh_shipping_lines_if_s1.NEXTVAL INTO ln_seq FROM dual;
--
  ELSE
    ln_seq := NULL;
--
  END IF;
--
  RETURN ln_seq;
--
END xxwsh_loader_id_func;
/
