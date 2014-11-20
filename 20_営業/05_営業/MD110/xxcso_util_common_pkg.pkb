CREATE OR REPLACE PACKAGE BODY APPS.xxcso_util_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_util_common_pkg(BODY)
 * Description      : 共通関数(XXCSOユーティリティ）
 * MD.050/070       :
 * Version          : 1.4
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
 *  get_rs_base_code          F    -     所属拠点取得
 *  get_current_rs_base_code  F    -     現所属拠点取得
 *  conv_ng_char_vdms         F    -     自販機管理S禁則文字変換関数
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Ogawa          新規作成
 *  2008/11/11    1.0   K.Hosoi          get_business_year(年度取得関数)を追記
 *  2008/11/19    1.0   H.Ogawa          get_lookup_info：基準日の検索条件を修正
 *  2008/11/25    1.0   H.Ogawa          get_lookup_info：返却値を設定
 *  2008/11/26    1.0   K.Hosoi          get_emp_parameter：id_issue_dateの型を
 *                                       DATEからVARCHAR2へ修正
 *  2008/11/26    1.0   H.Ogawa          拠点名取得関数で拠点名をdescriptionから
 *                                       attribute4に修正
 *  2008/12/04    1.0   K.Cho            check_date(日付書式チェック関数)を追記
 *  2008/12/04    1.0   H.Ogawa          get_emp_parameter：日付の書式を追加
 *  2008/12/08    1.0   T.Kyo            check_ar_gl_period_status:AR会計期間クローズチェック 
 *  2008/12/16    1.0   H.Ogawa          LOOKUP_TYPEのみでクイックコードを取得する関数を追加
 *  2008/12/16    1.0   H.Ogawa          get_online_sysdate(システム日付取得関数
 *                                        (オンライン用))を追加
 *  2008/12/19    1.0   M.maruyama       従業員パラメータ取得関数の発令日の'/'外す処理を削除し、
 *                                       型チェックを追加 合わせてissue_dateを150桁へ変更
 *  2008/12/24    1.0   M.maruyama       ヘッダ修正(Oracle版からSCS版へ)
 *  2009/01/15    1.0   T.maruyama       get_ar_gl_period_from（AR会計期間開始日取得関数）を追加
 *  2009/01/16    1.0   T.maruyama       chk_exe_report_visite_sales
 *                                       （訪問売上計画管理表出力判定関数）を追加
 *                                       get_working_days（営業日数取得関数）を追加
 *  2009/02/02    1.0   K.Boku           chk_responsibility新規作成
 *  2009/02/23    1.0   T.Mori           chk_exe_report_visite_sales（訪問売上計画管理表出力判定関数）に
 *                                       メッセージを追加
 *  2009/04/16    1.1   K.Satomura       conv_multi_byte新規作成(T1_0172対応)
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009/05/12    1.3   K.Satomura       get_rs_base_code
 *                                       get_current_rs_base_code 新規作成(T1_0593対応)
 *  2009/05/20    1.4   K.Satomura       T1_1082対応
 *  2009/12/14    1.5   T.Maruyama       conv_ng_char_vdms新規作成（E_本稼動_00469）
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_y                CONSTANT VARCHAR2(1)   := 'Y';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_util_common_pkg';   -- パッケージ名
--
   /**********************************************************************************
   * Function Name    : get_base_name
   * Description      : 拠点名取得関数
   ***********************************************************************************/
  FUNCTION get_base_name(
    iv_base_code             IN  VARCHAR2,               -- 拠点コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_base_name';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cn_gl_application_id         CONSTANT NUMBER          := 101;
    cv_flex_code                 CONSTANT VARCHAR2(3)     := 'GL#';
    cv_column_name               CONSTANT VARCHAR2(8)     := 'SEGMENT2';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_base_name                 fnd_flex_values_tl.description%TYPE;
    ld_standard_date             DATE;
--
  BEGIN
--
    IF ( id_standard_date IS NULL ) THEN
--
      ld_standard_date := SYSDATE;
--
    ELSE
--
      ld_standard_date := id_standard_date;
--
    END IF;
--
    -- 拠点名取得
    BEGIN
--
      SELECT   ffv.attribute4
      INTO     lv_base_name
      FROM     gl_sets_of_books        gsob
              ,fnd_id_flex_segments    fifs
              ,fnd_flex_values         ffv
      WHERE    ffv.flex_value                 = iv_base_code
        AND    gsob.set_of_books_id           = fnd_profile.value(cv_set_of_books_id)
        AND    fifs.application_id            = cn_gl_application_id
        AND    fifs.id_flex_code              = cv_flex_code
        AND    fifs.application_column_name   = cv_column_name
        AND    fifs.id_flex_num               = gsob.chart_of_accounts_id
        AND    ffv.flex_value_set_id          = fifs.flex_value_set_id
        AND    ffv.enabled_flag               = 'Y'
        AND    NVL(ffv.start_date_active, TRUNC(ld_standard_date)) <= TRUNC(ld_standard_date)
        AND    NVL(ffv.end_date_active,   TRUNC(ld_standard_date)) >= TRUNC(ld_standard_date)
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_base_name := NULL;
    END;
--
    RETURN lv_base_name;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_base_name;
--
   /**********************************************************************************
   * Function Name    : get_parent_base_code
   * Description      : 親拠点コード取得関数
   ***********************************************************************************/
  FUNCTION get_parent_base_code(
    iv_base_code             IN  VARCHAR2,               -- 拠点コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_parent_base_code';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cn_gl_application_id         CONSTANT NUMBER          := 101;
    cv_flex_code                 CONSTANT VARCHAR2(3)     := 'GL#';
    cv_column_name               CONSTANT VARCHAR2(8)     := 'SEGMENT2';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_parent_base_code          fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
    ld_standard_date             DATE;
--
  BEGIN
--
    IF ( id_standard_date IS NULL ) THEN
--
      ld_standard_date := SYSDATE;
--
    ELSE
--
      ld_standard_date := id_standard_date;
--
    END IF;
--
    -- 拠点名取得
    BEGIN
--
      SELECT   ffv.flex_value
      INTO     lv_parent_base_code
      FROM     gl_sets_of_books               gsob
              ,fnd_id_flex_segments           fifs
              ,fnd_flex_value_norm_hierarchy  ffvnh
              ,fnd_flex_values                ffv
      WHERE    ffvnh.child_flex_value_low     = iv_base_code
        AND    gsob.set_of_books_id           = fnd_profile.value(cv_set_of_books_id)
        AND    fifs.application_id            = cn_gl_application_id
        AND    fifs.id_flex_code              = cv_flex_code
        AND    fifs.application_column_name   = cv_column_name
        AND    fifs.id_flex_num               = gsob.chart_of_accounts_id
        AND    ffvnh.flex_value_set_id        = fifs.flex_value_set_id
        AND    ffv.flex_value                 = ffvnh.parent_flex_value
        AND    ffv.enabled_flag               = 'Y'
        AND    NVL(ffv.start_date_active, TRUNC(ld_standard_date)) <= TRUNC(ld_standard_date)
        AND    NVL(ffv.end_date_active,   TRUNC(ld_standard_date)) >= TRUNC(ld_standard_date)
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_parent_base_code := NULL;
    END;
--
    RETURN lv_parent_base_code;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_parent_base_code;
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
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_emp_parameter';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_parameter                 VARCHAR2(150);
    lv_issue_date                VARCHAR2(150);
    ld_issue_date                DATE;

--
  BEGIN
--
    
    lv_issue_date := iv_issue_date;  -- 初期化
    
    
    -- 型チェック
    
    BEGIN
      SELECT TO_DATE(lv_issue_date, 'YYYYMMDD')
      INTO   ld_issue_date
      FROM   DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;
  

--
    IF ( trunc(ld_issue_date) <= TRUNC(id_standard_date) ) THEN
--
     lv_parameter := iv_parameter_new;
--
    ELSE
--
     lv_parameter := iv_parameter_old;
--
    END IF;
--
    RETURN lv_parameter;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_emp_parameter;
--
   /**********************************************************************************
   * Function Name    : get_lookup_meaning(TYPEのみ)
   * Description      : クイックコード内容取得関数
   ***********************************************************************************/
  FUNCTION get_lookup_meaning(
    iv_lookup_type           IN  VARCHAR2,               -- タイプ
    iv_lookup_code           IN  VARCHAR2,               -- コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_meaning';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_meaning             fnd_lookup_values_vl.meaning%TYPE;
    lv_description         fnd_lookup_values_vl.description%TYPE;
    lv_attribute1          fnd_lookup_values_vl.attribute1%TYPE;
    lv_attribute2          fnd_lookup_values_vl.attribute2%TYPE;
    lv_attribute3          fnd_lookup_values_vl.attribute3%TYPE;
    lv_attribute4          fnd_lookup_values_vl.attribute4%TYPE;
    lv_attribute5          fnd_lookup_values_vl.attribute5%TYPE;
    lv_attribute6          fnd_lookup_values_vl.attribute6%TYPE;
    lv_attribute7          fnd_lookup_values_vl.attribute7%TYPE;
    lv_attribute8          fnd_lookup_values_vl.attribute8%TYPE;
    lv_attribute9          fnd_lookup_values_vl.attribute9%TYPE;
    lv_attribute10         fnd_lookup_values_vl.attribute10%TYPE;
    lv_attribute11         fnd_lookup_values_vl.attribute11%TYPE;
    lv_attribute12         fnd_lookup_values_vl.attribute12%TYPE;
    lv_attribute13         fnd_lookup_values_vl.attribute13%TYPE;
    lv_attribute14         fnd_lookup_values_vl.attribute14%TYPE;
    lv_attribute15         fnd_lookup_values_vl.attribute15%TYPE;
    lv_retcode             VARCHAR2(1);
    lv_errbuf              VARCHAR2(4000);
    lv_errmsg              VARCHAR2(4000);
--
  BEGIN
--
    -- クイックコード取得
    xxcso_util_common_pkg.get_lookup_info(
      iv_lookup_type              => iv_lookup_type
     ,iv_lookup_code              => iv_lookup_code
     ,id_standard_date            => id_standard_date
     ,ov_meaning                  => lv_meaning
     ,ov_description              => lv_description
     ,ov_attribute1               => lv_attribute1
     ,ov_attribute2               => lv_attribute2
     ,ov_attribute3               => lv_attribute3
     ,ov_attribute4               => lv_attribute4
     ,ov_attribute5               => lv_attribute5
     ,ov_attribute6               => lv_attribute6
     ,ov_attribute7               => lv_attribute7
     ,ov_attribute8               => lv_attribute8
     ,ov_attribute9               => lv_attribute9
     ,ov_attribute10              => lv_attribute10
     ,ov_attribute11              => lv_attribute11
     ,ov_attribute12              => lv_attribute12
     ,ov_attribute13              => lv_attribute13
     ,ov_attribute14              => lv_attribute14
     ,ov_attribute15              => lv_attribute15
     ,ov_errbuf                   => lv_errbuf
     ,ov_retcode                  => lv_retcode
     ,ov_errmsg                   => lv_errmsg
    );
--
    RETURN lv_meaning;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_lookup_meaning;
--
   /**********************************************************************************
   * Function Name    : get_lookup_description(TYPEのみ)
   * Description      : クイックコード摘要取得関数
   ***********************************************************************************/
  FUNCTION get_lookup_description(
    iv_lookup_type           IN  VARCHAR2,               -- タイプ
    iv_lookup_code           IN  VARCHAR2,               -- コード
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_description';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_meaning             fnd_lookup_values_vl.meaning%TYPE;
    lv_description         fnd_lookup_values_vl.description%TYPE;
    lv_attribute1          fnd_lookup_values_vl.attribute1%TYPE;
    lv_attribute2          fnd_lookup_values_vl.attribute2%TYPE;
    lv_attribute3          fnd_lookup_values_vl.attribute3%TYPE;
    lv_attribute4          fnd_lookup_values_vl.attribute4%TYPE;
    lv_attribute5          fnd_lookup_values_vl.attribute5%TYPE;
    lv_attribute6          fnd_lookup_values_vl.attribute6%TYPE;
    lv_attribute7          fnd_lookup_values_vl.attribute7%TYPE;
    lv_attribute8          fnd_lookup_values_vl.attribute8%TYPE;
    lv_attribute9          fnd_lookup_values_vl.attribute9%TYPE;
    lv_attribute10         fnd_lookup_values_vl.attribute10%TYPE;
    lv_attribute11         fnd_lookup_values_vl.attribute11%TYPE;
    lv_attribute12         fnd_lookup_values_vl.attribute12%TYPE;
    lv_attribute13         fnd_lookup_values_vl.attribute13%TYPE;
    lv_attribute14         fnd_lookup_values_vl.attribute14%TYPE;
    lv_attribute15         fnd_lookup_values_vl.attribute15%TYPE;
    lv_retcode             VARCHAR2(1);
    lv_errbuf              VARCHAR2(4000);
    lv_errmsg              VARCHAR2(4000);
--
  BEGIN
--
    -- クイックコード取得
    xxcso_util_common_pkg.get_lookup_info(
      iv_lookup_type              => iv_lookup_type
     ,iv_lookup_code              => iv_lookup_code
     ,id_standard_date            => id_standard_date
     ,ov_meaning                  => lv_meaning
     ,ov_description              => lv_description
     ,ov_attribute1               => lv_attribute1
     ,ov_attribute2               => lv_attribute2
     ,ov_attribute3               => lv_attribute3
     ,ov_attribute4               => lv_attribute4
     ,ov_attribute5               => lv_attribute5
     ,ov_attribute6               => lv_attribute6
     ,ov_attribute7               => lv_attribute7
     ,ov_attribute8               => lv_attribute8
     ,ov_attribute9               => lv_attribute9
     ,ov_attribute10              => lv_attribute10
     ,ov_attribute11              => lv_attribute11
     ,ov_attribute12              => lv_attribute12
     ,ov_attribute13              => lv_attribute13
     ,ov_attribute14              => lv_attribute14
     ,ov_attribute15              => lv_attribute15
     ,ov_errbuf                   => lv_errbuf
     ,ov_retcode                  => lv_retcode
     ,ov_errmsg                   => lv_errmsg
    );
--
    RETURN lv_description;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_lookup_description;
--
   /**********************************************************************************
   * Function Name    : get_lookup_attribute(TYPEのみ)
   * Description      : クイックコードDFF値取得関数
   ***********************************************************************************/
  FUNCTION get_lookup_attribute(
    iv_lookup_type           IN  VARCHAR2,               -- タイプ
    iv_lookup_code           IN  VARCHAR2,               -- コード
    in_dff_number            IN  NUMBER,                 -- DFF番号
    id_standard_date         IN  DATE                    -- 基準日
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_attribute';
    cn_dff1                      CONSTANT NUMBER          := 1;
    cn_dff2                      CONSTANT NUMBER          := 2;
    cn_dff3                      CONSTANT NUMBER          := 3;
    cn_dff4                      CONSTANT NUMBER          := 4;
    cn_dff5                      CONSTANT NUMBER          := 5;
    cn_dff6                      CONSTANT NUMBER          := 6;
    cn_dff7                      CONSTANT NUMBER          := 7;
    cn_dff8                      CONSTANT NUMBER          := 8;
    cn_dff9                      CONSTANT NUMBER          := 9;
    cn_dff10                     CONSTANT NUMBER          := 10;
    cn_dff11                     CONSTANT NUMBER          := 11;
    cn_dff12                     CONSTANT NUMBER          := 12;
    cn_dff13                     CONSTANT NUMBER          := 13;
    cn_dff14                     CONSTANT NUMBER          := 14;
    cn_dff15                     CONSTANT NUMBER          := 15;
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_meaning             fnd_lookup_values_vl.meaning%TYPE;
    lv_description         fnd_lookup_values_vl.description%TYPE;
    lv_attribute1          fnd_lookup_values_vl.attribute1%TYPE;
    lv_attribute2          fnd_lookup_values_vl.attribute2%TYPE;
    lv_attribute3          fnd_lookup_values_vl.attribute3%TYPE;
    lv_attribute4          fnd_lookup_values_vl.attribute4%TYPE;
    lv_attribute5          fnd_lookup_values_vl.attribute5%TYPE;
    lv_attribute6          fnd_lookup_values_vl.attribute6%TYPE;
    lv_attribute7          fnd_lookup_values_vl.attribute7%TYPE;
    lv_attribute8          fnd_lookup_values_vl.attribute8%TYPE;
    lv_attribute9          fnd_lookup_values_vl.attribute9%TYPE;
    lv_attribute10         fnd_lookup_values_vl.attribute10%TYPE;
    lv_attribute11         fnd_lookup_values_vl.attribute11%TYPE;
    lv_attribute12         fnd_lookup_values_vl.attribute12%TYPE;
    lv_attribute13         fnd_lookup_values_vl.attribute13%TYPE;
    lv_attribute14         fnd_lookup_values_vl.attribute14%TYPE;
    lv_attribute15         fnd_lookup_values_vl.attribute15%TYPE;
    lv_return_value        VARCHAR2(150);
    lv_retcode             VARCHAR2(1);
    lv_errbuf              VARCHAR2(4000);
    lv_errmsg              VARCHAR2(4000);
--
  BEGIN
--
    -- クイックコード取得
    xxcso_util_common_pkg.get_lookup_info(
      iv_lookup_type              => iv_lookup_type
     ,iv_lookup_code              => iv_lookup_code
     ,id_standard_date            => id_standard_date
     ,ov_meaning                  => lv_meaning
     ,ov_description              => lv_description
     ,ov_attribute1               => lv_attribute1
     ,ov_attribute2               => lv_attribute2
     ,ov_attribute3               => lv_attribute3
     ,ov_attribute4               => lv_attribute4
     ,ov_attribute5               => lv_attribute5
     ,ov_attribute6               => lv_attribute6
     ,ov_attribute7               => lv_attribute7
     ,ov_attribute8               => lv_attribute8
     ,ov_attribute9               => lv_attribute9
     ,ov_attribute10              => lv_attribute10
     ,ov_attribute11              => lv_attribute11
     ,ov_attribute12              => lv_attribute12
     ,ov_attribute13              => lv_attribute13
     ,ov_attribute14              => lv_attribute14
     ,ov_attribute15              => lv_attribute15
     ,ov_errbuf                   => lv_errbuf
     ,ov_retcode                  => lv_retcode
     ,ov_errmsg                   => lv_errmsg
    );
--
    IF ( in_dff_number = cn_dff1 ) THEN
--
     lv_return_value := lv_attribute1;
--
    ELSIF ( in_dff_number = cn_dff2 ) THEN
--
     lv_return_value := lv_attribute2;
--
    ELSIF ( in_dff_number = cn_dff3 ) THEN
--
     lv_return_value := lv_attribute3;
--
    ELSIF ( in_dff_number = cn_dff4 ) THEN
--
     lv_return_value := lv_attribute4;
--
    ELSIF ( in_dff_number = cn_dff5 ) THEN
--
     lv_return_value := lv_attribute5;
--
    ELSIF ( in_dff_number = cn_dff6 ) THEN
--
     lv_return_value := lv_attribute6;
--
    ELSIF ( in_dff_number = cn_dff7 ) THEN
--
     lv_return_value := lv_attribute7;
--
    ELSIF ( in_dff_number = cn_dff8 ) THEN
--
     lv_return_value := lv_attribute8;
--
    ELSIF ( in_dff_number = cn_dff9 ) THEN
--
     lv_return_value := lv_attribute9;
--
    ELSIF ( in_dff_number = cn_dff10 ) THEN
--
     lv_return_value := lv_attribute10;
--
    ELSIF ( in_dff_number = cn_dff11 ) THEN
--
     lv_return_value := lv_attribute11;
--
    ELSIF ( in_dff_number = cn_dff12 ) THEN
--
     lv_return_value := lv_attribute12;
--
    ELSIF ( in_dff_number = cn_dff13 ) THEN
--
     lv_return_value := lv_attribute13;
--
    ELSIF ( in_dff_number = cn_dff14 ) THEN
--
     lv_return_value := lv_attribute14;
--
    ELSIF ( in_dff_number = cn_dff15 ) THEN
--
     lv_return_value := lv_attribute15;
--
    ELSE
--
     lv_return_value := NULL;
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
  END get_lookup_attribute;
--
   /**********************************************************************************
   * Function Name    : get_lookup_info(TYPEのみ)
   * Description      : クイックコード取得処理
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
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_info';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_standard_date       DATE;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- 基準日チェック
    IF ( id_standard_date IS NULL ) THEN
--
     ld_standard_date := SYSDATE;
--
    ELSE
--
     ld_standard_date := id_standard_date;
--
    END IF;
--
    -- クイックコード取得
    SELECT   flvv.meaning
            ,flvv.description
            ,flvv.attribute1
            ,flvv.attribute2
            ,flvv.attribute3
            ,flvv.attribute4
            ,flvv.attribute5
            ,flvv.attribute6
            ,flvv.attribute7
            ,flvv.attribute8
            ,flvv.attribute9
            ,flvv.attribute10
            ,flvv.attribute11
            ,flvv.attribute12
            ,flvv.attribute13
            ,flvv.attribute14
            ,flvv.attribute15
    INTO     ov_meaning
            ,ov_description
            ,ov_attribute1
            ,ov_attribute2
            ,ov_attribute3
            ,ov_attribute4
            ,ov_attribute5
            ,ov_attribute6
            ,ov_attribute7
            ,ov_attribute8
            ,ov_attribute9
            ,ov_attribute10
            ,ov_attribute11
            ,ov_attribute12
            ,ov_attribute13
            ,ov_attribute14
            ,ov_attribute15
    FROM     fnd_lookup_values_vl   flvv
    WHERE    flvv.lookup_type                 = iv_lookup_type
      AND    flvv.lookup_code                 = iv_lookup_code
      AND    flvv.enabled_flag                = 'Y'
      AND    NVL(flvv.start_date_active, TRUNC(ld_standard_date)) <= TRUNC(ld_standard_date)
      AND    NVL(flvv.end_date_active,   TRUNC(ld_standard_date)) >= TRUNC(ld_standard_date)
    ;
--
  EXCEPTION
    -- *** データなし ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errbuf     := xxcso_common_pkg.gv_no_data_error_msg;
      ov_errmsg     := NULL;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_lookup_info;
--
   /**********************************************************************************
   * Function Name    : get_business_year
   * Description      : 年度取得関数
   ***********************************************************************************/
  FUNCTION get_business_year(
    iv_year_month      IN  VARCHAR2                      -- 年月
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_business_year';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cv_first_date                CONSTANT VARCHAR2(2)     := '01';
    cv_no                        CONSTANT VARCHAR2(1)     := 'N';
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    ln_business_year             gl_periods.period_year%TYPE;
--
  BEGIN
--
    SELECT glp.period_year
    INTO   ln_business_year
    FROM   gl_periods  glp
          ,gl_sets_of_books  gls
    WHERE  glp.period_set_name = gls.period_set_name
      AND  gls.set_of_books_id = fnd_profile.value(cv_set_of_books_id)
      AND  glp.start_date <= TO_DATE(iv_year_month || cv_first_date, 'yyyymmdd')
      AND  glp.end_date   >= TO_DATE(iv_year_month || cv_first_date, 'yyyymmdd')
      AND  glp.adjustment_period_flag = cv_no
    ;
--
    RETURN ln_business_year;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN  NULL;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_business_year;
--
  /**********************************************************************************
   * Function Name    : check_date
   * Description      : 日付書式チェック関数
   ***********************************************************************************/
  FUNCTION check_date(
    iv_date         IN  VARCHAR2,                     -- 日付入力欄に入力された値
    iv_date_format  IN  VARCHAR2                      -- 日付フォーマット（書式文字列）
  )
  RETURN BOOLEAN
  IS
    -- *** ローカル変数 ***
    ln_convert_temp    DATE;   -- 変換チェック用一時領域
--
  BEGIN
--
    ln_convert_temp := TO_DATE(iv_date, iv_date_format);

    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END check_date;
--
   /**********************************************************************************
   * Function Name    : check_ar_gl_period_status
   * Description      : AR会計期間クローズチェック
   ***********************************************************************************/
  FUNCTION check_ar_gl_period_status(
    id_standard_date         IN  DATE                    -- チェック対象日
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'check_ar_gl_period_status';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cv_app_short_name            CONSTANT VARCHAR2(2)     := 'AR';
    cv_closing_status_c          CONSTANT VARCHAR2(1)     := 'C';
    cv_adjmt_period_flag         CONSTANT VARCHAR2(1)     := 'N';
    cv_true                      CONSTANT VARCHAR2(4)     := 'TRUE';
    cv_false                     CONSTANT VARCHAR2(5)     := 'FALSE';  
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_standard_date             DATE;
    ln_books_id                  NUMBER;
    ln_gl_period_closed_cnt      NUMBER;
--
  BEGIN
--
    IF ( id_standard_date IS NULL ) THEN
--
      RETURN cv_false;
--
    ELSE
--
      ld_standard_date := TRUNC(id_standard_date);
      ln_books_id      := FND_PROFILE.VALUE(cv_set_of_books_id);
--
    END IF;
--
    -- カウント数取得
--
    SELECT COUNT(*) cnt
    INTO   ln_gl_period_closed_cnt
    FROM   gl_period_statuses gps
          ,fnd_application fa
    WHERE  gps.set_of_books_id        = ln_books_id
      AND  fa.application_id          = gps.application_id
      AND  fa.application_short_name  = cv_app_short_name
      AND  gps.adjustment_period_flag = cv_adjmt_period_flag
      AND  gps.closing_status         = cv_closing_status_c
      AND  ld_standard_date BETWEEN gps.start_date AND gps.end_date
    ;
--
    IF ( ln_gl_period_closed_cnt > 0 ) THEN
      RETURN cv_false;
    ELSE
      RETURN cv_true;
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
  END check_ar_gl_period_status;
--
   /**********************************************************************************
   * Function Name    : get_online_sysdate
   * Description      : システム日付取得関数（オンライン用）
   ***********************************************************************************/
  FUNCTION get_online_sysdate
  RETURN DATE
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'check_ar_gl_period_status';
  BEGIN
--
    RETURN xxccp_common_pkg2.get_process_date;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_online_sysdate;
--
   /**********************************************************************************
   * Function Name    : get_ar_gl_period_from
   * Description      : AR会計期間開始日取得関数
   ***********************************************************************************/
  FUNCTION get_ar_gl_period_from
  RETURN DATE
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_ar_gl_period_from';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cv_app_short_name            CONSTANT VARCHAR2(2)     := 'AR';
    cv_closing_status_open       CONSTANT VARCHAR2(1)     := 'O';
    cv_adjmt_period_flag         CONSTANT VARCHAR2(1)     := 'N';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_start_date                DATE;
--
  BEGIN
--
    BEGIN
      --オープン中の会計期間の一番古い開始日を取得
      SELECT min(gps.start_date) start_date  -- 開始日
      INTO   ld_start_date
      FROM   gl_period_statuses gps          -- 会計期間ステータス
            ,fnd_application fa
      WHERE  gps.set_of_books_id        = FND_PROFILE.VALUE(cv_set_of_books_id)
        AND  fa.application_id          = gps.application_id
        AND  fa.application_short_name  = cv_app_short_name
        AND  gps.adjustment_period_flag = cv_adjmt_period_flag
        AND  gps.closing_status         = cv_closing_status_open;
--  
    EXCEPTION
      WHEN OTHERS THEN
        ld_start_date := NULL;
    END;
--
    RETURN ld_start_date;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_ar_gl_period_from;
--
   /**********************************************************************************
   * Function Name    : chk_exe_report_visite_sales
   * Description      : 訪問売上計画管理表出力判定関数
   ***********************************************************************************/
  PROCEDURE chk_exe_report_visite_sales(
    in_user_id               IN  NUMBER                  -- ログインユーザＩＤ
   ,in_resp_id               IN  NUMBER                  -- ログイン者職責ＩＤ
   ,iv_base_code             IN  VARCHAR2                -- 拠点コード（参照先）
   ,iv_report_type           IN  VARCHAR2                -- 帳票種別
   ,ov_ret_code              OUT VARCHAR2                -- 判定結果（'TRUE’／’FALSE’）
   ,ov_err_msg               OUT VARCHAR2                -- エラー理由
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_exe_report_visite_sales';
    cv_true                      CONSTANT VARCHAR2(10)    := 'TRUE';
    cv_false                     CONSTANT VARCHAR2(10)    := 'FALSE';
    cv_auto_loolup_type          CONSTANT VARCHAR2(100)   := 'XXCSO1_VST_SLS_REP_AUTH_CTRL';
    cv_process_date              CONSTANT DATE := xxcso_util_common_pkg.get_online_sysdate;
    cv_c_null                    CONSTANT VARCHAR2(100)   := 'XXXXXXXXXX'; --nullの代替値
    cv_any_char                  CONSTANT VARCHAR2(100)   := '*';
    --帳票タイプ
    cv_rep_eigyouin              CONSTANT VARCHAR2(1)     := '1'; -- 営業員別
    cv_rep_group                 CONSTANT VARCHAR2(1)     := '2'; -- 営業員グループ別
    cv_rep_kyoten                CONSTANT VARCHAR2(1)     := '3'; -- 拠点／課別
    cv_rep_chiku                 CONSTANT VARCHAR2(1)     := '4'; -- 地区営業部／部別
    cv_rep_honbu                 CONSTANT VARCHAR2(1)     := '5'; -- 地域営業本部
    --アプリケーション短縮名
    cv_app_name                  CONSTANT VARCHAR2(100)   := 'XXCSO';
    --メッセージ
    cv_msg_number_01             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00535';
        -- 情報取得エラーメッセージ
    cv_msg_number_02             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00536';
        -- 訪問売上計画管理表出力権限情報取得エラーメッセージ
    cv_msg_number_03             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00537';
        -- 訪問売上計画管理表出力権限情報NULLエラーメッセージ
    cv_msg_number_04             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00538';
        -- 出力権限チェックエラーメッセージ（ログイン者）
    cv_msg_number_05             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00539';
        -- 出力権限チェックエラーメッセージ
    cv_msg_number_06             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00540';
        -- ＡＦＦ部門階層情報取得エラーメッセージ
    cv_msg_number_07             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00382';
        -- パラメータ入力チェックエラーメッセージ
    --トークン名
    cv_tkn_info             CONSTANT VARCHAR2(100)   := 'INFO';  -- 
    cv_tkn_item             CONSTANT VARCHAR2(100)   := 'ITEM';  -- 
    cv_tkn_resp_name        CONSTANT VARCHAR2(100)   := 'RESP_NAME';  -- 
    cv_tkn_posit_cd         CONSTANT VARCHAR2(100)   := 'POSIT_CD';  -- 
    cv_tkn_job_type_cd      CONSTANT VARCHAR2(100)   := 'JOB_TYPE_CD';  -- 
    cv_tkn_base_code        CONSTANT VARCHAR2(100)   := 'BASE_CODE';  -- 
    cv_tkn_err_msg          CONSTANT VARCHAR2(100)   := 'ERR_MSG';  -- 
    --
    cv_tkn_msg_job_type     CONSTANT VARCHAR2(100)   := '職責情報';  -- 
    cv_tkn_msg_job_nm       CONSTANT VARCHAR2(100)   := '職責名';  -- 
    cv_tkn_msg_resorce_vw   CONSTANT VARCHAR2(100)   := 'リソースマスタ（最新）ビュー';  -- 
    cv_tkn_msg_emp_info     CONSTANT VARCHAR2(100)   := '従業員情報';  -- 
    cv_tkn_msg_report_type  CONSTANT VARCHAR2(100)   := '帳票種別';  -- 
    cv_tkn_msg_base         CONSTANT VARCHAR2(100)   := '拠点';  -- 
    cv_tkn_msg_errmsg1      CONSTANT VARCHAR2(100)   := '（階層レベル範囲外）';  -- 
    cv_tkn_msg_errmsg2      CONSTANT VARCHAR2(100)   := '（非直轄範囲）';  -- 
    cv_tkn_msg_base2        CONSTANT VARCHAR2(100)   := '指定した拠点';  -- 
    cv_tkn_msg_base3        CONSTANT VARCHAR2(100)   := 'ログイン者の拠点';  -- 
    -- ===============================
    -- ローカル変数
    -- ===============================
    lt_resp_key       fnd_responsibility_vl.responsibility_key%type; -- 職責名
    lt_resp_name      fnd_responsibility_vl.responsibility_name%type; -- 職責名
    lt_position_code  xxcso_resources_v2.position_code_new%type; -- 職位コード
    lt_job_type_code  xxcso_resources_v2.job_type_code_new%type; -- 職種コード
    lt_work_base_code xxcso_resources_v2.work_base_code_new%type; -- 勤務地拠点コード
    lv_max_rep_kind   VARCHAR2(1); -- 出力可能帳票種別
    lv_max_base_lavel VARCHAR2(1); -- 出力可能部門階層レベル
    lt_my_parent_base_cd    xxcso_aff_base_level_v2.base_code%type; 
                                    --ログインユーザー拠点の階層上位拠点情報
    lt_param_parent_base_cd xxcso_aff_base_level_v2.base_code%type;
                                    --パラメータ拠点の階層上位拠点情報
    
    
  BEGIN
--
    ------------------------------------------------------
    --パラメータ入力チェック
    ------------------------------------------------------
    --INパラメータ：帳票種別入力チェック
    IF (iv_report_type IS NULL) THEN
      ov_ret_code := cv_false;
      ov_err_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_number_07
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_tkn_msg_report_type
                      );
      RETURN;
    END IF;
--
    ------------------------------------------------------
    --ログイン者基本情報取得
    ------------------------------------------------------
    --ログイン職責名称取得
    BEGIN
      SELECT  frv.responsibility_key  responsibility_key  --職責キー
      ,       frv.responsibility_name responsibility_name --職責名
      INTO    lt_resp_key
      ,       lt_resp_name
      FROM    fnd_responsibility_vl frv 
      WHERE   frv.responsibility_id = in_resp_id; --職責ＩＤ
    EXCEPTION
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_01
                         ,iv_token_name1  => cv_tkn_info
                         ,iv_token_value1 => cv_tkn_msg_job_type
                         ,iv_token_name2  => cv_tkn_item
                         ,iv_token_value2 => cv_tkn_msg_job_nm
                        );
        RETURN;
    END;
--
    --ログインユーザー情報取得
    BEGIN
      SELECT  CASE 
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.position_code_new
              ELSE
                xrv2.position_code_old
              END position_code        -- 職位ＣＤ
      ,       CASE 
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.job_type_code_new
              ELSE
                xrv2.job_type_code_old
              END job_type_code        -- 職種ＣＤ
      ,       CASE 
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.work_base_code_new
              ELSE
                xrv2.work_base_code_old
              END work_base_code       -- 拠点ＣＤ
      INTO    lt_position_code
      ,       lt_job_type_code
      ,       lt_work_base_code
      FROM    xxcso_resources_v2 xrv2    -- リソースマスタ（最新）ビュー
      WHERE   xrv2.user_id = in_user_id; -- ユーザーＩＤ
    EXCEPTION
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_01
                         ,iv_token_name1  => cv_tkn_info
                         ,iv_token_value1 => cv_tkn_msg_resorce_vw
                         ,iv_token_name2  => cv_tkn_item
                         ,iv_token_value2 => cv_tkn_msg_emp_info
                        );
        RETURN;
    END;
--
    ------------------------------------------------------
    --参照タイプから訪問売上計画管理表出力権限情報を取得
    ------------------------------------------------------
    --以下の条件にて対照の権限情報を取得する--------------
    --attribute3=ログイン者の職責キー
    --attribute4=ログイン者の職位ＣＤ
    --attribute5=ログイン者の職種ＣＤ
    ------------------------------------------------------
    --attribute4,attribute5の条件について
    --１．'*'が設定されている場合、条件を無視（ワイルドカード）
    --２．未設定（null）の場合は、ログイン者のＣＤもnullにて一致
    ------------------------------------------------------
    BEGIN 
      SELECT flv.attribute1 max_rep_kind   -- 出力可能帳票種別
      ,      flv.attribute2 max_base_lavel -- 出力可能部門階層レベル
      into   lv_max_rep_kind
      ,      lv_max_base_lavel
      FROM   fnd_lookup_values_vl flv      -- 参照タイプ
      WHERE  flv.lookup_type  = cv_auto_loolup_type
      AND    flv.enabled_flag = 'Y'
      AND    TRUNC(cv_process_date) 
             BETWEEN TRUNC(nvl(flv.start_date_active, cv_process_date)) 
                 AND TRUNC(nvl(flv.end_date_active, cv_process_date))
      AND    flv.attribute3   = lt_resp_key                          -- 職責キー
      AND    DECODE(flv.attribute4, NULL, cv_c_null
                                  , cv_any_char, nvl(lt_position_code,cv_c_null)
                                  , flv.attribute4) 
                                             = nvl(lt_position_code,cv_c_null)  --職位ＣＤ
      AND    DECODE(flv.attribute5, NULL, cv_c_null
                                  , cv_any_char, nvl(lt_job_type_code,cv_c_null)
                                  , flv.attribute5)
                                             = nvl(lt_job_type_code,cv_c_null)  --職種ＣＤ
      ;    
    EXCEPTION
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_02
                         ,iv_token_name1  => cv_tkn_resp_name
                         ,iv_token_value1 => lt_resp_key  -- 職責キー
                         ,iv_token_name2  => cv_tkn_posit_cd
                         ,iv_token_value2 => lt_position_code  --職位ＣＤ
                         ,iv_token_name3  => cv_tkn_job_type_cd
                         ,iv_token_value3 => lt_job_type_code  --職種ＣＤ
                        );
        RETURN;
    END;    
--
    IF ( lv_max_rep_kind IS NULL ) OR ( lv_max_base_lavel IS NULL ) THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_03
                        );
        RETURN;    
    END IF;
--
    ------------------------------------------------------
    --権限チェック：帳票種別
    ------------------------------------------------------
    --出力可能帳票種別より大きい場合エラー
    IF ( iv_report_type > lv_max_rep_kind ) THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_05
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => cv_tkn_msg_report_type
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => NULL
                        );
        RETURN;
    END IF;
--
    ------------------------------------------------------
    --権限チェック：指定拠点階層レベル
    ------------------------------------------------------
    --※以下、基準拠点＝（ログイン者の拠点およびパラメータの拠点）
    --１．パラメータ拠点から系列の出力可能部門階層レベルにあたる
    --    拠点ＣＤを取得。
    --２．"１"が取得できない（出力可能レベル範囲外）もしくは
    --    ログイン者の同一階層拠点ＣＤと不一致（＝管轄系統が異なる）
    --    の場合、エラー。
    ------------------------------------------------------
    --１．パラメータ拠点から系列の出力可能部門階層レベルにあたる拠点ＣＤ取得
    BEGIN
      SELECT v.base_code
      INTO   lt_param_parent_base_cd
      FROM   (
               --基準拠点から上位拠点を再帰で最上位まで取得
               --（基準拠点は子としてスタートするため親には出てこない）
               SELECT  ROWNUM kaisou_level --階層レベル
               ,       up_base.base_code   --拠点ＣＤ
               FROM   (
                       SELECT level           sqllev
                       ,      xabl1.base_code base_code
                       FROM   xxcso_aff_base_level_v2 xabl1 --AFF部門階層ビュー（最新）
                       START WITH xabl1.child_base_code = iv_base_code  --基準拠点
                       CONNECT BY PRIOR xabl1.base_code = xabl1.child_base_code
                       ORDER BY level DESC
                      ) up_base
               UNION
               --基準拠点を最下層としてUNION（基準拠点は子としてスタートするため）
               SELECT (
                       SELECT NVL(MAX(xabl3.sqllev), 0) + 1  max_level
                       FROM  (
                              --基準拠点から上位拠点を再帰で取得
                              SELECT level           sqllev
                              ,      xabl2.base_code base_code
                              FROM   xxcso_aff_base_level_v2 xabl2 --AFF部門階層ビュー（最新）
                              START WITH xabl2.child_base_code = iv_base_code  --基準拠点
                              CONNECT BY PRIOR xabl2.base_code = xabl2.child_base_code
                              ORDER BY level DESC
                             ) xabl3
                      ) kaisou_level
                     ,iv_base_code  base_code  --基準拠点
               FROM DUAL
              ) v
        WHERE v.kaisou_level = TO_NUMBER(lv_max_base_lavel); --階層レベル
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_05
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => cv_tkn_msg_base
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => cv_tkn_msg_errmsg1
                        );
        RETURN;      
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_06
                         ,iv_token_name1  => cv_tkn_base_code
                         ,iv_token_value1 => cv_tkn_msg_base2
                        );
        RETURN;    
    END;
--
    --２．ログイン者の拠点から系列の出力可能部門階層レベルにあたる拠点ＣＤ取得
    BEGIN
      SELECT v.base_code
      INTO   lt_my_parent_base_cd
      FROM   (
               --基準拠点から上位拠点を再帰で最上位まで取得
               --（基準拠点は子としてスタートするため親には出てこない）
               SELECT  ROWNUM kaisou_level --階層レベル
               ,       up_base.base_code   --拠点ＣＤ
               FROM   (
                       SELECT level           sqllev
                       ,      xabl1.base_code base_code
                       FROM   xxcso_aff_base_level_v2 xabl1 --AFF部門階層ビュー（最新）
                       START WITH xabl1.child_base_code = lt_work_base_code  --基準拠点
                       CONNECT BY PRIOR xabl1.base_code = xabl1.child_base_code
                       ORDER BY level DESC
                      ) up_base
               UNION
               --基準拠点を最下層としてUNION（基準拠点は子としてスタートするため）
               SELECT (
                       SELECT NVL(MAX(xabl3.sqllev), 0) + 1  max_level
                       FROM  (
                              --基準拠点から上位拠点を再帰で取得
                              SELECT level           sqllev
                              ,      xabl2.base_code base_code
                              FROM   xxcso_aff_base_level_v2 xabl2 --AFF部門階層ビュー（最新）
                              START WITH xabl2.child_base_code = lt_work_base_code --	
                              CONNECT BY PRIOR xabl2.base_code = xabl2.child_base_code
                              ORDER BY level DESC
                             ) xabl3
                      ) kaisou_level
                     ,lt_work_base_code  base_code  --基準拠点
               FROM DUAL
              ) v
        WHERE v.kaisou_level = TO_NUMBER(lv_max_base_lavel); --階層レベル
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_04
                        );
        RETURN;      
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_06
                         ,iv_token_name1  => cv_tkn_base_code
                         ,iv_token_value1 => cv_tkn_msg_base3
                        );
        RETURN;    
    END;
--
    --２．ログイン者拠点と指定拠点の同一階層レベル拠点ＣＤを比較
    IF ( lt_param_parent_base_cd <> lt_my_parent_base_cd ) THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_05
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => cv_tkn_msg_base
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => cv_tkn_msg_errmsg2
                        );
        RETURN;     
    END IF;
--
    ov_ret_code := cv_true;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_exe_report_visite_sales;
--
   /**********************************************************************************
   * Function Name    : get_working_days
   * Description      : 営業日数取得関数
   ***********************************************************************************/
  FUNCTION get_working_days(
    id_from_date             IN  DATE                    -- 基点日付
   ,id_to_date               IN  DATE                    -- 終点日付
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_working_days';
    cv_profile_name              CONSTANT VARCHAR2(100)   := 'XXCCP1_WORKING_CALENDAR';
    -- ===============================
    -- ローカル変数
    -- ===============================
    --**ローカル変数**
    ln_working_days      NUMBER;
  BEGIN
    --カレンダから稼働日をカウント
    SELECT count(*) cnt
    INTO   ln_working_days
    FROM   bom_calendar_dates bcd
    WHERE  bcd.calendar_code = FND_PROFILE.VALUE(cv_profile_name)
    AND    bcd.seq_num IS NOT NULL
    AND    bcd.calendar_date BETWEEN TRUNC(id_from_date) AND TRUNC(id_to_date)
    ;
--    
    RETURN ln_working_days;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_working_days;
--
   /**********************************************************************************
   * Function Name    : chk_responsibility
   * Description      : ログイン者職責判定関数
   *                    訪問売上計画管理表出力権限の参照タイプを利用し、
   *                    ログインユーザＩＤ、職責ＩＤより、
   *                    営業員または、営業員グループ長か判定する。
   ***********************************************************************************/
  FUNCTION chk_responsibility(
    in_user_id               IN  NUMBER                  -- ログインユーザＩＤ
   ,in_resp_id               IN  NUMBER                  -- 職位ＩＤ
   ,iv_report_type           IN  VARCHAR2                -- 帳票タイプ（1:営業員別、2:営業員グループ別、その他は指定不可）
  ) RETURN VARCHAR2                                      -- 'TRUE':チェックＯＫ 'FALSE':チェックＮＧ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_responsibility';
    cv_auto_loolup_type          CONSTANT VARCHAR2(100)   := 'XXCSO1_VST_SLS_REP_AUTH_CTRL';
    cv_process_date              CONSTANT DATE := xxcso_util_common_pkg.get_online_sysdate;
    cv_c_null                    CONSTANT VARCHAR2(100)   := 'XXXXXXXXXX'; --nullの代替値
    cv_any_char                  CONSTANT VARCHAR2(100)   := '*';
    cv_true                      CONSTANT VARCHAR2(4)     := 'TRUE';
    cv_false                     CONSTANT VARCHAR2(5)     := 'FALSE';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lt_resp_key       fnd_responsibility_vl.responsibility_name%type; -- 職責キー
    lt_position_code  xxcso_resources_v2.position_code_new%type; -- 職位コード
    lt_job_type_code  xxcso_resources_v2.job_type_code_new%type; -- 職種コード
    lv_max_rep_kind   VARCHAR2(1); -- 出力可能帳票種別
--
--
  BEGIN
--
    ------------------------------------------------------
    --ログイン者基本情報取得
    ------------------------------------------------------
    --ログイン職責名称取得
    SELECT  frv.responsibility_key  responsibility_key --職責キー
      INTO  lt_resp_key
      FROM  fnd_responsibility_vl frv 
     WHERE  frv.responsibility_id = in_resp_id; --職責ＩＤ
--
    --ログインユーザー情報取得
    SELECT  CASE
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.position_code_new
              ELSE
                xrv2.position_code_old
            END position_code        -- 職位ＣＤ
           ,CASE
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.job_type_code_new
              ELSE
                xrv2.job_type_code_old
            END job_type_code        -- 職種ＣＤ
      INTO  lt_position_code
           ,lt_job_type_code
      FROM  xxcso_resources_v2 xrv2    -- リソースマスタ（最新）ビュー
     WHERE  xrv2.user_id = in_user_id; -- ユーザーＩＤ
--
    ------------------------------------------------------
    --参照タイプから訪問売上計画管理表出力権限情報を取得
    ------------------------------------------------------
    --以下の条件にて対照の権限情報を取得する--------------
    --attribute3=ログイン者の職責名
    --attribute4=ログイン者の職位ＣＤ
    --attribute5=ログイン者の職種ＣＤ
    ------------------------------------------------------
    --attribute4,attribute5の条件について
    --１．'*'が設定されている場合、条件を無視（ワイルドカード）
    --２．未設定（null）の場合は、ログイン者のＣＤもnullにて一致
    ------------------------------------------------------
    SELECT flv.attribute1 max_rep_kind   -- 出力可能帳票種別
    into   lv_max_rep_kind
    FROM   fnd_lookup_values_vl flv      -- 参照タイプ
    WHERE  flv.lookup_type  = cv_auto_loolup_type
    AND    flv.enabled_flag = 'Y'
    AND    TRUNC(cv_process_date) 
           BETWEEN TRUNC(nvl(flv.start_date_active, cv_process_date)) 
               AND TRUNC(nvl(flv.end_date_active, cv_process_date))
    AND    flv.attribute3   = lt_resp_key                          -- 職責キー
    AND    DECODE(flv.attribute4, NULL, cv_c_null, cv_any_char, nvl(lt_position_code,cv_c_null), flv.attribute4) 
                                           = nvl(lt_position_code,cv_c_null)  --職位ＣＤ
    AND    DECODE(flv.attribute5, NULL, cv_c_null, cv_any_char, nvl(lt_job_type_code,cv_c_null), flv.attribute5)
                                           = nvl(lt_job_type_code,cv_c_null)  --職種ＣＤ
    AND    ROWNUM = 1
    ;
--
    IF ( lv_max_rep_kind IS NULL ) THEN
        RETURN cv_false;
    END IF;
--
    ------------------------------------------------------
    --権限チェック：帳票種別
    ------------------------------------------------------
    IF ( iv_report_type <> lv_max_rep_kind ) THEN
        RETURN cv_false;
    END IF;
--
    RETURN cv_true;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** NO_DATA_FOUNDハンドラ ***
    WHEN NO_DATA_FOUND THEN
      RETURN cv_false;

    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_responsibility;
--
  /* 2009.04.16 K.Satomura T1_0172対応 START */
  /**********************************************************************************
   * Function Name    : conv_multi_byte
   * Description      :半角文字全角置換関数
   ***********************************************************************************/
  FUNCTION conv_multi_byte(
    iv_char IN VARCHAR2 -- 文字列
  ) RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'conv_multi_byte';
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_char   VARCHAR2(5000);
    lv_return VARCHAR2(5000);
    --
  BEGIN
    --
    lv_char   := iv_char;
    lv_return := NULL;
    --
    IF (lv_char IS NULL) THEN
      RETURN NULL;
      --
    END IF;
    --
    -- 濁点・半濁付き文字の置換
    IF (INSTRB(lv_char, 'ﾞ') > 0
      OR INSTRB(lv_char, 'ﾟ') > 0)
    THEN
      lv_char := REPLACE(lv_char, 'ｶﾞ', 'ガ');
      lv_char := REPLACE(lv_char, 'ｷﾞ', 'ギ');
      lv_char := REPLACE(lv_char, 'ｸﾞ', 'グ');
      lv_char := REPLACE(lv_char, 'ｹﾞ', 'ゲ');
      lv_char := REPLACE(lv_char, 'ｺﾞ', 'ゴ');
      lv_char := REPLACE(lv_char, 'ｻﾞ', 'ザ');
      lv_char := REPLACE(lv_char, 'ｼﾞ', 'ジ');
      lv_char := REPLACE(lv_char, 'ｽﾞ', 'ズ');
      lv_char := REPLACE(lv_char, 'ｾﾞ', 'ゼ');
      lv_char := REPLACE(lv_char, 'ｿﾞ', 'ゾ');
      lv_char := REPLACE(lv_char, 'ﾀﾞ', 'ダ');
      lv_char := REPLACE(lv_char, 'ﾁﾞ', 'ヂ');
      lv_char := REPLACE(lv_char, 'ﾂﾞ', 'ヅ');
      lv_char := REPLACE(lv_char, 'ﾃﾞ', 'デ');
      lv_char := REPLACE(lv_char, 'ﾄﾞ', 'ド');
      lv_char := REPLACE(lv_char, 'ﾊﾞ', 'バ');
      lv_char := REPLACE(lv_char, 'ﾋﾞ', 'ビ');
      lv_char := REPLACE(lv_char, 'ﾌﾞ', 'ブ');
      lv_char := REPLACE(lv_char, 'ﾍﾞ', 'ベ');
      lv_char := REPLACE(lv_char, 'ﾎﾞ', 'ボ');
      lv_char := REPLACE(lv_char, 'ﾊﾟ', 'パ');
      lv_char := REPLACE(lv_char, 'ﾋﾟ', 'ピ');
      lv_char := REPLACE(lv_char, 'ﾌﾟ', 'プ');
      lv_char := REPLACE(lv_char, 'ﾍﾟ', 'ペ');
      lv_char := REPLACE(lv_char, 'ﾎﾟ', 'ポ');
      --
    END IF;
    --
    -- 半角カナ文字・半角英数字の置換
    lv_char := TRANSLATE(lv_char
               ,'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝｧｨｩｪｫｬｭｮｯｰ' ||
                'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '
               ,'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンァィゥェォャュョッー' ||
                'ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ' ||
                '０１２３４５６７８９　');
               --
    -- その他の半角文字の置換
    FOR i IN 1..LENGTH(lv_char) LOOP
      IF (LENGTHB(SUBSTR(lv_char, i, 1)) = 1) THEN
        -- １文字が１バイトの場合
        lv_return := lv_return || '＊';
        --
      ELSE
        lv_return := lv_return || SUBSTR(lv_char, i, 1);
        --
      END IF;
      --
    END LOOP;
    --
    RETURN lv_return;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END conv_multi_byte;
  /* 2009.04.16 K.Satomura T1_0172対応 END */
  /* 2009.05.12 K.Satomura T1_0593対応 START */
   /**********************************************************************************
   * Function Name    : get_rs_base_code
   * Description      : 所属拠点取得（リソースID、基準日指定）
   ***********************************************************************************/
  FUNCTION  get_rs_base_code(
    in_resource_id       IN   NUMBER
   ,id_standard_date     IN   DATE
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_rs_base_code';
--
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    CURSOR  get_rs_group_cur(
      in_resource_id       IN   NUMBER
     ,id_standard_date     IN   DATE
    )
    IS
      SELECT  jrgb.attribute1
      FROM    jtf_rs_group_members  jrgm
             ,jtf_rs_role_relations jrrr
             ,jtf_rs_groups_b       jrgb
             ,xxcso_aff_base_v2     xabv
      WHERE   jrgm.resource_id                             = in_resource_id
      AND     jrgm.delete_flag                             = 'N'
      AND     jrgb.group_id                                = jrgm.group_id
      AND     jrgb.start_date_active                      <= id_standard_date
      AND     NVL(jrgb.end_date_active, id_standard_date) >= id_standard_date
      AND     xabv.base_code                               = jrgb.attribute1
      AND     jrrr.role_resource_id                        = jrgm.group_member_id
      AND     jrrr.role_resource_type                      = 'RS_GROUP_MEMBER'
      AND     jrrr.delete_flag                             = 'N'
      AND     jrrr.start_date_active                      <= id_standard_date
      AND     NVL(jrrr.end_date_active, id_standard_date) >= id_standard_date
      /* 2009.05.20 K.Satomura T1_1082対応 START */
      --ORDER BY jrrr.start_date_active, jrrr.last_update_date DESC
      ORDER BY jrrr.start_date_active DESC
              ,jrrr.last_update_date  DESC
      /* 2009.05.20 K.Satomura T1_1082対応 END */
    ;
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_base_code  jtf_rs_groups_b.attribute1%TYPE;
--
  BEGIN
--
    << resource_group_loop >>
    FOR lr_rec IN get_rs_group_cur(in_resource_id, id_standard_date)
    LOOP
--
      lv_base_code := lr_rec.attribute1;
      EXIT resource_group_loop;
--
    END LOOP resource_group_loop;
--
    RETURN lv_base_code;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_rs_base_code;
--
   /**********************************************************************************
   * Function Name    : get_current_rs_base_code
   * Description      : 現所属拠点取得
   ***********************************************************************************/
  FUNCTION  get_current_rs_base_code
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_current_rs_base_code';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_resource_id  xxcso_resources_v2.resource_id%TYPE;
    lv_base_code    jtf_rs_groups_b.attribute1%TYPE;
--
  BEGIN
--
    BEGIN
--
      SELECT  xrv.resource_id
      INTO    ln_resource_id
      FROM    xxcso_resources_v2  xrv
      WHERE   xrv.user_id = fnd_global.user_id
      ;
--
      lv_base_code :=
        get_rs_base_code(
          ln_resource_id
         ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_base_code := NULL;
    END;
--
    RETURN lv_base_code;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_current_rs_base_code;
  /* 2009.05.12 K.Satomura T1_0593対応 END */
--
--
  /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
  /**********************************************************************************
   * Function  Name   : conv_ng_char_vdms
   * Description      : 自販機管理S禁則文字変換関数
   *                    禁則文字チェックに該当する文字を"○"に変換する。
   *                    禁則文字は共通関数chk_mojiと合わせる。
   *                    ＜前提＞禁則文字が1byteの場合も、2byte固定の"○"で変換する。
   ***********************************************************************************/
  FUNCTION conv_ng_char_vdms(
    iv_char IN VARCHAR2 -- 文字列
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100) := 'conv_ng_char_vdms'; -- プログラム名
    cv_conv_char             CONSTANT VARCHAR2(2)   := '○'; -- 変換文字列
  --自販機システムチェック
  --半角文字
    cn_chr_code_tab          CONSTANT NUMBER        := 9;                            -- '	'の文字コード
    cn_chr_code_exmark       CONSTANT NUMBER        := 33;                           -- '!'の文字コード
    cn_chr_code_plus         CONSTANT NUMBER        := 43;                           -- '+'の文字コード
    cn_chr_code_colon        CONSTANT NUMBER        := 58;                           -- ':'の文字コード
    cn_chr_code_atmark       CONSTANT NUMBER        := 64;                           -- '@'の文字コード
    cn_chr_code_bracket      CONSTANT NUMBER        := 91;                           -- '['の文字コード
    cn_chr_code_caret        CONSTANT NUMBER        := 94;                           -- '^'の文字コード
    cn_chr_code_acsan        CONSTANT NUMBER        := 96;                           -- '`'の文字コード
    cn_chr_code_brace        CONSTANT NUMBER        := 123;                          -- '{'の文字コード
    cn_chr_code_tilde        CONSTANT NUMBER        := 126;                          -- '~'の文字コード
  --全角文字
    cn_chr_code_wavy_line    CONSTANT NUMBER        := 33120;                        -- '0'の文字コード
    cn_chr_code_union        CONSTANT NUMBER        := 33214;                        -- '∪'の文字コード
    cn_chr_code_intersection CONSTANT NUMBER        := 33215;                        -- '∩'の文字コード
    cn_chr_code_corner       CONSTANT NUMBER        := 33242;                        -- '∠'の文字コード
    cn_chr_code_vertical     CONSTANT NUMBER        := 33243;                        -- '⊥'の文字コード
    cn_chr_code_combination  CONSTANT NUMBER        := 33247;                        -- '≡'の文字コード
    cn_chr_code_route        CONSTANT NUMBER        := 33251;                        -- '√'の文字コード
    cn_chr_code_because      CONSTANT NUMBER        := 33254;                        -- '∵'の文字コード^
    cn_chr_code_integration  CONSTANT NUMBER        := 33255;                        -- '∫'の文字コード
    cn_chr_code_maruone      CONSTANT NUMBER        := 34624;                        -- '①'の文字コード
    cn_chr_code_some         CONSTANT NUMBER        := 33248;                        -- '≒'の文字コード
    cn_chr_code_difference   CONSTANT NUMBER        := 34713;                        -- '⊿'の文字コード
  --文字化けチェック
  --半角文字
    cn_chr_code_yen_mark     CONSTANT NUMBER        := 92;                           -- '\'の文字コード
  --全角文字
    cn_chr_code_over_line    CONSTANT NUMBER        := 33104;                        -- '￣'の文字コード
    cn_chr_code_darshi       CONSTANT NUMBER        := 33116;                        -- '―'の文字コード
    cn_chr_code_backslash    CONSTANT NUMBER        := 33119;                        -- '＼'の文字コード
    cn_chr_code_parallel     CONSTANT NUMBER        := 33121;                        -- '∥'の文字コード
    cn_chr_code_three_reader CONSTANT NUMBER        := 33123;                        -- '…'の文字コード
    cn_chr_code_two_darshi   CONSTANT NUMBER        := 33148;                        -- '－'の文字コード
    cn_chr_code_yen_mark_b   CONSTANT NUMBER        := 33167;                        -- '￥'の文字コード
    cn_chr_code_cent         CONSTANT NUMBER        := 33169;                        -- '￠'の文字コード
    cn_chr_code_pound        CONSTANT NUMBER        := 33170;                        -- '￡'の文字コード
    cn_chr_code_not          CONSTANT NUMBER        := 33226;                        -- '￢'の文字コード
--
    -- *** ローカル定数 ***
--
    lv_return     VARCHAR2(5000); -- リターン用文字列変数
    lv_check_char VARCHAR2(2);    -- チェック対象文字
    ln_check_char NUMBER;         -- チェック対象文字コード
    
  BEGIN
--
    --チェック対象文字列NULLチェック
    IF (iv_char IS NULL) THEN
      RETURN NULL;
    END IF;
--
    --チェック対象文字列を1文字づつチェック
    FOR ln_position IN 1..LENGTH(iv_char) LOOP
      --チェック対象文字列を1文字づつに切り取り
      lv_check_char := SUBSTR(iv_char,ln_position,1);
      --チェック対象文字を文字コードに変換
      ln_check_char := ASCII(lv_check_char);
--
      IF ((ln_check_char BETWEEN cn_chr_code_colon AND cn_chr_code_atmark)
        OR (ln_check_char BETWEEN cn_chr_code_exmark AND cn_chr_code_plus)
        OR (ln_check_char BETWEEN cn_chr_code_bracket AND cn_chr_code_caret)
        OR (ln_check_char BETWEEN cn_chr_code_brace AND cn_chr_code_tilde)
        OR (ln_check_char IN (cn_chr_code_tab,cn_chr_code_acsan))
        OR (ln_check_char BETWEEN cn_chr_code_maruone AND cn_chr_code_difference)
        OR (ln_check_char IN (cn_chr_code_some,cn_chr_code_combination,cn_chr_code_integration,
          cn_chr_code_route,cn_chr_code_vertical,cn_chr_code_corner,cn_chr_code_because,
            cn_chr_code_intersection,cn_chr_code_union,cn_chr_code_wavy_line)))
      THEN
        --禁則文字の場合
        lv_return := lv_return || cv_conv_char;
      ELSE
        --禁則文字でない場合
        lv_return := lv_return || lv_check_char;
      END IF;
--
    END LOOP;
--
    RETURN lv_return;
--
  EXCEPTION
--
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--###################################  固定部 END   #########################################
--
  END conv_ng_char_vdms;
  /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
--
END xxcso_util_common_pkg;
/
