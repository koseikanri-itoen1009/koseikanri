create or replace PACKAGE BODY XXCOI009A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A04R(body)
 * Description      : 入出庫ジャーナルチェックリスト
 * MD.050           : 入出庫ジャーナルチェックリスト MD050_COI_009_A04
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ワークテーブルデータ削除(A-8)
 *  svf_request            SVF起動(A-7)
 *  upd_hht_data           出力フラグ更新(A-6)
 *  ins_work_zero          ワークテーブルデータ登録(0件)(A-5)
 *  ins_work               ワークテーブルデータ登録(A-4)
 *  get_hht_data           HHT入出庫データ取得(A-3)
 *  get_base_data          拠点情報取得処理(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   SCS.Tsuboi       新規作成
 *  2009/04/02    1.1   H.Sasaki         [T1_0002]VD預け先の顧客コード出力
 *  2009/05/15    1.2   H.Sasaki         [T1_0785]帳票出力のソート項目の設定値を変更
 *  2009/06/03    1.3   H.Sasaki         [T1_1202]保管場所マスタの結合条件に在庫組織IDを追加
 *  2009/06/19    1.4   H.Sasaki         [I_E_453][T1_1090]HHT入出庫取得データを変更
 *  2009/07/02    1.5   H.Sasaki         [0000275]パフォーマンス改善
 *  2009/07/10    1.6   H.Sasaki         [0000459]入出庫逆転データの出力条件を変更
 *  2009/09/08    1.7   H.Sasaki         [0001266]OPM品目アドオンの版管理対応
 *  2009/12/15    1.8   H.Sasaki         [E_本稼動_00256]起動パラメータの年月日From-Toを設定
 *  2009/12/25    1.9   N.Abe            [E_本稼動_00222]顧客名称取得方法修正
 *                                       [E_本稼動_00610]パフォーマンス改善
 *  2011/04/08    1.10  S.Ochiai         [E_本稼動_06588]レコード種別'21'(新規ベンダ基準在庫)追加対応
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
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  lock_expt                 EXCEPTION;    -- ロック取得エラー
  get_no_data_expt          EXCEPTION;    -- 取得データ0件
  svf_request_err_expt      EXCEPTION;    -- SVF起動APIエラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCOI009A04R';   -- パッケージ名
  cv_app_name          CONSTANT VARCHAR2(5)   := 'XXCOI';          -- アプリケーション短縮名
  cv_0                 CONSTANT VARCHAR2(1)   := '0';              -- 定数
  cv_1                 CONSTANT VARCHAR2(1)   := '1';              -- 定数
  cv_2                 CONSTANT VARCHAR2(1)   := '2';              -- 定数
  cv_3                 CONSTANT VARCHAR2(1)   := '3';              -- 定数
  cv_log               CONSTANT VARCHAR2(3)   := 'LOG';            -- コンカレントヘッダ出力先
  cv_yes               CONSTANT VARCHAR2(3)   := 'Y';              -- 定数Y
  cv_no                CONSTANT VARCHAR2(3)   := 'N';              -- 定数N
--
  -- メッセージ
  cv_msg_xxcoi00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- 在庫組織コード取得エラー
  cv_msg_xxcoi00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- 在庫組織ID取得エラー
  cv_msg_xxcoi00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0件メッセージ
  cv_msg_xxcoi10004  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10004';   -- ロック取得エラーメッセージ(HHT入出庫一時表)
  cv_msg_xxcoi00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- APIエラー
  cv_msg_xxcoi00011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';   -- 業務日付取得エラー
  cv_msg_xxcoi10005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10005';   -- ロック取得エラーメッセージ(入出庫ｼﾞｬｰﾅﾙ帳票ワークテーブル)
  cv_msg_xxcoi10092  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10092';   -- 所属拠点取得エラー
  cv_msg_xxcoi10067  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10067';   -- パラメータ.年月日メッセージ
  cv_msg_xxcoi10307  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10307';   -- パラメータ.出力区分メッセージ
  cv_msg_xxcoi10308  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10308';   -- パラメータ.拠点メッセージ
  cv_msg_xxcoi10309  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10309';   -- パラメータ.正負データ区分メッセージ
  cv_msg_xxcoi10310  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10310';   -- パラメータ.伝票区分メッセージ
  cv_msg_xxcoi10311  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10311';   -- パラメータ出力区分名取得エラー
  cv_msg_xxcoi10312  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10312';   -- パラメータ伝票区分名取得エラー
  cv_msg_xxcoi10313  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10313';   -- パラメータ正負データ区分名取得エラー
-- == 2009/12/15 V1.8 Added START ===============================================================
  cv_msg_xxcoi10164  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10164';   -- パラメータ日付（From）値メッセージ
  cv_msg_xxcoi10165  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10165';   -- パラメータ日付（To）値メッセージ
  cv_msg_xxcoi10337  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10337';   -- 日付パラメータ整合性エラーメッセージ
-- == 2009/12/15 V1.8 Added END   ===============================================================
--
  -- トークン名
  cv_token_pro                CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code           CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_output_kbn         CONSTANT VARCHAR2(30) := 'P_OUTPUT_KBN';
  cv_token_invoice_kbn        CONSTANT VARCHAR2(30) := 'P_INVOICE_KBN';
  cv_token_date               CONSTANT VARCHAR2(30) := 'P_DATE';
  cv_token_base_code          CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_token_reverse_kbn        CONSTANT VARCHAR2(30) := 'P_REVERSE_KBN';
  cv_token_location_code      CONSTANT VARCHAR2(20) := 'LOCATION_CODE';
-- == 2009/12/15 V1.8 Added START ===============================================================
  cv_tkn_msg_10164            CONSTANT VARCHAR2(30) :=  'P_DATE_FROM';
  cv_tkn_msg_10165            CONSTANT VARCHAR2(30) :=  'P_DATE_TO';
-- == 2009/12/15 V1.8 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE gr_param_rec  IS RECORD(
      output_kbn        VARCHAR2(1)       -- 01 : 出力区分      (必須)
     ,invoice_kbn       VARCHAR2(2)       -- 02 : 伝票区分      (任意)
     ,target_date       VARCHAR2(20)      -- 03 : 年月日        (必須)
-- == 2009/12/15 V1.8 Added START ===============================================================
     ,target_date_to    VARCHAR2(20)      -- 年月日（至）
-- == 2009/12/15 V1.8 Added END   ===============================================================
     ,out_base_code     VARCHAR2(4)       -- 04 : 拠点          (任意)
     ,reverse_kbn       VARCHAR2(1)       -- 05 : 正負データ出力区分 (必須)
     ,output_dpt        VARCHAR2(1)       -- 06 : 帳票出力場所  (必須)
    );
--
  -- 拠点情報格納用レコード変数
  TYPE gr_base_num_rec IS RECORD
    (
      hca_cust_num                   hz_cust_accounts.account_number%TYPE    -- 拠点コード
    );
--
  --  拠点情報格納用テーブル
  TYPE gt_base_num_ttype IS TABLE OF gr_base_num_rec INDEX BY BINARY_INTEGER;
--
  -- HHT情報格納用レコード変数
-- == 2009/06/19 V1.4 Modified START ===============================================================
--  TYPE gr_hht_info_rec IS RECORD(
--      transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE       -- HHT入出庫テーブルID
--    , interface_id               xxcoi_hht_inv_transactions.interface_id%TYPE         -- インターフェース
--    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE    -- 出庫拠点コード
--    , outside_base_name          hz_cust_accounts.account_name%TYPE                   -- 出庫拠点名
--    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE  -- 出庫側保管場所コード
--    , outside_subinv_name        mtl_secondary_inventories.description%TYPE           -- 出庫側保管場所名
--    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE         -- 伝票区分
--    , invoice_type_name          fnd_lookup_values.meaning%TYPE                       -- 伝票区分名
--    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE   -- 入庫側保管場所コード
--    , inside_subinv_name         mtl_secondary_inventories.description%TYPE           -- 入庫側保管場所コード
--    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE            -- 商品コード
--    , item_name                  xxcmn_item_mst_b.item_short_name%TYPE                -- 商品名
--    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE        -- ケース数
--    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE     -- ケース入数
--    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE             -- 本数
--    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE       -- 総数
--    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE           -- 伝票No
--  );
  TYPE gr_hht_info_rec IS RECORD(
      transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE       -- HHT入出庫テーブルID
    , interface_id               xxcoi_hht_inv_transactions.interface_id%TYPE         -- インターフェース
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE    -- 出庫拠点コード
    , outside_base_name          hz_cust_accounts.account_name%TYPE                   -- 出庫拠点名
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE         -- 出庫側コード
    , outside_cust_code          xxcoi_hht_inv_transactions.outside_cust_code%TYPE    -- 出庫側顧客コード
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE  -- 出庫側保管場所コード
    , invoice_type               fnd_lookup_values.attribute11%TYPE                   -- 伝票区分
    , invoice_type_name          fnd_lookup_values.meaning%TYPE                       -- 伝票区分名
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE          -- 入庫側コード
    , inside_cust_code           xxcoi_hht_inv_transactions.inside_cust_code%TYPE     -- 入庫側顧客コード
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE   -- 入庫側保管場所コード
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE            -- 商品コード
    , item_name                  xxcmn_item_mst_b.item_short_name%TYPE                -- 商品名
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE        -- ケース数
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE     -- ケース入数
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE             -- 本数
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE       -- 総数
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE           -- 伝票No
-- == 2009/12/15 V1.8 Added START ===============================================================
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE         -- 伝票日付
-- == 2009/12/15 V1.8 Added END   ===============================================================
  );
-- == 2009/06/19 V1.4 Modified END   ===============================================================
--
  --  HHT情報格納用テーブル
  TYPE gt_hht_info_ttype IS TABLE OF gr_hht_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE;                                             -- 業務日付
  gv_base_code              hz_cust_accounts.account_number%TYPE;             -- 拠点コード
  gv_output_kbn_name        fnd_lookup_values.meaning%TYPE;                   -- 出力区分
  gv_out_base_name          hz_cust_accounts.account_name%TYPE;               -- 出力拠点名
  -- カウンタ
  gn_base_cnt               NUMBER;                                           -- 拠点コード件数
  gn_base_loop_cnt          NUMBER;                                           -- 拠点コードループカウンタ
  gn_hht_info_cnt           NUMBER;                                           -- HHT入出庫情報件数
  gn_hht_info_loop_cnt      NUMBER;                                           -- HHT入出庫情報ループカウンタ
  gn_organization_id        mtl_parameters.organization_id%TYPE;              -- 在庫組織ID
  --
  gr_param                  gr_param_rec;
  gt_base_num_tab           gt_base_num_ttype;
  gt_hht_info_tab           gt_hht_info_ttype;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ワークテーブルデータ削除(A-8)
   ***********************************************************************************/
  PROCEDURE del_work(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_work'; -- プログラム名
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
-- == 2009/12/25 V1.9 Deleted START ===============================================================
--    -- ワークテーブルロック
--    CURSOR del_xrj_tbl_cur
--    IS
--      SELECT 'X'
--      FROM   xxcoi_rep_shipstore_jour_list xrj     -- 入出庫ジャーナルチェックリスト帳票ワークテーブル
--      WHERE  xrj.request_id = cn_request_id        -- 要求ID
--      FOR UPDATE OF xrj.request_id NOWAIT
--    ;
----
--    -- *** ローカル・レコード ***
--    del_xrj_tbl_rec  del_xrj_tbl_cur%ROWTYPE;
-- == 2009/12/25 V1.9 Deleted END   ===============================================================
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
-- == 2009/12/25 V1.9 Deleted START ===============================================================
--    -- カーソルオープン
--    OPEN del_xrj_tbl_cur;
----
--    <<del_xrj_tbl_cur_loop>>
--    LOOP
--      -- レコード読込
--      FETCH del_xrj_tbl_cur INTO del_xrj_tbl_rec;
--      EXIT WHEN del_xrj_tbl_cur%NOTFOUND;
--
-- == 2009/12/25 V1.9 Deleted END   ===============================================================
      -- 入出庫ジャーナルチェックリスト帳票ワークテーブルの削除
      DELETE
      FROM   xxcoi_rep_shipstore_jour_list xrj        -- 入出庫ジャーナルチェックリスト帳票ワークテーブル
      WHERE  xrj.request_id = cn_request_id           -- 要求ID
      ;
-- == 2009/12/25 V1.9 Deleted START ===============================================================
----
--    END LOOP del_xrj_tbl_cur_loop;
----
--    -- カーソルクローズ
--    CLOSE del_xrj_tbl_cur;
-- == 2009/12/25 V1.9 Deleted END   ===============================================================
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- == 2009/12/25 V1.9 Deleted START ===============================================================
--    -- ロック取得エラー
--    WHEN lock_expt THEN
--      -- カーソルがOPENしている場合
--      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrj_tbl_cur;
--      END IF;
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name
--                      , iv_name         => cv_msg_xxcoi10005
--                    );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
-- == 2009/12/25 V1.9 Deleted END   ===============================================================
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- == 2009/12/25 V1.9 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrj_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.9 Deleted END   ===============================================================
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- == 2009/12/25 V1.9 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrj_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.9 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- == 2009/12/25 V1.9 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xrj_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrj_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.9 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_work;
--
  /**********************************************************************************
   * Procedure Name   : svf_request
   * Description      : SVF起動(A-7)
   ***********************************************************************************/
  PROCEDURE svf_request(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_request'; -- プログラム名
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
    cv_output_mode  CONSTANT VARCHAR2(1)  := '1';                    -- 出力区分(PDF出力)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI009A04S.xml';     -- フォーム様式ファイル名
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI009A04S.vrq';     -- クエリー様式ファイル名
    cv_api_name     CONSTANT VARCHAR2(7)  := 'SVF起動';              -- SVF起動API名
--
    -- トークン名
    cv_token_name_1  CONSTANT VARCHAR2(30) := 'API_NAME';
--
    -- *** ローカル変数 ***
    ld_date       VARCHAR2(8);   -- 日付
    lv_file_name  VARCHAR2(100); -- 出力ファイル名
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
    -- 日付書式変換
    ld_date := TO_CHAR( cd_creation_date, 'YYYYMMDD' );
--
    -- 出力ファイル名
    lv_file_name := cv_pkg_name || ld_date || TO_CHAR(cn_request_id);
--
    --SVF起動処理
      xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode      => lv_retcode             -- リターンコード
     ,ov_errbuf       => lv_errbuf              -- エラーメッセージ
     ,ov_errmsg       => lv_errmsg              -- ユーザー・エラーメッセージ
     ,iv_conc_name    => cv_pkg_name            -- コンカレント名
     ,iv_file_name    => lv_file_name           -- 出力ファイル名
     ,iv_file_id      => cv_pkg_name            -- 帳票ID
     ,iv_output_mode  => cv_output_mode         -- 出力区分
     ,iv_frm_file     => cv_frm_file            -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_vrq_file            -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id      -- ORG_ID
     ,iv_user_name    => fnd_global.user_name   -- ログイン・ユーザ名
     ,iv_resp_name    => fnd_global.resp_name   -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                   -- 文書名
     ,iv_printer_name => NULL                   -- プリンタ名
     ,iv_request_id   => cn_request_id          -- 要求ID
     ,iv_nodata_msg   => NULL                   -- データなしメッセージ
    );
--
    --==============================================================
    --エラーメッセージ出力
    --==============================================================
    IF lv_retcode <> cv_status_normal THEN
      RAISE svf_request_err_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** SVF起動APIエラー ***
    WHEN svf_request_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                    , iv_name         => cv_msg_xxcoi00010
                    , iv_token_name1  => cv_token_name_1
                    , iv_token_value1 => cv_api_name
                   );
      ov_errmsg  := lv_errmsg;
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
  END svf_request;
--
  /**********************************************************************************
   * Procedure Name   : upd_hht_data
   * Description      : 出力フラグ更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_hht_data(
    gn_hht_info_loop_cnt   IN NUMBER,        -- HHT入出庫データ情報ループカウンタ
    ov_errbuf              OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg              OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_data'; -- プログラム名
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
    lv_transaction_id      xxcoi_hht_inv_transactions.transaction_id%TYPE;
--
    -- *** ローカル・カーソル ***
    -- HHT入出庫一時表テーブルロック
    CURSOR upd_hht_tbl_cur
    IS
      SELECT 'X'                       AS output_flag                                   -- 出力区分
      FROM   xxcoi_hht_inv_transactions xhit                                            -- HHT入出庫一時表
      WHERE  xhit.transaction_id = gt_hht_info_tab( gn_hht_info_loop_cnt ).transaction_id
      FOR UPDATE OF xhit.output_flag NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_hht_tbl_rec  upd_hht_tbl_cur%ROWTYPE;
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
    -- カーソルオープン
    OPEN upd_hht_tbl_cur;
--
    -- レコード読込
    FETCH upd_hht_tbl_cur INTO upd_hht_tbl_rec;
--
    --HHT入出庫一時表の更新
    UPDATE xxcoi_hht_inv_transactions xhit
    SET    xhit.output_flag = cv_yes
         , xhit.last_updated_by        = cn_last_updated_by                             -- 最終更新者
         , xhit.last_update_date       = cd_last_update_date                            -- 最終更新日
         , xhit.last_update_login      = cn_last_update_login                           -- 最終更新ユーザ
         , xhit.request_id             = cn_request_id                                  -- 要求ID
         , xhit.program_application_id = cn_program_application_id                      -- プログラムアプリケーションID
         , xhit.program_id             = cn_program_id                                  -- プログラムID
         , xhit.program_update_date    = cd_program_update_date                         -- プログラム更新日
    WHERE  xhit.transaction_id  = gt_hht_info_tab( gn_hht_info_loop_cnt ).transaction_id
    ;
--
    -- カーソルクローズ
    CLOSE upd_hht_tbl_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                      , iv_name         => cv_msg_xxcoi10004
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( upd_hht_tbl_cur%ISOPEN ) THEN
        CLOSE upd_hht_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_hht_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_zero
   * Description      : ワークテーブルデータ登録(0件)(A-5)
   ***********************************************************************************/
  PROCEDURE ins_work_zero(
    iv_nodata_msg              IN  VARCHAR2,     -- ゼロ件メッセージ
    ov_errbuf                  OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_zero'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --入出庫ジャーナルチェックリスト帳票ワークテーブル登録処理
    INSERT INTO xxcoi_rep_shipstore_jour_list(
        interface_id
       ,target_term
       ,output_kbn
       ,outside_base_code
       ,outside_base_name
       ,outside_subinv_code
       ,outside_subinv_name
       ,invoice_type
       ,invoice_type_name
       ,inside_subinv_code
       ,inside_subinv_name
       ,item_code
       ,item_name
       ,case_quantity
       ,case_in_quantity
       ,quantity
       ,total_quantity
       ,invoice_no
       ,nodata_msg
       --WHOカラム
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
     )VALUES(
        NULL
       ,SUBSTRB(gr_param.target_date,1,10)       -- 対象期間
       ,gv_output_kbn_name                       -- 出力区分
       ,gr_param.out_base_code                   -- 拠点コード
       ,SUBSTRB(gv_out_base_name,1,8)            -- 拠点名
       ,NULL                                     -- 出庫側保管場所コード
       ,NULL                                     -- 出庫側保管場所名
       ,NULL                                     -- 伝票区分
       ,NULL                                     -- 伝票区分名
       ,NULL                                     -- 出庫側保管場所コード
       ,NULL                                     -- 出庫側保管場所名
       ,NULL                                     -- 商品コード
       ,NULL                                     -- 商品名
       ,NULL                                     -- ケース数
       ,NULL                                     -- 入数
       ,NULL                                     -- 本数
       ,NULL                                     -- 合計数量
       ,NULL                                     -- 伝票No
       ,iv_nodata_msg                            -- 0件メッセージ
       --WHOカラム
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login
       ,cn_request_id
       ,cn_program_application_id
       ,cn_program_id
       ,cd_program_update_date
      );
--
    -- コミット
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_work_zero;
--
   /**********************************************************************************
   * Procedure Name   : ins_work
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work(
    gn_hht_info_loop_cnt       IN NUMBER,        -- HHT入出庫データ情報ループカウンタ
    ov_errbuf                  OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work'; -- プログラム名
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
-- == 2009/06/19 V1.4 Added START ===============================================================
    cv_10               CONSTANT VARCHAR2(2)  := '10';    -- 顧客区分：10（顧客）
    cv_20               CONSTANT VARCHAR2(2)  := '20';    -- 伝票区分：他拠点から預け先
-- == 2009/06/19 V1.4 Added END   ===============================================================
--
    -- *** ローカル変数 ***
-- == 2009/06/19 V1.4 Added START ===============================================================
    lv_outside_name     VARCHAR2(50);                     -- 出庫側名称
    lv_inside_name      VARCHAR2(50);                     -- 入庫側名称
-- == 2009/06/19 V1.4 Added END   ===============================================================
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
-- == 2009/06/19 V1.4 Added START ===============================================================
    -- 出庫側名称
    BEGIN
      IF (gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_type = cv_20) THEN
        SELECT  SUBSTRB(msi.description, 1, 50)
        INTO    lv_outside_name
        FROM    mtl_secondary_inventories   msi
        WHERE   msi.attribute7                =   gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_code
        AND     msi.attribute6                =   cv_yes
        AND     msi.organization_id           =   gn_organization_id
        AND     SYSDATE                       <=  NVL(msi.disable_date, SYSDATE);
        --
      ELSIF (gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_cust_code IS NULL) THEN
        SELECT  SUBSTRB(msi.description, 1, 50)
        INTO    lv_outside_name
        FROM    mtl_secondary_inventories   msi
        WHERE   msi.secondary_inventory_name  =   gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_subinv_code
        AND     msi.organization_id           =   gn_organization_id;
        --
      ELSE
-- == 2009/12/25 V1.9 Modified START ===============================================================
--        SELECT  SUBSTRB(hca.account_name, 1, 50)
--        INTO    lv_outside_name
--        FROM    hz_cust_accounts    hca
--        WHERE   hca.account_number      =   gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_cust_code
--        AND     hca.customer_class_code =   cv_10;
        SELECT  SUBSTRB(hp.party_name, 1, 50)
        INTO    lv_outside_name
        FROM    hz_cust_accounts    hca
               ,hz_parties          hp
        WHERE   hca.account_number      =   gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_cust_code
        AND     hca.customer_class_code =   cv_10
        AND     hca.party_id            =   hp.party_id;
-- == 2009/12/25 V1.9 Modified END   ===============================================================
        --
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND  THEN
        lv_outside_name :=  NULL;
    END;
    --
    -- 入庫側名称
    BEGIN
      IF (gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_cust_code IS NULL) THEN
        SELECT  SUBSTRB(msi.description, 1, 50)
        INTO    lv_inside_name
        FROM    mtl_secondary_inventories   msi
        WHERE   msi.secondary_inventory_name  =   gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_subinv_code
        AND     msi.organization_id           =   gn_organization_id;
        --
      ELSE
-- == 2009/12/25 V1.9 Modified START ===============================================================
--        SELECT  SUBSTRB(hca.account_name, 1, 50)
--        INTO    lv_inside_name
--        FROM    hz_cust_accounts    hca
--        WHERE   hca.account_number      =   gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_cust_code
--        AND     hca.customer_class_code =   cv_10;
        SELECT  SUBSTRB(hp.party_name, 1, 50)
        INTO    lv_inside_name
        FROM    hz_cust_accounts    hca
               ,hz_parties          hp
        WHERE   hca.account_number      =   gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_cust_code
        AND     hca.customer_class_code =   cv_10
        AND     hca.party_id            =   hp.party_id;
-- == 2009/12/25 V1.9 Modified END   ===============================================================
        --
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND  THEN
        lv_inside_name  :=  NULL;
    END;
-- == 2009/06/19 V1.4 Added END   ===============================================================
    --
    --入出庫ジャーナルチェックリスト帳票ワークテーブル登録処理
    INSERT INTO xxcoi_rep_shipstore_jour_list(
        interface_id
       ,target_term                 -- 1
       ,output_kbn                  -- 2
       ,outside_base_code           -- 3
       ,outside_base_name           -- 4
       ,outside_subinv_code         -- 5
       ,outside_subinv_name         -- 6
       ,invoice_type                -- 7
       ,invoice_type_name           -- 8
       ,inside_subinv_code          -- 9
       ,inside_subinv_name          -- 10
       ,item_code                   -- 11
       ,item_name                   -- 12
       ,case_quantity               -- 13
       ,case_in_quantity            -- 14
       ,quantity                    -- 15
       ,total_quantity              -- 16
       ,invoice_no                  -- 17
       ,nodata_msg                  -- 18
       --WHOカラム
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
     )VALUES(
-- == 2009/05/15 V1.2 Modified START ===============================================================
--        gt_hht_info_tab( gn_hht_info_loop_cnt ).interface_id
        gt_hht_info_tab( gn_hht_info_loop_cnt ).transaction_id                      -- インターフェースID
-- == 2009/05/15 V1.2 Modified END   ===============================================================
-- == 2009/12/15 V1.8 Modified START ===============================================================
--       ,SUBSTR(gr_param.target_date,1,10)                                           -- 1.対象期間
       ,TO_CHAR(gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_date, 'YYYY/MM/DD') -- 1.対象期間
-- == 2009/12/15 V1.8 Modified END   ===============================================================
       ,gv_output_kbn_name                                                          -- 2.出力区分
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_base_code                   -- 3.拠点コード
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_base_name                   -- 4.拠点名
-- == 2009/06/19 V1.4 Added START ===============================================================
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_subinv_code
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_subinv_name
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_code                        -- 5.出庫側保管場所コード
       ,lv_outside_name                                                             -- 6.出庫側保管場所名
-- == 2009/06/19 V1.4 Added START ===============================================================
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_type                        -- 7.伝票区分
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_type_name                   -- 8.伝票区分名
-- == 2009/06/19 V1.4 Added START ===============================================================
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_subinv_code
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_subinv_name
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_code                         -- 9.出庫側保管場所コード
       ,lv_inside_name                                                              -- 10.出庫側保管場所名
-- == 2009/06/19 V1.4 Added START ===============================================================
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_code                           -- 11.商品コード
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_name                           -- 12.商品名
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).case_quantity                       -- 13.ケース数
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).case_in_quantity                    -- 14.入数
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).quantity                            -- 15.本数
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).total_quantity                      -- 16.合計数量
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_no                          -- 17.伝票No
       ,NULL                                                                        -- 18.0件メッセージ
       --WHOカラム
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login
       ,cn_request_id
       ,cn_program_application_id
       ,cn_program_id
       ,cd_program_update_date
      );
--
    -- コミット
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_work;
--
  /**********************************************************************************
   * Procedure Name   : get_hht_data（ループ部）
   * Description      : HHT入出庫データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_hht_data(
    gn_base_loop_cnt IN NUMBER,       --   カウント
    ov_errbuf        OUT VARCHAR2,    --   エラー・メッセージ                --# 固定 #
    ov_retcode       OUT VARCHAR2,    --   リターン・コード                  --# 固定 #
    ov_errmsg        OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cv_99                         CONSTANT VARCHAR2(2)  := '99';
-- == 2009/04/02 V1.1 Added START ===============================================================
    -- レコード種別
    cv_record_type_30             CONSTANT VARCHAR2(2)  :=  '30';
-- == 2009/04/02 V1.1 Added END   ===============================================================
-- == 2011/04/08 V1.10 Added START ===============================================================
    cv_record_type_21             CONSTANT VARCHAR2(2)  :=  '21';
-- == 2011/04/08 V1.10 Added END =================================================================
--
    -- 参照タイプ
-- == 2009/06/19 V1.4 Modified START ===============================================================
--    cv_invoice_type               CONSTANT VARCHAR2(30)  := 'XXCOI1_INVOICE_KBN';        -- 伝票区分
    cv_invoice_type               CONSTANT VARCHAR2(30)  := 'XXCOI1_HHT_EBS_CONVERT_TABLE';        -- 伝票区分
-- == 2009/06/19 V1.4 Modified END   ===============================================================
--
    -- 参照コード
--
    -- *** ローカル変数 ***
    ln_cnt                         NUMBER       DEFAULT  0;          -- ループカウンタ
    lv_zero_message                VARCHAR2(30) DEFAULT  NULL;       -- ゼロ件メッセージ
    ln_sql_cnt                     NUMBER       DEFAULT  0;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- HHT入出庫データ
    CURSOR info_hht_cur
    IS
-- == 2009/06/19 V1.4 Modified START ===============================================================
--    SELECT  xhit.transaction_id             transaction_id              -- HHT入出庫一時表ID
--           ,xhit.interface_id               interface_id                -- インターフェースID
--           ,xhit.outside_base_code          out_base_code               -- 出庫拠点コード
--           ,SUBSTRB(hca.account_name,1,8)   out_base_name               -- 出庫拠点名
--           ,xhit.outside_subinv_code        outside_subinv_code         -- 出庫側保管場所コード
--           ,msi1.description                outside_subinv_name         -- 出庫拠保管場所名
--           ,xhit.invoice_type               invoice_type                -- 伝票区分
--           ,flv.meaning                     invoice_name                -- 伝票区分名
--           ,xhit.inside_subinv_code         inside_subinv_code          -- 入庫側保管場所コード
--           ,msi2.description                inside_subinv_name          -- 入庫拠保管場所名
--           ,xhit.item_code                  item_code                   -- 品目コード
--           ,ximb.item_short_name            item_short_name             -- 略称
--           ,xhit.case_quantity              case_quantity               -- ケース数
--           ,xhit.case_in_quantity           case_in_quantity            -- ケース入数
--           ,xhit.quantity                   quantity                    -- 本数
--           ,xhit.total_quantity             total_quantity              -- 総数
---- == 2009/04/02 V1.1 Modified START ===============================================================
----           ,xhit.invoice_no                invoice_no                 -- 伝票No
--           ,CASE  WHEN  xhit.record_type = cv_record_type_30  THEN
--                    NVL(xhit.inside_cust_code, xhit.invoice_no)
--                  ELSE
--                    NVL(xhit.inside_code, xhit.invoice_no)
--            END                             invoice_no                  -- 伝票№
---- == 2009/04/02 V1.1 Modified END   ===============================================================
--    FROM    xxcoi_hht_inv_transactions xhit                           -- HHT入出庫一時表
--           ,hz_cust_accounts           hca                            -- 顧客マスタ
--           ,mtl_secondary_inventories  msi1                           -- 保管場所マスタ1
--           ,mtl_secondary_inventories  msi2                           -- 保管場所マスタ2
--           ,mtl_system_items_b         msib                           -- 品目マスタ
--           ,ic_item_mst_b              iimb                           -- OPM品目マスタ
--           ,xxcmn_item_mst_b           ximb                           -- OPM品目アドオンマスタ
--           ,fnd_lookup_values          flv                            -- クイックコードマスタ
--    WHERE  xhit.output_flag                         =  gr_param.output_kbn
--      AND  xhit.invoice_type                        =  NVL(gr_param.invoice_kbn,xhit.invoice_type)
--      AND  TO_CHAR(xhit.invoice_date,'YYYY/MM/DD')  =  SUBSTR(gr_param.target_date,1,10)
--      AND  xhit.outside_base_code                   =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
--      AND  ( ( ( gr_param.reverse_kbn = cv_1 ) AND (xhit.total_quantity < 0 ) )
--           OR ( ( gr_param.reverse_kbn = cv_0 ) AND (xhit.total_quantity > 0 ) ) )
--      AND  hca.account_number                       =  xhit.outside_base_code
--      AND  hca.customer_class_code                  =  cv_1
--      AND  xhit.outside_subinv_code                 =  msi1.secondary_inventory_name
--      AND  xhit.inside_subinv_code                  =  msi2.secondary_inventory_name(+)
---- == 2009/06/03 V1.3 Added START ===============================================================
--      AND  msi1.organization_id                     =  gn_organization_id
--      AND  msi2.organization_id(+)                  =  gn_organization_id
---- == 2009/06/03 V1.3 Added END   ===============================================================
--      AND  msib.segment1                            =  xhit.item_code
--      AND  msib.organization_id                     =  gn_organization_id
--      AND  msib.segment1                            =  iimb.item_no
--      AND  iimb.item_id                             =  ximb.item_id(+)
--      AND  flv.lookup_type                          =  cv_invoice_type
--      AND  flv.lookup_code                          =  xhit.invoice_type
--      AND  flv.enabled_flag                         =  cv_yes
--      AND  flv.language                             =  USERENV( 'LANG' )
--   ORDER BY xhit.interface_id
--      ;
-- == 2009/12/15 V1.8 Modified START ===============================================================
--      SELECT  xhit.transaction_id             transaction_id              -- HHT入出庫一時表ID
--             ,xhit.interface_id               interface_id                -- インターフェースID
--             ,xhit.outside_base_code          out_base_code               -- 出庫拠点コード
--             ,SUBSTRB(hca.account_name,1,8)   out_base_name               -- 出庫拠点名
--             ,xhit.outside_code               outside_code                -- 出庫側コード
--             ,xhit.outside_cust_code          outside_cust_code           -- 出庫側顧客コード
--             ,xhit.outside_subinv_code        outside_subinv_code         -- 出庫側保管場所コード
--             ,flv.attribute11                 invoice_type                -- 伝票区分
--             ,flv.meaning                     invoice_name                -- 伝票区分名
--             ,xhit.inside_code                inside_code                 -- 入庫側コード
--             ,xhit.inside_cust_code           inside_cust_code            -- 入庫側顧客コード
--             ,xhit.inside_subinv_code         inside_subinv_code          -- 入庫側保管場所コード
--             ,xhit.item_code                  item_code                   -- 品目コード
--             ,ximb.item_short_name            item_short_name             -- 略称
--             ,xhit.case_quantity              case_quantity               -- ケース数
--             ,xhit.case_in_quantity           case_in_quantity            -- ケース入数
--             ,xhit.quantity                   quantity                    -- 本数
--             ,xhit.total_quantity             total_quantity              -- 総数
--             ,xhit.invoice_no                 invoice_no                  -- 伝票№
--      FROM    xxcoi_hht_inv_transactions      xhit                        -- HHT入出庫一時表
--             ,hz_cust_accounts                hca                         -- 顧客マスタ
--             ,mtl_system_items_b              msib                        -- 品目マスタ
--             ,ic_item_mst_b                   iimb                        -- OPM品目マスタ
--             ,xxcmn_item_mst_b                ximb                        -- OPM品目アドオンマスタ
--             ,fnd_lookup_values               flv                         -- クイックコードマスタ
--      WHERE   xhit.output_flag                          =   gr_param.output_kbn
---- == 2009/07/02 V1.5 Modified START ===============================================================
----      AND     TO_CHAR(xhit.invoice_date, 'YYYY/MM/DD')  =   SUBSTR(gr_param.target_date, 1, 10)
--      AND     xhit.invoice_date                         =   TO_DATE(SUBSTR(gr_param.target_date, 1, 10), 'YYYY/MM/DD')
---- == 2009/07/02 V1.5 Modified END   ===============================================================
--      AND     xhit.outside_base_code                    =   gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
---- == 2009/07/10 V1.6 Modified START ===============================================================
----      AND     ((    (gr_param.reverse_kbn   =   cv_1)
----                AND (xhit.total_quantity    <   0)
----               )
----               OR
----               (    (gr_param.reverse_kbn   = cv_0)
----                AND (xhit.total_quantity    > 0)
----               )
----              )
--      AND     ((gr_param.reverse_kbn  =  cv_0)
--               OR
--               (    (gr_param.reverse_kbn   = cv_1)
--                AND (xhit.total_quantity    > 0)
--               )
--               OR
--               (    (gr_param.reverse_kbn   = cv_2)
--                AND (xhit.total_quantity    < 0)
--               )
--              )
---- == 2009/07/10 V1.6 Modified END   ===============================================================
--      AND     hca.account_number                        =   xhit.outside_base_code
--      AND     hca.customer_class_code                   =   cv_1
--      AND     msib.segment1                             =   xhit.item_code
--      AND     msib.organization_id                      =   gn_organization_id
--      AND     msib.segment1                             =   iimb.item_no
--      AND     iimb.item_id                              =   ximb.item_id(+)
---- == 2009/09/08 V1.7 Added START ===============================================================
--      AND     ((   (ximb.item_id IS NOT NULL)
--               AND (TO_DATE(SUBSTR(gr_param.target_date, 1, 10), 'YYYY/MM/DD') BETWEEN ximb.start_date_active
--                                                                               AND     NVL(ximb.end_date_active, TO_DATE(SUBSTR(gr_param.target_date, 1, 10), 'YYYY/MM/DD'))
--                   )
--               )
--               OR
--               (ximb.item_id IS NULL)
--              )
---- == 2009/09/08 V1.7 Added END   ===============================================================
--      AND     xhit.record_type                          =   flv.attribute1
--      AND     xhit.invoice_type                         =   flv.attribute2
--      AND     NVL(xhit.department_flag, cv_99)          =   flv.attribute3
--      AND     flv.lookup_type                           =   cv_invoice_type
--      AND     flv.language                              =   USERENV('LANG')
--      AND     flv.enabled_flag                          =   cv_yes
--      AND     flv.attribute11                           =   NVL(gr_param.invoice_kbn, flv.attribute11)
--      ORDER BY xhit.interface_id;
---- == 2009/06/19 V1.4 Modified END   ===============================================================
--
      SELECT  xhit.transaction_id             transaction_id              -- HHT入出庫一時表ID
             ,xhit.interface_id               interface_id                -- インターフェースID
             ,xhit.outside_base_code          out_base_code               -- 出庫拠点コード
             ,SUBSTRB(hca.account_name,1,8)   out_base_name               -- 出庫拠点名
             ,xhit.outside_code               outside_code                -- 出庫側コード
             ,xhit.outside_cust_code          outside_cust_code           -- 出庫側顧客コード
             ,xhit.outside_subinv_code        outside_subinv_code         -- 出庫側保管場所コード
             ,flv.attribute11                 invoice_type                -- 伝票区分
             ,flv.meaning                     invoice_name                -- 伝票区分名
             ,xhit.inside_code                inside_code                 -- 入庫側コード
             ,xhit.inside_cust_code           inside_cust_code            -- 入庫側顧客コード
             ,xhit.inside_subinv_code         inside_subinv_code          -- 入庫側保管場所コード
             ,xhit.item_code                  item_code                   -- 品目コード
             ,ximb.item_short_name            item_short_name             -- 略称
             ,xhit.case_quantity              case_quantity               -- ケース数
             ,xhit.case_in_quantity           case_in_quantity            -- ケース入数
             ,xhit.quantity                   quantity                    -- 本数
             ,xhit.total_quantity             total_quantity              -- 総数
             ,xhit.invoice_no                 invoice_no                  -- 伝票№
             ,xhit.invoice_date               invoice_date                -- 伝票日付
      FROM    xxcoi_hht_inv_transactions      xhit                        -- HHT入出庫一時表
             ,hz_cust_accounts                hca                         -- 顧客マスタ
             ,mtl_system_items_b              msib                        -- 品目マスタ
             ,ic_item_mst_b                   iimb                        -- OPM品目マスタ
             ,xxcmn_item_mst_b                ximb                        -- OPM品目アドオンマスタ
             ,fnd_lookup_values               flv                         -- クイックコードマスタ
      WHERE   xhit.output_flag                          =   gr_param.output_kbn
      AND     xhit.invoice_date               BETWEEN       TO_DATE(SUBSTRB(gr_param.target_date, 1, 10), 'YYYY/MM/DD')
                                              AND           TO_DATE(SUBSTRB(gr_param.target_date_to, 1, 10), 'YYYY/MM/DD')
      AND     xhit.outside_base_code                    =   gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
      AND     ((gr_param.reverse_kbn  =  cv_0)
               OR
               (    (gr_param.reverse_kbn   = cv_1)
                AND (xhit.total_quantity    > 0)
               )
               OR
               (    (gr_param.reverse_kbn   = cv_2)
                AND (xhit.total_quantity    < 0)
               )
              )
      AND     hca.account_number                        =   xhit.outside_base_code
      AND     hca.customer_class_code                   =   cv_1
      AND     msib.segment1                             =   xhit.item_code
      AND     msib.organization_id                      =   gn_organization_id
      AND     msib.segment1                             =   iimb.item_no
      AND     iimb.item_id                              =   ximb.item_id(+)
      AND     ((   (ximb.item_id IS NOT NULL)
               AND (xhit.invoice_date BETWEEN ximb.start_date_active
                                      AND     NVL(ximb.end_date_active, xhit.invoice_date)
                   )
               )
               OR
               (ximb.item_id IS NULL)
              )
      AND     xhit.record_type                          =   flv.attribute1
-- == 2011/04/08 V1.10 Added START ===============================================================
      AND     xhit.record_type                          <>  cv_record_type_21
-- == 2011/04/08 V1.10 Added END =================================================================
      AND     xhit.invoice_type                         =   flv.attribute2
      AND     NVL(xhit.department_flag, cv_99)          =   flv.attribute3
      AND     flv.lookup_type                           =   cv_invoice_type
      AND     flv.language                              =   USERENV('LANG')
      AND     flv.enabled_flag                          =   cv_yes
      AND     flv.attribute11                           =   NVL(gr_param.invoice_kbn, flv.attribute11)
      ORDER BY xhit.interface_id;
-- == 2009/12/15 V1.8 Modified END   ===============================================================
    -- ローカル・レコード
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- HHT入出庫情報件数初期化
    gn_hht_info_cnt := 0;
--
    -- カーソルオープン
    OPEN info_hht_cur;
--
    -- レコード読込
    FETCH info_hht_cur BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT入出庫情報カウントセット
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE info_hht_cur;
--
    -- 対象処理件数
    gn_target_cnt := gn_target_cnt + gn_hht_info_cnt;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur%ISOPEN ) THEN
        CLOSE info_hht_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_hht_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 拠点情報取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_data'; -- プログラム名
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
    -- 拠点情報(管理元拠点)
    CURSOR info_base1_cur
    IS
      SELECT hca.account_number       account_num           -- 顧客コード
      FROM   hz_cust_accounts         hca                   -- 顧客マスタ
            ,xxcmm_cust_accounts      xca                   -- 顧客追加情報アドオンマスタ
      WHERE  hca.cust_account_id      = xca.customer_id
        AND  hca.customer_class_code  = cv_1
        AND  hca.account_number       = NVL( gr_param.out_base_code, hca.account_number )
        AND  xca.management_base_code = gv_base_code
      ORDER BY hca.account_number
    ;
--
    -- 拠点情報(拠点)
    CURSOR info_base2_cur
    IS
      SELECT  hca.account_number      account_num           -- 顧客コード
        FROM  hz_cust_accounts        hca                   -- 顧客マスタ
       WHERE  hca.customer_class_code = cv_1
         AND  hca.account_number      = NVL( gr_param.out_base_code, hca.account_number )
       ORDER BY hca.account_number
    ;
--
    -- *** ローカル・レコード ***
    lr_info_base1_rec   info_base1_cur%ROWTYPE;
    lr_info_base2_rec   info_base2_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 管理元拠点で起動の時
    IF ( gr_param.output_dpt = cv_2 ) THEN
      OPEN info_base1_cur;
--
      -- レコード読み込み
      FETCH info_base1_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base1_cur;
--
    -- 拠点・商品部で起動の時
    ELSIF ( ( gr_param.output_dpt = cv_1 ) OR ( gr_param.output_dpt = cv_3 ) ) THEN
      OPEN info_base2_cur;
      -- レコード読み込み
      FETCH info_base2_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base2_cur;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_base_data;
--
    /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'init';                      -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 定数
    cv_profile_name    CONSTANT VARCHAR2(24)   := 'XXCOI1_ORGANIZATION_CODE';        -- プロファイル名(在庫組織コード)
    cv_output_kbn      CONSTANT VARCHAR2(30)   := 'XXCOI1_OUTPUT_KBN';               -- 参照タイプ(出力区分)
-- == 2009/07/10 V1.6 Modified START ===============================================================
--    cv_reverse_kbn     CONSTANT VARCHAR2(30)   := 'XXCOI1_REVERSE_DATA_OUTPUT_KBN';  -- 参照タイプ(入出庫逆転データ出力区分)
    cv_reverse_kbn     CONSTANT VARCHAR2(30)   := 'XXCOI1_DATA_SIGN_KBN';  -- 参照タイプ(正負データ出力区分)
-- == 2009/07/10 V1.6 Modified END   ===============================================================
-- == 2009/06/19 V1.4 Modified START ===============================================================
--    cv_invoice_type    CONSTANT VARCHAR2(30)   := 'XXCOI1_INVOICE_KBN';              -- 参照タイプ(伝票区分)
    cv_invoice_type    CONSTANT VARCHAR2(30)   := 'XXCOI1_HHT_EBS_CONVERT_TABLE';    -- 参照タイプ(伝票区分)
-- == 2009/06/19 V1.4 Modified END   ===============================================================
--
    -- *** ローカル変数 ***
    lv_organization_code mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
    lv_invoice_type_name fnd_lookup_values.meaning%TYPE ;        -- 伝票区分
    lv_reverse_kbn_name  fnd_lookup_values.meaning%TYPE;         -- 正負データ出力区分
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
    -- =====================================
    -- 業務日付取得(共通関数)
    -- =====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- 業務日付が取得できない場合はエラー
    IF ( gd_process_date IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00011
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- プロファイル値取得(在庫組織コード)
    -- =====================================
    lv_organization_code := FND_PROFILE.VALUE(cv_profile_name);
    IF ( lv_organization_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00005
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_profile_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 在庫組織ID取得
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    IF ( gn_organization_id IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00006
                     ,iv_token_name1  => cv_token_org_code
                     ,iv_token_value1 => lv_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 所属拠点取得
    -- =====================================
    gv_base_code := xxcoi_common_pkg.get_base_code(
                        in_user_id     => cn_created_by     -- ユーザーID
                       ,id_target_date => gd_process_date); -- 対象日
    IF ( gv_base_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10092);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- コンカレント入力パラメータ出力
    --==============================================================
    -- パラメータ.出力区分
    -- 出力区分名取得
    gv_output_kbn_name := xxcoi_common_pkg.get_meaning(cv_output_kbn,gr_param.output_kbn);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( gv_output_kbn_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10311
                    ,iv_token_name1  =>  cv_token_output_kbn
                    ,iv_token_value1 =>  gr_param.output_kbn
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- パラメータ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10308
                    ,iv_token_name1  =>  cv_token_output_kbn
                    ,iv_token_value1 =>  gv_output_kbn_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.伝票区分
    -- 伝票区分名取得
    IF ( gr_param.invoice_kbn IS NOT NULL ) THEN
-- == 2009/06/19 V1.4 Modified START ===============================================================
--     lv_invoice_type_name := xxcoi_common_pkg.get_meaning(cv_invoice_type, gr_param.invoice_kbn);
--      --
--      -- リターンコードがNULLの場合はエラー
--      IF ( lv_invoice_type_name IS NULL ) THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  =>  cv_app_name
--                      ,iv_name         =>  cv_msg_xxcoi10312
--                      ,iv_token_name1  =>  cv_token_invoice_kbn
--                      ,iv_token_value1 =>  gr_param.invoice_kbn
--                      );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      END IF;
--
      BEGIN
        SELECT  flv.meaning
        INTO    lv_invoice_type_name
        FROM    fnd_lookup_values     flv
        WHERE   flv.lookup_type   =   cv_invoice_type
        AND     flv.attribute11   =   gr_param.invoice_kbn
        AND     flv.language      =   USERENV('LANG')
        AND     flv.enabled_flag  =   cv_yes
        AND     SYSDATE   BETWEEN   NVL(flv.start_date_active, SYSDATE)
                          AND       NVL(flv.end_date_active, SYSDATE);
        --
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  =>  cv_app_name
                        ,iv_name         =>  cv_msg_xxcoi10312
                        ,iv_token_name1  =>  cv_token_invoice_kbn
                        ,iv_token_value1 =>  gr_param.invoice_kbn
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
-- == 2009/06/19 V1.4 Modified END   ===============================================================
    ELSE
      lv_invoice_type_name := gr_param.invoice_kbn;
    END IF;
--
    -- パラメータ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10310
                    ,iv_token_name1  =>  cv_token_invoice_kbn
                    ,iv_token_value1 =>  lv_invoice_type_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
-- == 2009/12/15 V1.8 Modified START ===============================================================
    -- パラメータ.年月日
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  =>  cv_app_name
--                    ,iv_name         =>  cv_msg_xxcoi10067
--                    ,iv_token_name1  =>  cv_token_date
--                    ,iv_token_value1 =>  SUBSTR(gr_param.target_date,1,10)
--                  );
--    fnd_file.put_line(
--      which  => FND_FILE.LOG
--    , buff   => gv_out_msg
--    );
    -- パラメータ.年月日（FROM）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10164
                    ,iv_token_name1  =>  cv_tkn_msg_10164
                    ,iv_token_value1 =>  SUBSTR(gr_param.target_date,1,10)
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
    -- パラメータ.年月日（TO）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10165
                    ,iv_token_name1  =>  cv_tkn_msg_10165
                    ,iv_token_value1 =>  SUBSTR(gr_param.target_date_to,1,10)
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
    -- 年月日FROM-TOの大小チェック
    IF (TO_DATE(SUBSTRB(gr_param.target_date, 1, 10), 'YYYY/MM/DD') > TO_DATE(SUBSTRB(gr_param.target_date_to, 1, 10), 'YYYY/MM/DD')) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10337
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- == 2009/12/15 V1.8 Modified END   ===============================================================
--
    -- パラメータ.拠点
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10307
                    ,iv_token_name1  =>  cv_token_base_code
                    ,iv_token_value1 =>  gr_param.out_base_code
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.正負データ出力区分
    -- 正負データ出力区分名取得
    lv_reverse_kbn_name := xxcoi_common_pkg.get_meaning(cv_reverse_kbn, gr_param.reverse_kbn);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_reverse_kbn_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10313
                    ,iv_token_name1  =>  cv_token_reverse_kbn
                    ,iv_token_value1 =>  gr_param.reverse_kbn
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- パラメータ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10309
                    ,iv_token_name1  =>  cv_token_reverse_kbn
                    ,iv_token_value1 =>  lv_reverse_kbn_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
    iv_output_kbn        IN  VARCHAR2,         --   1.出力区分
    iv_invoice_kbn       IN  VARCHAR2,         --   2.伝票区分
    iv_target_date       IN  VARCHAR2,         --   3.年月日
-- == 2009/12/15 V1.8 Added START ===============================================================
    iv_target_date_to    IN  VARCHAR2,         --   年月日（至）
-- == 2009/12/15 V1.8 Added END   ===============================================================
    iv_out_base_code     IN  VARCHAR2,         --   4.拠点
    iv_reverse_kbn       IN  VARCHAR2,         --   5.正負データ出力区分
    iv_output_dpt        IN  VARCHAR2,         --   6.帳票出力場所
    ov_errbuf            OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_nodata_msg VARCHAR2(50);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    -- パラメータ値の格納
    -- =====================================================
    gr_param.output_kbn        := iv_output_kbn;         -- 01 : 出力区分    (必須)
    gr_param.invoice_kbn       := iv_invoice_kbn;        -- 02 : 伝票区分    (任意)
    gr_param.target_date       := iv_target_date;        -- 03 : 年月日      (必須)
    gr_param.out_base_code     := iv_out_base_code;      -- 04 : 拠点        (任意)
    gr_param.reverse_kbn       := iv_reverse_kbn;        -- 05 : 正負データ出力区分 (必須)
    gr_param.output_dpt        := iv_output_dpt;         -- 06 : 出力場所    (必須)
-- == 2009/12/15 V1.8 Added START ===============================================================
    gr_param.target_date_to    := iv_target_date_to;     -- 年月日（至）
-- == 2009/12/15 V1.8 Added END   ===============================================================
--
    -- =====================================================
    -- 初期処理(A-1)
    -- =====================================================
    init(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- 拠点情報取得処理(A-2)
    -- =====================================================
    get_base_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 拠点情報が１件以上取得出来た場合
    IF ( gn_base_cnt > 0 ) THEN
--
      -- 拠点単位ループ開始
      <<gt_param_tab_loop>>
      FOR gn_base_loop_cnt IN 1 .. gn_base_cnt LOOP
--
        -- =====================================================
        -- HHT入出庫データ取得(A-3)
        -- =====================================================
        get_hht_data(
            gn_base_loop_cnt
          , lv_errbuf            -- エラー・メッセージ           --# 固定 #
          , lv_retcode           -- リターン・コード             --# 固定 #
          , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          -- エラー処理
          RAISE global_process_expt ;
        END IF;
--
        -- HHT入出庫データが1件以上取得できた場合
        IF ( gn_hht_info_cnt > 0 ) THEN
--
          -- HHT入出庫データループ開始
          <<gn_hht_info_cnt_loop>>
          FOR gn_hht_info_loop_cnt IN 1 .. gn_hht_info_cnt LOOP
--
            -- =============================
            -- ワークテーブルデータ登録(A-4)
            -- =============================
            ins_work(
                gn_hht_info_loop_cnt => gn_hht_info_loop_cnt -- HHT入出庫データループカウンタ
              , ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
              , ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
              , ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- パラメータ.出力フラグが"未出力"の場合のみ
            IF ( gr_param.output_kbn = cv_no ) THEN
              -- =============================
              -- 出力フラグ更新(A-5)
              -- =============================
              upd_hht_data(
                  gn_hht_info_loop_cnt => gn_hht_info_loop_cnt -- HHT入出庫データループカウンタ
                , ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
                , ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
                , ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
          END LOOP gn_hht_info_cnt_loop;
--
        END IF;
--
      END LOOP gt_param_tab_loop;
    END IF;
--
    -- 出力対象件数が0件の場合、ワークテーブルにパラメータ情報のみを登録
    IF (gn_target_cnt = 0) THEN
--
      -- 0件メッセージの取得
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi00008
                         );
--
      -- ==============================================
      --  ワークテーブルデータ登録(A-5)
      -- ==============================================
      ins_work_zero(
           iv_nodata_msg        => lv_nodata_msg        -- ゼロ件メッセージ
         , ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
         , ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
         , ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        -- エラー処理
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    -- SVF起動(A-5)
    -- =====================================================
    svf_request(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- ワークテーブルデータ削除(A-6)
    -- =====================================================
    del_work(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- 正常終了件数
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
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
    errbuf               OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode              OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_output_kbn        IN  VARCHAR2,      --   1.取引タイプ
    iv_invoice_kbn       IN  VARCHAR2,      --   2.伝票区分
    iv_target_date       IN  VARCHAR2,      --   3.年月日
-- == 2009/12/15 V1.8 Added START ===============================================================
    iv_target_date_to    IN  VARCHAR2,      --   年月日（至）
-- == 2009/12/15 V1.8 Added END   ===============================================================
    iv_out_base_code     IN  VARCHAR2,      --   4.出庫拠点
    iv_reverse_kbn       IN  VARCHAR2,      --   5.正負データ出力区分
    iv_output_dpt        IN  VARCHAR2)      --   6.帳票出力場所
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
       iv_which   =>  cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_output_kbn        --   1.出力区分
      ,iv_invoice_kbn       --   2.伝票区分
      ,iv_target_date       --   3.年月日
-- == 2009/12/15 V1.8 Added START ===============================================================
      ,iv_target_date_to    --   年月日（至）
-- == 2009/12/15 V1.8 Added END   ===============================================================
      ,iv_out_base_code     --   4.出庫拠点
      ,iv_reverse_kbn       --   5.正負データ出力区分
      ,iv_output_dpt        --   6.帳票出力場所
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI009A04R;
/
