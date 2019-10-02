CREATE OR REPLACE PACKAGE BODY xxcmn_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common_pkg(BODY)
 * Description            : 共通関数(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数（補足資料）.xls
 * Version                : 1.6
 *
 * Program List
 *  --------------------        ---- ----- --------------------------------------------------
 *   Name                       Type  Ret   Description
 *  --------------------        ---- ----- --------------------------------------------------
 *  get_msg                       F   VAR   Message取得
 *  get_user_name                 F   VAR   担当者名取得
 *  get_user_dept                 F   VAR   担当部署名取得
 *  get_tbl_lock                  F   BOL   テーブルロック関数
 *  del_all_data                  F   BOL   テーブルデータ一括削除関数
 *  get_opminv_close_period       F   VAR   OPM在庫会計期間CLOSE年月取得関数
 *  get_category_desc             F   VAR   カテゴリ取得関数
 *  get_sagara_factory_info       P         伊藤園相良工場情報取得プロシージャ
 *  get_calender_cd               F   VAR   カレンダコード取得関数
 *  check_oprtn_day               F   NUM   稼働日チェック関数
 *  get_seq_no                    P         採番関数
 *  get_dept_info                 P         部署情報取得プロシージャ
 *  get_term_of_payment           F   VAR   支払条件文言取得関数
 *  check_param_date_yyyymm       F   NUM   パラメータチェック：日付形式（YYYYMM）
 *  check_param_date_yyyymmdd     F   NUM   パラメータチェック：日付形式（YYYYMMDD HH24:MI:SS）
 *  put_api_log                   P   なし  標準APIログ出力API
 *  get_outbound_info             P   なし  アウトバウンド処理情報取得関数
 *  upd_outbound_info             P   なし  ファイル出力情報更新関数
 *  wf_start                      P   なし  ワークフロー起動関数
 *  get_can_enc_total_qty         F   NUM   総引当可能数算出API
 *  get_can_enc_in_time_qty       F   NUM   有効日ベース引当可能数算出API
 *  get_stock_qty                 F   NUM   手持在庫数量算出API
 *  get_can_enc_qty               F   NUM   引当可能数算出API
 *  rcv_ship_conv_qty             F   NUM   入出庫換算関数(生産バッチ用)
 *  get_user_dept_code            F   VAR   担当部署CD取得
 *  create_lot_mst_history        P         ロットマスタ履歴作成関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/12/07   1.0   marushita       新規作成
 *  2008/05/07   1.1   marushita       WF起動関数のWF起動時パラメータにWFオーナーを追加
 *  2008/09/18   1.2   Oracle 山根 一浩T_S_453対応(WFファイルコピー)
 *  2008/09/30   1.3   Yuko Kawano      OPM在庫会計期間CLOSE年月取得関数 T_S_500対応
 *  2008/10/29   1.4   T.Yoshimoto     統合指摘対応(No.251)
 *  2008/12/29   1.5   A.Shiina        [採番関数]動的に修正
 *  2019/09/19   1.6   Y.Ohishi        ロットマスタ履歴作成関数を追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  resource_busy_expt           EXCEPTION;     -- デッドロックエラー
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common_pkg'; -- パッケージ名
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- 正常
  gn_ret_error     CONSTANT NUMBER := 1; -- エラー
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Function Name    : get_msg
   * Description      :
   ***********************************************************************************/
  FUNCTION get_msg(
    iv_application   IN VARCHAR2,
    iv_name          IN VARCHAR2,
    iv_token_name1   IN VARCHAR2 DEFAULT NULL,
    iv_token_value1  IN VARCHAR2 DEFAULT NULL,
    iv_token_name2   IN VARCHAR2 DEFAULT NULL,
    iv_token_value2  IN VARCHAR2 DEFAULT NULL,
    iv_token_name3   IN VARCHAR2 DEFAULT NULL,
    iv_token_value3  IN VARCHAR2 DEFAULT NULL,
    iv_token_name4   IN VARCHAR2 DEFAULT NULL,
    iv_token_value4  IN VARCHAR2 DEFAULT NULL,
    iv_token_name5   IN VARCHAR2 DEFAULT NULL,
    iv_token_value5  IN VARCHAR2 DEFAULT NULL,
    iv_token_name6   IN VARCHAR2 DEFAULT NULL,
    iv_token_value6  IN VARCHAR2 DEFAULT NULL,
    iv_token_name7   IN VARCHAR2 DEFAULT NULL,
    iv_token_value7  IN VARCHAR2 DEFAULT NULL,
    iv_token_name8   IN VARCHAR2 DEFAULT NULL,
    iv_token_value8  IN VARCHAR2 DEFAULT NULL,
    iv_token_name9   IN VARCHAR2 DEFAULT NULL,
    iv_token_value9  IN VARCHAR2 DEFAULT NULL,
    iv_token_name10  IN VARCHAR2 DEFAULT NULL,
    iv_token_value10 IN VARCHAR2 DEFAULT NULL,
--  2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
    iv_token_name11  IN VARCHAR2 DEFAULT NULL,
    iv_token_value11 IN VARCHAR2 DEFAULT NULL
--  2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
    )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msg'; -- プログラム名
--
    -- *** ローカル変数 ***
    lv_token_name          VARCHAR2(1000);
    lv_token_value         VARCHAR2(2000);
    ln_cnt                 NUMBER;
--
  BEGIN
--
    -- スタックにメッセージをセット
    FND_MESSAGE.SET_NAME(
      iv_application,
      iv_name);
--
    -- スタックにトークンをセット
    IF (iv_token_name1 IS NOT NULL) THEN
      -- カウンタ初期化
      ln_cnt := 0;
--
      <<token_set>>
      LOOP
--
        ln_cnt := ln_cnt + 1;
--
        -- トークンの値が2000バイトを超える場合、
        -- 2000バイト行こうを切り捨てるよう修正
        IF (ln_cnt = 1) THEN
          lv_token_name := iv_token_name1;
          lv_token_value := SUBSTRB(iv_token_value1,1,2000);
        ELSIF (ln_cnt = 2) THEN
          lv_token_name := iv_token_name2;
          lv_token_value := SUBSTRB(iv_token_value2,1,2000);
        ELSIF (ln_cnt = 3) THEN
          lv_token_name := iv_token_name3;
          lv_token_value := SUBSTRB(iv_token_value3,1,2000);
        ELSIF (ln_cnt = 4) THEN
          lv_token_name := iv_token_name4;
          lv_token_value := SUBSTRB(iv_token_value4,1,2000);
        ELSIF (ln_cnt = 5) THEN
          lv_token_name := iv_token_name5;
          lv_token_value := SUBSTRB(iv_token_value5,1,2000);
        ELSIF (ln_cnt = 6) THEN
          lv_token_name := iv_token_name6;
          lv_token_value := SUBSTRB(iv_token_value6,1,2000);
        ELSIF (ln_cnt = 7) THEN
          lv_token_name := iv_token_name7;
          lv_token_value := SUBSTRB(iv_token_value7,1,2000);
        ELSIF (ln_cnt = 8) THEN
          lv_token_name := iv_token_name8;
          lv_token_value := SUBSTRB(iv_token_value8,1,2000);
        ELSIF (ln_cnt = 9) THEN
          lv_token_name := iv_token_name9;
          lv_token_value := SUBSTRB(iv_token_value9,1,2000);
        ELSIF (ln_cnt = 10) THEN
          lv_token_name := iv_token_name10;
          lv_token_value := SUBSTRB(iv_token_value10,1,2000);
--  2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
        ELSIF (ln_cnt = 11) THEN
          lv_token_name := iv_token_name11;
          lv_token_value := SUBSTRB(iv_token_value11,1,2000);
--  2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
        END IF;
--
        EXIT WHEN (lv_token_name IS NULL)
--  2008/10/29 v1.4 T.Yoshimoto Mod Start 統合#251
               --OR (ln_cnt > 10);
               OR (ln_cnt > 11);
--  2008/10/29 v1.4 T.Yoshimoto Mod End 統合#251
--
        FND_MESSAGE.SET_TOKEN(
          lv_token_name,
          lv_token_value,
          FALSE);
--
      END LOOP token_set;
--
    END IF;
    -- スタックの内容を取得
    RETURN FND_MESSAGE.GET;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_msg;
--
  /**********************************************************************************
   * Function Name    : get_user_name
   * Description      : 担当者名取得
   ***********************************************************************************/
  FUNCTION get_user_name
    (
      in_user_id  IN FND_USER.USER_ID%TYPE    -- ログインユーザーID
    )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_name' ;  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_user_name    VARCHAR2(100) ;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 個人情報のテーブルより、漢字氏名を取得する。
    BEGIN
      SELECT papf.per_information18 || ' ' || papf.per_information19
      INTO   lv_user_name
      FROM per_all_people_f  papf
          ,fnd_user          fu
      WHERE TRUNC(SYSDATE) 
        BETWEEN papf.effective_start_date
        AND     papf.effective_end_date
      AND   fu.employee_id  = papf.person_id
      AND   fu.user_id      = in_user_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_user_name := NULL ;
    END ;
--
    RETURN lv_user_name ;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_user_name ;
--
  /**********************************************************************************
   * Function Name    : get_user_dept
   * Description      : 担当部署名取得
   ***********************************************************************************/
  FUNCTION get_user_dept
    (
      in_user_id  IN FND_USER.USER_ID%TYPE    -- ログインユーザーID
    )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_dept' ;  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_user_dept_name   VARCHAR2(100) ;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 事業所テーブルより、事業署名を取得する。
    BEGIN
      SELECT xla.location_short_name
      INTO   lv_user_dept_name
      FROM xxcmn_locations_all    xla
          ,per_all_assignments_f  paaf
          ,fnd_user               fu
      WHERE TRUNC(SYSDATE)    BETWEEN xla.start_date_active     AND xla.end_date_active
      AND   paaf.location_id  = xla.location_id
      AND   paaf.primary_flag = 'Y'
      AND   TRUNC(SYSDATE)    BETWEEN paaf.effective_start_date AND paaf.effective_end_date
      AND   fu.employee_id    = paaf.person_id
      AND   fu.user_id        = in_user_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_user_dept_name := NULL ;
    END ;
--
    RETURN lv_user_dept_name ;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_user_dept ;
--
  /**********************************************************************************
   * Function Name    : get_tbl_lock
   * Description      : テーブルロック関数
   ***********************************************************************************/
  FUNCTION get_tbl_lock(
    iv_schema_name IN VARCHAR2,         -- スキーマ名
    iv_table_name  IN VARCHAR2)         -- テーブル名
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tbl_lock'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    BEGIN
--
      EXECUTE IMMEDIATE
        'LOCK TABLE ' || iv_schema_name || '.' || iv_table_name ||
        ' IN EXCLUSIVE MODE NOWAIT';
--
      RETURN TRUE;
--
    EXCEPTION
--
      WHEN resource_busy_expt THEN
        RETURN FALSE;
--
    END;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_tbl_lock;
--
  /**********************************************************************************
   * Function Name    : del_all_data
   * Description      : テーブルデータ一括削除関数
   ***********************************************************************************/
  FUNCTION del_all_data(
    iv_schema_name IN VARCHAR2,         -- スキーマ名
    iv_table_name  IN VARCHAR2)         -- テーブル名
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_all_data'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    BEGIN
--
      EXECUTE IMMEDIATE
        'TRUNCATE TABLE ' || iv_schema_name || '.' || iv_table_name;
--
      RETURN TRUE;
--
    EXCEPTION
--
      WHEN OTHERS THEN
        RETURN FALSE;
--
    END;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END del_all_data;
--
  /**********************************************************************************
   * Function Name    : get_opminv_close_period
   * Description      : OPM在庫会計期間CLOSE年月取得関数
   ***********************************************************************************/
  FUNCTION get_opminv_close_period 
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_opminv_close_period'; --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prf_min_date_name CONSTANT VARCHAR2(15)  := 'MIN日付';
    -- *** ローカル変数 ***
    lv_errmsg         VARCHAR2(5000); -- エラーメッセージ
    lv_return_date    VARCHAR2(10);   -- 返却年月
    lv_min_date       VARCHAR2(10);   -- MIN日付のYYYYMM
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    -- MIN日付プロファイル取得エラー
    profile_expt             EXCEPTION;
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- 最小日付のYYYMMを取得(プロファイル)
    lv_min_date := SUBSTRB(REPLACE(FND_PROFILE.VALUE('XXCMN_MIN_DATE'),'/'), 1, 6) ;
    -- プロファイルが取得できない場合はエラー
    IF (lv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10002',
                                            'NG_PROFILE', cv_prf_min_date_name);
      RAISE profile_expt ;
    END IF ;
--
    -- OPM在庫会計期間で最新のCLOSE日付を取得
--2008/09/26 Y.Kawano Mod Start
--    SELECT 
--      NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(MAX(oap.period_name), 'MON-RR'), 'YYYYMM'), lv_min_date)
--    INTO   lv_return_date
--    FROM   org_acct_periods       oap,
--           ic_whse_mst            iwm
--    WHERE  iwm.whse_code        = FND_PROFILE.VALUE('XXCMN_COST_PRICE_WHSE_CODE')
--    AND    oap.organization_id  = iwm.mtl_organization_id
--    AND    oap.open_flag        = 'N';
    --
    SELECT 
      NVL(TO_CHAR(MAX(icd.period_end_date), 'YYYYMM'), lv_min_date)
    INTO  lv_return_date
    FROM  ic_cldr_dtl            icd
         ,ic_whse_sts            iws
    WHERE iws.whse_code        = FND_PROFILE.VALUE('XXCMN_COST_PRICE_WHSE_CODE')
    AND   icd.period_id        = iws.period_id
    AND   iws.close_whse_ind  <> 1
    ;
--2008/09/26 Y.Kawano Mod End
--
    RETURN lv_return_date;
--
  EXCEPTION
    WHEN profile_expt THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_opminv_close_period;
--
  /**********************************************************************************
   * Function Name    : get_category_desc
   * Description      : カテゴリ取得関数
   ***********************************************************************************/
  FUNCTION get_category_desc(
    in_item_no      IN  VARCHAR2,     -- 品目
    iv_category_set IN  VARCHAR2)     -- カテゴリセットコード
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_category_desc'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_description  VARCHAR2(240) ;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    BEGIN
--
      -- 品目カテゴリマスタ日本語テーブルより、カテゴリ摘要を取得する。
      SELECT  xcv.description
      INTO    lv_description
      FROM    xxcmn_categories_v    xcv
              ,gmi_item_categories  gic
              ,ic_item_mst_b        iimb
      WHERE   xcv.category_set_name    = iv_category_set
      AND     iimb.item_no             = in_item_no
      AND     iimb.item_id             = gic.item_id
      AND     xcv.category_id          = gic.category_id
      AND     xcv.category_set_id      = gic.category_set_id
      AND     ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_description := NULL;
--
    END;
--
    RETURN lv_description;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_category_desc;
--
  /**********************************************************************************
   * Procedure Name   : get_sagara_factory_info
   * Description      : 伊藤園相良工場情報取得プロシージャ
   ***********************************************************************************/
  PROCEDURE get_sagara_factory_info(
    ov_postal_code OUT NOCOPY VARCHAR2,     -- 郵便番号
    ov_address     OUT NOCOPY VARCHAR2,     -- 住所
    ov_tel_num     OUT NOCOPY VARCHAR2,     -- 電話番号
    ov_fax_num     OUT NOCOPY VARCHAR2,     -- FAX番号
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sagara_factory_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    SELECT xla.zip                        -- 郵便番号
           ,xla.address_line1             -- 住所
           ,xla.phone                     -- 電話番号
           ,xla.fax                       -- FAX番号
    INTO   ov_postal_code
           ,ov_address
           ,ov_tel_num
           ,ov_fax_num
    FROM   hr_locations_all      hla    -- 事業所マスタ
           ,xxcmn_locations_all  xla    -- 事業所アドオンマスタ
    WHERE  hla.location_code = FND_PROFILE.VALUE('XXCMN_SAGARA_F_CODE')-- 伊藤園相良工場事業所コード
    AND    hla.location_id   = xla.location_id
    AND    TRUNC(SYSDATE) BETWEEN xla.start_date_active AND xla.end_date_active
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10036');
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sagara_factory_info;
--
  /**********************************************************************************
   * Function Name    : get_calender_cd
   * Description      : カレンダコード取得関数
   ***********************************************************************************/
  FUNCTION get_calender_cd(
    iv_whse_code      IN  VARCHAR2 DEFAULT NULL,  -- 保管倉庫コード
    in_party_site_no  IN  VARCHAR2 DEFAULT NULL,  -- パーティサイト番号
    iv_leaf_drink     IN  VARCHAR2)               -- リーフドリンク区分
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_calender_cd'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_calender_code        VARCHAR2(150);
    lv_basic_calender_code  VARCHAR2(150);
    -- *** ローカル定数 ***
    cn_cal_cd_len CONSTANT NUMBER(15,0)  := 150; -- カレンダコード長
    cv_leaf       CONSTANT VARCHAR2(1)   := '1'; -- リーフ
    cv_drink      CONSTANT VARCHAR2(1)   := '2'; -- ドリンク
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- パラメータチェックおよび基準カレンダの取得
    IF (    (iv_whse_code IS NOT NULL) 
        AND (in_party_site_no IS NULL)
        AND (iv_leaf_drink = cv_leaf)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_LEAF_WHSE_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSIF ((iv_whse_code IS NOT NULL)
        AND (in_party_site_no IS NULL)
        AND (iv_leaf_drink = cv_drink)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_DRNK_WHSE_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSIF ((iv_whse_code IS NULL)
        AND (in_party_site_no IS NOT NULL)
        AND (iv_leaf_drink = cv_leaf)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_LEAF_DELIVER_TO_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSIF ((iv_whse_code IS NULL) 
        AND (in_party_site_no IS NOT NULL)
        AND (iv_leaf_drink = cv_drink)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_DRNK_DELIVER_TO_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSE
      -- その他の場合はNULLを返す
      RETURN NULL;
    END IF;
--
    IF (iv_whse_code IS NOT NULL) THEN
    -- 保管倉庫コードが指定された場合
      BEGIN
        SELECT  CASE
                  -- パラメータ'リーフドリンク区分'が'リーフ'の場合
                  WHEN (iv_leaf_drink = cv_leaf) THEN
                    SUBSTRB(xilv.leaf_calender, 1, cn_cal_cd_len)
                  -- パラメータ'リーフドリンク区分'が'ドリンク'の場合
                  ELSE
                    SUBSTRB(xilv.drink_calender, 1, cn_cal_cd_len)
                END
        INTO    lv_calender_code
        FROM    xxcmn_item_locations_v xilv
        WHERE   xilv.segment1 = iv_whse_code
        AND     ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_calender_code := lv_basic_calender_code;
      END;
    ELSIF (in_party_site_no IS NOT NULL) THEN
    -- パーティサイト番号が指定された場合
      BEGIN
        SELECT  CASE
                  -- パラメータ'リーフドリンク区分'が'リーフ'の場合
                  WHEN (iv_leaf_drink = cv_leaf) THEN
                    SUBSTRB(xpsv.leaf_calender, 1, cn_cal_cd_len)
                  -- パラメータ'リーフドリンク区分'が'ドリンク'の場合
                  ELSE
                    SUBSTRB(xpsv.drink_calender, 1, cn_cal_cd_len)
                END
        INTO    lv_calender_code
        FROM    xxcmn_party_sites_v xpsv
        WHERE   xpsv.ship_to_no = in_party_site_no
        AND     ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_calender_code := lv_basic_calender_code;
      END;
    END IF;
--
    RETURN NVL(lv_calender_code, lv_basic_calender_code);
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_calender_cd;
--
  /**********************************************************************************
   * Function Name    : check_oprtn_day
   * Description      : 稼働日チェック関数
   ***********************************************************************************/
  FUNCTION check_oprtn_day(
    id_date         IN  DATE,      -- チェック対象日付
    iv_calender_cd  IN  VARCHAR2)  -- カレンダーコード
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_oprtn_day'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_active     NUMBER(5,0) := 0;
    -- *** ローカル変数 ***
    ln_ret_num    NUMBER(1); -- 戻り値
    ln_cnt        NUMBER(1); -- 取得件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    ln_ret_num := gn_ret_nomal;
--
    SELECT  COUNT(1)
    INTO    ln_cnt
    FROM    mr_shcl_hdr msh,
            mr_shcl_dtl msd
    WHERE   msh.calendar_no   = iv_calender_cd
    AND     msh.calendar_id   = msd.calendar_id
    AND     msd.calendar_date = TRUNC(id_date)
    AND     msd.delete_mark   = cn_active
    AND     ROWNUM = 1;
--
    IF (ln_cnt = 0) THEN
      ln_ret_num := gn_ret_error;
    END IF;
--
    RETURN ln_ret_num;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_oprtn_day;
--
  /**********************************************************************************
   * Procedure Name   : get_seq_no
   * Description      : 伝票番号などで使用する番号を採番します
   ***********************************************************************************/
  PROCEDURE get_seq_no(
    iv_seq_class  IN  VARCHAR2,            --   採番する番号を表す区分
    ov_seq_no     OUT NOCOPY VARCHAR2,     --   採番した固定長12桁の番号
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcmn_common_pkg.get_seq_no'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_slip_no             CONSTANT VARCHAR2(100) := '伝票番号';
--
    -- *** ローカル変数 ***
    lv_seq_admit  VARCHAR2(1);
    lv_seq_yyyymm VARCHAR2(6);
    ln_no         NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
  seq_admin_exp               EXCEPTION;     -- 採番可否取得エラー
  seq_yyyymm_exp              EXCEPTION;     -- 採番用現在年月取得エラー
  get_set_seq_exp             EXCEPTION;     -- シーケンス取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lv_seq_admit := SUBSTR(FND_PROFILE.VALUE('XXCMN_SEQ_ADMIT'),1,1); -- プロファイル取得
--
    -- プロファイルが'Y'でないか、NULLの場合はエラー
    IF ((lv_seq_admit != 'Y') OR (lv_seq_admit IS NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10031');
      lv_errbuf := lv_errmsg;
      RAISE seq_admin_exp;
    END IF;
--
    lv_seq_yyyymm := SUBSTR(FND_PROFILE.VALUE('XXCMN_SEQ_YYYYMM'),1,6); -- プロファイル取得
--
    IF (lv_seq_yyyymm IS NULL) THEN -- プロファイルが取得できない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10032');
      lv_errbuf := lv_errmsg;
      RAISE seq_yyyymm_exp;
    END IF;
--
    BEGIN
      -- 採番を1つのシーケンスで行う場合
-- 2008/12/29 v1.5 UPDATE START
--      SELECT xxcmn_slip_no_s1.NEXTVAL INTO ln_no FROM dual;
      EXECUTE IMMEDIATE 'SELECT xxcmn_slip_no_s1.NEXTVAL FROM dual' INTO ln_no;
-- 2008/12/29 v1.5 UPDATE END
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10029',
                                              'SEQ_NAME',
                                              cv_slip_no);
        lv_errbuf := lv_errmsg;
        RAISE get_set_seq_exp;
    END;
--
    ov_seq_no := SUBSTRB(lv_seq_yyyymm, -4) || TO_CHAR(ln_no, 'FM00000000');
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN seq_admin_exp THEN                           --*** 採番可否取得例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN seq_yyyymm_exp THEN                           --*** 採番用現在年月取得例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN get_set_seq_exp THEN                            --*** シーケンス取得例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_seq_no;
--
  /**********************************************************************************
   * Procedure Name   : get_dept_info
   * Description      : 部署情報取得プロシージャ
   ***********************************************************************************/
  PROCEDURE get_dept_info(
    iv_dept_cd          IN  VARCHAR2,          -- 部署コード(事業所CD)
    id_appl_date        IN  DATE DEFAULT NULL, -- 基準日
    ov_postal_code      OUT NOCOPY VARCHAR2,          -- 郵便番号
    ov_address          OUT NOCOPY VARCHAR2,          -- 住所
    ov_tel_num          OUT NOCOPY VARCHAR2,          -- 電話番号
    ov_fax_num          OUT NOCOPY VARCHAR2,          -- FAX番号
    ov_dept_formal_name OUT NOCOPY VARCHAR2,          -- 部署正式名
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dept_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_basic_date DATE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ld_basic_date := NVL(id_appl_date, TRUNC(SYSDATE));
--
    SELECT  xlv.zip,
            xlv.address_line1,
            xlv.phone,
            xlv.fax,
            xlv.location_name
    INTO    ov_postal_code,
            ov_address,
            ov_tel_num,
            ov_fax_num,
            ov_dept_formal_name
    FROM    xxcmn_locations2_v xlv
    WHERE   xlv.location_code =  iv_dept_cd
    AND     ((xlv.inactive_date IS NULL) OR (xlv.inactive_date > ld_basic_date))
    AND     ld_basic_date BETWEEN xlv.start_date_active AND xlv.end_date_active;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10036');
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dept_info;
--
  /**********************************************************************************
   * Function Name    : get_term_of_payment
   * Description      : 支払条件文言取得関数
   ***********************************************************************************/
  FUNCTION get_term_of_payment(
    in_vendor_id   IN NUMBER,
    id_appl_date   IN DATE DEFAULT NULL)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_term_of_payment'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_effective_date     DATE;
    lv_pay_flag           VARCHAR2(1);
    lv_pay_desc1          VARCHAR2(1000);
    lv_pay_desc2          VARCHAR2(1000);
    lv_pay_desc3          VARCHAR2(1000);
    lv_pay_date_pat       VARCHAR2(50);
    lv_pay_date           VARCHAR2(50);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    invalid_pattern_expt             EXCEPTION;     -- 日付フォーマット不正エラー
--
    PRAGMA EXCEPTION_INIT(invalid_pattern_expt, -1821);
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 有効日を設定
    IF (id_appl_date IS NULL) THEN
      ld_effective_date := TRUNC(SYSDATE);
    ELSE
      ld_effective_date := id_appl_date;
    END IF;
--
    -- 支払条件文言の取得パターンを取得
    lv_pay_flag := SUBSTRB(FND_PROFILE.VALUE('XXCMN_PAY_FLAG'), 1);
--
    IF (lv_pay_flag = '1') THEN
      -- パターンに対応した文言の取得
      lv_pay_desc1 := FND_PROFILE.VALUE('XXCMN_PAY_DESC1');
      lv_pay_desc2 := FND_PROFILE.VALUE('XXCMN_PAY_DESC2');
      lv_pay_date_pat := FND_PROFILE.VALUE('XXCMN_PAY_DATE_PAT');
--
      -- プロファイル値が取得できない場合は終了
      IF (   (lv_pay_desc1 IS NULL)
          OR (lv_pay_desc2 IS NULL)
          OR (lv_pay_date_pat IS NULL)) THEN
        RETURN NULL;
      END IF;
--
      -- 支払条件設定日を取得
      BEGIN
        SELECT  TO_CHAR(xvv.terms_date, lv_pay_date_pat)
        INTO    lv_pay_date
        FROM    xxcmn_vendors2_v xvv
        WHERE   xvv.vendor_id         = in_vendor_id
        AND     (   (xvv.inactive_date     IS NULL)
                 OR (xvv.inactive_date > ld_effective_date))
        AND     (   (xvv.start_date_active IS NULL) 
                 OR (xvv.start_date_active <= ld_effective_date))
        AND     (   (xvv.end_date_active   IS NULL) 
                 OR (xvv.end_date_active   >= ld_effective_date))
        AND     ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN invalid_pattern_expt THEN
          RETURN NULL;
      END;
--
      IF (lv_pay_date IS NULL) THEN
        RETURN NULL;
      END IF;
--
      -- 文言を作成
      RETURN lv_pay_desc1 || lv_pay_date || lv_pay_desc2;
--
    ELSIF (lv_pay_flag = '2') THEN
      -- 文言を作成
      lv_pay_desc3 := FND_PROFILE.VALUE('XXCMN_PAY_DESC3');
      RETURN lv_pay_desc3;
--
    ELSE
      -- NULLを含め対象外のパターンはエラーとする。
      RETURN NULL;
    END IF;
--
    RETURN NULL;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_term_of_payment;
--
  /**********************************************************************************
   * Function Name    : check_param_date_yyyymm
   * Description      : パラメータチェック：日付形式(YYYYMM)
   ***********************************************************************************/
  FUNCTION check_param_date_yyyymm(
    iv_date_ym      VARCHAR2)
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_date_yyyymm' ; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_temp_date    DATE ;
    ln_ret_num      NUMBER := gn_ret_nomal;
--
  BEGIN
--
    ld_temp_date := FND_DATE.STRING_TO_DATE( iv_date_ym, 'YYYY/MM' ) ;
--
    -- 日付が取得できなかった場合
    IF ld_temp_date IS NULL THEN
      ln_ret_num := gn_ret_error;
--
    -- 日付が取得できた場合
    ELSE
      ln_ret_num := gn_ret_nomal;
--
    END IF ;
--
    RETURN ln_ret_num ;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_param_date_yyyymm ;
--
  /**********************************************************************************
   * Function Name    : check_param_date_yyyymmdd
   * Description      : パラメータチェック：日付形式(YYYYMMDD HH24:MI:SS)
   ***********************************************************************************/
  FUNCTION check_param_date_yyyymmdd(
    iv_date_ymd      VARCHAR2)
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_date_yyyymmdd' ; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_temp_date    DATE ;
    ln_ret_num      NUMBER := gn_ret_nomal;
--
  BEGIN
--
    ld_temp_date := FND_DATE.STRING_TO_DATE( iv_date_ymd, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- 日付が取得できなかった場合
    IF ld_temp_date IS NULL THEN
      ln_ret_num := gn_ret_error;
--
    -- 日付が取得できた場合
    ELSE
      ln_ret_num := gn_ret_nomal;
--
    END IF ;
--
    RETURN ln_ret_num ;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_param_date_yyyymmdd ;
--
  /**********************************************************************************
   * Procedure Name   : put_api_log
   * Description      : 標準APIログ出力APIプロシージャ
   ***********************************************************************************/
  PROCEDURE put_api_log(
    ov_errbuf   OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_api_log'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_msg            VARCHAR2(32000);
    ln_dummy_cnt      NUMBER(10);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    <<count_msg_loop>>
    FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
      -- メッセージ取得
      FND_MSG_PUB.GET(
             p_msg_index      => i
            ,p_encoded        => FND_API.G_FALSE
            ,p_data           => lv_msg
            ,p_msg_index_out  => ln_dummy_cnt
      );
      -- ログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
--
    END LOOP count_msg_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_api_log;
--
  /**********************************************************************************
   * Procedure Name   : get_outbound_info
   * Description      : アウトバウンド処理情報取得関数
   ***********************************************************************************/
  PROCEDURE get_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    or_outbound_rec     OUT NOCOPY outbound_rec,      -- ファイル情報
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_outbound_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_wf_noti        CONSTANT VARCHAR2(100) := 'XXCMN_WF_NOTIFICATION'; -- Workflow通知
    cv_wf_info        CONSTANT VARCHAR2(100) := 'XXCMN_WF_INFO'; -- Workflow通知
    cv_prof_min_date  CONSTANT VARCHAR2(100) := 'XXCMN_MIN_DATE';
    cv_prof_min_date_name CONSTANT VARCHAR2(15)  := 'MIN日付';
    cv_xxcmn_outboud_name CONSTANT VARCHAR2(50)  := 'アウトバウンド';
--
    -- *** ローカル変数 ***
    ld_min_date               DATE;         -- MIN日付
    lr_outbound_rec           outbound_rec; -- outbound関連データ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_min_date_expt                 EXCEPTION;     -- MIN日付が存在しないエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- MIN日付取得
    ld_min_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE(cv_prof_min_date), 'YYYY/MM/DD');
    IF (ld_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10002',
                                            'NG_PROFILE',
                                            cv_prof_min_date_name);
      RAISE no_min_date_expt;
    END IF;
--
    BEGIN
      -- 最終更新日を取得
      SELECT xo.file_last_update_date
      INTO   lr_outbound_rec.file_last_update_date
      FROM   xxcmn_outbound xo
      WHERE  xo.wf_ope_div      = iv_wf_ope_div
      AND    xo.wf_class        = iv_wf_class
      AND    xo.wf_notification = iv_wf_notification
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10019',
                                              'TABLE',
                                              cv_xxcmn_outboud_name);
        RAISE resource_busy_expt;
      WHEN NO_DATA_FOUND THEN
        lr_outbound_rec.file_last_update_date := ld_min_date;
    END;
--
    BEGIN
      -- 通知先ユーザーを取得
      SELECT  xlv.attribute1,
              xlv.attribute2,
              xlv.attribute3,
              xlv.attribute4,
              xlv.attribute5,
              xlv.attribute6,
              xlv.attribute7,
              xlv.attribute8,
              xlv.attribute9,
              xlv.attribute10,
              xlv.attribute11,
              xlv.attribute12
      INTO    lr_outbound_rec.wf_class,
              lr_outbound_rec.wf_notification,
              lr_outbound_rec.user_cd01,
              lr_outbound_rec.user_cd02,
              lr_outbound_rec.user_cd03,
              lr_outbound_rec.user_cd04,
              lr_outbound_rec.user_cd05,
              lr_outbound_rec.user_cd06,
              lr_outbound_rec.user_cd07,
              lr_outbound_rec.user_cd08,
              lr_outbound_rec.user_cd09,
              lr_outbound_rec.user_cd10
      FROM    xxcmn_lookup_values_v xlv
      WHERE  xlv.lookup_type  = cv_wf_noti
      AND    xlv.attribute1   = iv_wf_class
      AND    xlv.attribute2   = iv_wf_notification
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lr_outbound_rec.wf_class        := iv_wf_class;
        lr_outbound_rec.wf_notification := iv_wf_notification;
        lr_outbound_rec.user_cd01 := NULL;
        lr_outbound_rec.user_cd02 := NULL;
        lr_outbound_rec.user_cd03 := NULL;
        lr_outbound_rec.user_cd04 := NULL;
        lr_outbound_rec.user_cd05 := NULL;
        lr_outbound_rec.user_cd06 := NULL;
        lr_outbound_rec.user_cd07 := NULL;
        lr_outbound_rec.user_cd08 := NULL;
        lr_outbound_rec.user_cd09 := NULL;
        lr_outbound_rec.user_cd10 := NULL;
    END;
--
    BEGIN
      -- ワークフロー情報を取得
      SELECT  xlv.attribute4,
              xlv.attribute5,
              xlv.attribute6,
              xlv.attribute7,
              xlv.attribute8
      INTO    lr_outbound_rec.wf_name,
              lr_outbound_rec.wf_owner,
              lr_outbound_rec.directory,
              lr_outbound_rec.file_name,
              lr_outbound_rec.file_display_name
      FROM    xxcmn_lookup_values_v xlv
      WHERE   xlv.lookup_type   = cv_wf_info
      AND     xlv.attribute1    = iv_wf_ope_div
      AND     xlv.attribute2    = iv_wf_class
      AND     xlv.attribute3    = iv_wf_notification
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lr_outbound_rec.wf_name   := NULL;
        lr_outbound_rec.wf_owner  := NULL;
        lr_outbound_rec.directory := NULL;
        lr_outbound_rec.file_name := NULL;
        lr_outbound_rec.file_display_name := NULL;
    END;
--
    or_outbound_rec := lr_outbound_rec;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN resource_busy_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_min_date_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_outbound_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_outbound_info
   * Description      : ファイル出力情報更新関数
   ***********************************************************************************/
  PROCEDURE upd_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    id_last_update_date IN  DATE,                     -- ファイル最終更新日
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_outbound_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt    NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxcmn_outbound  xo
    WHERE  xo.wf_ope_div               = iv_wf_ope_div
    AND    xo.wf_class                 = iv_wf_class
    AND    xo.wf_notification          = iv_wf_notification;
--
    IF (ln_cnt = 0) THEN
      -- 存在しない場合は登録する。
      INSERT INTO xxcmn_outbound(
        wf_ope_div,
        wf_class,
        wf_notification,
        file_last_update_date,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        last_update_login,
        request_id,
        program_application_id,
        program_id,
        program_update_date
      )
      VALUES(
        iv_wf_ope_div,
        iv_wf_class,
        iv_wf_notification,
        id_last_update_date,
        FND_GLOBAL.USER_ID,
        SYSDATE,
        FND_GLOBAL.USER_ID,
        SYSDATE,
        FND_GLOBAL.LOGIN_ID,
        FND_GLOBAL.CONC_REQUEST_ID,
        FND_GLOBAL.PROG_APPL_ID,
        FND_GLOBAL.CONC_PROGRAM_ID,
        SYSDATE
      );
    ELSE
      -- データが存在する場合は更新する
      UPDATE xxcmn_outbound  xo
      SET    xo.file_last_update_date    = id_last_update_date,
             xo.last_updated_by          = FND_GLOBAL.USER_ID,
             xo.last_update_date         = SYSDATE,
             xo.last_update_login        = FND_GLOBAL.LOGIN_ID,
             xo.request_id               = FND_GLOBAL.CONC_REQUEST_ID,
             xo.program_application_id   = FND_GLOBAL.PROG_APPL_ID,
             xo.program_id               = FND_GLOBAL.CONC_PROGRAM_ID,
             xo.program_update_date      = SYSDATE
      WHERE  xo.wf_ope_div               = iv_wf_ope_div
      AND    xo.wf_class                 = iv_wf_class
      AND    xo.wf_notification          = iv_wf_notification;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_outbound_info;
--
  /**********************************************************************************
   * Procedure Name   : wf_start
   * Description      : ワークフロー起動関数
   ***********************************************************************************/
  PROCEDURE wf_start(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    ov_errbuf   OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wf_start'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_joint_word     CONSTANT VARCHAR2(4)   := '_';
    lv_extend_word    CONSTANT VARCHAR2(4)   := '.csv';
--
    -- *** ローカル変数 ***
    lv_itemkey VARCHAR2(30);
    lr_outbound_rec           outbound_rec; -- outbound関連データ
--
    lv_file_name   VARCHAR2(300);       --2009/09/18 Add
    ln_len         NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_wf_info_expt                  EXCEPTION;     -- ワークフロー未設定エラー
    wf_exec_expt                     EXCEPTION;     -- ワークフロー実行エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- WFに関連する情報を取得
    get_outbound_info(
      iv_wf_ope_div,
      iv_wf_class,
      iv_wf_notification,
      lr_outbound_rec,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE no_wf_info_expt;
    END IF;
--
--2008/09/18 Add ↓
    ln_len := LENGTH(lr_outbound_rec.file_name);
--
    -- ファイル名称加工(ファイル名 - '.CSV'+'_'+'YYYYMMDDHH24MISS'+'.CSV')
    lv_file_name := SUBSTR(lr_outbound_rec.file_name,1,ln_len-4)
                    || lv_joint_word
                    || TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
                    || lv_extend_word;
--
    -- ファイルコピー
    UTL_FILE.FCOPY(lr_outbound_rec.directory,     -- コピー元_DIR
                   lr_outbound_rec.file_name,     -- コピー元_FILE
                   lr_outbound_rec.directory,     -- コピー先_DIR
                   lv_file_name                   -- コピー先_FILE
                  );
--
    lr_outbound_rec.file_name := lv_file_name;
--2008/09/18 Add ↑
--
    --WFタイプで一意となるWFキーを取得
    SELECT TO_CHAR(xxcmn_wf_key_s1.NEXTVAL)
    INTO   lv_itemkey
    FROM   DUAL;
--
    BEGIN
--
      --WFプロセスを作成
      WF_ENGINE.CREATEPROCESS(lr_outbound_rec.wf_name, lv_itemkey, lr_outbound_rec.wf_name);
      --WFオーナーを設定
      WF_ENGINE.SETITEMOWNER(lr_outbound_rec.wf_name, lv_itemkey, lr_outbound_rec.wf_owner);
      --WF属性を設定
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_NAME',
                                  lr_outbound_rec.directory|| ',' ||lr_outbound_rec.file_name );
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD01',
                                  lr_outbound_rec.user_cd01);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD02',
                                  lr_outbound_rec.user_cd02);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD03',
                                  lr_outbound_rec.user_cd03);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD04',
                                  lr_outbound_rec.user_cd04);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD05',
                                  lr_outbound_rec.user_cd05);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD06',
                                  lr_outbound_rec.user_cd06);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD07',
                                  lr_outbound_rec.user_cd07);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD08',
                                  lr_outbound_rec.user_cd08);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD09',
                                  lr_outbound_rec.user_cd09);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD10',
                                  lr_outbound_rec.user_cd10);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_DISP_NAME',
                                  lr_outbound_rec.file_display_name);
      -- 1.1追加
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'WF_OWNER',
                                  lr_outbound_rec.wf_owner);
--
      --WFプロセスを起動
      WF_ENGINE.STARTPROCESS(lr_outbound_rec.wf_name, lv_itemkey);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10117');
        RAISE wf_exec_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN no_wf_info_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
    WHEN wf_exec_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END wf_start;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_total_qty
   * Description      : 総引当可能数算出API
   ***********************************************************************************/
  FUNCTION get_can_enc_total_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_total_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_can_enc_in_time_qty(in_whse_id, in_item_id, in_lot_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_can_enc_total_qty;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_in_time_qty
   * Description      : 有効日ベース引当可能数算出API
   ***********************************************************************************/
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE)                      -- 有効日
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_in_time_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_qty NUMBER;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_can_enc_in_time_qty(in_whse_id,
                                                          in_item_id,
                                                          in_lot_id,
                                                          in_active_date);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_can_enc_in_time_qty;
--
  /**********************************************************************************
   * Function Name    : get_stock_qty
   * Description      : 手持在庫数量算出API
   ***********************************************************************************/
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    ln_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_stock_qty(in_whse_id, in_item_id, in_lot_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_stock_qty;
--
--
  /**********************************************************************************
   * Function Name    : get_can_enc_qty
   * Description      : 引当可能数算出API
   ***********************************************************************************/
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE)                      -- 有効日
    RETURN NUMBER                                     -- 引当可能数
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_can_enc_qty(in_whse_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_can_enc_qty;
--
  /**********************************************************************************
   * Function Name    : rcv_ship_conv_qty
   * Description      : 入出庫換算関数(生産バッチ用)
   ***********************************************************************************/
  FUNCTION rcv_ship_conv_qty(
    iv_conv_type  IN VARCHAR2,          -- 変換方法(1:入出庫換算単位→第1単位,2:その逆)
    in_item_id    IN NUMBER,            -- OPM品目ID
    in_qty        IN NUMBER)            -- 変換対象の数量
    RETURN NUMBER                      -- 変換結果の数量
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rcv_ship_conv_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_to_inout   CONSTANT VARCHAR2(1)  := '1'; -- 入出庫換算単位から第1単位へ変換
    cv_to_first   CONSTANT VARCHAR2(1)  := '2'; -- 第1単位から入出庫換算単位へ変換
    cv_drink      CONSTANT VARCHAR2(1)  := '2'; -- ドリンク
    -- *** ローカル変数 ***
    lv_errmsg        VARCHAR2(5000); -- エラーメッセージ
    ln_conv_factor     NUMBER; -- 換算係数
    ln_converted_num  NUMBER; -- 換算結果
    lt_prod_class_code mtl_categories_b.segment1%TYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    invalid_conv_unit_expt           EXCEPTION;     -- 不正な換算係数エラー
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_converted_num := 0;
--
    -- 品目にひもづく換算係数を取得する。
    BEGIN
      SELECT  CASE
                WHEN (ximv.conv_unit IS NULL) THEN 1
                ELSE TO_NUMBER(ximv.num_of_cases)
              END
             ,xicv.prod_class_code 
      INTO    ln_conv_factor
             ,lt_prod_class_code
      FROM    xxcmn_item_mst_v          ximv -- 品目情報VIEW
             ,xxcmn_item_categories4_v  xicv -- 品目カテゴリ情報VIEW4
      WHERE   ximv.item_id = xicv.item_id
      AND     ximv.item_id = in_item_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_conv_factor := NULL;
--
    END;
--
    -- 商品区分がドリンクでは無い場合は換算を行わない。
    IF (cv_drink <> lt_prod_class_code) THEN
      ln_converted_num :=  in_qty;
--
    ELSE
      -- 換算係数が取得できない、0以下はエラー
      IF( (ln_conv_factor IS NULL) OR (ln_conv_factor <= 0)) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10133','CONV_UNIT', ln_conv_factor);
        RAISE invalid_conv_unit_expt;
      END IF;
--
      IF (iv_conv_type = cv_to_inout) THEN
        ln_converted_num := in_qty * ln_conv_factor;
--
      ELSE
        ln_converted_num := in_qty / ln_conv_factor;
--
      END IF;
--
    END IF;
--
    RETURN ln_converted_num;
--
  EXCEPTION
    WHEN invalid_conv_unit_expt THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END rcv_ship_conv_qty;
--
  /**********************************************************************************
   * Function Name    : get_user_dept_code
   * Description      : 担当部署CD取得
   ***********************************************************************************/
  FUNCTION get_user_dept_code
    (
      in_user_id    IN FND_USER.USER_ID%TYPE,  -- ログインユーザーID
      id_appl_date  IN DATE DEFAULT NULL       -- 基準日
    )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_dept_code' ;  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_user_dept_cd   VARCHAR2(100) ;
    ld_appl_date      DATE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 基準日がNULLの場合はSYSDATEを設定
    IF (id_appl_date IS NULL) THEN
      ld_appl_date := TRUNC(SYSDATE);
    ELSE
      ld_appl_date := TRUNC(id_appl_date);
    END IF;
--
    -- ユーザーにひもづく担当部署コードを取得する。
    BEGIN
      SELECT xlv.location_code
      INTO   lv_user_dept_cd
      FROM per_all_assignments_f  paaf
          ,fnd_user               fu
          ,xxcmn_locations2_v     xlv
      WHERE fu.user_id        = in_user_id
      AND   fu.employee_id    = paaf.person_id
      AND   paaf.primary_flag = 'Y'
      AND   ld_appl_date    BETWEEN paaf.effective_start_date AND paaf.effective_end_date
      AND   paaf.location_id  = xlv.location_id
      AND   ld_appl_date    BETWEEN xlv.start_date_active     AND xlv.end_date_active
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_user_dept_cd := NULL ;
    END ;
--
    RETURN lv_user_dept_cd ;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_user_dept_code ;
-- Ver_1.6 E_本稼動_15887 ADD Start
--
  /**********************************************************************************
   * Procedure Name   : create_lot_mst_history
   * Description      : ロットマスタ履歴作成関数
   ***********************************************************************************/
  PROCEDURE create_lot_mst_history(
    ir_lot_data         IN  lot_rec,              -- 更新前ロットマスタのデータ
    ov_errbuf           OUT NOCOPY VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_lot_mst_history'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_zero               CONSTANT NUMBER := 0;
    cn_one                CONSTANT NUMBER := 1;
--
    -- *** ローカル変数 ***
    ln_history_no                  NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    --  ロットマスタ履歴テーブルより発行済最大履歴番号を取得
    BEGIN
      SELECT NVL( MAX( xlmh.history_no ) , cn_zero )   history_no
      INTO   ln_history_no
      FROM   xxcmn_lots_mst_history  xlmh
      WHERE  xlmh.item_id = ir_lot_data.item_id
      AND    xlmh.lot_id  = ir_lot_data.lot_id;
    END;
--
    --  発行済最大履歴番号確認
    IF ( ln_history_no = cn_zero )  THEN
--
      --  履歴番号加算
      ln_history_no := ln_history_no + cn_one;
--
      --  変更前のロットマスタの情報をロットマスタ履歴テーブルに登録
      BEGIN
        INSERT INTO xxcmn_lots_mst_history(
          item_id,
          lot_id,
          history_no,
          lot_no,
          sublot_no,
          lot_desc,
          qc_grade,
          expaction_code,
          expaction_date,
          lot_created,
          expire_date,
          retest_date,
          strength,
          inactive_ind,
          origination_type,
          shipvend_id,
          vendor_lot_no,
          creation_date,
          last_update_date,
          created_by,
          last_updated_by,
          trans_cnt,
          delete_mark,
          text_code,
          last_update_login,
          program_application_id,
          program_id,
          program_update_date,
          request_id,
          attribute1,
          attribute2,
          attribute3,
          attribute4,
          attribute5,
          attribute6,
          attribute7,
          attribute8,
          attribute9,
          attribute10,
          attribute11,
          attribute12,
          attribute13,
          attribute14,
          attribute15,
          attribute16,
          attribute17,
          attribute18,
          attribute19,
          attribute20,
          attribute21,
          attribute22,
          attribute23,
          attribute24,
          attribute25,
          attribute26,
          attribute27,
          attribute28,
          attribute29,
          attribute30,
          attribute_category,
          odm_lot_number
        )
        VALUES(
          ir_lot_data.item_id,
          ir_lot_data.lot_id,
          ln_history_no,
          ir_lot_data.lot_no,
          ir_lot_data.sublot_no,
          ir_lot_data.lot_desc,
          ir_lot_data.qc_grade,
          ir_lot_data.expaction_code,
          ir_lot_data.expaction_date,
          ir_lot_data.lot_created,
          ir_lot_data.expire_date,
          ir_lot_data.retest_date,
          ir_lot_data.strength,
          ir_lot_data.inactive_ind,
          ir_lot_data.origination_type,
          ir_lot_data.shipvend_id,
          ir_lot_data.vendor_lot_no,
          ir_lot_data.creation_date,
          ir_lot_data.last_update_date,
          ir_lot_data.created_by,
          ir_lot_data.last_updated_by,
          ir_lot_data.trans_cnt,
          ir_lot_data.delete_mark,
          ir_lot_data.text_code,
          ir_lot_data.last_update_login,
          ir_lot_data.program_application_id,
          ir_lot_data.program_id,
          ir_lot_data.program_update_date,
          ir_lot_data.request_id,
          ir_lot_data.attribute1,
          ir_lot_data.attribute2,
          ir_lot_data.attribute3,
          ir_lot_data.attribute4,
          ir_lot_data.attribute5,
          ir_lot_data.attribute6,
          ir_lot_data.attribute7,
          ir_lot_data.attribute8,
          ir_lot_data.attribute9,
          ir_lot_data.attribute10,
          ir_lot_data.attribute11,
          ir_lot_data.attribute12,
          ir_lot_data.attribute13,
          ir_lot_data.attribute14,
          ir_lot_data.attribute15,
          ir_lot_data.attribute16,
          ir_lot_data.attribute17,
          ir_lot_data.attribute18,
          ir_lot_data.attribute19,
          ir_lot_data.attribute20,
          ir_lot_data.attribute21,
          ir_lot_data.attribute22,
          ir_lot_data.attribute23,
          ir_lot_data.attribute24,
          ir_lot_data.attribute25,
          ir_lot_data.attribute26,
          ir_lot_data.attribute27,
          ir_lot_data.attribute28,
          ir_lot_data.attribute29,
          ir_lot_data.attribute30,
          ir_lot_data.attribute_category,
          ir_lot_data.odm_lot_number
        );
      END;
    END IF;
--
    --  履歴番号加算
    ln_history_no := ln_history_no + cn_one;
--
    --  変更後のロットマスタの情報をロットマスタ履歴テーブルに登録
    BEGIN
      INSERT INTO xxcmn_lots_mst_history(
        item_id,
        lot_id,
        history_no,
        lot_no,
        sublot_no,
        lot_desc,
        qc_grade,
        expaction_code,
        expaction_date,
        lot_created,
        expire_date,
        retest_date,
        strength,
        inactive_ind,
        origination_type,
        shipvend_id,
        vendor_lot_no,
        creation_date,
        last_update_date,
        created_by,
        last_updated_by,
        trans_cnt,
        delete_mark,
        text_code,
        last_update_login,
        program_application_id,
        program_id,
        program_update_date,
        request_id,
        attribute1,
        attribute2,
        attribute3,
        attribute4,
        attribute5,
        attribute6,
        attribute7,
        attribute8,
        attribute9,
        attribute10,
        attribute11,
        attribute12,
        attribute13,
        attribute14,
        attribute15,
        attribute16,
        attribute17,
        attribute18,
        attribute19,
        attribute20,
        attribute21,
        attribute22,
        attribute23,
        attribute24,
        attribute25,
        attribute26,
        attribute27,
        attribute28,
        attribute29,
        attribute30,
        attribute_category,
        odm_lot_number
      )
      SELECT
             ilm.item_id                   item_id,
             ilm.lot_id                    lot_id,
             ln_history_no                 history_no,
             ilm.lot_no                    lot_no,
             ilm.sublot_no                 sublot_no,
             ilm.lot_desc                  lot_desc,
             ilm.qc_grade                  qc_grade,
             ilm.expaction_code            expaction_code,
             ilm.expaction_date            expaction_date,
             ilm.lot_created               lot_created,
             ilm.expire_date               expire_date,
             ilm.retest_date               retest_date,
             ilm.strength                  strength,
             ilm.inactive_ind              inactive_ind,
             ilm.origination_type          origination_type,
             ilm.shipvend_id               shipvend_id,
             ilm.vendor_lot_no             vendor_lot_no,
             ilm.creation_date             creation_date,
             ilm.last_update_date          last_update_date,
             ilm.created_by                created_by,
             ilm.last_updated_by           last_updated_by,
             ilm.trans_cnt                 trans_cnt,
             ilm.delete_mark               delete_mark,
             ilm.text_code                 text_code,
             ilm.last_update_login         last_update_login,
             ilm.program_application_id    program_application_id,
             ilm.program_id                program_id,
             ilm.program_update_date       program_update_date,
             ilm.request_id                request_id,
             ilm.attribute1                attribute1,
             ilm.attribute2                attribute2,
             ilm.attribute3                attribute3,
             ilm.attribute4                attribute4,
             ilm.attribute5                attribute5,
             ilm.attribute6                attribute6,
             ilm.attribute7                attribute7,
             ilm.attribute8                attribute8,
             ilm.attribute9                attribute9,
             ilm.attribute10               attribute10,
             ilm.attribute11               attribute11,
             ilm.attribute12               attribute12,
             ilm.attribute13               attribute13,
             ilm.attribute14               attribute14,
             ilm.attribute15               attribute15,
             ilm.attribute16               attribute16,
             ilm.attribute17               attribute17,
             ilm.attribute18               attribute18,
             ilm.attribute19               attribute19,
             ilm.attribute20               attribute20,
             ilm.attribute21               attribute21,
             ilm.attribute22               attribute22,
             ilm.attribute23               attribute23,
             ilm.attribute24               attribute24,
             ilm.attribute25               attribute25,
             ilm.attribute26               attribute26,
             ilm.attribute27               attribute27,
             ilm.attribute28               attribute28,
             ilm.attribute29               attribute29,
             ilm.attribute30               attribute30,
             ilm.attribute_category        attribute_category,
             ilm.odm_lot_number            odm_lot_number
      FROM   ic_lots_mst ilm
      WHERE  ilm.item_id = ir_lot_data.item_id
      AND    ilm.lot_id  = ir_lot_data.lot_id;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_lot_mst_history;
-- Ver_1.6 E_本稼動_15887 ADD End
--
END xxcmn_common_pkg;
/
