CREATE OR REPLACE PACKAGE BODY XXCMM003A14C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A14C(body)
 * Description      : HHT側に顧客への最終訪問日を連携するため、顧客マスタ上に最終訪問日を
 *                    保持する必要があります。
 *                    当機能を日次で稼動させ、最新の最終訪問日を自動更新します。
 * MD.050           : 最終訪問日更新 MD050_CMM_003_A14
 * Version          : Issue3.4
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_hz_parties              顧客ステータス更新(A-6)
 *  prc_ins_xxcmm_cust_accounts     顧客追加情報テーブル登録(A-5)
 *  prc_upd_xxcmm_cust_accounts     顧客追加情報テーブル最終訪問日更新(A-4)
 *  prc_init                        初期処理(A-1)
 *  submain                         メイン処理プロシージャ(A-2:処理対象データ抽出)
 *                                    ・prc_init
 *                                    ・prc_upd_xxcmm_cust_accounts
 *                                    ・prc_ins_xxcmm_cust_accounts
 *                                    ・prc_upd_hz_parties
 *  main                            コンカレント実行ファイル登録プロシージャ(A-7:終了処理)
 *                                    ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/21    1.0   SCS Okuyama      新規作成
 *  2009/02/29    1.1   Yutaka.Kuboshima 顧客ステータス更新処理を変更
 *  2009/03/18    1.2   Yuuki.Nakamura   タスクステータス名定義テーブル．名称の取得条件を「クローズ」に変更
 *  2009/05/20    1.3   Yutaka.Kuboshima 障害T1_0476,T1_1098の対応
 *  2009/08/27    1.4   Yutaka.Kuboshima 障害0001193の対応 担当営業員の取得条件を修正
 *                                       (アサイメント番号 -> 従業員番号)
 *  2009/11/09    1.5   Shigeto.Niki     障害E_T4_00135の対応 エラー終了 -> 警告終了に修正
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
  gn_xx_cust_acnt_ins_cnt NUMBER;       -- 顧客追加情報テーブル登録件数
  gn_hz_pts_upd_cnt       NUMBER;       -- パーティテーブル更新件数
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
  global_get_base_cd_expt    EXCEPTION;     -- 売上拠点取得エラー
  --
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';               -- アドオン：共通・IF領域
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';               -- アドオン：マスタ・マスタ領域
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A14C';        -- パッケージ名
  -- メッセージコード
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';    -- ｼｽﾃﾑｴﾗｰ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';    -- 対象データ無し
  cv_msg_xxcmm_00002        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00002';    -- プロファイル取得エラー
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';    -- ロックエラー
  cv_msg_xxcmm_00305        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00305';    -- パラメータエラー
  cv_msg_xxcmm_00306        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00306';    -- 最終訪問日更新エラー
  cv_msg_xxcmm_00307        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00307';    -- 売上拠点取得エラー
  cv_msg_xxcmm_00308        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00308';    -- 最終訪問日登録エラー
  cv_msg_xxcmm_00309        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00309';    -- 顧客ステータス更新エラー
  cv_msg_xxcmm_00033        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00033';    -- 更新件数メッセージ
  cv_msg_xxcmm_00034        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00034';    -- 登録件数メッセージ
  -- メッセージトークン
  cv_tkn_ng_profile         CONSTANT VARCHAR2(10) := 'NG_PROFILE';          -- プロファイル名
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';            -- テーブル名
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';             -- 顧客コード
  cv_tkn_fnl_call_date      CONSTANT VARCHAR2(13) := 'FINAL_CALL_DT';       -- 最終訪問日
  cv_tkn_table              CONSTANT VARCHAR2(8)  := 'TBL_NAME';            -- テーブル名
  --
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '顧客追加情報';        -- XXCMM_CUST_ACCOUNTS
  cv_tbl_nm_hzpt            CONSTANT VARCHAR2(8)  := 'パーティ';            -- HZ_PARTIES
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- 日付フォーマット
  cv_month_fmt              CONSTANT VARCHAR2(6)  := 'YYYYMM';              -- 月フォーマット
  cv_date_time_fmt          CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';          -- 日時フォーマット
  cv_time_max               CONSTANT VARCHAR2(9)  := ' 23:59:59';
  cv_profile_ctrl_cal       CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';  -- ｼｽﾃﾑ稼働日ｶﾚﾝﾀﾞｺｰﾄﾞ定義ﾌﾟﾛﾌｧｲﾙ
  cv_term_immediate         CONSTANT VARCHAR2(8)  := '00_00_00';            -- 支払条件名（即時）
  cv_lang_ja                CONSTANT VARCHAR2(2)  := 'JA';                  -- 言語（日本）
  cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';                   -- フラグ（Yes）
  cv_flag_no                CONSTANT VARCHAR2(1)  := 'N';                   -- フラグ（No）
  cv_tsk_type_visit         CONSTANT VARCHAR2(4)  := '訪問';                -- タスクタイプ名（訪問）
-- 2009/03/18 mod start
--  cv_tsk_status_cmp         CONSTANT VARCHAR2(4)  := '完了';                -- タスクステータス名（完了）
  cv_tsk_status_cmp         CONSTANT VARCHAR2(8)  := 'クローズ';            -- タスクステータス名（クローズ）
-- 2009/03/18 mod end
  cv_sgl_space              CONSTANT VARCHAR2(1)  := CHR(32);               -- 半角スペース文字
  cv_ui_flag_new            CONSTANT VARCHAR2(1)  := '1';                   -- 新規／更新フラグ（新規）
  cv_cust_status_mc_cnd     CONSTANT VARCHAR2(2)  := '10';                  -- 顧客ステータス（ＭＣ候補）
  cv_cust_status_mc         CONSTANT VARCHAR2(2)  := '20';                  -- 顧客ステータス（ＭＣ）
  --
  cv_para01_name            CONSTANT VARCHAR2(12) := '処理日(FROM)';        -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名01
  cv_para02_name            CONSTANT VARCHAR2(12) := '処理日(TO)  ';        -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名02
  cv_para_at_name           CONSTANT VARCHAR2(10) := '自動取得値';          -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名_自動
--
-- 2009/05/20 Ver1.3 障害T1_1098 add start by Yutaka.Kuboshima
  cv_cust_kbn               CONSTANT VARCHAR2(2)  := '10';                  -- 顧客区分（顧客）
  cv_uesama_kbn             CONSTANT VARCHAR2(2)  := '12';                  -- 顧客区分（上様顧客）
-- 2009/05/20 Ver1.3 障害T1_1098 add end by Yutaka.Kuboshima
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_cal_code           VARCHAR2(10);   -- システム稼働日カレンダコード値
  gd_now_proc_date      DATE;           -- 業務日付
  gd_para_proc_date_f   DATE;           -- 処理日(From)
  gd_para_proc_date_t   DATE;           -- 処理日(To)
  --
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  --
  -- A-2.処理対象データ抽出カーソル
  --
  CURSOR  XXCMM003A14C_cur
  IS
    SELECT
      hzac.cust_account_id        AS  cust_id,              -- 顧客ID
      hzac.account_number         AS  cust_code,            -- 顧客コード
      hzac.customer_class_code    AS  cust_kbn,             -- 顧客区分
      hzpt.duns_number_c          AS  cust_status,          -- 顧客ステータス
      TRUNC(fcdt.final_call_date) AS  task_final_call_date, -- 実績終了日（訪問日）
      TRUNC(xcac.final_call_date) AS  now_final_call_date,  -- 現在最終訪問日
      CASE WHEN (xcac.customer_id IS NULL)
      THEN
        cv_flag_yes
      ELSE
        cv_flag_no
      END                       AS  rec_ins_flg,          -- レコード作成有無
      hzac.party_id             AS  party_id,             -- パーティID
      hzpt.ROWID                AS  hzpt_rowid,           -- レコードID（パーティ）
      xcac.ROWID                AS  xcac_rowid            -- レコードID（顧客追加情報）
    FROM
      hz_cust_accounts        hzac,                       -- 顧客マスタ
      hz_parties              hzpt,                       -- パーティ
      xxcmm_cust_accounts     xcac,                       -- 顧客追加情報
-- 2009/05/20 Ver1.3 障害T1_0476 modify start by Yutaka.Kuboshima
--      (
--        SELECT
--          jtab.customer_id            AS  party_id,         -- パーティID
--          MAX(jtab.actual_end_date)   AS  final_call_date   -- 実績終了日（訪問日）
--        FROM
--          jtf_tasks_b                 jtab,                 -- タスク
--          jtf_task_statuses_b         jtsb,                 -- タスクステータス定義
--          jtf_task_statuses_tl        jtst,                 -- タスクステータス名定義
--          jtf_task_types_b            jttb,                 -- タスクタイプ定義
--          jtf_task_types_tl           jttt                  -- タスクタイプ名定義
--        WHERE
--              jtab.task_type_id     = jttb.task_type_id
--          AND jtab.task_status_id   = jtsb.task_status_id
--          AND jttb.task_type_id     = jttt.task_type_id
--          AND jtsb.task_status_id   = jtst.task_status_id
--          AND jttt.language         = cv_lang_ja
--          AND jttt.name             = cv_tsk_type_visit
--          AND jtsb.completed_flag   = cv_flag_yes
--          AND jtst.language         = cv_lang_ja
--          AND jtst.name             = cv_tsk_status_cmp
--          AND jtab.last_update_date BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
--        GROUP BY
--          jtab.customer_id
--      )                     fcdt      -- 最終訪問日更新対象情報
        (
          SELECT xvav.customer_id          AS party_id,       -- パーティID
                 MAX(xvav.actual_end_date) AS final_call_date -- 実績終了日（訪問日）
          FROM xxcso_visit_actual_v xvav                      -- 有効訪問実績ビュー
          WHERE xvav.last_update_date BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
          GROUP BY xvav.customer_id
        )                     fcdt      -- 最終訪問日更新対象情報
-- 2009/05/20 Ver1.3 障害T1_0476 modify end by Yutaka.Kuboshima
    WHERE
          hzac.party_id         = fcdt.party_id
      AND hzpt.party_id         = hzac.party_id
      AND hzac.cust_account_id  = xcac.customer_id(+)
    FOR UPDATE OF xcac.customer_id, hzpt.party_id NOWAIT
  ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : 顧客ステータス更新(A-6)
   ***********************************************************************************/
  PROCEDURE prc_upd_hz_parties(
    iv_rec        IN  XXCMM003A14C_cur%ROWTYPE,   -- 処理対象データレコード
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
    lv_step := 'A-6.1';
    --
    -- 顧客ステータス更新SQL文
-- 2009/02/27 delete start
--    UPDATE
--      hz_parties                    hzpt                          -- パーティ
--    SET
--      hzpt.duns_number_c            = cv_cust_status_mc,          -- 顧客ステータス（ＭＣ）
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
                                        cv_cust_status_mc,
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
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod end by Shigeto.Niki
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
   * Procedure Name   : prc_ins_xxcmm_cust_accounts
   * Description      : 顧客追加情報登録(A-5)
   ***********************************************************************************/
  PROCEDURE prc_ins_xxcmm_cust_accounts(
    iv_rec        IN  XXCMM003A14C_cur%ROWTYPE,   -- 処理対象データレコード
    ov_errbuf     OUT VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_xxcmm_cust_accounts'; -- プログラム名
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
    lv_emp_code   hz_org_profiles_ext_b.c_ext_attr1%TYPE;     -- 担当営業員
    lv_base_code  per_all_assignments_f.ass_attribute5%TYPE;  -- 拠点コード（新）
-- 2009/05/20 Ver1.3 障害T1_1098 add start by Yutaka.Kuboshima
    lv_delivery_base_code xxcmm_cust_accounts.delivery_base_code%TYPE; -- 納品拠点コード
-- 2009/05/20 Ver1.3 障害T1_1098 add end by Yutaka.Kuboshima
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
    -- A-5.担当営業員所属拠点コード取得
    --
    BEGIN
      --
      lv_emp_code   :=  NULL;
      lv_base_code  :=  NULL;
      -- 
      SELECT
        eres.resource_no,                   -- 担当営業員
        SUBSTRB(pasi.ass_attribute5, 1, 4)  -- 拠点コード（新）
      INTO
        lv_emp_code,
        lv_base_code
      FROM
        hz_organization_profiles    opro,   -- 組織プロファイルテーブル
        ego_resource_agv            eres,   -- 組織プロファイル拡張テーブル
        per_all_assignments_f       pasi    -- アサインメントマスタテーブル
-- 2009/08/27 Ver1.4 add start by Yutaka.Kuboshima
       ,per_all_people_f            papf    -- 従業員マスタテーブル
-- 2009/08/27 Ver1.4 add end by Yutaka.Kuboshima
      WHERE
            opro.organization_profile_id  = eres.organization_profile_id
-- 2009/08/27 Ver1.4 modify start by Yutaka.Kuboshima
--        AND eres.resource_no              = pasi.assignment_number
        AND eres.resource_no              = papf.employee_number
        AND papf.person_id                = pasi.person_id
        AND gd_now_proc_date BETWEEN
              papf.effective_start_date AND papf.effective_end_date
-- 2009/08/27 Ver1.4 modify end by Yutaka.Kuboshima
        AND gd_now_proc_date BETWEEN
              opro.effective_start_date AND NVL(opro.effective_end_date, gd_now_proc_date)
        AND gd_now_proc_date BETWEEN
              NVL(eres.resource_s_date, gd_now_proc_date) AND NVL(eres.resource_e_date, gd_now_proc_date)
        AND gd_now_proc_date BETWEEN
              pasi.effective_start_date AND pasi.effective_end_date
        AND opro.party_id                 = iv_rec.party_id
        AND ROWNUM  = 1
      ;
      --
      IF (lv_base_code IS NULL) THEN
        RAISE global_get_base_cd_expt;
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_get_base_cd_expt;
    END;
-- 2009/05/20 Ver1.3 障害T1_01098 add start by Yutaka.Kuboshima
    -- 顧客区分が'10','12'の場合、拠点コード（新）を納品拠点に登録
    IF (iv_rec.cust_kbn IN (cv_cust_kbn, cv_uesama_kbn)) THEN
      lv_delivery_base_code := lv_base_code;
    ELSE
      lv_delivery_base_code := NULL;
    END IF;
-- 2009/05/20 Ver1.3 障害T1_01098 add end by Yutaka.Kuboshima
    --
    -- 顧客追加情報登録SQL文
    lv_step := 'A-5.1';
    --
    INSERT INTO xxcmm_cust_accounts
    (
      customer_id,                  -- 顧客ID
      customer_code,                -- 顧客コード
      cust_update_flag,             -- 新規／更新フラグ
      business_low_type,            -- 業態（小分類）
      industry_div,                 -- 業種
      selling_transfer_div,         -- 売上実績振替
      torihiki_form,                -- 取引形態
      delivery_form,                -- 配送形態
      wholesale_ctrl_code,          -- 問屋管理コード
      ship_storage_code,            -- 出荷元保管場所(EDI)
      start_tran_date,              -- 初回取引日
      final_tran_date,              -- 最終取引日
      past_final_tran_date,         -- 前月最終取引日
      final_call_date,              -- 最終訪問日
      stop_approval_date,           -- 中止決裁日
      stop_approval_reason,         -- 中止理由
      vist_untarget_date,           -- 顧客対象外変更日
      vist_target_div,              -- 訪問対象区分
      party_representative_name,    -- 代表者名（相手先）
      party_emp_name,               -- 担当者（相手先）
      sale_base_code,               -- 売上拠点コード
      past_sale_base_code,          -- 前月売上拠点コード
      rsv_sale_base_act_date,       -- 予約売上拠点有効開始日
      rsv_sale_base_code,           -- 予約売上拠点コード
      delivery_base_code,           -- 納品拠点コード
      sales_head_base_code,         -- 販売先本部担当拠点
      chain_store_code,             -- チェーン店コード（EDI）
      store_code,                   -- 店舗コード
      cust_store_name,              -- 顧客店舗名称
      torihikisaki_code,            -- 取引先コード
      sales_chain_code,             -- 販売先チェーンコード
      delivery_chain_code,          -- 納品先チェーンコード
      policy_chain_code,            -- 政策用チェーンコード
      intro_chain_code1,            -- 紹介者チェーンコード１
      intro_chain_code2,            -- 紹介者チェーンコード２
      tax_div,                      -- 消費税区分
      rate,                         -- 消化計算用掛率
      receiv_discount_rate,         -- 入金値引率
      conclusion_day1,              -- 消化計算締め日１
      conclusion_day2,              -- 消化計算締め日２
      conclusion_day3,              -- 消化計算締め日３
      contractor_supplier_code,     -- 契約者仕入先コード
      bm_pay_supplier_code1,        -- 紹介者BM支払仕入先コード１
      bm_pay_supplier_code2,        -- 紹介者BM支払仕入先コード２
      delivery_order,               -- 配送順（EDI)
      edi_district_code,            -- EDI地区コード（EDI)
      edi_district_name,            -- EDI地区名（EDI)
      edi_district_kana,            -- EDI地区名カナ（EDI)
      center_edi_div,               -- センターEDI区分
      tsukagatazaiko_div,           -- 通過在庫型区分（EDI）
      establishment_location,       -- 設置ロケーション
      open_close_div,               -- 物件オープン・クローズ区分
      operation_div,                -- オペレーション区分
      change_amount,                -- 釣銭
      vendor_machine_number,        -- 自動販売機番号（相手先）
      established_site_name,        -- 設置先名（相手先）
      cnvs_date,                    -- 顧客獲得日
      cnvs_base_code,               -- 獲得拠点コード
      cnvs_business_person,         -- 獲得営業員
      new_point_div,                -- 新規ポイント区分
      new_point,                    -- 新規ポイント
      intro_base_code,              -- 紹介拠点コード
      intro_business_person,        -- 紹介営業員
      edi_chain_code,               -- チェーン店コード(EDI)【親レコード用】
      latitude,                     -- 緯度
      longitude,                    -- 経度
      management_base_code,         -- 管理元拠点コード
      edi_item_code_div,            -- EDI連携品目コード区分
      edi_forward_number,           -- EDI伝送追番
      handwritten_slip_div,         -- EDI手書伝票伝送区分
      deli_center_code,             -- EDI納品センターコード
      deli_center_name,             -- EDI納品センター名
      dept_hht_div,                 -- 百貨店用HHT区分
      bill_base_code,               -- 請求拠点コード
      receiv_base_code,             -- 入金拠点コード
      child_dept_shop_code,         -- 百貨店伝区コード
      parnt_dept_shop_code,         -- 百貨店伝区コード【親レコード用】
      past_customer_status,         -- 前月顧客ステータス
      created_by,                   -- 作成者
      creation_date,                -- 作成日
      last_updated_by,              -- 最終更新者
      last_update_date,             -- 最終更新日
      last_update_login,            -- 最終更新ﾛｸﾞｲﾝ
      request_id,                   -- 要求ID
      program_application_id,       -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      program_id,                   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      program_update_date           -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    VALUES
    (
      iv_rec.cust_id,               -- 顧客ID
      iv_rec.cust_code,             -- 顧客コード
      cv_ui_flag_new,               -- 新規／更新フラグ
      NULL,                         -- 業態（小分類）
      NULL,                         -- 業種
      NULL,                         -- 売上実績振替
      NULL,                         -- 取引形態
      NULL,                         -- 配送形態
      NULL,                         -- 問屋管理コード
      NULL,                         -- 出荷元保管場所(EDI)
      NULL,                         -- 初回取引日
      NULL,                         -- 最終取引日
      NULL,                         -- 前月最終取引日
      iv_rec.task_final_call_date,  -- 最終訪問日
      NULL,                         -- 中止決裁日
      NULL,                         -- 中止理由
      NULL,                         -- 顧客対象外変更日
      NULL,                         -- 訪問対象区分
      NULL,                         -- 代表者名（相手先）
      NULL,                         -- 担当者（相手先）
      SUBSTRB(lv_base_code, 1, 4),  -- 売上拠点コード
      SUBSTRB(lv_base_code, 1, 4),  -- 前月売上拠点コード
      NULL,                         -- 予約売上拠点有効開始日
      NULL,                         -- 予約売上拠点コード
-- 2009/05/20 Ver1.3 障害T1_1098 modify start by Yutaka.Kuboshima
--      NULL,                         -- 納品拠点コード
      lv_delivery_base_code,        -- 納品拠点コード
-- 2009/05/20 Ver1.3 障害T1_1098 modify end by Yutaka.Kuboshima
      NULL,                         -- 販売先本部担当拠点
      NULL,                         -- チェーン店コード（EDI）
      NULL,                         -- 店舗コード
      NULL,                         -- 顧客店舗名称
      NULL,                         -- 取引先コード
      NULL,                         -- 販売先チェーンコード
      NULL,                         -- 納品先チェーンコード
      NULL,                         -- 政策用チェーンコード
      NULL,                         -- 紹介者チェーンコード１
      NULL,                         -- 紹介者チェーンコード２
      NULL,                         -- 消費税区分
      NULL,                         -- 消化計算用掛率
      NULL,                         -- 入金値引率
      NULL,                         -- 消化計算締め日１
      NULL,                         -- 消化計算締め日２
      NULL,                         -- 消化計算締め日３
      NULL,                         -- 契約者仕入先コード
      NULL,                         -- 紹介者BM支払仕入先コード１
      NULL,                         -- 紹介者BM支払仕入先コード２
      NULL,                         -- 配送順（EDI)
      NULL,                         -- EDI地区コード（EDI)
      NULL,                         -- EDI地区名（EDI)
      NULL,                         -- EDI地区名カナ（EDI)
      NULL,                         -- センターEDI区分
      NULL,                         -- 通過在庫型区分（EDI）
      NULL,                         -- 設置ロケーション
      NULL,                         -- 物件オープン・クローズ区分
      NULL,                         -- オペレーション区分
      NULL,                         -- 釣銭
      NULL,                         -- 自動販売機番号（相手先）
      NULL,                         -- 設置先名（相手先）
      NULL,                         -- 顧客獲得日
      NULL,                         -- 獲得拠点コード
      NULL,                         -- 獲得営業員
      NULL,                         -- 新規ポイント区分
      NULL,                         -- 新規ポイント
      NULL,                         -- 紹介拠点コード
      NULL,                         -- 紹介営業員
      NULL,                         -- チェーン店コード(EDI)【親レコード用】
      NULL,                         -- 緯度
      NULL,                         -- 経度
      NULL,                         -- 管理元拠点コード
      NULL,                         -- EDI連携品目コード区分
      NULL,                         -- EDI伝送追番
      NULL,                         -- EDI手書伝票伝送区分
      NULL,                         -- EDI納品センターコード
      NULL,                         -- EDI納品センター名
      NULL,                         -- 百貨店用HHT区分
      NULL,                         -- 請求拠点コード
      NULL,                         -- 入金拠点コード
      NULL,                         -- 百貨店伝区コード
      NULL,                         -- 百貨店伝区コード【親レコード用】
      NULL,                         -- 前月顧客ステータス
      cn_created_by,                -- 作成者
      cd_creation_date,             -- 作成日
      cn_last_updated_by,           -- 最終更新者
      cd_last_update_date,          -- 最終更新日
      cn_last_update_login,         -- 最終更新ﾛｸﾞｲﾝ
      cn_request_id,                -- 要求ID
      cn_program_application_id,    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      cn_program_id,                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      cd_program_update_date        -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    ;
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_get_base_cd_expt THEN
      -- メッセージセット
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00307,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_cust_code,           -- トークンコード1
                        iv_token_value1 =>  iv_rec.cust_code,           -- トークン値1
                        iv_token_name2  =>  cv_tkn_fnl_call_date,       -- トークンコード2
                        iv_token_value2 =>  TO_CHAR(iv_rec.task_final_call_date, cv_date_fmt) -- トークン値2
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      -- 処理ステータスセット
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod end by Shigeto.Niki
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- メッセージセット
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00308,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,            -- トークンコード1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- トークン値1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- トークンコード2
                        iv_token_value2 =>  iv_rec.cust_code,           -- トークン値2
                        iv_token_name3  =>  cv_tkn_fnl_call_date,       -- トークンコード3
                        iv_token_value3 =>  TO_CHAR(iv_rec.task_final_call_date, cv_date_fmt) -- トークン値3
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
  END prc_ins_xxcmm_cust_accounts;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : 最終訪問日更新(A-4)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  XXCMM003A14C_cur%ROWTYPE,   -- 処理対象データレコード
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
    lv_step := 'A-4.1';
    --
    -- 最終訪問日更新SQL文
    UPDATE
      -- 顧客追加情報
      xxcmm_cust_accounts         xcac
    SET
      -- 最終訪問日
      xcac.final_call_date        = iv_rec.task_final_call_date,
      -- WHO
      xcac.last_updated_by        = cn_last_updated_by,         -- 最終更新者
      xcac.last_update_date       = cd_last_update_date,        -- 最終更新日
      xcac.last_update_login      = cn_last_update_login,       -- 最終更新ログイン
      xcac.request_id             = cn_request_id,              -- 要求ID
      xcac.program_application_id = cn_program_application_id,  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      xcac.program_id             = cn_program_id,              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      xcac.program_update_date    = cd_program_update_date      -- プログラム更新日
    WHERE
      xcac.rowid  = iv_rec.xcac_rowid                           -- レコードID（顧客追加情報）
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
                        iv_name         =>  cv_msg_xxcmm_00306,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,            -- トークンコード1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- トークン値1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- トークンコード2
                        iv_token_value2 =>  iv_rec.cust_code,           -- トークン値2
                        iv_token_name3  =>  cv_tkn_fnl_call_date,       -- トークンコード3
                        iv_token_value3 =>  TO_CHAR(iv_rec.task_final_call_date, cv_date_fmt) -- トークン値3
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxccp_91003        -- メッセージコード
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- 処理ステータスセット
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod end by Shigeto.Niki
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
    iv_proc_date_from  IN  VARCHAR2,     --  処理日
    iv_proc_date_to    IN  VARCHAR2,     --  処理日
    ov_errbuf     OUT VARCHAR2,     --  エラー・メッセージ            --# 固定 #
    ov_retcode    OUT VARCHAR2,     --  リターン・コード              --# 固定 #
    ov_errmsg     OUT VARCHAR2      --  ユーザー・エラー・メッセージ --# 固定 #
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
    ld_prev_proc_date   DATE;           -- 前業務日付
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
    lb_err_flg                  BOOLEAN;    -- エラー有無
    lb_xxcust_acnt_upd_cnt_flg  BOOLEAN;    -- 顧客追加情報更新件数カウント有無
    lb_xxcust_acnt_ins_cnt_flg  BOOLEAN;    -- 顧客追加情報登録件数カウント有無
    ln_err_cnt                  NUMBER;     -- エラー発生数（１顧客単位）
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    XXCMM003A14C_rec    XXCMM003A14C_cur%ROWTYPE;
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
    gn_xx_cust_acnt_ins_cnt :=  0;
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
    OPEN  XXCMM003A14C_cur;
    --
    LOOP
      -- 処理対象データ・カーソルフェッチ
      FETCH XXCMM003A14C_cur INTO XXCMM003A14C_rec;
      EXIT WHEN XXCMM003A14C_cur%NOTFOUND;
      --
      gn_target_cnt := XXCMM003A14C_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      lb_xxcust_acnt_upd_cnt_flg := FALSE;
      lb_xxcust_acnt_ins_cnt_flg := FALSE;
      --
      -- ===============================
      -- A-3.SAVE POINT 発行
      -- ===============================
      lv_step := 'A-3';
      SAVEPOINT svpt_cust_rec;
      --
      IF (XXCMM003A14C_rec.rec_ins_flg = cv_flag_no) THEN
        --
        IF (      (XXCMM003A14C_rec.now_final_call_date IS NULL)
              OR  (XXCMM003A14C_rec.task_final_call_date > XXCMM003A14C_rec.now_final_call_date)) THEN
          -- ===============================
          -- A-4.最終訪問日更新
          -- ===============================
          lv_step := 'A-4';
          prc_upd_xxcmm_cust_accounts(
            XXCMM003A14C_rec,   -- カーソルレコード
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
          END IF;
        --
        END IF;
        -- 顧客追加情報更新件数カウント
        IF (ln_err_cnt = 0) THEN
          gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt + 1;
          lb_xxcust_acnt_upd_cnt_flg := TRUE;
        END IF;
      ELSE
        -- ===============================
        -- A-5.顧客追加情報登録
        -- ===============================
        lv_step := 'A-5';
        prc_ins_xxcmm_cust_accounts(
          XXCMM003A14C_rec,   -- カーソルレコード
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
          -- 顧客追加情報登録件数カウント
          gn_xx_cust_acnt_ins_cnt := gn_xx_cust_acnt_ins_cnt + 1;
          lb_xxcust_acnt_ins_cnt_flg := TRUE;
        END IF;
        --
      END IF;
      --
      -- 10:MC候補
-- 2009/03/02 modify start
      IF (XXCMM003A14C_rec.cust_status = cv_cust_status_mc_cnd) --THEN
        AND (ln_err_cnt = 0)
      THEN
-- 2009/03/02 modify end
        -- ===============================
        -- A-6.顧客ステータス更新
        -- ===============================
        lv_step := 'A-6';
        prc_upd_hz_parties(
          XXCMM003A14C_rec,   -- カーソルレコード
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
          -- 顧客追加情報更新件数カウント戻し
          IF (lb_xxcust_acnt_upd_cnt_flg = TRUE) THEN
            gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt - 1;
          END IF;
          -- 顧客追加情報登録件数カウント戻し
          IF (lb_xxcust_acnt_ins_cnt_flg = TRUE) THEN
            gn_xx_cust_acnt_ins_cnt := gn_xx_cust_acnt_ins_cnt - 1;
          END IF;
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
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod start by Shigeto.Niki
--        gn_error_cnt := gn_error_cnt + ln_err_cnt;
        gn_warn_cnt := gn_warn_cnt + ln_err_cnt;
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod end by Shigeto.Niki
      END IF;
      --
      -- エラー検出時、SAVEPOINTまでROLLBACK
      IF (ln_err_cnt > 0) THEN
        -- ===============================
        -- A-9.ROLLBACK発行処理
        -- ===============================
        lv_step := 'A-9';
        ROLLBACK TO svpt_cust_rec;
        --
      END IF;
      --
    END LOOP;
    --
    -- カーソルクローズ
    CLOSE XXCMM003A14C_cur;
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
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 障害E_T4_00135 mod end by Shigeto.Niki
    END IF;
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    -- *** パラメータエラー例外ハンドラ ***
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      -- カーソルクローズ
      IF XXCMM003A14C_cur%ISOPEN THEN
        CLOSE  XXCMM003A14C_cur;
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
      IF XXCMM003A14C_cur%ISOPEN THEN
        CLOSE XXCMM003A14C_cur;
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
      IF XXCMM003A14C_cur%ISOPEN THEN
        CLOSE XXCMM003A14C_cur;
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
-- 2009/11/09 Ver1.5 障害E_T4_00135 add start by Shigeto.Niki
    cv_skip_rec_msg   CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
-- 2009/11/09 Ver1.5 障害E_T4_00135 add end by Shigeto.Niki
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
    --顧客追加情報登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00034,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_xx_cust_acnt_ins_cnt),
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
-- 2009/11/09 Ver1.5 障害E_T4_00135 add start by Shigeto.Niki
    --
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_skip_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
-- 2009/11/09 Ver1.5 障害E_T4_00135 add end by Shigeto.Niki
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
END xxcmm003a14c;
/
