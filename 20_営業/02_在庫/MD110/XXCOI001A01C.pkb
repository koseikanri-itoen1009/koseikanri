CREATE OR REPLACE PACKAGE BODY XXCOI001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A01C(body)
 * Description      : 生産物流システムから営業システムへの出荷依頼データの抽出・データ連携を行う
 * MD.050           : 入庫情報取得 MD050_COI_001_A01
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_summary_record     入庫情報サマリの抽出(A-2)
 *  get_detail_record      入庫情報詳細の抽出(A-3)
 *  get_subinventories     保管場所情報処理(A-4)
 *  ins_summary_unconfirmed入庫情報サマリの登録[入庫未確認](A-5)
 *  ins_summary_confirmed  入庫情報サマリの登録[入庫確認済](A-6)
 *  upd_summary_disp       入庫情報サマリの更新[出荷依頼ステータスNULL対象](A-7)
 *  upd_summary_close      入庫情報サマリの更新[出荷依頼ステータス03対象](A-8)
 *  upd_summary_results    入庫情報サマリの更新[出荷依頼ステータス04対象](A-9)
 *  ins_detail_confirmed   入庫情報詳細の登録(A-10)
 *  upd_detail_close       入庫情報詳細の更新[出荷依頼ステータス03対象](A-11)
 *  upd_detail_results     入庫情報詳細の更新[出荷依頼ステータス04対象](A-12)
 *  upd_order_lines        受注明細アドオン更新(A-13)
 *  chk_item               品目有効チェック(A-15)
 *  chk_summary_data       入庫情報サマリ存在確認(A-16)
 *  chk_detail_data        入庫情報詳細存在確認(A-17)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *  chk_period_status      在庫会計期間チェック(A-20)
 *  del_detail_data        旧明細削除処理(A-21)
 *  upd_old_data           旧情報出庫数量初期化処理(A-22)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   S.Moriyama       main新規作成
 *  2009/03/16    1.1   H.Wada           障害番号T1_0041 get_subinventories
 *                                         保管場所の有効チェック取得条件変更
 *  2009/04/02    1.2   T.Nakamura       障害番号T1_0004 get_summary_record, get_detail_record
 *                                         出荷実績数量を小数2桁に丸めるよう変更
 *  2009/04/16    1.3   H.Sasaki         [T1_0386]データ抽出条件の変更（配送先番号）
 *                                                抽出情報の変更（配送先番号）
 *                                       [T1_0387]データ抽出条件の変更（レコードタイプ）
 *  2009/05/01    1.4   T.Nakamura       [T1_0485]サマリ、詳細抽出条件の追加、詳細の取得情報の変更
 *                                                出荷依頼ステータス04対象のサマリ、詳細の更新情報の変更
 *  2009/05/14    1.5   H.Sasaki         [T1_0387]入庫情報一時表の存在チェック条件を修正
 *  2009/06/03    1.6   H.Sasaki         [T1_1186]サマリ、明細カーソルのPT
 *  2009/07/13    1.7   H.Sasaki         [0000495]入庫情報サマリ抽出カーソルのPT対応
 *  2009/09/08    1.8   H.Sasaki         [0001266]OPM品目アドオンの版管理対応
 *  2009/10/26    1.9   H.Sasaki         [E_T4_00076]倉庫コードの設定方法を修正
 *  2009/11/06    1.10  H.Sasaki         [E_T4_00143]PT対応
 *  2009/11/13    1.11  N.Abe            [E_T4_00189]品目1桁目が5,6を資材として処理
 *  2009/12/08    1.12  N.Abe            [E_本稼動_00308,E_本稼動_00312]削除データ処理順序の修正
 *                                       [E_本稼動_00374]削除データ登録方法の修正
 *  2009/12/14    1.13  H.Sasaki         [E_本稼動_00428]在庫会計期間CLOSE時の処理を修正
 *  2009/12/18    1.14  H.Sasaki         [E_本稼動_00524]伝票日付違いの入庫情報編集内容を修正
 *  2010/01/04    1.15  H.Sasaki         [E_本稼動_00760]サマリデータの更新方法を修正
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt    NUMBER;                                            -- 対象件数
  gn_normal_cnt    NUMBER;                                            -- 正常件数
  gn_error_cnt     NUMBER;                                            -- エラー件数
  gn_warn_cnt      NUMBER;                                            -- スキップ件数
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  subinventory_found_expt   EXCEPTION;                                -- 保管場所存在チェックエラー
  subinventory_disable_expt EXCEPTION;                                -- 保管場所有効チェックエラー
  subinventory_plural_expt  EXCEPTION;                                -- 保管場所取得エラー
  item_found_expt           EXCEPTION;                                -- 品目存在チェックエラー
  item_disable_expt         EXCEPTION;                                -- 品目有効チェックエラー
  item_expt                 EXCEPTION;                                -- 品目チェック関数エラー
  lock_expt                 EXCEPTION;                                -- ロック処理例外
  conv_slip_num_expt        EXCEPTION;                                -- 伝票番号コンバートエラー
  period_status_close_expt  EXCEPTION;                                -- 在庫会計期間クローズエラー
  period_status_common_expt EXCEPTION;                                -- 在庫会計期間例外
-- == 2009/10/26 V1.9 Modified START ===============================================================
  main_store_expt           EXCEPTION;                                -- メイン倉庫区分重複エラー
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI001A01C';          -- パッケージ名
  cv_application   CONSTANT VARCHAR2(100) := 'XXCOI';                 -- アプリケーション名
--
  cv_slip_type     CONSTANT VARCHAR2(100) := '10';                    -- 工場入庫
  cv_y_flag        CONSTANT VARCHAR2(100) := 'Y';                     -- フラグ値:Y
  cv_n_flag        CONSTANT VARCHAR2(100) := 'N';                     -- フラグ値:N
  cv_status_flag   CONSTANT VARCHAR2(100) := 'A';                     -- フラグ値:A
  cv_class_code    CONSTANT VARCHAR2(100) := '1';                     -- 顧客区分:1（拠点）
  cv_hht_kbn       CONSTANT VARCHAR2(100) := '1';                     -- 百貨店HHT区分:1（百貨店）
  cv_site_use_code CONSTANT VARCHAR2(100) := 'SHIP_TO';               -- 顧客所在地使用目的（出荷先）
  cv_subinv_class  CONSTANT VARCHAR2(100) := '3';                     -- 保管場所区分:3（預け先）
  cv_subinv_type   CONSTANT VARCHAR2(100) := '9';                     -- 保管場所分類:9（百貨店預け先）
  cv_exclude_type  CONSTANT VARCHAR2(100) := 'XXCOI1_EXCLUDE_ORDER_TYPE';  -- 除外受注タイプコード
  cv_item_category CONSTANT VARCHAR2(100) := 'XXCOI1_ITEM_CATEGORY_CLASS'; -- 品目カテゴリ
  cv_order_type    CONSTANT VARCHAR2(100) := 'ORDER';                 -- 受注タイプ:ORDER
  cv_return_type   CONSTANT VARCHAR2(100) := 'RETURN';                -- 受注タイプ:RETURN
  cv_0             CONSTANT VARCHAR2(100) := '0';                     -- コード固定値:0
  cv_1             CONSTANT VARCHAR2(100) := '1';                     -- コード固定値:1
  cv_2             CONSTANT VARCHAR2(100) := '2';                     -- コード固定値:2
--
  cv_tkn_pro       CONSTANT VARCHAR2(100) := 'PRO_TOK';
  cv_tkn_org       CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';
  cv_tkn_base_code CONSTANT VARCHAR2(100) := 'BASE_CODE';
  cv_tkn_warehouse CONSTANT VARCHAR2(100) := 'WAREHOUSE_CODE';
  cv_tkn_item_code CONSTANT VARCHAR2(100) := 'ITEM_CODE';
  cv_tkn_den_no    CONSTANT VARCHAR2(100) := 'DEN_NO';
  cv_tkn_api_nm    CONSTANT VARCHAR2(100) := 'API_NAME';
  cv_tkn_target    CONSTANT VARCHAR2(100) := 'TARGET_DATE';
-- == 2009/10/26 V1.9 Modified START ===============================================================
  cv_token_10379   CONSTANT VARCHAR2(30)  := 'BASE_CODE_TOK';
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
  -- 初期処理出力
  cv_prf_org_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  cv_prf_ship_err_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10168'; -- 出荷依頼ステータスコード取得エラーメッセージ
  cv_prf_notice_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10169'; -- 通知ステータスコード取得エラーメッセージ
  cv_org_id_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_prf_lot_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10343'; -- ロットレコード取得エラーメッセージ
  cv_prf_itou_ou_mfg_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10338'; -- 生産営業単位取得名称取得エラーメッセージ
--
  -- データチェック処理出力
  cv_subinventory_found_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10053'; -- 保管場所存在チェックエラー
  cv_subinventory_disable_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10238'; -- 保管場所有効チェックエラー
  cv_subinventory_plural_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10239'; -- 保管場所取得エラー
  cv_item_found_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10236'; -- 品目存在チェックエラーメッセージ
  cv_item_disable_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10237'; -- 品目有効チェックエラーメッセージ
  cv_conv_slip_num_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10032'; -- 依頼Noコンバートエラーメッセージ
  cv_item_expt_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00010'; -- APIエラーメッセージ
  cv_process_date_expt_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_period_status_cmn_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00026'; -- 在庫会計期間取得エラーメッセージ
  cv_period_status_close_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10361'; -- 在庫会計期間クローズメッセージ
-- == 2009/10/26 V1.9 Modified START ===============================================================
  cv_msg_code_10379           CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10379'; -- メイン倉庫区分重複エラーメッセージ
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
  -- 更新時出力
  cv_lock_expt_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10029'; -- ロックエラーメッセージ(入庫情報一時表)
  cv_detail_lock_expt_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10336'; -- ロックエラーメッセージ(入庫情報一時表)
  cv_lines_lock_expt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10031'; -- ロックエラーメッセージ(受注明細アドオンテーブル)
--
  cv_conc_not_parm_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなし
  cv_not_found_slip_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データ無し
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_code                 mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
  gt_org_id                   mtl_parameters.organization_id%TYPE;    -- 在庫組織ID
  gt_ship_status_close        xxwsh_order_headers_all.req_status%TYPE;-- 出荷依頼ステータス_締め済み
  gt_ship_status_result       xxwsh_order_headers_all.req_status%TYPE;-- 出荷依頼ステータス_出荷実績計上済
  gt_ship_status_cancel       xxwsh_order_headers_all.req_status%TYPE;-- 出荷依頼ステータス_取消
  gt_notice_status            xxwsh_order_headers_all.notif_status%TYPE;
                                                                      -- 通知ステータス_確定通知済
  gt_lot_status_request       xxinv_mov_lot_details.record_type_code%TYPE;
                                                                      -- ロットレコードステータス_出荷指示
  gt_lot_status_results       xxinv_mov_lot_details.record_type_code%TYPE;
                                                                      -- ロットレコードステータス_出荷実績
  gt_org_name                 hr_organization_units.name%TYPE;        -- 営業単位名称
  gt_itou_ou_id               hr_organization_units.organization_id%TYPE;
                                                                      -- 組織ID
  gd_process_date             DATE;                                   -- 業務日付
  gv_slip_num                 VARCHAR2(12);                           -- 伝票No(12桁コンバート後)
  gn_summary_cnt              NUMBER;                                 -- サマリレコード取得件数
  gn_detail_cnt               NUMBER;                                 -- 詳細レコード取得件数
  gn_slip_cnt                 NUMBER;                                 -- サマリレコードカウンタ
  gn_line_cnt                 NUMBER;                                 -- 詳細レコードカウンタ
--
  TYPE g_summary_rtype IS RECORD(
      req_status        xxwsh_order_headers_all.req_status%TYPE       -- 出荷実績ステータス
    , result_deliver_to xxwsh_order_headers_all.result_deliver_to%TYPE-- 出荷先_実績
    , slip_date         xxwsh_order_headers_all.arrival_date%TYPE     -- 伝票日付
    , req_move_no       xxwsh_order_headers_all.request_no%TYPE       -- 依頼No
    , deliver_from      xxwsh_order_headers_all.deliver_from%TYPE     -- 出荷元保管場所
    , item_no           xxwsh_order_lines_all.request_item_code%TYPE  -- 子品目コード
    , parent_item_no    ic_item_mst_b.item_no%TYPE                    -- 親品目コード
    , base_code         hz_cust_accounts.account_number%TYPE          -- 拠点コード
    , delete_flag       xxwsh_order_lines_all.delete_flag%TYPE        -- 削除フラグ
    , dept_hht_div      xxcmm_cust_accounts.dept_hht_div%TYPE         -- 百貨店用HHT区分
    , deliverly_code    hz_cust_acct_sites_all.attribute18%TYPE       -- 配送先コード
    , case_in_qty       ic_item_mst_b.attribute11%TYPE                -- ケース入数
    , shipped_qty       xxwsh_order_lines_all.shipped_quantity%TYPE   -- 出荷実績数量
  );
  TYPE g_detail_rtype IS RECORD(
      req_status              xxwsh_order_headers_all.req_status%TYPE -- 出荷実績ステータス
    , result_deliver_to       xxwsh_order_headers_all.result_deliver_to%TYPE
                                                                      -- 出荷先_実績
    , slip_date               xxwsh_order_headers_all.arrival_date%TYPE
                                                                      -- 伝票日付
    , req_move_no             xxwsh_order_headers_all.request_no%TYPE -- 依頼No
    , deliver_from            xxwsh_order_headers_all.deliver_from%TYPE
                                                                      -- 出荷元保管場所
    , item_no                 xxwsh_order_lines_all.request_item_code%TYPE
                                                                      -- 子品目コード
    , parent_item_no          ic_item_mst_b.item_no%TYPE              -- 親品目コード
    , base_code               hz_cust_accounts.account_number%TYPE    -- 拠点コード
    , delete_flag             xxwsh_order_lines_all.delete_flag%TYPE  -- 削除フラグ
    , dept_hht_div            xxcmm_cust_accounts.dept_hht_div%TYPE   -- 百貨店用HHT区分
    , deliverly_code          hz_cust_acct_sites_all.attribute18%TYPE -- 配送先コード
    , case_in_qty             ic_item_mst_b.attribute11%TYPE          -- ケース入数
    , taste_term              ic_lots_mst.attribute3%TYPE             -- 賞味期限
    , difference_summary_code ic_lots_mst.attribute2%TYPE             -- 固有番号
    , order_header_id         xxwsh_order_lines_all.order_header_id%TYPE
                                                                      -- 受注ヘッダID
    , order_line_id           xxwsh_order_lines_all.order_line_id%TYPE-- 受注明細ID
    , shipped_qty             xxwsh_order_lines_all.shipped_quantity%TYPE
                                                                      -- 出荷実績数量
  );
--
  TYPE g_summary_ttype IS TABLE OF g_summary_rtype INDEX BY BINARY_INTEGER ;
  g_summary_tab                    g_summary_ttype;
  TYPE g_detail_ttype IS TABLE OF g_detail_rtype INDEX BY BINARY_INTEGER ;
  g_detail_tab                    g_detail_ttype;
--
-- == 2009/12/18 V1.14 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : del_detail_data（ループ部）
   * Description      : 旧明細削除処理(A-21)
   ***********************************************************************************/
  PROCEDURE del_detail_data(
      in_slip_cnt   IN NUMBER                                          -- 1.ループカウンタ
    , iv_store_code IN VARCHAR2                                        -- 2.倉庫コード
    , ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_detail_data';    -- プログラム名
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
    -- 明細情報を削除
    -- ロック処理はサマリ情報の更新処理で実施
    DELETE  FROM  xxcoi_storage_information   xsi
    WHERE   xsi.slip_num          = gv_slip_num
    AND     xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
    AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
    AND     xsi.warehouse_code    = iv_store_code
    AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
    AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
    AND     xsi.slip_type         = cv_slip_type
    AND     xsi.summary_data_flag = cv_n_flag;
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
  END del_detail_data;
  --
  /**********************************************************************************
   * Procedure Name   : upd_old_data（ループ部）
   * Description      : 旧情報出庫数量初期化処理(A-22)
   ***********************************************************************************/
  PROCEDURE upd_old_data(
      in_slip_cnt   IN NUMBER                                          -- 1.ループカウンタ
    , iv_store_code IN VARCHAR2                                        -- 2.倉庫コード
    , ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_old_data';    -- プログラム名
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
    CURSOR  old_data_lock_cur
    IS
      SELECT  1
      FROM    xxcoi_storage_information     xsi
      WHERE   xsi.slip_num          = gv_slip_num
      AND     xsi.slip_date        <> g_summary_tab ( in_slip_cnt ) .slip_date
      AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND     xsi.warehouse_code    = iv_store_code
      AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND     xsi.slip_type         = cv_slip_type
      FOR UPDATE NOWAIT;

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
    OPEN  old_data_lock_cur;
    --
    IF (old_data_lock_cur%NOTFOUND) THEN
      NULL;
    ELSE
      -- 同一の伝票番号、品目で伝票日付の異なるデータが存在する場合
      -- 異なる伝票日付の出荷数量（ケース、バラ、総バラ）を初期化
      UPDATE  xxcoi_storage_information   xsi
      SET     ship_case_qty           =   0
             ,ship_singly_qty         =   0
             ,ship_summary_qty        =   0
             ,last_updated_by         = cn_last_updated_by
             ,last_update_date        = SYSDATE
             ,last_update_login       = cn_last_update_login
             ,request_id              = cn_request_id
             ,program_application_id  = cn_program_application_id
             ,program_id              = cn_program_id
             ,program_update_date     = SYSDATE
      WHERE   xsi.slip_num          = gv_slip_num
      AND     xsi.slip_date        <> g_summary_tab ( in_slip_cnt ) .slip_date
      AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND     xsi.warehouse_code    = iv_store_code
      AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND     xsi.slip_type         = cv_slip_type;
    END IF;
    --
    CLOSE old_data_lock_cur;
    --
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_old_data;
-- == 2009/12/18 V1.14 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                   -- プログラム名
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
    cv_prf_org                CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';
                                                                      -- XXCOI:在庫組織コード
    cv_prf_ship_status_close  CONSTANT VARCHAR2(100) := 'XXCOI1_SHIP_STATUS_CLOSE';
                                                                      -- XXCOI:出荷依頼ステータス_締め済み
    cv_prf_ship_status_result CONSTANT VARCHAR2(100) := 'XXCOI1_SHIP_STATUS_RESULTS';
                                                                      -- XXCOI:出荷依頼ステータス_出荷実績計上済
    cv_prf_ship_status_cancel CONSTANT VARCHAR2(100) := 'XXCOI1_SHIP_STATUS_CANCEL';
                                                                      -- XXCOI:出荷依頼ステータス_取消
    cv_prf_notice_status      CONSTANT VARCHAR2(100) := 'XXCOI1_NOTICE_STATUS_CLOSE';
                                                                      -- XXCOI:通知ステータス_確定通知済
    cv_prf_lot_status_request CONSTANT VARCHAR2(100) := 'XXCOI1_LOT_STATUS_REQUEST';
                                                                      -- XXCOI:ロットレコードステータス_出荷指示
    cv_prf_lot_status_results CONSTANT VARCHAR2(100) := 'XXCOI1_LOT_STATUS_RESULTS';
                                                                      -- XXCOI:ロットレコードステータス_出荷実績
    cv_prf_itou_ou_mfg        CONSTANT VARCHAR2(100) := 'XXCOI1_ITOE_OU_MFG';
                                                                      -- XXCOI:生産営業単位取得名称
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';      -- アドオン：共通・IF領域
--
    -- *** ローカル変数 ***
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
    --==============================================================
    --コンカレントパラメータ出力（なし）
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => cv_conc_not_parm_msg
                  );
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    fnd_file.put_line(
        which  => fnd_file.output
      , buff   => ''
    );
    -- 空行出力
    fnd_file.put_line(
        which  => fnd_file.log
      , buff   => ''
    );
--
    --==============================================================
    --プロファイルより在庫組織コード取得
    --==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    -- プロファイルが取得できない場合
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_org_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより出荷依頼ステータス_締め済み取得
    --==============================================================
    gt_ship_status_close := fnd_profile.value( cv_prf_ship_status_close );
    -- プロファイルが取得できない場合
    IF ( gt_ship_status_close IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_close
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより出荷依頼ステータス_出荷実績計上済取得
    --==============================================================
    gt_ship_status_result := fnd_profile.value( cv_prf_ship_status_result );
    -- プロファイルが取得できない場合
    IF ( gt_ship_status_result IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_result
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより出荷依頼ステータス_取消
    --==============================================================
    gt_ship_status_cancel := fnd_profile.value( cv_prf_ship_status_cancel );
    -- プロファイルが取得できない場合
    IF ( gt_ship_status_cancel IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_cancel
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより通知ステータス_確定通知済取得
    --==============================================================
    gt_notice_status := fnd_profile.value( cv_prf_notice_status );
    -- プロファイルが取得できない場合
    IF ( gt_notice_status IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_notice_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_notice_status
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルよりロットレコードステータス_出荷指示取得
    --==============================================================
    gt_lot_status_request := fnd_profile.value( cv_prf_lot_status_request );
    -- プロファイルが取得できない場合
    IF ( gt_lot_status_request IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_lot_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_lot_status_request
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルよりロットレコードステータス_出荷実績取得
    --==============================================================
    gt_lot_status_results := fnd_profile.value( cv_prf_lot_status_results );
    -- プロファイルが取得できない場合
    IF ( gt_lot_status_results IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_lot_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_lot_status_results
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより生産営業単位取得名称
    --==============================================================
    gt_org_name := fnd_profile.value( cv_prf_itou_ou_mfg );
    -- プロファイルが取得できない場合
    IF ( gt_org_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_itou_ou_mfg_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_itou_ou_mfg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      BEGIN
        SELECT hou.organization_id
        INTO   gt_itou_ou_id
        FROM   hr_organization_units hou
        WHERE  hou.name = gt_org_name;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_prf_itou_ou_mfg_err_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_prf_itou_ou_mfg
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
--
    --==============================================================
    --共通関数より在庫組織ID取得
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_org_id_err_msg
                     , iv_token_name1  => cv_tkn_org
                     , iv_token_value1 => gt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --共通関数より業務日付取得
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application
                     , iv_name        => cv_process_date_expt_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : get_summary_record
   * Description      : 入庫情報サマリの抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_summary_record(
      ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_summary_record';     -- プログラム名
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
    -- 入庫情報サマリの抽出
    CURSOR summary_cur
    IS
-- == 2009/06/03 V1.6 Modified START ===============================================================
--      SELECT  xoha.req_status                  AS req_status          -- 出荷依頼ステータス
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.result_deliver_to ELSE xoha.deliver_to END
--                                               AS result_deliver_to   -- 出荷先_実績
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.arrival_date ELSE xoha.schedule_arrival_date END
--                                               AS arrive_date         -- 伝票日付
--            , xoha.request_no                  AS req_move_no         -- 依頼No
--            , xoha.deliver_from                AS deliver_from        -- 出荷元保管場所
--            , xola.request_item_code           AS item_no             -- 子品目コード
--            , imbp.item_no                     AS parent_item_no      -- 親品目コード
--            , hca.account_number               AS base_code           -- 拠点コード
--            , xola.delete_flag                 AS delete_flag         -- 削除フラグ
--            , xca.dept_hht_div                 AS dept_hht_div        -- 百貨店用HHT区分
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18                AS deliverly_code      -- 配送先コード
--            , hl.province                      AS deliverly_code
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--            , imbc.attribute11                 AS case_in_qty         -- ケース入数
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                CASE WHEN otta.order_category_code = cv_order_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.shipped_quantity)
--                  SUM( ROUND( xola.shipped_quantity, 2 ) )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                     WHEN otta.order_category_code = cv_return_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.shipped_quantity) * -1
--                  SUM( ROUND( xola.shipped_quantity, 2 ) * -1 )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                END
--              ELSE
--                CASE WHEN otta.order_category_code = cv_order_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.quantity)
--                  SUM( ROUND( xola.quantity, 2 ) )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                     WHEN otta.order_category_code = cv_return_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.quantity) * -1
--                  SUM( ROUND( xola.quantity, 2 ) * -1 )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                END
--              END                              AS shipped_quantity    -- 出荷実績数量
--      FROM    xxwsh_order_headers_all          xoha                   -- 受注ヘッダアドオン
--            , xxwsh_order_lines_all            xola                   -- 受注明細アドオン
--            , ic_item_mst_b                    imbc                   -- OPM品目マスタ（子）
--            , ic_item_mst_b                    imbp                   -- OPM品目マスタ（親）
--            , xxcmn_item_mst_b                 ximb                   -- OPM品目アドオンマスタ
--            , mtl_system_items_b               msib                   -- Disc品目マスタ
--            , hz_party_sites                   hps                    -- パーティサイトマスタ
--            , hz_cust_accounts                 hca                    -- 顧客マスタ
--            , hz_cust_acct_sites_all           hcasa                  -- 顧客所在地マスタ
--            , hz_cust_site_uses_all            hcaua                  -- 顧客使用目的マスタ
--            , xxcmm_cust_accounts              xca                    -- 顧客追加情報
--            , oe_transaction_types_all         otta                   -- 受注タイプマスタ
--            , oe_transaction_types_tl          ottt
---- == 2009/04/16 V1.3 Added START ===============================================================
--            ,hz_locations                      hl                     -- 事業所マスタ
---- == 2009/04/16 V1.3 Added END   ===============================================================
--      WHERE  xoha.order_header_id = xola.order_header_id
--      AND    xola.request_item_id = msib.inventory_item_id
--      AND    imbc.item_no         = msib.segment1
--      AND    imbc.item_id         = ximb.item_id
--      AND    imbp.item_id         = ximb.parent_item_id
--      AND    msib.organization_id = gt_org_id
--      AND ( ( -- 締め済み、確定通知済出荷依頼（出荷依頼は削除明細を除外）
--              xoha.req_status                          = gt_ship_status_close
--              AND xoha.notif_status                    = gt_notice_status
--              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
--              AND xoha.deliver_to_id                   = hps.party_site_id
--            )
--         OR ( -- 出荷実績計上済出荷実績（出荷実績は削除明細を除外、ただし出荷依頼連携済は対象）
--              (xoha.actual_confirm_class               = cv_y_flag
--              AND xoha.result_deliver_to_id            = hps.party_site_id)
--              AND(( xoha.req_status                    = gt_ship_status_result
--                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                  )
--              OR ( xoha.req_status                     = gt_ship_status_result
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                 ))
--            )
--         OR ( -- 出荷依頼連携済に対して取消を行ったものは対象
--              xoha.req_status                                       = gt_ship_status_cancel
--              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
--            )
--          )
--      AND     otta.attribute1             = cv_1
--      AND     NVL ( otta.attribute4 , cv_1 ) <> cv_2
--      AND     otta.org_id                 = gt_itou_ou_id
--      AND     otta.transaction_type_id    = ottt.transaction_type_id
--      AND     ottt.language               = USERENV('LANG')
--      AND NOT EXISTS ( SELECT   '1'
--                       FROM     fnd_lookup_values flv
--                              , fnd_lookup_types flt
--                       WHERE    flt.lookup_type = cv_exclude_type
--                       AND      flt.lookup_type = flv.lookup_type
--                       AND      flv.enabled_flag = cv_y_flag
--                       AND      flv.language = USERENV('LANG')
--                       AND      gd_process_date BETWEEN flv.start_date_active AND NVL ( flv.end_date_active , gd_process_date )
--                       AND      ottt.name = flv.meaning
--                     )
--      AND     xoha.order_type_id          = ottt.transaction_type_id
--      AND     hps.party_id                = hca.party_id
--      AND     hca.cust_account_id         = hcasa.cust_account_id
--      AND     hcasa.cust_acct_site_id     = hcaua.cust_acct_site_id
--      AND     hcaua.site_use_code         = cv_site_use_code
--      AND     hcaua.status                = cv_status_flag
--      AND     hcaua.primary_flag          = cv_y_flag
--      AND     hca.cust_account_id         = xca.customer_id
--      AND     hca.customer_class_code     = cv_class_code
--      AND     hca.status                  = cv_status_flag
---- == 2009/04/16 V1.3 Modified START ===============================================================
----      AND     SUBSTRB ( hcasa.attribute18 , 1 , 1 ) = cv_0
--      AND     hps.location_id             = hl.location_id
--      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
---- == 2009/04/16 V1.3 Modified END   ===============================================================
---- == 2009/05/01 V1.4 Added START ==================================================================
--      AND     xoha.latest_external_flag   = cv_y_flag
---- == 2009/05/01 V1.4 Added END   ==================================================================
--      GROUP BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                     xoha.result_deliver_to ELSE xoha.deliver_to END
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
--              , xoha.deliver_from
--              , xola.request_item_code
--              , imbp.item_no
--              , xola.delete_flag
--              , xca.dept_hht_div
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18
--              , hl.province
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              , imbc.attribute11
--              , otta.order_category_code
--      ORDER BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , xola.request_item_code
--              , imbp.item_no
--      ;
--
      SELECT
-- == 2009/07/13 V1.7 Added START ===============================================================
              /*+ leading(ottt otta xoha xola) use_nl(xoha xola msib imbc imbp ximb hps hl) */
-- == 2009/07/13 V1.7 Added END   ===============================================================
              xoha.req_status                  AS req_status          -- 出荷依頼ステータス
            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                xoha.result_deliver_to ELSE xoha.deliver_to END
                                               AS result_deliver_to   -- 出荷先_実績
            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                xoha.arrival_date ELSE xoha.schedule_arrival_date END
                                               AS arrive_date         -- 伝票日付
            , xoha.request_no                  AS req_move_no         -- 依頼No
            , xoha.deliver_from                AS deliver_from        -- 出荷元保管場所
            , xola.request_item_code           AS item_no             -- 子品目コード
            , imbp.item_no                     AS parent_item_no      -- 親品目コード
            , hca.account_number               AS base_code           -- 拠点コード
-- == 2009/12/08 V1.12 Modified START ===============================================================
--            , xola.delete_flag                 AS delete_flag         -- 削除フラグ
            , NVL(xola.delete_flag,cv_n_flag)  AS delete_flag         -- 削除フラグ
-- == 2009/12/08 V1.12 Modified END   ===============================================================
            , xca.dept_hht_div                 AS dept_hht_div        -- 百貨店用HHT区分
            , hl.province                      AS deliverly_code
            , imbc.attribute11                 AS case_in_qty         -- ケース入数
-- == 2009/12/18 V1.14 Modified START ===============================================================
--             , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                 CASE WHEN otta.order_category_code = cv_order_type THEN
--                   SUM( ROUND( xola.shipped_quantity, 2 ) )
--                      WHEN otta.order_category_code = cv_return_type THEN
--                   SUM( ROUND( xola.shipped_quantity, 2 ) * -1 )
--                 END
--               ELSE
--                 CASE WHEN otta.order_category_code = cv_order_type THEN
--                   SUM( ROUND( xola.quantity, 2 ) )
--                      WHEN otta.order_category_code = cv_return_type THEN
--                   SUM( ROUND( xola.quantity, 2 ) * -1 )
--                 END
--               END                              AS shipped_quantity    -- 出荷実績数量
            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                CASE WHEN otta.order_category_code = cv_order_type THEN
                  SUM( ROUND( NVL(xola.shipped_quantity, 0), 2 ) )
                     WHEN otta.order_category_code = cv_return_type THEN
                  SUM( ROUND( NVL(xola.shipped_quantity, 0), 2 ) * -1 )
                END
              ELSE
                CASE WHEN otta.order_category_code = cv_order_type THEN
                  SUM( ROUND( NVL(xola.quantity, 0), 2 ) )
                     WHEN otta.order_category_code = cv_return_type THEN
                  SUM( ROUND( NVL(xola.quantity, 0), 2 ) * -1 )
                END
              END                              AS shipped_quantity    -- 出荷実績数量
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FROM    xxwsh_order_headers_all          xoha                   -- 受注ヘッダアドオン
            , xxwsh_order_lines_all            xola                   -- 受注明細アドオン
            , ic_item_mst_b                    imbc                   -- OPM品目マスタ（子）
            , ic_item_mst_b                    imbp                   -- OPM品目マスタ（親）
            , xxcmn_item_mst_b                 ximb                   -- OPM品目アドオンマスタ
            , mtl_system_items_b               msib                   -- Disc品目マスタ
            , hz_party_sites                   hps                    -- パーティサイトマスタ
            , hz_cust_accounts                 hca                    -- 顧客マスタ
            , xxcmm_cust_accounts              xca                    -- 顧客追加情報
            , oe_transaction_types_all         otta                   -- 受注タイプマスタ
            , oe_transaction_types_tl          ottt
            ,hz_locations                      hl                     -- 事業所マスタ
      WHERE  xoha.order_header_id   =   xola.order_header_id
      AND    xola.request_item_id   =   msib.inventory_item_id
      AND    imbc.item_no           =   msib.segment1
      AND    imbc.item_id           =   ximb.item_id
      AND    imbp.item_id           =   ximb.parent_item_id
-- == 2009/09/08 V1.8 Added START ===============================================================
      AND    ((xoha.req_status = gt_ship_status_result
               AND
               xoha.arrival_date BETWEEN ximb.start_date_active
                                 AND     NVL(ximb.end_date_active, xoha.arrival_date)
              )
              OR
              (xoha.req_status <> gt_ship_status_result
               AND
               xoha.schedule_arrival_date BETWEEN ximb.start_date_active
                                          AND     NVL(ximb.end_date_active, xoha.schedule_arrival_date)
              )
             )
-- == 2009/09/08 V1.8 Added END   ===============================================================
      AND    msib.organization_id   =   gt_org_id
      AND ( ( -- 締め済み、確定通知済出荷依頼（出荷依頼は削除明細を除外）
              xoha.req_status                          = gt_ship_status_close
              AND xoha.notif_status                    = gt_notice_status
              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
              AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_n_flag
              AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
              AND xoha.deliver_to_id                   = hps.party_site_id
            )
         OR ( -- 出荷実績計上済出荷実績（出荷実績は削除明細を除外、ただし出荷依頼連携済は対象）
              (xoha.actual_confirm_class               = cv_y_flag
              AND xoha.result_deliver_to_id            = hps.party_site_id)
              AND(( xoha.req_status                    = gt_ship_status_result
                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                   AND xola.shipping_result_if_flg     = cv_n_flag
                   AND NVL(xola.shipping_result_if_flg,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                  )
              OR ( xoha.req_status                     = gt_ship_status_result
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
                   AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                   AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                   AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                 ))
            )
         OR ( -- 出荷依頼連携済に対して取消を行ったものは対象
              xoha.req_status                                       = gt_ship_status_cancel
              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
              AND NVL(xola.shipping_request_if_flg,cv_n_flag)       = cv_y_flag
              AND NVL(xola.shipping_result_if_flg,cv_n_flag)        = cv_n_flag
              AND NVL(xola.delete_flag,cv_n_flag)                   = cv_y_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
            )
          )
      AND     otta.attribute1             = cv_1
      AND     NVL(otta.attribute4, cv_1) <> cv_2
      AND     otta.org_id                 = gt_itou_ou_id
      AND     otta.transaction_type_id    = ottt.transaction_type_id
      AND     ottt.language               = USERENV('LANG')
      AND NOT EXISTS ( SELECT   '1'
                       FROM     fnd_lookup_values flv
                       WHERE    flv.lookup_type   = cv_exclude_type
                       AND      flv.enabled_flag  = cv_y_flag
                       AND      flv.language      = USERENV('LANG')
                       AND      gd_process_date BETWEEN flv.start_date_active AND NVL ( flv.end_date_active , gd_process_date )
                       AND      ottt.name         = flv.meaning
                     )
      AND     xoha.order_type_id          = ottt.transaction_type_id
      AND     hps.party_id                = hca.party_id
      AND     hca.cust_account_id         = xca.customer_id
      AND     hca.customer_class_code     = cv_class_code
      AND     hca.status                  = cv_status_flag
      AND     hps.location_id             = hl.location_id
      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
      AND     xoha.latest_external_flag   = cv_y_flag
      GROUP BY  xoha.req_status
              , xoha.request_no
              , hca.account_number
              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                     xoha.result_deliver_to ELSE xoha.deliver_to END
              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
              , xoha.deliver_from
              , xola.request_item_code
              , imbp.item_no
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              , xola.delete_flag
              , NVL(xola.delete_flag,cv_n_flag)
-- == 2009/12/08 V1.12 Modified END   ===============================================================
              , xca.dept_hht_div
              , hl.province
              , imbc.attribute11
              , otta.order_category_code
      ORDER BY  xoha.req_status
              , xoha.request_no
              , hca.account_number
              , xola.request_item_code
              , imbp.item_no
-- == 2009/12/08 V1.12 Modified START ===============================================================
              , NVL(xola.delete_flag,cv_n_flag) DESC
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      ;
-- == 2009/06/03 V1.6 Modified END   ===============================================================
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
    -- カーソルオープン
    OPEN summary_cur;
    FETCH summary_cur BULK COLLECT INTO g_summary_tab;
--
    -- 対象処理件数
    gn_target_cnt := g_summary_tab.COUNT;
    -- サマリカウントセット
    gn_summary_cnt := g_summary_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE summary_cur;
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
      -- カーソルクローズ
      IF ( summary_cur%ISOPEN ) THEN
        CLOSE summary_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( summary_cur%ISOPEN ) THEN
        CLOSE summary_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( summary_cur%ISOPEN ) THEN
        CLOSE summary_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_summary_record;
--
  /**********************************************************************************
   * Procedure Name   : get_detail_record
   * Description      : 入庫情報詳細の抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_detail_record(
      in_slip_cnt   IN NUMBER                                         -- ループカウンタ
    , ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_detail_record';      -- プログラム名
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
    -- 入庫情報詳細の抽出
    CURSOR detail_cur(
      g_summary_tab g_summary_ttype )
    IS
-- == 2009/06/03 V1.6 Modified START ===============================================================
--      SELECT  xoha.req_status                  AS req_status          -- 出荷依頼ステータス
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.result_deliver_to ELSE xoha.deliver_to END
--                                               AS result_deliver_to   -- 出荷先_実績
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.arrival_date ELSE xoha.schedule_arrival_date END
--                                               AS arrive_date         -- 伝票日付
--            , xoha.request_no                  AS req_move_no         -- 依頼No
--            , xoha.deliver_from                AS deliver_from        -- 出荷元保管場所
--            , xola.request_item_code           AS item_no             -- 子品目コード
--            , imbp.item_no                     AS parent_item_no      -- 親品目コード
--            , hca.account_number               AS base_code           -- 拠点コード
--            , xola.delete_flag                 AS delete_flag         -- 削除フラグ
--            , xca.dept_hht_div                 AS dept_hht_div        -- 百貨店用HHT区分
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18                AS deliverly_code      -- 配送先コード
--            , hl.province                      AS deliverly_code
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--            , imbc.attribute11                 AS case_in_qty         -- ケース入数
--            , ilm.attribute3                   AS taste_term          -- 賞味期限
--            , ilm.attribute2                   AS difference_summary_code
--                                                                      -- 固有記号
--            , xola.order_header_id             AS order_header_id     -- 受注ヘッダID
--            , xola.order_line_id               AS order_line_id       -- 受注明細ID
---- == 2009/05/01 V1.4 Modified START ===============================================================
----            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
----                CASE WHEN otta.order_category_code = cv_order_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.shipped_quantity)
----                  SUM( ROUND( xola.shipped_quantity, 2 ) )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                     WHEN otta.order_category_code = cv_return_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.shipped_quantity) * -1
----                  SUM( ROUND( xola.shipped_quantity, 2 ) * -1 )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                END
----              ELSE
----                CASE WHEN otta.order_category_code = cv_order_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.quantity)
----                  SUM( ROUND( xola.quantity, 2 ) )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                     WHEN otta.order_category_code = cv_return_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.quantity) * -1
----                  SUM( ROUND( xola.quantity, 2 ) * -1 )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                END
--            , CASE WHEN otta.order_category_code = cv_order_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) )
--                   WHEN otta.order_category_code = cv_return_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) * -1 )
---- == 2009/05/01 V1.4 Modified END   ===============================================================
--              END                              AS shipped_quantity    -- 出荷実績数量
--      FROM    xxwsh_order_headers_all          xoha                   -- 受注ヘッダアドオン
--            , xxwsh_order_lines_all            xola                   -- 受注明細アドオン
--            , ic_item_mst_b                    imbc                   -- OPM品目マスタ（子）
--            , ic_item_mst_b                    imbp                   -- OPM品目マスタ（親）
--            , xxcmn_item_mst_b                 ximb                   -- OPM品目アドオンマスタ
--            , mtl_system_items_b               msib                   -- Disc品目マスタ
--            , hz_party_sites                   hps                    -- パーティサイトマスタ
--            , hz_cust_accounts                 hca                    -- 顧客マスタ
--            , hz_cust_acct_sites_all           hcasa                  -- 顧客所在地マスタ
--            , hz_cust_site_uses_all            hcaua                  -- 顧客使用目的マスタ
--            , xxcmm_cust_accounts              xca                    -- 顧客追加情報
--            , xxinv_mov_lot_details            xmld                   -- 移動ロット詳細(アドオン)
--            , ic_lots_mst                      ilm                    -- OPMロットマスタ
--            , oe_transaction_types_all         otta                   -- 受注タイプマスタ
--            , oe_transaction_types_tl          ottt
---- == 2009/04/16 V1.3 Added START ===============================================================
--            , hz_locations                     hl                     -- 事業所マスタ
---- == 2009/04/16 V1.3 Added END   ===============================================================
--      WHERE   xoha.order_header_id = xola.order_header_id
--      AND     xola.request_item_id = msib.inventory_item_id
--      AND     imbc.item_no         = msib.segment1
--      AND     imbc.item_id         = ximb.item_id
--      AND     imbp.item_id         = ximb.parent_item_id
--      AND     msib.organization_id = gt_org_id
--      AND ( ( -- 締め済み、確定通知済出荷依頼（出荷依頼は削除明細を除外）
--              xoha.req_status                          = gt_ship_status_close
--              AND xoha.notif_status                    = gt_notice_status
--              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
--              AND xoha.deliver_to_id                   = hps.party_site_id
--            )
--         OR ( -- 出荷実績計上済出荷実績（出荷実績は削除明細を除外、ただし出荷依頼連携済は対象）
--              (xoha.actual_confirm_class               = cv_y_flag
--              AND xoha.result_deliver_to_id            = hps.party_site_id)
--              AND(( xoha.req_status                    = gt_ship_status_result
--                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                  )
--              OR ( xoha.req_status                     = gt_ship_status_result
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                 ))
--            )
--         OR ( -- 出荷依頼連携済に対して取消を行ったものは対象
--              xoha.req_status                                       = gt_ship_status_cancel
--              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
--            )
--          )
--      AND     otta.attribute1             = cv_1
--      AND     NVL ( otta.attribute4 , cv_1 ) <> cv_2
--      AND     otta.org_id                 = gt_itou_ou_id
--      AND     otta.transaction_type_id    = ottt.transaction_type_id
--      AND     ottt.language               = USERENV('LANG')
--      AND     xoha.order_type_id          = ottt.transaction_type_id
--      AND     hps.party_id                = hca.party_id
--      AND     hca.cust_account_id         = hcasa.cust_account_id
--      AND     hcasa.cust_acct_site_id     = hcaua.cust_acct_site_id
--      AND     hcaua.site_use_code         = cv_site_use_code
--      AND     hcaua.status                = cv_status_flag
--      AND     hcaua.primary_flag          = cv_y_flag
--      AND     hca.cust_account_id         = xca.customer_id
--      AND     hca.customer_class_code     = cv_class_code
--      AND     hca.status                  = cv_status_flag
---- == 2009/04/16 V1.3 Modified START ===============================================================
----      AND     SUBSTRB ( hcasa.attribute18 , 1 , 1 ) = cv_0
--      AND     hps.location_id             = hl.location_id
--      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--      AND     xola.order_line_id          = xmld.mov_line_id(+)
--      AND     xmld.lot_id                 = ilm.lot_id(+)
--      AND     xmld.item_id                = ilm.item_id(+)
--      AND     xoha.req_status             = g_summary_tab ( in_slip_cnt ) .req_status
--      AND     xoha.request_no             = g_summary_tab ( in_slip_cnt ) .req_move_no
--      AND     xoha.deliver_from           = g_summary_tab ( in_slip_cnt ) .deliver_from
--      AND     xola.request_item_code      = g_summary_tab ( in_slip_cnt ) .item_no
--      AND ( (
--              xoha.req_status                IN ( gt_ship_status_close , gt_ship_status_cancel )
---- == 2009/04/16 V1.3 Modified START ===============================================================
----              AND xmld.record_type_code      = gt_lot_status_request
--              AND (   (xmld.record_type_code  = gt_lot_status_request)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              AND xoha.deliver_to            = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.schedule_arrival_date = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--         OR (
--              xoha.req_status            = gt_ship_status_result
---- == 2009/04/16 V1.3 Modified START ===============================================================
----              AND xmld.record_type_code  = gt_lot_status_results
--              AND (   (xmld.record_type_code  = gt_lot_status_results)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              AND xoha.result_deliver_to = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.arrival_date      = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--          )
---- == 2009/05/01 V1.4 Added START ==================================================================
--      AND     xoha.latest_external_flag   = cv_y_flag
---- == 2009/05/01 V1.4 Added END   ==================================================================
--      GROUP BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                     xoha.result_deliver_to ELSE xoha.deliver_to END
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
--              , xoha.deliver_from
--              , xola.request_item_code
--              , imbp.item_no
--              , xola.delete_flag
--              , xca.dept_hht_div
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18
--              , hl.province
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              , imbc.attribute11
--              , otta.order_category_code
--              , xmld.lot_no
--              , ilm.attribute3
--              , ilm.attribute2
--              , xola.order_header_id
--              , xola.order_line_id
--      ;
--
-- == 2009/11/06 V1.10 Modified START ===============================================================
--      SELECT  xoha.req_status                  AS req_status          -- 出荷依頼ステータス
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.result_deliver_to ELSE xoha.deliver_to END
--                                               AS result_deliver_to   -- 出荷先_実績
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.arrival_date ELSE xoha.schedule_arrival_date END
--                                               AS arrive_date         -- 伝票日付
--            , xoha.request_no                  AS req_move_no         -- 依頼No
--            , xoha.deliver_from                AS deliver_from        -- 出荷元保管場所
--            , xola.request_item_code           AS item_no             -- 子品目コード
--            , imbp.item_no                     AS parent_item_no      -- 親品目コード
--            , hca.account_number               AS base_code           -- 拠点コード
--            , xola.delete_flag                 AS delete_flag         -- 削除フラグ
--            , xca.dept_hht_div                 AS dept_hht_div        -- 百貨店用HHT区分
--            , hl.province                      AS deliverly_code
--            , imbc.attribute11                 AS case_in_qty         -- ケース入数
--            , ilm.attribute3                   AS taste_term          -- 賞味期限
--            , ilm.attribute2                   AS difference_summary_code
--                                                                      -- 固有記号
--            , xola.order_header_id             AS order_header_id     -- 受注ヘッダID
--            , xola.order_line_id               AS order_line_id       -- 受注明細ID
--            , CASE WHEN otta.order_category_code = cv_order_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) )
--                   WHEN otta.order_category_code = cv_return_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) * -1 )
--              END                              AS shipped_quantity    -- 出荷実績数量
--      FROM    xxwsh_order_headers_all          xoha                   -- 受注ヘッダアドオン
--            , xxwsh_order_lines_all            xola                   -- 受注明細アドオン
--            , ic_item_mst_b                    imbc                   -- OPM品目マスタ（子）
--            , ic_item_mst_b                    imbp                   -- OPM品目マスタ（親）
--            , xxcmn_item_mst_b                 ximb                   -- OPM品目アドオンマスタ
--            , mtl_system_items_b               msib                   -- Disc品目マスタ
--            , hz_party_sites                   hps                    -- パーティサイトマスタ
--            , hz_cust_accounts                 hca                    -- 顧客マスタ
--            , xxcmm_cust_accounts              xca                    -- 顧客追加情報
--            , xxinv_mov_lot_details            xmld                   -- 移動ロット詳細(アドオン)
--            , ic_lots_mst                      ilm                    -- OPMロットマスタ
--            , oe_transaction_types_all         otta                   -- 受注タイプマスタ
--            , oe_transaction_types_tl          ottt
--            , hz_locations                     hl                     -- 事業所マスタ
--      WHERE   xoha.order_header_id  =   xola.order_header_id
--      AND     xola.request_item_id  =   msib.inventory_item_id
--      AND     imbc.item_no          =   msib.segment1
--      AND     imbc.item_id          =   ximb.item_id
--      AND     imbp.item_id          =   ximb.parent_item_id
---- == 2009/09/08 V1.8 Added START ===============================================================
--      AND    ((xoha.req_status = gt_ship_status_result
--               AND
--               xoha.arrival_date BETWEEN ximb.start_date_active
--                                 AND     NVL(ximb.end_date_active, xoha.arrival_date)
--              )
--              OR
--              (xoha.req_status <> gt_ship_status_result
--               AND
--               xoha.schedule_arrival_date BETWEEN ximb.start_date_active
--                                          AND     NVL(ximb.end_date_active, xoha.schedule_arrival_date)
--              )
--             )
---- == 2009/09/08 V1.8 Added END   ===============================================================
--      AND     msib.organization_id  =   gt_org_id
--      AND ( ( -- 締め済み、確定通知済出荷依頼（出荷依頼は削除明細を除外）
--              xoha.req_status                          = gt_ship_status_close
--              AND xoha.notif_status                    = gt_notice_status
--              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
--              AND xoha.deliver_to_id                   = hps.party_site_id
--            )
--         OR ( -- 出荷実績計上済出荷実績（出荷実績は削除明細を除外、ただし出荷依頼連携済は対象）
--              (xoha.actual_confirm_class               = cv_y_flag
--              AND xoha.result_deliver_to_id            = hps.party_site_id)
--              AND(( xoha.req_status                    = gt_ship_status_result
--                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                  )
--              OR ( xoha.req_status                     = gt_ship_status_result
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                 ))
--            )
--         OR ( -- 出荷依頼連携済に対して取消を行ったものは対象
--              xoha.req_status                                       = gt_ship_status_cancel
--              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
--            )
--          )
--      AND     otta.attribute1             = cv_1
--      AND     NVL ( otta.attribute4 , cv_1 ) <> cv_2
--      AND     otta.org_id                 = gt_itou_ou_id
--      AND     otta.transaction_type_id    = ottt.transaction_type_id
--      AND     ottt.language               = USERENV('LANG')
--      AND     xoha.order_type_id          = ottt.transaction_type_id
--      AND     hps.party_id                = hca.party_id
--      AND     hca.cust_account_id         = xca.customer_id
--      AND     hca.customer_class_code     = cv_class_code
--      AND     hca.status                  = cv_status_flag
--      AND     hps.location_id             = hl.location_id
--      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
--      AND     xola.order_line_id          = xmld.mov_line_id(+)
--      AND     xmld.lot_id                 = ilm.lot_id(+)
--      AND     xmld.item_id                = ilm.item_id(+)
--      AND     xoha.req_status             = g_summary_tab ( in_slip_cnt ) .req_status
--      AND     xoha.request_no             = g_summary_tab ( in_slip_cnt ) .req_move_no
--      AND     xoha.deliver_from           = g_summary_tab ( in_slip_cnt ) .deliver_from
--      AND     xola.request_item_code      = g_summary_tab ( in_slip_cnt ) .item_no
--      AND ( (
--              xoha.req_status                IN ( gt_ship_status_close , gt_ship_status_cancel )
--              AND (   (xmld.record_type_code  = gt_lot_status_request)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
--              AND xoha.deliver_to            = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.schedule_arrival_date = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--         OR (
--              xoha.req_status            = gt_ship_status_result
--              AND (   (xmld.record_type_code  = gt_lot_status_results)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
--              AND xoha.result_deliver_to = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.arrival_date      = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--          )
--      AND     xoha.latest_external_flag   = cv_y_flag
--      GROUP BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                     xoha.result_deliver_to ELSE xoha.deliver_to END
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
--              , xoha.deliver_from
--              , xola.request_item_code
--              , imbp.item_no
--              , xola.delete_flag
--              , xca.dept_hht_div
--              , hl.province
--              , imbc.attribute11
--              , otta.order_category_code
--              , xmld.lot_no
--              , ilm.attribute3
--              , ilm.attribute2
--              , xola.order_header_id
--              , xola.order_line_id
--      ;
-- == 2009/06/03 V1.6 Modified END   ===============================================================
      SELECT
                    oiv.req_status                    AS  req_status                        -- 出荷依頼ステータス
                  , oiv.result_deliver_to             AS  result_deliver_to                 -- 出荷先_実績
                  , oiv.arrive_date                   AS  arrive_date                       -- 伝票日付
                  , oiv.req_move_no                   AS  req_move_no                       -- 依頼No
                  , oiv.deliver_from                  AS  deliver_from                      -- 出荷元保管場所
                  , oiv.item_no                       AS  item_no                           -- 子品目コード
                  , imbp.item_no                      AS  parent_item_no                    -- 親品目コード
                  , hca.account_number                AS  base_code                         -- 拠点コード
                  , oiv.delete_flag                   AS  delete_flag                       -- 削除フラグ
                  , xca.dept_hht_div                  AS  dept_hht_div                      -- 百貨店用HHT区分
                  , hl.province                       AS  deliverly_code                    -- 配送先コード
                  , imbc.attribute11                  AS  case_in_qty                       -- ケース入数
                  , oiv.taste_term                    AS  taste_term                        -- 賞味期限
                  , oiv.difference_summary_code       AS  difference_summary_code           -- 固有記号
                  , oiv.order_header_id               AS  order_header_id                   -- 受注ヘッダID
                  , oiv.order_line_id                 AS  order_line_id                     -- 受注明細ID
                  , CASE  WHEN oiv.order_category_code = cv_order_type
                            THEN  SUM(oiv.actual_quantity)
                          WHEN oiv.order_category_code = cv_return_type
                            THEN  SUM(oiv.actual_quantity * -1)
                    END                               AS  shipped_quantity                  -- 出荷実績数量
      FROM
                    ic_item_mst_b               imbc                  -- OPM品目マスタ（子）
                  , ic_item_mst_b               imbp                  -- OPM品目マスタ（親）
                  , xxcmn_item_mst_b            ximb                  -- OPM品目アドオンマスタ
                  , mtl_system_items_b          msib                  -- Disc品目マスタ
                  , hz_party_sites              hps                   -- パーティサイトマスタ
                  , hz_cust_accounts            hca                   -- 顧客マスタ
                  , xxcmm_cust_accounts         xca                   -- 顧客追加情報
                  , hz_locations                hl                    -- 事業所マスタ
                  , (
                      SELECT        xoha.req_status                     AS  req_status                  -- 出荷依頼ステータス
                                  , CASE  WHEN xoha.req_status = gt_ship_status_result
                                            THEN  xoha.result_deliver_to
                                            ELSE  xoha.deliver_to
                                    END                                 AS  result_deliver_to           -- 出荷先_実績
                                  , CASE  WHEN xoha.req_status = gt_ship_status_result
                                            THEN  xoha.arrival_date
                                            ELSE  xoha.schedule_arrival_date
                                    END                                 AS  arrive_date                 -- 伝票日付
                                  , xoha.request_no                     AS  req_move_no                 -- 依頼No
                                  , xoha.deliver_from                   AS  deliver_from                -- 出荷元保管場所
                                  , xola.request_item_code              AS  item_no                     -- 子品目コード
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                  , xola.delete_flag                    AS  delete_flag                 -- 削除フラグ
                                  , NVL(xola.delete_flag,cv_n_flag)     AS  delete_flag                 -- 削除フラグ
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                  , ilm.attribute3                      AS  taste_term                  -- 賞味期限
                                  , ilm.attribute2                      AS  difference_summary_code     -- 固有記号
                                  , xola.order_header_id                AS  order_header_id             -- 受注ヘッダID
                                  , xola.order_line_id                  AS  order_line_id               -- 受注明細ID
                                  , otta.order_category_code            AS  order_category_code         -- 受注カテゴリ
-- == 2009/12/18 V1.14 Modified START ===============================================================
--                                   , ROUND( xmld.actual_quantity, 2 )    AS  actual_quantity             -- 出荷実績数量
                                  , ROUND( NVL(xmld.actual_quantity, 0), 2 )    AS  actual_quantity             -- 出荷実績数量
-- == 2009/12/18 V1.14 Modified END   ===============================================================
                                  , xmld.lot_no                         AS  lot_no                      -- ロット番号
                                  , xola.request_item_id                AS  request_item_id             -- 品目ID
                                  , CASE  WHEN      xoha.req_status                   = gt_ship_status_close
                                                AND xoha.notif_status                 = gt_notice_status
                                                AND NVL(xola.delete_flag,cv_n_flag)   = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.shipping_request_if_flg      = cv_n_flag
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
                                                AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_n_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN  xoha.deliver_to_id
                                          WHEN      xoha.actual_confirm_class         = cv_y_flag
                                                AND xoha.req_status                   = gt_ship_status_result
                                                AND NVL(xola.delete_flag,cv_n_flag)   = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN  xoha.result_deliver_to_id
                                          WHEN      xoha.actual_confirm_class         = cv_y_flag
                                                AND xoha.req_status                   = gt_ship_status_result
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.delete_flag                  = cv_y_flag
--                                                AND xola.shipping_request_if_flg      = cv_y_flag
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
                                                AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                                                AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN  xoha.result_deliver_to_id
                                          WHEN      xoha.req_status                   = gt_ship_status_cancel
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.shipping_request_if_flg      = cv_y_flag
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
--                                                AND xola.delete_flag                  = cv_y_flag
                                                AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
                                                AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN NVL(xoha.deliver_to_id, xoha.result_deliver_to_id)
                                    END                                 AS  party_site_id               -- パーティサイト結合ID
                      FROM
                                  xxwsh_order_headers_all           xoha                                -- 受注ヘッダアドオン
                                , xxwsh_order_lines_all             xola                                -- 受注明細アドオン
                                , xxinv_mov_lot_details             xmld                                -- 移動ロット詳細(アドオン)
                                , ic_lots_mst                       ilm                                 -- OPMロットマスタ
                                , oe_transaction_types_all          otta                                -- 受注タイプマスタ
                      WHERE       xoha.order_header_id              =   xola.order_header_id
                      AND         xoha.order_type_id                =   otta.transaction_type_id
                      AND         otta.attribute1                   =   cv_1
                      AND         NVL ( otta.attribute4 , cv_1 )    <>  cv_2
                      AND         otta.org_id                       =   gt_itou_ou_id
                      AND         otta.transaction_type_code        =   cv_order_type
                      AND         xola.order_line_id                =   xmld.mov_line_id(+)
                      AND         xmld.lot_id                       =   ilm.lot_id(+)
                      AND         xmld.item_id                      =   ilm.item_id(+)
                      AND         xoha.req_status                   =   g_summary_tab ( in_slip_cnt ) .req_status
                      AND         xoha.request_no                   =   g_summary_tab ( in_slip_cnt ) .req_move_no
                      AND         xoha.deliver_from                 =   g_summary_tab ( in_slip_cnt ) .deliver_from
                      AND         xola.request_item_code            =   g_summary_tab ( in_slip_cnt ) .item_no
                      AND         xoha.latest_external_flag         =   cv_y_flag
                      AND(        ( -- 締め済み、確定通知済出荷依頼（出荷依頼は削除明細を除外）
                                        xoha.req_status                         = gt_ship_status_close
                                    AND xoha.notif_status                       = gt_notice_status
                                    AND NVL(xola.delete_flag,cv_n_flag)         = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                    AND xola.shipping_request_if_flg            = cv_n_flag
--                                    AND xola.shipping_result_if_flg             = cv_n_flag
                                    AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_n_flag
                                    AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                  )
                                  OR
                                  ( -- 出荷実績計上済出荷実績（出荷実績は削除明細を除外、ただし出荷依頼連携済は対象）
                                        xoha.actual_confirm_class               = cv_y_flag
                                    AND xoha.req_status                         = gt_ship_status_result
                                    AND(
                                        (     NVL(xola.delete_flag,cv_n_flag)   = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                          AND xola.shipping_result_if_flg       = cv_n_flag
                                          AND NVL(xola.shipping_result_if_flg,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                        )
                                        OR
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                        (     xola.delete_flag                  = cv_y_flag
--                                          AND xola.shipping_request_if_flg      = cv_y_flag
--                                          AND xola.shipping_result_if_flg       = cv_n_flag
                                        (     NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                                          AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                          AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                        )
                                    )
                                  )
                                  OR
                                  ( -- 出荷依頼連携済に対して取消を行ったものは対象
                                        xoha.req_status                         = gt_ship_status_cancel
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                    AND xola.shipping_request_if_flg            = cv_y_flag
--                                    AND xola.shipping_result_if_flg             = cv_n_flag
--                                    AND xola.delete_flag                        = cv_y_flag
                                    AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                                    AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                    AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                  )
                      )
                      AND(        (
                                        xoha.req_status               IN (gt_ship_status_close, gt_ship_status_cancel)
                                    AND xoha.deliver_to               = g_summary_tab ( in_slip_cnt ) .result_deliver_to
                                    AND xoha.schedule_arrival_date    = g_summary_tab ( in_slip_cnt ) .slip_date
                                    AND (     (xmld.record_type_code  = gt_lot_status_request)
                                          OR  (xmld.record_type_code  IS NULL)
                                    )
                                  )
                                  OR
                                  (
                                        xoha.req_status               = gt_ship_status_result
                                    AND xoha.result_deliver_to        = g_summary_tab ( in_slip_cnt ) .result_deliver_to
                                    AND xoha.arrival_date             = g_summary_tab ( in_slip_cnt ) .slip_date
                                    AND (     (xmld.record_type_code  = gt_lot_status_results)
                                          OR  (xmld.record_type_code  IS NULL)
                                    )
                                  )
                      )
                    )                           oiv                   -- 受注情報View
      WHERE     msib.inventory_item_id      =   oiv.request_item_id
      AND       msib.organization_id        =   gt_org_id
      AND       msib.segment1               =   imbc.item_no
      AND       imbc.item_id                =   ximb.item_id
      AND       imbp.item_id                =   ximb.parent_item_id
      AND       hps.party_id                =   hca.party_id
      AND       hca.customer_class_code     =   cv_class_code
      AND       hca.status                  =   cv_status_flag
      AND       hca.cust_account_id         =   xca.customer_id
      AND       hps.location_id             =   hl.location_id
      AND       SUBSTRB(hl.province, 1, 1)  =   cv_0
      AND       oiv.arrive_date   BETWEEN   ximb.start_date_active
                                  AND       NVL(ximb.end_date_active, oiv.arrive_date)
      AND       oiv.party_site_id           =   hps.party_site_id
      GROUP BY
                oiv.req_status
              , oiv.req_move_no
              , hca.account_number
              , oiv.result_deliver_to
              , oiv.arrive_date
              , oiv.deliver_from
              , oiv.item_no
              , imbp.item_no
              , oiv.delete_flag
              , xca.dept_hht_div
              , hl.province
              , imbc.attribute11
              , oiv.order_category_code
              , oiv.lot_no
              , oiv.taste_term
              , oiv.difference_summary_code
              , oiv.order_header_id
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              , oiv.order_line_id;
              , oiv.order_line_id
      ORDER BY  oiv.delete_flag   DESC
      ;
-- == 2009/12/08 V1.12 Modified END   ===============================================================
-- == 2009/11/06 V1.10 Modified END   ===============================================================
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
    -- カーソルオープン
    OPEN detail_cur(
      g_summary_tab );
    FETCH detail_cur BULK COLLECT INTO g_detail_tab;
--
    -- 詳細カウントセット
    gn_detail_cnt := g_detail_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE detail_cur;
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
      -- カーソルクローズ
      IF ( detail_cur%ISOPEN ) THEN
        CLOSE detail_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( detail_cur%ISOPEN ) THEN
        CLOSE detail_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( detail_cur%ISOPEN ) THEN
        CLOSE detail_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_detail_record;
--
  /**********************************************************************************
   * Procedure Name   : get_subinventories
   * Description      : 保管場所情報処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_subinventories(
      iv_base_code              IN VARCHAR2                                         -- 1.拠点コード
-- == 2009/04/16 V1.3 Added START ===============================================================
    , it_deliverly_code         IN  hz_locations.province%TYPE                      -- 2.配送先コード
-- == 2009/04/16 V1.3 Added END   ===============================================================
    , it_org_id                 IN mtl_secondary_inventories.organization_id%TYPE   -- 3.在庫組織ID
    , ot_store_code             OUT xxcoi_subinventory_info_v.store_code%TYPE       -- 4.倉庫コード
    , ot_shop_code              OUT xxcoi_subinventory_info_v.shop_code%TYPE        -- 5.店舗コード
    , ot_auto_confirmation_flag OUT mtl_secondary_inventories.attribute11%TYPE      -- 6.自動入庫確認フラグ
    , ov_errbuf                 OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    , ov_retcode                OUT VARCHAR2     --   リターン・コード             --# 固定 #
    , ov_errmsg                 OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_subinventories';     -- プログラム名
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
    lt_store_code        xxcoi_subinventory_info_v.store_code%TYPE;   -- 倉庫コード
    ln_valid_cnt         NUMBER;
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
    --==============================================================
    --1.本社拠点倉庫コードの取得
    --==============================================================
-- == 2009/04/16 V1.3 Modified START ===============================================================
--    BEGIN
--      SELECT xsi.store_code
--      INTO   lt_store_code
--      FROM   xxcoi_subinventory_info_v xsi
--      WHERE  xsi.base_code              = iv_base_code
--      AND    xsi.base_code NOT LIKE '7%'
--      AND    xsi.organization_id        = it_org_id
--      AND    xsi.auto_confirmation_flag = cv_y_flag
--      AND    xsi.subinventory_class     = cv_1
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--    --==============================================================
--    --2.顧客所在地マスタより倉庫コードの取得
--    --==============================================================
--        BEGIN
--          SELECT  SUBSTRB ( hcasa.attribute18 , LENGTHB(hcasa.attribute18)-1 , 2 )
--          INTO    lt_store_code
--          FROM    hz_cust_accounts        hca             -- 顧客マスタ
--                , hz_cust_acct_sites_all  hcasa           -- 顧客所在地
--                , hz_cust_site_uses_all   hcsua           -- 顧客使用目的
--          WHERE   hca.account_number      = iv_base_code
--          AND     hca.cust_account_id     = hcasa.cust_account_id
--          AND     hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
--          AND     hca.customer_class_code = cv_class_code
--          AND     hca.status              = cv_status_flag
--          AND     hcsua.site_use_code     = cv_site_use_code
--          AND     hcsua.status            = hca.status
--          AND     hcsua.primary_flag      = cv_y_flag
--          ;
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            RAISE subinventory_found_expt;
--        END;
--    END;
--
-- == 2009/10/26 V1.9 Modified START ===============================================================
    --==============================================================
    --1.倉庫コードの取得
    --==============================================================
--    lt_store_code :=  SUBSTRB ( it_deliverly_code , LENGTHB(it_deliverly_code)-1 , 2 );
-- == 2009/04/16 V1.3 Added END   ===============================================================
    BEGIN
      SELECT  xsi.store_code
      INTO    lt_store_code
      FROM    xxcoi_subinventory_info_v xsi
      WHERE   xsi.base_code               =   iv_base_code
      AND     xsi.organization_id         =   it_org_id
      AND     xsi.auto_confirmation_flag  =   cv_y_flag
      AND     xsi.main_store_class        =   cv_y_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_store_code :=  SUBSTRB ( it_deliverly_code , LENGTHB(it_deliverly_code)-1 , 2 );
      WHEN TOO_MANY_ROWS THEN
        RAISE main_store_expt;
    END;
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
    --==============================================================
    --3.1で取得した倉庫コードより保管場所の存在チェックを行う
    --==============================================================
    SELECT COUNT(1)
    INTO   ln_valid_cnt
    FROM   xxcoi_subinventory_info_v xsi
    WHERE  xsi.base_code        = iv_base_code
    AND    xsi.store_code       = lt_store_code
    AND    xsi.organization_id  = it_org_id
    AND    ROWNUM = 1
    ;
--
    IF ( ln_valid_cnt = 0 ) THEN
      RAISE subinventory_found_expt;
    END IF;
--
    --==============================================================
    --4.1で取得した倉庫コードより保管場所の有効チェックを行う
    --==============================================================
    BEGIN
      SELECT  xsi.store_code
            , xsi.auto_confirmation_flag
      INTO    ot_store_code
            , ot_auto_confirmation_flag
      FROM    xxcoi_subinventory_info_v xsi
      WHERE   xsi.base_code = iv_base_code
      AND     xsi.store_code = lt_store_code
      AND     xsi.organization_id = it_org_id
      AND     ( xsi.disable_date IS NULL
              OR xsi.disable_date > gd_process_date )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE subinventory_disable_expt;
      WHEN TOO_MANY_ROWS THEN
        RAISE subinventory_plural_expt;
    END;
--
    --==============================================================
    --5.拠点コードを元に預け先店舗コードの取得を行う
    --==============================================================
    BEGIN
      SELECT  xsi.shop_code
      INTO    ot_shop_code
      FROM    xxcoi_subinventory_info_v xsi
      WHERE   xsi.base_code = iv_base_code
      AND     xsi.organization_id = it_org_id
      AND     xsi.subinventory_class = cv_subinv_class
      AND     xsi.subinventory_type = cv_subinv_type
      AND     ( xsi.disable_date IS NULL
              OR xsi.disable_date > gd_process_date )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ot_shop_code := NULL;
      WHEN TOO_MANY_ROWS THEN
        ot_shop_code := NULL;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- == 2009/10/26 V1.9 Modified START ===============================================================
    WHEN main_store_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_code_10379
                       , iv_token_name1  => cv_token_10379
                       , iv_token_value1 => iv_base_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
-- == 2009/10/26 V1.9 Modified END   ===============================================================
    WHEN subinventory_found_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_subinventory_found_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => iv_base_code
                       , iv_token_name2  => cv_tkn_warehouse
                       , iv_token_value2 => lt_store_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN subinventory_disable_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_subinventory_disable_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => iv_base_code
                       , iv_token_name2  => cv_tkn_warehouse
                       , iv_token_value2 => lt_store_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN subinventory_plural_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_subinventory_plural_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => iv_base_code
                       , iv_token_name2  => cv_tkn_warehouse
                       , iv_token_value2 => lt_store_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
--      ROLLBACK TO SAVEPOINT summary_point;
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
  END get_subinventories;
--
  /**********************************************************************************
   * Procedure Name   : ins_summary_unconfirmed
   * Description      : 入庫情報サマリの登録[入庫未確認](A-5)
   ***********************************************************************************/
  PROCEDURE ins_summary_unconfirmed(
      in_slip_cnt    IN NUMBER                                        -- 1.ループカウンタ
    , iv_store_code  IN VARCHAR2                                      -- 2.倉庫コード
    , iv_shop_code   IN VARCHAR2                                      -- 3.店舗コード
    , it_auto_confirmation_flag IN mtl_secondary_inventories.attribute11%TYPE
                                                                      -- 4.自動入庫確認フラグ
    , ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_summary_unconfirmed';-- プログラム名
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
    --================================
    --入庫情報一時表へのデータ登録
    --================================
    INSERT INTO xxcoi_storage_information(
        transaction_id
      , base_code
      , warehouse_code
      , slip_date
      , slip_num
      , req_status
      , parent_item_code
      , item_code
      , case_in_qty
      , ship_case_qty
      , ship_singly_qty
      , ship_summary_qty
      , ship_warehouse_code
      , check_warehouse_code
      , check_case_qty
      , check_singly_qty
      , check_summary_qty
      , material_transaction_unset_qty
      , slip_type
      , ship_base_code
      , taste_term
      , difference_summary_code
      , summary_data_flag
      , store_check_flag
      , material_transaction_set_flag
      , auto_store_check_flag
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date
    ) VALUES (
        xxcoi_storage_information_s01.nextval                         -- 取引ID
      , g_summary_tab ( in_slip_cnt ) .base_code                      -- 拠点コード
      , iv_store_code                                                 -- 倉庫コード
      , g_summary_tab ( in_slip_cnt ) .slip_date                      -- 伝票日付
      , gv_slip_num                                                   -- 伝票No
      , g_summary_tab ( in_slip_cnt ) .req_status                     -- 出荷依頼ステータス
      , g_summary_tab ( in_slip_cnt ). parent_item_no                 -- 親品目コード
      , g_summary_tab ( in_slip_cnt ). item_no                        -- 子品目コード
      , g_summary_tab ( in_slip_cnt ). case_in_qty                    -- 入数
-- == 2009/12/08 V1.12 Modified START ===============================================================
--      , TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty )
--                                                                      -- 出庫数量ケース数
--      , MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) )
--                                                                      -- 出庫数量バラ数
--      , g_summary_tab ( in_slip_cnt ) .shipped_qty                    -- 出荷数量総バラ数
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
                                                                      -- 出庫数量ケース数
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
                                                                      -- 出庫数量バラ数
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          g_summary_tab ( in_slip_cnt ) .shipped_qty )                -- 出荷数量総バラ数
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      , DECODE ( g_summary_tab ( in_slip_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
                                                                      -- 転送先倉庫コード
      , iv_store_code                                                 -- 確認倉庫コード
      , 0                                                             -- 確認数量ケース数
      , 0                                                             -- 確認数量バラ数
      , 0                                                             -- 確認数量総バラ数
      , 0                                                             -- 資材取引未連携数量
      , cv_slip_type                                                  -- 伝票区分
      , g_summary_tab ( in_slip_cnt ) .deliver_from                   -- 出庫拠点コード
      , NULL                                                          -- 賞味期限
      , NULL                                                          -- 工場固有記号
      , cv_y_flag                                                     -- サマリーデータフラグ
      , cv_n_flag                                                     -- 入庫確認フラグ
      , cv_n_flag                                                     -- 資材取引連携済フラグ
      , it_auto_confirmation_flag                                     -- 自動入庫確認フラグ
      , cn_created_by
      , SYSDATE
      , cn_last_updated_by
      , SYSDATE
      , cn_last_update_login
      , cn_request_id
      , cn_program_application_id
      , cn_program_id
      , SYSDATE
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
  END ins_summary_unconfirmed;
--
  /**********************************************************************************
   * Procedure Name   : ins_summary_confirmed
   * Description      : 入庫情報サマリの登録[入庫確認済](A-6)
   ***********************************************************************************/
  PROCEDURE ins_summary_confirmed(
      in_slip_cnt    IN NUMBER                                        -- 1.ループカウンタ
    , iv_store_code  IN VARCHAR2                                      -- 2.倉庫コード
    , iv_shop_code   IN VARCHAR2                                      -- 3.店舗コード
    , it_auto_confirmation_flag IN mtl_secondary_inventories.attribute11%TYPE
                                                                      -- 4.自動入庫確認フラグ
    , ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_summary_confirmed';  -- プログラム名
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
    --================================
    --入庫情報一時表へのデータ登録
    --================================
    INSERT INTO xxcoi_storage_information(
        transaction_id
      , base_code
      , warehouse_code
      , slip_date
      , slip_num
      , req_status
      , parent_item_code
      , item_code
      , case_in_qty
      , ship_case_qty
      , ship_singly_qty
      , ship_summary_qty
      , ship_warehouse_code
      , check_warehouse_code
      , check_case_qty
      , check_singly_qty
      , check_summary_qty
      , material_transaction_unset_qty
      , slip_type
      , ship_base_code
      , taste_term
      , difference_summary_code
      , summary_data_flag
      , store_check_flag
      , material_transaction_set_flag
      , auto_store_check_flag
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date
    ) VALUES (
        xxcoi_storage_information_s01.nextval                         -- 取引ID
      , g_summary_tab ( in_slip_cnt ) .base_code                      -- 拠点コード
      , iv_store_code                                                 -- 倉庫コード
      , g_summary_tab ( in_slip_cnt ) .slip_date                      -- 伝票日付
      , gv_slip_num                                                   -- 伝票No
      , g_summary_tab ( in_slip_cnt ) .req_status                     -- 出荷依頼ステータス
      , g_summary_tab ( in_slip_cnt ) .parent_item_no                 -- 親品目コード
      , g_summary_tab ( in_slip_cnt ) .item_no                        -- 子品目コード
      , g_summary_tab ( in_slip_cnt ) .case_in_qty                    -- 入数
-- == 2009/12/08 V1.12 Modified START ===============================================================
--      , TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty )
--                                                                      -- 出庫数量ケース数
--      , MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) )
--                                                                      -- 出庫数量バラ数
--      , g_summary_tab ( in_slip_cnt ) .shipped_qty                    -- 出荷数量総バラ数
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
                                                                      -- 出庫数量ケース数
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
                                                                      -- 出庫数量バラ数
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          g_summary_tab ( in_slip_cnt ) .shipped_qty )                -- 出荷数量総バラ数
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      , DECODE ( g_summary_tab ( in_slip_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
                                                                      -- 転送先倉庫コード
      , iv_store_code                                                 -- 確認倉庫コード
      , 0                                                             -- 確認数量ケース数
      , 0                                                             -- 確認数量バラ数
      , 0                                                             -- 確認数量総バラ数
      , 0                                                             -- 資材取引未連携数量
      , cv_slip_type                                                  -- 伝票区分
      , g_summary_tab ( in_slip_cnt ) .deliver_from                   -- 出庫拠点コード
      , NULL                                                          -- 賞味期限
      , NULL                                                          -- 工場固有記号
      , cv_y_flag                                                     -- サマリーデータフラグ
      , cv_y_flag                                                     -- 入庫確認フラグ
      , cv_n_flag                                                     -- 資材取引連携済フラグ
      , it_auto_confirmation_flag                                     -- 自動入庫確認フラグ
      , cn_created_by
      , SYSDATE
      , cn_last_updated_by
      , SYSDATE
      , cn_last_update_login
      , cn_request_id
      , cn_program_application_id
      , cn_program_id
      , SYSDATE
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
  END ins_summary_confirmed;
--
  /**********************************************************************************
   * Procedure Name   : upd_summary_disp
   * Description      : 入庫情報サマリの更新[出荷依頼ステータスNULL対象](A-7)
   ***********************************************************************************/
  PROCEDURE upd_summary_disp(
      in_slip_cnt   IN NUMBER                                          -- 1.ループカウンタ
    , iv_rowid      IN ROWID                                           -- 2.更新対象ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
    , iv_store_code IN VARCHAR2                                        -- 3.倉庫コード
-- == 2009/12/18 V1.14 Added END   ===============================================================
    , ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_summary_disp';       -- プログラム名
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
-- == 2009/12/18 V1.14 Modified START ===============================================================
--      WHERE  xsi.rowid = iv_rowid
      WHERE  xsi.slip_num          = gv_slip_num
      AND    xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND    xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND    xsi.warehouse_code    = iv_store_code
      AND    xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND    xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND    xsi.slip_type         = cv_slip_type
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FOR UPDATE NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --入庫情報一時表のロック取得
    -- ===============================
    OPEN upd_xsi_tbl_cur;
--
    -- レコード読込
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- 入庫情報サマリの更新
      UPDATE  xxcoi_storage_information xsi
      SET     req_status             = g_summary_tab ( in_slip_cnt ) .req_status
            , case_in_qty            = g_summary_tab ( in_slip_cnt ) .case_in_qty
            , ship_case_qty          = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
                                               / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
            , ship_singly_qty        = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
                                               NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty       = g_summary_tab ( in_slip_cnt ) .shipped_qty
            , ship_base_code         = g_summary_tab ( in_slip_cnt ) .deliver_from
            , last_updated_by        = cn_last_updated_by
            , last_update_date       = SYSDATE
            , last_update_login      = cn_last_update_login
            , request_id             = cn_request_id
            , program_application_id = cn_program_application_id
            , program_id             = cn_program_id
            , program_update_date    = SYSDATE
-- == 2010/01/04 V1.15 Modified START ===============================================================
--      WHERE  xsi.rowid               = upd_xsi_tbl_rec.rowid
      WHERE  xsi.rowid               = iv_rowid
-- == 2010/01/04 V1.15 Modified END   ===============================================================
      ;
--
    -- カーソルクローズ
    CLOSE upd_xsi_tbl_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_summary_disp;
--
  /**********************************************************************************
   * Procedure Name   : upd_summary_close（ループ部）
   * Description      : 入庫情報サマリの更新[出荷依頼ステータス03対象](A-8)
   ***********************************************************************************/
  PROCEDURE upd_summary_close(
      in_slip_cnt   IN NUMBER                                          -- 1.ループカウンタ
    , iv_rowid      IN ROWID                                           -- 2.更新対象ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
    , iv_store_code IN VARCHAR2                                        -- 3.倉庫コード
-- == 2009/12/18 V1.14 Added END   ===============================================================
    , ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_summary_close';      -- プログラム名
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
-- == 2009/12/18 V1.14 Modified START ===============================================================
--       WHERE  xsi.rowid = iv_rowid
      WHERE  xsi.slip_num          = gv_slip_num
      AND    xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND    xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND    xsi.warehouse_code    = iv_store_code
      AND    xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND    xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND    xsi.slip_type         = cv_slip_type
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FOR UPDATE NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --入庫情報一時表のロック取得
    -- ===============================
    OPEN upd_xsi_tbl_cur;
--
    -- レコード読込
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- 入庫情報サマリの更新
      UPDATE xxcoi_storage_information xsi
      SET     req_status             = g_summary_tab ( in_slip_cnt ) .req_status
            , ship_case_qty          = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
                                               / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
            , ship_singly_qty        = DECODE( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
                                             NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty       = DECODE( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         g_summary_tab ( in_slip_cnt ) .shipped_qty )
            , ship_base_code         = g_summary_tab ( in_slip_cnt ) .deliver_from
            , last_updated_by        = cn_last_updated_by
            , last_update_date       = SYSDATE
            , last_update_login      = cn_last_update_login
            , request_id             = cn_request_id
            , program_application_id = cn_program_application_id
            , program_id             = cn_program_id
            , program_update_date    = SYSDATE
-- == 2010/01/04 V1.15 Modified START ===============================================================
--      WHERE  xsi.rowid               = upd_xsi_tbl_rec.rowid
      WHERE  xsi.rowid               = iv_rowid
-- == 2010/01/04 V1.15 Modified END   ===============================================================
      ;
--
    -- カーソルクローズ
    CLOSE upd_xsi_tbl_cur;
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_summary_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_summary_results（ループ部）
   * Description      : 入庫情報サマリの更新[出荷依頼ステータス04対象](A-9)
   ***********************************************************************************/
  PROCEDURE upd_summary_results(
      in_slip_cnt   IN NUMBER                                          -- 1.ループカウンタ
    , iv_rowid      IN ROWID                                           -- 2.更新対象ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
    , iv_store_code IN VARCHAR2                                        -- 3.倉庫コード
-- == 2009/12/18 V1.14 Added END   ===============================================================
    , ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_summary_results';    -- プログラム名
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
-- == 2009/12/18 V1.14 Modified START ===============================================================
--       WHERE  xsi.rowid = iv_rowid
      WHERE  xsi.slip_num          = gv_slip_num
      AND    xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND    xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND    xsi.warehouse_code    = iv_store_code
      AND    xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND    xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND    xsi.slip_type         = cv_slip_type
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FOR UPDATE NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --入庫情報一時表のロック取得
    -- ===============================
    OPEN upd_xsi_tbl_cur;
--
    -- レコード読込
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- 入庫情報サマリの更新
      UPDATE xxcoi_storage_information xsi
      SET     ship_case_qty          = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                         ship_case_qty + TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
                                         TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                           / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
            , ship_singly_qty        = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                         ship_singly_qty + MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
                                         MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                           NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty       = DECODE( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                         ship_summary_qty + g_summary_tab ( in_slip_cnt ) .shipped_qty )
                                         g_summary_tab ( in_slip_cnt ) .shipped_qty )
-- == 2009/05/01 V1.4 Modified END   ===============================================================
            , ship_base_code         = g_summary_tab ( in_slip_cnt ) .deliver_from
            , last_updated_by        = cn_last_updated_by
            , last_update_date       = SYSDATE
            , last_update_login      = cn_last_update_login
            , request_id             = cn_request_id
            , program_application_id = cn_program_application_id
            , program_id             = cn_program_id
            , program_update_date    = SYSDATE
-- == 2010/01/04 V1.15 Modified START ===============================================================
--      WHERE  xsi.rowid               = upd_xsi_tbl_rec.rowid
      WHERE  xsi.rowid               = iv_rowid
-- == 2010/01/04 V1.15 Modified END   ===============================================================
      ;
--
    -- カーソルクローズ
    CLOSE upd_xsi_tbl_cur;
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_summary_results;
--
  /**********************************************************************************
   * Procedure Name   : ins_detail_confirmed（ループ部）
   * Description      : 入庫情報詳細の登録(A-10)
   ***********************************************************************************/
  PROCEDURE ins_detail_confirmed(
      in_line_cnt    IN NUMBER                                        -- 1.ループカウンタ
    , iv_store_code  IN VARCHAR2                                      -- 2.倉庫コード
    , iv_shop_code   IN VARCHAR2                                      -- 3.店舗コード
    , it_auto_confirmation_flag IN mtl_secondary_inventories.attribute11%TYPE
                                                                      -- 4.自動入庫確認フラグ
    , ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_detail_confirmed';   -- プログラム名
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
    --==============================================================
    --入庫未確認リスト帳票ワークテーブルへのデータ登録
    --==============================================================
    INSERT INTO xxcoi_storage_information(
        transaction_id
      , base_code
      , warehouse_code
      , slip_date
      , slip_num
      , req_status
      , parent_item_code
      , item_code
      , case_in_qty
      , ship_case_qty
      , ship_singly_qty
      , ship_summary_qty
      , ship_warehouse_code
      , check_warehouse_code
      , check_case_qty
      , check_singly_qty
      , check_summary_qty
      , material_transaction_unset_qty
      , slip_type
      , ship_base_code
      , taste_term
      , difference_summary_code
      , summary_data_flag
      , store_check_flag
      , material_transaction_set_flag
      , auto_store_check_flag
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date
    ) VALUES (
        xxcoi_storage_information_s01.nextval                          -- 取引ID
      , g_detail_tab(in_line_cnt).base_code                            -- 拠点コード
      , iv_store_code                                                  -- 倉庫コード
      , g_detail_tab(in_line_cnt).slip_date                            -- 伝票日付
      , gv_slip_num                                                    -- 伝票No
      , g_detail_tab(in_line_cnt).req_status                           -- 出荷依頼ステータス
      , g_detail_tab(in_line_cnt).parent_item_no                       -- 親品目コード
      , g_detail_tab(in_line_cnt).item_no                              -- 子品目コード
      , g_detail_tab(in_line_cnt).case_in_qty                          -- 入数
-- == 2009/12/08 V1.12 Modified START ===============================================================
--      , TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty / g_detail_tab ( in_line_cnt ) .case_in_qty )
--                                                                       -- 出庫数量ケース数
--      , MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty , NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) )
--                                                                       -- 出庫数量バラ数
--      , g_detail_tab ( in_line_cnt ). shipped_qty                      -- 出荷数量総バラ数
      , DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
          TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty / g_detail_tab ( in_line_cnt ) .case_in_qty ) )
                                                                       -- 出庫数量ケース数
      , DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
          MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty , NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) ) )
                                                                       -- 出庫数量バラ数
      , DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
          g_detail_tab ( in_line_cnt ). shipped_qty )                  -- 出荷数量総バラ数
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      , DECODE ( g_detail_tab ( in_line_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
                                                                       -- 転送先倉庫コード
      , iv_store_code                                                  -- 確認倉庫コード
      , 0                                                              -- 確認数量ケース数
      , 0                                                              -- 確認数量バラ数
      , 0                                                              -- 確認数量総バラ数
      , 0                                                              -- 資材取引未連携数量
      , cv_slip_type                                                   -- 伝票区分
      , g_detail_tab ( in_line_cnt ) .deliver_from                     -- 出庫拠点コード
      , g_detail_tab ( in_line_cnt ) .taste_term                       -- 賞味期限
      , g_detail_tab ( in_line_cnt ) .difference_summary_code          -- 工場固有記号
      , cv_n_flag                                                      -- サマリーデータフラグ
      , cv_n_flag                                                      -- 入庫確認フラグ
      , cv_n_flag                                                      -- 資材取引連携済フラグ
      , it_auto_confirmation_flag                                      -- 自動入庫確認フラグ
      , cn_created_by
      , SYSDATE
      , cn_last_updated_by
      , SYSDATE
      , cn_last_update_login
      , cn_request_id
      , cn_program_application_id
      , cn_program_id
      , SYSDATE
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
  END ins_detail_confirmed;
--
  /**********************************************************************************
   * Procedure Name   : upd_detail_close（ループ部）
   * Description      : 入庫情報詳細の更新[出荷依頼ステータス03対象](A-11)
   ***********************************************************************************/
  PROCEDURE upd_detail_close(
      in_line_cnt    IN NUMBER                                        -- 1.ループカウンタ
    , iv_rowid       IN ROWID                                         -- 2.更新対象ROWID
    , iv_store_code  IN VARCHAR2                                      -- 3.倉庫コード
    , iv_shop_code   IN VARCHAR2                                      -- 4.店舗コード
    , ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_detail_close';       -- プログラム名
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
      WHERE  xsi.rowid = iv_rowid
      FOR UPDATE NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --入庫情報一時表のロック取得
    -- ===============================
    OPEN upd_xsi_tbl_cur;
    -- レコード読込
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- 入庫情報詳細の更新
      UPDATE  xxcoi_storage_information  xsi
      SET     req_status                    = g_detail_tab ( in_line_cnt ) .req_status
            , ship_case_qty                 = DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
                                                TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty / g_detail_tab ( in_line_cnt ) .case_in_qty ) )
            , ship_singly_qty               = DECODE( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
                                                MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty ,
                                                NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty              = DECODE( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
                                                g_detail_tab ( in_line_cnt ) .shipped_qty )
            , ship_warehouse_code           = DECODE ( g_detail_tab ( in_line_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
            , check_warehouse_code          = iv_store_code
            , ship_base_code                = g_detail_tab ( in_line_cnt ) .deliver_from
            , taste_term                    = g_detail_tab ( in_line_cnt ) .taste_term
            , difference_summary_code       = g_detail_tab ( in_line_cnt ) .difference_summary_code
            , material_transaction_set_flag = cv_n_flag
            , last_updated_by               = cn_last_updated_by
            , last_update_date              = SYSDATE
            , last_update_login             = cn_last_update_login
            , request_id                    = cn_request_id
            , program_application_id        = cn_program_application_id
            , program_id                    = cn_program_id
            , program_update_date           = SYSDATE
      WHERE   xsi.rowid                     = upd_xsi_tbl_rec.rowid
      ;
--
    -- カーソルクローズ
    CLOSE upd_xsi_tbl_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_detail_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_detail_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_detail_results（ループ部）
   * Description      : 入庫情報詳細の更新[出荷依頼ステータス04対象](A-12)
   ***********************************************************************************/
  PROCEDURE upd_detail_results(
      in_line_cnt    IN NUMBER                                        -- 1.ループカウンタ
    , iv_rowid       IN ROWID                                         -- 2.更新対象ROWID
    , iv_store_code  IN VARCHAR2                                      -- 3.倉庫コード
    , iv_shop_code   IN VARCHAR2                                      -- 4.店舗コード
    , ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_detail_results';     -- プログラム名
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
      WHERE  xsi.rowid = iv_rowid
      FOR UPDATE NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --入庫情報一時表のロック取得
    -- ===============================
    OPEN upd_xsi_tbl_cur;
    -- レコード読込
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- 入庫情報詳細の更新
      UPDATE  xxcoi_storage_information xsi
      SET     req_status                    = g_detail_tab ( in_line_cnt ) .req_status
            , case_in_qty                   = g_detail_tab ( in_line_cnt ) .case_in_qty
            , ship_case_qty                 = DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                                ship_case_qty + TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty
                                                TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                                      / g_detail_tab ( in_line_cnt ) .case_in_qty ) )
            , ship_singly_qty               = DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                                ship_singly_qty + MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty ,
                                                MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty ,
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                                  NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty              = DECODE( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                                ship_summary_qty + g_detail_tab ( in_line_cnt ) .shipped_qty )
                                                g_detail_tab ( in_line_cnt ) .shipped_qty )
-- == 2009/05/01 V1.4 Modified END   ===============================================================
            , ship_warehouse_code           = DECODE ( g_detail_tab ( in_line_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
            , check_warehouse_code          = iv_store_code
            , ship_base_code                = g_detail_tab(in_line_cnt).deliver_from
            , taste_term                    = g_detail_tab ( in_line_cnt ) .taste_term
            , difference_summary_code       = g_detail_tab ( in_line_cnt ) .difference_summary_code
            , material_transaction_set_flag = cv_n_flag
            , last_updated_by               = cn_last_updated_by
            , last_update_date              = SYSDATE
            , last_update_login             = cn_last_update_login
            , request_id                    = cn_request_id
            , program_application_id        = cn_program_application_id
            , program_id                    = cn_program_id
            , program_update_date           = SYSDATE
      WHERE   xsi.rowid                     = upd_xsi_tbl_rec.rowid
      ;
--
    -- カーソルクローズ
    CLOSE upd_xsi_tbl_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_detail_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_detail_results;
--
  /**********************************************************************************
   * Procedure Name   : upd_order_lines（ループ部）
   * Description      : 受注明細アドオン更新(A-13)
   ***********************************************************************************/
  PROCEDURE upd_order_lines(
      in_line_cnt    IN NUMBER                                        -- 1.ループカウンタ
    , ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_order_lines';        -- プログラム名
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
    CURSOR upd_xola_tbl_cur(
      g_detail_tab g_detail_ttype )
    IS
      SELECT xola.rowid
      FROM   xxwsh_order_lines_all xola
      WHERE  xola.order_header_id = g_detail_tab ( in_line_cnt ) .order_header_id
      AND    xola.order_line_id   = g_detail_tab ( in_line_cnt ) .order_line_id
      FOR UPDATE NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_xola_tbl_rec  upd_xola_tbl_cur%ROWTYPE;
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
    -- ===============================
    -- 受注明細アドオンテーブルのロック取得
    -- ===============================
    OPEN upd_xola_tbl_cur(
      g_detail_tab
    );
    -- レコード読込
    FETCH upd_xola_tbl_cur INTO upd_xola_tbl_rec;
--
      IF ( g_detail_tab ( in_line_cnt ) .req_status = gt_ship_status_close ) THEN
        -- 受注明細アドオンテーブルの更新（出荷指示の場合は指示連携済みフラグ更新）
        UPDATE xxwsh_order_lines_all xola
        SET    xola.shipping_request_if_flg = cv_y_flag
        WHERE  xola.rowid                   = upd_xola_tbl_rec.rowid
        ;
      ELSE
        -- 受注明細アドオンテーブルの更新（出荷実績・取消の場合は実績連携済みフラグ更新）
        UPDATE xxwsh_order_lines_all xola
        SET    xola.shipping_result_if_flg  = cv_y_flag
        WHERE  xola.rowid                   = upd_xola_tbl_rec.rowid
        ;
      END IF;
--
    -- カーソルクローズ
    CLOSE upd_xola_tbl_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lines_lock_expt_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_order_lines;
--
  /**********************************************************************************
   * Procedure Name   : chk_item（ループ部）
   * Description      : 品目有効チェック(A-15)
   ***********************************************************************************/
  PROCEDURE chk_item(
      in_slip_cnt   IN  NUMBER        --   1.ループカウンタ
    , ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item';               -- プログラム名
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
    cv_status                 CONSTANT VARCHAR2(10) := 'Inactive';
    cv_cmnfunc_nm             CONSTANT VARCHAR2(50) := 'XXCOI_COMMON_PKG.GET_ITEM_INFO';
--
    -- *** ローカル変数 ***
    lt_item_status            mtl_system_items_b.inventory_item_status_code%TYPE;
    lt_cust_order_flg         mtl_system_items_b.customer_order_enabled_flag%TYPE;
    lt_transaction_enable     mtl_system_items_b.mtl_transactions_enabled_flag%TYPE;
    lt_stock_enabled_flg      mtl_system_items_b.stock_enabled_flag%TYPE;
    lt_return_enable          mtl_system_items_b.returnable_flag%TYPE;
    lt_sales_class            ic_item_mst_b.attribute26%TYPE;
    lt_primary_unit           mtl_system_items_b.primary_unit_of_measure%TYPE;
    ln_item_cnt               NUMBER;
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
    -- ===============================
    -- 共通関数を使用し品目情報を取得
    -- ===============================
      xxcoi_common_pkg.get_item_info(
         iv_item_code          => g_summary_tab ( in_slip_cnt ) .item_no
                                                                      -- 1.品目コード
        ,in_org_id             => gt_org_id                           -- 2.在庫組織ID
        ,ov_item_status        => lt_item_status                      -- 3.品目ステータス
        ,ov_cust_order_flg     => lt_cust_order_flg                   -- 4.顧客受注可能フラグ
        ,ov_transaction_enable => lt_transaction_enable               -- 5.取引可能
        ,ov_stock_enabled_flg  => lt_stock_enabled_flg                -- 6.在庫保有可能フラグ
        ,ov_return_enable      => lt_return_enable                    -- 7.返品可能
        ,ov_sales_class        => lt_sales_class                      -- 8.売上対象区分
        ,ov_primary_unit       => lt_primary_unit                     -- 9.基準単位
        ,ov_errbuf             => lv_errbuf                           -- 10.エラー・メッセージ
        ,ov_retcode            => lv_retcode                          -- 11.リターン・コード
        ,ov_errmsg             => lv_errmsg                           -- 12.ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE item_expt;
      ELSIF ( lt_item_status IS NULL ) THEN
        RAISE item_found_expt;
      ELSIF ( lt_item_status != cv_status ) THEN
        --子品目＋品目カテゴリ：資材以外をエラーとする
        IF ( lt_cust_order_flg = cv_y_flag
             AND lt_transaction_enable = cv_y_flag
             AND lt_stock_enabled_flg = cv_y_flag
             AND lt_return_enable = cv_y_flag )
        THEN
          SELECT   COUNT(*)
          INTO     ln_item_cnt
          FROM     mtl_system_items_b msib
                 , ic_item_mst_b iimbc
                 , ic_item_mst_b iimbp
                 , xxcmn_item_mst_b ximb
          WHERE    msib.organization_id               = gt_org_id
          AND      iimbc.item_no                      = msib.segment1
          AND      msib.segment1                      = g_summary_tab ( in_slip_cnt ) .item_no
          AND      iimbc.item_id                      = ximb.item_id
          AND      iimbp.item_id                      = ximb.parent_item_id
-- == 2009/09/08 V1.8 Added START ===============================================================
          AND      g_summary_tab( in_slip_cnt ).slip_date BETWEEN ximb.start_date_active
                                                          AND     NVL(ximb.end_date_active, g_summary_tab( in_slip_cnt ).slip_date)
-- == 2009/09/08 V1.8 Added END   ===============================================================
-- == 2009/11/13 V1.11 Modified START ===============================================================
--          AND      ( ximb.parent_item_id = iimbc.item_id
--                   AND iimbc.attribute26 != cv_1
--                   AND NOT EXISTS ( SELECT '1'
--                                    FROM   mtl_system_items_b     msib2
--                                         , mtl_category_sets_tl   mcst
--                                         , mtl_item_categories    mic
--                                         , mtl_categories_b       mcb
--                                    WHERE  msib2.organization_id  = gt_org_id
--                                    AND    mcst.category_set_name = fnd_profile.value ( cv_item_category )
--                                    AND    mcst.language          = USERENV('LANG')
--                                    AND    mic.category_set_id    = mcst.category_set_id
--                                    AND    mic.inventory_item_id  = msib2.inventory_item_id
--                                    AND    mic.organization_id    = msib2.organization_id
--                                    AND    mcb.category_id        = mic.category_id
--                                    AND    mcb.enabled_flag       = cv_y_flag
--                                    AND    mcb.segment1           = cv_2
--                                    AND    msib.inventory_item_id = msib2.inventory_item_id
--                                  )
--                  );
          AND      iimbp.attribute26 != cv_1
          AND      NOT EXISTS    ( SELECT  1
                                   FROM    mtl_system_items_b    msib2
                                   WHERE  msib2.organization_id   = gt_org_id
                                   AND    msib2.inventory_item_id = msib.inventory_item_id
                                   AND   (msib2.segment1          LIKE '5%'
                                   OR     msib2.segment1          LIKE '6%')
                                 );
-- == 2009/11/13 V1.11 Modified END   ===============================================================
          IF (ln_item_cnt != 0) THEN
            RAISE item_disable_expt;
          END IF;
        ELSE
          RAISE item_disable_expt;
        END IF;
      ELSE
        RAISE item_disable_expt;
      END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN item_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_item_expt_msg
                       , iv_token_name1  => cv_tkn_api_nm
                       , iv_token_value1 => cv_cmnfunc_nm
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN item_found_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_item_disable_msg
                       , iv_token_name1  => cv_tkn_item_code
                       , iv_token_value1 => g_summary_tab(in_slip_cnt).item_no
                       , iv_token_name2  => cv_tkn_den_no
                       , iv_token_value2 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN item_disable_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_item_disable_msg
                       , iv_token_name1  => cv_tkn_item_code
                       , iv_token_value1 => g_summary_tab(in_slip_cnt).item_no
                       , iv_token_name2  => cv_tkn_den_no
                       , iv_token_value2 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- セーブポイントまでロールバック
--      ROLLBACK TO SAVEPOINT summary_point;
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : chk_summary_data（ループ部）
   * Description      : 入庫情報サマリ存在確認(A-16)
   ***********************************************************************************/
  PROCEDURE chk_summary_data(
      in_slip_cnt      IN NUMBER                                      -- 1.ループカウンタ
    , iv_store_code    IN VARCHAR2                                    -- 2.倉庫コード
    , ov_rowid        OUT ROWID                                       -- 3.ROWID
    , ot_req_status   OUT xxcoi_storage_information.req_status%TYPE   -- 4.出荷依頼ステータス
    , ob_record_valid OUT BOOLEAN                                     -- 5.TRUE:サマリレコード存在 FALSE:存在せず
    , ov_errbuf       OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2     --   リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_summary_data';       -- プログラム名
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
    -- ===============================
    -- 入庫情報一時表にサマリレコードが存在するかチェックを行う
    -- ===============================
    BEGIN
      SELECT  xsi.rowid
            , xsi.req_status
      INTO    ov_rowid
            , ot_req_status
      FROM    xxcoi_storage_information xsi
      WHERE   xsi.slip_num          = gv_slip_num
      AND     xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND     xsi.warehouse_code    = iv_store_code
      AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND     xsi.slip_type         = cv_slip_type
      AND     xsi.summary_data_flag = cv_y_flag
      ;
      ob_record_valid := TRUE;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_record_valid := FALSE;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ob_record_valid := FALSE;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_summary_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_detail_data（ループ部）
   * Description      : 入庫情報詳細存在確認(A-17)
   ***********************************************************************************/
  PROCEDURE chk_detail_data(
      in_line_cnt      IN NUMBER                                      -- 1.ループカウンタ
    , iv_store_code    IN VARCHAR2                                    -- 2.倉庫コード
    , ov_rowid        OUT ROWID                                       -- 3.ROWID
    , ot_req_status   OUT xxcoi_storage_information.req_status%TYPE   -- 4.出荷依頼ステータス
    , ob_record_valid OUT BOOLEAN                                     -- 5.TRUE:詳細レコード存在 FALSE:存在せず
    , ov_errbuf       OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_detail_data';        -- プログラム名
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
    -- ===============================
    -- 入庫情報一時表に詳細レコードが存在するかチェックを行う
    -- ===============================
    BEGIN
      SELECT xsi.rowid
            ,xsi.req_status
      INTO   ov_rowid
            ,ot_req_status
      FROM   xxcoi_storage_information xsi
      WHERE  xsi.slip_num                 = gv_slip_num
      AND    xsi.slip_date                = g_detail_tab ( in_line_cnt ) .slip_date
      AND    xsi.base_code                = g_detail_tab ( in_line_cnt ) .base_code
      AND    xsi.warehouse_code           = iv_store_code
      AND    xsi.parent_item_code         = g_detail_tab ( in_line_cnt ) .parent_item_no
      AND    xsi.item_code                = g_detail_tab ( in_line_cnt ) .item_no
-- == 2009/05/14 V1.5 Modified START ===============================================================
--      AND    xsi.taste_term               = g_detail_tab ( in_line_cnt ) .taste_term
--      AND    xsi.difference_summary_code  = g_detail_tab ( in_line_cnt ) .difference_summary_code
      AND    (   (xsi.taste_term          = g_detail_tab ( in_line_cnt ) .taste_term)
              OR (xsi.taste_term IS NULL)
             )
      AND    (   (xsi.difference_summary_code  = g_detail_tab ( in_line_cnt ) .difference_summary_code)
              OR (xsi.difference_summary_code IS NULL)
             )
-- == 2009/05/14 V1.5 Modified END   ===============================================================
      AND    xsi.slip_type                = cv_slip_type
      AND    xsi.summary_data_flag        = cv_n_flag
      ;
      ob_record_valid := TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_record_valid := FALSE;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ob_record_valid := FALSE;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_status（ループ部）
   * Description      : 在庫会計期間チェック(A-20)
   ***********************************************************************************/
  PROCEDURE chk_period_status(
      in_slip_cnt   IN  NUMBER        --   1.ループカウンタ
    , ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_status';      -- プログラム名
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
    lb_fnc_status             BOOLEAN;
--
    -- *** ローカル・カーソル ***
-- == 2009/12/14 V1.13 Added START ===============================================================
    CURSOR  cur_upd_lines
    IS
      SELECT  1
      FROM    xxwsh_order_headers_all   xoh
             ,xxwsh_order_lines_all     xol
      WHERE   xoh.order_header_id       =   xol.order_header_id
      AND     xoh.latest_external_flag  =   cv_y_flag
      AND     xoh.request_no            =   g_summary_tab ( in_slip_cnt ) .req_move_no
      FOR UPDATE NOWAIT;
-- == 2009/12/14 V1.13 Added END   ===============================================================
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
    -- ===============================
    -- 共通関数を使用し在庫会計期間ステータスを取得
    -- ===============================
    IF ( TO_CHAR(gd_process_date,'YYYYMM') >= TO_CHAR(g_summary_tab ( in_slip_cnt ) .slip_date ,'YYYYMM')) THEN
      xxcoi_common_pkg.org_acct_period_chk(
          in_organization_id => gt_org_id                             -- 1.在庫組織ID
        , id_target_date     => g_summary_tab ( in_slip_cnt ) .slip_date
                                                                      -- 2.伝票日付
        , ob_chk_result      => lb_fnc_status
        , ov_errbuf          => lv_errbuf
        , ov_retcode         => lv_retcode
        , ov_errmsg          => lv_errmsg
      );
      IF ( lb_fnc_status = FALSE ) THEN
-- == 2009/12/14 V1.13 Added START ===============================================================
        -- 受注明細ロック取得
        OPEN    cur_upd_lines;
        CLOSE   cur_upd_lines;
        --
        -- 既に在庫会計期間がクローズされているデータは取込済みとする
        -- 受注明細「出荷実績連携済フラグ」更新
        UPDATE xxwsh_order_lines_all xol
        SET    xol.shipping_result_if_flg   =   cv_y_flag
        WHERE  xol.order_header_id          =   ( SELECT    xoh.order_header_id
                                                  FROM      xxwsh_order_headers_all   xoh
                                                  WHERE     xoh.request_no            =   g_summary_tab ( in_slip_cnt ) .req_move_no
                                                  AND       xoh.latest_external_flag  =   cv_y_flag
                                                )
        ;
-- == 2009/12/14 V1.13 Added END   ===============================================================
        RAISE period_status_close_expt;
      ELSIF ( lv_retcode != cv_status_normal ) THEN
        RAISE period_status_common_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- == 2009/12/14 V1.13 Added START ===============================================================
    WHEN lock_expt THEN
      IF ( cur_upd_lines%ISOPEN ) THEN
        CLOSE cur_upd_lines;
      END IF;
      --
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                        , iv_name         => cv_lines_lock_expt_msg
                        , iv_token_name1  => cv_tkn_den_no
                        , iv_token_value1 => g_summary_tab ( in_slip_cnt ) .req_move_no
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  :=  cv_status_warn;
      --
-- == 2009/12/14 V1.13 Added END   ===============================================================
    WHEN period_status_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_period_status_close_msg
                     , iv_token_name1  => cv_tkn_den_no
                     , iv_token_value1 => gv_slip_num
                     , iv_token_name2  => cv_tkn_target
                     , iv_token_value2 => TO_CHAR ( g_summary_tab ( in_slip_cnt ) .slip_date , 'YYYY/MM/DD' )
                   );
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    WHEN period_status_common_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_period_status_cmn_msg
                     , iv_token_name1  => cv_tkn_target
                     , iv_token_value1 => TO_CHAR ( g_summary_tab ( in_slip_cnt ) .slip_date , 'YYYY/MM/DD' )
                   );
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END chk_period_status;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf    OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
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
    lv_rowid                  ROWID;
    lt_req_status             xxcoi_storage_information.req_status%TYPE;
                                                                      -- 出荷依頼ステータス
    lb_record_valid           BOOLEAN;                                -- 登録/更新制御用フラグ
    lb_slip_chk_status        BOOLEAN;                                -- 伝票単位スキップ制御用フラグ
    lt_store_code             xxcoi_subinventory_info_v.store_code%TYPE;
                                                                      -- 倉庫コード
    lt_shop_code              xxcoi_subinventory_info_v.shop_code%TYPE;
                                                                      -- 店舗コード
    lt_auto_confirmation_flg  xxcoi_subinventory_info_v.auto_confirmation_flag%TYPE;
                                                                      -- 自動入庫確認フラグ
    ln_store_check_cnt        NUMBER;                                 -- 自動入庫確認済伝票カウンタ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
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
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode                                      -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg                                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.入庫情報サマリの取得
    -- ===============================
    get_summary_record(
        ov_errbuf  => lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode                                      -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg                                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 入庫情報サマリ抽出が0件時は抽出レコードなしで終了
    IF (gn_summary_cnt > 0) THEN
      <<g_summary_tab_loop>>
      FOR gn_slip_cnt IN 1 .. gn_summary_cnt LOOP
--
        --伝票単位処理制御フラグ初期化
        lb_slip_chk_status := TRUE;
--
    -- ===============================
    -- セーブポイント設定
    -- ===============================
        SAVEPOINT summary_point;
--
        gv_slip_num := g_summary_tab(gn_slip_cnt).req_move_no;
--
    -- ===============================
    -- A-4.保管場所情報処理
    -- ===============================
        IF ( lb_slip_chk_status = TRUE ) THEN
          get_subinventories(
              iv_base_code              => g_summary_tab(gn_slip_cnt).base_code
                                                                      -- 1.拠点コード
-- == 2009/04/16 V1.3 Added START ===============================================================
            , it_deliverly_code         => g_summary_tab(gn_slip_cnt).deliverly_code
                                                                      -- 2.配送先コード
-- == 2009/04/16 V1.3 Added END   ===============================================================
            , it_org_id                 => gt_org_id                  -- 3.在庫組織ID
            , ot_store_code             => lt_store_code              -- 4.倉庫コード
            , ot_shop_code              => lt_shop_code               -- 5.店舗コード
            , ot_auto_confirmation_flag => lt_auto_confirmation_flg   -- 6.自動入庫確認フラグ
            , ov_errbuf                 => lv_errbuf                  -- エラー・メッセージ
            , ov_retcode                => lv_retcode                 -- リターン・コード
            , ov_errmsg                 => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_slip_chk_status := FALSE;
          END IF;
        END IF;
--
    -- ===============================
    -- A-15.品目有効チェック
    -- ===============================
        IF ( lb_slip_chk_status = TRUE ) THEN
          chk_item(
              in_slip_cnt => gn_slip_cnt                              -- 1.ループカウンタ
            , ov_errbuf   => lv_errbuf                                -- エラー・メッセージ
            , ov_retcode  => lv_retcode                               -- リターン・コード
            , ov_errmsg   => lv_errmsg                                -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_slip_chk_status := FALSE;
          END IF;
        END IF;
--
    -- ===============================
    -- A-20.在庫会計期間チェック
    -- ===============================
        IF ( lb_slip_chk_status = TRUE ) THEN
          chk_period_status(
              in_slip_cnt => gn_slip_cnt                              -- 1.ループカウンタ
            , ov_errbuf   => lv_errbuf                                -- エラー・メッセージ
            , ov_retcode  => lv_retcode                               -- リターン・コード
            , ov_errmsg   => lv_errmsg                                -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_slip_chk_status := FALSE;
          END IF;
        END IF;
--
-- *************************************************************************************************
--  サマリ情報の作成(START)
-- *************************************************************************************************
        -- 伝票単位でのスキップ判定
        IF ( lb_slip_chk_status = TRUE ) THEN
          -- ===============================
          -- A-16.入庫情報サマリ存在確認
          -- ===============================
          chk_summary_data(
              in_slip_cnt     => gn_slip_cnt                          -- 1.ループカウンタ
            , iv_store_code   => lt_store_code                        -- 2.倉庫コード
            , ov_rowid        => lv_rowid                             -- 3.ROWID
            , ot_req_status   => lt_req_status                        -- 4.出荷依頼ステータス
            , ob_record_valid => lb_record_valid                      -- 5.TRUE:サマリレコード存在 FALSE:存在せず
            , ov_errbuf       => lv_errbuf                            -- エラー・メッセージ
            , ov_retcode      => lv_retcode                           -- リターン・コード
            , ov_errmsg       => lv_errmsg                            -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ==========================================
          --  入出庫一時表にサマリデータが存在する場合
          -- ==========================================
          IF ( lb_record_valid = TRUE ) THEN
--
            IF ( lt_req_status IS NULL ) THEN
              -- ======================================
              -- 入出庫一時表の出荷依頼ステータスがNULL
              -- A-7.入庫情報サマリの更新
              -- ======================================
              upd_summary_disp(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.ループカウンタ
                , iv_rowid      => lv_rowid                           -- 2.更新対象ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
                , iv_store_code => lt_store_code                      -- 3.倉庫コード
-- == 2009/12/18 V1.14 Added END   ===============================================================
                , ov_errbuf     => lv_errbuf                          -- エラー・メッセージ
                , ov_retcode    => lv_retcode                         -- リターン・コード
                , ov_errmsg     => lv_errmsg                          -- ユーザー・エラー・メッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            ELSIF ( lt_req_status = gt_ship_status_close ) THEN
              -- ======================================
              -- 入出庫一時表の出荷依頼ステータスが03
              -- A-8.入庫情報サマリの更新
              -- ======================================
              upd_summary_close(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.ループカウンタ
                , iv_rowid      => lv_rowid                           -- 2.更新対象ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
                , iv_store_code => lt_store_code                      -- 3.倉庫コード
-- == 2009/12/18 V1.14 Added END   ===============================================================
                , ov_errbuf     => lv_errbuf                          -- エラー・メッセージ
                , ov_retcode    => lv_retcode                         -- リターン・コード
                , ov_errmsg     => lv_errmsg                          -- ユーザー・エラー・メッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            ELSIF ( lt_req_status = gt_ship_status_result ) THEN
              -- ======================================
              -- 入出庫一時表の出荷依頼ステータスが04
              -- A-9.入庫情報サマリの更新
              -- ======================================
              upd_summary_results(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.ループカウンタ
                , iv_rowid      => lv_rowid                           -- 2.更新対象ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
                , iv_store_code => lt_store_code                      -- 3.倉庫コード
-- == 2009/12/18 V1.14 Added END   ===============================================================
                , ov_errbuf     => lv_errbuf                          -- エラー・メッセージ
                , ov_retcode    => lv_retcode                         -- リターン・コード
                , ov_errmsg     => lv_errmsg                          -- ユーザー・エラー・メッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            END IF;
            --
-- == 2009/12/18 V1.14 Added START ===============================================================
            IF (lb_slip_chk_status) THEN
              -- ======================================
              -- A-21.旧明細削除処理
              -- ======================================
              del_detail_data(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.ループカウンタ
                , iv_store_code => lt_store_code                      -- 2.倉庫コード
                , ov_errbuf     => lv_errbuf                          -- エラー・メッセージ
                , ov_retcode    => lv_retcode                         -- リターン・コード
                , ov_errmsg     => lv_errmsg                          -- ユーザー・エラー・メッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            END IF;
-- == 2009/12/18 V1.14 Added END   ===============================================================
          ELSE
            -- ===========================================
            --  入出庫一時表にサマリデータが存在しない場合
            -- ===========================================
            -- =========================================
            -- 取得した伝票が入庫確認済かカウント
            -- =========================================
            BEGIN
              SELECT COUNT(*)
              INTO   ln_store_check_cnt
              FROM   xxcoi_storage_information xsi
              WHERE  xsi.slip_num = gv_slip_num
              AND    xsi.store_check_flag = cv_y_flag
              AND    ROWNUM = 1
              ;
            EXCEPTION
              WHEN OTHERS THEN
                ln_store_check_cnt := 0;
            END;
--
            IF ( ln_store_check_cnt > 0 ) THEN
              -- =========================================
              --  取得した伝票が入庫確認済の場合
              --  A-6.入庫情報サマリの登録
              -- =========================================
              ins_summary_confirmed(
                  in_slip_cnt               => gn_slip_cnt            -- 1.ループカウンタ
                , iv_store_code             => lt_store_code          -- 2.倉庫コード
                , iv_shop_code              => lt_shop_code           -- 3.店舗コード
                , it_auto_confirmation_flag => lt_auto_confirmation_flg
                                                                      -- 4.自動入庫確認フラグ
                , ov_errbuf                 => lv_errbuf              -- エラー・メッセージ
                , ov_retcode                => lv_retcode             -- リターン・コード
                , ov_errmsg                 => lv_errmsg              -- ユーザー・エラー・メッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            ELSE
              -- =========================================
              --  取得した伝票が入庫未確認の場合
              --  A-5.入庫情報サマリの登録
              -- =========================================
              ins_summary_unconfirmed(
                  in_slip_cnt               => gn_slip_cnt            -- 1.ループカウンタ
                , iv_store_code             => lt_store_code          -- 2.倉庫コード
                , iv_shop_code              => lt_shop_code           -- 3.店舗コード
                , it_auto_confirmation_flag => lt_auto_confirmation_flg
                                                                      -- 4.自動入庫確認フラグ
                , ov_errbuf                 => lv_errbuf              -- エラー・メッセージ
                , ov_retcode                => lv_retcode             -- リターン・コード
                , ov_errmsg                 => lv_errmsg              -- ユーザー・エラー・メッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END IF;
          --
-- == 2009/12/18 V1.14 Added START ===============================================================
          -- 伝票日付不一致データの出庫側数量初期化
          IF (lb_slip_chk_status) THEN
            -- ======================================
            -- A-22.旧情報出庫数量初期化処理
            -- ======================================
            upd_old_data(
                in_slip_cnt   => gn_slip_cnt                        -- 1.ループカウンタ
              , iv_store_code => lt_store_code                      -- 2.倉庫コード
              , ov_errbuf     => lv_errbuf                          -- エラー・メッセージ
              , ov_retcode    => lv_retcode                         -- リターン・コード
              , ov_errmsg     => lv_errmsg                          -- ユーザー・エラー・メッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSIF ( lv_retcode = cv_status_warn ) THEN
              gn_warn_cnt := gn_warn_cnt + 1;
              lb_slip_chk_status := FALSE;
            END IF;
          END IF;
-- == 2009/12/18 V1.14 Added END   ===============================================================
        END IF;
-- *************************************************************************************************
--  サマリ情報の作成(END)
-- *************************************************************************************************
--
-- *************************************************************************************************
--  明細情報の作成(START)
-- *************************************************************************************************
        -- 伝票単位でのスキップ判定
        IF ( lb_slip_chk_status = TRUE ) THEN
          -- ===============================
          -- A-3.入庫情報詳細の取得
          -- ===============================
          get_detail_record(
              in_slip_cnt => gn_slip_cnt                              -- 1.ループカウンタ
            , ov_errbuf   => lv_errbuf                                -- エラー・メッセージ
            , ov_retcode  => lv_retcode                               -- リターン・コード
            , ov_errmsg   => lv_errmsg                                -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          <<g_detail_tab_loop>>
          FOR gn_line_cnt IN 1..g_detail_tab.COUNT LOOP
-- == 2009/12/18 V1.14 Deleted START ===============================================================
--             -- ===============================
--             -- A-17.入庫情報詳細存在確認
--             -- ===============================
--             chk_detail_data(
--                 in_line_cnt     => gn_line_cnt                        -- 1.ループカウンタ
--               , iv_store_code   => lt_store_code                      -- 2.倉庫コード
--               , ov_rowid        => lv_rowid                           -- 3.ROWID
--               , ot_req_status   => lt_req_status                      -- 4.出荷依頼ステータス
--               , ob_record_valid => lb_record_valid                    -- 5.TRUE:詳細レコード存在 FALSE:存在せず
--               , ov_errbuf       => lv_errbuf                          -- エラー・メッセージ
--               , ov_retcode      => lv_retcode                         -- リターン・コード
--               , ov_errmsg       => lv_errmsg                          -- ユーザー・エラー・メッセージ
--             );
--             IF ( lv_retcode = cv_status_error ) THEN
--               RAISE global_process_expt;
--             END IF;
-- == 2009/12/18 V1.14 Deleted END   ===============================================================
--
-- == 2009/12/18 V1.14 Modified START ===============================================================
--             IF ( lb_record_valid = TRUE ) THEN
--               IF ( lt_req_status = gt_ship_status_result ) THEN
--                 -- ===============================
--                 -- A-12.入庫情報詳細の更新
--                 -- ===============================
--                 upd_detail_results(
--                     in_line_cnt   => gn_line_cnt                      -- 1.ループカウンタ
--                   , iv_rowid      => lv_rowid                         -- 2.更新対象ROWID
--                   , iv_store_code => lt_store_code                    -- 3.倉庫コード
--                   , iv_shop_code  => lt_shop_code                     -- 4.店舗コード
--                   , ov_errbuf     => lv_errbuf                        -- エラー・メッセージ
--                   , ov_retcode    => lv_retcode                       -- リターン・コード
--                   , ov_errmsg     => lv_errmsg                        -- ユーザー・エラー・メッセージ
--                 );
--                 IF ( lv_retcode = cv_status_error ) THEN
--                   RAISE global_process_expt;
--                 ELSIF ( lv_retcode = cv_status_warn ) THEN
--                   gn_warn_cnt := gn_warn_cnt + 1;
--                   lb_slip_chk_status := FALSE;
--                   -- 次伝票Noへ遷移
--                   EXIT g_detail_tab_loop;
--                 END IF;
--               ELSE
--                 -- ===============================
--                 -- A-11.入庫情報詳細の更新
--                 -- ===============================
--                 upd_detail_close(
--                     in_line_cnt   => gn_line_cnt                      -- 1.ループカウンタ
--                   , iv_rowid      => lv_rowid                         -- 2.更新対象ROWID
--                   , iv_store_code => lt_store_code                    -- 3.倉庫コード
--                   , iv_shop_code  => lt_shop_code                     -- 4.店舗コード
--                   , ov_errbuf     => lv_errbuf                        -- エラー・メッセージ
--                   , ov_retcode    => lv_retcode                       -- リターン・コード
--                   , ov_errmsg     => lv_errmsg                        -- ユーザー・エラー・メッセージ
--                 );
--                 IF ( lv_retcode = cv_status_error ) THEN
--                   RAISE global_process_expt;
--                 ELSIF ( lv_retcode = cv_status_warn ) THEN
--                   gn_warn_cnt := gn_warn_cnt + 1;
--                   lb_slip_chk_status := FALSE;
--                   -- 次伝票Noへ遷移
--                   EXIT g_detail_tab_loop;
--                 END IF;
--               END IF;
--             ELSE
--               -- ===============================
--               -- A-10.入庫情報詳細の登録
--               -- ===============================
--               ins_detail_confirmed(
--                   in_line_cnt               => gn_line_cnt            -- 1.ループカウンタ
--                 , iv_store_code             => lt_store_code          -- 2.倉庫コード
--                 , iv_shop_code              => lt_shop_code           -- 3.店舗コード
--                 , it_auto_confirmation_flag => lt_auto_confirmation_flg
--                                                                       -- 4.自動入庫確認フラグ
--                 , ov_errbuf                 => lv_errbuf              -- エラー・メッセージ
--                 , ov_retcode                => lv_retcode             -- リターン・コード
--                 , ov_errmsg                 => lv_errmsg              -- ユーザー・エラー・メッセージ
--               );
--               IF ( lv_retcode = cv_status_error ) THEN
--                 RAISE global_process_expt;
--               END IF;
--             END IF;
--
            -- ===============================
            -- A-10.入庫情報詳細の登録
            -- ===============================
            ins_detail_confirmed(
                in_line_cnt               => gn_line_cnt            -- 1.ループカウンタ
              , iv_store_code             => lt_store_code          -- 2.倉庫コード
              , iv_shop_code              => lt_shop_code           -- 3.店舗コード
              , it_auto_confirmation_flag => lt_auto_confirmation_flg
                                                                    -- 4.自動入庫確認フラグ
              , ov_errbuf                 => lv_errbuf              -- エラー・メッセージ
              , ov_retcode                => lv_retcode             -- リターン・コード
              , ov_errmsg                 => lv_errmsg              -- ユーザー・エラー・メッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
-- == 2009/12/18 V1.14 Modified END   ===============================================================
            --
            -- ===============================
            -- A-13.受注明細アドオンの更新
            -- ===============================
            upd_order_lines(
                in_line_cnt => gn_line_cnt                            -- 1.ループカウンタ
              , ov_errbuf   => lv_errbuf                              -- エラー・メッセージ
              , ov_retcode  => lv_retcode                             -- リターン・コード
              , ov_errmsg   => lv_errmsg                              -- ユーザー・エラー・メッセージ
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSIF ( lv_retcode = cv_status_warn ) THEN
              gn_warn_cnt := gn_warn_cnt + 1;
              -- 次伝票Noへ遷移
              EXIT g_detail_tab_loop;
            END IF;
            --
          END LOOP g_detail_tab_loop;
        END IF;
--
        -- 正常終了件数カウントアップ（伝票単位）
        IF ( lb_slip_chk_status = TRUE ) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          fnd_file.put_line(
              which => fnd_file.output
            , buff  => lv_errmsg --ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
              which => fnd_file.log
            , buff  => lv_errbuf --エラーメッセージ
          );
        END IF;
      END LOOP g_summary_tab_loop;
-- *************************************************************************************************
--  明細情報の作成(END)
-- *************************************************************************************************
    ELSE
      -- 対象サマリ情報０件の場合
      lv_retcode := cv_status_normal;
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_not_found_slip_msg
                   );
      lv_errbuf := lv_errmsg;
    END IF;
--
    -- ===============================
    -- A-17.終了処理
    -- ===============================
--
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      --警告処理
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    ELSIF ( gn_warn_cnt > 0 ) THEN
      --警告処理
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      gn_error_cnt := 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt := 1;
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
      errbuf      OUT VARCHAR2       --   エラー・メッセージ  --# 固定 #
    , retcode     OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      fnd_file.put_line(
          which => fnd_file.output
        , buff  => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
          which => fnd_file.log
        , buff  => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_warn_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_warn_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => lv_message_code
                   );
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => gv_out_msg
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
END XXCOI001A01C;
/
