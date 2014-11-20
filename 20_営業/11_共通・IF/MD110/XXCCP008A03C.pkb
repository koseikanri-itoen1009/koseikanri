CREATE OR REPLACE PACKAGE BODY APPS.XXCCP008A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A03C(body)
 * Description      : リース支払計画データCSV出力
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/05    1.00  SCSK 高崎美和    新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- アプリケーション短縮名
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP008A03C';   -- パッケージ名
  -- 物件コード指定有無フラグ コード値
  cv_obj_code_param_off     CONSTANT VARCHAR2(1)  := '0';              -- 物件コードの指定無し
  cv_obj_code_param_on      CONSTANT VARCHAR2(1)  := '1';              -- 物件コードの指定有り
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_obj_code_param         VARCHAR2(1);               -- 物件コード指定有無フラグ
  -- 以下パラメータ --
  gv_contract_number        xxcff_contract_headers.contract_number%TYPE;   -- パラメータ：契約番号
  gv_lease_company          xxcff_contract_headers.lease_company%TYPE;     -- パラメータ：リース会社
  gv_object_code_01         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード1
  gv_object_code_02         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード2
  gv_object_code_03         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード3
  gv_object_code_04         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード4
  gv_object_code_05         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード5
  gv_object_code_06         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード6
  gv_object_code_07         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード7
  gv_object_code_08         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード8
  gv_object_code_09         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード9
  gv_object_code_10         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード10
--
  --==================================================
  -- グローバルカーソル
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
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
    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';                           -- 区切り文字
    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';                           -- 単語囲み文字
    cv_con_sts_cont         CONSTANT  VARCHAR2(3)   := '202';                         -- 契約ステータス：契約
    cv_con_sts_re_lease     CONSTANT  VARCHAR2(3)   := '203';                         -- 契約ステータス：再リース
    cv_date_format          CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';       --YYYYMMDDHHMISS型
--
    -- *** ローカル変数 ***
--
    -- ===============================================
    -- ローカル例外処理
    -- ===============================================
    err_prm_expt             EXCEPTION;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 支払計画 取得カーソル  パラメータ.契約番号が指定有り
    CURSOR l_xpay_plan_rec_cur
    IS
      SELECT xppl.contract_line_id                --  リース支払計画.契約明細内部ID
      ,      xppl.payment_frequency               --  リース支払計画.支払回数
      ,      xppl.contract_header_id              --  リース支払計画.契約内部ID
      ,      xppl.period_name                     --  リース支払計画.会計期間
      ,      TO_CHAR( xppl.payment_date , cv_date_format ) AS payment_date
                                                  --  リース支払計画.支払日
      ,      xppl.lease_charge                    --  リース支払計画.リース料
      ,      xppl.lease_tax_charge                --  リース支払計画.リース料_消費税
      ,      xppl.lease_deduction                 --  リース支払計画.リース控除額
      ,      xppl.lease_tax_deduction             --  リース支払計画.リース控除額_消費税
      ,      xppl.op_charge                       --  リース支払計画.ＯＰリース料
      ,      xppl.op_tax_charge                   --  リース支払計画.ＯＰリース料額_消費税
      ,      xppl.fin_debt                        --  リース支払計画.ＦＩＮリース債務額
      ,      xppl.fin_tax_debt                    --  リース支払計画.ＦＩＮリース債務額_消費税
      ,      xppl.fin_interest_due                --  リース支払計画.ＦＩＮリース支払利息
      ,      xppl.fin_debt_rem                    --  リース支払計画.ＦＩＮリース債務残
      ,      xppl.fin_tax_debt_rem                --  リース支払計画.ＦＩＮリース債務残_消費税
      ,      xppl.accounting_if_flag              --  リース支払計画.会計ＩＦフラグ
      ,      xppl.payment_match_flag              --  リース支払計画.照合済フラグ
      ,      xppl.created_by                      --  リース支払計画.作成者
      ,      TO_CHAR( xppl.creation_date , cv_date_format ) AS creation_date
                                                  --  リース支払計画.作成日
      ,      xppl.last_updated_by                 --  リース支払計画.最終更新者
      ,      TO_CHAR( xppl.last_update_date , cv_date_format ) AS last_update_date
                                                  --  リース支払計画.最終更新日
      ,      xppl.last_update_login               --  リース支払計画.最終更新ログイン
      ,      xppl.request_id                      --  リース支払計画.要求ID
      ,      xppl.program_application_id          --  リース支払計画.コンカレント・プログラム・アプリケーションID
      ,      xppl.program_id                      --  リース支払計画.コンカレント・プログラムID
      ,      TO_CHAR( xppl.program_update_date , cv_date_format ) AS program_update_date
                                                  --  リース支払計画.プログラム更新日
        FROM xxcff_contract_headers xconhe        --  リース契約ヘッダ
           , xxcff_contract_lines   xconli        --  リース契約明細
           , xxcff_object_headers   xobjh         --  リース物件
           , xxcff_pay_planning     xppl          --  リース支払計画
           , ( -- 各契約毎の最大再リース回数
               SELECT c_head.contract_number          AS contract_number
                    , c_head.lease_company            AS lease_company
                    , MAX(c_head.re_lease_times)      AS re_lease_times
                 FROM xxcff_contract_headers   c_head      -- リース契約ヘッダ
                WHERE c_head.contract_number = gv_contract_number
                GROUP BY c_head.contract_number , c_head.lease_company
             ) c_head_max
       WHERE
             -- リース契約ヘッダ.契約内部ID = リース契約明細.契約内部ID
             xconhe.contract_header_id = xconli.contract_header_id
             -- リース契約ヘッダ.契約内部ID = リース支払計画.契約内部ID
         AND xconhe.contract_header_id = xppl.contract_header_id
             -- リース契約明細.契約明細内部ID = リース支払計画.契約明細内部ID
         AND xconli.contract_line_id = xppl.contract_line_id
             -- リース契約明細.物件内部ID = リース物件.物件内部ID
         AND xconli.object_header_id = xobjh.object_header_id
             --  リース契約ヘッダ.再リース回数が最大
         AND xconhe.contract_number = c_head_max.contract_number
         AND xconhe.lease_company   = c_head_max.lease_company
         AND xconhe.re_lease_times  = c_head_max.re_lease_times
             -- リース契約ヘッダ.契約番号 = :パラメータ契約番号
         AND xconhe.contract_number = gv_contract_number
             -- リース契約ヘッダ.リース会社 = :パラメータリース会社
         AND ( gv_lease_company IS NULL
             OR
               xconhe.lease_company = gv_lease_company
             )
             -- 物件コードの指定がある場合は、いずれかに合致するもの
         AND (
               gv_obj_code_param = cv_obj_code_param_off
             OR
               (
                 gv_obj_code_param = cv_obj_code_param_on
                 AND
                 -- リース物件.物件コード パラメタ1～10のいずれか
                 xobjh.object_code in ( gv_object_code_01
                                      , gv_object_code_02
                                      , gv_object_code_03
                                      , gv_object_code_04
                                      , gv_object_code_05
                                      , gv_object_code_06
                                      , gv_object_code_07
                                      , gv_object_code_08
                                      , gv_object_code_09
                                      , gv_object_code_10
                                      )
               )
             )
         -- リース契約ヘッダ.契約番号 , リース物件.物件コード , リース支払計画.支払回数
       ORDER BY xconhe.contract_number
              , xobjh.object_code
              , xppl.payment_frequency
    ;
    -- 支払計画 取得カーソル  パラメータ.契約番号が未指定
    CURSOR l_no_xpay_plan_rec_cur
    IS
      SELECT xppl.contract_line_id                --  リース支払計画.契約明細内部ID
      ,      xppl.payment_frequency               --  リース支払計画.支払回数
      ,      xppl.contract_header_id              --  リース支払計画.契約内部ID
      ,      xppl.period_name                     --  リース支払計画.会計期間
      ,      TO_CHAR( xppl.payment_date , cv_date_format ) AS payment_date
                                                  --  リース支払計画.支払日
      ,      xppl.lease_charge                    --  リース支払計画.リース料
      ,      xppl.lease_tax_charge                --  リース支払計画.リース料_消費税
      ,      xppl.lease_deduction                 --  リース支払計画.リース控除額
      ,      xppl.lease_tax_deduction             --  リース支払計画.リース控除額_消費税
      ,      xppl.op_charge                       --  リース支払計画.ＯＰリース料
      ,      xppl.op_tax_charge                   --  リース支払計画.ＯＰリース料額_消費税
      ,      xppl.fin_debt                        --  リース支払計画.ＦＩＮリース債務額
      ,      xppl.fin_tax_debt                    --  リース支払計画.ＦＩＮリース債務額_消費税
      ,      xppl.fin_interest_due                --  リース支払計画.ＦＩＮリース支払利息
      ,      xppl.fin_debt_rem                    --  リース支払計画.ＦＩＮリース債務残
      ,      xppl.fin_tax_debt_rem                --  リース支払計画.ＦＩＮリース債務残_消費税
      ,      xppl.accounting_if_flag              --  リース支払計画.会計ＩＦフラグ
      ,      xppl.payment_match_flag              --  リース支払計画.照合済フラグ
      ,      xppl.created_by                      --  リース支払計画.作成者
      ,      TO_CHAR( xppl.creation_date , cv_date_format ) AS creation_date
                                                  --  リース支払計画.作成日
      ,      xppl.last_updated_by                 --  リース支払計画.最終更新者
      ,      TO_CHAR( xppl.last_update_date , cv_date_format ) AS last_update_date
                                                  --  リース支払計画.最終更新日
      ,      xppl.last_update_login               --  リース支払計画.最終更新ログイン
      ,      xppl.request_id                      --  リース支払計画.要求ID
      ,      xppl.program_application_id          --  リース支払計画.コンカレント・プログラム・アプリケーションID
      ,      xppl.program_id                      --  リース支払計画.コンカレント・プログラムID
      ,      TO_CHAR( xppl.program_update_date , cv_date_format ) AS program_update_date
                                                  --  リース支払計画.プログラム更新日
        FROM xxcff_contract_headers xconhe        --  リース契約ヘッダ
           , xxcff_contract_lines   xconli        --  リース契約明細
           , xxcff_object_headers   xobjh         --  リース物件
           , xxcff_pay_planning     xppl          --  リース支払計画
       WHERE
             -- リース契約ヘッダ.契約内部ID = リース契約明細.契約内部ID
             xconhe.contract_header_id = xconli.contract_header_id
             -- リース契約ヘッダ.契約内部ID = リース支払計画.契約内部ID
         AND xconhe.contract_header_id = xppl.contract_header_id
             -- リース契約明細.契約明細内部ID = リース支払計画.契約明細内部ID
         AND xconli.contract_line_id = xppl.contract_line_id
             -- リース契約明細.物件内部ID = リース物件.物件内部ID
         AND xconli.object_header_id = xobjh.object_header_id
             -- リース契約ヘッダ.再リース回数 = リース物件.再リース回数
         AND xconhe.re_lease_times = xobjh.re_lease_times
             -- リース契約ヘッダ.リース会社 = :パラメータリース会社
         AND ( gv_lease_company IS NULL
             OR
               xconhe.lease_company = gv_lease_company
             )
         AND -- リース物件.物件コード パラメタ1～10のいずれか
             xobjh.object_code in ( gv_object_code_01
                                  , gv_object_code_02
                                  , gv_object_code_03
                                  , gv_object_code_04
                                  , gv_object_code_05
                                  , gv_object_code_06
                                  , gv_object_code_07
                                  , gv_object_code_08
                                  , gv_object_code_09
                                  , gv_object_code_10
                                  )
         -- リース契約ヘッダ.契約番号 , リース物件.物件コード , リース支払計画.支払回数
       ORDER BY xconhe.contract_number
              , xobjh.object_code
              , xppl.payment_frequency
    ;
    TYPE l_xpay_plan_rec_ttype IS TABLE OF l_xpay_plan_rec_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xpay_plan_rec_tab l_xpay_plan_rec_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
--
    -- ===============================================
    -- 入力パラメータチェック
    -- ===============================================
    -- パラメータ.物件コード1～10の内、一つでも指定されている場合は物件コード指定有無フラグを有りにする。
    gv_obj_code_param := cv_obj_code_param_off;
    IF ( gv_object_code_01 IS NOT NULL ) OR
       ( gv_object_code_02 IS NOT NULL ) OR
       ( gv_object_code_03 IS NOT NULL ) OR
       ( gv_object_code_04 IS NOT NULL ) OR
       ( gv_object_code_05 IS NOT NULL ) OR
       ( gv_object_code_06 IS NOT NULL ) OR
       ( gv_object_code_07 IS NOT NULL ) OR
       ( gv_object_code_08 IS NOT NULL ) OR
       ( gv_object_code_09 IS NOT NULL ) OR
       ( gv_object_code_10 IS NOT NULL )
      THEN
       gv_obj_code_param := cv_obj_code_param_on;
    END IF;
    -- ===============================================
    -- リース会社・物件コードチェック
    -- ===============================================
    -- パラメータ.物件コード1～10が全て未指定の場合、パラメータ.契約番号、パラメータ.リース会社は共に必須
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( ( gv_lease_company IS NULL ) OR ( gv_contract_number IS NULL ) ) 
      THEN
        lv_errmsg  := '物件コードが未指定時は、契約番号とリース会社を指定して下さい。';
        lv_errbuf  := lv_errmsg;
        RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- リース支払計画 抽出処理
    -- ===============================================
    -- リース支払計画情報取得カーソル
    IF gv_contract_number IS NULL THEN
       -- パラメータ.契約番号が未指定
      OPEN l_no_xpay_plan_rec_cur;
      FETCH l_no_xpay_plan_rec_cur BULK COLLECT INTO l_xpay_plan_rec_tab;
      CLOSE l_no_xpay_plan_rec_cur;
    ELSE
       -- パラメータ.契約番号が指定有り
      OPEN l_xpay_plan_rec_cur;
      FETCH l_xpay_plan_rec_cur BULK COLLECT INTO l_xpay_plan_rec_tab;
      CLOSE l_xpay_plan_rec_cur;
    END IF;
    --処理件数カウント
    gn_target_cnt := l_xpay_plan_rec_tab.COUNT;
--
    -- 見出し
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"リース支払計画"'
    );
    -- 項目名
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || '契約明細内部ID'                           || cv_enclosed
         || cv_delimit || cv_enclosed || '支払回数'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '契約内部ID'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '会計期間'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '支払日'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース料'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース料_消費税'                          || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース控除額'                             || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース控除額_消費税'                      || cv_enclosed
         || cv_delimit || cv_enclosed || 'ＯＰリース料'                             || cv_enclosed
         || cv_delimit || cv_enclosed || 'ＯＰリース料額_消費税'                    || cv_enclosed
         || cv_delimit || cv_enclosed || 'ＦＩＮリース債務額'                       || cv_enclosed
         || cv_delimit || cv_enclosed || 'ＦＩＮリース債務額_消費税'                || cv_enclosed
         || cv_delimit || cv_enclosed || 'ＦＩＮリース支払利息'                     || cv_enclosed
         || cv_delimit || cv_enclosed || 'ＦＩＮリース債務残'                       || cv_enclosed
         || cv_delimit || cv_enclosed || 'ＦＩＮリース債務残_消費税'                || cv_enclosed
         || cv_delimit || cv_enclosed || '会計ＩＦフラグ'                           || cv_enclosed
         || cv_delimit || cv_enclosed || '照合済フラグ'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '作成者'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '作成日'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新者'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新日'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新ログイン'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '要求ID'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレントプログラムアプリケーションID' || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレントプログラムID'                 || cv_enclosed
         || cv_delimit || cv_enclosed || 'プログラム更新日'                         || cv_enclosed
    );
--
    <<lines_loop>>
    FOR i IN 1 .. l_xpay_plan_rec_tab.COUNT LOOP
        -- 項目値
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>          cv_enclosed || l_xpay_plan_rec_tab( i ).contract_line_id       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).payment_frequency      || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).contract_header_id     || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).period_name            || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).payment_date           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_charge           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_tax_charge       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_deduction        || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_tax_deduction    || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).op_charge              || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).op_tax_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_debt               || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_tax_debt           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_interest_due       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_debt_rem           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_tax_debt_rem       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).accounting_if_flag     || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).payment_match_flag     || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).created_by             || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).creation_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).last_updated_by        || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).last_update_date       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).last_update_login      || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).request_id             || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).program_application_id || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).program_id             || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).program_update_date    || cv_enclosed
        );
        --成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP lines_loop;
--
--
    -- 対象件数０件の場合、終了ステータスを「警告」にする
    IF (gn_target_cnt = 0) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '対象データが存在しません。'
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** 入力パラメータ例外ハンドラ ***
    WHEN err_prm_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT VARCHAR2,       --   エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       --   リターン・コード    --# 固定 #
    iv_contract_number  IN  VARCHAR2,       --    1.契約番号
    iv_lease_company    IN  VARCHAR2,       --    2.リース会社
    iv_object_code_01   IN  VARCHAR2,       --    3.物件コード1
    iv_object_code_02   IN  VARCHAR2,       --    4.物件コード2
    iv_object_code_03   IN  VARCHAR2,       --    5.物件コード3
    iv_object_code_04   IN  VARCHAR2,       --    6.物件コード4
    iv_object_code_05   IN  VARCHAR2,       --    7.物件コード5
    iv_object_code_06   IN  VARCHAR2,       --    8.物件コード6
    iv_object_code_07   IN  VARCHAR2,       --    9.物件コード7
    iv_object_code_08   IN  VARCHAR2,       --   10.物件コード8
    iv_object_code_09   IN  VARCHAR2,       --   11.物件コード9
    iv_object_code_10   IN  VARCHAR2        --   12.物件コード10
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- パラメータをグローバル変数に設定
    gv_contract_number := iv_contract_number;  -- 契約番号
    gv_lease_company   := iv_lease_company;    -- リース会社
    gv_object_code_01  := iv_object_code_01;   -- 物件コード1
    gv_object_code_02  := iv_object_code_02;   -- 物件コード2
    gv_object_code_03  := iv_object_code_03;   -- 物件コード3
    gv_object_code_04  := iv_object_code_04;   -- 物件コード4
    gv_object_code_05  := iv_object_code_05;   -- 物件コード5
    gv_object_code_06  := iv_object_code_06;   -- 物件コード6
    gv_object_code_07  := iv_object_code_07;   -- 物件コード7
    gv_object_code_08  := iv_object_code_08;   -- 物件コード8
    gv_object_code_09  := iv_object_code_09;   -- 物件コード9
    gv_object_code_10  := iv_object_code_10;   -- 物件コード10
    -- プログラム入力項目を出力
    -- 契約番号
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '契約番号：' || gv_contract_number
    );
    -- リース会社
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'リース会社：' || gv_lease_company
    );
    -- 物件コード1
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード1：' || gv_object_code_01
    );
    -- 物件コード2
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード2：' || gv_object_code_02
    );
    -- 物件コード3
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード3：' || gv_object_code_03
    );
    -- 物件コード4
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード4：' || gv_object_code_04
    );
    -- 物件コード5
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード5：' || gv_object_code_05
    );
    -- 物件コード6
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード6：' || gv_object_code_06
    );
    -- 物件コード7
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード7：' || gv_object_code_07
    );
    -- 物件コード8
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード8：' || gv_object_code_08
    );
    -- 物件コード9
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード9：' || gv_object_code_09
    );
    -- 物件コード10
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード10：' || gv_object_code_10
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --エラーの場合、成功件数クリア
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP008A03C;
/
