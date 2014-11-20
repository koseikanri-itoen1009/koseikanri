create or replace
PACKAGE BODY XXCCP008A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A01C(body)
 * Description      : リース契約データCSV出力
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  out_csv_data           CSV出力の実行                             (A-3)
 *  chk_param              入力パラメータチェック処理                (A-2)
 *  init                   初期処理                                  (A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/30    1.0   SCSK 古山        新規作成
 *  2013/07/05    1.1   SCSK 中村        E_本稼動_10871対応 消費税増税対応
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP008A01C';   -- パッケージ名
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
   * Procedure Name   : out_csv_data
   * Description      : CSV出力の実行
   **********************************************************************************/
  PROCEDURE out_csv_data(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_data'; -- プログラム名
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
    cv_date_ymdhms          CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';       --YYYYMMDDHHMISS型
    cv_date_ymd             CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD';                  --YYYYMMDD型
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 契約情報 取得カーソル(パラメータ.契約番号指定有り)
    CURSOR l_contract_rec_cur
    IS
      SELECT
         xch.contract_header_id                             AS  h_contract_header_id        -- ヘッダ.契約内部ID
        ,xch.contract_number                                AS  contract_number             -- ヘッダ.契約番号
        ,xch.lease_class                                    AS  lease_class                 -- ヘッダ.リース種別
        ,xch.lease_type                                     AS  lease_type                  -- ヘッダ.リース区分
        ,xch.lease_company                                  AS  lease_company               -- ヘッダ.リース会社
        ,xch.re_lease_times                                 AS  re_lease_times              -- ヘッダ.再リース回数
        ,xch.comments                                       AS  comments                    -- ヘッダ.件名
        ,TO_CHAR( xch.contract_date, cv_date_ymd )          AS  contract_date               -- ヘッダ.リース契約日
        ,xch.payment_frequency                              AS  payment_frequency           -- ヘッダ.支払回数
        ,xch.payment_type                                   AS  payment_type                -- ヘッダ.頻度
        ,xch.payment_years                                  AS  payment_years               -- ヘッダ.年数
        ,TO_CHAR( xch.lease_start_date, cv_date_ymd )       AS  lease_start_date            -- ヘッダ.リース開始日
        ,TO_CHAR( xch.lease_end_date, cv_date_ymd )         AS  lease_end_date              -- ヘッダ.リース終了日
        ,TO_CHAR( xch.first_payment_date, cv_date_ymd )     AS  first_payment_date          -- ヘッダ.初回支払日
        ,TO_CHAR( xch.second_payment_date, cv_date_ymd )    AS  second_payment_date         -- ヘッダ.2回目支払日
        ,xch.third_payment_date                             AS  third_payment_date          -- ヘッダ.3回目以降支払日
        ,xch.start_period_name                              AS  start_period_name           -- ヘッダ.費用計上開始会計期間
        ,xch.lease_payment_flag                             AS  lease_payment_flag          -- ヘッダ.リース支払計画完了フラグ
-- 2013/07/05 Ver.1.1 K.Nakamura MOD Start
--        ,xch.tax_code                                       AS  tax_code                    -- ヘッダ.税金コード
        ,DECODE(xcl.tax_code, NULL, xch.tax_code,
                                    xcl.tax_code)           AS  tax_code                    -- 明細.税金コード、NULLの場合はヘッダ.税金コード
-- 2013/07/05 Ver.1.1 K.Nakamura MOD End
        ,xch.created_by                                     AS  h_created_by                -- ヘッダ.作成者
        ,TO_CHAR( xch.creation_date, cv_date_ymdhms )       AS  h_creation_date             -- ヘッダ.作成日
        ,xch.last_updated_by                                AS  h_last_updated_by           -- ヘッダ.最終更新者
        ,TO_CHAR( xch.last_update_date, cv_date_ymdhms )    AS  h_last_update_date          -- ヘッダ.最終更新日
        ,xch.last_update_login                              AS  h_last_update_login         -- ヘッダ.最終更新ログイン
        ,xch.request_id                                     AS  h_request_id                -- ヘッダ.要求ID
        ,xch.program_application_id                         AS  h_program_application_id    -- ヘッダ.コンカレント・プログラム・アプリケーションID
        ,xch.program_id                                     AS  h_program_id                -- ヘッダ.コンカレント・プログラムID
        ,TO_CHAR( xch.program_update_date, cv_date_ymdhms ) AS  h_program_update_date       -- ヘッダ.プログラム更新日
        ,xcl.contract_line_id                               AS  contract_line_id            -- 明細.契約明細内部ID
        ,xcl.contract_line_num                              AS  contract_line_num           -- 明細.契約枝番
        ,xcl.contract_status                                AS  contract_status             -- 明細.契約ステータス
        ,xcl.first_charge                                   AS  first_charge                -- 明細.初回月額リース料_リース料
        ,xcl.first_tax_charge                               AS  first_tax_charge            -- 明細.初回消費税額_リース料
        ,xcl.first_total_charge                             AS  first_total_charge          -- 明細.初回計_リース料
        ,xcl.second_charge                                  AS  second_charge               -- 明細.2回目以降月額リース料_リース料
        ,xcl.second_tax_charge                              AS  second_tax_charge           -- 明細.2回目以降消費税額_リース料
        ,xcl.second_total_charge                            AS  second_total_charge         -- 明細.2回目以降計_リース料
        ,xcl.first_deduction                                AS  first_deduction             -- 明細.初回月額リース料_控除額
        ,xcl.first_tax_deduction                            AS  first_tax_deduction         -- 明細.初回月額消費税額_控除額
        ,xcl.first_total_deduction                          AS  first_total_deduction       -- 明細.初回計_控除額
        ,xcl.second_deduction                               AS  second_deduction            -- 明細.2回目以降月額リース料_控除額
        ,xcl.second_tax_deduction                           AS  second_tax_deduction        -- 明細.2回目以降消費税額_控除額
        ,xcl.second_total_deduction                         AS  second_total_deduction      -- 明細.2回目以降計_控除額
        ,xcl.gross_charge                                   AS  gross_charge                -- 明細.総額リース料_リース料
        ,xcl.gross_tax_charge                               AS  gross_tax_charge            -- 明細.総額消費税_リース料
        ,xcl.gross_total_charge                             AS  gross_total_charge          -- 明細.総額計_リース料
        ,xcl.gross_deduction                                AS  gross_deduction             -- 明細.総額リース料_控除額
        ,xcl.gross_tax_deduction                            AS  gross_tax_deduction         -- 明細.総額消費税_控除額
        ,xcl.gross_total_deduction                          AS  gross_total_deduction       -- 明細.総額計_控除額
        ,xcl.lease_kind                                     AS  lease_kind                  -- 明細.リース種類
        ,xcl.estimated_cash_price                           AS  estimated_cash_price        -- 明細.見積現金購入価額
        ,xcl.present_value_discount_rate                    AS  present_value_discount_rate -- 明細.現在価値割引率
        ,xcl.present_value                                  AS  present_value               -- 明細.現在価値
        ,xcl.life_in_months                                 AS  life_in_months              -- 明細.法定耐用年数
        ,xcl.original_cost                                  AS  original_cost               -- 明細.取得価額
        ,xcl.calc_interested_rate                           AS  calc_interested_rate        -- 明細.計算利子率
        ,xcl.object_header_id                               AS  object_header_id            -- 明細.物件内部ID
        ,xcl.asset_category                                 AS  asset_category              -- 明細.資産種類
        ,TO_CHAR( xcl.expiration_date, cv_date_ymd)         AS  expiration_date             -- 明細.満了日
        ,TO_CHAR( xcl.cancellation_date, cv_date_ymd)       AS  cancellation_date           -- 明細.中途解約日
        ,TO_CHAR( xcl.vd_if_date, cv_date_ymdhms)           AS  vd_if_date                  -- 明細.リース契約情報連携日
        ,TO_CHAR( xcl.info_sys_if_date, cv_date_ymdhms)     AS  info_sys_if_date            -- 明細.リース管理情報連携日
        ,xcl.first_installation_address                     AS  first_installation_address  -- 明細.初回設置場所
        ,xcl.first_installation_place                       AS  first_installation_place    -- 明細.初回設置先
        ,xcl.created_by                                     AS  l_created_by                -- 明細.作成者
        ,TO_CHAR( xcl.creation_date, cv_date_ymdhms )       AS  l_creation_date             -- 明細.作成日
        ,xcl.last_updated_by                                AS  l_last_updated_by           -- 明細.最終更新者
        ,TO_CHAR( xcl.last_update_date, cv_date_ymdhms )    AS  l_last_update_date          -- 明細.最終更新日
        ,xcl.last_update_login                              AS  l_last_update_login         -- 明細.最終更新ログイン
        ,xcl.request_id                                     AS  l_request_id                -- 明細.要求ID
        ,xcl.program_application_id                         AS  l_program_application_id    -- 明細.コンカレント・プログラム・アプリケーションID
        ,xcl.program_id                                     AS  l_program_id                -- 明細.コンカレント・プログラムID
        ,TO_CHAR( xcl.program_update_date, cv_date_ymdhms ) AS  l_program_update_date       -- 明細.プログラム更新日
      FROM
         xxcff_contract_headers xch        --  リース契約ヘッダ
        ,xxcff_contract_lines   xcl        --  リース契約明細
        ,xxcff_object_headers   xoh        --  リース物件
        ,( -- 各契約毎の最大再リース回数
           SELECT 
              c_head.contract_number          AS contract_number
             ,c_head.lease_company            AS lease_company
             ,MAX(c_head.re_lease_times)      AS re_lease_times
           FROM
             xxcff_contract_headers   c_head      -- リース契約ヘッダ
           WHERE
             c_head.contract_number = gv_contract_number
           GROUP BY
              c_head.contract_number
             ,c_head.lease_company
         ) c_head_max
      WHERE
          -- リース契約ヘッダ.契約内部ID = リース契約明細.契約内部ID
          xch.contract_header_id = xcl.contract_header_id
            -- リース契約明細.物件内部ID = リース物件.物件内部ID
      AND xcl.object_header_id = xoh.object_header_id
          --  リース契約ヘッダ.再リース回数が最大
      AND xch.contract_number = c_head_max.contract_number
      AND xch.lease_company   = c_head_max.lease_company
      AND xch.re_lease_times  = c_head_max.re_lease_times
          -- リース契約ヘッダ.契約番号 = :パラメータ契約番号
      AND xch.contract_number = gv_contract_number
          -- リース契約ヘッダ.リース会社 = :パラメータリース会社
      AND ( gv_lease_company IS NULL
          OR
            xch.lease_company = gv_lease_company
          )
          -- 物件コードの指定がある場合は、いずれかに合致するもの
      AND (
            gv_obj_code_param = cv_obj_code_param_off
          OR
            (
              gv_obj_code_param = cv_obj_code_param_on
              AND
              -- リース物件.物件コード パラメタ1～10のいずれか
              xoh.object_code in ( gv_object_code_01
                                  ,gv_object_code_02
                                  ,gv_object_code_03
                                  ,gv_object_code_04
                                  ,gv_object_code_05
                                  ,gv_object_code_06
                                  ,gv_object_code_07
                                  ,gv_object_code_08
                                  ,gv_object_code_09
                                  ,gv_object_code_10
                                   )
            )
          )
      ORDER BY
         xch.contract_number
        ,xoh.object_code
      ;
--
    -- 契約情報 取得カーソル(パラメータ.契約番号指定無し)
    CURSOR l_no_contract_rec_cur
    IS
      SELECT
         xch.contract_header_id                             AS  h_contract_header_id        -- ヘッダ.契約内部ID
        ,xch.contract_number                                AS  contract_number             -- ヘッダ.契約番号
        ,xch.lease_class                                    AS  lease_class                 -- ヘッダ.リース種別
        ,xch.lease_type                                     AS  lease_type                  -- ヘッダ.リース区分
        ,xch.lease_company                                  AS  lease_company               -- ヘッダ.リース会社
        ,xch.re_lease_times                                 AS  re_lease_times              -- ヘッダ.再リース回数
        ,xch.comments                                       AS  comments                    -- ヘッダ.件名
        ,TO_CHAR( xch.contract_date, cv_date_ymd )          AS  contract_date               -- ヘッダ.リース契約日
        ,xch.payment_frequency                              AS  payment_frequency           -- ヘッダ.支払回数
        ,xch.payment_type                                   AS  payment_type                -- ヘッダ.頻度
        ,xch.payment_years                                  AS  payment_years               -- ヘッダ.年数
        ,TO_CHAR( xch.lease_start_date, cv_date_ymd )       AS  lease_start_date            -- ヘッダ.リース開始日
        ,TO_CHAR( xch.lease_end_date, cv_date_ymd )         AS  lease_end_date              -- ヘッダ.リース終了日
        ,TO_CHAR( xch.first_payment_date, cv_date_ymd )     AS  first_payment_date          -- ヘッダ.初回支払日
        ,TO_CHAR( xch.second_payment_date, cv_date_ymd )    AS  second_payment_date         -- ヘッダ.2回目支払日
        ,xch.third_payment_date                             AS  third_payment_date          -- ヘッダ.3回目以降支払日
        ,xch.start_period_name                              AS  start_period_name           -- ヘッダ.費用計上開始会計期間
        ,xch.lease_payment_flag                             AS  lease_payment_flag          -- ヘッダ.リース支払計画完了フラグ
-- 2013/07/05 Ver.1.1 K.Nakamura MOD Start
--        ,xch.tax_code                                       AS  tax_code                    -- ヘッダ.税金コード
        ,DECODE(xcl.tax_code, NULL, xch.tax_code,
                                    xcl.tax_code)           AS  tax_code                    -- 明細.税金コード、NULLの場合はヘッダ.税金コード
-- 2013/07/05 Ver.1.1 K.Nakamura MOD End
        ,xch.created_by                                     AS  h_created_by                -- ヘッダ.作成者
        ,TO_CHAR( xch.creation_date, cv_date_ymdhms )       AS  h_creation_date             -- ヘッダ.作成日
        ,xch.last_updated_by                                AS  h_last_updated_by           -- ヘッダ.最終更新者
        ,TO_CHAR( xch.last_update_date, cv_date_ymdhms )    AS  h_last_update_date          -- ヘッダ.最終更新日
        ,xch.last_update_login                              AS  h_last_update_login         -- ヘッダ.最終更新ログイン
        ,xch.request_id                                     AS  h_request_id                -- ヘッダ.要求ID
        ,xch.program_application_id                         AS  h_program_application_id    -- ヘッダ.コンカレント・プログラム・アプリケーションID
        ,xch.program_id                                     AS  h_program_id                -- ヘッダ.コンカレント・プログラムID
        ,TO_CHAR( xch.program_update_date, cv_date_ymdhms ) AS  h_program_update_date       -- ヘッダ.プログラム更新日
        ,xcl.contract_line_id                               AS  contract_line_id            -- 明細.契約明細内部ID
        ,xcl.contract_line_num                              AS  contract_line_num           -- 明細.契約枝番
        ,xcl.contract_status                                AS  contract_status             -- 明細.契約ステータス
        ,xcl.first_charge                                   AS  first_charge                -- 明細.初回月額リース料_リース料
        ,xcl.first_tax_charge                               AS  first_tax_charge            -- 明細.初回消費税額_リース料
        ,xcl.first_total_charge                             AS  first_total_charge          -- 明細.初回計_リース料
        ,xcl.second_charge                                  AS  second_charge               -- 明細.2回目以降月額リース料_リース料
        ,xcl.second_tax_charge                              AS  second_tax_charge           -- 明細.2回目以降消費税額_リース料
        ,xcl.second_total_charge                            AS  second_total_charge         -- 明細.2回目以降計_リース料
        ,xcl.first_deduction                                AS  first_deduction             -- 明細.初回月額リース料_控除額
        ,xcl.first_tax_deduction                            AS  first_tax_deduction         -- 明細.初回月額消費税額_控除額
        ,xcl.first_total_deduction                          AS  first_total_deduction       -- 明細.初回計_控除額
        ,xcl.second_deduction                               AS  second_deduction            -- 明細.2回目以降月額リース料_控除額
        ,xcl.second_tax_deduction                           AS  second_tax_deduction        -- 明細.2回目以降消費税額_控除額
        ,xcl.second_total_deduction                         AS  second_total_deduction      -- 明細.2回目以降計_控除額
        ,xcl.gross_charge                                   AS  gross_charge                -- 明細.総額リース料_リース料
        ,xcl.gross_tax_charge                               AS  gross_tax_charge            -- 明細.総額消費税_リース料
        ,xcl.gross_total_charge                             AS  gross_total_charge          -- 明細.総額計_リース料
        ,xcl.gross_deduction                                AS  gross_deduction             -- 明細.総額リース料_控除額
        ,xcl.gross_tax_deduction                            AS  gross_tax_deduction         -- 明細.総額消費税_控除額
        ,xcl.gross_total_deduction                          AS  gross_total_deduction       -- 明細.総額計_控除額
        ,xcl.lease_kind                                     AS  lease_kind                  -- 明細.リース種類
        ,xcl.estimated_cash_price                           AS  estimated_cash_price        -- 明細.見積現金購入価額
        ,xcl.present_value_discount_rate                    AS  present_value_discount_rate -- 明細.現在価値割引率
        ,xcl.present_value                                  AS  present_value               -- 明細.現在価値
        ,xcl.life_in_months                                 AS  life_in_months              -- 明細.法定耐用年数
        ,xcl.original_cost                                  AS  original_cost               -- 明細.取得価額
        ,xcl.calc_interested_rate                           AS  calc_interested_rate        -- 明細.計算利子率
        ,xcl.object_header_id                               AS  object_header_id            -- 明細.物件内部ID
        ,xcl.asset_category                                 AS  asset_category              -- 明細.資産種類
        ,TO_CHAR( xcl.expiration_date, cv_date_ymd)         AS  expiration_date             -- 明細.満了日
        ,TO_CHAR( xcl.cancellation_date, cv_date_ymd)       AS  cancellation_date           -- 明細.中途解約日
        ,TO_CHAR( xcl.vd_if_date, cv_date_ymdhms)           AS  vd_if_date                  -- 明細.リース契約情報連携日
        ,TO_CHAR( xcl.info_sys_if_date, cv_date_ymdhms)     AS  info_sys_if_date            -- 明細.リース管理情報連携日
        ,xcl.first_installation_address                     AS  first_installation_address  -- 明細.初回設置場所
        ,xcl.first_installation_place                       AS  first_installation_place    -- 明細.初回設置先
        ,xcl.created_by                                     AS  l_created_by                -- 明細.作成者
        ,TO_CHAR( xcl.creation_date, cv_date_ymdhms )       AS  l_creation_date             -- 明細.作成日
        ,xcl.last_updated_by                                AS  l_last_updated_by           -- 明細.最終更新者
        ,TO_CHAR( xcl.last_update_date, cv_date_ymdhms )    AS  l_last_update_date          -- 明細.最終更新日
        ,xcl.last_update_login                              AS  l_last_update_login         -- 明細.最終更新ログイン
        ,xcl.request_id                                     AS  l_request_id                -- 明細.要求ID
        ,xcl.program_application_id                         AS  l_program_application_id    -- 明細.コンカレント・プログラム・アプリケーションID
        ,xcl.program_id                                     AS  l_program_id                -- 明細.コンカレント・プログラムID
        ,TO_CHAR( xcl.program_update_date, cv_date_ymdhms ) AS  l_program_update_date       -- 明細.プログラム更新日
      FROM
         xxcff_contract_headers xch        --  リース契約ヘッダ
        ,xxcff_contract_lines   xcl        --  リース契約明細
        ,xxcff_object_headers   xoh        --  リース物件
      WHERE
          -- リース契約ヘッダ.契約内部ID = リース契約明細.契約内部ID
          xch.contract_header_id = xcl.contract_header_id
          -- リース契約明細.物件内部ID = リース物件.物件内部ID
      AND xcl.object_header_id = xoh.object_header_id
      AND xoh.re_lease_times = xch.re_lease_times
          -- リース契約ヘッダ.リース会社 = :パラメータリース会社
      AND ( gv_lease_company IS NULL
          OR
            xch.lease_company = gv_lease_company
          )
          -- リース物件.物件コード パラメタ1～10のいずれか
      AND 
          xoh.object_code IN ( gv_object_code_01
                              ,gv_object_code_02
                              ,gv_object_code_03
                              ,gv_object_code_04
                              ,gv_object_code_05
                              ,gv_object_code_06
                              ,gv_object_code_07
                              ,gv_object_code_08
                              ,gv_object_code_09
                              ,gv_object_code_10
                              )
      ORDER BY
         xch.contract_number
        ,xoh.object_code
      ;
--
    TYPE l_contract_rec_ttype IS TABLE OF l_contract_rec_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_contract_rec_tab l_contract_rec_ttype;
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
    -- リース契約情報 抽出処理
    -- ===============================================
--
    IF gv_contract_number IS NULL THEN
    -- 契約情報取得(パラメータ.契約番号指定無し)カーソル
      OPEN l_no_contract_rec_cur;
      FETCH l_no_contract_rec_cur BULK COLLECT INTO l_contract_rec_tab;
      CLOSE l_no_contract_rec_cur;
    ELSE
    -- 契約情報取得(パラメータ.契約番号指定有り)カーソル
      OPEN l_contract_rec_cur;
      FETCH l_contract_rec_cur BULK COLLECT INTO l_contract_rec_tab;
      CLOSE l_contract_rec_cur;
    END IF;
--
    --処理件数カウント
    gn_target_cnt := l_contract_rec_tab.COUNT;
--
    -- 見出し
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"リース契約データ"'
    );
    -- 項目名
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || '契約内部ID'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '契約番号'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース種別'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース区分'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース会社'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '再リース回数'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '件名'                                                     || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース契約日'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '支払回数'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '頻度'                                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '年数'                                                     || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース開始日'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース終了日'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '初回支払日'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '2回目支払日'                                              || cv_enclosed
         || cv_delimit || cv_enclosed || '3回目以降支払日'                                          || cv_enclosed
         || cv_delimit || cv_enclosed || '費用計上開始会計期間'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース支払計画完了フラグ'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '税金コード'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '作成者'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '作成日'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新者'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新日'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新ログイン'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '要求ID'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレントプログラムアプリケーションID'                 || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレントプログラムID'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || 'プログラム更新日'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '契約明細内部ID'                                           || cv_enclosed
         || cv_delimit || cv_enclosed || '契約枝番'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '契約ステータス'                                           || cv_enclosed
         || cv_delimit || cv_enclosed || '初回月額リース料_リース料'                                || cv_enclosed
         || cv_delimit || cv_enclosed || '初回消費税額_リース料'                                    || cv_enclosed
         || cv_delimit || cv_enclosed || '初回計_リース料'                                          || cv_enclosed
         || cv_delimit || cv_enclosed || '2回目以降月額リース料_リース料'                           || cv_enclosed
         || cv_delimit || cv_enclosed || '2回目以降消費税額_リース料'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '2回目以降計_リース料'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '初回月額リース料_控除額'                                  || cv_enclosed
         || cv_delimit || cv_enclosed || '初回月額消費税額_控除額'                                  || cv_enclosed
         || cv_delimit || cv_enclosed || '初回計_控除額'                                            || cv_enclosed
         || cv_delimit || cv_enclosed || '2回目以降月額リース料_控除額'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '2回目以降消費税額_控除額'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '2回目以降計_控除額'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '総額リース料_リース料'                                    || cv_enclosed
         || cv_delimit || cv_enclosed || '総額消費税_リース料'                                      || cv_enclosed
         || cv_delimit || cv_enclosed || '総額計_リース料'                                          || cv_enclosed
         || cv_delimit || cv_enclosed || '総額リース料_控除額'                                      || cv_enclosed
         || cv_delimit || cv_enclosed || '総額消費税_控除額'                                        || cv_enclosed
         || cv_delimit || cv_enclosed || '総額計_控除額'                                            || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース種類'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '見積現金購入価額'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '現在価値割引率'                                           || cv_enclosed
         || cv_delimit || cv_enclosed || '現在価値'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '法定耐用年数'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '取得価額'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '計算利子率'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '物件内部ID'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '資産種類'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '満了日'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '中途解約日'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース契約情報連携日'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース管理情報連携日'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '初回設置場所'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '初回設置先'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '作成者(リース契約明細)'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '作成日(リース契約明細)'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新者(リース契約明細)'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新日(リース契約明細)'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新ログイン(リース契約明細)'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '要求ID(リース契約明細)'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレントプログラムアプリケーションID(リース契約明細)' || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレントプログラムID(リース契約明細)'                 || cv_enclosed
         || cv_delimit || cv_enclosed || 'プログラム更新日(リース契約明細)'                         || cv_enclosed
    );
--
    <<lines_loop>>
    FOR i IN 1 .. l_contract_rec_tab.COUNT LOOP
        -- 項目値
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>          cv_enclosed || l_contract_rec_tab( i ).h_contract_header_id        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_number             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_class                 || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_type                  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_company               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).re_lease_times              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).comments                    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_date               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).payment_frequency           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).payment_type                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).payment_years               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_start_date            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_end_date              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_payment_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_payment_date         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).third_payment_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).start_period_name           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_payment_flag          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).tax_code                    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_created_by                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_creation_date             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_last_updated_by           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_last_update_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_last_update_login         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_request_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_program_application_id    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_program_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_program_update_date       || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_line_id            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_line_num           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_status             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_charge                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_tax_charge            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_total_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_charge               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_tax_charge           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_total_charge         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_deduction             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_tax_deduction         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_total_deduction       || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_deduction            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_tax_deduction        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_total_deduction      || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_charge                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_tax_charge            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_total_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_deduction             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_tax_deduction         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_total_deduction       || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_kind                  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).estimated_cash_price        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).present_value_discount_rate || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).present_value               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).life_in_months              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).original_cost               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).calc_interested_rate        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).object_header_id            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).asset_category              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).expiration_date             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).cancellation_date           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).vd_if_date                  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).info_sys_if_date            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_installation_address  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_installation_place    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_created_by                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_creation_date             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_last_updated_by           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_last_update_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_last_update_login         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_request_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_program_application_id    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_program_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_program_update_date       || cv_enclosed
        );
        --成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP lines_loop;
--
  EXCEPTION
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
  END out_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : 入力パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf           OUT   VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT   VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg           OUT   VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
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
    -- ===============================================
    -- ローカル例外処理
    -- ===============================================
    err_prm_expt             EXCEPTION;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 物件コード指定有無フラグ更新
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
--
    -- ===============================================
    -- 会社リース・物件コードチェック
    -- ===============================================
    -- パラメータ.物件コード1～10が全て未指定 かつ、パラメータ.リース会社が未指定
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( gv_lease_company IS NULL ) AND
       ( gv_contract_number IS NOT NULL ) THEN
      lv_errmsg  := '物件コードが未指定時は、契約番号とリース会社を指定して下さい。';
      lv_errbuf  := lv_errmsg;
      RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- 契約番号・物件コードチェック
    -- ===============================================
    -- パラメータ.物件コード1～10が全て未指定 かつ、パラメータ.契約番号が未指定
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( gv_contract_number IS NULL ) AND
       ( gv_lease_company IS NOT NULL ) THEN
      lv_errmsg  := '物件コードが未指定時は、契約番号とリース会社を指定して下さい。';
      lv_errbuf  := lv_errmsg;
      RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- 契約番号・物件コードチェック
    -- ===============================================
    -- パラメータ全てが未指定
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( gv_contract_number IS NULL ) AND
       ( gv_lease_company IS NULL ) THEN
      lv_errmsg  := '物件コードが未指定時は、契約番号とリース会社を指定して下さい。';
      lv_errbuf  := lv_errmsg;
      RAISE err_prm_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 入力パラメータ例外ハンドラ ***
    WHEN err_prm_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_contract_number  IN    VARCHAR2,       --   01.契約番号
    iv_lease_company    IN    VARCHAR2,       --   02.リース会社
    iv_object_code_01   IN    VARCHAR2,       --   03.物件コード1
    iv_object_code_02   IN    VARCHAR2,       --   04.物件コード2
    iv_object_code_03   IN    VARCHAR2,       --   05.物件コード3
    iv_object_code_04   IN    VARCHAR2,       --   06.物件コード4
    iv_object_code_05   IN    VARCHAR2,       --   07.物件コード5
    iv_object_code_06   IN    VARCHAR2,       --   08.物件コード6
    iv_object_code_07   IN    VARCHAR2,       --   09.物件コード7
    iv_object_code_08   IN    VARCHAR2,       --   10.物件コード8
    iv_object_code_09   IN    VARCHAR2,       --   11.物件コード9
    iv_object_code_10   IN    VARCHAR2,       --   12.物件コード10
    ov_errbuf           OUT   VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT   VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg           OUT   VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ============================================
    -- パラメータをグローバル変数に設定
    -- ============================================
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
--
    -- ============================================
    -- コンカレントパラメータ出力処理
    -- ============================================
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
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_contract_number  IN    VARCHAR2,       --   01.契約番号
    iv_lease_company    IN    VARCHAR2,       --   02.リース会社
    iv_object_code_01   IN    VARCHAR2,       --   03.物件コード1
    iv_object_code_02   IN    VARCHAR2,       --   04.物件コード2
    iv_object_code_03   IN    VARCHAR2,       --   05.物件コード3
    iv_object_code_04   IN    VARCHAR2,       --   06.物件コード4
    iv_object_code_05   IN    VARCHAR2,       --   07.物件コード5
    iv_object_code_06   IN    VARCHAR2,       --   08.物件コード6
    iv_object_code_07   IN    VARCHAR2,       --   09.物件コード7
    iv_object_code_08   IN    VARCHAR2,       --   10.物件コード8
    iv_object_code_09   IN    VARCHAR2,       --   11.物件コード9
    iv_object_code_10   IN    VARCHAR2,       --   12.物件コード10
    ov_errbuf           OUT   VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT   VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg           OUT   VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
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
--    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';                           -- 区切り文字
--    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';                           -- 単語囲み文字
--
    -- *** ローカル変数 ***
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
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
       iv_contract_number         --   01.契約番号
      ,iv_lease_company           --   02.リース会社
      ,iv_object_code_01          --   03.物件コード1
      ,iv_object_code_02          --   04.物件コード2
      ,iv_object_code_03          --   05.物件コード3
      ,iv_object_code_04          --   06.物件コード4
      ,iv_object_code_05          --   07.物件コード5
      ,iv_object_code_06          --   08.物件コード6
      ,iv_object_code_07          --   09.物件コード7
      ,iv_object_code_08          --   10.物件コード8
      ,iv_object_code_09          --   11.物件コード9
      ,iv_object_code_10          --   12.物件コード10
      ,lv_errbuf                  --   エラー・メッセージ           --# 固定 #
      ,lv_retcode                 --   リターン・コード             --# 固定 #
      ,lv_errmsg                  --   ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．入力パラメータチェック処理
    -- ============================================
--
    chk_param(
       lv_errbuf                  --   エラー・メッセージ           --# 固定 #
      ,lv_retcode                 --   リターン・コード             --# 固定 #
      ,lv_errmsg                  --   ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．CSV出力の実行
    -- ============================================
    out_csv_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
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
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_contract_number         --   01.契約番号
      ,iv_lease_company           --   02.リース会社
      ,iv_object_code_01          --   03.物件コード1
      ,iv_object_code_02          --   04.物件コード2
      ,iv_object_code_03          --   05.物件コード3
      ,iv_object_code_04          --   06.物件コード4
      ,iv_object_code_05          --   07.物件コード5
      ,iv_object_code_06          --   08.物件コード6
      ,iv_object_code_07          --   09.物件コード7
      ,iv_object_code_08          --   10.物件コード8
      ,iv_object_code_09          --   11.物件コード9
      ,iv_object_code_10          --   12.物件コード10
      ,lv_errbuf                  --   エラー・メッセージ           --# 固定 #
      ,lv_retcode                 --   リターン・コード             --# 固定 #
      ,lv_errmsg                  --   ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
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
END XXCCP008A01C;
/