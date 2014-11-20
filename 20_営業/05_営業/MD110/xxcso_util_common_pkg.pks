CREATE OR REPLACE PACKAGE APPS.xxcso_util_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_UTIL_COMMON_PKG(SPEC)
 * Description      : 共通関数(XXCSOユーティリティ）
 * MD.050/070       :
 * Version          : 1.3
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_base_name             F    V     拠点名取得関数
 *  get_parent_base_code      F    V     親拠点コード取得関数
 *  get_emp_parameter         F    V     従業員パラメータ取得関数
 *  get_lookup_meaning        F    V     クイックコード内容取得関数(TYPEのみ)
 *  get_lookup_description    F    V     クイックコード摘要取得関数(TYPEのみ)
 *  get_lookup_attribute      F    V     クイックコードDFF値取得関数(TYPEのみ)
 *  get_lookup_info           P    -     クイックコード取得処理(TYPEのみ)
 *  get_business_year         F    N     年度取得関数
 *  check_date                F    B     日付書式チェック関数
 *  check_ar_gl_period_status F    V     AR会計期間クローズチェック
 *  get_online_sysdate        F    D     システム日付取得関数（オンライン用）
 *  get_ar_gl_period_from     F    D     AR会計期間開始日取得関数
 *  chk_exe_report_visite_sales
 *                            P    -     訪問売上計画管理表出力判定関数
 *  get_working_days          F    N     営業日数取得関数
 *  chk_responsibility        F    -     ログイン者職責判定関数
 *  conv_multi_byte           F    -     半角文字全角置換関数
 *  conv_ng_char_vdms         F    -     自販機管理S禁則文字変換関数
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Ogawa          新規作成
 *  2008/11/11    1.0   K.Hosoi          get_business_year(年度取得関数)を追記
 *  2008/11/26    1.0   K.Hosoi          get_emp_parameter：id_issue_dateの型を
 *                                       DATEからVARCHAR2へ修正
 *  2008/12/04    1.0   K.Cho            check_date(日付書式チェック関数)を追記
 *  2008/12/08    1.0   T.Kyo            check_ar_gl_period_status:AR会計期間クローズチェック
 *  2008/12/16    1.0   H.Ogawa          LOOKUP_TYPEのみでクイックコードを取得する関数を追加
 *  2008/12/16    1.0   H.Ogawa          get_online_sysdate(システム日付取得関数
 *                                        (オンライン用))を追加
 *  2008/12/24    1.0   M.maruyama       ヘッダ修正(Oracle版からSCS版へ)
 *  2009/01/15    1.0   T.mori           get_ar_gl_period_from（AR会計期間開始日取得関数）を追加
 *  2009/01/16    1.0   T.mori           chk_exe_report_visite_sales
 *                                       （訪問売上計画管理表出力判定関数）を追加
 *                                       get_working_days（営業日数取得関数）を追加
 *  2009/02/02    1.0   K.Boku           chk_responsibility新規作成
 *  2009/04/16    1.1   K.Satomura       conv_multi_byte新規作成(T1_0172対応)
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009/05/12    1.3   K.Satomura       get_rs_base_code
 *                                       get_current_rs_base_code 新規作成(T1_0593対応)
 *  2009/12/14    1.4   T.Maruyama       E_本稼動_00469対応 conv_ng_char_vdms新規作成
 *****************************************************************************************/
--
  /**********************************************************************************
   * Function Name    : get_base_name
   * Description      : 拠点名取得関数
   ***********************************************************************************/
  FUNCTION get_base_name(
    iv_base_code             IN  VARCHAR2,               -- 拠点コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_parent_base_code
   * Description      : 親拠点コード取得関数
   ***********************************************************************************/
  FUNCTION get_parent_base_code(
    iv_base_code             IN  VARCHAR2,               -- 拠点コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_emp_parameter
   * Description      : 従業員パラメータ取得関数
   ***********************************************************************************/
  FUNCTION get_emp_parameter(
    iv_parameter_new         IN  VARCHAR2,               -- パラメータ(新)
    iv_parameter_old         IN  VARCHAR2,               -- パラメータ(旧)
    iv_issue_date            IN  VARCHAR2,               -- 発令日
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_lookup_meaning
   * Description      : クイックコード内容取得関数(TYPEのみ)
   ***********************************************************************************/
  FUNCTION get_lookup_meaning(
    iv_lookup_type           IN  VARCHAR2,               -- タイプ
    iv_lookup_code           IN  VARCHAR2,               -- コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_lookup_description
   * Description      : クイックコード摘要取得関数(TYPEのみ)
   ***********************************************************************************/
  FUNCTION get_lookup_description(
    iv_lookup_type           IN  VARCHAR2,               -- タイプ
    iv_lookup_code           IN  VARCHAR2,               -- コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_lookup_attribute
   * Description      : クイックコードDFF値取得関数(TYPEのみ)
   ***********************************************************************************/
  FUNCTION get_lookup_attribute(
    iv_lookup_type           IN  VARCHAR2,               -- タイプ
    iv_lookup_code           IN  VARCHAR2,               -- コード
    in_dff_number            IN  NUMBER,                 -- DFF番号
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Procedure Name    : get_lookup_info
   * Description      :クイックコード取得処理(TYPEのみ)
   ***********************************************************************************/
  PROCEDURE get_lookup_info(
    iv_lookup_type           IN  VARCHAR2,               -- タイプ
    iv_lookup_code           IN  VARCHAR2,               -- コード
    id_standard_date         IN  DATE,                   -- 基準日
    ov_meaning               OUT VARCHAR2,               -- 内容
    ov_description           OUT VARCHAR2,               -- 摘要
    ov_attribute1            OUT VARCHAR2,               -- DFF1
    ov_attribute2            OUT VARCHAR2,               -- DFF2
    ov_attribute3            OUT VARCHAR2,               -- DFF3
    ov_attribute4            OUT VARCHAR2,               -- DFF4
    ov_attribute5            OUT VARCHAR2,               -- DFF5
    ov_attribute6            OUT VARCHAR2,               -- DFF6
    ov_attribute7            OUT VARCHAR2,               -- DFF7
    ov_attribute8            OUT VARCHAR2,               -- DFF8
    ov_attribute9            OUT VARCHAR2,               -- DFF9
    ov_attribute10           OUT VARCHAR2,               -- DFF10
    ov_attribute11           OUT VARCHAR2,               -- DFF11
    ov_attribute12           OUT VARCHAR2,               -- DFF12
    ov_attribute13           OUT VARCHAR2,               -- DFF13
    ov_attribute14           OUT VARCHAR2,               -- DFF14
    ov_attribute15           OUT VARCHAR2,               -- DFF15
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- システムメッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 処理結果('0':正常, '1':警告, '2':エラー)
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザーメッセージ
  );
--
   /**********************************************************************************
   * Function Name    : get_business_year
   * Description      :年度取得関数
   ***********************************************************************************/
  FUNCTION get_business_year(
    iv_year_month    IN  VARCHAR2                        -- 年月
  )
  RETURN NUMBER;
--
   /**********************************************************************************
   * Function Name    : check_date
   * Description      :日付書式チェック関数
   ***********************************************************************************/
  FUNCTION check_date(
    iv_date         IN  VARCHAR2,                     -- 日付入力欄に入力された値
    iv_date_format  IN  VARCHAR2                      -- 日付フォーマット（書式文字列）
  )
  RETURN BOOLEAN;
--
   /**********************************************************************************
   * Function Name    : check_ar_gl_period_status
   * Description      :AR会計期間クローズチェック
   ***********************************************************************************/
  FUNCTION check_ar_gl_period_status(
    id_standard_date         IN  DATE                    -- チェック対象日
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_online_sysdate
   * Description      :システム日付取得関数（オンライン用）
   ***********************************************************************************/
  FUNCTION get_online_sysdate RETURN DATE;
--
  /**********************************************************************************
   * Function Name    : get_online_sysdate
   * Description      :AR会計期間開始日取得関数
   ***********************************************************************************/
  FUNCTION get_ar_gl_period_from RETURN DATE;
--
  /**********************************************************************************
   * Procedure Name    : chk_exe_report_visite_sales
   * Description      :訪問売上計画管理表出力判定関数
   ***********************************************************************************/
  PROCEDURE chk_exe_report_visite_sales(
    in_user_id               IN  NUMBER                  -- ログインユーザＩＤ
   ,in_resp_id               IN  NUMBER                  -- ログイン者職責ＩＤ
   ,iv_base_code             IN  VARCHAR2                -- 拠点コード（参照先）
   ,iv_report_type           IN  VARCHAR2                -- 帳票種別
   ,ov_ret_code              OUT VARCHAR2                -- 判定結果（'TRUE’／’FALSE’）
   ,ov_err_msg               OUT VARCHAR2                -- エラー理由
  );
--
  /**********************************************************************************
   * Function Name    : get_working_days
   * Description      :営業日数取得関数
   ***********************************************************************************/
  FUNCTION get_working_days(
    id_from_date             IN  DATE                    -- 基点日付
   ,id_to_date               IN  DATE                    -- 終点日付
  )
   RETURN NUMBER;
--
  -- ログイン者職責判定関数
  FUNCTION chk_responsibility(
    in_user_id               IN  NUMBER                  -- ログインユーザＩＤ
   ,in_resp_id               IN  NUMBER                  -- 職位ＩＤ
   ,iv_report_type           IN  VARCHAR2                -- 帳票タイプ（1:営業員別、2:営業員グループ別、その他は指定不可）
  ) RETURN VARCHAR2;                                     -- 'TRUE':チェックＯＫ 'FALSE':チェックＮＧ
--
  /* 2009.04.16 K.Satomura T1_0172対応 START */
  /**********************************************************************************
   * Function Name    : conv_multi_byte
   * Description      : 半角文字全角置換関数
   ***********************************************************************************/
  FUNCTION conv_multi_byte(
    iv_char IN VARCHAR2 -- 文字列
  ) RETURN VARCHAR2;
  /* 2009.04.16 K.Satomura T1_0172対応 END */
--
  /* 2009.05.12 K.Satomura T1_0593対応 START */
  /**********************************************************************************
   * Function Name    : get_rs_base_code
   * Description      : 所属拠点取得（リソースID、基準日指定）
   ***********************************************************************************/
  FUNCTION  get_rs_base_code(
    in_resource_id   IN NUMBER
   ,id_standard_date IN DATE
  ) RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_current_rs_base_code
   * Description      : 現所属拠点取得（ログインユーザー）
   ***********************************************************************************/
  FUNCTION  get_current_rs_base_code
  RETURN VARCHAR2;
  /* 2009.05.12 K.Satomura T1_0593対応 END */
--
  /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
  /**********************************************************************************
   * Function Name    : conv_ng_char_vdms
   * Description      : 自販機管理S禁則文字変換関数
   ***********************************************************************************/
  FUNCTION conv_ng_char_vdms(
    iv_char IN VARCHAR2 -- 文字列
  ) RETURN VARCHAR2;
  /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
--
END xxcso_util_common_pkg;
--
/
