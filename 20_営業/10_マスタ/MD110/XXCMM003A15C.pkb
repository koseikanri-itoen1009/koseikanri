CREATE OR REPLACE PACKAGE BODY xxcmm003a15c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A15C(body)
 * Description      : HHT側に顧客への最終取引日を連携するため、顧客マスタ上に最終取引日を
 *                    保持する必要があります。
 *                    当機能を日次で稼動させ、最新の最終取引日を自動更新します。
 *                    顧客の中止を行う判断として、最終取引日を参照して一定期間取引が
 *                    発生していない顧客を判断します。
 *                    （未取引客チェックリストに出力されます。）
 * MD.050           : 最終取引日更新 MD050_CMM_003_A15
 * Version          : Draft3A
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_hz_parties              顧客ステータス更新(A-6)
 *  prc_ins_xxcmm_cust_accounts     顧客追加情報テーブル登録(A-5)
 *  prc_upd_xxcmm_cust_accounts     顧客追加情報テーブル最終取引日更新(A-4)
 *  prc_init                        初期処理(A-1)
 *  submain                         メイン処理プロシージャ(A-2:処理対象データ抽出)
 *                                    ・prc_init
 *                                    ・prc_upd_xxcmm_cust_accounts
 *                                    ・prc_upd_hz_parties
 *  main                            コンカレント実行ファイル登録プロシージャ(A-7:終了処理)
 *                                    ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/03    1.0   SCS Okuyama      新規作成
 *  2009/02/27    1.1   Yutaka.Kuboshima 顧客ステータス更新処理を変更
 *  2009/05/27    1.2   Yutaka.Kuboshima 障害T1_0816,T1_0863の対応
 *  2009/08/31    1.3   Yutaka.Kuboshima 障害0001229の対応
 *  2009/12/18    1.4   Yutaka.Kuboshima 障害E_本稼動_00540の対応
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
  gv_out_msg              VARCHAR2(2000);
  gv_sep_msg              VARCHAR2(2000);
  gv_exec_user            VARCHAR2(100);
  gv_conc_name            VARCHAR2(30);
  gv_conc_status          VARCHAR2(30);
  gn_target_cnt           NUMBER;       -- 対象件数
  gn_normal_cnt           NUMBER;       -- 正常件数
  gn_error_cnt            NUMBER;       -- エラー件数
  gn_warn_cnt             NUMBER;       -- スキップ件数
  gn_xx_cust_acnt_upd_cnt NUMBER;       -- 顧客追加情報テーブル更新件数
  gn_hz_pts_upd_cnt       NUMBER;       -- パーティテーブル更新件数
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
  global_get_base_cd_expt    EXCEPTION;     -- 売上拠点取得エラー
  --
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';                       -- アドオン：共通・IF領域
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';                       -- アドオン：マスタ・マスタ領域
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A15C';                -- パッケージ名
  -- メッセージコード
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';            -- ｼｽﾃﾑｴﾗｰ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';            -- 対象データ無し
  cv_msg_xxcmm_00002        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00002';            -- プロファイル取得エラー
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';            -- ロックエラー
  cv_msg_xxcmm_00305        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00305';            -- パラメータエラー
  cv_msg_xxcmm_00311        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00311';            -- 最終取引日更新エラー
  cv_msg_xxcmm_00309        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00309';            -- 顧客ステータス更新エラー
  cv_msg_xxcmm_00331        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00331';            -- 会計クローズステータス取得エラー
  cv_msg_xxcmm_00033        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00033';            -- 更新件数メッセージ
  -- メッセージトークン
  cv_tkn_ng_profile         CONSTANT VARCHAR2(10) := 'NG_PROFILE';                  -- プロファイル名
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';                    -- テーブル名
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';                     -- 顧客コード
  cv_tkn_fnl_trn_date       CONSTANT VARCHAR2(12) := 'FINAL_TRN_DT';                -- 最終取引日
  cv_tkn_table              CONSTANT VARCHAR2(8)  := 'TBL_NAME';                    -- テーブル名
  --
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '顧客追加情報';                -- XXCMM_CUST_ACCOUNTS
  cv_tbl_nm_hzpt            CONSTANT VARCHAR2(8)  := 'パーティ';                    -- HZ_PARTIES
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                  -- 日付フォーマット
  cv_month_fmt              CONSTANT VARCHAR2(6)  := 'YYYYMM';                      -- 月フォーマット
  cv_date_time_fmt          CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';       -- 日時フォーマット
  cv_time_max               CONSTANT VARCHAR2(9)  := ' 23:59:59';
  cv_profile_ctrl_cal       CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';  -- ｼｽﾃﾑ稼働日ｶﾚﾝﾀﾞｺｰﾄﾞ定義ﾌﾟﾛﾌｧｲﾙ
  cv_profile_gl_cal         CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_GL_PERIOD_MN';  -- 会計カレンダ名定義ﾌﾟﾛﾌｧｲﾙ
  cv_profile_ar_bks         CONSTANT VARCHAR2(25) := 'XXCMM1_003A15_AR_BOOKS_NM';   -- 営業帳簿定義名ﾌﾟﾛﾌｧｲﾙ
  cv_lang_ja                CONSTANT VARCHAR2(2)  := 'JA';                          -- 言語（日本）
  cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';                           -- フラグ（Yes）
  cv_flag_no                CONSTANT VARCHAR2(1)  := 'N';                           -- フラグ（No）
  cv_lkup_type_gyotai_sho   CONSTANT VARCHAR2(21) := 'XXCMM_CUST_GYOTAI_SHO';       -- 参照タイプ（業態小分類）
  cv_lkup_type_gyotai_chu   CONSTANT VARCHAR2(21) := 'XXCMM_CUST_GYOTAI_CHU';       -- 参照タイプ（業態中分類）
  cv_sal_cls_usually        CONSTANT VARCHAR2(1)  := '1';                           -- 売上区分（通常）
  cv_sal_cls_bargain        CONSTANT VARCHAR2(1)  := '2';                           -- 売上区分（特売）
  cv_sal_cls_vdsale         CONSTANT VARCHAR2(1)  := '3';                           -- 売上区分（ベンダ売上）
  cv_sal_cls_consume        CONSTANT VARCHAR2(1)  := '4';                           -- 売上区分（消化・VD消化）
  cv_sal_cls_cvrsale        CONSTANT VARCHAR2(1)  := '9';                           -- 売上区分（補填商品の販売）
  cv_deli_slp_deliver       CONSTANT VARCHAR2(1)  := '1';                           -- 納品伝票区分（納品）
  cv_deli_slp_returned      CONSTANT VARCHAR2(1)  := '2';                           -- 納品伝票区分（返品）
  cv_deli_slp_crtn_deli     CONSTANT VARCHAR2(1)  := '3';                           -- 納品伝票区分（納品訂正）
  cv_sgl_space              CONSTANT VARCHAR2(1)  := CHR(32);                       -- 半角スペース文字
  cv_cust_status_admit      CONSTANT VARCHAR2(2)  := '30';                          -- 顧客ステータス（承認済）
  cv_cust_status_cust       CONSTANT VARCHAR2(2)  := '40';                          -- 顧客ステータス（顧客）
  cv_apl_short_nm_ar        CONSTANT VARCHAR2(2)  := 'AR';                          -- ｱﾌﾟﾘｹｰｼｮﾝ短縮名（AR）
  cv_cal_status_close       CONSTANT VARCHAR2(1)  := 'C';                           -- カレンダステータス（クローズ）
  cv_gyotai_chu_vd          CONSTANT VARCHAR2(2)  := '11';                          -- 業態中分類（VD）
  cd_min_date               CONSTANT DATE         := TO_DATE('1900/01/01', cv_date_fmt);  -- 最小日付
  cv_sel_trn_type_exchg     CONSTANT VARCHAR2(1)  := '0';                           -- 実績振替区分（振替割合）
  cv_rpt_dec_flg_rpt        CONSTANT VARCHAR2(1)  := '0';                           -- 速報確定フラグ（速報）
  cv_rpt_dec_flg_dec        CONSTANT VARCHAR2(1)  := '1';                           -- 速報確定フラグ（確定）
  cv_crt_flg_correction     CONSTANT VARCHAR2(1)  := '1';                           -- 振戻フラグ（振り戻し情報）
  cv_crt_flg_others         CONSTANT VARCHAR2(1)  := '0';                           -- 振戻フラグ（振り戻し情報以外）
-- 2009/05/27 Ver1.2 障害T1_0863 add start by Yutaka.Kuboshima
  cv_gyotai_sho_vd24        CONSTANT VARCHAR2(2)  := '24';                          -- 業態小分類（フルサービス（消化）ＶＤ）
  cv_gyotai_sho_vd25        CONSTANT VARCHAR2(2)  := '25';                          -- 業態小分類（フルサービスＶＤ）
-- 2009/05/27 Ver1.2 障害T1_0863 add end by Yutaka.Kuboshima
  --
  cv_para01_name            CONSTANT VARCHAR2(12) := '処理日(FROM)';                -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名01
  cv_para02_name            CONSTANT VARCHAR2(12) := '処理日(TO)  ';                -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名02
  cv_para_at_name           CONSTANT VARCHAR2(10) := '自動取得値';                  -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名_自動
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_cal_code           VARCHAR2(30);   -- システム稼働日カレンダコード値
  gv_gl_cal_code        VARCHAR2(30);   -- 会計カレンダコード値
  gd_now_proc_date      DATE;           -- 業務日付
  gd_para_proc_date_f   DATE;           -- 処理日(From)
  gd_para_proc_date_t   DATE;           -- 処理日(To)
  gd_last_month_day     DATE;           -- 前月末日
  gv_prev_month_cls_status  gl_period_statuses.closing_status%TYPE; -- 会計カレンダ・前月クローズステータス
  --
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  --
  -- A-2.処理対象データ抽出カーソル
  --
  CURSOR  XXCMM003A15C_cur
  IS
    SELECT
-- 2009/08/31 Ver1.3 add start by Yutaka.Kuboshima
--    ヒント句の追加
      /*+ FIRST_ROWS LEADING(fidt) USE_NL(hzca,hzpt,xcac)*/
-- 2009/08/31 Ver1.3 add end by Yutaka.Kuboshima
      hzca.cust_account_id        AS  cust_id,                -- 顧客ID
      hzca.party_id               AS  party_id,               -- パーティID
      fidt.cust_code              AS  cust_code,              -- 顧客コード
      hzpt.duns_number_c          AS  cust_status,            -- 顧客ステータス
      fidt.new_tran_date          AS  new_tran_date,          -- 最新取引日
-- 2009/05/27 Ver1.2 障害T1_0816,T1_0863 modify start by Yutaka.Kuboshima
--      fidt.past_deli_date         AS  past_deli_date,         -- 前月最新取引日
      xcac.final_tran_date        AS  final_tran_date,        -- 最終取引日
-- 2009/05/27 Ver1.2 障害T1_0816,T1_0863 modify end by Yutaka.Kuboshima
      xcac.past_final_tran_date   AS  past_final_tran_date,   -- 前月最終取引日
      fidt.past_deli_date         AS  past_new_fnl_trn_dt,    -- 前月最新取引日
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--      xcac.final_call_date        AS  final_call_date,        -- 最終訪問日
-- 2009/05/27 Ver1.2 delete end by Yutaka.Kuboshima
      xcac.cnvs_date              AS  cnvs_date,              -- 顧客獲得日
      xcac.start_tran_date        AS  start_tran_date,        -- 初回取引日
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--      gyti.business_mid_type      AS  business_mid_type,      -- 業態中分類
-- 2009/05/27 Ver1.2 delete end by Yutaka.Kuboshima
      hzpt.ROWID                  AS  hzpt_rowid,             -- レコードID（パーティ）
      xcac.ROWID                  AS  xcac_rowid,             -- レコードID（顧客追加情報）
-- 2009/05/27 Ver.12 障害T1_0816,T1_0863 add start by Yutaka.Kuboshima
      fidt.old_tran_date          AS  old_tran_date,          -- 最前取引日
      xcac.business_low_type      AS  business_low_type       -- 業態小分類
-- 2009/05/27 Ver.12 障害T1_0816,T1_0863 add end by Yutaka.Kuboshima
    FROM
      (
        SELECT
          xfid.cust_code              AS  cust_code,
          MAX(xfid.new_tran_date)     AS  new_tran_date,
-- 2009/05/27 Ver1.3 障害T1_0863 add start by Yutaka.Kuboshima
          MIN(xfid.new_tran_date)     AS  old_tran_date,
-- 2009/05/27 Ver1.3 障害T1_0863 add end by Yutaka.Kuboshima
          MAX(xfid.past_deli_date)    AS  past_deli_date
        FROM
          (
            -- 販売実績情報
            SELECT
              xseh.ship_to_customer_code    AS  cust_code,        -- 顧客コード【納品先】
              xseh.delivery_date            AS  new_tran_date,    -- 納品日（最新取引日）
              CASE WHEN (TRUNC(xseh.delivery_date) <= gd_last_month_day) THEN
                xseh.delivery_date
              ELSE
                NULL
              END                           AS  past_deli_date    -- 前月最新取引日
            FROM
              xxcos_sales_exp_headers       xseh    -- 販売実績ヘッダ
            WHERE
                  EXISTS(
                    SELECT
                      'X'
                    FROM
                          xxcos_sales_exp_lines   xsel  -- 販売実績明細
                    WHERE
                          xsel.sales_exp_header_id = xseh.sales_exp_header_id
                      AND xsel.sales_class IN (
                            cv_sal_cls_usually, cv_sal_cls_bargain, cv_sal_cls_vdsale,
                            cv_sal_cls_consume,  cv_sal_cls_cvrsale
                          )   -- 売上区分
                  )
              AND xseh.business_date BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
              AND xseh.dlv_invoice_class IN (
                    cv_deli_slp_deliver, cv_deli_slp_returned, cv_deli_slp_crtn_deli
                  )   -- 納品伝票区分
            UNION ALL
            -- 実績振替情報
            SELECT
              xsti.cust_code                AS  cust_code,      -- 顧客コード
              xsti.selling_date             AS  new_tran_date,  -- 計上日（最新取引日）
              CASE WHEN (TRUNC(xsti.selling_date) <= gd_last_month_day) THEN
                xsti.selling_date
              ELSE
                NULL
              END                           AS  past_deli_date    -- 前月最新取引日
            FROM
              xxcok_selling_trns_info       xsti                  -- 売上実績振替情報
            WHERE
-- 2009/08/31 Ver1.3 delete start by Yutaka.Kuboshima
--                  EXISTS(
--                    SELECT
--                      'X'
--                    FROM
--                      xxcok_selling_to_info     xsto              -- 売上振替先情報
--                    WHERE
--                          xsto.start_month            <=  TO_CHAR(xsti.registration_date, cv_month_fmt)
--                      AND xsto.selling_to_cust_code   =   xsti.cust_code
--                  )
-- 2009/08/31 Ver1.3 delete end by Yutaka.Kuboshima
                 xsti.registration_date  BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
          )   xfid
        GROUP BY
          xfid.cust_code
      )                     fidt,   -- 販売実績＆実績振替
      hz_cust_accounts      hzca,   -- 顧客マスタ
      hz_parties            hzpt,   -- パーティ
      xxcmm_cust_accounts   xcac    -- 顧客追加情報
-- 2009/05/27 Ver1.2 障害T1_0863 delete start by Yutaka.Kuboshima
--      (
--        SELECT
--          lkch.lookup_code      AS  business_mid_type,  -- 業態中分類区分
--          lkch.meaning          AS  business_mid_name,  -- 業態中分類区分名
--          lksh.lookup_code      AS  business_low_type,  -- 業態小分類区分
--          lksh.meaning          AS  business_low_name   -- 業態小分類区分名
--        FROM
--          fnd_lookup_values     lkch,   -- LOOKUP(業態中分類)
--          fnd_lookup_values     lksh    -- LOOKUP(業態小分類)
--        WHERE
--              lksh.attribute1     =   lkch.lookup_code
--          AND lksh.lookup_type    =   cv_lkup_type_gyotai_sho
--          AND lksh.enabled_flag   =   cv_flag_yes
--          AND lksh.language       =   cv_lang_ja
--          AND lkch.lookup_type    =   cv_lkup_type_gyotai_chu
--          AND lkch.enabled_flag   =   cv_flag_yes
--          AND lkch.language       =   cv_lang_ja
--      )                     gyti    -- 業態分類
-- 2009/05/27 Ver1.2 障害T1_0863 delete end by Yutaka.Kuboshima
    WHERE
          fidt.cust_code              = hzca.account_number
      AND hzca.cust_account_id        = xcac.customer_id
      AND hzca.party_id               = hzpt.party_id
-- 2009/05/27 Ver1.2 障害T1_0863 delete start by Yutaka.Kuboshima
--      AND xcac.business_low_type      = gyti.business_low_type(+)
-- 2009/05/27 Ver1.2 障害T1_0863 delete end by Yutaka.Kuboshima
    FOR UPDATE OF xcac.customer_id, hzpt.party_id NOWAIT
  ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : 顧客ステータス更新(A-5)
   ***********************************************************************************/
  PROCEDURE prc_upd_hz_parties(
    iv_rec        IN  XXCMM003A15C_cur%ROWTYPE,   -- 処理対象データレコード
    ov_errbuf     OUT VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_hz_parties'; -- プログラム名
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
    lv_step := 'A-5.1';
    --
    -- 顧客ステータス更新SQL文
-- 2009/02/27 delete start
--    UPDATE
--      hz_parties                    hzpt                          -- パーティ
--    SET
--      hzpt.duns_number_c            = cv_cust_status_cust,        -- 顧客ステータス（顧客）
--      hzpt.last_updated_by          = cn_last_updated_by,         -- 最終更新者
--      hzpt.last_update_date         = cd_last_update_date,        -- 最終更新日
--      hzpt.last_update_login        = cn_last_update_login,       -- 最終更新ログイン
--      hzpt.request_id               = cn_request_id,              -- 要求ID
--      hzpt.program_application_id   = cn_program_application_id,  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--      hzpt.program_id               = cn_program_id,              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--      hzpt.program_update_date      = cd_program_update_date      -- プログラム更新日
--    WHERE
--          hzpt.rowid                = iv_rec.hzpt_rowid           -- レコードID（パーティ）
--    ;
-- 2009/02/27 delete end
-- 2009/02/27 add start
    -- 共通関数パーティマスタ更新用関数呼出し
    xxcmm_003common_pkg.update_hz_party(iv_rec.party_id,
                                        cv_cust_status_cust,
                                        lv_errbuf,
                                        lv_retcode,
                                        lv_errmsg);
    -- 処理結果がエラーの場合はRAISE
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/02/27 add end
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- 2009/02/27 add start
    WHEN global_process_expt THEN
      -- メッセージセット
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00309,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_cust_code,           -- トークンコード1
                        iv_token_value1 =>  iv_rec.cust_code            -- トークン値1
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
-- 2009/02/27 add end
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- メッセージセット
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00309,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_cust_code,           -- トークンコード1
                        iv_token_value1 =>  iv_rec.cust_code            -- トークン値1
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
  END prc_upd_hz_parties;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : 最終取引日更新(A-4)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  XXCMM003A15C_cur%ROWTYPE,   -- 処理対象データレコード
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
    lv_step                   VARCHAR2(10);                                   -- ステップ
    ld_past_final_tran_date   xxcmm_cust_accounts.past_final_tran_date%TYPE;  -- 前月最終取引日
-- 2009/05/25 Ver1.2 delete start by Yutaka.Kuboshima
--    ld_final_call_date        xxcmm_cust_accounts.final_call_date%TYPE;       -- 最終訪問日
-- 2009/05/25 Ver1.2 delete end by Yutaka.Kuboshima
    ld_cnvs_date              xxcmm_cust_accounts.cnvs_date%TYPE;             -- 顧客獲得日
    ld_start_tran_date        xxcmm_cust_accounts.start_tran_date%TYPE;       -- 初回取引日
-- 2009/05/27 Ver1.2 障害T1_0816 add start by Yutaka.Kuboshima
    ld_final_tran_date        xxcmm_cust_accounts.final_tran_date%TYPE;       -- 最終取引日
-- 2009/05/27 Ver1.2 障害T1_0816 add end by Yutaka.Kuboshima
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
    -- 更新項目編集
    --
-- 2009/05/27 Ver1.2 障害T1_0816 add start by Yutaka.Kuboshima
    -- 最終取引日
    lv_step := 'A-4.1';
    IF (iv_rec.final_tran_date > iv_rec.new_tran_date) 
      OR (iv_rec.new_tran_date IS NULL)
    THEN
      ld_final_tran_date := iv_rec.final_tran_date;
    ELSE
      ld_final_tran_date := iv_rec.new_tran_date;
    END IF;
-- 2009/05/27 Ver1.2 障害T1_0816 add end by Yutaka.Kuboshima
    -- 前月最終取引日
-- 2009/05/27 Ver1.2 障害T1_0816 modify start by Yutaka.Kuboshima
--    lv_step := 'A-4.1';
    lv_step := 'A-4.2';
-- 2009/05/27 Ver1.2 障害T1_0816 modify end by Yutaka.Kuboshima
    IF (gv_prev_month_cls_status = cv_cal_status_close) THEN
      ld_past_final_tran_date :=  iv_rec.past_final_tran_date;
    ELSE
-- 2009/12/16 Ver1.4 E_本稼動_00540 modify start by Yutaka.Kuboshima
--      ld_past_final_tran_date :=  iv_rec.past_new_fnl_trn_dt;
      -- 前月最新取引日が前月最終取引日より未来の場合は更新
      IF (iv_rec.past_new_fnl_trn_dt > NVL(iv_rec.past_final_tran_date, cd_min_date)) THEN
        ld_past_final_tran_date :=  iv_rec.past_new_fnl_trn_dt;
      ELSE
        ld_past_final_tran_date :=  iv_rec.past_final_tran_date;
      END IF;
-- 2009/12/16 Ver1.4 E_本稼動_00540 modify end by Yutaka.Kuboshima
    END IF;
    -- 最終訪問日
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--    lv_step := 'A-4.2';
--    IF ((iv_rec.cust_status = cv_cust_status_admit) AND (iv_rec.new_tran_date > iv_rec.final_call_date)) THEN
--      ld_final_call_date  :=  iv_rec.new_tran_date;
--    ELSE
--      ld_final_call_date  :=  iv_rec.final_call_date;
--    END IF;
-- 2009/05/27 Ver1.2 delete end by Yutaka.Kuboshima
    -- 顧客獲得日
    lv_step := 'A-4.3';
-- 2009/05/27 Ver1.2 障害T1_0811,T1_0863 modify start by Yutaka.Kuboshima
--    IF ((iv_rec.business_mid_type = cv_gyotai_chu_vd) AND (iv_rec.cnvs_date IS NULL)) THEN
--      ld_cnvs_date  :=  iv_rec.new_tran_date;
--    ELSE
--      IF (iv_rec.cust_status = cv_cust_status_admit) THEN
--        IF (iv_rec.new_tran_date > iv_rec.final_call_date) THEN
--          ld_cnvs_date  :=  iv_rec.new_tran_date;
--        ELSE
--          ld_cnvs_date  :=  iv_rec.final_call_date;
--        END IF;
--      ELSE
--        ld_cnvs_date  :=  iv_rec.cnvs_date;
--      END IF;
--    END IF;
    IF (iv_rec.cnvs_date IS NULL)
      AND (iv_rec.cust_status = cv_cust_status_admit)
        AND (iv_rec.business_low_type NOT IN (cv_gyotai_sho_vd24, cv_gyotai_sho_vd25))
    THEN
      ld_cnvs_date := iv_rec.old_tran_date;
    ELSE
      ld_cnvs_date := iv_rec.cnvs_date;
    END IF;
-- 2009/05/27 Ver1.2 障害T1_0811,T1_0863 modify end by Yutaka.Kuboshima
    -- 初回取引日
    lv_step := 'A-4.4';
    IF (iv_rec.start_tran_date IS NULL) THEN
      ld_start_tran_date    :=  iv_rec.new_tran_date;
    ELSE
      ld_start_tran_date    :=  iv_rec.start_tran_date;
    END IF;
    --
    -- 最終取引日更新SQL文
    --
    lv_step := 'A-4.5';
    --
    UPDATE
      -- 顧客追加情報
      xxcmm_cust_accounts         xcac
    SET
-- 2009/05/27 Ver1.2 障害T1_0816 modify start by Yutaka.Kuboshima
--      xcac.final_tran_date        = iv_rec.new_tran_date,         -- 最終取引日
      xcac.final_tran_date        = ld_final_tran_date,           -- 最終取引日
-- 2009/05/27 Ver1.2 障害T1_0816 modify end by Yutaka.Kuboshima
      xcac.past_final_tran_date   = ld_past_final_tran_date,      -- 前月最終取引日
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--      xcac.final_call_date        = ld_final_call_date,           -- 最終訪問日
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
      xcac.cnvs_date              = ld_cnvs_date,                 -- 顧客獲得日
      xcac.start_tran_date        = ld_start_tran_date,           -- 初回取引日
      -- WHO
      xcac.last_updated_by        = cn_last_updated_by,           -- 最終更新者
      xcac.last_update_date       = cd_last_update_date,          -- 最終更新日
      xcac.last_update_login      = cn_last_update_login,         -- 最終更新ログイン
      xcac.request_id             = cn_request_id,                -- 要求ID
      xcac.program_application_id = cn_program_application_id,    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      xcac.program_id             = cn_program_id,                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      xcac.program_update_date    = cd_program_update_date        -- プログラム更新日
    WHERE
          xcac.rowid              = iv_rec.xcac_rowid             -- レコードID（顧客追加情報）
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
                        iv_name         =>  cv_msg_xxcmm_00311,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,            -- トークンコード1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- トークン値1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- トークンコード2
                        iv_token_value2 =>  iv_rec.cust_code,           -- トークン値2
                        iv_token_name3  =>  cv_tkn_fnl_trn_date,        -- トークンコード3
                        iv_token_value3 =>  TO_CHAR(iv_rec.new_tran_date, cv_date_fmt) -- トークン値3
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
    iv_proc_date_from   IN    VARCHAR2,   -- 処理日
    iv_proc_date_to     IN    VARCHAR2,   -- 処理日
    ov_errbuf           OUT   VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT   VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT   VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_step                   VARCHAR2(10);   -- ステップ
    lv_now_proc_date          VARCHAR2(10);   -- 業務日付（文字列）
    lv_proc_date              VARCHAR2(10);   -- パラメータ処理日
    ld_now_proc_date          DATE;           -- 業務日付
    ld_prev_proc_date         DATE;           -- 前業務日付
    lv_para_edit_buf          VARCHAR2(60);   -- 出力用ﾊﾟﾗﾒｰﾀ文字列編集領域
    lv_ar_set_of_books_nm     gl_sets_of_books.name%TYPE;             -- 営業システム会計帳簿定義名
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
    --
    -- プロファイル値取得
    --
    lv_step := 'A-1.1';
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
    -- 会計カレンダコード取得
    gv_gl_cal_code := fnd_profile.value(cv_profile_gl_cal);
    IF (gv_gl_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- アプリケーション短縮名
                      iv_name           =>  cv_msg_xxcmm_00002,   -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_gl_cal     -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 営業システム会計帳簿定義名取得
    lv_ar_set_of_books_nm := fnd_profile.value(cv_profile_ar_bks);
    IF (lv_ar_set_of_books_nm IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- アプリケーション短縮名
                      iv_name           =>  cv_msg_xxcmm_00002,   -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_ar_bks     -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --
    -- 業務日付取得
    --
    lv_step := 'A-1.2';
    --
    ld_now_proc_date    :=  xxccp_common_pkg2.get_process_date;
    gd_now_proc_date    :=  ld_now_proc_date;
    -- 処理日(To)をグローバル変数に格納
    IF (iv_proc_date_to IS NULL) THEN
      gd_para_proc_date_t   :=  TO_DATE(TO_CHAR(ld_now_proc_date, cv_date_fmt) || cv_time_max, cv_date_time_fmt);
    ELSE
      gd_para_proc_date_t   :=  TO_DATE(iv_proc_date_to || cv_time_max, cv_date_time_fmt);
    END IF;
    --
    -- 前業務日付取得
    --
    lv_step := 'A-1.3';
    --
    ld_prev_proc_date   :=  xxccp_common_pkg2.get_working_day(
                              gd_now_proc_date,
                              -1,
                              gv_cal_code
                            );
    ld_prev_proc_date   :=  TRUNC(ld_prev_proc_date + 1);
    --
    -- 処理日(From)をグローバル変数に格納
    IF (iv_proc_date_from IS NULL) THEN
      gd_para_proc_date_f   :=  ld_prev_proc_date;
    ELSE
      gd_para_proc_date_f   :=  TO_DATE(iv_proc_date_from, cv_date_fmt);
    END IF;
    lv_step := 'A-1.4';
    --
    -- コンカレント・パラメータのログ出力
    -- 処理日(From)
    lv_para_edit_buf    :=  cv_para01_name    ||  cv_msg_part       ||
                            cv_msg_bracket_f  ||  iv_proc_date_from ||  cv_msg_bracket_t;
    -- 処理日(From)の自動取得値
    IF (iv_proc_date_from IS NULL) THEN
      lv_para_edit_buf  :=  lv_para_edit_buf  ||  cv_msg_part       ||  cv_para_at_name     ||
                            cv_msg_bracket_f  ||  TO_CHAR(gd_para_proc_date_f, cv_date_fmt) ||  cv_msg_bracket_t;
    END IF;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    -- 処理日(To)
    lv_para_edit_buf    :=  cv_para02_name    ||  cv_msg_part       ||
                            cv_msg_bracket_f  ||  iv_proc_date_to   ||  cv_msg_bracket_t;
    -- 処理日(To)の自動取得値
    IF (iv_proc_date_to IS NULL) THEN
      lv_para_edit_buf  :=  lv_para_edit_buf  ||  cv_msg_part       ||  cv_para_at_name     ||
                            cv_msg_bracket_f  ||  TO_CHAR(gd_para_proc_date_t, cv_date_fmt) ||  cv_msg_bracket_t;
    END IF;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    -- 空行挿入
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --
    --
    -- パラメータチェック（処理日）
    --
    lv_step := 'A-1.5';
    IF (gd_para_proc_date_f > gd_para_proc_date_t) THEN
      -- パラメータの「処理日(From)」＞ 「処理日(To)」である場合、エラー
      -- メッセージ取得
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,      -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00305    -- メッセージコード
                      );
      -- パラメータエラー例外
      RAISE global_check_para_expt;
      --
    END IF;
    --
    -- 前月会計期間のクローズステータスを取得
    --
    lv_step := 'A-1.6';
    --
    gv_prev_month_cls_status  :=  NULL;
    --
    BEGIN
    --
      SELECT
        pers.closing_status
      INTO
        gv_prev_month_cls_status
      FROM
        gl_periods              peri,     -- 会計カレンダ
        gl_period_statuses      pers      -- 会計カレンダステータス
      WHERE
            EXISTS(
              -- ARアプリケーションのカレンダを抽出
              SELECT
                'X'
              FROM
                fnd_application   fapl
              WHERE
                    fapl.application_id         = pers.application_id
                AND fapl.application_short_name = cv_apl_short_nm_ar
            )
        AND EXISTS(
              -- 営業システム会計帳簿IDのカレンダを抽出
              SELECT
                'X'
              FROM
                gl_sets_of_books  gsob
              WHERE
                    gsob.set_of_books_id  = pers.set_of_books_id
                AND gsob.name             = lv_ar_set_of_books_nm
            )
        AND peri.period_name              = pers.period_name
        AND peri.period_set_name          = gv_gl_cal_code
        AND peri.adjustment_period_flag   = cv_flag_no
        AND pers.adjustment_period_flag   = cv_flag_no
        AND ADD_MONTHS(gd_now_proc_date, -1) BETWEEN pers.start_date AND pers.end_date
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,          -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00331        -- メッセージコード
                      );
        lv_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxccp_91003        -- メッセージコード
                      );
        lv_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
        RAISE global_process_expt;
    END;
    --
    -- 前月末日
    lv_step := 'A-1.7';
    --
    gd_last_month_day   :=  LAST_DAY(ADD_MONTHS(gd_now_proc_date, -1));
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
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 処理共通例外ハンドラ **
    WHEN global_process_expt THEN
      -- メッセージセット
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
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
    iv_proc_date_from   IN  VARCHAR2,   -- コンカレント・パラメータ 処理日(From)
    iv_proc_date_to     IN  VARCHAR2,   -- コンカレント・パラメータ 処理日(To)
    ov_errbuf           OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
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
    XXCMM003A15C_rec    XXCMM003A15C_cur%ROWTYPE;
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
    gn_target_cnt           :=  0;
    gn_normal_cnt           :=  0;
    gn_error_cnt            :=  0;
    gn_warn_cnt             :=  0;
    gn_xx_cust_acnt_upd_cnt :=  0;
    gn_hz_pts_upd_cnt       :=  0;
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
      iv_proc_date_from,  -- 処理日(From)
      iv_proc_date_to,    -- 処理日(To)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    -- A-2.処理対象データ抽出
    -- ===============================
    lv_step := 'A-2';
    --
    OPEN  XXCMM003A15C_cur;
    --
    LOOP
      -- 処理対象データ・カーソルフェッチ
      FETCH XXCMM003A15C_cur INTO XXCMM003A15C_rec;
      EXIT WHEN XXCMM003A15C_cur%NOTFOUND;
      --
      gn_target_cnt := XXCMM003A15C_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      --
      -- ===============================
      -- A-3.SAVE POINT 発行
      -- ===============================
      lv_step := 'A-3';
      --
      SAVEPOINT svpt_cust_rec;
      --
      -- ===============================
      -- A-4.最終取引日更新
      -- ===============================
      lv_step := 'A-4';
      prc_upd_xxcmm_cust_accounts(
        XXCMM003A15C_rec,   -- カーソルレコード
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        lb_err_flg  :=  TRUE;
        ln_err_cnt  :=  1;
        fnd_file.put_line(
          which => fnd_file.output,
          buff  => lv_errmsg --ユーザーエラーメッセージ
        );
        fnd_file.put_line(
          which => fnd_file.log,
          buff  => lv_errmsg --ユーザーエラーメッセージ
        );
        fnd_file.put_line(
          which => fnd_file.log,
          buff  => lv_errbuf --エラーメッセージ
        );
        -- メッセージ編集領域初期化
        lv_errmsg := NULL;
        lv_errbuf := NULL;
        --
      ELSE
        -- 顧客追加情報更新件数カウント
        gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt + 1;
      END IF;
      --
-- 2009/03/02 modify start
      IF (XXCMM003A15C_rec.cust_status = cv_cust_status_admit) --THEN
        AND (ln_err_cnt = 0)
      THEN
-- 2009/03/02 modify end
        -- ===============================
        -- A-5.顧客ステータス更新
        -- ===============================
        lv_step := 'A-5';
        --
        prc_upd_hz_parties(
          XXCMM003A15C_rec,   -- カーソルレコード
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          lb_err_flg  :=  TRUE;
          ln_err_cnt  :=  1;
          fnd_file.put_line(
            which => fnd_file.output,
            buff  => lv_errmsg --ユーザーエラーメッセージ
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errmsg --ユーザーエラーメッセージ
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errbuf --エラーメッセージ
          );
          -- メッセージ編集領域初期化
          lv_errmsg := NULL;
          lv_errbuf := NULL;
          --
          -- 顧客追加情報更新件数カウントを戻す
          gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt - 1;
          --
        ELSE
          -- パーティ更新（顧客ステータス）件数
          gn_hz_pts_upd_cnt := gn_hz_pts_upd_cnt + 1;
        END IF;
        --
      END IF;
      --
      -- 成功件数、エラー件数のカウント
      IF (ln_err_cnt = 0) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt + ln_err_cnt;
      END IF;
      --
      -- エラー検出時、SAVEPOINTまでROLLBACK
      IF (ln_err_cnt > 0) THEN
        -- ===============================
        -- A-7.ROLLBACK発行処理
        -- ===============================
        lv_step := 'A-7';
        --
        ROLLBACK TO svpt_cust_rec;
        --
      END IF;
      --
    END LOOP;
    --
    -- カーソルクローズ
    CLOSE XXCMM003A15C_cur;
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
          which => fnd_file.output,
          buff  => lv_errmsg --パラメータなしメッセージ
        );
        fnd_file.put_line(
          which => fnd_file.log,
          buff  => lv_errmsg --パラメータなしメッセージ
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
      IF XXCMM003A15C_cur%ISOPEN THEN
        CLOSE  XXCMM003A15C_cur;
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
      IF XXCMM003A15C_cur%ISOPEN THEN
        CLOSE XXCMM003A15C_cur;
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
      IF XXCMM003A15C_cur%ISOPEN THEN
        CLOSE XXCMM003A15C_cur;
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
--
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT   VARCHAR2,     -- エラー・メッセージ  --# 固定 #
    retcode           OUT   VARCHAR2,     -- リターン・コード    --# 固定 #
    iv_proc_date_from IN    VARCHAR2,     -- コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to   IN    VARCHAR2      -- コンカレント・パラメータ処理日(TO)
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
    cv_all_error_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_prt_error_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了一部処理
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
      iv_proc_date_from,    -- コンカレント・パラメータ処理日(FROM)
      iv_proc_date_to,      -- コンカレント・パラメータ処理日(TO)
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
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
    --顧客追加情報更新件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00033,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_xx_cust_acnt_upd_cnt),
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => cv_tbl_nm_xcac
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
    --パーティ更新件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00033,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_hz_pts_upd_cnt),
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => cv_tbl_nm_hzpt
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
      IF (gn_normal_cnt > 0) THEN
        lv_message_code := cv_prt_error_msg;
      ELSE
        lv_message_code := cv_all_error_msg;
      END IF;
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
    --コミット
    COMMIT;
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
END xxcmm003a15c;
/
