CREATE OR REPLACE PACKAGE BODY xxwsh400005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400005C(body)
 * Description      : 出荷依頼情報抽出
 * MD.050           : 出荷依頼         T_MD050_BPO_401
 * MD.070           : 出荷依頼情報抽出 T_MD070_BPO_40F
 * Version          : 1.14
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  cutoff_str             文字列を末尾から切り取る
 *  if_flg_upd             I/F済フラグの更新
 *  tbl_lock               テーブルのロックの取得
 *  get_request_class      依頼区分の取得
 *  get_results_data       出荷実績情報の取得
 *  get_request_data       出荷依頼情報の取得
 *  parameter_check        パラメータチェック                           (F-1)
 *  get_profile            プロファイル取得                             (F-2)
 *  get_obj_data           出荷依頼情報抽出                             (F-3)
 *  put_obj_data           出荷依頼情報出力                             (F-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/01    1.0   Oracle 山根 一浩 初回作成
 *  2008/05/30    1.1   Oracle 石渡 賢和 出荷依頼(実績)出力済みフラグの判定修正
 *  2008/06/10    1.2   Oracle 石渡 賢和 TE080指摘事項修正
 *  2008/07/14    1.3   Oracle 椎名 昭圭 TE080指摘事項#73対応
 *  2008/08/04    1.4   Oracle 山根 一浩 ST#103対応
 *  2008/08/22    1.5   Oracle 山根 一浩 T_S_597対応
 *  2008/09/04    1.6   Oracle 山根 一浩 PT 3-3_23 指摘37対応
 *  2008/09/18    1.7   Oracle 伊藤 ひとみ T_TE080_BPO_400 指摘79,T_S_630対応
 *  2008/11/06    1.8   SCS    伊藤 ひとみ 統合テスト指摘560対応
 *  2008/12/01    1.9   SCS    吉田 夏樹 本番#291対応
 *  2008/12/03    1.10  SCS    宮田      本番#255対応
 *  2008/12/24    1.11  SCS    椎名 昭圭 本番#827対応
 *  2009/01/21    1.12  SCS    上原 正好 本番#1010対応
 *  2009/05/22    1.13  SCS    伊藤 ひとみ 本番#1398対応
 *  2009/10/06    1.14  SCS    伊藤 ひとみ 本番#1648対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
-- 2008/09/18 1.17 Add ↓ T_TE080_BPO_400 指摘79
  gv_status_skip   CONSTANT VARCHAR2(1) := '3';
-- 2008/09/18 1.17 Add ↑
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  get_profile_expt          EXCEPTION;     -- プロファイル取得エラー
  lock_expt                 EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh400005c';  -- パッケージ名
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXWSH';         -- アプリケーション短縮名
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';         -- アプリケーション短縮名
--
  gv_tkn_num_40f_01    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11251';  -- パラメータ未入力エラー
  gv_tkn_num_40f_02    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11252';  -- 対象データ0件エラー
  gv_tkn_num_40f_03    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11253';  -- 入力パラメータ入力値エラー
  gv_tkn_num_40f_04    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11254';  -- プロファイル取得エラー
  gv_tkn_num_40f_05    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11255';  -- 依頼区分取得エラー
  gv_tkn_num_40f_06    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11256';  -- 依頼Noコンバートエラー
  gv_tkn_num_40f_07    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11704';  -- ファイルアクセス権限エラー
  gv_tkn_num_40f_08    CONSTANT VARCHAR2(15) := 'APP-XXWSH-10006';  -- ロック処理エラー
--
  gv_tkn_parameter     CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_tkn_prof_name     CONSTANT VARCHAR2(15) := 'PROF_NAME';
  gv_type_name         CONSTANT VARCHAR2(15) := 'TYPE_NAME';
--
  gv_inf_sub_request   CONSTANT VARCHAR2(1)  := '1';    -- 出荷依頼
  gv_inf_sub_results   CONSTANT VARCHAR2(1)  := '2';    -- 出荷実績
  gv_adjs_class_req    CONSTANT VARCHAR2(1)  := '1';    -- 出荷依頼
  gv_adjs_class_adj    CONSTANT VARCHAR2(1)  := '2';    -- 在庫調整
--
  gv_req_status_03     CONSTANT VARCHAR2(2)  := '03';   -- 締め済み
  gv_req_status_04     CONSTANT VARCHAR2(2)  := '04';   -- 出荷実績計上済
  gv_req_status_99     CONSTANT VARCHAR2(2)  := '99';   -- 取消
--
  gv_flag_on           CONSTANT VARCHAR2(1)  := 'Y';
  gv_flag_off          CONSTANT VARCHAR2(1)  := 'N';
--
  gv_data_div          CONSTANT VARCHAR2(3)  := '440';     -- データ種別
  gv_r_no              CONSTANT VARCHAR2(1)  := '0';       -- R_No
  gv_continue          CONSTANT VARCHAR2(2)  := '00';      -- 継続
  gv_num_zero          CONSTANT VARCHAR2(1)  := '0';
  gv_prod_class_reef   CONSTANT VARCHAR2(1)  := '1';       -- リーフ
  gv_prod_class_drink  CONSTANT VARCHAR2(1)  := '2';       -- ドリンク
  gv_base_code_reef    CONSTANT VARCHAR2(4)  := '2020';    -- リーフ
  gv_base_code_drink   CONSTANT VARCHAR2(4)  := '2100';    -- ドリンク
  gv_max_date          CONSTANT VARCHAR2(6)  := '999999';
  gv_tran_type_name    CONSTANT VARCHAR2(20) := '出荷依頼';
  gv_category_code     CONSTANT VARCHAR2(20) := 'ORDER';
-- 2008/09/18 1.17 Add ↓ T_TE080_BPO_400 指摘79
  gv_shipping_shikyu_class_1 CONSTANT VARCHAR2(1)  := '1';         -- 出荷支給区分:出荷依頼
  gv_cust_class_code_10      CONSTANT VARCHAR2(2)  := '10';        -- 顧客区分:顧客配送
  gv_dummy_cust_code         CONSTANT VARCHAR2(9)  := '000000000'; -- 顧客コード(ダミー)
-- 2008/09/18 1.17 Add ↑
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  TYPE masters_rec IS RECORD(
    deliver_from          xxwsh_order_headers_all.deliver_from%TYPE,      -- 出荷元
    head_sales_branch     xxwsh_order_headers_all.head_sales_branch%TYPE, -- 管轄拠点
-- 2008/07/14 1.3 Update Start
--    prod_class_code       xxcmn_item_categories3_v.prod_class_code%TYPE,  -- 商品区分
    prod_class_h_code     mtl_categories_b.segment1%TYPE,                 -- 本社商品区分
-- 2008/07/14 1.3 Update End
    order_type_id         xxwsh_order_headers_all.order_type_id%TYPE,     -- 受注タイプID
    arrival_date          xxwsh_order_headers_all.arrival_date%TYPE,      -- 着荷日
    deliver_to            xxwsh_order_headers_all.deliver_to%TYPE,        -- 出荷先
    customer_code         xxwsh_order_headers_all.customer_code%TYPE,     -- 顧客
    request_no            xxwsh_order_headers_all.request_no%TYPE,        -- 依頼No
    order_line_id         xxwsh_order_lines_all.order_line_id%TYPE,       -- 受注明細アドオンID
    request_item_code     xxwsh_order_lines_all.request_item_code%TYPE,   -- 依頼品目
    quantity              xxwsh_order_lines_all.quantity%TYPE,            -- 数量
    num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE,             -- ケース入数
    delete_flag           xxwsh_order_lines_all.delete_flag%TYPE,         -- 削除フラグ
    cust_po_number        xxwsh_order_headers_all.cust_po_number%TYPE,    -- 顧客発注番号
    shipped_date          xxwsh_order_headers_all.shipped_date%TYPE,      -- 出荷日
    arrival_time_from     xxwsh_order_headers_all.arrival_time_from%TYPE, -- 着荷時間From
    item_no               xxcmn_item_mst_v.item_no%TYPE,                  -- 親品目
-- 2008/12/24 v2.1 UPDATE START
--    new_crowd_code        xxcmn_item_mst2_v.new_crowd_code%TYPE,          -- 新・群コード
    crowd_code            VARCHAR2(240),                                    -- 群コード
-- 2008/12/24 v2.1 UPDATE END
    shipped_quantity      xxwsh_order_lines_all.shipped_quantity%TYPE,    -- 出荷実績数量
--
    request_class         xxwsh_shipping_class_v.request_class%TYPE,      -- 依頼区分
--
    cases_values          NUMBER,                                         -- ケース入数
--
    -- YYYY/MM/DD
    vd_arrival_date       VARCHAR2(10),                                   -- 着荷日
    vd_shipped_date       VARCHAR2(10),                                   -- 出荷日
--
    -- YYYYMMDD
    v_arrival_date        VARCHAR2(10),                                   -- 着荷日
    v_shipped_date        VARCHAR2(10),                                   -- 出荷日
--
-- 2008/09/18 1.17 Add ↓ T_S_630
    customer_class_code  xxcmn_cust_accounts2_v.customer_class_code%TYPE, -- 顧客情報VIEW.顧客区分
-- 2008/09/18 1.17 Add ↑
    exec_flg              NUMBER                                    -- 処理フラグ
  );
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
--
  TYPE reg_order_line_id IS TABLE OF
       xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
--
  gt_master_tbl           masters_tbl;  -- 各マスタへ登録するデータ
--
  gt_order_line_id        reg_order_line_id;           -- 受注明細アドオンID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_request_path         VARCHAR2(2000);     -- ディレクトリ(出荷依頼)
  gv_request_file         VARCHAR2(2000);     -- ファイル名(出荷依頼)
  gv_results_path         VARCHAR2(2000);     -- ディレクトリ(出荷実績)
  gv_results_file         VARCHAR2(2000);     -- ファイル名(出荷実績)
--
  -- 定数
  gn_created_by               NUMBER;                     -- 作成者
  gd_creation_date            DATE;                       -- 作成日
  gd_last_update_date         DATE;                       -- 最終更新日
  gn_last_update_by           NUMBER;                     -- 最終更新者
  gn_last_update_login        NUMBER;                     -- 最終更新ログイン
  gn_request_id               NUMBER;                     -- 要求ID
  gn_program_application_id   NUMBER;                     -- プログラムアプリケーションID
  gn_program_id               NUMBER;                     -- プログラムID
  gd_program_update_date      DATE;                       -- プログラム更新日
--
-- 2008/12/24 ADD START
  gv_sysdate                  VARCHAR2(240);  -- システム現在日付
--
-- 2008/12/24 ADD END
  /***********************************************************************************
   * Function Name    : cutoff_str
   * Description      : 文字列を末尾から切り取る
   ***********************************************************************************/
  FUNCTION cutoff_str(
    iv_str  IN VARCHAR2,     -- 対象文字列
    in_len  IN NUMBER,       -- 長さ
    in_size IN NUMBER)       -- サイズ
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cutoff_str'; --プログラム名
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
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
--
    RETURN SUBSTR(iv_str,in_len-in_size+1,in_size);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END cutoff_str;
--
  /***********************************************************************************
   * Procedure Name   : if_flg_upd
   * Description      : I/F済フラグの更新
   ***********************************************************************************/
  PROCEDURE if_flg_upd(
    iv_inf_div    IN            VARCHAR2,     -- 1.インタフェース対象
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'if_flg_upd'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- 出荷依頼
    IF (iv_inf_div = gv_inf_sub_request) THEN
      FORALL item_cnt IN 1 .. gt_order_line_id.COUNT
        UPDATE xxwsh_order_lines_all
        SET  shipping_request_if_flg = gv_flag_on                    -- 出荷依頼I/F済フラグ
            ,last_updated_by         = gn_last_update_by
            ,last_update_date        = gd_last_update_date
            ,last_update_login       = gn_last_update_login
            ,request_id              = gn_request_id
            ,program_application_id  = gn_program_application_id
            ,program_id              = gn_program_id
            ,program_update_date     = gd_program_update_date
        WHERE order_line_id = gt_order_line_id(item_cnt);
--
    -- 出荷実績
    ELSIF (iv_inf_div = gv_inf_sub_results) THEN
      FORALL item_cnt IN 1 .. gt_order_line_id.COUNT
        UPDATE xxwsh_order_lines_all
        SET  shipping_result_if_flg  = gv_flag_on                    -- 出荷実績I/F済フラグ
            ,last_updated_by         = gn_last_update_by
            ,last_update_date        = gd_last_update_date
            ,last_update_login       = gn_last_update_login
            ,request_id              = gn_request_id
            ,program_application_id  = gn_program_application_id
            ,program_id              = gn_program_id
            ,program_update_date     = gd_program_update_date
        WHERE order_line_id = gt_order_line_id(item_cnt);
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END if_flg_upd;
--
  /***********************************************************************************
   * Procedure Name   : tbl_lock
   * Description      : テーブルのロックの取得
   ***********************************************************************************/
  PROCEDURE tbl_lock(
    ir_mst_rec    IN OUT NOCOPY masters_rec,  -- 対象データ
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'tbl_lock'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_order_line_id     xxwsh_order_lines_all.order_line_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
--
    -- 受注明細アドオンのロック
    BEGIN
      SELECT xola.order_line_id
      INTO   ln_order_line_id
      FROM   xxwsh_order_lines_all xola
      WHERE  xola.order_line_id = ir_mst_rec.order_line_id
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_08);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END tbl_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_request_class
   * Description      : 依頼区分の取得
   ***********************************************************************************/
  PROCEDURE get_request_class(
    ir_mst_rec    IN OUT NOCOPY masters_rec,  -- 対象データ
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_request_class'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
-- 2008/09/18 1.17 Add ↓ T_TE080_BPO_400 指摘79 出荷区分情報VIEW.依頼区分と出荷区分情報VIEW.顧客区分を取得し、両方NULLの場合はCSV出力しない。
    lt_customer_class   xxwsh_shipping_class_v.customer_class%TYPE; -- 出荷区分情報VIEWの顧客区分
-- 2008/09/18 1.17 Add ↑
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    BEGIN
-- 2008/09/18 1.17 Mod ↓ T_TE080_BPO_400 指摘79 出荷区分情報VIEW.依頼区分と出荷区分情報VIEW.顧客区分を取得し、両方NULLの場合はCSV出力しないように変更
--                        T_S_630                顧客情報VIEW.顧客区分は別箇所での取得となったので、依頼区分の取得に顧客情報VIEWの結合は不要となった
--      SELECT xscv.request_class                     -- 依頼区分
--      INTO   ir_mst_rec.request_class
--      FROM   xxwsh_oe_transaction_types2_v xottv        -- 受注タイプ情報VIEW2
--            ,xxwsh_shipping_class_v        xscv         -- 出荷区分情報VIEW
----            ,hz_parties                    hp           -- パーティマスタ
----            ,hz_party_sites                hps          -- パーティサイトマスタ
----            ,hz_cust_accounts              hca          -- 顧客マスタ
--            ,xxcmn_cust_accounts2_v          xcav       -- 顧客情報View2
--            ,xxcmn_cust_acct_sites2_v        xcasv      -- 顧客サイト情報View2
--      WHERE  xscv.order_transaction_type_name = xottv.transaction_type_name
----      AND    hp.party_id                      = hps.party_id
----      AND    hca.party_id                     = hp.party_id
----      AND    hca.customer_class_code          = xscv.customer_class(+)
----      AND    hps.party_site_number            = ir_mst_rec.deliver_to
--      AND    xcav.customer_class_code         = xscv.customer_class(+)
--      AND    xcav.start_date_active          <= ir_mst_rec.shipped_date
--      AND    xcav.end_date_active            >= ir_mst_rec.shipped_date
--      AND    xcasv.party_id                   = xcav.party_id
--      AND    xcasv.start_date_active         <= ir_mst_rec.shipped_date
--      AND    xcasv.end_date_active           >= ir_mst_rec.shipped_date
--      AND    xcasv.party_site_number          = ir_mst_rec.deliver_to
--      AND    xottv.transaction_type_id        = ir_mst_rec.order_type_id
--      AND    xottv.shipping_shikyu_class      = '1'                        -- 出荷依頼
--      AND    ROWNUM                           = 1;
--
      SELECT xscv.request_class         request_class   -- 依頼区分
            ,xscv.customer_class        customer_class  -- 顧客区分
      INTO   ir_mst_rec.request_class
            ,lt_customer_class
      FROM   xxwsh_oe_transaction_types2_v xottv        -- 受注タイプ情報VIEW2
            ,xxwsh_shipping_class_v        xscv         -- 出荷区分情報VIEW
      WHERE  -- *** 結合条件 受注タイプ情報VIEW2 AND 出荷区分情報VIEW *** --
             xscv.order_transaction_type_name = xottv.transaction_type_name
             -- *** 抽出条件 *** --
      AND    NVL(xscv.customer_class, ir_mst_rec.customer_class_code)
                                              = ir_mst_rec.customer_class_code  -- 出荷区分情報VIEW.顧客区分(出荷区分情報VIEW.顧客区分がNULLの場合は顧客区分を条件としない)
      AND    xottv.transaction_type_id        = ir_mst_rec.order_type_id        -- 受注タイプ
      AND    xottv.shipping_shikyu_class      = gv_shipping_shikyu_class_1      -- 出荷支給区分「1：出荷依頼」
      AND    ROWNUM                           = 1;
-- 2008/09/18 1.17 Mod ↑
--
-- 2008/09/18 1.17 Add ↓ T_TE080_BPO_400 指摘79
    -- 出荷区分情報VIEW.依頼区分と出荷区分情報VIEW.顧客区分を取得し、両方NULLの場合はCSV出力しない。
    IF ((ir_mst_rec.request_class IS NULL)
    AND (lt_customer_class IS NULL)) THEN
      ov_retcode := gv_status_skip;
    END IF;
-- 2008/09/18 1.17 Add ↑
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_mst_rec.request_class := NULL;
        ov_retcode := gv_status_warn;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_request_class;
--
  /***********************************************************************************
   * Procedure Name   : get_results_data
   * Description      : 出荷実績情報の取得
   ***********************************************************************************/
  PROCEDURE get_results_data(
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_results_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt               NUMBER;
    mst_rec              masters_rec;
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
-- 2008/09/04 Mod ↓
/*
      SELECT xoha.arrival_date                   -- 着荷日
*/
      SELECT /*+ leading(xola xoha) use_nl(xoha xola ximb ximv1.iimb ximv2.iimb ) */
             xoha.arrival_date                   -- 着荷日
-- 2008/09/04 Mod ↑
            ,xoha.head_sales_branch              -- 管轄拠点
-- 2008/09/18 1.17 Add ↓ T_S_630
            ,xoha.order_type_id                  -- 受注タイプID
            ,xoha.shipped_date                   -- 出荷日
-- 2008/09/18 1.17 Add ↑
            ,xoha.result_deliver_to              -- 出荷先_実績
            ,xoha.customer_code                  -- 顧客
            ,xoha.request_no                     -- 依頼No
            ,xola.order_line_id                  -- 受注明細アドオンID
            ,xola.request_item_code              -- 依頼品目
-- 2008/12/01 1.9  Mod ↓
            ,CASE WHEN otta.order_category_code   = gv_category_code
                  THEN xola.shipped_quantity
                  ELSE xola.shipped_quantity * (-1)
             END  shipped_quantity
            --,xola.shipped_quantity               -- 出荷実績数量
-- 2008/12/01 1.9  Mod ↑
            ,xola.delete_flag                    -- 削除フラグ
            ,ximv1.item_no                       -- 親品目
-- 2008/12/24 v2.1 UPDATE START
--            ,ximv2.new_crowd_code                -- 新・群コード
            ,CASE
              WHEN NVL(ximv2.crowd_start_date, gv_sysdate) <= gv_sysdate THEN
                ximv2.new_crowd_code             -- 新・群コード
              ELSE
                ximv2.old_crowd_code             -- 旧・群コード
             END crowd_code
-- 2008/12/24 v2.1 UPDATE END
            ,ximv2.num_of_cases                  -- ケース入数
-- 2008/07/14 1.3 Update Start
--            ,xic4.prod_class_code                -- 商品区分
-- 2008/09/04 Mod ↓
--            ,xicv2.prod_class_h_code             -- 本社商品区分
-- 2008/07/14 1.3 Update End
            ,(
             SELECT MAX(CASE
                        WHEN xicv.category_set_name = '本社商品区分' THEN
                          mcb.segment1
                        ELSE
                          NULL
                    END) as prod_class_h_code 
             FROM   xxcmn_item_categories_v xicv 
                  , mtl_categories_b mcb 
             WHERE  xicv.category_id  = mcb.category_id 
             AND    xicv.structure_id = mcb.structure_id 
             AND    xicv.item_id      = ximv2.item_id
             ) prod_class_h_code
-- 2008/09/04 Mod ↑
      FROM   xxwsh_order_headers_all       xoha          -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all         xola          -- 受注明細アドオン
            ,xxwsh_oe_transaction_types2_v otta          -- 受注タイプ情報VIEW
            ,xxcmn_item_mst2_v             ximv1         -- OPM品目マスタ(親)
            ,xxcmn_item_mst2_v             ximv2         -- OPM品目マスタ(子)
            ,xxcmn_item_mst_b              ximb          -- OPM品目アドオンマスタ
-- 2008/07/14 1.3 Update Start
--            ,xxcmn_item_categories4_v      xic4          -- OPM品目カテゴリ割当情報VIEW4
-- 2008/09/04 Del ↓
/*
            ,(SELECT  xicv.item_id
                     ,MAX(CASE
                        WHEN xicv.category_set_name = '本社商品区分' THEN
                          mcb.segment1
                        ELSE
                          NULL
                      END) AS prod_class_h_code          -- 本社商品区分
            FROM      xxcmn_item_categories_v   xicv     -- OPM品目カテゴリ割当情報VIEW
                     ,mtl_categories_b          mcb
            WHERE     xicv.category_id  = mcb.category_id
            AND       xicv.structure_id = mcb.structure_id
            GROUP BY  xicv.item_id) xicv2
*/
-- 2008/09/04 Del ↑
-- 2008/07/14 1.3 Update End
      WHERE  xoha.order_header_id       = xola.order_header_id
      AND    xoha.order_type_id         = otta.transaction_type_id
      AND    ximv2.item_no              = xola.request_item_code
      AND    ximb.item_id               = ximv2.item_id
      AND    ximb.parent_item_id        = ximv1.item_id
      AND    ximb.start_date_active    <= xoha.shipped_date
      AND    ximb.end_date_active      >= xoha.shipped_date
-- 2008/12/01 1.9  Mod ↓
      AND    ximv1.start_date_active    <= xoha.shipped_date
      AND    ximv1.end_date_active      >= xoha.shipped_date
      AND    ximv2.start_date_active    <= xoha.shipped_date
      AND    ximv2.end_date_active      >= xoha.shipped_date
-- 2008/12/01 1.9  Mod ↑
-- 2008/07/14 1.3 Update Start
--      AND    ximv2.item_id              = xic4.item_id
-- 2008/09/04 Del ↓
--      AND    ximv2.item_id              = xicv2.item_id
-- 2008/09/04 Del ↑
-- 2008/07/14 1.3 Update End
      AND    xoha.req_status            = gv_req_status_04                  -- 出荷実績計上済
-- 2008/09/18 1.17 Mod ↓ T_TE080_BPO_400 指摘79 出荷依頼以外の出荷データも抽出対象とする。
--      AND    otta.transaction_type_name = gv_tran_type_name               -- 出荷依頼
      AND    otta.shipping_shikyu_class = gv_shipping_shikyu_class_1        -- 出荷支給区分が「1：出荷依頼」
-- 2008/09/18 1.17 Mod ↑
-- 2008/12/01 1.9  Mod ↓
--    AND    otta.order_category_code   = gv_category_code                  -- 受注
-- 2008/12/01 1.9  Mod ↑
      AND    NVL(otta.adjs_class,gv_adjs_class_req) <> gv_adjs_class_adj    -- 在庫調整以外
      AND    NVL(xola.shipping_result_if_flg, gv_flag_off )  = gv_flag_off  -- 出力済み以外
-- 2009/01/21 2.2 Add start
      AND    xoha.actual_confirm_class = gv_flag_on                         -- 実績計上済区分が'Y'
-- 2009/01/21 2.2 Add end
      ORDER BY xoha.request_no,xola.request_item_code;
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.arrival_date      := lr_mst_data_rec.arrival_date;       -- 着荷日
      mst_rec.head_sales_branch := lr_mst_data_rec.head_sales_branch;  -- 管轄拠点
-- 2008/09/18 1.17 Add ↓ T_S_630
      mst_rec.order_type_id     := lr_mst_data_rec.order_type_id;      -- 受注タイプID
      mst_rec.shipped_date      := lr_mst_data_rec.shipped_date;       -- 出荷日
-- 2008/09/18 1.17 Add ↑
      mst_rec.deliver_to        := lr_mst_data_rec.result_deliver_to;  -- 出荷先_実績
-- 2008/09/18 1.17 Mod ↓ T_S_630 顧客区分により顧客コードを決定
--      mst_rec.customer_code     := lr_mst_data_rec.customer_code;      -- 顧客
--
      -- 顧客区分取得
      SELECT xcav.customer_class_code                   -- 顧客区分
-- 2009/05/22 H.Itou Add Start 本番障害#1398
            ,xcav.party_number                          -- 顧客
-- 2009/05/22 H.Itou Add End
      INTO   mst_rec.customer_class_code
-- 2009/05/22 H.Itou Add Start 本番障害#1398 最新の配送先から顧客を取得し直す。
            ,lr_mst_data_rec.customer_code              -- 顧客
-- 2009/05/22 H.Itou Add End
      FROM   xxcmn_cust_accounts2_v          xcav       -- 顧客情報View2
            ,xxcmn_cust_acct_sites2_v        xcasv      -- 顧客サイト情報View2
      WHERE  xcasv.party_id                   = xcav.party_id
      AND    xcav.start_date_active          <= lr_mst_data_rec.shipped_date
      AND    xcav.end_date_active            >= lr_mst_data_rec.shipped_date
      AND    xcasv.start_date_active         <= lr_mst_data_rec.shipped_date
      AND    xcasv.end_date_active           >= lr_mst_data_rec.shipped_date
      AND    xcasv.party_site_number          = lr_mst_data_rec.result_deliver_to
-- 2009/05/22 H.Itou Add Start 本番障害#1398
-- 2009/10/06 H.Itou Del Start 本番障害#1648 顧客ステータスは参照せず、無効でも処理対象とする。
--      AND    xcav.account_status              = 'A'
-- 2009/10/06 H.Itou Del End
      AND    xcasv.party_site_status          = 'A'
      AND    xcasv.cust_acct_site_status      = 'A'
-- 2009/05/22 H.Itou Add End
      AND    ROWNUM                           = 1;
--
     -- 顧客配送先への出荷の場合
     IF (mst_rec.customer_class_code = gv_cust_class_code_10) THEN
       -- 受注ヘッダアドオンから取得した顧客コード
       mst_rec.customer_code := lr_mst_data_rec.customer_code;
--
     -- 顧客配送先への出荷でない場合
     ELSE
       -- ダミー「000000000」をセット
       mst_rec.customer_code := gv_dummy_cust_code;
     END IF;
-- 2008/09/18 1.17 Mod ↑
      mst_rec.request_no        := lr_mst_data_rec.request_no;         -- 依頼No
      mst_rec.request_item_code := lr_mst_data_rec.request_item_code;  -- 依頼品目
      mst_rec.shipped_quantity  := lr_mst_data_rec.shipped_quantity;   -- 出荷実績数量
      mst_rec.delete_flag       := lr_mst_data_rec.delete_flag;        -- 削除フラグ
      mst_rec.item_no           := lr_mst_data_rec.item_no;            -- 親品目
-- 2008/12/24 v2.1 UPDATE START
--      mst_rec.new_crowd_code    := lr_mst_data_rec.new_crowd_code;     -- 新・群コード
      mst_rec.crowd_code        := lr_mst_data_rec.crowd_code;         -- 群コード
-- 2008/12/24 v2.1 UPDATE END
      mst_rec.num_of_cases      := lr_mst_data_rec.num_of_cases;       -- ケース入数
-- 2008/07/14 1.3 Update Start
--      mst_rec.prod_class_code   := lr_mst_data_rec.prod_class_code;    -- 商品区分
      mst_rec.prod_class_h_code := lr_mst_data_rec.prod_class_h_code;  -- 本社商品区分
-- 2008/07/14 1.3 Update End
--
      mst_rec.order_line_id     := lr_mst_data_rec.order_line_id;      -- 受注明細アドオンID
--
      mst_rec.cases_values      := TO_NUMBER(mst_rec.num_of_cases);
--
      mst_rec.vd_arrival_date   := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYYMMDD');
--
      -- テーブルのロック
      tbl_lock(mst_rec,
               lv_errbuf,
               lv_retcode,
               lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      gt_master_tbl(ln_cnt) := mst_rec;
--
      gt_order_line_id(ln_cnt) := mst_rec.order_line_id;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_results_data;
--
  /***********************************************************************************
   * Procedure Name   : get_request_data
   * Description      : 出荷依頼情報の取得
   ***********************************************************************************/
  PROCEDURE get_request_data(
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_request_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_prof_name   CONSTANT VARCHAR2(100) := '受注タイプ';
--
    -- *** ローカル変数 ***
    ln_cnt                NUMBER;
    mst_rec               masters_rec;
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
-- 2008/09/04 Mod ↓
/*
      SELECT xoha.deliver_from                       -- 出荷元
*/
-- 2008/09/04 Mod ↑
      SELECT /*+ leading(xola xoha) use_nl(xoha xola ximv.ximb ximv.iimb ) */ 
             xoha.deliver_from                       -- 出荷元
            ,xoha.head_sales_branch                  -- 管轄拠点
            ,xoha.order_type_id                      -- 受注タイプID
            ,DECODE(xoha.req_status,gv_req_status_03,NVL( xoha.schedule_arrival_date, xoha.arrival_date ),   -- 着荷予定日
                                    gv_req_status_04,xoha.arrival_date,            -- 着荷日
                                    NULL
                   ) as arrival_date                 -- 着荷日
            ,DECODE(xoha.req_status,gv_req_status_03,NVL( xoha.deliver_to, xoha.result_deliver_to ),         -- 出荷先
                                    gv_req_status_04,xoha.result_deliver_to,       -- 出荷先_実績
                                    NULL
                   ) as deliver_to                   -- 出荷先
            ,xoha.customer_code                      -- 顧客
            ,xoha.request_no                         -- 依頼No
            ,xoha.cust_po_number                     -- 顧客発注番号
            ,DECODE(xoha.req_status,gv_req_status_03,NVL( xoha.schedule_ship_date, xoha.shipped_date ),     -- 出荷予定日
                                    gv_req_status_04,xoha.shipped_date,            -- 出荷日
                                    NULL
                   ) as shipped_date                 -- 出荷日
            ,xoha.arrival_time_from                  -- 着荷時間From
            ,xola.order_line_id                      -- 受注明細アドオンID
            ,xola.request_item_code                  -- 依頼品目
            ,xola.quantity                           -- 数量
            ,xola.delete_flag                        -- 削除フラグ
            ,ximv.num_of_cases                       -- ケース入数
-- 2008/07/14 1.3 Update Start
--            ,xic4.prod_class_code                -- 商品区分
-- 2008/09/04 Mod ↓
--            ,xicv2.prod_class_h_code             -- 本社商品区分
-- 2008/07/14 1.3 Update End
            ,(SELECT MAX(CASE
                        WHEN xicv.category_set_name = '本社商品区分' THEN
                          mcb.segment1
                        ELSE
                          NULL
                     END) AS prod_class_h_code          -- 本社商品区分
              FROM    xxcmn_item_categories_v   xicv     -- OPM品目カテゴリ割当情報VIEW
                     ,mtl_categories_b          mcb
              WHERE   xicv.category_id  = mcb.category_id
              AND     xicv.structure_id = mcb.structure_id
              AND     xicv.item_id      = ximv.item_id
             ) prod_class_h_code
-- 2008/09/04 Mod ↑
      FROM   xxwsh_order_headers_all       xoha          -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all         xola          -- 受注明細アドオン
            ,xxwsh_oe_transaction_types2_v otta          -- 受注タイプ情報VIEW
            ,xxcmn_item_mst_v              ximv          -- OPM品目情報VIEW
-- 2008/09/04 Del ↓
-- 2008/07/14 1.3 Update Start
--            ,xxcmn_item_categories4_v      xic4          -- OPM品目カテゴリ割当情報VIEW4
/*
            ,(SELECT  xicv.item_id
                     ,MAX(CASE
                        WHEN xicv.category_set_name = '本社商品区分' THEN
                          mcb.segment1
                        ELSE
                          NULL
                      END) AS prod_class_h_code          -- 本社商品区分
            FROM      xxcmn_item_categories_v   xicv     -- OPM品目カテゴリ割当情報VIEW
                     ,mtl_categories_b          mcb
            WHERE     xicv.category_id  = mcb.category_id
            AND       xicv.structure_id = mcb.structure_id
            GROUP BY  xicv.item_id) xicv2
*/
-- 2008/07/14 1.3 Update End
-- 2008/09/04 Del ↑
      WHERE  xoha.order_header_id       = xola.order_header_id
      AND    xoha.order_type_id         = otta.transaction_type_id
      AND    xola.request_item_code     = ximv.item_no
-- 2008/07/14 1.3 Update Start
--      AND    ximv.item_id               = xic4.item_id
-- 2008/09/04 Del ↓
--      AND    ximv.item_id               = xicv2.item_id
-- 2008/09/04 Del ↑
-- 2008/07/14 1.3 Update End
      AND    xoha.req_status           >= gv_req_status_03                --「締め済み」以上
      AND    xoha.req_status           <> gv_req_status_99                --「取消」以外
      AND    NVL(xoha.latest_external_flag,gv_flag_off) = gv_flag_on      -- 最新のみ
-- 2008/09/18 1.17 Mod ↓ T_TE080_BPO_400 指摘79 出荷依頼以外の出荷データも抽出対象とする。
--      AND    otta.transaction_type_name = gv_tran_type_name               -- 出荷依頼
      AND    otta.shipping_shikyu_class = gv_shipping_shikyu_class_1        -- 出荷支給区分が「1：出荷依頼」
-- 2008/09/18 1.17 Mod ↑
      AND    otta.order_category_code   = gv_category_code                -- 受注
      AND    NVL(otta.adjs_class,gv_adjs_class_req) <> gv_adjs_class_adj  -- 在庫調整以外
      AND    NVL(xola.delete_flag,gv_flag_off)      <> gv_flag_on         -- 削除以外
      AND    NVL(xola.shipping_request_if_flg, gv_flag_off ) = gv_flag_off  -- 出力済み以外
      ORDER BY xoha.request_no,xola.request_item_code;
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.deliver_from       := lr_mst_data_rec.deliver_from;        -- 出荷元
      mst_rec.head_sales_branch  := lr_mst_data_rec.head_sales_branch;   -- 管轄拠点
      mst_rec.order_type_id      := lr_mst_data_rec.order_type_id;       -- 受注タイプID
-- 2008/09/18 1.17 Mod ↓ T_S_630 顧客区分により顧客コードを決定
--      mst_rec.customer_code      := lr_mst_data_rec.customer_code;       -- 顧客
--
      -- 顧客区分取得
      SELECT xcav.customer_class_code                   -- 顧客区分
-- 2009/05/22 H.Itou Add Start 本番障害#1398
            ,xcav.party_number                          -- 顧客
-- 2009/05/22 H.Itou Add End
      INTO   mst_rec.customer_class_code
-- 2009/05/22 H.Itou Add Start 本番障害#1398 最新の配送先から顧客を取得し直す。
            ,lr_mst_data_rec.customer_code              -- 顧客
-- 2009/05/22 H.Itou Add End
      FROM   xxcmn_cust_accounts2_v          xcav       -- 顧客情報View2
            ,xxcmn_cust_acct_sites2_v        xcasv      -- 顧客サイト情報View2
      WHERE  xcasv.party_id                   = xcav.party_id
      AND    xcav.start_date_active          <= lr_mst_data_rec.shipped_date
      AND    xcav.end_date_active            >= lr_mst_data_rec.shipped_date
      AND    xcasv.start_date_active         <= lr_mst_data_rec.shipped_date
      AND    xcasv.end_date_active           >= lr_mst_data_rec.shipped_date
      AND    xcasv.party_site_number          = lr_mst_data_rec.deliver_to
-- 2009/05/22 H.Itou Add Start 本番障害#1398
-- 2009/10/06 H.Itou Del Start 本番障害#1648 顧客ステータスは参照せず、無効でも処理対象とする。
--      AND    xcav.account_status              = 'A'
-- 2009/10/06 H.Itou Del End
      AND    xcasv.party_site_status          = 'A'
      AND    xcasv.cust_acct_site_status      = 'A'
-- 2009/05/22 H.Itou Add End
      AND    ROWNUM                           = 1;
--
     -- 顧客配送先への出荷の場合
     IF (mst_rec.customer_class_code = gv_cust_class_code_10) THEN
       -- 受注ヘッダアドオンから取得した顧客コード
       mst_rec.customer_code := lr_mst_data_rec.customer_code;
--
     -- 顧客配送先への出荷でない場合
     ELSE
       -- ダミー「000000000」をセット
       mst_rec.customer_code := gv_dummy_cust_code;
     END IF;
-- 2008/09/18 1.17 Mod ↑
      mst_rec.request_no         := lr_mst_data_rec.request_no;          -- 依頼No
      mst_rec.cust_po_number     := lr_mst_data_rec.cust_po_number;      -- 顧客発注番号
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;   -- 着荷時間From
      mst_rec.request_item_code  := lr_mst_data_rec.request_item_code;   -- 依頼品目
      mst_rec.quantity           := lr_mst_data_rec.quantity;            -- 数量
      mst_rec.delete_flag        := lr_mst_data_rec.delete_flag;         -- 削除フラグ
      mst_rec.num_of_cases       := lr_mst_data_rec.num_of_cases;        -- ケース入数
-- 2008/07/14 1.3 Update Start
--      mst_rec.prod_class_code    := lr_mst_data_rec.prod_class_code;     -- 商品区分
      mst_rec.prod_class_h_code  := lr_mst_data_rec.prod_class_h_code;   -- 本社商品区分
-- 2008/07/14 1.3 Update End
--
      mst_rec.order_line_id      := lr_mst_data_rec.order_line_id;       -- 受注明細アドオンID
--
      mst_rec.arrival_date       := lr_mst_data_rec.arrival_date;        -- 着荷予定日
      mst_rec.deliver_to         := lr_mst_data_rec.deliver_to;          -- 出荷先
      mst_rec.shipped_date       := lr_mst_data_rec.shipped_date;        -- 出荷予定日
--
      mst_rec.cases_values       := TO_NUMBER(mst_rec.num_of_cases);
--
      mst_rec.vd_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.vd_shipped_date    := TO_CHAR(mst_rec.shipped_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date     := TO_CHAR(mst_rec.arrival_date,'YYYYMMDD');
      mst_rec.v_shipped_date     := TO_CHAR(mst_rec.shipped_date,'YYYYMMDD');
--
      -- テーブルのロック
      tbl_lock(mst_rec,
               lv_errbuf,
               lv_retcode,
               lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 依頼区分の取得
      get_request_class(mst_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      -- エラー
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- 警告
      ELSIF (lv_retcode = gv_status_warn) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_05,
                                              gv_type_name,
                                              lv_prof_name);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := gv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
--
-- 2008/09/18 1.17 Mod ↓ T_TE080_BPO_400 指摘79
--      END IF;
      -- 出荷区分情報VIEW.依頼区分と出荷区分情報VIEW.顧客区分を取得し、両方NULLの場合(荒茶出荷,庭先出荷)はCSV出力しない。
      ELSIF (lv_retcode = gv_status_skip) THEN
        NULL;
--
      -- 正常の場合のみCSV出力
      ELSE
-- 2008/09/18 1.17 Mod ↑
        gt_master_tbl(ln_cnt) := mst_rec;
--
        gt_order_line_id(ln_cnt) := mst_rec.order_line_id;
--
        ln_cnt := ln_cnt + 1;
-- 2008/09/18 1.17 Add ↓ T_TE080_BPO_400 指摘79
      END IF;
-- 2008/09/18 1.17 Add ↑
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_request_data;
--
  /***********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック       (F-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_inf_div    IN            VARCHAR2,     -- 1.インタフェース対象
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_tkn_name     CONSTANT VARCHAR2(100) := 'インタフェース対象';
    lv_lookup_code  CONSTANT VARCHAR2(50)  := 'XXWSH_401F_INTERFACE_SUBJECT';
--
    -- *** ローカル変数 ***
    ln_cnt      NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    IF (iv_inf_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_num_40f_01,
                                            gv_tkn_parameter,
                                            lv_tkn_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 存在チェック
    SELECT COUNT(xlv.lookup_type)
    INTO   ln_cnt
    FROM   xxcmn_lookup_values_v xlv
    WHERE  xlv.lookup_type = lv_lookup_code
    AND    xlv.lookup_code = iv_inf_div;
-- 2008/08/04 Mod ↓
--    AND    ROWNUM      = 1;
-- 2008/08/04 Mod ↑
--
    -- 存在しない
    IF (ln_cnt < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_num_40f_03);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- WHOカラムの取得
    gn_created_by             := FND_GLOBAL.USER_ID;           -- 作成者
    gd_creation_date          := SYSDATE;                      -- 作成日
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- 最終更新者
    gd_last_update_date       := SYSDATE;                      -- 最終更新日
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- プログラムアプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    gd_program_update_date    := SYSDATE;                      -- プログラム更新日
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END parameter_check;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : プロファイル取得         (F-2)
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_prof_name     VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- XXWSH:IFファイル出力先ディレクトリ_出荷依頼情報抽出(出荷依頼)
    gv_request_path := FND_PROFILE.VALUE('XXWSH_OB_IF_DEST_PATH_REQUEST');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_request_path IS NULL) THEN
      lv_prof_name := 'XXWSH:IFファイル出力先ディレクトリ_出荷依頼情報抽出(出荷依頼)';
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:IFファイル名_出荷依頼情報抽出(出荷依頼)
    gv_request_file := FND_PROFILE.VALUE('XXWSH_OB_IF_FILENAME_REQUEST');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_request_file IS NULL) THEN
      lv_prof_name := 'XXWSH:IFファイル名_出荷依頼情報抽出(出荷依頼)';
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:IFファイル出力先ディレクトリ_出荷依頼情報抽出(出荷実績)
    gv_results_path := FND_PROFILE.VALUE('XXWSH_OB_IF_DEST_PATH_RESULTS');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_results_path IS NULL) THEN
      lv_prof_name := 'XXWSH:IFファイル出力先ディレクトリ_出荷依頼情報抽出(出荷実績)';
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:IFファイル名_出荷依頼情報抽出(出荷実績)
    gv_results_file := FND_PROFILE.VALUE('XXWSH_OB_IF_FILENAME_RESULTS');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_results_file IS NULL) THEN
      lv_prof_name := 'XXWSH:IFファイル名_出荷依頼情報抽出(出荷実績)';
      RAISE get_profile_expt;
    END IF;
--
  EXCEPTION
    WHEN get_profile_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_num_40f_04,
                                            gv_tkn_prof_name,
                                            lv_prof_name);
--
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||ov_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_profile;
--
  /***********************************************************************************
   * Procedure Name   : get_obj_data
   * Description      : 出荷依頼情報抽出         (F-3)
   ***********************************************************************************/
  PROCEDURE get_obj_data(
    iv_inf_div    IN            VARCHAR2,     -- 1.インタフェース対象
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_obj_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    IF (iv_inf_div = gv_inf_sub_request) THEN
--
      -- 出荷依頼情報の取得
      get_request_data(lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
    ELSE
--
      -- 出荷実績情報の取得
      get_results_data(lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- 対象件数なし
    IF (gt_master_tbl.COUNT < 1) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_02);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- 2008/08/04 Mod ↓
--        gn_warn_cnt := gn_warn_cnt + 1;
-- 2008/08/04 Mod ↑
        ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_obj_data;
--
  /***********************************************************************************
   * Procedure Name   : put_obj_data
   * Description      : 出荷依頼情報出力         (F-4)
   ***********************************************************************************/
  PROCEDURE put_obj_data(
    iv_inf_div    IN            VARCHAR2,     -- 1.インタフェース対象
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_obj_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
-- 2008/08/22 Add ↓
    cv_def_date     CONSTANT VARCHAR2(4)  := '9999';
    cv_def_kbn      CONSTANT VARCHAR2(1)  := '1';
-- 2008/08/22 Add ↑
--
    -- *** ローカル変数 ***
    mst_rec         masters_rec;
    lv_data         VARCHAR2(5000);
    lf_file_hand    UTL_FILE.FILE_TYPE;         -- ファイル・ハンドルの宣言
    lv_dir          VARCHAR2(2000);             -- 出力先
    lv_file         VARCHAR2(2000);             -- ファイル名
--
    ln_retcd        NUMBER;
    lv_outno        VARCHAR2(12);
    ln_qty          NUMBER;
    ln_len          NUMBER;
    lv_str          VARCHAR2(20);
-- 2008/08/22 Add ↓
    lv_def_date     VARCHAR2(6);
-- 2008/08/22 Add ↑
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- 出荷依頼
    IF (iv_inf_div = gv_inf_sub_request) THEN
      lv_dir  := gv_request_path;
      lv_file := gv_request_file;
--
    -- 出荷実績
    ELSE
      lv_dir  := gv_results_path;
      lv_file := gv_results_file;
    END IF;
--
    gn_target_cnt := gt_master_tbl.COUNT;
--
    BEGIN
--
      -- ファイルオープン
      lf_file_hand := UTL_FILE.FOPEN(lv_dir,
                                     lv_file,
                                     'w');
--
      -- データあり
      IF (gt_master_tbl.COUNT > 0) THEN
--
        <<file_put_loop>>
        FOR i IN 1..gt_master_tbl.COUNT LOOP
          mst_rec := gt_master_tbl(i);
--
          -- 依頼Noコンバート関数
          ln_retcd := xxwsh_common_pkg.convert_request_number(
                              iv_conv_div             => '2'
                             ,iv_pre_conv_request_no  => mst_rec.request_no
                             ,ov_aft_conv_request_no  => lv_outno
                             );
--
          -- コンバートエラー
          IF (ln_retcd <> 0) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_tkn_num_40f_06);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- 共通部分
          lv_data := gv_data_div||cv_sep_com||gv_r_no||cv_sep_com||gv_continue;
--
          -- 出荷依頼
          IF (iv_inf_div = gv_inf_sub_request) THEN
-- 2008/08/22 Add ↓
            lv_def_date := cv_def_date || mst_rec.prod_class_h_code
                                       || mst_rec.request_class;
-- 2008/08/22 Add ↑
--
-- 2008/08/22 Mod ↓
--            lv_data := lv_data || cv_sep_com || gv_max_date;                -- 計上年月
            lv_data := lv_data || cv_sep_com || lv_def_date;                -- 計上年月
-- 2008/08/22 Mod ↓
            lv_data := lv_data || cv_sep_com || mst_rec.deliver_from;       -- 出庫拠点コード
            lv_data := lv_data || cv_sep_com || mst_rec.head_sales_branch;  -- 依頼拠点コード
-- 2008/07/14 1.3 Update Start
--            lv_data := lv_data || cv_sep_com || mst_rec.prod_class_code;    -- 商品区分
--            lv_data := lv_data || cv_sep_com || mst_rec.prod_class_h_code;  -- 本社商品区分
-- 2008/07/14 1.3 Update End
--            lv_data := lv_data || cv_sep_com || mst_rec.request_class;      -- 依頼区分
-- 2008/08/22 Mod ↓
--            lv_data := lv_data || cv_sep_com || cv_def_kbn;                 -- 本社商品区分
--            lv_data := lv_data || cv_sep_com || cv_def_kbn;                 -- 依頼区分
-- 2008/08/22 Mod ↑
-- 2008/12/03 Mod 2.0 Update Start 出荷実績と同様の仕組みとする。本番#255
            -- 伝票区分1
            IF (SUBSTR(mst_rec.head_sales_branch,1,1) = '7') THEN
              lv_data := lv_data || cv_sep_com || '2';              -- 専門店
            ELSE
              lv_data := lv_data || cv_sep_com || '1';              -- 拠点出荷
            END IF;
            lv_data := lv_data || cv_sep_com || '1';                        -- 伝票区分2
-- 2008/12/03 Mod 2.0 Update End
            lv_data := lv_data || cv_sep_com || mst_rec.v_arrival_date;     -- 着日(YYYYMMDD)
            lv_data := lv_data || cv_sep_com || mst_rec.deliver_to;         -- 配送先コード
            lv_data := lv_data || cv_sep_com || mst_rec.customer_code;      -- 顧客コード
            lv_data := lv_data || cv_sep_com || lv_outno;                   -- 依頼伝票NO
--
            -- 品名コード
            ln_len := LENGTHB(mst_rec.request_item_code);
            IF (ln_len > 6) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.request_item_code,ln_len,5);
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.request_item_code;
            END IF;
--
            lv_data := lv_data || cv_sep_com || gv_num_zero;                -- 予備1
            lv_data := lv_data || cv_sep_com || gv_num_zero;                -- 予備2
--
            --ケース数
            IF ((mst_rec.num_of_cases IS NULL)
              OR (mst_rec.num_of_cases = gv_num_zero)
              OR (mst_rec.quantity IS NULL)) THEN
              lv_str := NULL;
            ELSE
              ln_qty := TRUNC(mst_rec.quantity / mst_rec.cases_values);
              lv_str := TO_CHAR(ln_qty,'FM999999');
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            --入数
            IF (mst_rec.num_of_cases IS NULL) THEN
              lv_data := lv_data || cv_sep_com || NULL;
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.num_of_cases;
            END IF;
--
            --本数(バラ)
            IF ((mst_rec.num_of_cases IS NULL)
              OR (mst_rec.num_of_cases = gv_num_zero)) THEN
              lv_str := TO_CHAR(mst_rec.quantity);
            ELSE
              IF (mst_rec.quantity IS NULL) THEN
                lv_str := NULL;
              ELSE
                ln_qty  := MOD(mst_rec.quantity, mst_rec.cases_values);
                lv_str  := TO_CHAR(ln_qty,'FM999999990.99');
              END IF;
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            --PO#
            ln_len := LENGTHB(mst_rec.cust_po_number);
            IF (ln_len > 9) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.cust_po_number,ln_len,9);
            ELSE
-- 2008/11/06 1.17 Mod ↓ 9桁未満は左0埋めを行い9桁にする。
--              lv_data := lv_data || cv_sep_com || mst_rec.cust_po_number;
              lv_data := lv_data || cv_sep_com || LPAD(mst_rec.cust_po_number, 9, '0');
-- 2008/11/06 1.17 Mod ↑
            END IF;
--
            lv_data := lv_data || cv_sep_com || mst_rec.v_shipped_date;     -- 発送日(YYYYMMDD)
            lv_data := lv_data || cv_sep_com || mst_rec.arrival_time_from;  -- 時間指定
            lv_data := lv_data || cv_sep_com || NULL;                       -- 予備4
--
          -- 出荷実績
          ELSE
            lv_data := lv_data || cv_sep_com || TO_CHAR(mst_rec.arrival_date,'YYYYMM');
--
            -- 入力拠点コード
-- 2008/07/14 1.3 Update Start
--            IF (mst_rec.prod_class_code = gv_prod_class_reef) THEN
            IF (mst_rec.prod_class_h_code = gv_prod_class_reef) THEN
-- 2008/07/14 1.3 Update End
              lv_data := lv_data || cv_sep_com || gv_base_code_reef;
            ELSE
              lv_data := lv_data || cv_sep_com || gv_base_code_drink;
            END IF;
--
            lv_data := lv_data || cv_sep_com || mst_rec.head_sales_branch;  -- 相手拠点コード
--
            -- 伝票区分1
            IF (SUBSTR(mst_rec.head_sales_branch,1,1) = '7') THEN
              lv_data := lv_data || cv_sep_com || '2';              -- 専門店
            ELSE
              lv_data := lv_data || cv_sep_com || '1';              -- 拠点出荷
            END IF;
--
            lv_data := lv_data || cv_sep_com || '1';                        -- 伝票区分2
            lv_data := lv_data || cv_sep_com || mst_rec.v_arrival_date;     -- 着荷日(YYYYMMDD)
            lv_data := lv_data || cv_sep_com || mst_rec.deliver_to;         -- 配送先コード
            lv_data := lv_data || cv_sep_com || mst_rec.customer_code;      -- 顧客コード
            lv_data := lv_data || cv_sep_com || lv_outno;                   -- 伝票NO
--
            -- 品名コード・エントリー
            ln_len := LENGTHB(mst_rec.request_item_code);
            IF (ln_len > 6) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.request_item_code,ln_len,5);
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.request_item_code;
            END IF;
--
             -- 品名コード・親
            ln_len := LENGTHB(mst_rec.item_no);
            IF (ln_len > 6) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.item_no,ln_len,5);
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.item_no;
            END IF;
--
-- 2008/12/24 v2.1 UPDATE START
--            lv_data := lv_data || cv_sep_com || mst_rec.new_crowd_code;     -- 群コード
            lv_data := lv_data || cv_sep_com || mst_rec.crowd_code;         -- 群コード
-- 2008/12/24 v2.1 UPDATE END
--
            -- ケース数
            IF (NVL(mst_rec.delete_flag,gv_flag_off) = gv_flag_on) THEN
              lv_str := gv_num_zero;
            ELSE
              IF ((mst_rec.num_of_cases IS NULL)
                OR (mst_rec.num_of_cases = gv_num_zero)
                OR (mst_rec.shipped_quantity IS NULL)) THEN
                lv_str := NULL;
              ELSE
                ln_qty := TRUNC(mst_rec.shipped_quantity / mst_rec.cases_values);
                lv_str := TO_CHAR(ln_qty,'FM999999');
              END IF;
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            -- 入数
            IF (mst_rec.num_of_cases IS NULL) THEN
              lv_data := lv_data || cv_sep_com || NULL;
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.num_of_cases;
            END IF;
--
            -- 本数(バラ)
            IF (NVL(mst_rec.delete_flag,gv_flag_off) = gv_flag_on) THEN
              lv_str := gv_num_zero;
            ELSE
              IF ((mst_rec.num_of_cases IS NULL)
                OR (mst_rec.num_of_cases = gv_num_zero)) THEN
                lv_str := TO_CHAR(mst_rec.shipped_quantity);
              ELSE
                IF (mst_rec.shipped_quantity IS NULL) THEN
                  lv_str := NULL;
                ELSE
                  ln_qty  := MOD(mst_rec.shipped_quantity, mst_rec.cases_values);
                  lv_str  := TO_CHAR(ln_qty,'FM999999990.99');
                END IF;
              END IF;
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            -- 予備
            lv_data := lv_data || cv_sep_com || NULL;                -- 予備1
            lv_data := lv_data || cv_sep_com || NULL;                -- 予備2
            lv_data := lv_data || cv_sep_com || NULL;                -- 予備3
            lv_data := lv_data || cv_sep_com || NULL;                -- 予備4
          END IF;
--
          -- データ出力
          UTL_FILE.PUT_LINE(lf_file_hand,lv_data);
        END LOOP file_put_loop;
      END IF;
--
      -- ファイルクローズ
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
--
      WHEN UTL_FILE.INVALID_PATH OR         -- ファイルパス不正エラー
           UTL_FILE.INVALID_FILENAME OR     -- ファイル名不正エラー
           UTL_FILE.ACCESS_DENIED OR        -- ファイルアクセス権限エラー
           UTL_FILE.WRITE_ERROR THEN        -- 書き込みエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_07);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END put_obj_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_inf_div    IN            VARCHAR2,     -- 1.インタフェース対象
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/12/24 v2.1 ADD START
    -- 群コード適用日付
    gv_sysdate    := TO_CHAR(SYSDATE, 'YYYY/MM/DD');
--
-- 2008/12/24 v2.1 ADD END
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      パラメータチェック(F-1)          ***
    --*********************************************
    parameter_check(
           iv_inf_div,   -- インタフェース対象
           lv_errbuf,    -- エラー・メッセージ
           lv_retcode,   -- リターン・コード
           lv_errmsg);   -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      プロファイル取得(F-2)            ***
    --*********************************************
    get_profile(
           lv_errbuf,    -- エラー・メッセージ
           lv_retcode,   -- リターン・コード
           lv_errmsg);   -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      出荷依頼情報抽出(F-3)            ***
    --*********************************************
    get_obj_data(
           iv_inf_div,   -- インタフェース対象
           lv_errbuf,    -- エラー・メッセージ
           lv_retcode,   -- リターン・コード
           lv_errmsg);   -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 警告
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    --*********************************************
    --***      出荷依頼情報出力(F-4)            ***
    --*********************************************
    put_obj_data(
           iv_inf_div,   -- インタフェース対象
           lv_errbuf,    -- エラー・メッセージ
           lv_retcode,   -- リターン・コード
           lv_errmsg);   -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- I/F済フラグの更新
    if_flg_upd(
           iv_inf_div,   -- インタフェース対象
           lv_errbuf,    -- エラー・メッセージ
           lv_retcode,   -- リターン・コード
           lv_errmsg);   -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_inf_div    IN            VARCHAR2       -- 1.インタフェース対象
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
--
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
      iv_inf_div,  -- 1.インタフェース対象
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh400005c;
/
