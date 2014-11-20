CREATE OR REPLACE PACKAGE XXCFR_COMMON_PKG--(変更)
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcfr_common_pkg(spec)
 * Description      : 
 * MD.050           : なし
 * Version          : 1.2
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_user_dept             F    VAR    ログインユーザ所属部門取得関数
 *  chk_invoice_all_dept      F    VAR    請求書全社出力権限判定関数
 *  put_log_param             P           入力パラメータ値ログ出力処理
 *  get_table_comment         F    VAR    テーブルコメント取得処理
 *  get_user_profile_name     F    VAR    ユーザプロファイル名取得処理
 *  get_cust_account_name     F    VAR    顧客名称取得関数
 *  get_col_comment           F    VAR    項目コメント取得処理
 *  lookup_dictionary         F    VAR    日本語辞書参照関数処理
 *  get_date_param_trans      F    VAR    日付パラメータ変換関数
 *  csv_out                   P           OUTファイル出力処理
 *  get_base_target_tel_num   F    VAR    請求拠点担当電話番号取得関数
 *  get_receive_updatable     F    VAR    入金画面 顧客変更可能判定
-- Modify 2010.07.09 Ver1.2 Start
 *  awi_ship_code             P           ARWebInquiry用 納品先顧客コード値リスト
-- Modify 2010.07.09 Ver1.2 End
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-10-16   1.0    SCS 大川恵       新規作成
 *  2008-10-28   1.0    SCS 松尾 泰生    顧客名称取得関数追加
 *  2008-10-29   1.0    SCS 中村 博      入力パラメータ値ログ出力関数関数追加
 *  2008-11-10   1.0    SCS 中村 博      入力パラメータ値ログ出力関数修正
 *  2008-11-10   1.0    SCS 中村 博      項目コメント取得処理関数追加
 *  2008-11-12   1.0    SCS 中村 博      日本語辞書参照関数処理追加
 *  2008-11-13   1.0    SCS 松尾 泰生    日付パラメータ変換関数追加
 *  2008-11-18   1.0    SCS 吉村 憲司    OUTファイル出力処理追加
 *  2008-12-22   1.0    SCS 松尾 泰生    請求拠点担当電話番号取得関数追加
 *  2010-03-31   1.1    SCS 安川 智博    障害「E_本稼動_02092」対応
 *                                       新規function「get_receive_updatable」を追加
 *  2010-07-09   1.2    SCS 廣瀬 真佐人  障害「E_本稼動_01990」対応
 *                                       新規Prucedure「awi_ship_code」を追加
 *
 *****************************************************************************************/
--
  --ログインユーザ所属部門取得関数
  FUNCTION get_user_dept(
    in_user_id       IN     NUMBER,           -- 1.ユーザID
    id_get_date      IN     DATE)             -- 2.取得日付
  RETURN VARCHAR2;                            -- ログインユーザ所属部門
  --
  --請求書全社出力権限判定関数
  FUNCTION chk_invoice_all_dept(
    iv_user_dept_code IN    VARCHAR2,         -- 1.所属部門コード
    iv_invoice_type   IN    VARCHAR2)         -- 2.請求書タイプ
  RETURN VARCHAR2;                            -- 判定結果
  --
  --入力パラメータ値ログ出力処理
  PROCEDURE put_log_param(
    iv_which                IN  VARCHAR2 DEFAULT 'OUTPUT',  -- 出力区分
    iv_conc_param1          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ１
    iv_conc_param2          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ２
    iv_conc_param3          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ３
    iv_conc_param4          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ４
    iv_conc_param5          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ５
    iv_conc_param6          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ６
    iv_conc_param7          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ７
    iv_conc_param8          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ８
    iv_conc_param9          IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ９
    iv_conc_param10         IN  VARCHAR2 DEFAULT NULL,      -- コンカレントパラメータ１０
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  ;
  --
  --テーブルコメント取得処理
  FUNCTION get_table_comment(
    iv_table_name          IN  VARCHAR2 )       -- テーブル名
  RETURN VARCHAR2;                              -- テーブルコメント
  --
  --プロファイル名取得処理
  FUNCTION get_user_profile_name(
    iv_profile_name        IN  VARCHAR2 )       -- プロファイル名
  RETURN VARCHAR2;                              -- ユーザプロファイル名
  --
  --顧客名称取得関数
  FUNCTION get_cust_account_name(
    iv_account_number  IN   VARCHAR2,         -- 1.顧客コード
    iv_kana_judge_type IN   VARCHAR2 )        -- 2.カナ名判断区分(0:正式名称, 1:カナ名)
  RETURN VARCHAR2;
  --
  --項目コメント取得処理
  FUNCTION get_col_comment(
    iv_table_name          IN  VARCHAR2,        -- テーブル名
    iv_column_name         IN  VARCHAR2 )       -- 項目名
  RETURN VARCHAR2;                              -- 項目コメント
  --日本語辞書参照処理
  FUNCTION lookup_dictionary(
    iv_loopup_type_prefix  IN  VARCHAR2,        -- 参照タイプの接頭辞（アプリケーション短縮名と同じ）
    iv_keyword             IN  VARCHAR2 )       -- キーワード
  RETURN VARCHAR2;                              -- 日本語内容
  --
  --日付パラメータ変換関数
  FUNCTION get_date_param_trans(
    iv_date_param          IN  VARCHAR2 )       -- 日付値パラメータ(文字列型)
  RETURN DATE;                                  -- 日付値パラメータ(日付型)
  --
  --OUTファイル出力処理
  PROCEDURE  csv_out(
    in_request_id     IN   NUMBER,    -- 1.要求ID
    iv_lookup_type    IN   VARCHAR2,  -- 2.参照タイプ
    in_rec_cnt        IN   NUMBER,    -- 3.レコード件数
    ov_errbuf         OUT  VARCHAR2,  -- 4.出力メッセージ
    ov_retcode        OUT  VARCHAR2,  -- 5.リターンコード
    ov_errmsg         OUT  VARCHAR2)  -- 6.ユーザメッセージ
  ;
  --
  --請求拠点担当電話番号取得関数
  FUNCTION get_base_target_tel_num(
    iv_bill_acct_code  IN   VARCHAR2          -- 1.請求先顧客コード
  )
  RETURN VARCHAR2;
  --
  --入金顧客変更可能判定
  FUNCTION get_receive_updatable(
    in_cash_receipt_id IN NUMBER,   -- 1.入金ID
    iv_gl_date IN VARCHAR2          -- 2.GL記帳日
  )
  RETURN VARCHAR2;
-- Modify 2010.07.09 Ver1.2 Start
  --
  -- ARWebInquiry用 納品先顧客コード値リスト
  PROCEDURE awi_ship_code(
    p_sql_type         IN     VARCHAR2,
    p_sql              IN OUT VARCHAR2,
    p_list_filter_item IN     VARCHAR2,
    p_sort_item        IN     VARCHAR2,
    p_sort_method      IN     VARCHAR2,
    p_segment_id       IN     NUMBER,
    p_child_condition  IN     VARCHAR2,
    p_parent_condition IN     VARCHAR2 DEFAULT NULL)
  ;
-- Modify 2010.07.09 Ver1.2 End
--
END XXCFR_COMMON_PKG;--(変更)
/
