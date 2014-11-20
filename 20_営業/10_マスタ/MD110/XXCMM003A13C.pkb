CREATE OR REPLACE PACKAGE BODY xxcmm003a13c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A13C(body)
 * Description      : このコンカレント処理は、２つの機能を持っています 。
 *                      （１）顧客移行・拠点分割による売上拠点の変更予約情報を、
 *                            適用開始日到来時に反映する。
 *                      （２）月末日に、前月売上拠点コードを更新する。
 * MD.050           : 有効拠点データ反映 MD050_CMM_003_A13
 * Version          : Issue3.3
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_xxcmm_cust_accounts     顧客追加情報テーブル予約拠点情報更新(A-3)
 *  prc_init                        初期処理(A-1)
 *  submain                         メイン処理プロシージャ(A-2:処理対象データ抽出)
 *                                    ・prc_init
 *                                    ・prc_upd_xxcmm_cust_accounts
 *  main                            コンカレント実行ファイル登録プロシージャ(A-5:終了処理)
 *                                    ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/13    1.0   SCS Okuyama      新規作成
 *  2009/05/21    1.1   Yutaka.Kuboshima 障害T1_1134の対応
 *  2009/12/22    1.2   Yutaka.Kuboshima 障害E_本稼動_00598の対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
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
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_bracket_f          CONSTANT VARCHAR2(1) := '[';
  cv_msg_bracket_t          CONSTANT VARCHAR2(1) := ']';
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
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt        EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt            EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  global_check_para_expt     EXCEPTION;     -- パラメータエラー
  global_check_lock_expt     EXCEPTION;     -- ロック取得エラー

  --
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';               -- アドオン：共通・IF領域
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';               -- アドオン：マスタ・マスタ領域
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A13C';        -- パッケージ名
  -- メッセージコード
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';    -- ｼｽﾃﾑｴﾗｰ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';    -- 対象データ無し
  cv_msg_xxcmm_00002        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00002';    -- プロファイル取得エラー
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';    -- ロックエラー
  cv_msg_xxcmm_00303        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00303';    -- データ更新エラー
  cv_msg_xxcmm_00333        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00333';    -- パラメータエラー
  -- メッセージトークン
  cv_tkn_ng_profile         CONSTANT VARCHAR2(10) := 'NG_PROFILE';          -- プロファイル名
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';            -- テーブル名
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';             -- 顧客コード
  cv_tkn_sale_base_code     CONSTANT VARCHAR2(12) := 'SALE_BASE_CD';        -- 売上拠点コード
  cv_tkn_para_date          CONSTANT VARCHAR2(9)  := 'PARA_DATE';           -- 処理日付（パラメータ）
  cv_tkn_proc_date          CONSTANT VARCHAR2(9)  := 'PROC_DATE';           -- 業務日付
  --
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '顧客追加情報';        -- XXCMM_CUST_ACCOUNTS
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- 日付フォーマット
  cv_month_fmt              CONSTANT VARCHAR2(6)  := 'YYYYMM';              -- 月フォーマット
  cv_profile_ctrl_cal       CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';  -- ｼｽﾃﾑ稼働日ｶﾚﾝﾀﾞｺｰﾄﾞ定義ﾌﾟﾛﾌｧｲﾙ
  cv_term_immediate         CONSTANT VARCHAR2(8)  := '00_00_00';            -- 支払条件名（即時）
  cv_lang_ja                CONSTANT VARCHAR2(2)  := 'JA';                  -- 言語（日本）
  cv_rec_status_active      CONSTANT VARCHAR2(1)  := 'A';                   -- EBSデータステータス（有効）
  cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';                   -- フラグ（Yes）
  cv_site_use_cd_bt         CONSTANT VARCHAR2(7)  := 'BILL_TO';             -- 使用目的コード（請求先）
  cv_para01_name            CONSTANT VARCHAR2(6)  := '処理日';              -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名01
  cv_sgl_space              CONSTANT VARCHAR2(1)  := CHR(32);               -- 半角スペース文字
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_cal_code           VARCHAR2(10);   -- システム稼働日カレンダコード値
  gv_para_proc_date     VARCHAR2(10);   -- 処理日
  gd_para_proc_date     DATE;           -- 処理日
-- 2009/05/21 Ver1.1 add start by Yutaka.Kuboshima
  gv_para_proc_month    VARCHAR2(6);    -- 処理日月(YYYYMM)
-- 2009/05/21 Ver1.1 add end by Yutaka.Kuboshima
  gd_next_proc_date     DATE;           -- 翌業務日付
  gv_now_proc_month     VARCHAR2(6);    -- 業務日付月(YYYYMM)
  gv_next_proc_month    VARCHAR2(6);    -- 翌業務日付月(YYYYMM)
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  --
  -- A-2.処理対象データ抽出カーソル
  --
  CURSOR  xxcmm003A13c_cur
  IS
    SELECT
      xcac.customer_code                  AS  customer_code,          -- 顧客コード
      xcac.sale_base_code                 AS  sale_base_code,         -- 売上拠点コード
      xcac.past_sale_base_code            AS  past_sale_base_code,    -- 前月売上拠点コード
      xcac.rsv_sale_base_code             AS  rsv_sale_base_code,     -- 予約売上拠点コード
      TRUNC(xcac.rsv_sale_base_act_date)  AS  rsv_sale_base_act_date, -- 予約売上拠点有効開始日
      xcac.ROWID                          AS  xcac_rowid,             -- レコードID（顧客追加情報）
      xcac.delivery_base_code             AS  delivery_base_code,     -- 納品拠点コード
      xcac.bill_base_code                 AS  bill_base_code,         -- 請求拠点コード
      xcac.receiv_base_code               AS  receiv_base_code,       -- 入金拠点コード
      TRUNC(xcac.past_final_tran_date)    AS  past_final_tran_date,   -- 前月最終取引日
      TRUNC(xcac.final_tran_date)         AS  final_tran_date,        -- 最終取引日
      xcac.past_customer_status           AS  past_customer_status,   -- 前月顧客ステータス
      hzpt.duns_number_c                  AS  customer_status,        -- 顧客ステータス
      ratt.name                           AS  term_name               -- 支払条件名
    FROM
      xxcmm_cust_accounts       xcac,   -- 顧客追加情報テーブル
      hz_cust_accounts          hzca,   -- 顧客マスタテーブル
      hz_parties                hzpt,   -- パーティテーブル
      hz_party_sites            hzps,   -- パーティサイトテーブル
-- 2009/12/22 Ver1.2 E_本稼動_00598 modify start by Yutaka.Kuboshima
-- 営業OUのみを対象とする
--      hz_cust_acct_sites_all    hzsa,   -- 顧客所在地テーブル
--      hz_cust_site_uses_all     hzsu,   -- 顧客使用目的テーブル
      hz_cust_acct_sites        hzsa,   -- 顧客所在地テーブル
      hz_cust_site_uses         hzsu,   -- 顧客使用目的テーブル
-- 2009/12/22 Ver1.2 E_本稼動_00598 modify end by Yutaka.Kuboshima
      ra_terms_tl               ratt    -- 支払条件テーブル
    WHERE
          xcac.customer_id              =   hzca.cust_account_id
      AND hzca.party_id                 =   hzpt.party_id
      AND hzpt.party_id                 =   hzps.party_id
      AND hzsa.cust_account_id          =   hzca.cust_account_id
      AND hzsa.party_site_id            =   hzps.party_site_id
      AND hzsu.cust_acct_site_id(+)     =   hzsa.cust_acct_site_id
      AND ratt.term_id(+)               =   hzsu.payment_term_id
      AND hzps.status                   =   cv_rec_status_active
-- 2009/12/22 Ver1.2 E_本稼動_00598 delete start by Yutaka.Kuboshima
-- 識別所在地フラグの条件は削除
--      AND hzps.identifying_address_flag =   cv_flag_yes
-- 2009/12/22 Ver1.2 E_本稼動_00598 delete end by Yutaka.Kuboshima
      AND hzsu.status(+)                =   cv_rec_status_active
      AND hzsu.site_use_code(+)         =   cv_site_use_cd_bt
      AND ratt.language(+)              =   cv_lang_ja
      AND (
                (xcac.rsv_sale_base_act_date <= gd_next_proc_date)
            OR  (
-- 2009/05/21 Ver1.1 modify start by Yutaka.Kuboshima
--                      (gv_now_proc_month <> gv_next_proc_month)
                      (gv_para_proc_month <> gv_next_proc_month)
-- 2009/05/21 Ver1.1 modify end by Yutaka.Kuboshima
                  AND
                      (
                              ((cv_sgl_space || xcac.past_sale_base_code)   <>  (cv_sgl_space || xcac.sale_base_code))
                          OR  ((cv_sgl_space || xcac.past_final_tran_date)  <>  (cv_sgl_space || xcac.final_tran_date))
                          OR  ((cv_sgl_space || xcac.past_customer_status)  <>  (cv_sgl_space || hzpt.duns_number_c))
                      )
                )
          )
    FOR UPDATE OF xcac.customer_id NOWAIT
    ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : 顧客追加情報テーブル予約拠点情報更新(A-3)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  xxcmm003A13c_cur%ROWTYPE,   -- 処理対象データレコード
    ov_errbuf     OUT VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_xxcmm_cust_accounts'; -- プログラム名
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
    lv_step       VARCHAR2(10);     -- ステップ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    lv_step := 'A-3.1';
    --
    -- 顧客追加情報テーブル予約拠点情報更新SQL文
    UPDATE
      -- 顧客追加情報
      xxcmm_cust_accounts         xcac
    SET
      -- 前月売上拠点コード
      xcac.past_sale_base_code    = (
                                      CASE  WHEN
                                              (
-- 2009/05/21 Ver1.1 modify start by Yutaka.Kuboshima
--                                                    (gv_now_proc_month <> gv_next_proc_month)
                                                    (gv_para_proc_month <> gv_next_proc_month)
-- 2009/05/21 Ver1.1 modify end by Yutaka.Kuboshima
                                                AND ((cv_sgl_space || iv_rec.past_sale_base_code)
                                                            <> (cv_sgl_space || iv_rec.sale_base_code))
                                              ) THEN
                                        iv_rec.sale_base_code
                                      ELSE
                                        iv_rec.past_sale_base_code
                                      END
                                    ),
      -- 売上拠点コード
      xcac.sale_base_code         = (
                                      CASE  WHEN
                                              (
                                                iv_rec.rsv_sale_base_act_date <= gd_next_proc_date
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.sale_base_code
                                      END
                                    ),
      -- 予約売上拠点コード
      xcac.rsv_sale_base_code     = (
                                      CASE  WHEN
                                              (
                                                iv_rec.rsv_sale_base_act_date <= gd_next_proc_date
                                              ) THEN
                                        NULL
                                      ELSE
                                        iv_rec.rsv_sale_base_code
                                      END
                                    ),
      -- 予約売上拠点有効開始日
      xcac.rsv_sale_base_act_date = (
                                      CASE  WHEN
                                              (
                                                iv_rec.rsv_sale_base_act_date <= gd_next_proc_date
                                              ) THEN
                                        NULL
                                      ELSE
                                        iv_rec.rsv_sale_base_act_date
                                      END
                                    ),
      -- 前月最終取引日
      xcac.past_final_tran_date   = (
                                      CASE  WHEN
                                              (
-- 2009/05/21 Ver1.1 modify start by Yutaka.Kuboshima
--                                                    (gv_now_proc_month <> gv_next_proc_month)
                                                    (gv_para_proc_month <> gv_next_proc_month)
-- 2009/05/21 Ver1.1 modify end by Yutaka.Kuboshima
                                                AND ((cv_sgl_space || iv_rec.past_final_tran_date)
                                                          <> (cv_sgl_space || iv_rec.final_tran_date))
                                              ) THEN
                                        iv_rec.final_tran_date
                                      ELSE
                                        iv_rec.past_final_tran_date
                                      END
                                    ),
      -- 前月顧客ステータス
      xcac.past_customer_status   = (
                                      CASE  WHEN
                                              (
-- 2009/05/21 Ver1.1 modify start by Yutaka.Kuboshima
--                                                    (gv_now_proc_month <> gv_next_proc_month)
                                                    (gv_para_proc_month <> gv_next_proc_month)
-- 2009/05/21 Ver1.1 modify end by Yutaka.Kuboshima
                                                AND ((cv_sgl_space || iv_rec.past_customer_status)
                                                            <> (cv_sgl_space || iv_rec.customer_status))
                                              ) THEN
                                        iv_rec.customer_status
                                      ELSE
                                        iv_rec.past_customer_status
                                      END
                                    ),
      -- 納品拠点コード
      xcac.delivery_base_code     = (
                                      CASE  WHEN
                                              (
                                                    (iv_rec.rsv_sale_base_act_date <= gd_next_proc_date)
                                                AND ((cv_sgl_space || iv_rec.term_name)
                                                                          = cv_sgl_space || cv_term_immediate)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.delivery_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.bill_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.receiv_base_code)
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.delivery_base_code
                                      END
                                    ),
      -- 請求拠点コード
      xcac.bill_base_code         = (
                                      CASE  WHEN
                                              (
                                                    (iv_rec.rsv_sale_base_act_date <= gd_next_proc_date)
                                                AND ((cv_sgl_space || iv_rec.term_name)
                                                                          = cv_sgl_space || cv_term_immediate)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.delivery_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.bill_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.receiv_base_code)
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.bill_base_code
                                      END
                                    ),
      -- 入金拠点コード
      xcac.receiv_base_code       = (
                                      CASE  WHEN
                                              (
                                                    (iv_rec.rsv_sale_base_act_date <= gd_next_proc_date)
                                                AND ((cv_sgl_space || iv_rec.term_name)
                                                                          = cv_sgl_space || cv_term_immediate)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.delivery_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.bill_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.receiv_base_code)
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.receiv_base_code
                                      END
                                    ),
      -- WHO
      xcac.last_updated_by        = cn_last_updated_by,         -- 最終更新者
      xcac.last_update_date       = cd_last_update_date,        -- 最終更新日
      xcac.last_update_login      = cn_last_update_login,       -- 最終更新ログイン
      xcac.request_id             = cn_request_id,              -- 要求ID
      xcac.program_application_id = cn_program_application_id,  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      xcac.program_id             = cn_program_id,              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      xcac.program_update_date    = cd_program_update_date      -- プログラム更新日
    WHERE
      xcac.rowid  = iv_rec.xcac_rowid                           -- レコードID（顧客追加）
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- メッセージセット
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00303,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,            -- トークンコード1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- トークン値1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- トークンコード2
                        iv_token_value2 =>  iv_rec.customer_code,       -- トークン値2
                        iv_token_name3  =>  cv_tkn_sale_base_code,      -- トークンコード3
                        iv_token_value3 =>  iv_rec.sale_base_code       -- トークン値3
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxccp_91003        -- メッセージコード
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- 処理ステータスセット
      ov_retcode  :=  cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_upd_xxcmm_cust_accounts;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE prc_init(
    iv_proc_date  IN  VARCHAR2,     --   処理日
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_init'; -- プログラム名
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
    lv_step             VARCHAR2(10);   -- ステップ
    lv_now_proc_date    VARCHAR2(10);   -- 業務日付（文字列）
    lv_proc_date        VARCHAR2(10);   -- パラメータ処理日
    ld_now_proc_date    DATE;           -- 業務日付
    ld_next_proc_date   DATE;           -- 翌業務日付
    lv_para_edit_buf    VARCHAR2(60);   -- 出力用ﾊﾟﾗﾒｰﾀ文字列編集領域
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    lv_step := 'A-1.1';
    --
    -- 業務日付取得
    --
    ld_now_proc_date    :=  xxccp_common_pkg2.get_process_date;
    IF (iv_proc_date IS NULL) THEN
      lv_proc_date      :=  TO_CHAR(TRUNC(ld_now_proc_date), cv_date_fmt);
    ELSE
      lv_proc_date      :=  SUBSTRB(iv_proc_date, 1, 10);
    END IF;
    --
    -- 業務日付月(YYYYMM)
    gv_now_proc_month   :=  TO_CHAR(ld_now_proc_date, cv_month_fmt);
    lv_step := 'A-1.2';
    --
    -- コンカレント・パラメータのログ出力
    -- 処理日
    lv_para_edit_buf  :=  cv_para01_name || cv_msg_part || cv_msg_bracket_f || lv_proc_date || cv_msg_bracket_t;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    --空行挿入
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --
    -- プロファイル値取得
    --
    lv_step := 'A-1.3';
    -- システム稼働日カレンダコード取得
    gv_cal_code := fnd_profile.value(cv_profile_ctrl_cal);
    IF (gv_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- アプリケーション短縮名
                      iv_name           =>  cv_msg_xxcmm_00002,   -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_ctrl_cal   -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- パラメータチェック（処理日）
    --
    lv_step := 'A-1.4';
    lv_now_proc_date  :=  TO_CHAR(ld_now_proc_date, cv_date_fmt);
    IF (TRIM(lv_proc_date) IS NOT NULL) THEN
      IF (lv_proc_date > lv_now_proc_date) THEN
        -- パラメータの「処理日」＞ 業務日付 である場合、エラー
        -- メッセージ取得
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_apl_name_cmm,      -- アプリケーション短縮名
                          iv_name         =>  cv_msg_xxcmm_00333,   -- メッセージコード
                          iv_token_name1  =>  cv_tkn_para_date,     -- トークンコード1
                          iv_token_value1 =>  lv_proc_date,         -- トークン値1
                          iv_token_name2  =>  cv_tkn_proc_date,     -- トークンコード2
                          iv_token_value2 =>  lv_now_proc_date      -- トークン値2
                        );
        -- パラメータエラー例外
        RAISE global_check_para_expt;
        --
      END IF;
    END IF;
    --
    -- 処理日をグローバル変数に格納
    --
    gv_para_proc_date :=  lv_proc_date;
    gd_para_proc_date :=  TO_DATE(lv_proc_date, cv_date_fmt);
-- 2009/05/21 Ver1.1 add start by Yutaka.Kuboshima
    gv_para_proc_month := TO_CHAR(gd_para_proc_date, cv_month_fmt);
-- 2009/05/21 Ver1.1 add end by Yutaka.Kuboshima
    --
    -- 翌業務日付取得
    --
    lv_step := 'A-1.5';
    ld_next_proc_date   :=  xxccp_common_pkg2.get_working_day(
                              gd_para_proc_date,
                              1,
                              gv_cal_code
                            );
    gd_next_proc_date   :=  TRUNC(ld_next_proc_date);
    -- 翌業務日付月(YYYYMM)
    gv_next_proc_month  :=  TO_CHAR(gd_next_proc_date, cv_month_fmt);
    --
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** パラメータエラー例外ハンドラ ***
    WHEN global_check_para_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- アプリケーション短縮名
                      iv_name         =>  cv_msg_xxccp_91003        -- メッセージコード
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_init;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date  IN  VARCHAR2,   --   コンカレント・パラメータ 処理日
    ov_errbuf     OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_step       VARCHAR2(10);     -- ステップ
--
    -- *** ローカル変数 ***
    lb_err_flg    BOOLEAN;          -- エラー有無
    ln_err_cnt    NUMBER;           -- エラー発生数（１顧客単位）
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    xxcmm003A13c_rec    xxcmm003A13c_cur%ROWTYPE;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
   -- エラー有無を初期化
   lb_err_flg := FALSE;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-1.初期化処理
    -- ===============================
    lv_step := 'A-1';
    prc_init(
      iv_proc_date, -- 処理日
      lv_errbuf,    -- エラー・メッセージ           --# 固定 #
      lv_retcode,   -- リターン・コード             --# 固定 #
      lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    -- A-2.処理対象データ抽出
    -- ===============================
    lv_step := 'A-2';
    OPEN  xxcmm003A13c_cur;
    --
    LOOP
      -- 処理対象データ・カーソルフェッチ
      FETCH xxcmm003A13c_cur INTO xxcmm003A13c_rec;
      EXIT WHEN xxcmm003A13c_cur%NOTFOUND;
      --
      gn_target_cnt := xxcmm003A13c_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      --
      -- ===============================
      -- A-3.顧客追加情報テーブル有効拠点情報更新
      -- ===============================
      lv_step := 'A-3';
      prc_upd_xxcmm_cust_accounts(
        xxcmm003A13c_rec,   -- カーソルレコード
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        lb_err_flg  :=  TRUE;
        ln_err_cnt  :=  1;
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg --ユーザーエラーメッセージ
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg --ユーザーエラーメッセージ
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errbuf --エラーメッセージ
        );
        --
        lv_errmsg := NULL;
        lv_errbuf := NULL;
        --
      END IF;
      --
      -- 成功件数、エラー件数のカウント
      IF (ln_err_cnt = 0) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt := gn_error_cnt + ln_err_cnt;
      END IF;
      --
    END LOOP;
    --
    CLOSE xxcmm003A13c_cur;
    --
    IF (lb_err_flg = FALSE) THEN
      -- 対象データなし時のメッセージ
      IF (gn_target_cnt = 0) THEN
        -- メッセージセット
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_apl_name_cmm,        -- アプリケーション短縮名
                          iv_name         =>  cv_msg_xxcmm_00001      -- メッセージコード
                        );
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg --パラメータなしメッセージ
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg --パラメータなしメッセージ
        );
      END IF;
    ELSE
      -- 更新エラーが発生している為、エラーをセット
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    -- *** パラメータエラー例外ハンドラ ***
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      -- カーソルクローズ
      IF xxcmm003A13c_cur%ISOPEN THEN
        CLOSE  xxcmm003A13c_cur;
      END IF;
      -- メッセージセット
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00008,     -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,        -- トークンコード1
                        iv_token_value1 =>  cv_tbl_nm_xcac          -- トークン値1
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- 処理ステータスセット
      ov_retcode  :=  cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF xxcmm003A13c_cur%ISOPEN THEN
        CLOSE xxcmm003A13c_cur;
      END IF;
      -- メッセージセット
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      -- 処理ステータスセット
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF xxcmm003A13c_cur%ISOPEN THEN
        CLOSE xxcmm003A13c_cur;
      END IF;
      -- メッセージセット
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- アプリケーション短縮名
                      iv_name         =>  cv_msg_xxccp_91003        -- メッセージコード
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- 処理ステータスセット
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
    errbuf        OUT VARCHAR2,     -- エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,     -- リターン・コード    --# 固定 #
    iv_proc_date  IN  VARCHAR2      -- コンカレント・パラメータ処理日付
  )
--
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
    --
    cv_log             CONSTANT VARCHAR2(100) := 'LOG';              -- ログ
    cv_output          CONSTANT VARCHAR2(100) := 'OUTPUT';           -- アウトプット
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
    ----------------------------------
    -- ログヘッダ出力
    ----------------------------------
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_log,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_proc_date, -- コンカレント・パラメータ処理日付
      lv_errbuf,    -- エラー・メッセージ           --# 固定 #
      lv_retcode,   -- リターン・コード             --# 固定 #
      lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      IF (LENGTHB(TRIM(lv_errmsg)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.output,
          buff   => LTRIM(lv_errmsg)   --ユーザー・エラーメッセージ
        );
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errmsg)   --ユーザー・エラーメッセージ
        );
      END IF;
      IF (LENGTHB(TRIM(lv_errbuf)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errbuf)   --エラーメッセージ
        );
      END IF;
    END IF;
    --空行挿入
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --空白行出力
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
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
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxcmm003a13c;
/
