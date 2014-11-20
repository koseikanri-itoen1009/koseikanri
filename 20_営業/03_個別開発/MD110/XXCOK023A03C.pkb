CREATE OR REPLACE PACKAGE BODY XXCOK023A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A03C(body)
 * Description      : 運送費予算及び運送費実績を拠点別品目別（単品別）月別にCSVデータ形式で要求出力します。
 * MD.050           : 運送費予算一覧表出力 MD050_COK_023_A03
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                  初期処理(A-1)
 *  put_file_date         要求出力処理(A-7 ～ A-9)
 *  put_file_set          出力データの編集処理(A-7 ～ A-9)
 *  get_base_data         拠点抽出処理(A-2)
 *  get_put_file_data     要求出力対象データの取得・出力処理(A-2 ～ A-6)
 *  submain               メイン処理プロシージャ
 *  main                  コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.0   SCS T.Taniguchi  新規作成
 *  2009/02/06    1.1   SCS T.Taniguchi  [障害COK_017] クイックコードビューの有効日・無効日の判定追加
 *  2009/03/02    1.2   SCS T.Taniguchi  [障害COK_069] 入力パラメータ「職責タイプ」により、拠点の取得範囲を制御
 *  2009/05/15    1.3   SCS A.Yano       [障害T1_1001] 出力される金額単位を千円に修正
 *  2009/09/03    1.4   SCS S.Moriyama   [障害0001257] OPM品目マスタ取得条件追加
 *  2009/10/02    1.5   SCS S.Moriyama   [障害E_T3_00630] VDBM残高一覧表が出力されない（同類不具合調査）
 *  2009/12/07    1.6   SCS K.Nakamura   [障害E_本稼動_00022] PT対応（品目カテゴリから政策群コードを取得）
 *
 *****************************************************************************************/
--
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1) := '.';
-- グローバル変数
  gv_out_msg              VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg              VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user            VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name            VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status          VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt           NUMBER DEFAULT 0;       -- 対象件数
  gn_normal_cnt           NUMBER DEFAULT 0;       -- 正常件数
  gn_error_cnt            NUMBER DEFAULT 0;       -- エラー件数
  gn_warn_cnt             NUMBER DEFAULT 0;       -- スキップ件数
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(12) := 'XXCOK023A03C'; -- パッケージ名
  -- メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- エラー終了メッセージ
  cv_msg_xxccp1_90000       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- 対象件数出力
  cv_msg_xxccp1_90001       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- 成功件数出力
  cv_msg_xxccp1_90002       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- エラー件数出力
  cv_msg_xxccp1_90003       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- スキップ件数出力
  cv_msg_xxcok1_10184       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10184'; -- 対象データ無し
  cv_msg_xxcok1_00003       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003'; -- プロファイル取得エラー
  cv_msg_xxcok1_00013       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00013'; -- 在庫組織ID取得エラー
  cv_msg_xxcok1_00052       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00052'; -- 職責ID取得エラー
  cv_msg_xxcok1_10182       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10182'; -- 拠点取得エラー
  cv_msg_xxcok1_10183       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10183'; -- 商品名取得エラー
  cv_msg_xxcok1_00014       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00014'; -- 月情報取得エラー(値セット取得)
  cv_msg_xxcok1_00018       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00018'; -- コンカレント入力パラメータ(拠点コード)
  cv_msg_xxcok1_00019       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00019'; -- コンカレント入力パラメータ2(予算年度)
  cv_msg_xxcok1_00012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00012'; -- 所属拠点エラー
  cv_msg_xxcok1_10367       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10367'; -- 要求出力エラー
  cv_msg_xxcok1_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015'; -- クイックコード取得エラー
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- 業務処理日付取得エラー
  -- トークン
  cv_year                   CONSTANT VARCHAR2(4)  := 'YEAR';           -- 予算年度
  cv_resp_name              CONSTANT VARCHAR2(9)  := 'RESP_NAME';      -- 職責名
  cv_profile                CONSTANT VARCHAR2(7)  := 'PROFILE';        -- プロファイル・オプション名
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';  -- 拠点コード
  cv_item_code              CONSTANT VARCHAR2(9)  := 'ITEM_CODE';      -- 品目コード
  cv_flex_value             CONSTANT VARCHAR2(14) := 'FLEX_VALUE_SET'; -- 値セット名
  cv_org_code               CONSTANT VARCHAR2(8)  := 'ORG_CODE';       -- 在庫組織コード
  cv_count                  CONSTANT VARCHAR2(5)  := 'COUNT';          -- 処理件数
  cv_user_id                CONSTANT VARCHAR2(7)  := 'USER_ID';        -- ユーザーID
  cv_token_lookup_value_set CONSTANT VARCHAR2(16) := 'LOOKUP_VALUE_SET';
  -- application_short_name
  cv_appl_name_xxcok        CONSTANT VARCHAR2(5)  := 'XXCOK'; -- アプリケーションショートネーム(XXCOK)
  cv_appl_name_xxccp        CONSTANT VARCHAR2(5)  := 'XXCCP'; -- アプリケーションショートネーム(XXCCP)
  -- カスタム・プロファイル
  cv_pro_organization_code  CONSTANT VARCHAR2(21)  := 'XXCOK1_ORG_CODE_SALES';    -- 在庫組織コード
  cv_pro_head_office_code   CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF2_DEPT_HON';     -- 本社の部門コード
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura ADD START
  cv_pro_policy_group_code  CONSTANT VARCHAR2(24)  := 'XXCOK1_POLICY_GROUP_CODE'; -- 政策群コード
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura ADD END
 -- 値セット名
  cv_flex_st_name_department  CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT';           -- 部門
  cv_flex_st_name_bd_month    CONSTANT VARCHAR2(25) := 'XXCOK1_BUDGET_MONTH_ORDER'; -- 予算月
  -- その他
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';          -- フラグ('Y')
  cv_yyyymmdd                 CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD'; -- 日付フォーマット
  cv_cust_cd_base             CONSTANT VARCHAR2(1)   := '1';          -- 顧客区分('1':拠点)
  cv_put_code_line            CONSTANT VARCHAR2(1)   := '1';          -- 出力区分('1':明細)
  cv_put_code_sum             CONSTANT VARCHAR2(1)   := '2';          -- 出力区分('2':拠点計)
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';          -- カンマ
  cv_kbn_koguchi              CONSTANT VARCHAR2(1)   := '1';          -- 小口区分('1':小口)
  cv_kbn_syatate              CONSTANT VARCHAR2(1)   := '0';          -- 小口区分('0':車立)
  cn_number_0                 CONSTANT NUMBER        := 0;
  cn_number_1                 CONSTANT NUMBER        := 1;
  cv_month01                  CONSTANT VARCHAR2(2)   := '01';         -- 1月
  cv_month05                  CONSTANT VARCHAR2(2)   := '05';         -- 5月
  cv_resp_name_val            CONSTANT VARCHAR2(100) := fnd_global.resp_name; -- 職責名
  cv_resp_type_0              CONSTANT VARCHAR2(1)   := '0';          -- 主管部署担当者職責
  cv_resp_type_1              CONSTANT VARCHAR2(1)   := '1';          -- 本部部門担当者職責
  cv_resp_type_2              CONSTANT VARCHAR2(1)   := '2';          -- 拠点部門_担当者職責
  -- 参照タイプ
  cv_lookup_type_put_val      CONSTANT VARCHAR2(28)  := 'XXCOK1_COST_BUDGET_PUT_VALUE';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_base_code            VARCHAR2(4)  DEFAULT NULL; -- 入力パラメータの拠点コード
  gv_budget_year          VARCHAR2(4)  DEFAULT NULL; -- 入力パラメータの予算年度
  gv_org_code             VARCHAR2(3)  DEFAULT NULL; -- 在庫組織コード
  gv_head_office_code     VARCHAR2(4)  DEFAULT NULL; -- 本社部門コード
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura ADD START
  gv_policy_group_code    VARCHAR2(12) DEFAULT NULL; -- 政策群コード
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura ADD END
  gn_org_id               NUMBER       DEFAULT NULL; -- 在庫組織ID
  gn_resp_id              NUMBER       DEFAULT NULL; -- ログイン職責ID
  gn_user_id              NUMBER       DEFAULT NULL; -- ログインユーザーID
  gn_put_count            NUMBER       DEFAULT 0;    -- 明細出力カウント
  gv_target_year          VARCHAR2(4)  DEFAULT NULL; -- 対象年度
  gd_process_date         DATE         DEFAULT NULL; -- 業務処理日付
  gv_resp_type            VARCHAR2(1)  DEFAULT NULL; -- 職責タイプ
--
  -- ===============================
  -- レコードタイプの宣言部
  -- ===============================
--
  -- 拠点情報のレコードタイプ
  TYPE base_rec IS RECORD(
    base_code        VARCHAR2(4), -- 拠点コード
    base_name        VARCHAR2(50) -- 拠点名
  );
--
  -- 運送費予算一覧表出力のレコードタイプ
  TYPE budget_rec IS RECORD(
    base_code          VARCHAR2(4),  -- 拠点コード
    base_name          VARCHAR2(50), -- 拠点名
    budget_item_code   VARCHAR2(7),  -- 予算_商品コード
    budget_item_name   VARCHAR2(60), -- 予算_商品名(略称)
    budget_month       VARCHAR2(2)   -- 予算_月
  );
--
  -- ===============================
  -- テーブルタイプの宣言部
  -- ===============================
--
  -- 拠点情報のテーブルタイプ
  TYPE base_tbl IS TABLE OF base_rec INDEX BY BINARY_INTEGER;
--
  -- 運送費予算一覧表出力のテーブルタイプ
  TYPE budget_tbl IS TABLE OF budget_rec INDEX BY BINARY_INTEGER;
--
  -- 金額・数量のテーブルタイプ
  TYPE number_tbl IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
  g_default_value  number_tbl;   -- 月別値のデフォルト
--
  /**********************************************************************************
   * Procedure Name   : put_file_date
   * Description      : 要求出力処理(A-7 ～ A-9)
   ***********************************************************************************/
  PROCEDURE put_file_date(
    ov_errbuf           OUT   VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT   VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT   VARCHAR2,   -- ユーザー・エラー・メッセージ --# 固定 #
    iv_header_data      IN    VARCHAR2,   -- 出力レコードの見出し部分
    i_month_data_ttype  IN    number_tbl) -- 月別の値
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'put_file_date'; -- プログラム名
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_file_value     VARCHAR2(500) DEFAULT NULL;
    ln_index_cunt     NUMBER        DEFAULT 0;
    ln_half_term      NUMBER        DEFAULT 0;
    ln_yearly         NUMBER        DEFAULT 0;
    lb_retcode        BOOLEAN;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- 月別のデータが設定されていない場合
    IF ( i_month_data_ttype.COUNT = 0 ) THEN
      lv_file_value := iv_header_data;
    -- 月別の値を連結する
    ELSE
      -- 月別データの連結ループ
      -- ループの回数に対応する月値は、下記の通りになる
      --「1 ⇒ レコードのヘッダ部分」、「2 ⇒ 5月」、「3 ⇒ 6月」、「4 ⇒ 7月」、「5 ⇒ 8月」、「6 ⇒ 9月」、
      --「7 ⇒ 10月」、「8 ⇒ 前期計」、「9 ⇒ 11月」、「10 ⇒ 12月」、「11 ⇒ 1月」、「12 ⇒ 2月」、
      --「13 ⇒ 3月」、「14 ⇒ 4月」、「15 ⇒ 年間計」
--
      -- データを連結して、出力レコードを作成
      <<month_value_loop>>
      FOR i IN 1..15 LOOP
        IF ( i = 1 ) THEN -- ヘッダ
          lv_file_value := iv_header_data;
        ELSIF ( i = 8 ) THEN  -- 前期計
          lv_file_value := lv_file_value || cv_comma || ln_half_term;
        ELSIF ( i = 15 ) THEN -- 年間計
          lv_file_value := lv_file_value || cv_comma || ln_yearly;
        ELSE
          -- 月別データのindexは5月からのデータが最初になる為、2回目のループより発番する
          ln_index_cunt := ln_index_cunt + 1;
          -- 前期集計
          ln_half_term  := ln_half_term + i_month_data_ttype(ln_index_cunt);
          -- 年間集計
          ln_yearly     := ln_yearly + i_month_data_ttype(ln_index_cunt);
          -- 月別データを連結
          lv_file_value := lv_file_value || cv_comma || i_month_data_ttype(ln_index_cunt);
        END IF;
      END LOOP month_value_loop;
    END IF;
--
    -- ===============================
    -- 運送費予算一覧表データ出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT,
                    iv_message  => lv_file_value,  --出力データ
                    in_new_line => cn_number_0     -- 改行数
                  );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_file_date;
--
  /**********************************************************************************
   * Procedure Name   : put_file_set
   * Description      : 出力データの編集処理(A-7 ～ A-9)
   ***********************************************************************************/
  PROCEDURE put_file_set(
    ov_errbuf                   OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_put_code                 IN  VARCHAR2 DEFAULT NULL, -- 出力フラグ(1:明細、2:拠点計)
    iv_back_base_code           IN  VARCHAR2 DEFAULT NULL, -- 拠点コード(前回値の退避)
    iv_base_code                IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_base_name                IN  VARCHAR2 DEFAULT NULL, -- 拠点名
    iv_item_code                IN  VARCHAR2 DEFAULT NULL, -- 商品コード
    iv_item_short_name          IN  VARCHAR2 DEFAULT NULL, -- 商品名(略称)
    i_budget_qty_tyype          IN  number_tbl,            -- 予算_数量
    i_budget_amt_tyype          IN  number_tbl,            -- 予算_金額
    i_result_syatate_qty_tyype  IN  number_tbl,            -- 実績(車立)_数量
    i_result_syatate_amt_tyype  IN  number_tbl,            -- 実績(車立)_金額
    i_result_koguchi_qty_tyype  IN  number_tbl,            -- 実績(小口)_数量
    i_result_koguchi_amt_tyype  IN  number_tbl,            -- 実績(小口)_金額
    i_sum_result_qty_tyype      IN  number_tbl,            -- 実績計_数量
    i_sum_result_qmt_tyype      IN  number_tbl,            -- 実績計_金額
    i_sum_syatate_amt_tyype     IN  number_tbl,            -- 拠点計_車立金額
    i_sum_koguchi_amt_tyype     IN  number_tbl,            -- 拠点計_小口金額
    i_sum_budget_amt_tyype      IN  number_tbl,            -- 拠点計_予算金額
    i_sum_result_amt_tyype      IN  number_tbl,            -- 拠点計_実績金額
    i_sum_diff_amt_tyype        IN  number_tbl)            -- 拠点計_差額金額
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(12) := 'put_file_set'; -- プログラム名
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    ln_target_cnt NUMBER         DEFAULT 0;     -- クイックコードデータ取得件数
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・カーソル ***
    -- 見出し取得カーソル
    CURSOR put_value_cur
    IS
      SELECT attribute1 AS put_val
      FROM   xxcok_lookups_v
      WHERE  lookup_type                              = cv_lookup_type_put_val
      AND    NVL( start_date_active,gd_process_date ) <= gd_process_date  -- 適用開始日
      AND    NVL( end_date_active,gd_process_date )   >= gd_process_date  -- 適用終了日
      ORDER BY TO_NUMBER(lookup_code)
    ;
    TYPE put_value_ttype IS TABLE OF put_value_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    put_value_tab put_value_ttype;
--
    -- *** ローカル変数 ***
    lb_retcode  BOOLEAN      DEFAULT TRUE;  -- メッセージ出力関数戻り値
    -- *** 例外 ***
    put_data_expt            EXCEPTION;     -- 要求出力エラー
    no_data_expt             EXCEPTION;      -- データ取得エラー
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  put_value_cur;
    FETCH put_value_cur BULK COLLECT INTO put_value_tab;
    CLOSE put_value_cur;
    -- ===============================================
    -- 対象件数取得
    -- ===============================================
    ln_target_cnt := put_value_tab.COUNT;
    IF ( ln_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    -- ===============================
    -- 明細出力
    -- ===============================
    IF ( iv_put_code = cv_put_code_line ) THEN
      -- 1件目または拠点が変わったら出力する(見出し部分)
      IF ( iv_back_base_code <> iv_base_code )
        OR ( gn_put_count = 0 ) THEN
        -- 拠点項目行出力
        put_file_date(
          ov_errbuf           => lv_errbuf,       -- エラー・メッセージ
          ov_retcode          => lv_retcode,      -- リターン・コード
          ov_errmsg           => lv_errmsg,       -- ユーザー・エラー・メッセージ
          iv_header_data      => put_value_tab(1).put_val
                                 || iv_base_code
                                 || cv_comma
                                 || iv_base_name, -- レコードのヘッダ部
          i_month_data_ttype  => g_default_value  -- 月別の値
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE put_data_expt;
        END IF;
        -- 見出し出力(単位)
        put_file_date(
          ov_errbuf           => lv_errbuf,                -- エラー・メッセージ
          ov_retcode          => lv_retcode,               -- リターン・コード
          ov_errmsg           => lv_errmsg,                -- ユーザー・エラー・メッセージ
          iv_header_data      => put_value_tab(2).put_val, -- レコードのヘッダ部
          i_month_data_ttype  => g_default_value           -- 月別の値
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE put_data_expt;
        END IF;
        -- 行見出し
        put_file_date(
          ov_errbuf           => lv_errbuf,                -- エラー・メッセージ
          ov_retcode          => lv_retcode,               -- リターン・コード
          ov_errmsg           => lv_errmsg,                -- ユーザー・エラー・メッセージ
          iv_header_data      => put_value_tab(3).put_val, -- レコードのヘッダ部
          i_month_data_ttype  => g_default_value           -- 月別の値
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE put_data_expt;
        END IF;
      END IF;
      -- 実績(車立) 数量行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                   -- エラー・メッセージ
        ov_retcode          => lv_retcode,                  -- リターン・コード
        ov_errmsg           => lv_errmsg,                   -- ユーザー・エラー・メッセージ
        iv_header_data      => iv_item_code
                               || cv_comma
                               || iv_item_short_name
                               || put_value_tab(4).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_result_syatate_qty_tyype   -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 実績(車立) 金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                  -- エラー・メッセージ
        ov_retcode          => lv_retcode,                 -- リターン・コード
        ov_errmsg           => lv_errmsg,                  -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(5).put_val,   -- レコードのヘッダ部
        i_month_data_ttype  => i_result_syatate_amt_tyype  -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 実績(小口) 数量行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                  -- エラー・メッセージ
        ov_retcode          => lv_retcode,                 -- リターン・コード
        ov_errmsg           => lv_errmsg,                  -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(6).put_val,   -- レコードのヘッダ部
        i_month_data_ttype  => i_result_koguchi_qty_tyype  -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 実績(小口) 金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                  -- エラー・メッセージ
        ov_retcode          => lv_retcode,                 -- リターン・コード
        ov_errmsg           => lv_errmsg,                  -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(5).put_val,   -- レコードのヘッダ部
        i_month_data_ttype  => i_result_koguchi_amt_tyype  -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 予算 数量行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- エラー・メッセージ
        ov_retcode          => lv_retcode,               -- リターン・コード
        ov_errmsg           => lv_errmsg,                -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(7).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_budget_qty_tyype        -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 予算 金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- エラー・メッセージ
        ov_retcode          => lv_retcode,               -- リターン・コード
        ov_errmsg           => lv_errmsg,                -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(5).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_budget_amt_tyype        -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 実績計 数量行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- エラー・メッセージ
        ov_retcode          => lv_retcode,               -- リターン・コード
        ov_errmsg           => lv_errmsg,                -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(8).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_sum_result_qty_tyype    -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 実績計 金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- エラー・メッセージ
        ov_retcode          => lv_retcode,               -- リターン・コード
        ov_errmsg           => lv_errmsg,                -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(5).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_sum_result_qmt_tyype    -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
    END IF;
    -- ===============================
    -- 拠点計出力
    -- ===============================
    IF ( iv_put_code = cv_put_code_sum ) THEN
      -- 拠点計_車立金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- エラー・メッセージ
        ov_retcode          => lv_retcode,               -- リターン・コード
        ov_errmsg           => lv_errmsg,                -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(9).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_sum_syatate_amt_tyype   -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 拠点計_小口金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- エラー・メッセージ
        ov_retcode          => lv_retcode,                -- リターン・コード
        ov_errmsg           => lv_errmsg,                 -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(10).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_sum_koguchi_amt_tyype    -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 拠点計_予算金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- エラー・メッセージ
        ov_retcode          => lv_retcode,                -- リターン・コード
        ov_errmsg           => lv_errmsg,                 -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(11).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_sum_budget_amt_tyype     -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 拠点計_実績金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- エラー・メッセージ
        ov_retcode          => lv_retcode,                -- リターン・コード
        ov_errmsg           => lv_errmsg,                 -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(12).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_sum_result_amt_tyype     -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- 拠点計_差額(予-実)金額行出力
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- エラー・メッセージ
        ov_retcode          => lv_retcode,                -- リターン・コード
        ov_errmsg           => lv_errmsg,                 -- ユーザー・エラー・メッセージ
        iv_header_data      => put_value_tab(13).put_val, -- レコードのヘッダ部
        i_month_data_ttype  => i_sum_diff_amt_tyype       -- 月別の値
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** データ取得例外 ***
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_type_put_val
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 要求出力例外 ***
    WHEN put_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_10367
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_file_set;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 拠点抽出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf           OUT     VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT     VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg           OUT     VARCHAR2, -- ユーザー・エラー・メッセージ --# 固定 #
    o_budget_ttype      OUT     base_tbl) -- 拠点情報
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_base_data'; -- プログラム名
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    ln_base_index     NUMBER       DEFAULT 1;    -- 拠点情報用インデックス
    lv_resp_nm        VARCHAR2(40) DEFAULT NULL; -- 職責名
    ln_admin_resp_id  NUMBER       DEFAULT NULL; -- 主管部署担当者
    ln_main_resp_id   NUMBER       DEFAULT NULL; -- 本部部門担当者
    ln_sales_resp_id  NUMBER       DEFAULT NULL; -- 拠点部門担当者
    lv_belong_base_cd VARCHAR2(4)  DEFAULT NULL; -- 所属拠点
    lb_retcode        BOOLEAN      DEFAULT TRUE; -- メッセージ出力関数戻り値
--
    -- *** ローカル・カーソル ***
--
    -- 拠点名カーソル
    CURSOR base_name_cur(
      iv_base_code IN VARCHAR2) -- 拠点コード
    IS
      SELECT account_name AS base_name
      FROM   hz_cust_accounts
      WHERE  account_number      = iv_base_code
      AND    customer_class_code = cv_cust_cd_base -- 拠点
    ;
    -- 拠点名カーソルレコード型
    base_name_rec base_name_cur%ROWTYPE;
    -- 全拠点カーソル
    CURSOR all_base_cur
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- 拠点コード
              hca.account_name            AS base_name  -- 拠点名
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value IN
          (SELECT  ffvnh.child_flex_value_high
          FROM    fnd_flex_value_norm_hierarchy ffvnh,
                  fnd_flex_values_vl ffvv
          WHERE   ffvnh.parent_flex_value IN
              (SELECT  ffvnh.child_flex_value_high
              FROM    fnd_flex_value_norm_hierarchy ffvnh,
                      fnd_flex_values_vl ffvv
              WHERE   ffvnh.parent_flex_value IN
                  (SELECT  ffvnh.child_flex_value_high
                  FROM    fnd_flex_value_norm_hierarchy ffvnh,
                          fnd_flex_values_vl ffvv
                  WHERE   ffvnh.parent_flex_value IN
                      (SELECT  ffvnh.child_flex_value_high
                      FROM    fnd_flex_value_norm_hierarchy ffvnh,
                              fnd_flex_values_vl ffvv
                      WHERE   ffvnh.parent_flex_value = gv_head_office_code -- 本社部門コード
                      AND     ffvv.value_category         = cv_flex_st_name_department
                      AND     ffvnh.child_flex_value_high = ffvv.flex_value
                      )
                  AND     ffvv.value_category         = cv_flex_st_name_department
                  AND     ffvnh.child_flex_value_high = ffvv.flex_value
                  )
              AND     ffvv.value_category         = cv_flex_st_name_department
              AND     ffvnh.child_flex_value_high = ffvv.flex_value
              )
          AND     ffvv.value_category         = cv_flex_st_name_department
          AND     ffvnh.child_flex_value_high = ffvv.flex_value
          )
      AND     ffvv.value_category         = cv_flex_st_name_department
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- 拠点
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- 全拠点カーソルレコード型
    all_base_rec all_base_cur%ROWTYPE;
    -- 配下拠点カーソル
    CURSOR child_base_cur(
      iv_base_code IN VARCHAR2) -- 拠点コード
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- 拠点コード
              hca.account_name            AS base_name  -- 拠点名
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                         FROM   fnd_flex_value_sets ffvs,
                                                fnd_flex_value_norm_hierarchy ffvnh
                                         WHERE  ffvs.flex_value_set_name    = cv_flex_st_name_department
                                         AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                         AND    ffvnh.child_flex_value_high = iv_base_code -- 所属拠点コード
                                        )
      AND     ffvv.value_category         = cv_flex_st_name_department
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- 拠点
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- 配下拠点カーソルレコード型
    child_base_rec child_base_cur%ROWTYPE;
--
    -- *** ローカル・例外 ***
    no_resp_id_expt   EXCEPTION;
    no_resp_data_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 拠点情報の取得
    -- ===============================
    -- 入力パラメータの拠点情報を取得
    IF (gv_base_code IS NOT NULL) THEN
      <<base_name_loop>>
      FOR base_name_rec IN base_name_cur( gv_base_code ) LOOP
        o_budget_ttype(ln_base_index).base_code := gv_base_code;            -- 拠点コード
        o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name; -- 拠点名
      END LOOP base_name_loop;
      -- 拠点情報が取得できなかった場合
      IF ( o_budget_ttype(1).base_name IS NULL ) THEN
        -- エラー処理
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10182,
                       iv_token_name1  => cv_resp_name,
                       iv_token_value1 => cv_resp_name_val,
                       iv_token_name2  => cv_location_code,
                       iv_token_value2 => gv_base_code
                     );
        lv_errbuf := lv_errmsg;
--
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE no_resp_data_expt;
      END IF;
    -- 職責別に拠点を取得
    ELSE
      -- ===============================
      -- 職責別の拠点取得処理
      -- ===============================
      ----------------------------
      -- 主管部署担当者職責の場合
      ----------------------------
      IF ( gv_resp_type = cv_resp_type_0 ) THEN
        -- 全拠点コードと拠点名を取得
        <<all_base_loop>>
        FOR all_base_rec IN all_base_cur LOOP
          o_budget_ttype(ln_base_index).base_code := all_base_rec.base_code; -- 拠点コード
          o_budget_ttype(ln_base_index).base_name := all_base_rec.base_name; -- 拠点名
          ln_base_index := ln_base_index + 1;
        END LOOP all_base_loop;
      ----------------------------
      -- 本部部門担当者職責の場合
      ----------------------------
      ELSE
        -- 所属拠点取得
-- 2009/10/02 Ver.1.5 [障害E_T3_00630] SCS S.Moriyama UPD START
--        lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( SYSDATE , cn_created_by );
        lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( gd_process_date, cn_created_by );
-- 2009/10/02 Ver.1.5 [障害E_T3_00630] SCS S.Moriyama UPD END
        IF ( lv_belong_base_cd IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_00012,
                         iv_token_name1  => cv_user_id,
                         iv_token_value1 => cn_created_by
                       );
--
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.LOG
                          , iv_message  => lv_errmsg
                          , in_new_line => cn_number_0
                          );
            RAISE no_resp_data_expt;
        END IF;
--
        IF ( gv_resp_type = cv_resp_type_1 ) THEN
          -- ログインユーザーの自拠点より配下の拠点を取得
          <<child_base_loop>>
          FOR child_base_rec IN child_base_cur( lv_belong_base_cd ) LOOP
            o_budget_ttype(ln_base_index).base_code := child_base_rec.base_code; -- 拠点コード
            o_budget_ttype(ln_base_index).base_name := child_base_rec.base_name; -- 拠点名
            ln_base_index := ln_base_index + 1;
          END LOOP child_base_loop;
        ----------------------------
        -- 拠点部門_担当者職責の場合
        ----------------------------
        ELSE
          -- 自拠点を取得
          o_budget_ttype(ln_base_index).base_code   := lv_belong_base_cd;        -- 拠点コード
          <<resp_loop>>
          FOR base_name_rec IN base_name_cur( lv_belong_base_cd ) LOOP
            o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name;  -- 拠点名
          END LOOP resp_loop;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    --*** 職責ID取得エラー ***
    WHEN no_resp_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_00052,
                      iv_token_name1  => cv_resp_name,
                      iv_token_value1 => lv_resp_nm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 拠点取得例外 ***
    WHEN no_resp_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : get_put_file_data
   * Description      : 要求出力対象データの取得・出力処理(A-2 ～ A-9)
   ***********************************************************************************/
  PROCEDURE get_put_file_data(
    ov_errbuf     OUT  VARCHAR2, -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT  VARCHAR2, -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT  VARCHAR2) -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_put_file_data'; -- プログラム名
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_budget_year              xxcok_dlv_cost_calc_budget.budget_year%TYPE         DEFAULT NULL;
    lt_base_code                xxcok_dlv_cost_calc_budget.base_code%TYPE           DEFAULT NULL;
    lt_cs_qty                   xxcok_dlv_cost_calc_budget.cs_qty%TYPE              DEFAULT NULL;
    lt_budget_amt               xxcok_dlv_cost_calc_budget.dlv_cost_budget_amt%TYPE DEFAULT NULL;
    lv_line_put_flg             VARCHAR2(1)    DEFAULT NULL; -- 明細出力フラグ
    l_base_ttype                base_tbl;
    l_budget_ttype              budget_tbl;
    l_base_loop_index           NUMBER         DEFAULT NULL;
    ln_index                    NUMBER         DEFAULT NULL;
    -- 集計用変数
    ln_sum_result_qty           NUMBER;         -- 実績計_数量
    ln_sum_result_qmt           NUMBER;         -- 実績計_金額
    ln_sum_syatate_amt          NUMBER;         -- 拠点計_車立金額
    ln_sum_koguchi_amt          NUMBER;         -- 拠点計_小口金額
    ln_sum_budget_amt           NUMBER;         -- 拠点計_予算金額
    ln_sum_result_amt           NUMBER;         -- 拠点計_実績金額
    ln_sum_diff_amt             NUMBER;         -- 拠点計_差額金額
    l_budget_qty_tyype          number_tbl;     -- 予算_数量
    l_budget_amt_tyype          number_tbl;     -- 予算_金額
    l_result_syatate_qty_tyype  number_tbl;     -- 実績(車立)_数量
    l_result_syatate_amt_tyype  number_tbl;     -- 実績(車立)_金額
    l_result_koguchi_qty_tyype  number_tbl;     -- 実績(小口)_数量
    l_result_koguchi_amt_tyype  number_tbl;     -- 実績(小口)_金額
    l_sum_result_qty_tyype      number_tbl;     -- 実績計_数量
    l_sum_result_qmt_tyype      number_tbl;     -- 実績計_金額
    l_sum_syatate_amt_tyype     number_tbl;     -- 拠点計_車立金額
    l_sum_koguchi_amt_tyype     number_tbl;     -- 拠点計_小口金額
    l_sum_budget_amt_tyype      number_tbl;     -- 拠点計_予算金額
    l_sum_result_amt_tyype      number_tbl;     -- 拠点計_実績金額
    l_sum_diff_amt_tyype        number_tbl;     -- 拠点計_差額金額
    l_default_value             number_tbl;     -- 月別のデフォルト値
    lb_retcode  BOOLEAN         DEFAULT TRUE;   -- メッセージ出力関数戻り値
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 運送費予算カーソル
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura UPD START
--    CURSOR budget_data_cur(
--      iv_base_code IN VARCHAR2)
--    IS
--      SELECT xdccb.budget_year    AS budget_year,      -- 予算年度
--             xdccb.base_code      AS base_code,        -- 拠点コード
--             xdccb.item_code      AS item_code,        -- 商品コード
--             item.item_short_name AS item_short_name   -- 商品名(略称)
--      FROM   xxcok_dlv_cost_calc_budget xdccb,         -- 運送費予算テーブル
--            (SELECT iimb.item_no,                      -- 品目コード
--                    ximb.item_short_name,              -- 略称
--                    xsibh.policy_group                 -- 政策群コード
--             FROM   ic_item_mst_b              iimb,   -- opm品目マスタ
--                    xxcmn_item_mst_b           ximb,   -- opm品目アドオンマスタ
--                    mtl_system_items_b         msib,   -- 品目マスタ
--                    xxcmm_system_items_b_hst   xsibh   -- Ｄｉｓｃ品目アドオンマスタ（変更履歴）
--             WHERE  ximb.item_id          = iimb.item_id
--             AND    iimb.item_no          = msib.segment1
--             AND    msib.organization_id  = gn_org_id
--             AND    xsibh.item_id         = iimb.item_id
--             AND    xsibh.item_code       = msib.segment1
--             AND    xsibh.apply_flag      = cv_flag_y
--             AND    xsibh.policy_group IS NOT NULL
---- 2009/09/03 Ver.1.4 [障害0001257] SCS S.Moriyama ADD START
--             AND    gd_process_date BETWEEN ximb.start_date_active
--                                    AND NVL ( ximb.end_date_active , gd_process_date )
---- 2009/09/03 Ver.1.4 [障害0001257] SCS S.Moriyama ADD END
--             AND    (xsibh.apply_date,xsibh.item_id) IN (SELECT MAX( xsibh.apply_date ), -- 適用日
--                                                                item_id                  -- 品目ID
--                                                         FROM   xxcmm_system_items_b_hst xsibh
--                                                         WHERE  xsibh.policy_group IS NOT NULL
--                                                         AND    xsibh.apply_flag   = cv_flag_y
--                                                         GROUP BY item_id
--                                                        )
--            )item
--      WHERE    xdccb.budget_year = gv_budget_year -- 入力パラメータの予算年度
--      AND      xdccb.base_code   = iv_base_code
--      AND      xdccb.item_code   = item.item_no(+)
--      GROUP BY xdccb.budget_year,
--               xdccb.base_code,
--               xdccb.item_code,
--               item.item_short_name,
--               SUBSTRB( item.policy_group,1,3 )
--      ORDER BY SUBSTRB( item.policy_group,1,3 ),
--               xdccb.item_code
--      ;
    CURSOR budget_data_cur(
      iv_base_code IN VARCHAR2)
    IS
      SELECT /*+
                  LEADING(xdccb)
             */
             xdccb.budget_year    AS budget_year,      -- 予算年度
             xdccb.base_code      AS base_code,        -- 拠点コード
             xdccb.item_code      AS item_code,        -- 商品コード
             item.item_short_name AS item_short_name   -- 商品名(略称)
      FROM   xxcok_dlv_cost_calc_budget xdccb,         -- 運送費予算テーブル
            (SELECT /*+
                        USE_NL( msib,iimc,ximb )
                        USE_NL( mic,mcb,mcsb,mcst )
                    */
                    iimb.item_no,                      -- 品目コード
                    ximb.item_short_name,              -- 略称
                    mcb.segment1                       -- 政策群コード
             FROM   ic_item_mst_b              iimb,   -- opm品目マスタ
                    xxcmn_item_mst_b           ximb,   -- opm品目アドオンマスタ
                    mtl_system_items_b         msib,   -- 品目マスタ
                    mtl_category_sets_b        mcsb,   -- 品目カテゴリセット
                    mtl_category_sets_tl       mcst,   -- 品目カテゴリセット日本語
                    mtl_categories_b           mcb ,   -- 品目カテゴリマスタ
                    mtl_item_categories        mic     -- 品目カテゴリ割当
             WHERE  ximb.item_id           = iimb.item_id
             AND    iimb.item_no           = msib.segment1
             AND    msib.organization_id   = gn_org_id
             AND    mcst.category_set_id   = mcsb.category_set_id
             AND    mcb.structure_id       = mcsb.structure_id
             AND    mcb.category_id        = mic.category_id
             AND    mcsb.category_set_id   = mic.category_set_id
             AND    mcst.language          = USERENV( 'LANG' )
             AND    mcst.category_set_name = gv_policy_group_code
             AND    mcb.segment1           IS NOT NULL
             AND    msib.organization_id   = mic.organization_id
             AND    msib.inventory_item_id = mic.inventory_item_id
             AND    gd_process_date BETWEEN ximb.start_date_active
                                    AND NVL ( ximb.end_date_active , gd_process_date )
            )item
      WHERE    xdccb.budget_year = gv_budget_year -- 入力パラメータの予算年度
      AND      xdccb.base_code   = iv_base_code
      AND      xdccb.item_code   = item.item_no(+)
      GROUP BY xdccb.budget_year,
               xdccb.base_code,
               xdccb.item_code,
               item.item_short_name,
               SUBSTRB( item.segment1,1,3 )
      ORDER BY SUBSTRB( item.segment1,1,3 ),
               xdccb.item_code
    ;
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura UPD END
--
    -- 運送費予算カーソルレコード型
    budget_data_rec budget_data_cur%ROWTYPE;
    -- 予算月カーソル
    CURSOR budget_month_cur
    IS
      SELECT ffv.flex_value            AS month,   -- 月
             TO_NUMBER(ffv.attribute1) AS order_no -- 処理順
      FROM   fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv
      WHERE  ffvs.flex_value_set_name = cv_flex_st_name_bd_month  --'XXCOK1_BUDGET_MONTH_ORDER'
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffv.enabled_flag         = cv_flag_y
      ORDER BY TO_NUMBER(ffv.attribute1)
    ;
    -- 運送費予算カーソルレコード型
    budget_month_rec budget_month_cur%ROWTYPE;
    -- 運送費実績カーソル
    CURSOR result_info_cur(
      i_budget_year IN xxcok_dlv_cost_calc_budget.budget_year%TYPE, -- 予算年度
      i_month       IN VARCHAR2,                                    -- 月
      i_base_code   IN VARCHAR2,                                    -- 拠点コード
      i_item_code   IN xxcok_dlv_cost_calc_budget.item_code%TYPE)   -- 商品コード
    IS
      SELECT small_amt_type, -- 小口区分
             sum_cs_qty,     -- 実績数量
             sum_amt         -- 実績金額
      FROM   xxcok_dlv_cost_result_sum
      WHERE  target_year  = i_budget_year
      AND    target_month = TO_CHAR(i_month,'FM00')
      AND    base_code    = i_base_code
      AND    item_code    = i_item_code
      ORDER BY small_amt_type
    ;
    -- 運送費実績カーソルレコード型
    result_info_rec result_info_cur%ROWTYPE;
    -- 例外
    no_data_expt             EXCEPTION; -- 初期処理エラー
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 拠点データの取得(A-2.)
    -- ===============================
    get_base_data(
      ov_errbuf      => lv_errbuf,    -- エラー・メッセージ
      ov_retcode     => lv_retcode,   -- リターン・コード
      ov_errmsg      => lv_errmsg,    -- ユーザー・エラー・メッセージ
      o_budget_ttype => l_base_ttype  -- 拠点情報
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- 取得対象となる年度を設定する
    gv_target_year := gv_budget_year;
--
    l_base_loop_index := l_base_ttype.FIRST;
    -- 取得した拠点の数分ループします
    <<base_loop>>
    WHILE ( l_base_loop_index IS NOT NULL ) LOOP
      -- 拠点が変わったら、拠点計行を出力する
      IF ( l_base_ttype(l_base_loop_index).base_code <> lt_base_code )
        AND ( lv_line_put_flg = cv_flag_y )
        AND ( l_base_loop_index <> 1 ) THEN
        -- ===============================
        -- 拠点計項目格納・要求出力処理(A-7)
        -- ===============================
        put_file_set(
          ov_errbuf                   => lv_errbuf,               -- エラー・メッセージ
          ov_retcode                  => lv_retcode,              -- リターン・コード
          ov_errmsg                   => lv_errmsg,               -- ユーザー・エラー・メッセージ
          iv_put_code                 => cv_put_code_sum,         -- 出力フラグ(1:明細、2:拠点計)
          i_budget_qty_tyype          => l_default_value,         -- 予算_数量
          i_budget_amt_tyype          => l_default_value,         -- 予算_金額
          i_result_syatate_qty_tyype  => l_default_value,         -- 実績(車立)_数量
          i_result_syatate_amt_tyype  => l_default_value,         -- 実績(車立)_金額
          i_result_koguchi_qty_tyype  => l_default_value,         -- 実績(小口)_数量
          i_result_koguchi_amt_tyype  => l_default_value,         -- 実績(小口)_金額
          i_sum_result_qty_tyype      => l_default_value,         -- 実績計_数量
          i_sum_result_qmt_tyype      => l_default_value,         -- 実績計_金額
          i_sum_syatate_amt_tyype     => l_sum_syatate_amt_tyype, -- 拠点計_車立金額
          i_sum_koguchi_amt_tyype     => l_sum_koguchi_amt_tyype, -- 拠点計_小口金額
          i_sum_budget_amt_tyype      => l_sum_budget_amt_tyype,  -- 拠点計_予算金額
          i_sum_result_amt_tyype      => l_sum_result_amt_tyype,  -- 拠点計_実績金額
          i_sum_diff_amt_tyype        => l_sum_diff_amt_tyype     -- 拠点計_差額金額
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      -- 初期化
      lv_line_put_flg     := NULL;      -- 明細出力フラグ
      ln_sum_syatate_amt  := 0;         -- 拠点計_車立金額
      ln_sum_koguchi_amt  := 0;         -- 拠点計_小口金額
      ln_sum_budget_amt   := 0;         -- 拠点計_予算金額
      ln_sum_result_amt   := 0;         -- 拠点計_実績金額
      ln_sum_diff_amt     := 0;         -- 拠点計_差額金額
      l_sum_syatate_amt_tyype.DELETE;   -- 拠点計_車立金額
      l_sum_koguchi_amt_tyype.DELETE;   -- 拠点計_小口金額
      l_sum_budget_amt_tyype.DELETE;    -- 拠点計_予算金額
      l_sum_result_amt_tyype.DELETE;    -- 拠点計_実績金額
      l_sum_diff_amt_tyype.DELETE;      -- 拠点計_差額金額
      -- ===============================
      -- 運送費予算データの取得(A-3.)
      -- ===============================
      <<budget_loop>>
      FOR budget_data_rec IN budget_data_cur( l_base_ttype(l_base_loop_index).base_code ) LOOP
        -- 商品名(略称)が取得できなかった場合
        IF ( budget_data_rec.item_short_name IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_10183,
                         iv_token_name1  => cv_item_code,
                         iv_token_value1 => budget_data_rec.item_code
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        END IF;
        -- 対象件数カウント
        gn_target_cnt := gn_target_cnt + 1;
        -- ===============================
        -- 予算月の取得(A-4.)
        -- ===============================
        --初期化
        ln_index := NULL;
        -- 月別ループ
        <<budget_month_loop>>
        FOR budget_month_rec IN budget_month_cur LOOP
          -- 取得した処理順をインデックスとして使用する
          ln_index := budget_month_rec.order_no;
          -- 初期化
          lt_cs_qty     := 0;
          lt_budget_amt := 0;
          BEGIN
            -- 月別の運送費予算数量・金額の値を取得する
            SELECT NVL(cs_qty,0), -- 予算数量
                   NVL(dlv_cost_budget_amt,0)      -- 予算金額
            INTO   lt_cs_qty,
                   lt_budget_amt
            FROM   xxcok_dlv_cost_calc_budget
            WHERE  budget_year  = budget_data_rec.budget_year
            AND    base_code    = l_base_ttype(l_base_loop_index).base_code
            AND    item_code    = budget_data_rec.item_code
            AND    target_month = TO_CHAR(budget_month_rec.month,'FM00')
            ;
          EXCEPTION
            --*** データ取得エラー ***
            WHEN NO_DATA_FOUND THEN
              -- 対象月のデータがない場合、金額・数量に0を設定する
              lt_cs_qty     := 0;
              lt_budget_amt := 0;
          END;
          -- 拠点コード・拠点名及び、予算データの商品コード・商品名(略称)・月・数量・金額をPL/SQL表に値をセットします。
          l_budget_ttype(ln_index).base_code        := l_base_ttype(l_base_loop_index).base_code; -- 拠点コード
          l_budget_ttype(ln_index).base_name        := l_base_ttype(l_base_loop_index).base_name; -- 拠点名
          l_budget_ttype(ln_index).budget_item_code := budget_data_rec.item_code;                 -- 予算_商品コード
          l_budget_ttype(ln_index).budget_item_name := budget_data_rec.item_short_name;           -- 予算_商品名(略称)
          l_budget_ttype(ln_index).budget_month     := TO_CHAR(budget_month_rec.month, 'FM00');   -- 予算_月
          l_budget_qty_tyype(ln_index)              := lt_cs_qty;                                 -- 予算_数量
--【2009/05/15 A.Yano Ver.1.3 START】------------------------------------------------------
--          l_budget_amt_tyype(ln_index)              := lt_budget_amt;                             -- 予算_金額
          l_budget_amt_tyype(ln_index)              := ROUND( lt_budget_amt, -3 ) / 1000;         -- 予算_金額
--【2009/05/15 A.Yano Ver.1.3 END  】------------------------------------------------------
          -- 実績数量・金額デフォルト設定
          l_result_syatate_qty_tyype(ln_index) := 0; -- 実績(車立)_数量
          l_result_syatate_amt_tyype(ln_index) := 0; -- 実績(車立)_金額
          l_result_koguchi_qty_tyype(ln_index) := 0; -- 実績(小口)_数量
          l_result_koguchi_amt_tyype(ln_index) := 0; -- 実績(小口)_金額
          -- 実績計項目の初期化
          ln_sum_result_qty := 0;
          ln_sum_result_qmt := 0;
          -- ===============================
          -- 運送費実績情報取得処理(A-5.)
          -- ===============================
          -- 5月から12月は、予算年度を対象年度にし
          -- 1月から4月は、予算年度の翌年を対象年度とする
          IF TO_CHAR(budget_month_rec.month,'FM00') = cv_month01 THEN
            gv_target_year := gv_budget_year + 1;
          ELSIF TO_CHAR(budget_month_rec.month,'FM00') = cv_month05 THEN
            gv_target_year := gv_budget_year;
          END IF;
--
          <<result_info_loop>>
          FOR result_info_rec IN result_info_cur(
            gv_target_year,                            -- 予算年度
            budget_month_rec.month,                    -- 月
            l_base_ttype(l_base_loop_index).base_code, -- 拠点コード
            budget_data_rec.item_code                  -- 商品コード
            ) LOOP
            -- ===============================
            -- 実績数量・実績金額格納処理(A-6)
            -- ===============================
            -- 小口区分別に数量・金額を設定
            IF ( result_info_rec.small_amt_type = cv_kbn_syatate ) THEN
              l_result_syatate_qty_tyype(ln_index) := result_info_rec.sum_cs_qty;  -- 実績(車立)_数量
--【2009/05/15 A.Yano Ver.1.3 START】------------------------------------------------------
--              l_result_syatate_amt_tyype(ln_index) := result_info_rec.sum_amt;     -- 実績(車立)_金額
              l_result_syatate_amt_tyype(ln_index) := ROUND( result_info_rec.sum_amt, -3 ) / 1000;     -- 実績(車立)_金額
--【2009/05/15 A.Yano Ver.1.3 END  】------------------------------------------------------
              -- 実績計項目の集計
              ln_sum_result_qty := ln_sum_result_qty + result_info_rec.sum_cs_qty; -- 実績計_数量
--【2009/05/15 A.Yano Ver.1.3 START】------------------------------------------------------
--              ln_sum_result_qmt := ln_sum_result_qmt + result_info_rec.sum_amt;    -- 実績計_金額
              ln_sum_result_qmt := ln_sum_result_qmt + ROUND( result_info_rec.sum_amt, -3 ) / 1000;    -- 実績計_金額
--【2009/05/15 A.Yano Ver.1.3 END  】------------------------------------------------------
            ELSIF ( result_info_rec.small_amt_type = cv_kbn_koguchi ) THEN
              l_result_koguchi_qty_tyype(ln_index) := result_info_rec.sum_cs_qty;  -- 実績(小口)_数量
--【2009/05/15 A.Yano Ver.1.3 START】------------------------------------------------------
--              l_result_koguchi_amt_tyype(ln_index) := result_info_rec.sum_amt;     -- 実績(小口)_金額
              l_result_koguchi_amt_tyype(ln_index) := ROUND( result_info_rec.sum_amt, -3 ) / 1000;     -- 実績(小口)_金額
--【2009/05/15 A.Yano Ver.1.3 END  】------------------------------------------------------
              -- 実績計項目の集計
              ln_sum_result_qty := ln_sum_result_qty + result_info_rec.sum_cs_qty; -- 実績計_数量
--【2009/05/15 A.Yano Ver.1.3 START】------------------------------------------------------
--              ln_sum_result_qmt := ln_sum_result_qmt + result_info_rec.sum_amt;    -- 実績計_金額
              ln_sum_result_qmt := ln_sum_result_qmt + ROUND( result_info_rec.sum_amt, -3 ) / 1000;    -- 実績計_金額
--【2009/05/15 A.Yano Ver.1.3 END  】------------------------------------------------------
            ELSE
              -- 実績計項目の集計
              ln_sum_result_qty := ln_sum_result_qty + 0;
              ln_sum_result_qmt := ln_sum_result_qmt + 0;
            END IF;
          END LOOP;
          -- 実績計項目の集計値を格納
          l_sum_result_qty_tyype(ln_index) := ln_sum_result_qty; -- 実績計_数量
          l_sum_result_qmt_tyype(ln_index) := ln_sum_result_qmt; -- 実績計_金額
          -- 拠点計項目の集計
          ln_sum_syatate_amt := l_result_syatate_amt_tyype(ln_index);     -- 拠点計_車立金額
          ln_sum_koguchi_amt := l_result_koguchi_amt_tyype(ln_index);     -- 拠点計_小口金額
          ln_sum_budget_amt  := l_budget_amt_tyype(ln_index);             -- 拠点計_予算金額
          ln_sum_result_amt  := l_sum_result_qmt_tyype(ln_index);         -- 拠点計_実績金額
          ln_sum_diff_amt    := ln_sum_budget_amt - ln_sum_result_amt;    -- 拠点計_差額金額
          -- 拠点計項目の集計を格納
          -- 一度も明細行を出力していないまたは、拠点が変わった場合は取得した値を格納
          IF ( gn_put_count = 0 )
            OR ( l_base_ttype(l_base_loop_index).base_code <> lt_base_code ) THEN
            -- 拠点計_車立金額
            l_sum_syatate_amt_tyype(ln_index) := ln_sum_syatate_amt;
            -- 拠点計_小口金額
            l_sum_koguchi_amt_tyype(ln_index) := ln_sum_koguchi_amt;
            -- 拠点計_予算金額
            l_sum_budget_amt_tyype(ln_index)  := ln_sum_budget_amt;
            -- 拠点計_実績金額
            l_sum_result_amt_tyype(ln_index)  := ln_sum_result_amt;
            -- 拠点計_差額金額
            l_sum_diff_amt_tyype(ln_index)    := ln_sum_diff_amt;
          ELSE
            -- 拠点計_車立金額
            l_sum_syatate_amt_tyype(ln_index) := NVL(l_sum_syatate_amt_tyype(ln_index),0) + ln_sum_syatate_amt;
            -- 拠点計_小口金額
            l_sum_koguchi_amt_tyype(ln_index) := NVL(l_sum_koguchi_amt_tyype(ln_index),0) + ln_sum_koguchi_amt;
            -- 拠点計_予算金額
            l_sum_budget_amt_tyype(ln_index)  := NVL(l_sum_budget_amt_tyype(ln_index),0) + ln_sum_budget_amt;
            -- 拠点計_実績金額
            l_sum_result_amt_tyype(ln_index)  := NVL(l_sum_result_amt_tyype(ln_index),0) + ln_sum_result_amt;
            -- 拠点計_差額金額
            l_sum_diff_amt_tyype(ln_index)    := NVL(l_sum_diff_amt_tyype(ln_index),0) + ln_sum_diff_amt;
          END IF;
        END LOOP budget_month_loop;
--
        IF ( ln_index IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_00014,
                         iv_token_name1  => cv_flex_value,
                         iv_token_value1 => cv_flex_st_name_bd_month
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        ELSE
          -- ===============================
          -- 運送費予算一覧表の要求出力処理(A-8)
          -- ===============================
          put_file_set(
            ov_errbuf                   => lv_errbuf,                          -- エラー・メッセージ
            ov_retcode                  => lv_retcode,                         -- リターン・コード
            ov_errmsg                   => lv_errmsg,                          -- ユーザー・エラー・メッセージ
            iv_put_code                 => cv_put_code_line,                   -- 出力フラグ(1:明細、2:拠点計)
            iv_back_base_code           => lt_base_code,                       -- 拠点コード(前回値の退避)
            iv_base_code                => l_budget_ttype(1).base_code,        -- 拠点コード
            iv_base_name                => l_budget_ttype(1).base_name,        -- 拠点名
            iv_item_code                => l_budget_ttype(1).budget_item_code, -- 商品コード
            iv_item_short_name          => l_budget_ttype(1).budget_item_name, -- 商品名(略称)
            i_budget_qty_tyype          => l_budget_qty_tyype,                 -- 予算_数量
            i_budget_amt_tyype          => l_budget_amt_tyype,                 -- 予算_金額
            i_result_syatate_qty_tyype  => l_result_syatate_qty_tyype,         -- 実績(車立)_数量
            i_result_syatate_amt_tyype  => l_result_syatate_amt_tyype,         -- 実績(車立)_金額
            i_result_koguchi_qty_tyype  => l_result_koguchi_qty_tyype,         -- 実績(小口)_数量
            i_result_koguchi_amt_tyype  => l_result_koguchi_amt_tyype,         -- 実績(小口)_金額
            i_sum_result_qty_tyype      => l_sum_result_qty_tyype,             -- 実績計_数量
            i_sum_result_qmt_tyype      => l_sum_result_qmt_tyype,             -- 実績計_金額
            i_sum_syatate_amt_tyype     => l_default_value,                    -- 拠点計_車立金額
            i_sum_koguchi_amt_tyype     => l_default_value,                    -- 拠点計_小口金額
            i_sum_budget_amt_tyype      => l_default_value,                    -- 拠点計_予算金額
            i_sum_result_amt_tyype      => l_default_value,                    -- 拠点計_実績金額
            i_sum_diff_amt_tyype        => l_default_value                     -- 拠点計_差額金額
          );
        END IF;
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- 明細出力件数をカウント
        gn_put_count := gn_put_count + 1;
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
        -- 初期化
        lv_line_put_flg := cv_flag_y;  -- 明細出力フラグ
        lt_base_code    := l_budget_ttype(1).base_code;
        l_budget_ttype.DELETE;
      END LOOP budget_loop;
      -- 次のインデックスを番号を取得
      l_base_loop_index := l_base_ttype.NEXT( l_base_loop_index );
    END LOOP base_loop;
--
    -- 明細出力した場合、拠点計行を出力する
    IF ( gn_put_count > 0 )
      AND ( lv_line_put_flg = cv_flag_y ) THEN
      -- ===============================
      -- 最終拠点計行の要求出力処理(A-9)
      -- ===============================
      put_file_set(
        ov_errbuf                   => lv_errbuf,               -- エラー・メッセージ
        ov_retcode                  => lv_retcode,              -- リターン・コード
        ov_errmsg                   => lv_errmsg,               -- ユーザー・エラー・メッセージ
        iv_put_code                 => cv_put_code_sum,         -- 出力フラグ(1:明細、2:拠点計)
        i_budget_qty_tyype          => l_default_value,         -- 予算_数量
        i_budget_amt_tyype          => l_default_value,         -- 予算_金額
        i_result_syatate_qty_tyype  => l_default_value,         -- 実績(車立)_数量
        i_result_syatate_amt_tyype  => l_default_value,         -- 実績(車立)_金額
        i_result_koguchi_qty_tyype  => l_default_value,         -- 実績(小口)_数量
        i_result_koguchi_amt_tyype  => l_default_value,         -- 実績(小口)_金額
        i_sum_result_qty_tyype      => l_default_value,         -- 実績計_数量
        i_sum_result_qmt_tyype      => l_default_value,         -- 実績計_金額
        i_sum_syatate_amt_tyype     => l_sum_syatate_amt_tyype, -- 拠点計_車立金額
        i_sum_koguchi_amt_tyype     => l_sum_koguchi_amt_tyype, -- 拠点計_小口金額
        i_sum_budget_amt_tyype      => l_sum_budget_amt_tyype,  -- 拠点計_予算金額
        i_sum_result_amt_tyype      => l_sum_result_amt_tyype,  -- 拠点計_実績金額
        i_sum_diff_amt_tyype        => l_sum_diff_amt_tyype     -- 拠点計_差額金額
      );
    END IF;
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** データ取得例外 ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_put_file_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- 予算年度
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- 職責タイプ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(4) := 'init'; -- プログラム名
--
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--
    lv_profile_nm   VARCHAR2(30) DEFAULT NULL; -- プロファイル名称の格納用
    lb_retcode      BOOLEAN;
--
    -- *** ローカル・例外 ***
    no_profile_expt EXCEPTION; -- プロファイル値取得エラー
    no_org_id_expt  EXCEPTION; -- 在庫組織ID取得エラー
    no_process_date EXCEPTION; -- 業務日付取得エラー
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 入力パラメータの退避
    -- ===============================
    gv_base_code   := iv_base_code;   -- 拠点コード
    gv_budget_year := iv_budget_year; -- 予算年度
    gv_resp_type   := iv_resp_type;   -- 職責タイプ
--
    -- ===============================
    -- 入力パラメータの出力
    -- ===============================
    -- コンカレント入力パラメータメッセージ出力(1:拠点コード)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00018,
                    iv_token_name1  => cv_location_code,
                    iv_token_value1 => gv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    -- コンカレント入力パラメータメッセージ出力(2:予算年度)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00019,
                    iv_token_name1  => cv_year,
                    iv_token_value1 => gv_budget_year
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_1     -- 改行数
                  );
    -- ===============================
    -- プロファイル値取得
    -- ===============================
    -- カスタム・プロファイルの在庫組織コードを取得します。
    gv_org_code := fnd_profile.value(cv_pro_organization_code);
    IF ( gv_org_code IS NULL ) THEN
      lv_profile_nm := cv_pro_organization_code;
      RAISE no_profile_expt;
    END IF;
    -- カスタム・プロファイルの本社の部門コードを取得します。
    gv_head_office_code := fnd_profile.value(cv_pro_head_office_code);
    IF ( gv_head_office_code IS NULL ) THEN
      lv_profile_nm := cv_pro_head_office_code;
      RAISE no_profile_expt;
    END IF;
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura ADD START
    -- カスタム・プロファイルの政策群コードを取得します。
    gv_policy_group_code := fnd_profile.value(cv_pro_policy_group_code);
    IF ( gv_policy_group_code IS NULL ) THEN
      lv_profile_nm := cv_pro_policy_group_code;
      RAISE no_profile_expt;
    END IF;
-- 2009/12/07 Ver.1.6 [障害E_本稼動_00022] SCS K.Nakamura ADD END
    -- ===============================
    -- 在庫組織IDの取得
    -- ===============================
    gn_org_id := xxcoi_common_pkg.get_organization_id(gv_org_code);
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00013
                    , iv_token_name1  => cv_org_code
                    , iv_token_value1 => gv_org_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_org_id_expt;
    END IF;
    -- ===============================
    -- ログイン時の情報取得
    -- ===============================
    gn_resp_id := fnd_global.resp_id; -- 職責ID
    gn_user_id := fnd_global.user_id; -- ユーザーID
    -- =============================================
    -- 業務処理日付取得
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_process_date;
    END IF;
--
  EXCEPTION
    --*** プロファイル値取得エラー ***
    WHEN no_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00003,
                     iv_token_name1  => cv_profile,
                     iv_token_value1 => lv_profile_nm
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 在庫組織ID取得エラー ***
    WHEN no_org_id_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 業務日付取得取得エラー ***
    WHEN no_process_date THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- 予算年度
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- 職責タイプ
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      ov_errbuf      => lv_errbuf,      -- エラー・メッセージ
      ov_retcode     => lv_retcode,     -- リターン・コード
      ov_errmsg      => lv_errmsg,      -- ユーザー・エラー・メッセージ
      iv_base_code   => iv_base_code,   -- 拠点コード
      iv_budget_year => iv_budget_year, -- 予算年度
      iv_resp_type   => iv_resp_type    -- 職責タイプ
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- 要求出力対象データ取得処理(A2～A6)
    -- ===============================
    get_put_file_data(
      lv_errbuf,  -- エラー・メッセージ           --# 固定 #
      lv_retcode, -- リターン・コード             --# 固定 #
      lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf         OUT VARCHAR2, -- エラー・メッセージ --# 固定 #
    retcode        OUT VARCHAR2, -- リターン・コード   --# 固定 #
    iv_base_code   IN  VARCHAR2, -- 1.拠点コード
    iv_budget_year IN  VARCHAR2, -- 2.予算年度
    iv_resp_type   IN  VARCHAR2  -- 3.職責タイプ
  )
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(16)   DEFAULT NULL; -- メッセージコード
    lb_retcode      BOOLEAN;
--
  BEGIN
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => 'LOG'-- ログ出力
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- submainの呼び出し
    -- ===============================
    submain(
      ov_errbuf      => lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      ov_retcode     => lv_retcode,     -- リターン・コード             --# 固定 #
      ov_errmsg      => lv_errmsg,      -- ユーザー・エラー・メッセージ --# 固定 #
      iv_base_code   => iv_base_code,   -- 拠点コード
      iv_budget_year => iv_budget_year, -- 予算年度
      iv_resp_type   => iv_resp_type    -- 職責タイプ
    );
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errmsg      -- メッセージ
                    , in_new_line => cn_number_0    -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errbuf      -- メッセージ
                    , in_new_line => cn_number_1    -- 改行
                    );
      -- 対象件数・成功件数・エラー件数の設定
      gn_error_cnt  := 1;
    END IF;
    -- 明細出力件数が0件の場合
    IF ( gn_put_count = 0 ) AND ( lv_retcode = cv_status_normal ) THEN
      -- 対象データ無しのメッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_10184,
                      iv_token_name1  => cv_year,
                      iv_token_value1 => gv_budget_year
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.LOG,   -- LOG
                     iv_message  => gv_out_msg,     -- メッセージ
                     in_new_line => cn_number_1     -- 改行数
                    );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90000,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90001,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90002,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_1     -- 改行数
                  );
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal )   THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn )  THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK023A03C;
/
