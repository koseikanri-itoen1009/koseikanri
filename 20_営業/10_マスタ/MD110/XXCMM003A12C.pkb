create or replace PACKAGE BODY XXCMM003A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A12C(body)
 * Description      : 当機能は、拠点分割により顧客移行情報に入力された顧客に紐付く
 *                    拠点変更情報を抽出し、対応する顧客追加情報の予約拠点情報項目へ
 *                    連携する機能です。
 * MD.050           : 拠点更新データ連携 MD050_CMM_003_A12
 * Version          : 1.1
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_xxcok_cust_shift_info   顧客移行情報テーブル拠点分割情報連携フラグ更新(A-4)
 *  prc_upd_xxcmm_cust_accounts     顧客追加情報テーブル予約拠点情報更新(A-3)
 *  upd_for_cust_shift_cancel       顧客移行 変更・取消し処理(A-6)
 *  prc_init                        初期処理(A-1)
 *  submain                         メイン処理プロシージャ(A-2:処理対象データ抽出)
 *                                    ・prc_init
 *                                    ・upd_for_cust_shift_cancel
 *                                    ・prc_upd_xxcmm_cust_accounts
 *                                    ・prc_upd_xxcok_cust_shift_info
 *  main                            コンカレント実行ファイル登録プロシージャ(A-5:終了処理)
 *                                    ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   SCS Okuyama      新規作成
 *  2020/12/22    1.1   SCSK Yoshino     E_本稼動_16384 確定取消し対応
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
  cv_cust_shift_status_act  CONSTANT VARCHAR2(1) := 'A';  -- 顧客移行情報ステータス（確定済）
  cv_base_split_flag_on     CONSTANT VARCHAR2(1) := '1';  -- 拠点分割連携フラグ（連携済）
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD START
  cv_resv_selling_clr_flag  CONSTANT VARCHAR2(1) := '1';  -- 予約売上消去フラグ（予約消去対象）
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD END
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_bullet             CONSTANT VARCHAR2(2) := '・';
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
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD START
  gn_cust_shift_cnt NUMBER ;                  -- 顧客移行 変更・取消し対象件数
  gd_process_date  DATE ;                     -- 業務処理日付
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD END
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt        EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt     EXCEPTION;
  global_check_lock_expt     EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';               -- アドオン：共通・IF領域
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';               -- アドオン：マスタ・マスタ領域
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A12C';        -- パッケージ名
  -- メッセージコード
  cv_msg_xxccp_90008        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';    -- ｺﾝｶﾚﾝﾄﾊﾟﾗﾒｰﾀ無し
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';    -- ｼｽﾃﾑｴﾗｰ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';    -- 対象データ無し
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';    -- ロックエラー
  cv_msg_xxcmm_00300        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00300';    -- データ更新エラー

  -- メッセージトークン
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';            -- テーブル名
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';             -- 顧客コード
  cv_tkn_rsv_base_act_date  CONSTANT VARCHAR2(13) := 'BASE_ACT_DATE';       -- 顧客移行日
  cv_tkn_rsv_base_cd        CONSTANT VARCHAR2(7)  := 'BASE_CD';             -- 新担当拠点コード
  --
  cv_tbl_nm_xcsi            CONSTANT VARCHAR2(12) := '顧客移行情報';        -- XXCOK_CUST_SHIFT_INFO
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '顧客追加情報';        -- XXCMM_CUST_ACCOUNTS
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- 日付フォーマット
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  --
  -- 拠点更新データ連携対象取得カーソル
  --
  CURSOR xxcmm003A12c_cur
  IS
    SELECT
      xcsi.cust_code,             -- 顧客コード
      xcsi.cust_shift_date,       -- 顧客移行日
      xcsi.new_base_code,         -- 新担当拠点コード
      xcac.ROWID  AS  xcac_rowid, -- レコードID（顧客追加）
      xcsi.ROWID  AS  xcsi_rowid  -- レコードID（顧客移行）
    FROM
      xxcok_cust_shift_info       xcsi,   -- 顧客移行情報テーブル
      hz_cust_accounts            hcac,   -- 顧客マスタテーブル
      xxcmm_cust_accounts         xcac    -- 顧客追加情報テーブル
    WHERE
          hcac.cust_account_id    = xcac.customer_id
      AND xcsi.cust_code          = hcac.account_number
      AND xcsi.status             = cv_cust_shift_status_act
      AND xcsi.base_split_flag    IS NULL
    FOR UPDATE OF xcsi.cust_code, xcac.customer_id NOWAIT
    ;
--
--
--
--
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD START
  /**********************************************************************************
   * Procedure Name   : upd_for_cust_shift_cancel
   * Description      : 顧客移行 変更・取消し処理(A-6)
   ***********************************************************************************/
  PROCEDURE upd_for_cust_shift_cancel(
    ov_errbuf     OUT VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_for_cust_shift_cancel'; -- プログラム名
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
--    lv_step       VARCHAR2(10);     -- ステップ
--
    -- ***  顧客移行情報カーソル ***
--
  CURSOR l_cust_shift_cur
  IS
    SELECT xcsi.cust_code     AS cust_code     -- 顧客コード
          ,xcsi.ROWID         AS xcsi_rowid    -- レコードID（顧客移行）
          ,xcac.ROWID         AS xcac_rowid    -- レコードID（顧客追加）
    FROM   xxcok_cust_shift_info       xcsi    -- 顧客移行情報テーブル
          ,xxcmm_cust_accounts         xcac    -- 顧客追加情報テーブル
    WHERE  xcsi.resv_selling_clr_flag = cv_resv_selling_clr_flag
    AND    xcsi.cust_shift_date       > gd_process_date
    AND    xcsi.cust_code             = xcac.customer_code
    FOR UPDATE OF xcsi.cust_code , xcac.customer_code NOWAIT
    ;
--
  l_cust_shift_rec    l_cust_shift_cur%ROWTYPE;
--
  BEGIN
--    lv_step := 'A-6-1';
    gn_cust_shift_cnt := 0 ;              -- 顧客移行 変更・取消し件数
    OPEN l_cust_shift_cur ;
    --
    LOOP
      -- 処理対象データ・カーソルフェッチ
      FETCH l_cust_shift_cur INTO l_cust_shift_rec ;
      EXIT WHEN l_cust_shift_cur%NOTFOUND;
--
--      lv_step := 'A-6-3';
      -- 顧客追加情報更新
      UPDATE xxcmm_cust_accounts xcac                                 -- 顧客追加情報テーブル
      SET    xcac.rsv_sale_base_code     = NULL                       -- 予約売上拠点コード
            ,xcac.rsv_sale_base_act_date = NULL                       -- 予約売上拠点有効開始日
            ,xcac.last_updated_by        = cn_last_updated_by         -- 最終更新者
            ,xcac.last_update_date       = cd_last_update_date        -- 最終更新日
            ,xcac.last_update_login      = cn_last_update_login       -- 最終更新ログイン
            ,xcac.request_id             = cn_request_id              -- 要求ID
            ,xcac.program_application_id = cn_program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
            ,xcac.program_id             = cn_program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
            ,xcac.program_update_date    = cd_program_update_date     -- プログラム更新日
      WHERE xcac.ROWID                   = l_cust_shift_rec.xcac_rowid ;
--
--      lv_step := 'A-6-5';
--      -- 顧客移行情報テーブル
      UPDATE xxcok_cust_shift_info       xcsi                         -- 顧客移行情報テーブル
      SET    xcsi.resv_selling_clr_flag  = NULL                       -- 予約売上消去フラグ
            ,xcsi.base_split_flag        = NULL                       -- 拠点分割情報連携フラグ
            ,xcsi.last_updated_by        = cn_last_updated_by         -- 最終更新者
            ,xcsi.last_update_date       = cd_last_update_date        -- 最終更新日
            ,xcsi.last_update_login      = cn_last_update_login       -- 最終更新ログイン
            ,xcsi.request_id             = cn_request_id              -- 要求ID
            ,xcsi.program_application_id = cn_program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
            ,xcsi.program_id             = cn_program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
            ,xcsi.program_update_date    = cd_program_update_date     -- プログラム更新日
      WHERE  xcsi.ROWID                  = l_cust_shift_rec.xcsi_rowid ;
--
      gn_cust_shift_cnt := gn_cust_shift_cnt + 1 ;                    -- 顧客移行 変更・取消し件数カウントアップ
    END LOOP ;
--
    CLOSE l_cust_shift_cur;
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ***  ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      IF l_cust_shift_cur%ISOPEN THEN
        CLOSE  l_cust_shift_cur;
      END IF;
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00008,     -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,        -- トークンコード1
                        iv_token_value1 =>  (cv_tbl_nm_xcsi)        -- トークン値1
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- 処理ステータスセット
      ov_retcode  :=  cv_status_error;
      -- エラー件数設定
      gn_error_cnt := 1 ;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- アプリケーション短縮名
                      iv_name         =>  cv_msg_xxccp_91003        -- メッセージコード
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      RAISE global_process_expt;
--
--#####################################  固定部 END   ##########################################
--
  END upd_for_cust_shift_cancel;
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD END
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcok_cust_shift_info
   * Description      : 顧客移行情報テーブル拠点分割情報連携フラグ更新(A-4)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcok_cust_shift_info(
    iv_rec        IN  xxcmm003A12c_cur%ROWTYPE,   -- 処理対象データレコード
    ov_errbuf     OUT VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_xxcok_cust_shift_info'; -- プログラム名
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
    -- 顧客移行情報テーブル拠点分割情報連携フラグ更新SQL文
    UPDATE
      xxcok_cust_shift_info         xcsi                        -- 顧客移行情報
    SET
      xcsi.base_split_flag        = cv_base_split_flag_on,      -- 拠点分割情報連携フラグ
      xcsi.last_updated_by        = cn_last_updated_by,         -- 最終更新者
      xcsi.last_update_date       = cd_last_update_date,        -- 最終更新日
      xcsi.last_update_login      = cn_last_update_login,       -- 最終更新ログイン
      xcsi.request_id             = cn_request_id,              -- 要求ID
      xcsi.program_application_id = cn_program_application_id,  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      xcsi.program_id             = cn_program_id,              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      xcsi.program_update_date    = cd_program_update_date      -- プログラム更新日
    WHERE
      xcsi.rowid  = iv_rec.xcsi_rowid                           -- レコードID（顧客移行）
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
                        iv_name         =>  cv_msg_xxcmm_00300,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,            -- トークンコード1
                        iv_token_value1 =>  cv_tbl_nm_xcsi,             -- トークン値1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- トークンコード2
                        iv_token_value2 =>  iv_rec.cust_code,           -- トークン値2
                        iv_token_name3  =>  cv_tkn_rsv_base_act_date,   -- トークンコード3
                        iv_token_value3 =>  TO_CHAR(iv_rec.cust_shift_date, cv_date_fmt), -- トークン値3
                        iv_token_name4  =>  cv_tkn_rsv_base_cd,         -- トークンコード4
                       iv_token_value4  =>  iv_rec.new_base_code        -- トークン値4
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
  END prc_upd_xxcok_cust_shift_info;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : 顧客追加情報テーブル予約拠点情報更新(A-3)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  xxcmm003A12c_cur%ROWTYPE,   -- 処理対象データレコード
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
      xxcmm_cust_accounts         xcac                          -- 顧客追加情報
    SET
      xcac.rsv_sale_base_act_date = iv_rec.cust_shift_date,     -- 予約売上拠点有効開始日
      xcac.rsv_sale_base_code     = iv_rec.new_base_code,       -- 予約売上拠点コード
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
                        iv_name         =>  cv_msg_xxcmm_00300,         -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,            -- トークンコード1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- トークン値1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- トークンコード2
                        iv_token_value2 =>  iv_rec.cust_code,           -- トークン値2
                        iv_token_name3  =>  cv_tkn_rsv_base_act_date,   -- トークンコード3
                        iv_token_value3 =>  TO_CHAR(iv_rec.cust_shift_date, cv_date_fmt), -- トークン値3
                        iv_token_name4  =>  cv_tkn_rsv_base_cd,         -- トークンコード4
                        iv_token_value4 =>  iv_rec.new_base_code        -- トークン値4
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
    lv_step       VARCHAR2(10);     -- ステップ
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
    -- コンカレント・パラメータのログ出力
    -- メッセージセット
    lv_errmsg   :=  xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,    -- アプリケーション短縮名
                      iv_name         =>  cv_msg_xxccp_90008  -- メッセージコード
                    );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_errmsg --パラメータなしメッセージ
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => lv_errmsg --パラメータなしメッセージ
    );
    --空行挿入
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
    );

-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD START
    -- 業務日付の取得
    gd_process_date := xxccp_common_pkg2.get_process_date ;
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD END

--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- アプリケーション短縮名
                      iv_name         =>  cv_msg_xxccp_91003        -- メッセージコード
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      RAISE global_process_expt;
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
    xxcmm003A12c_rec    xxcmm003A12c_cur%ROWTYPE;

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
      lv_errbuf,    -- エラー・メッセージ           --# 固定 #
      lv_retcode,   -- リターン・コード             --# 固定 #
      lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD START
    -- ===============================
    -- A-6.顧客移行 変更・取消し処理
    -- ===============================
    lv_step := 'A-6';

      upd_for_cust_shift_cancel(
        lv_errbuf,    -- エラー・メッセージ           --# 固定 #
        lv_retcode,   -- リターン・コード             --# 固定 #
        lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
      );
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD END
    -- ===============================
    -- A-2.処理対象データ抽出
    -- ===============================
    lv_step := 'A-2';
    OPEN xxcmm003A12c_cur;
    --
    LOOP
      -- 処理対象データ・カーソルフェッチ
      FETCH xxcmm003A12c_cur INTO xxcmm003A12c_rec;
      EXIT WHEN xxcmm003A12c_cur%NOTFOUND;
      --
      gn_target_cnt := xxcmm003A12c_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      --
      -- ===============================
      -- A-3.顧客追加情報テーブル予約拠点情報更新
      -- ===============================
      lv_step := 'A-3';
      prc_upd_xxcmm_cust_accounts(
        xxcmm003A12c_rec,   -- カーソルレコード
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
      -- ===============================
      -- A-4.顧客移行情報テーブル拠点分割情報連携フラグ更新
      -- ===============================
      lv_step := 'A-4';
      prc_upd_xxcok_cust_shift_info(
        xxcmm003A12c_rec,   -- カーソルレコード
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
    CLOSE xxcmm003A12c_cur;
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
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      -- カーソルクローズ
      IF xxcmm003A12c_cur%ISOPEN THEN
        CLOSE  xxcmm003A12c_cur;
      END IF;
      -- メッセージセット
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- アプリケーション短縮名
                        iv_name         =>  cv_msg_xxcmm_00008,     -- メッセージコード
                        iv_token_name1  =>  cv_tkn_ng_table,        -- トークンコード1
                        iv_token_value1 =>  (cv_tbl_nm_xcac || cv_msg_bullet || cv_tbl_nm_xcsi) -- トークン値1
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
      IF xxcmm003A12c_cur%ISOPEN THEN
        CLOSE xxcmm003A12c_cur;
      END IF;
      -- メッセージセット
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                      cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf,
                      1,
                      5000
                    );
      -- 処理ステータスセット
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF xxcmm003A12c_cur%ISOPEN THEN
        CLOSE xxcmm003A12c_cur;
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
    retcode       OUT VARCHAR2      -- リターン・コード    --# 固定 #
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
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD START
    cv_cust_shift_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMM1-10501'; -- 顧客移行 変更・取消件数メッセージ
    cv_app_sht_nam_xxcmm CONSTANT VARCHAR2(10)  := 'XXCMM';            -- アドオン：共通・IF領域
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD END
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
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      IF (LENGTHB(TRIM(lv_errmsg)) > 0) THEN
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => LTRIM(lv_errmsg)   --ユーザー・エラーメッセージ
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => LTRIM(lv_errmsg)   --ユーザー・エラーメッセージ
        );
      END IF;
      IF (LENGTHB(TRIM(lv_errbuf)) > 0) THEN
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => LTRIM(lv_errbuf)   --エラーメッセージ
        );
      END IF;
    END IF;
    --空行挿入
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt + gn_cust_shift_cnt )
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
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
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
--
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD START
--
    --取消し件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_sht_nam_xxcmm
                    ,iv_name         => cv_cust_shift_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_cust_shift_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
--
-- 2020/12/22 Ver.1.1 [E_本稼動_16834] SCSK K.Yoshino ADD END
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
    --空白行出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
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
END XXCMM003A12C;
/
