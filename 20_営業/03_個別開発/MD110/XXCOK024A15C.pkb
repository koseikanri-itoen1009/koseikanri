CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A15 (spec)
 * Description      : 控除消込作成API(AP問屋支払)
 * MD.050           : 控除消込作成API(AP問屋支払) MD050_COK_024_A15
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      初期処理(A-1)
 *  sales_dedu_get            販売控除データ抽出(A-2)
 *  insert_dedu_recon_head    控除消込ヘッダー作成(A-3)
 *  insert_dedu_item_recon    商品別突合情報作成(A-4)
 *  insert_dedu_recon_line_wp 控除消込明細情報(問屋未収)作成(A-5)
 *  insert_dedu_num_recon     控除No別消込情報作成(A-6)
 *  insert_dedu_recon_line_ap 控除消込明細情報(AP申請)作成(A-7)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/11    1.0   Y.Nakajima       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt     NUMBER        DEFAULT 0;      -- 異常件数
  gn_skip_cnt      NUMBER        DEFAULT 0;      -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
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
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A15C';                -- パッケージ名
  -- アプリケーション短縮名
  cv_msg_kbn_cok            CONSTANT VARCHAR2(5)  := 'XXCOK';                       -- アドオン：個別開発
  -- メッセージ名称
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';            -- 対象データなしエラーメッセージ
  cv_pro_get_err_msg        CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00003';            -- プロファイル取得エラー
  cv_rock_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';            -- ロックエラーメッセージ
  -- 数値
  cn_zero                   CONSTANT NUMBER       := 0;                             -- 0
  cn_one                    CONSTANT NUMBER       := 1;                             -- 1
  -- 有効フラグ
  cv_enable                 CONSTANT VARCHAR2(1)  := 'Y';
  -- 言語コード
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  -- 参照タイプ
  cv_chain_code             CONSTANT VARCHAR2(50) := 'XXCMM_CHAIN_CODE';            -- 控除用チェーンコード
  cv_deduction_data_type    CONSTANT VARCHAR2(50) := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- 控除データ種類
  cv_target_data_type       CONSTANT VARCHAR2(50) := 'XXCOK1_TARGET_DATA_TYPE';     -- 対象データ種類
  -- プロファイル
  cv_profile_organi_code    CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';    -- 在庫組織コード
  --
  cv_condition_type_ws_fix  CONSTANT VARCHAR2(3)  :=  '030';                        -- 控除タイプ(問屋未収（定額）)
  cv_condition_type_ws_add  CONSTANT VARCHAR2(3)  :=  '040';                        -- 控除タイプ(問屋未収（追加）)
  --
  cv_ap                     CONSTANT VARCHAR2(4)  :=  'AP';                         -- 'AP'
  cv_wp                     CONSTANT VARCHAR2(4)  :=  'WP';                         -- 'WP'
  cv_one                    CONSTANT VARCHAR2(1)  :=  '1';                          -- '1'
  cv_two                    CONSTANT VARCHAR2(1)  :=  '2';                          -- '2'
  cv_three                  CONSTANT VARCHAR2(1)  :=  '3';                          -- '3'
  cv_hon                    CONSTANT VARCHAR2(2)  :=  '本';                         -- 単位:本
  cv_cs                     CONSTANT VARCHAR2(2)  :=  'CS';                         -- 単位:CS
  cv_bl                     CONSTANT VARCHAR2(2)  :=  'BL';                         -- 単位:BL
  cv_status_n               CONSTANT VARCHAR2(1)  :=  'N';                          -- 'N' (新規)
  cv_o                      CONSTANT VARCHAR2(1)  :=  'O';                          -- 'O' (繰越調整)
  -- 控除消込ヘッダ用
  cv_recon_status           CONSTANT VARCHAR2(2)  :=  'EG';                         -- 'EG'(作成中)
  -- トークン名
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE ';                     -- プロファイル
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_organization_code      VARCHAR2(3)   DEFAULT NULL;   -- 在庫組織コード
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_line_ap
   * Description      : 控除消込明細情報(AP申請)作成(A-7)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_line_ap(
    iv_recon_slip_num               IN     VARCHAR2   -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2   -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_line_ap'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 控除No別消込情報の抽出
    CURSOR dedu_num_recon_cur
    IS
      SELECT   xdnr.recon_line_num              AS recon_line_num           -- 消込明細番号
             , xdnr.deduction_chain_code        AS deduction_chain_code     -- 控除用チェーンコード
             , SUM(xdnr.prev_carryover_amt)     AS prev_carryover_amt       -- 前月繰越額(税抜)
             , SUM(xdnr.prev_carryover_tax)     AS prev_carryover_tax       -- 前月繰越額(消費税)
             , SUM(xdnr.deduction_amt)          AS deduction_amt            -- 控除額(税抜)
             , SUM(xdnr.deduction_tax)          AS deduction_tax            -- 控除額(消費税)
      FROM   xxcok_deduction_num_recon    xdnr
      WHERE  xdnr.recon_slip_num = iv_recon_slip_num
      GROUP BY   xdnr.recon_line_num
               , xdnr.deduction_chain_code
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 控除消込明細情報(AP申請)の登録
    <<dedu_recon_line_ap_ins_loop>>
    FOR dedu_num_recon_rec IN dedu_num_recon_cur LOOP
      INSERT INTO xxcok_deduction_recon_line_ap(
        deduction_recon_line_id                     -- 控除消込明細ID
      , recon_slip_num                              -- 支払伝票番号
      , deduction_line_num                          -- 消込明細番号
      , recon_line_status                           -- 入力ステータス
      , deduction_chain_code                        -- 控除用チェーンコード
      , prev_carryover_amt                          -- 前月繰越額(税抜)
      , prev_carryover_tax                          -- 前月繰越額(消費税)
      , deduction_amt                               -- 控除額(税抜)
      , deduction_tax                               -- 控除額(消費税)
      , payment_amt                                 -- 支払額(税抜)
      , payment_tax                                 -- 支払額(消費税)
      , difference_amt                              -- 調整差額(税抜)
      , difference_tax                              -- 調整差額(消費税)
      , next_carryover_amt                          -- 翌月繰越額(税抜)
      , next_carryover_tax                          -- 翌月繰越額(消費税)
      , created_by                                  -- 作成者
      , creation_date                               -- 作成日
      , last_updated_by                             -- 最終更新者
      , last_update_date                            -- 最終更新日
      , last_update_login                           -- 最終更新ログイン
      , request_id                                  -- 要求ID
      , program_application_id                      -- コンカレント・プログラム･アプリケーションID
      , program_id                                  -- コンカレント･プログラムID
      , program_update_date                         -- プログラム更新日
      )
      VALUES(
        xxcok_deduction_recon_line_s01.nextval                                      -- 控除消込明細ID
      , iv_recon_slip_num                                                           -- 支払伝票番号
      , dedu_num_recon_rec.recon_line_num                                           -- 消込明細番号
      , cv_recon_status                                                             -- 入力ステータス
      , dedu_num_recon_rec.deduction_chain_code                                     -- 控除用チェーンコード
      , dedu_num_recon_rec.prev_carryover_amt                                       -- 前月繰越額(税抜)
      , dedu_num_recon_rec.prev_carryover_tax                                       -- 前月繰越額(消費税)
      , dedu_num_recon_rec.deduction_amt                                            -- 控除額(税抜)
      , dedu_num_recon_rec.deduction_tax                                            -- 控除額(消費税)
      , cn_zero                                                                     -- 支払額(税抜)
      , cn_zero                                                                     -- 支払額(消費税)
      , dedu_num_recon_rec.deduction_amt                                            -- 調整差額(税抜)
      , dedu_num_recon_rec.deduction_tax                                            -- 調整差額(消費税)
      , dedu_num_recon_rec.prev_carryover_amt + dedu_num_recon_rec.deduction_amt    -- 翌月繰越額(税抜)
      , dedu_num_recon_rec.prev_carryover_tax + dedu_num_recon_rec.deduction_tax    -- 翌月繰越額(消費税)
      , cn_created_by                                                               -- 作成者
      , SYSDATE                                                                     -- 作成日
      , cn_last_updated_by                                                          -- 最終更新者
      , SYSDATE                                                                     -- 最終更新日
      , cn_last_update_login                                                        -- 最終更新ログイン
      , cn_request_id                                                               -- 要求ID
      , cn_program_application_id                                                   -- コンカレント・プログラム･アプリケーションID
      , cn_program_id                                                               -- コンカレント･プログラムID
      , SYSDATE                                                                     -- プログラム更新日
      )
      ;
--
    END LOOP dedu_recon_line_ap_ins_loop;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_recon_line_ap;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_num_recon
   * Description      : 控除No別消込情報作成(A-6)
   **********************************************************************************/
  PROCEDURE insert_dedu_num_recon(
    iv_recon_slip_num               IN     VARCHAR2   -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2   -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_num_recon'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    -- ブレイク判定用変数
    lt_break_dedu_chain_code      xxcok_sales_deduction.deduction_chain_code%TYPE DEFAULT NULL;         -- 控除用チェーンコード
    -- 明細インクリメント用
    deduction_line_num_cnt        xxcok_deduction_num_recon.deduction_line_num%TYPE;                    -- 控除明細番号
    recon_line_num_cnt            xxcok_deduction_num_recon.recon_line_num%TYPE;                        -- 消込明細番号
--
    -- *** ローカル・カーソル ***
    -- 販売控除情報抽出
    CURSOR sales_dedu_inline_cur
    IS
      SELECT  xsd_inline.deduction_chain_code       AS deduction_chain_code
            , xsd_inline.data_type                  AS data_type
            , xsd_inline.replace_flag               AS replace_flag
            , xsd_inline.condition_no               AS condition_no
            , xsd_inline.tax_code                   AS tax_code
            , SUM(xsd_inline.prev_carryover_amt)    AS prev_carryover_amt
            , SUM(xsd_inline.prev_carryover_tax)    AS prev_carryover_tax
            , SUM(xsd_inline.deduction_amount)      AS deduction_amount
            , SUM(xsd_inline.deduction_tax_amount)  AS deduction_tax_amount
      FROM    (
               SELECT  NVL(xca.intro_chain_code2,xsd.deduction_chain_code)  AS deduction_chain_code   -- 控除用チェーンコード
                     , xsd.data_type                                        AS data_type              -- データ種類
                     , flv.attribute8                                       AS replace_flag           -- 立替フラグ
                     , xsd.condition_no                                     AS condition_no           -- 控除番号
                     , xsd.tax_code                                         AS tax_code               -- 税コード
                     , xsd.deduction_amount * -1                            AS prev_carryover_amt     -- 前月繰越額
                     , xsd.deduction_tax_amount * -1                        AS prev_carryover_tax     -- 前月繰越消費税額
                     , 0                                                    AS deduction_amount       -- 控除額
                     , 0                                                    AS deduction_tax_amount   -- 控除消費税額
               FROM    xxcok_sales_deduction  xsd     -- 販売控除情報
                     , fnd_lookup_values      flv     -- データ種類(参照表)
                     , xxcmm_cust_accounts    xca     -- 顧客追加情報
               WHERE   xsd.carry_payment_slip_num  = iv_recon_slip_num
               AND     flv.lookup_code             = xsd.data_type
               AND     flv.lookup_type             = cv_deduction_data_type
               AND     flv.language                = ct_lang
               AND     flv.enabled_flag            = cv_enable
               AND     flv.attribute2 NOT IN( cv_condition_type_ws_fix,cv_condition_type_ws_add )
               AND     xsd.source_category         = cv_o
               AND     xca.customer_code(+)        = xsd.customer_code_to
               UNION ALL
               SELECT  NVL(xca.intro_chain_code2,xsd.deduction_chain_code)  AS deduction_chain_code   -- 控除用チェーンコード
                     , xsd.data_type            AS data_type              -- データ種類
                     , flv.attribute8           AS replace_flag           -- 立替フラグ
                     , xsd.condition_no         AS condition_no           -- 控除番号
                     , xsd.tax_code             AS tax_code               -- 税コード
                     , 0                        AS prev_carryover_amt     -- 前月繰越額
                     , 0                        AS prev_carryover_tax     -- 前月繰越消費税額
                     , xsd.deduction_amount     AS deduction_amount       -- 控除額
                     , xsd.deduction_tax_amount AS deduction_tax_amount   -- 控除消費税額
               FROM    xxcok_sales_deduction  xsd     -- 販売控除情報
                     , fnd_lookup_values      flv     -- データ種類(参照表)
                     , xxcmm_cust_accounts    xca     -- 顧客追加情報
               WHERE   xsd.carry_payment_slip_num  = iv_recon_slip_num
               AND     flv.lookup_code             = xsd.data_type
               AND     flv.lookup_type             = cv_deduction_data_type
               AND     flv.language                = ct_lang
               AND     flv.enabled_flag            = cv_enable
               AND     flv.attribute2 NOT IN( cv_condition_type_ws_fix,cv_condition_type_ws_add )
               AND     xsd.source_category         <> cv_o
               AND     xca.customer_code(+)        = xsd.customer_code_to
               )                                                           xsd_inline
      GROUP BY   xsd_inline.deduction_chain_code
               , xsd_inline.data_type
               , xsd_inline.replace_flag
               , xsd_inline.condition_no
               , xsd_inline.tax_code
      ORDER BY   xsd_inline.deduction_chain_code
               , xsd_inline.condition_no
               , xsd_inline.tax_code
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    deduction_line_num_cnt := 0;
    recon_line_num_cnt     := 0;
--
--###########################  固定部 END   ############################
--
    -- 控除No別消込情報の登録
    <<dedu_num_recon_ins_loop>>
    FOR sales_dedu_inline_rec IN sales_dedu_inline_cur LOOP
      -- 消込明細番号、控除明細番号の採番
      IF lt_break_dedu_chain_code = sales_dedu_inline_rec.deduction_chain_code THEN
        deduction_line_num_cnt := deduction_line_num_cnt + 1;
        IF recon_line_num_cnt   = 0 THEN
           recon_line_num_cnt  := 1;
        ELSE
          NULL;
        END IF;
      ELSE
        recon_line_num_cnt     := recon_line_num_cnt + 1;
        deduction_line_num_cnt := 1;
      END IF;
      
      -- 控除No別消込情報の登録
      INSERT INTO xxcok_deduction_num_recon(
        deduction_num_recon_id                      -- 控除No別消込ID
      , recon_slip_num                              -- 支払伝票番号
      , recon_line_num                              -- 消込明細番号
      , deduction_chain_code                        -- 控除用チェーンコード
      , deduction_line_num                          -- 控除明細番号
      , data_type                                   -- データ種類
      , target_flag                                 -- 対象フラグ
      , condition_no                                -- 控除番号
      , tax_code                                    -- 消費税コード
      , prev_carryover_amt                          -- 前月繰越額(税抜)
      , prev_carryover_tax                          -- 前月繰越額(消費税)
      , deduction_amt                               -- 控除額(税抜)
      , deduction_tax                               -- 控除額(消費税)
      , carryover_pay_off_flg                       -- 繰越額全額精算フラグ
      , payment_tax_code                            -- 支払時税コード
      , payment_amt                                 -- 支払額(税抜)
      , payment_tax                                 -- 支払額(消費税)
      , difference_amt                              -- 調整差額(税抜)
      , difference_tax                              -- 調整差額(消費税)
      , next_carryover_amt                          -- 翌月繰越額(税抜)
      , next_carryover_tax                          -- 翌月繰越額(消費税)
      , remarks                                     -- 摘要
      , created_by                                  -- 作成者
      , creation_date                               -- 作成日
      , last_updated_by                             -- 最終更新者
      , last_update_date                            -- 最終更新日
      , last_update_login                           -- 最終更新ログイン
      , request_id                                  -- 要求ID
      , program_application_id                      -- コンカレント・プログラム･アプリケーションID
      , program_id                                  -- コンカレント･プログラムID
      , program_update_date                         -- プログラム更新日
      )
      VALUES(
        xxcok_deduction_num_recon_s01.nextval                                                     -- 控除No別消込ID
      , iv_recon_slip_num                                                                         -- 支払伝票番号
      , recon_line_num_cnt                                                                        -- 消込明細番号
      , sales_dedu_inline_rec.deduction_chain_code                                                -- 控除用チェーンコード
      , deduction_line_num_cnt                                                                    -- 控除明細番号
      , sales_dedu_inline_rec.data_type                                                           -- データ種類
      , cv_status_n                                                                               -- 対象フラグ
      , sales_dedu_inline_rec.condition_no                                                        -- 控除番号
      , sales_dedu_inline_rec.tax_code                                                            -- 消費税コード
      , sales_dedu_inline_rec.prev_carryover_amt                                                  -- 前月繰越額(税抜)
      , sales_dedu_inline_rec.prev_carryover_tax                                                  -- 前月繰越額(消費税)
      , sales_dedu_inline_rec.deduction_amount                                                    -- 控除額(税抜)
      , sales_dedu_inline_rec.deduction_tax_amount                                                -- 控除額(消費税)
      , sales_dedu_inline_rec.replace_flag                                                        -- 繰越額全額精算フラグ
      , sales_dedu_inline_rec.tax_code                                                            -- 支払時税コード
      , cn_zero                                                                                   -- 支払額(税抜)
      , cn_zero                                                                                   -- 支払額(消費税)
      , sales_dedu_inline_rec.deduction_amount                                                    -- 調整差額(税抜)
      , sales_dedu_inline_rec.deduction_tax_amount                                                -- 調整差額(消費税)
      , CASE 
          WHEN sales_dedu_inline_rec.replace_flag = cv_enable THEN
            cn_zero
          ELSE
            (sales_dedu_inline_rec.prev_carryover_amt + sales_dedu_inline_rec.deduction_amount)
        END                                                                                       -- 翌月繰越額(税抜)
      , CASE
          WHEN sales_dedu_inline_rec.replace_flag = cv_enable THEN
            cn_zero
          ELSE
            (sales_dedu_inline_rec.prev_carryover_tax + sales_dedu_inline_rec.deduction_tax_amount)
        END                                                                                       -- 翌月繰越額(消費税)
      , NULL                                                                                      -- 摘要
      , cn_created_by                                                                             -- 作成者
      , SYSDATE                                                                                   -- 作成日
      , cn_last_updated_by                                                                        -- 最終更新者
      , SYSDATE                                                                                   -- 最終更新日
      , cn_last_update_login                                                                      -- 最終更新ログイン
      , cn_request_id                                                                             -- 要求ID
      , cn_program_application_id                                                                 -- コンカレント・プログラム･アプリケーションID
      , cn_program_id                                                                             -- コンカレント･プログラムID
      , SYSDATE                                                                                   -- プログラム更新日
      );
--
      -- 控除用チェーンコードを退避
      lt_break_dedu_chain_code := sales_dedu_inline_rec.deduction_chain_code;
--
    END LOOP dedu_num_recon_ins_loop;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_num_recon;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_line_wp
   * Description      : 控除消込明細情報(問屋未収)作成(A-5)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_line_wp(
    iv_recon_slip_num               IN     VARCHAR2          -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_line_wp'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 商品突合情報抽出カーソル
    CURSOR dedu_item_recon_cur
    IS
      SELECT  xdir.deduction_chain_code           AS deduction_chain_code   -- 控除用チェーンコード
             ,SUM(xdir.billing_amount)            AS billing_amount         -- 請求額(税抜)
             ,SUM(xdir.fixed_amount)              AS fixed_amount           -- 修正後請求額(税抜)
             ,SUM(xdir.prev_carryover_amt)        AS prev_carryover_amt     -- 前月繰越額(税抜)
             ,SUM(xdir.prev_carryover_tax)        AS prev_carryover_tax     -- 前月繰越額(消費税)
             ,SUM(xdir.deduction_amt)             AS deduction_amt          -- 控除額(税抜)
             ,SUM(xdir.deduction_tax)             AS deduction_tax          -- 控除額(消費税)
             ,SUM(xdir.payment_amt)               AS payment_amt            -- 支払額(税抜)
             ,SUM(xdir.payment_tax)               AS payment_tax            -- 支払額(消費税)
             ,SUM(xdir.difference_amt)            AS difference_amt         -- 調整差額(税抜)
             ,SUM(xdir.difference_tax)            AS difference_tax         -- 調整差額(消費税)
             ,SUM(xdir.next_carryover_amt)        AS next_carryover_amt     -- 翌月繰越額(税抜)
             ,SUM(xdir.next_carryover_tax)        AS next_carryover_tax     -- 翌月繰越額(消費税)
      FROM    xxcok_deduction_item_recon    xdir      -- 商品別突合情報テーブル
      WHERE   xdir.recon_slip_num  =  iv_recon_slip_num
      GROUP BY  xdir.deduction_chain_code
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 控除消込明細情報(問屋未収)登録
    <<dedu_recon_line_wp_ins_loop>>
    FOR dedu_item_recoe_rec IN dedu_item_recon_cur LOOP
      INSERT INTO xxcok_deduction_recon_line_wp(
        deduction_recon_line_id                     -- 控除消込明細ID
      , recon_slip_num                              -- 支払伝票番号
      , recon_line_status                           -- 入力ステータス
      , deduction_chain_code                        -- 控除用チェーンコード
      , billing_amount                              -- 請求額(税抜)
      , fixed_amount                                -- 修正後請求額(税抜)
      , prev_carryover_amt                          -- 前月繰越額(税抜)
      , prev_carryover_tax                          -- 前月繰越額(消費税)
      , deduction_amt                               -- 控除額(税抜)
      , deduction_tax                               -- 控除額(消費税)
      , carryover_pay_off_flg                       -- 繰越額全額精算フラグ
      , payment_amt                                 -- 支払額(税抜)
      , payment_tax                                 -- 支払額(消費税)
      , difference_amt                              -- 調整差額(税抜)
      , difference_tax                              -- 調整差額(消費税)
      , next_carryover_amt                          -- 翌月繰越額(税抜)
      , next_carryover_tax                          -- 翌月繰越額(消費税)
      , created_by                                  -- 作成者
      , creation_date                               -- 作成日
      , last_updated_by                             -- 最終更新者
      , last_update_date                            -- 最終更新日
      , last_update_login                           -- 最終更新ログイン
      , request_id                                  -- 要求ID
      , program_application_id                      -- コンカレント・プログラム･アプリケーションID
      , program_id                                  -- コンカレント･プログラムID
      , program_update_date                         -- プログラム更新日
      )
      VALUES(
        xxcok_deduction_recon_line_s01.nextval      -- 控除消込明細ID
      , iv_recon_slip_num                           -- 支払伝票番号
      , cv_recon_status                             -- 入力ステータス
      , dedu_item_recoe_rec.deduction_chain_code    -- 控除用チェーンコード
      , dedu_item_recoe_rec.billing_amount          -- 請求額(税抜)
      , dedu_item_recoe_rec.fixed_amount            -- 修正後請求額(税抜)
      , dedu_item_recoe_rec.prev_carryover_amt      -- 前月繰越額(税抜)
      , dedu_item_recoe_rec.prev_carryover_tax      -- 前月繰越額(消費税)
      , dedu_item_recoe_rec.deduction_amt           -- 控除額(税抜)
      , dedu_item_recoe_rec.deduction_tax           -- 控除額(消費税)
      , cv_status_n                                 -- 繰越額全額精算フラグ
      , dedu_item_recoe_rec.payment_amt             -- 支払額(税抜)
      , dedu_item_recoe_rec.payment_tax             -- 支払額(消費税)
      , dedu_item_recoe_rec.difference_amt          -- 調整差額(税抜)
      , dedu_item_recoe_rec.difference_tax          -- 調整差額(消費税)
      , dedu_item_recoe_rec.next_carryover_amt      -- 翌月繰越額(税抜)
      , dedu_item_recoe_rec.next_carryover_tax      -- 翌月繰越額(消費税)
      , cn_created_by                               -- 作成者
      , SYSDATE                                     -- 作成日
      , cn_last_updated_by                          -- 最終更新者
      , SYSDATE                                     -- 最終更新日
      , cn_last_update_login                        -- 最終更新ログイン
      , cn_request_id                               -- 要求ID
      , cn_program_application_id                   -- コンカレント・プログラム･アプリケーションID
      , cn_program_id                               -- コンカレント･プログラムID
      , SYSDATE                                     -- プログラム更新日
      )
      ;
--
    END LOOP dedu_recon_line_wp_ins_loop;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_recon_line_wp;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_item_recon
   * Description      : 商品別突合情報作成(A-4)
   **********************************************************************************/
  PROCEDURE insert_dedu_item_recon(
    iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,iv_recon_slip_num               IN     VARCHAR2          -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_item_recon'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_demand_unit_price      NUMBER;               -- 請求単価
    ln_demand_adj_amt         NUMBER;               -- 請求差額
    ln_dedu_quantity          NUMBER;               -- 控除数量
    ln_dedu_unit_price        NUMBER;               -- 控除単価
--
    ln_item_id                NUMBER DEFAULT NULL;  -- 品目ID
    ln_orga_id                NUMBER DEFAULT NULL;  -- 在庫組織ID
    ln_content                NUMBER;               -- 入数
--
    -- *** ローカル・カーソル ***
    -- 突合情報作成
    CURSOR dedu_item_recon_inline_cur
    IS
      SELECT
              xdir_inline.deduction_chain_code              AS  deduction_chain_code                -- 控除用チェーンコード
            , xdir_inline.item_code                         AS  item_code                           -- 品目コード
            , xrtrv.tax_rate                                AS  tax_rate                            -- 消費税率
            , xrtrv.tax_class_suppliers_outside             AS  tax_code                            -- 消費税コード
            , MAX(xdir_inline.demand_unit_type)             AS  demand_unit_type                    -- 請求単位
            , SUM(xdir_inline.demand_qty)                   AS  demand_qty                          -- 請求数量
            , SUM(xdir_inline.detail_amount)                AS  detail_amount                       -- 請求単価×請求数量
            , SUM(xdir_inline.demand_amt)                   AS  demand_amt                          -- 請求額
            , SUM(xdir_inline.prev_carryover_amt)           AS  prev_carryover_amt                  -- 前月繰越額
            , SUM(xdir_inline.prev_carryover_tax)           AS  prev_carryover_tax                  -- 前月繰越消費税額
            , MAX(xdir_inline.deduction_uom_code)           AS  deduction_uom_code                  -- 控除単位
            , SUM(xdir_inline.deduction_quantity)           AS  deduction_quantity                  -- 控除数量
            , SUM(xdir_inline.deduction_amt)                AS  deduction_amt                       -- 控除額
            , SUM(xdir_inline.deduction_030)                AS  deduction_030                       -- 控除額(通常)
            , SUM(xdir_inline.deduction_040)                AS  deduction_040                       -- 控除額(拡売)
            , SUM(xdir_inline.deduction_tax)                AS  deduction_tax                       -- 控除消費税額
      FROM    xxcos_reduced_tax_rate_v                      xrtrv                                   -- 品目別消費税率view
            , (
                -- ■ 問屋請求書 ■
                SELECT
                        xwbl.sales_outlets_code             AS  deduction_chain_code                -- 控除用チェーンコード
                      , xwbl.item_code                      AS  item_code                           -- 品目コード
                      , DECODE( xwbl.demand_unit_type, cv_one, cv_hon, cv_two, cv_cs, cv_three, cv_bl )
                                                            AS  demand_unit_type                    -- 請求単位
                      , DECODE(xwbl.expansion_sales_type, cv_one, cn_zero, xwbl.demand_qty)
                                                            AS  demand_qty                          -- 請求数量
                      , xwbl.demand_unit_price * xwbl.demand_qty
                                                            AS  detail_amount                       -- 請求単価×請求数量
                      , xwbl.demand_amt                     AS  demand_amt                          -- 請求額
                      , cn_zero                             AS  prev_carryover_amt                  -- 前月繰越額
                      , cn_zero                             AS  prev_carryover_tax                  -- 前月繰越消費税額
                      , NULL                                AS  deduction_uom_code                  -- 控除単位
                      , cn_zero                             AS  deduction_quantity                  -- 控除数量
                      , cn_zero                             AS  deduction_amt                       -- 控除額
                      , cn_zero                             AS  deduction_030                       -- 控除額(通常)
                      , cn_zero                             AS  deduction_040                       -- 控除額(拡売)
                      , cn_zero                             AS  deduction_tax                       -- 控除消費税額
                FROM    xxcok_wholesale_bill_line           xwbl                                    -- 問屋請求書明細テーブル
                WHERE   xwbl.recon_slip_num                 =   iv_recon_slip_num
                AND     xwbl.demand_unit_type               IN  ( cv_one, cv_two, cv_three )
                UNION ALL
                -- ■ 前月繰越 ■
                SELECT
                        NVL(xca.intro_chain_code2,xsd.deduction_chain_code)
                                                            AS  deduction_chain_code                -- 控除用チェーンコード
                      , xsd.item_code                       AS  item_code                           -- 品目コード
                      , NULL                                AS  demand_unit_type                    -- 請求単位
                      , cn_zero                             AS  demand_qty                          -- 請求数量
                      , cn_zero                             AS  detail_amount                       -- 請求単価×請求数量
                      , cn_zero                             AS  demand_amt                          -- 請求額
                      , xsd.deduction_amount * -1           AS  prev_carryover_amt                  -- 前月繰越額
                      , xsd.deduction_tax_amount * -1       AS  prev_carryover_tax                  -- 前月繰越消費税額
                      , msib.primary_uom_code               AS  deduction_uom_code                  -- 控除単位
                      , cn_zero                             AS  deduction_quantity                  -- 控除数量
                      , cn_zero                             AS  deduction_amt                       -- 控除額
                      , cn_zero                             AS  deduction_030                       -- 控除額(通常)
                      , cn_zero                             AS  deduction_040                       -- 控除額(拡売)
                      , cn_zero                             AS  deduction_tax                       -- 控除消費税額
                FROM    xxcok_sales_deduction               xsd                                     -- 販売控除情報
                      , fnd_lookup_values                   flv                                     -- データ種類
                      , xxcmm_cust_accounts                 xca                                     -- 顧客追加情報
                      , mtl_system_items_b                  msib                                    -- Disc品目マスタ
                WHERE   xsd.carry_payment_slip_num          =   iv_recon_slip_num
                AND     flv.lookup_type                     =   cv_deduction_data_type
                AND     flv.lookup_code                     =   xsd.data_type
                AND     flv.language                        =   ct_lang
                AND     flv.enabled_flag                    =   cv_enable
                AND     flv.attribute2                      IN  ( cv_condition_type_ws_fix,cv_condition_type_ws_add )
                AND     xsd.source_category                 =   cv_o
                AND     xca.customer_code(+)                =   xsd.customer_code_to
                AND     msib.segment1                       =   xsd.item_code
                AND     msib.organization_id                =   xxcoi_common_pkg.get_organization_id(gv_organization_code)
                UNION ALL
                -- ■ 販売控除 ■
                SELECT
                        NVL(xca.intro_chain_code2,xsd.deduction_chain_code)
                                                            AS  deduction_chain_code                -- 控除用チェーンコード
                      , xsd.item_code                       AS  item_code                           -- 品目コード
                      , NULL                                AS  demand_unit_type                    -- 請求単位
                      , cn_zero                             AS  demand_qty                          -- 請求数量
                      , cn_zero                             AS  detail_amount                       -- 請求単価×請求数量
                      , cn_zero                             AS  demand_amt                          -- 請求額
                      , cn_zero                             AS  prev_carryover_amt                  -- 前月繰越額
                      , cn_zero                             AS  prev_carryover_tax                  -- 前月繰越消費税額
                      , msib.primary_uom_code               AS  deduction_uom_code                  -- 控除単位
                      , CASE
                          WHEN flv.attribute2 = cv_condition_type_ws_fix THEN
                            xxcok_common_pkg.get_uom_conversion_qty_f(
                             xsd.item_code,
                             xsd.deduction_uom_code,
                             xsd.deduction_quantity
                             )
                          WHEN flv.attribute2 = cv_condition_type_ws_add THEN
                            cn_zero
                        END                                 AS  deduction_quantity                  -- 控除数量
                      , xsd.deduction_amount                AS  deduction_amt                       -- 控除額
                      , CASE
                          WHEN flv.attribute2 = cv_condition_type_ws_fix THEN
                            xsd.deduction_amount
                          WHEN flv.attribute2 = cv_condition_type_ws_add THEN
                            cn_zero
                        END                                 AS  deduction_030                       -- 控除額(通常)
                      , CASE
                          WHEN flv.attribute2 = cv_condition_type_ws_fix THEN
                            cn_zero
                          WHEN flv.attribute2 = cv_condition_type_ws_add THEN
                            xsd.deduction_amount
                        END                                 AS  deduction_040                       -- 控除額(拡売)
                      , xsd.deduction_tax_amount            AS  deduction_tax                       -- 控除消費税額
                FROM    xxcok_sales_deduction               xsd                                     -- 販売控除情報
                      , fnd_lookup_values                   flv                                     -- データ種類
                      , xxcmm_cust_accounts                 xca                                     -- 顧客追加情報
                      , mtl_system_items_b                  msib                                    -- Disc品目マスタ
                WHERE   xsd.carry_payment_slip_num          =   iv_recon_slip_num
                AND     flv.lookup_type                     =   cv_deduction_data_type
                AND     flv.lookup_code                     =   xsd.data_type
                AND     flv.language                        =   ct_lang
                AND     flv.enabled_flag                    =   cv_enable
                AND     flv.attribute2                      IN  ( cv_condition_type_ws_fix,cv_condition_type_ws_add )
                AND     xsd.source_category                 <>  cv_o
                AND     xca.customer_code(+)                =   xsd.customer_code_to
                AND     msib.segment1                       =   xsd.item_code
                AND     msib.organization_id                =   xxcoi_common_pkg.get_organization_id(gv_organization_code)
              )                                             xdir_inline
      WHERE   xrtrv.item_code                               =   xdir_inline.item_code
      AND     TRUNC(SYSDATE)                                BETWEEN xrtrv.start_date_histories  AND xrtrv.end_date_histories
      GROUP BY  xdir_inline.deduction_chain_code
              , xdir_inline.item_code
              , xrtrv.tax_rate
              , xrtrv.tax_class_suppliers_outside
      ORDER BY  xdir_inline.deduction_chain_code
              , xdir_inline.item_code
    ;
--
    dedu_item_recon_inline_rec      dedu_item_recon_inline_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN dedu_item_recon_inline_cur;
    LOOP
    FETCH dedu_item_recon_inline_cur INTO dedu_item_recon_inline_rec;
    EXIT WHEN dedu_item_recon_inline_cur%NOTFOUND;
--
      -- 請求単価
      IF  dedu_item_recon_inline_rec.demand_qty !=  0 THEN
        ln_demand_unit_price  :=  TRUNC( dedu_item_recon_inline_rec.detail_amount / dedu_item_recon_inline_rec.demand_qty, 2);
      ELSE
        ln_demand_unit_price  :=  0;
      END IF;
--
      -- 請求差額
      ln_demand_adj_amt :=  dedu_item_recon_inline_rec.demand_amt - TRUNC(ln_demand_unit_price * dedu_item_recon_inline_rec.demand_qty);
--
      -- 控除数量
      -- 請求単位がNULL以外の場合
      IF dedu_item_recon_inline_rec.demand_unit_type IS NOT NULL AND dedu_item_recon_inline_rec.deduction_uom_code IS NOT NULL THEN
           xxcos_common_pkg.get_uom_cnv(
                                          iv_before_uom_code      => dedu_item_recon_inline_rec.deduction_uom_code, -- 換算前単位コード
                                          in_before_quantity      => dedu_item_recon_inline_rec.deduction_quantity, -- 換算前数量
                                          iov_item_code           => dedu_item_recon_inline_rec.item_code,          -- 品目コード
                                          iov_organization_code   => gv_organization_code,                          -- 在庫組織コード
                                          ion_inventory_item_id   => ln_item_id,                                    -- 品目ID
                                          ion_organization_id     => ln_orga_id,                                    -- 在庫組織ID
                                          iov_after_uom_code      => dedu_item_recon_inline_rec.demand_unit_type,   -- 換算後単位コード
                                          on_after_quantity       => ln_dedu_quantity,                              -- 換算後数量
                                          on_content              => ln_content,                                    -- 入数
                                          ov_errbuf               => lv_errbuf,                                     -- エラー・メッセージエラー       #固定#
                                          ov_retcode              => lv_retcode,                                    -- リターン・コード               #固定#
                                          ov_errmsg               => lv_errmsg                                      -- ユーザー・エラー・メッセージ   #固定#
                                    );
      -- 請求単位もしくは控除単位がNULLの場合(請求なし/控除なし)
      ELSE
        ln_dedu_quantity  := dedu_item_recon_inline_rec.deduction_quantity;
      END IF;
      ln_dedu_quantity  :=  ROUND(ln_dedu_quantity,2);
--
      -- 控除単価
      IF  ln_dedu_quantity  !=  0 THEN
        ln_dedu_unit_price  :=  TRUNC( dedu_item_recon_inline_rec.deduction_amt / ln_dedu_quantity, 2);
      ELSE
        ln_dedu_unit_price  :=  0;
      END IF;
--
      -- 商品別突合情報の登録
      INSERT INTO xxcok_deduction_item_recon(
        deduction_item_recon_id         -- 商品別突合情報ID
      , recon_slip_num                  -- 支払伝票番号
      , deduction_chain_code            -- 控除用チェーンコード
      , item_code                       -- 品目コード
      , tax_code                        -- 消費税コード
      , tax_rate                        -- 税率
      , uom_code                        -- 単位
      , billing_quantity                -- 請求数量
      , billing_unit_price              -- 請求単価
      , billing_adj_amount              -- 請求差額
      , billing_amount                  -- 請求額(税抜)
      , fixed_quantity                  -- 修正後請求数量
      , fixed_unit_price                -- 修正後請求単価
      , fixed_adj_amount                -- 修正後請求差額
      , fixed_amount                    -- 修正後請求額(税抜)
      , prev_carryover_amt              -- 前月繰越額(税抜)
      , prev_carryover_tax              -- 前月繰越額(消費税)
      , deduction_quantity              -- 控除数量
      , deduction_unit_price            -- 控除単価
      , deduction_amt                   -- 控除額(税抜)
      , deduction_030                   -- 控除額(通常)
      , deduction_040                   -- 控除額(拡売)
      , deduction_tax                   -- 控除額(消費税)
      , payment_amt                     -- 支払額(税抜)
      , payment_tax                     -- 支払額(消費税)
      , difference_amt                  -- 調整差額(税抜)
      , difference_tax                  -- 調整差額(消費税)
      , next_carryover_amt              -- 翌月繰越額(税抜)
      , next_carryover_tax              -- 翌月繰越額(消費税)
      , differences                     -- 差異情報
      , created_by                      -- 作成者
      , creation_date                   -- 作成日
      , last_updated_by                 -- 最終更新者
      , last_update_date                -- 最終更新日
      , last_update_login               -- 最終更新ログイン
      , request_id                      -- 要求ID
      , program_application_id          -- コンカレント・プログラム･アプリケーションID
      , program_id                      -- コンカレント･プログラムID
      , program_update_date             -- プログラム更新日
      )
      VALUES(
        xxcok_deduction_item_recon_s01.nextval              -- 商品別突合情報ID
      , iv_recon_slip_num                                   -- 支払伝票番号
      , dedu_item_recon_inline_rec.deduction_chain_code     -- 控除用チェーンコード
      , dedu_item_recon_inline_rec.item_code                -- 品目コード
      , dedu_item_recon_inline_rec.tax_code                 -- 消費税コード
      , dedu_item_recon_inline_rec.tax_rate                 -- 税率
      , NVL( dedu_item_recon_inline_rec.demand_unit_type, dedu_item_recon_inline_rec.deduction_uom_code )
                                                            -- 単位
      , dedu_item_recon_inline_rec.demand_qty               -- 請求数量
      , ln_demand_unit_price                                -- 請求単価
      , ln_demand_adj_amt                                   -- 請求差額
      , dedu_item_recon_inline_rec.demand_amt               -- 請求額(税抜)
      , dedu_item_recon_inline_rec.demand_qty               -- 修正後請求数量
      , ln_demand_unit_price                                -- 修正後請求単価
      , ln_demand_adj_amt                                   -- 修正後請求差額
      , dedu_item_recon_inline_rec.demand_amt               -- 修正後請求額(税抜)
      , dedu_item_recon_inline_rec.prev_carryover_amt       -- 前月繰越額(税抜)
      , dedu_item_recon_inline_rec.prev_carryover_tax       -- 前月繰越額(消費税)
      , ln_dedu_quantity                                    -- 控除数量
      , ln_dedu_unit_price                                  -- 控除単価
      , dedu_item_recon_inline_rec.deduction_amt            -- 控除額(税抜)
      , dedu_item_recon_inline_rec.deduction_030            -- 控除額(通常)
      , dedu_item_recon_inline_rec.deduction_040            -- 控除額(拡売)
      , dedu_item_recon_inline_rec.deduction_tax            -- 控除額(消費税)
      , dedu_item_recon_inline_rec.demand_amt               -- 支払額(税抜)
      , ROUND(dedu_item_recon_inline_rec.demand_amt * dedu_item_recon_inline_rec.tax_rate / 100)
                                                            -- 支払額(消費税)
      , dedu_item_recon_inline_rec.deduction_amt - dedu_item_recon_inline_rec.demand_amt
                                                            -- 調整差額(税抜)
      , dedu_item_recon_inline_rec.deduction_tax - ROUND(dedu_item_recon_inline_rec.demand_amt * dedu_item_recon_inline_rec.tax_rate / 100)
                                                            -- 調整差額(消費税)
      , dedu_item_recon_inline_rec.prev_carryover_amt + dedu_item_recon_inline_rec.deduction_amt - dedu_item_recon_inline_rec.demand_amt
                                                            -- 翌月繰越額(税抜)
      , dedu_item_recon_inline_rec.prev_carryover_tax + dedu_item_recon_inline_rec.deduction_tax - ROUND(dedu_item_recon_inline_rec.demand_amt * dedu_item_recon_inline_rec.tax_rate / 100)
                                                            -- 翌月繰越額(消費税)
      , NULL                                                -- 差異情報
      , cn_created_by                                       -- 作成者
      , SYSDATE                                             -- 作成日
      , cn_last_updated_by                                  -- 最終更新者
      , SYSDATE                                             -- 最終更新日
      , cn_last_update_login                                -- 最終更新ログイン
      , cn_request_id                                       -- 要求ID
      , cn_program_application_id                           -- コンカレント・プログラム･アプリケーションID
      , cn_program_id                                       -- コンカレント･プログラムID
      , SYSDATE                                             -- プログラム更新日
      )
      ;
--
    END LOOP;
    CLOSE dedu_item_recon_inline_cur;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_item_recon;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_head
   * Description      : 控除消込ヘッダー作成(A-3)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_head(
    iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,id_recon_due_date               IN     DATE              -- 支払予定日
   ,id_gl_date                      IN     DATE              -- GL記帳日
   ,id_target_date_end              IN     DATE              -- 対象期間(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_invoice_number               IN     VARCHAR2          -- 問屋請求書番号
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_recon_slip_num               IN     VARCHAR2          -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_head'; -- プログラム名
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
  -- 
    INSERT INTO xxcok_deduction_recon_head(
      deduction_recon_head_id                     -- 控除消込ヘッダーID
    , recon_base_code                             -- 支払請求拠点
    , recon_slip_num                              -- 支払伝票番号 
    , recon_status                                -- 消込スタータス 
    , application_date                            -- 申請日
    , approval_date                               -- 承認日
    , cancellation_date                           -- 取消日
    , recon_due_date                              -- 支払予定日
    , gl_date                                     -- GL記帳日
    , target_date_end                             -- 対象期間(TO)
    , interface_div                               -- 連携先
    , payee_code                                  -- 支払先コード
    , corp_code                                   -- 企業コード
    , deduction_chain_code                        -- 控除用チェーンコード
    , cust_code                                   -- 顧客コード
    , invoice_number                              -- 問屋請求書番号
    , target_data_type                            -- 対象データ種類
    , applicant                                   -- 申請者
    , approver                                    -- 承認者
    , ap_ar_if_flag                               -- AP/AR連携フラグ
    , gl_if_flag                                  -- 消込GL連携フラグ
    , terms_name                                  -- 支払条件
    , invoice_date                                -- 請求書日付
    , created_by                                  -- 作成者
    , creation_date                               -- 作成日
    , last_updated_by                             -- 最終更新者
    , last_update_date                            -- 最終更新日
    , last_update_login                           -- 最終更新ログイン
    , request_id                                  -- 要求ID
    , program_application_id                      -- コンカレント・プログラム･アプリケーションID
    , program_id                                  -- コンカレント･プログラムID
    , program_update_date                         -- プログラム更新日
    )
    VALUES(
      xxcok_deduction_recon_head_s01.nextval      -- 控除消込ヘッダーID
    , iv_recon_base_code                          -- 支払請求拠点
    , iv_recon_slip_num                           -- 支払伝票番号 
    , cv_recon_status                             -- 消込スタータス 
    , NULL                                        -- 申請日
    , NULL                                        -- 承認日
    , NULL                                        -- 取消日
    , id_recon_due_date                           -- 支払予定日
    , id_gl_date                                  -- GL記帳日
    , id_target_date_end                          -- 対象期間(TO)
    , cv_wp                                       -- 連携先
    , iv_payee_code                               -- 支払先コード
    , NULL                                        -- 企業コード
    , NULL                                        -- 控除用チェーンコード
    , NULL                                        -- 顧客コード
    , iv_invoice_number                           -- 問屋請求書番号
    , iv_target_data_type                         -- 対象データ種類
    , xxcok_common_pkg.get_emp_code_f(cn_created_by)
                                                  -- 申請者
    , NULL                                        -- 承認者
    , cv_status_n                                 -- AP/AR連携フラグ
    , cv_status_n                                 -- 消込GL連携フラグ
    , iv_terms_name                               -- 支払条件
    , id_invoice_date                             -- 請求書日付
    , cn_created_by                               -- 作成者
    , SYSDATE                                     -- 作成日
    , cn_last_updated_by                          -- 最終更新者
    , SYSDATE                                     -- 最終更新日
    , cn_last_update_login                        -- 最終更新ログイン
    , cn_request_id                               -- 要求ID
    , cn_program_application_id                   -- コンカレント・プログラム･アプリケーションID
    , cn_program_id                               -- コンカレント･プログラムID
    , SYSDATE                                     -- プログラム更新日
    );
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_recon_head;
--
  /**********************************************************************************
   * Procedure Name   : sales_dedu_get
   * Description      : 販売控除データ抽出(A-2)
   **********************************************************************************/
  PROCEDURE sales_dedu_get(
    iv_recon_base_code              IN     VARCHAR2   -- 支払請求拠点
   ,id_recon_due_date               IN     DATE       -- 支払予定日
   ,id_gl_date                      IN     DATE       -- GL記帳日
   ,od_target_date_end              OUT    DATE       -- 対象期間(TO)
   ,iv_payee_code                   IN     VARCHAR2   -- 支払先コード
   ,iv_invoice_number               IN     VARCHAR2   -- 問屋請求書番号
   ,iv_target_data_type             IN     VARCHAR2   -- 対象データ種類
   ,iv_recon_slip_num               IN     VARCHAR2   -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2   -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_dedu_get'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    result_sales_dedu_count             NUMBER;
    result_whole_bill_line_count        NUMBER;
--
    -- *** ローカルカーソル ***
    -- 問屋請求書明細更新
    CURSOR  l_recon_wholesale_bill_up_cur
    IS
      SELECT  xwbl.wholesale_bill_detail_id AS  wholesale_bill_detail_id        -- 問屋請求書明細ID
            , xwbl.selling_date             AS  target_date_end                 -- 売上対象年月日
      FROM    xxcok_wholesale_bill_line     xwbl
      WHERE   xwbl.bill_no                  =   iv_invoice_number
      AND     xwbl.recon_slip_num           IS  NULL
      AND     xwbl.status                   IS  NULL
      AND     xwbl.wholesale_bill_header_id IN
              (
              SELECT  xwbh.wholesale_bill_header_id
              FROM    xxcok_wholesale_bill_head xwbh
              WHERE   xwbh.base_code            =   iv_recon_base_code
              AND     xwbh.supplier_code        =   iv_payee_code
              AND     xwbh.expect_payment_date  =   id_recon_due_date
              )
      FOR UPDATE  NOWAIT;
--
    -- 販売控除情報
    CURSOR l_recon_slip_num_up_cur
    IS
      WITH 
        target_data_type  AS
        ( SELECT  /*+ MATERIALIZED */
                  flvd.lookup_code  AS  lookup_code
          FROM    fnd_lookup_values flvd,                 -- 控除データ種類
                  fnd_lookup_values flvt                  -- 対象データ種類
          WHERE   flvt.lookup_type  =     cv_target_data_type
          AND     flvt.description  =     iv_target_data_type
          AND     flvt.language     =     ct_lang
          AND     flvt.enabled_flag =     cv_enable
          AND     flvd.lookup_type  =     cv_deduction_data_type
          AND     flvd.lookup_code  LIKE  flvt.attribute1
          AND     flvd.language     =     ct_lang
          AND     flvd.enabled_flag =     cv_enable
          AND     flvd.attribute3   =     cv_ap
          UNION ALL
          SELECT  flvd.lookup_code  AS  lookup_code
          FROM    fnd_lookup_values flvd
          WHERE   flvd.lookup_type  =     cv_deduction_data_type
          AND     flvd.language     =     ct_lang
          AND     flvd.enabled_flag =     cv_enable
          AND     flvd.attribute3   =     cv_wp                   )
      SELECT  xsd.sales_deduction_id
      FROM    xxcok_sales_deduction     xsd
      WHERE   xsd.sales_deduction_id    IN
              ( SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IN
                        ( SELECT  xca.customer_code
                          FROM    xxcmm_cust_accounts         xca ,
                                  xxcok_wholesale_bill_line   xwbl
                          WHERE   xwbl.recon_slip_num         = iv_recon_slip_num
                          AND     xca.intro_chain_code2       = xwbl.sales_outlets_code )
                AND     xsd.carry_payment_slip_num  IS  NULL
                AND     xsd.record_date             <=  od_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n
                UNION ALL
                SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IS  NULL
                AND     xsd.deduction_chain_code    IN
                        ( SELECT  xwbl.sales_outlets_code
                          FROM    xxcok_wholesale_bill_line   xwbl
                          WHERE   xwbl.recon_slip_num         = iv_recon_slip_num )
                AND     xsd.carry_payment_slip_num  IS  NULL
                AND     xsd.record_date             <=  od_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n                                           )
      FOR UPDATE  NOWAIT;
--
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数を初期化
    result_whole_bill_line_count := 0;
--
    -- 問屋請求書明細更新
    FOR recon_wholesale_bill_up_rec IN l_recon_wholesale_bill_up_cur LOOP
      UPDATE  xxcok_wholesale_bill_line     xwbl
      SET     xwbl.recon_slip_num           = iv_recon_slip_num         ,
              xwbl.last_updated_by          = cn_last_updated_by        ,
              xwbl.last_update_date         = SYSDATE                   ,
              xwbl.last_update_login        = cn_last_update_login      ,
              xwbl.request_id               = cn_request_id             ,
              xwbl.program_application_id   = cn_program_application_id ,
              xwbl.program_id               = cn_program_id             ,
              xwbl.program_update_date      = SYSDATE
      WHERE   xwbl.wholesale_bill_detail_id = recon_wholesale_bill_up_rec.wholesale_bill_detail_id
      ;
      od_target_date_end  :=  recon_wholesale_bill_up_rec.target_date_end;
      -- 実行結果件数を取得
      result_whole_bill_line_count := result_whole_bill_line_count + 1;
    END LOOP;
--
  -- 対象件数が０件の場合終了処理
    IF result_whole_bill_line_count = 0 THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_data_get_msg  -- 対象データなしエラーメッセージ
                   );
      RAISE global_api_warn_expt;
    END IF;
--
    -- 販売控除情報更新
    FOR recon_slip_num_up_rec IN l_recon_slip_num_up_cur LOOP
      UPDATE  xxcok_sales_deduction         xsd
      SET     xsd.recon_slip_num            = CASE WHEN xsd.recon_slip_num IS NULL THEN
                                                  iv_recon_slip_num
                                                ELSE
                                                  xsd.recon_slip_num
                                                END                     ,
              xsd.carry_payment_slip_num    = iv_recon_slip_num         ,
              xsd.last_updated_by           = cn_last_updated_by        ,
              xsd.last_update_date          = SYSDATE                   ,
              xsd.last_update_login         = cn_last_update_login      ,
              xsd.request_id                = cn_request_id             ,
              xsd.program_application_id    = cn_program_application_id ,
              xsd.program_id                = cn_program_id             ,
              xsd.program_update_date       = SYSDATE
      WHERE   xsd.sales_deduction_id        = recon_slip_num_up_rec.sales_deduction_id
      ;
    END LOOP;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      -- ロックエラーメッセージ
      ov_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cok
                                            ,cv_rock_err_msg
                                             );
      ov_errbuf :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END sales_dedu_get;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理プロシージャ(A-1)
   **********************************************************************************/
  PROCEDURE init(
    ov_recon_slip_num     OUT  VARCHAR2   --   支払伝票番号
   ,ov_errbuf             OUT  VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT  VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT  VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
--
    -- *** ローカル変数 ***
      lv_recon_slip_num         VARCHAR2(20);    -- 支払伝票番号
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
      -- プロファイル(在庫組織コード)
    gv_organization_code := FND_PROFILE.VALUE( cv_profile_organi_code );
    IF( gv_organization_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_msg_kbn_cok
                    , iv_name                 => cv_pro_get_err_msg
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_organi_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- 支払伝票番号取得
    lv_recon_slip_num := xxcok_deduction_slip_num_s01.nextval;
    --
    ov_recon_slip_num := TO_CHAR(lv_recon_slip_num,'FM0000000000');
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,id_recon_due_date               IN     DATE              -- 支払予定日
   ,id_gl_date                      IN     DATE              -- GL記帳日
   ,od_target_date_end              OUT    DATE              -- 対象期間(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_invoice_number               IN     VARCHAR2          -- 問屋請求書番号
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
   ,ov_recon_slip_num               OUT    VARCHAR2          -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
--
    -- *** ローカル変数 ***
    lv_recon_slip_num  VARCHAR2(20); -- 支払伝票番号
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
    gn_target_cnt        := 0; -- 対象件数
    gn_normal_cnt        := 0; -- 正常件数
    gn_error_cnt         := 0; -- エラー件数
--
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
       lv_recon_slip_num -- 支払伝票番号ID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    ov_recon_slip_num := lv_recon_slip_num;
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．販売控除データ抽出
    -- ============================================
    sales_dedu_get(
       iv_recon_base_code     -- 支払請求拠点
      ,id_recon_due_date      -- 支払予定日
      ,id_gl_date             -- GL記帳日
      ,od_target_date_end     -- 対象期間(TO)
      ,iv_payee_code          -- 支払先コード
      ,iv_invoice_number      -- 問屋請求書番号
      ,iv_target_data_type    -- 対象データ種類
      ,lv_recon_slip_num      -- 支払伝票番号
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3． 控除消込ヘッダー作成
    -- ============================================
    insert_dedu_recon_head(
       iv_recon_base_code     -- 支払請求拠点
      ,id_recon_due_date      -- 支払予定日
      ,id_gl_date             -- GL記帳日
      ,od_target_date_end     -- 対象期間(TO)
      ,iv_payee_code          -- 支払先コード
      ,iv_invoice_number      -- 問屋請求書番号
      ,iv_target_data_type    -- 対象データ種類
      ,iv_terms_name          -- 支払条件
      ,id_invoice_date        -- 請求書日付
      ,lv_recon_slip_num      -- 支払伝票番号
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4．商品別突合情報作成
    -- ============================================
    insert_dedu_item_recon(
       iv_recon_base_code  -- 支払請求拠点
      ,lv_recon_slip_num   -- 支払伝票番号
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5．控除消込明細情報(問屋未収)作成
    -- ============================================
    insert_dedu_recon_line_wp(
       lv_recon_slip_num   -- 支払伝票番号
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6．控除No別消込情報作成
    -- ============================================
    insert_dedu_num_recon(
       lv_recon_slip_num   -- 支払伝票番号
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7．控除消込明細情報(AP申請)作成
    -- ============================================
    insert_dedu_recon_line_ap(
       lv_recon_slip_num   -- 支払伝票番号
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,ov_recon_slip_num               OUT    VARCHAR2          -- 支払伝票番号
   ,iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,id_recon_due_date               IN     DATE              -- 支払予定日
   ,id_gl_date                      IN     DATE              -- GL記帳日
   ,od_target_date_end              OUT    DATE              -- 対象期間(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_invoice_number               IN     VARCHAR2          -- 問屋請求書番号
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  :=  'main';             -- プログラム名
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)   :=  'XXCCP';            -- アドオン：共通・IF領域
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    lv_recon_slip_num  VARCHAR2(20);    -- 支払伝票番号
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_recon_base_code        -- 支払請求拠点
      ,id_recon_due_date         -- 支払予定日
      ,id_gl_date                -- GL記帳日
      ,od_target_date_end        -- 対象期間(TO)
      ,iv_payee_code             -- 支払先コード
      ,iv_invoice_number         -- 問屋請求書番号
      ,iv_terms_name             -- 支払条件
      ,id_invoice_date           -- 請求書日付
      ,iv_target_data_type       -- 対象データ種類
      ,lv_recon_slip_num         -- 支払伝票番号
      ,lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                -- リターン・コード             --# 固定 #
      ,lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- A-1で採番した支払い伝票番号を反映
    ov_recon_slip_num := lv_recon_slip_num;
    -- 終了ステータスを反映
    retcode           := lv_retcode;
--
    --  正常終了以外の場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      errbuf := lv_errbuf;
      -- ロールバックを発行
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
END XXCOK024A15C;
/
