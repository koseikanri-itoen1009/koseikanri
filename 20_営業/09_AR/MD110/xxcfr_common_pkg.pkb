CREATE OR REPLACE PACKAGE BODY xxcfr_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcfr_common_pkg(body)
 * Description      : 
 * MD.050           : なし
 * Version          : 1.3
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
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
-- Modify 2010.07.09 Ver1.3 Start
 *  awi_ship_code             P           ARWebInquiry用 納品先顧客コード値リスト
-- Modify 2010.07.09 Ver1.3 End
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
 *  2009-03-31   1.1    SCS 大川 恵      [障害T1_0210] 請求拠点担当電話番号取得関数 複数組織対応
 *  2010-03-31   1.2    SCS 安川 智博    障害「E_本稼動_02092」対応
 *                                       新規function「get_receive_updatable」を追加
 *  2010-07-09   1.3    SCS 廣瀬 真佐人  障害「E_本稼動_01990」対応
 *                                       新規Prucedure「awi_ship_code」を追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
  gv_conc_prefix     CONSTANT VARCHAR2(6)   := '$SRS$.';   -- コンカレント短縮名プリフィックス
  gv_const_yes       CONSTANT VARCHAR2(1)   := 'Y';        -- 使用可能='Y'
--
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
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR_COMMON_PKG'; -- パッケージ名
  gv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  gv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
  -- メッセージ番号
  gv_msg_cmn_001     CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; --コンカレント入力パラメータなし
  gv_msg_cmn_002     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00002'; --パラメータ名
-- トークン
  gv_tkn_parmn       CONSTANT VARCHAR2(15) := 'PARAM_NAME';       -- パラメータ名
  gv_tkn_parmv       CONSTANT VARCHAR2(15) := 'PARAM_VAL';        -- パラメータ値
  gv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- 取得データ項目名
--
  /**********************************************************************************
   * Function Name    : get_user_dept
   * Description      : ログインユーザ所属部門取得関数
   ***********************************************************************************/
  FUNCTION get_user_dept(
    in_user_id      IN NUMBER,          -- ユーザID
    id_get_date     IN DATE  )          -- 取得日付
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_user_dept'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_get_date     DATE;                                     -- 取得日付
    lv_dept_code    FND_FLEX_VALUES.FLEX_VALUE%TYPE := NULL ; -- 取得部門名
--
  BEGIN
--
    -- ====================================================
    -- ログインユーザ所属部門取得関数処理ロジックの記述
    -- ===================================================
    -- 取得日付を設定
      ld_get_date := TRUNC(id_get_date);
--
    -- 所属部門を取得
    BEGIN
      SELECT papf.attribute28  attribute28                  -- ログインユーザ所属部門
      INTO lv_dept_code
      FROM per_all_people_f  papf                           -- 従業員マスタ
      WHERE TRUNC(papf.effective_start_date) <= ld_get_date -- 有効開始日
        AND ld_get_date <= TRUNC(papf.effective_end_date)   -- 有効終了日
        AND EXISTS( SELECT 'x'
                    FROM fnd_user fndu                      -- EBSユーザマスタ
                    WHERE fndu.employee_id=papf.person_id   -- 被雇用者ID
                      AND fndu.user_id = in_user_id)        -- 従業員ID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    RETURN lv_dept_code;
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
      RETURN NULL;
  END get_user_dept;
--
--
/**********************************************************************************
   * Function Name    : chk_invoice_all_dept
   * Description      : 請求書全社出力権限判定関数
   ***********************************************************************************/
  FUNCTION chk_invoice_all_dept(
    iv_user_dept_code IN VARCHAR2,        -- 所属部門コード
    iv_invoice_type   IN VARCHAR2)        -- 請求書タイプ
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.chk_invoice_all_dept'; -- プログラム名
    cv_lookup_type CONSTANT FND_LOOKUP_TYPES.LOOKUP_TYPE%TYPE := 'XXCFR1_INVOICE_ALL_OUTPUT_DEPT'; -- 参照タイプ名
    cv_return_type CONSTANT VARCHAR2(1)   := 'N'; -- リターンコード（無効）
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_invoice_type VARCHAR2(1); --請求書タイプ
    lv_return_val   VARCHAR2(1) := cv_return_type;--リターンコード
--
  BEGIN
--
    -- ====================================================
    -- 請求書全社出力権限判定関数処理ロジックの記述
    -- ===================================================
    -- 請求書タイプを設定
    lv_invoice_type := iv_invoice_type;
--
    -- 請求書タイプを取得
    BEGIN
      SELECT CASE iv_invoice_type WHEN 'A' THEN flvv.attribute1 -- 請求金額一覧表
                                  WHEN 'G' THEN flvv.attribute2 -- 汎用請求書
                                  WHEN 'S' THEN flvv.attribute3 -- 標準請求書
                                  ELSE cv_return_type
             END                  invoice_type                  -- 請求書タイプ
      INTO lv_return_val
      FROM fnd_lookup_values_vl flvv                            -- 参照タイプビュー
      WHERE flvv.lookup_type = cv_lookup_type                   -- 参照タイプ
        AND flvv.lookup_code = iv_user_dept_code                -- 所属部門
        AND flvv.enabled_flag = 'Y'                             -- 有効フラグ
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  RETURN lv_return_val;
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
      RETURN NULL;
  END chk_invoice_all_dept;
--
  /**********************************************************************************
   * Procedure Name   : put_log_param
   * Description      : 入力パラメータ値ログ出力処理 (A-1)
   ***********************************************************************************/
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
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_param'; -- プログラム名
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
    lv_which_out    VARCHAR2(10) := 'OUTPUT';   -- ファイル出力
--
    -- *** ローカル変数 ***
    ln_target_cnt   NUMBER;         -- 重複している件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
    lv_param_val    VARCHAR2(2000); -- パラメータ値
    ln_which        NUMBER;         -- ファイル出力先
--
    -- *** ローカル・カーソル ***
--
    -- コンカレントパラメータ名抽出
    CURSOR conc_param_name_cur1
    IS
      SELECT fdfc.column_seq_num          column_seq_num,         -- カラムＮＯ
             fdfc.end_user_column_name    end_user_column_name,   -- カラム名
             fdfc.description             description             -- 摘要
      FROM fnd_concurrent_programs_vl  fcpv,
           fnd_descr_flex_col_usage_vl fdfc
      WHERE fdfc.application_id                = fnd_global.prog_appl_id  -- コンカレント・プログラムのアプリケーションID
        AND fdfc.descriptive_flexfield_name    = gv_conc_prefix || fcpv.concurrent_program_name
        AND fdfc.enabled_flag                  = gv_const_yes
        AND fdfc.application_id                = fcpv.application_id
        AND fcpv.concurrent_program_id         = fnd_global.conc_program_id  -- コンカレント・プログラムのプログラムID 
      ORDER BY fdfc.column_seq_num
    ;
--
    TYPE conc_param_name_tbl1 IS TABLE OF conc_param_name_cur1%ROWTYPE INDEX BY PLS_INTEGER;
    lt_conc_param_name_data1    conc_param_name_tbl1;
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
    -- ファイル出力先の選択
    IF ( iv_which = lv_which_out ) THEN
      ln_which := FND_FILE.OUTPUT;
    ELSE
      ln_which := FND_FILE.LOG;
    END IF;
--
    -- １行スペース
    FND_FILE.PUT_LINE(
       ln_which
      ,''
    );
    -- カーソルオープン
    OPEN conc_param_name_cur1;
--
    -- データの一括取得
    FETCH conc_param_name_cur1 BULK COLLECT INTO lt_conc_param_name_data1;
--
    -- 処理件数のセット
    ln_target_cnt := lt_conc_param_name_data1.COUNT;
--
    -- カーソルクローズ
    CLOSE conc_param_name_cur1;
--
    -- パラメータ定義ありの場合はパラメータをログに出力する
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        -- パラメータ値をループ値に合わせ切り替える
        lv_param_val :=
          CASE ln_loop_cnt
            WHEN 1 THEN iv_conc_param1
            WHEN 2 THEN iv_conc_param2
            WHEN 3 THEN iv_conc_param3
            WHEN 4 THEN iv_conc_param4
            WHEN 5 THEN iv_conc_param5
            WHEN 6 THEN iv_conc_param6
            WHEN 7 THEN iv_conc_param7
            WHEN 8 THEN iv_conc_param8
            WHEN 9 THEN iv_conc_param9
            WHEN 10 THEN iv_conc_param10
            ELSE NULL
          END;
--
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_cfr     -- 'XXCFR'
                                                      ,gv_msg_cmn_002
                                                      ,gv_tkn_parmn -- トークン'PARAM_NAME'
                                                      ,lt_conc_param_name_data1(ln_loop_cnt).description -- パラメータ名
                                                      ,gv_tkn_parmv -- トークン'PARAM_VAL'
                                                      ,lv_param_val) -- パラメータ値
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(ln_which, lv_errmsg);
      END LOOP null_data_loop1;
--
    -- パラメータ定義なしの場合はパラメータなしメッセージをログに出力する
    ELSE
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_ccp     -- 'XXCCP'
                                                      ,gv_msg_cmn_001) -- パラメータ値
                                                        -- コンカレント入力パラメータなし
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(ln_which, lv_errmsg);
--
    END IF;
--
    FND_FILE.PUT_LINE(
       ln_which
      ,''
    );
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
  END put_log_param;
--
  /**********************************************************************************
   * Function Name    : get_table_comment
   * Description      : テーブルコメント取得処理
   ***********************************************************************************/
  FUNCTION get_table_comment(
    iv_table_name          IN  VARCHAR2 )       -- テーブル名
  RETURN VARCHAR2 IS -- テーブルコメント
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_table_comment'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt     NUMBER;         -- 対象件数
    ln_loop_cnt       NUMBER;         -- ループカウンタ
    lv_table_name_jp  VARCHAR2(200);  -- テーブル名
--
    -- *** ローカル・カーソル ***
--
    -- テーブル名抽出
    CURSOR table_name_cur
    IS
      SELECT atc.comments     comments    -- テーブルコメント
      FROM all_tab_comments   atc
      WHERE atc.table_name           = iv_table_name
    ;
--
    TYPE table_name_tbl IS TABLE OF table_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_table_name_data    table_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN table_name_cur;
--
    -- データの一括取得
    FETCH table_name_cur BULK COLLECT INTO lt_table_name_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_table_name_data.COUNT;
--
    -- カーソルクローズ
    CLOSE table_name_cur;
--
    -- 対象データありの場合はテーブル名を戻り値に設定
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_table_name_jp := lt_table_name_data(ln_loop_cnt).comments;
      END LOOP null_data_loop1;
      RETURN lv_table_name_jp;
--
    -- 対象データなしの場合は、NULLを戻り値に設定
    ELSE
--
      RETURN NULL;
    END IF;
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
  END get_table_comment;
--
  /**********************************************************************************
   * Function Name    : get_user_profile_name
   * Description      : プロファイル名取得処理
   ***********************************************************************************/
  FUNCTION get_user_profile_name(
    iv_profile_name          IN  VARCHAR2 )       -- プロファイル名
  RETURN VARCHAR2 IS    -- ユーザプロファイル名
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_profile_name'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt       NUMBER;         -- 対象件数
    ln_loop_cnt         NUMBER;         -- ループカウンタ
    lv_profile_name_jp  VARCHAR2(200);  -- プロファイル名
--
    -- *** ローカル・カーソル ***
--
    -- プロファイル名抽出
    CURSOR profile_name_cur
    IS
      SELECT fpot.user_profile_option_name    user_profile_option_name,   -- プロファイル名
             fpot.description                 description                 -- 摘要
      FROM fnd_profile_options_tl fpot
      WHERE profile_option_name = iv_profile_name
        AND language = userenv ( 'LANG' );
--
    TYPE profile_name_tbl IS TABLE OF profile_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_profile_name_data    profile_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN profile_name_cur;
--
    -- データの一括取得
    FETCH profile_name_cur BULK COLLECT INTO lt_profile_name_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_profile_name_data.COUNT;
--
    -- カーソルクローズ
    CLOSE profile_name_cur;
--
    -- 対象データありの場合はプロファイル名を戻り値に設定
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_profile_name_jp := lt_profile_name_data(ln_loop_cnt).user_profile_option_name;
      END LOOP null_data_loop1;
      RETURN lv_profile_name_jp;
--
    -- 対象データなしの場合は、NULLを戻り値に設定
    ELSE
--
      RETURN NULL;
    END IF;
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
  END get_user_profile_name;
--
  /**********************************************************************************
   * Function Name    : get_cust_account_name
   * Description      : 顧客名称取得関数
   ***********************************************************************************/
  FUNCTION get_cust_account_name(
    iv_account_number      IN  VARCHAR2,      -- 1.顧客コード
    iv_kana_judge_type     IN  VARCHAR2       -- 2.カナ名判断区分(0:正式名称, 1:カナ名)
                        )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_cust_account_name'; -- PRG名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_party_name         hz_parties.party_name%TYPE := NULL                 ; -- 取得顧客名
    lv_party_kana_name    hz_parties.organization_name_phonetic%TYPE := NULL ; -- 取得顧客カナ名
--
  BEGIN
--
    -- ====================================================
    -- 顧客名称(カナ名)取得関数処理ロジックの記述
    -- ===================================================
    -- 顧客名称(カナ名)を取得
    BEGIN
      SELECT hzpt.party_name                  party_name,
             hzpt.organization_name_phonetic  organization_name_phonetic
      INTO   lv_party_name
            ,lv_party_kana_name
      FROM   hz_parties       hzpt,
             hz_cust_accounts hzca
      WHERE  hzca.party_id = hzpt.party_id
      AND    hzca.account_number = iv_account_number
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL ;
    END ;
    
    IF iv_kana_judge_type = 1 THEN
      RETURN lv_party_kana_name;
    ELSE
      RETURN lv_party_name ;
    END IF;
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
      RETURN NULL;
  END get_cust_account_name;
--
  /**********************************************************************************
   * Function Name    : get_col_comment
   * Description      : 項目コメント取得処理
   ***********************************************************************************/
  FUNCTION get_col_comment(
    iv_table_name          IN  VARCHAR2,        -- テーブル名
    iv_column_name         IN  VARCHAR2 )       -- 項目名
  RETURN VARCHAR2 IS -- 項目コメント
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_col_comment'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt     NUMBER;         -- 対象件数
    ln_loop_cnt       NUMBER;         -- ループカウンタ
    lv_column_name_jp all_col_comments.comments%type; -- 項目名
--
    -- *** ローカル・カーソル ***
--
    -- 項目名抽出
    CURSOR column_name_cur
    IS
      SELECT acc.comments     comments      -- 項目コメント
      FROM all_col_comments   acc
      WHERE acc.table_name           = iv_table_name
        AND acc.column_name          = iv_column_name
      ;
--
    TYPE column_name_tbl IS TABLE OF column_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_column_name_data    column_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN column_name_cur;
--
    -- データの一括取得
    FETCH column_name_cur BULK COLLECT INTO lt_column_name_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_column_name_data.COUNT;
--
    -- カーソルクローズ
    CLOSE column_name_cur;
--
    -- 対象データありの場合は項目名を戻り値に設定
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_column_name_jp := lt_column_name_data(ln_loop_cnt).comments;
      END LOOP null_data_loop1;
      RETURN lv_column_name_jp;
--
    -- 対象データなしの場合は、NULLを戻り値に設定
    ELSE
--
      RETURN NULL;
    END IF;
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
  END get_col_comment;
--
  /**********************************************************************************
   * Function Name    : lookup_dictionary
   * Description      : 日本語辞書参照
   ***********************************************************************************/
  FUNCTION lookup_dictionary(
     iv_loopup_type_prefix  IN  VARCHAR2         -- 参照タイプの接頭辞（アプリケーション短縮名と同じ）
    ,iv_keyword             IN  VARCHAR2         -- キーワード
  )
  RETURN VARCHAR2 IS -- 日本語内容
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lookup_dictionary'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_lookup_type_const  CONSTANT VARCHAR2(100) := '1_ERR_MSG_TOKEN';  -- 参照タイプ名の接頭辞以降
    cv_enabled_yes        CONSTANT VARCHAR2(1)   := 'Y';                -- 有効フラグ（Ｙ）
--
    -- *** ローカル変数 ***
    ln_target_cnt     NUMBER;         -- 対象件数
    ln_loop_cnt       NUMBER;         -- ループカウンタ
    lv_meaning_jp     fnd_lookup_values_vl.meaning%type; -- 日本語内容
--
    -- *** ローカル・カーソル ***
--
    -- テーブル名抽出
    CURSOR meaning_cur
    IS
      SELECT flvv.meaning         meaning       -- 日本語文言
      FROM fnd_lookup_values_vl   flvv
      WHERE flvv.lookup_type             = iv_loopup_type_prefix || cv_lookup_type_const   -- 日本語辞書の参照タイプ名
        AND flvv.lookup_code             = iv_keyword
        AND flvv.enabled_flag            = cv_enabled_yes
        AND ( flvv.start_date_active     IS NULL
           OR flvv.start_date_active     <= TRUNC ( SYSDATE ) )
        AND ( flvv.end_date_active       IS NULL
           OR flvv.end_date_active       >= TRUNC ( SYSDATE ) )
      ;
--
    TYPE l_meaning_ttype IS TABLE OF meaning_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_meaning_data      l_meaning_ttype;
--
  BEGIN
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN meaning_cur;
--
    -- データの一括取得
    FETCH meaning_cur BULK COLLECT INTO lt_meaning_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_meaning_data.COUNT;
--
    -- カーソルクローズ
    CLOSE meaning_cur;
--
    -- 対象データありの場合は日本語内容を戻り値に設定
    IF (ln_target_cnt > 0) THEN
      <<data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_meaning_jp := lt_meaning_data(ln_loop_cnt).meaning;
      END LOOP data_loop;
      RETURN lv_meaning_jp;
--
    -- 対象データなしの場合は、NULLを戻り値に設定
    ELSE
--
      RETURN NULL;
    END IF;
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
  END lookup_dictionary;
--
  /**********************************************************************************
   * Function Name    : get_date_param_trans
   * Description      : 日付パラメータ変換関数
   ***********************************************************************************/
  FUNCTION get_date_param_trans(
    iv_date_param             IN  VARCHAR2         -- 日付値パラメータ(文字列型)
  )
  RETURN DATE IS -- 日付値パラメータ(日付型)
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_date_param_trans'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_date_format     CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';  -- 参照タイプ名
--
    -- *** ローカル変数 ***
    ld_date_param     DATE;
--
    -- *** ローカル・カーソル ***
--
  BEGIN
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
    -- パラメータ変換
      ld_date_param := TO_DATE(iv_date_param, cv_date_format);
--
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;
--
    RETURN ld_date_param;
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
  END get_date_param_trans;
--
/************************************************************************
 * Procedure Name  : csv_out
 * Description     : OUTファイル出力処理
 ************************************************************************/
  PROCEDURE  csv_out(
    in_request_id  IN  NUMBER,    -- 1.要求ID
    iv_lookup_type IN  VARCHAR2,  -- 2.参照タイプ
    in_rec_cnt     IN  NUMBER,    -- 3.レコード件数
    ov_errbuf      OUT VARCHAR2,  -- 4.出力メッセージ
    ov_retcode     OUT VARCHAR2,  -- 5.リターンコード
    ov_errmsg      OUT VARCHAR2 ) -- 6.ユーザメッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'csv_out' ;          -- プログラム名
    cv_meg_cfr1_15   CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00015' ; -- 取得データなしメッセージ
    cv_meg_cfr1_23   CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00023' ; -- 対象データなしメッセージ
--
    --
    -- 列見出し・括り文字情報格納
    -- レコードタイプ
    TYPE rt_flv_type IS RECORD (meaning     fnd_lookup_values.meaning%TYPE,
                                attribute1  fnd_lookup_values.attribute1%TYPE) ;
    -- 表タイプ
    TYPE tt_flv_type IS TABLE OF rt_flv_type INDEX BY BINARY_INTEGER ;
  
    -- 表変数
    tt_flv   tt_flv_type ;
  
    -- 列見出し・括り文字取得カーソル
    CURSOR  cur_flv(
      iv_lookup_type  VARCHAR2)
    IS
      SELECT  meaning          meaning,         -- 列見出し
              attribute1       attribute1       -- 括り文字判定
      FROM    fnd_lookup_values_vl
      WHERE   lookup_type       =  iv_lookup_type
      AND     enabled_flag      =  'Y' 
      AND     NVL(start_date_active,TO_DATE('19000101','YYYYMMDD')) <= TRUNC(SYSDATE)
      AND     NVL(end_date_active,TO_DATE('22001231','YYYYMMDD'))   >= TRUNC(SYSDATE)
      ORDER BY TO_NUMBER( lookup_code );
    --
    -- 列見出し・括り文字取得レコード変数
    rec_flv   cur_flv%ROWTYPE ;
    --
    -- 動的SQL用参照カーソルタイプ
    TYPE cur_sql_type IS REF CURSOR ;
    --
    -- 動的SQL用参照カーソル
    cur_sql cur_sql_type ;
    --
    ln_flv_cnt       NUMBER := 0 ;
    lv_buf           VARCHAR2(32767) ;
    lv_sql           VARCHAR2(32767) ;
    lv_errmsg        VARCHAR2(32767) ;
    lv_errbuf        VARCHAR2(32767) ;
    --
  BEGIN
  --
    -- リターンコード・正常値設定
    ov_retcode := gv_status_normal ;
  --
  ------------------------------------
  -- １．列見出しおよび括り文字判別の取得と列見出しの出力
  ------------------------------------
  --
    -- 参照表より列見出し・括り判別取得
    <<cur_flv_loop>>
    FOR rec_flv IN cur_flv( iv_lookup_type )
    LOOP
      ln_flv_cnt := ln_flv_cnt + 1 ;
      --
      tt_flv(ln_flv_cnt).meaning    := rec_flv.meaning ;     -- 列見出し
      tt_flv(ln_flv_cnt).attribute1 := rec_flv.attribute1 ;  -- 括り文字判別
      
      IF (ln_flv_cnt = 1) THEN  -- 見出し1件目
      --
        lv_buf := lv_buf||'"'||rec_flv.meaning||'"' ;
        --
      ELSE                    -- 見出し2件目以降
      --
        lv_buf := lv_buf||',"'||rec_flv.meaning||'"' ;
        --
      END IF ;
      --
    END LOOP cur_flv_loop ;
    --
    IF ( ln_flv_cnt = 0 ) THEN
    --
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_cfr,     -- 'XXCFR'
                                                     cv_meg_cfr1_15,     -- 取得データなし
                                                     gv_tkn_data,
                                                     xxcfr_common_pkg.lookup_dictionary('XXCFR','CFR000A00005'))  -- トークン'列見出し'
                                                     ,1
                                                     ,5000) ;
      --
      RAISE global_api_expt ;
    END IF ;
    --
    -- CSV出力（列見出し）
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT , lv_buf ) ;
    --
    -- 出力変数クリア
    lv_buf := NULL ;
    --
    ------------------------------------
    -- ２．処理件数0件の場合
    ------------------------------------
    IF (in_rec_cnt = 0) THEN
    --
      lv_buf := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_cfr,     -- 'XXCFR'
                                                  cv_meg_cfr1_23)     -- 対象データなし
                                                  ,1
                                                  ,5000) ;
      --
      -- CSV出力（0件メッセージ）
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT , lv_buf ) ;
      --
      -- 出力変数クリア
      lv_buf := NULL ;
      --
    ------------------------------------
    -- 3．データ出力
    ------------------------------------
    ELSE
    --
      -- SELECT句
      lv_sql   := 'SELECT ' ;
      --
      -- 列項目
      <<i_loop>>
      FOR  i IN 1 .. ln_flv_cnt
      LOOP
        IF (i = 1) THEN  -- 列1
        --
          IF (tt_flv(i).attribute1 = 'Y') THEN  -- 括りあり
          --
            lv_sql := lv_sql||'''"''||col'||i||'||''"''' ;
            --
          ELSE                                   -- 括りなし
          --
            lv_sql   := lv_sql||'col'||i ;
            --
          END IF ;
          --
        ELSE             -- 列2以降
        --
          IF (tt_flv(i).attribute1 = 'Y') THEN  -- 括りあり
          --
            lv_sql := lv_sql||'||'',"''||col'||i||'||''"''' ;
            --
          ELSE                                   -- 括りなし
          --
            lv_sql := lv_sql||'||'',''||col'||i ;
            --
          END IF ;
          --
        END IF ;
        --
      END LOOP i_loop ;
      --
      -- FROM句
      lv_sql := lv_sql||' FROM xxcfr_csv_outs_temp ' ;
      --
      -- WHERE句：要求ID
      lv_sql := lv_sql||' WHERE request_id = '||in_request_id ;
      --
      -- ORDER BY句
      lv_sql := lv_sql||' ORDER BY seq' ;
      --
      --
      --DBMS_OUTPUT.PUT_LINE(lv_sql) ;
      --
      -- 動的SQLのオープンとフェッチ
      OPEN cur_sql FOR lv_sql ;
        LOOP
          FETCH  cur_sql INTO lv_buf ;
          EXIT WHEN cur_sql%NOTFOUND ;
          --
            -- 1行ずつOUTファイルへ出力
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_buf) ;
            --
        END LOOP ;
        --
      CLOSE cur_sql ;
      --
    END IF ;
    --
    --
  EXCEPTION
  --
  --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      --
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END csv_out ;
  --
  /**********************************************************************************
   * Function Name    : get_base_target_tel_num
   * Description      : 請求拠点担当電話番号取得関数
   ***********************************************************************************/
  FUNCTION get_base_target_tel_num(
    iv_bill_acct_code      IN  VARCHAR2       -- 1.請求先顧客コード
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_base_target_tel_num'; -- PRG名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_base_tel_num       hz_locations.address_lines_phonetic%TYPE := NULL; -- 請求拠点担当電話番号
--
  BEGIN
--
    -- ====================================================
    -- 請求拠点担当電話番号取得関数処理ロジックの記述
    -- ===================================================
    -- 請求拠点担当電話番号を取得
    BEGIN
      SELECT base_hzlo.address_lines_phonetic  base_tel_num    --電話番号
      INTO   lv_base_tel_num
      FROM   hz_cust_accounts                  bill_hzca,      --顧客マスタ(請求先)
             xxcmm_cust_accounts               bill_hzad,      --顧客追加情報(請求先)
             hz_cust_accounts                  base_hzca,      --顧客マスタ(請求拠点)
-- Modify 2009.03.31 Ver1.1 Start
             hz_cust_acct_sites                base_hasa,      --顧客所在地ビュー(請求拠点)
--             hz_cust_acct_sites_all            base_hasa,      --顧客所在地(請求拠点)
-- Modify 2009.03.31 Ver1.1 End
             hz_locations                      base_hzlo,      --顧客事業所(請求拠点)
             hz_party_sites                    base_hzps       --パーティサイト(請求拠点)
      WHERE  bill_hzca.account_number = iv_bill_acct_code      --請求先顧客コード
      AND    bill_hzca.cust_account_id = bill_hzad.customer_id    
      AND    base_hzca.account_number = bill_hzad.bill_base_code
      AND    base_hzca.cust_account_id = base_hasa.cust_account_id
      AND    base_hasa.party_site_id = base_hzps.party_site_id    
      AND    base_hzps.location_id = base_hzlo.location_id        
      AND    base_hzca.customer_class_code = '1'                    
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL ;
    END ;
    
    RETURN lv_base_tel_num;
    
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
      RETURN NULL;
  END get_base_target_tel_num;
--
  /**********************************************************************************
   * Function Name    : get_receive_updatable
   * Description      : 入金画面 顧客変更可能判定
   ***********************************************************************************/
  FUNCTION get_receive_updatable(
    in_cash_receipt_id IN NUMBER,
    iv_gl_date IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_receive_updatable'; -- PRG名
    cv_appl_short_name_ar      CONSTANT fnd_application.application_short_name%TYPE := 'AR'; -- ARアプリケーション短縮名
    cv_prof_name_gl_bks_id     CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID'; -- プロファイル帳簿ID
    cv_date_format             CONSTANT VARCHAR2(100) := 'DD-MON-RRRR'; -- 入金日 日付フォーマット
    cv_return_value_y          CONSTANT VARCHAR2(1) := 'Y'; -- 戻り値'Y'
    cv_return_value_n          CONSTANT VARCHAR2(1) := 'N'; -- 戻り値'N'
    cv_receivable_status_unapp CONSTANT ar_receivable_applications_all.status%TYPE := 'UNAPP'; -- 未消込ステータス
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_in_gl_date DATE;
    lv_closing_status gl_period_statuses.closing_status%TYPE;
    lv_return_value VARCHAR2(1);
    ln_receivable_app_cnt NUMBER;
    -- ===============================
    -- ローカルカーソル
    CURSOR cur_get_closing_status(
      id_gl_date IN DATE
    )
    IS
    SELECT gps.closing_status AS closing_status
    FROM fnd_application fap
        ,gl_period_statuses gps
    WHERE fap.application_short_name = cv_appl_short_name_ar
      AND gps.set_of_books_id = fnd_profile.value(cv_prof_name_gl_bks_id)
      AND ld_in_gl_date BETWEEN gps.start_date AND gps.end_date
      AND gps.adjustment_period_flag = 'N'
      AND fap.application_id = gps.application_id
    ;
--
  BEGIN
--
    ld_in_gl_date := TO_DATE(iv_gl_date,cv_date_format);
    OPEN cur_get_closing_status(ld_in_gl_date);
    FETCH cur_get_closing_status INTO lv_closing_status;
    IF iv_gl_date IS NULL THEN
      lv_return_value := cv_return_value_y;
    ELSIF cur_get_closing_status%NOTFOUND THEN
      lv_return_value := cv_return_value_y;
    ELSIF lv_closing_status = 'O' THEN
      lv_return_value := cv_return_value_y;
    ELSE 
      SELECT COUNT('X') AS cnt
      INTO ln_receivable_app_cnt
      FROM ar_receivable_applications_all araa
      WHERE araa.cash_receipt_id = in_cash_receipt_id
      AND araa.status = cv_receivable_status_unapp;
      IF ln_receivable_app_cnt = 0 THEN
        lv_return_value := cv_return_value_y;
      ELSE
        lv_return_value := cv_return_value_n;
      END IF;
    END IF;
    CLOSE cur_get_closing_status;
    RETURN lv_return_value;
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
      RETURN NULL;
  END get_receive_updatable;
--
  /**********************************************************************************
   * Procedure Name    : awi_ship_code
   * Description      : ARWebInquiry用 納品先顧客コード値リスト
   *                    ※xx03_glwi_lov_pkg.input_departmentを応用
   ***********************************************************************************/
   PROCEDURE awi_ship_code(
    p_sql_type         IN     VARCHAR2,
    p_sql              IN OUT VARCHAR2,
    p_list_filter_item IN     VARCHAR2,
    p_sort_item        IN     VARCHAR2,
    p_sort_method      IN     VARCHAR2,
    p_segment_id       IN     NUMBER,
    p_child_condition  IN     VARCHAR2,
    p_parent_condition IN     VARCHAR2 DEFAULT NULL)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    -- ===============================
    -- ローカル変数
    -- ===============================
    l_sql_rec                   xgv_common.sql_rtype;  -- SQL文とバインド変数格納用
--
  BEGIN
--
    --------------------------------------------------
    -- 動的SQLの組み立て開始
    --------------------------------------------------
-- 値リストを開く際に、総件数を取得。懐中電灯ボタンを押下する際に通るロジック。
    IF  p_sql_type = 'COUNT'
    THEN
      l_sql_rec.text(1) := 'SELECT count(xtcv.name)';
      l_sql_rec.text(2) := 'FROM   xxcfr_awi_ship_code_v xtcv';
      l_sql_rec.text(3) := 'WHERE';
-- 値リストの表を表示する際にデータを取得。懐中電灯ボタンを押下する際に通るロジック。
    ELSE
      l_sql_rec.text(1) := 'SELECT NULL,';
      l_sql_rec.text(2) := '       NULL,';
      l_sql_rec.text(3) := '       xtcv.name name,';
      l_sql_rec.text(4) := '       xtcv.description description';
      l_sql_rec.text(5) := 'FROM   xxcfr_awi_ship_code_v xtcv';
      l_sql_rec.text(6) := 'WHERE';
    END IF;
    -- 値抽出条件に既に検索条件が指定されている場合
    -- 検索条件をWHERE句の書式に変更
    IF  p_child_condition IS NOT NULL
    THEN
-- 値リスト内の検索 検索項目=値のとき
      IF  p_list_filter_item = 'VALUE'
      THEN
        xgv_common.get_where_clause(
          l_sql_rec, 'xtcv', 'name', p_child_condition);
-- 値リスト内の検索 検索項目=摘要のとき
      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_child_condition));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'upper(xtcv.description) like :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
-- 値抽出条件に検索条件が指定されていない場合はWHERE句がないので1=1を追加。
    ELSE
      -- セキュリティルール用に必ず成立する条件をSQLに追加
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '       1 = 1';
    END IF;
    -- 動的SQLにORDER BY句の追加
    IF  p_sql_type = 'LIST'
    THEN
-- 値リストを表示する際にソート順を追加。
      IF  p_sort_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY xtcv.name ' || p_sort_method;
-- ロジックとして通っていない模様。念のため残しておく。
      ELSE
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY xtcv.description ' || p_sort_method;
      END IF;
    END IF;
    --------------------------------------------------
    -- 動的SQLの組み立て終了
    --------------------------------------------------
    -- 動的SQLのデバッグ用出力（HTMLコメントとして出力）
    xgv_common.show_sql_statement(l_sql_rec);
    -- xgv_common.sql_rtype型に格納したSQL文を、通常の文字列型のSQL文に変換
    xgv_common.get_plain_sql_statement(p_sql, l_sql_rec);
  END awi_ship_code;
--
END xxcfr_common_pkg;
/
