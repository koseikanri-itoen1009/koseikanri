CREATE OR REPLACE PACKAGE BODY xxpo440007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440007c(body)
 * Description      : 支給価格変更処理
 * MD.050           : 有償支給            T_MD050_BPO_440
 * MD.070           : 支給価格変更処理    T_MD070_BPO_44O
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  tbl_lock               受注明細アドオンのロック
 *  init_proc              前処理                                          (O-1)
 *  parameter_check        パラメータチェック                              (O-2)
 *  get_data               支給データ取得                                  (O-3)
 *  upd_lines              受注明細更新                                    (O-6)
 *  disp_report            処理結果情報出力                                (O-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/15    1.0   Oracle 山根 一浩 初回作成
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
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
  get_data_expt             EXCEPTION;     -- 支給データ取得エラー
  lock_expt                 EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo440007c';    -- パッケージ名
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';           -- アプリケーション短縮名
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';          -- アプリケーション短縮名
--
  gv_tkn_ng_profile     CONSTANT VARCHAR2(20) := 'NG_PROFILE';
  gv_tkn_data           CONSTANT VARCHAR2(20) := 'DATA';
  gv_tkn_param          CONSTANT VARCHAR2(20) := 'PARAM';
  gv_tkn_param_name     CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  gv_tkn_param_value    CONSTANT VARCHAR2(20) := 'PARAM_VALUE';
  gv_tkn_format         CONSTANT VARCHAR2(20) := 'FORMAT';
  gv_tkn_entry          CONSTANT VARCHAR2(20) := 'ENTRY';
  gv_tkn_cnt_all        CONSTANT VARCHAR2(20) := 'CNT_ALL';
  gv_tkn_cnt_out        CONSTANT VARCHAR2(20) := 'CNT_OUT';
  gv_tkn_cnt_in         CONSTANT VARCHAR2(20) := 'CNT_IN';
  gv_tkn_i_no           CONSTANT VARCHAR2(20) := 'I_NO';
  gv_tkn_vendor_cd      CONSTANT VARCHAR2(20) := 'VENDOR_CD';
  gv_tkn_date           CONSTANT VARCHAR2(20) := 'DATE';
  gv_tkn_item_no        CONSTANT VARCHAR2(20) := 'ITEM_NO';
  gv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';
--
  gv_tkn_name_dept_code   CONSTANT VARCHAR2(100) := '担当部署コード';
  gv_tkn_name_from_date   CONSTANT VARCHAR2(100) := '入庫日_FROM';
  gv_tkn_name_to_date     CONSTANT VARCHAR2(100) := '入庫日_TO';
  gv_tkn_name_prod_class  CONSTANT VARCHAR2(100) := '商品区分';
  gv_tkn_name_item_class  CONSTANT VARCHAR2(100) := '品目区分';
  gv_tkn_name_vendor_code CONSTANT VARCHAR2(100) := '取引先コード';
  gv_tkn_name_item_code   CONSTANT VARCHAR2(100) := '品目コード';
  gv_tkn_name_request_no  CONSTANT VARCHAR2(100) := '依頼No';
--
  gn_exec_flg_on          CONSTANT NUMBER := 1;
  gn_exec_flg_off         CONSTANT NUMBER := 0;
--
  gv_flg_on               CONSTANT VARCHAR2(1) := 'Y';
  gv_flg_off              CONSTANT VARCHAR2(1) := 'N';
  gv_fix_class_on         CONSTANT VARCHAR2(1) := '1';
  gv_fix_class_off        CONSTANT VARCHAR2(1) := '0';
  gv_req_status_on        CONSTANT VARCHAR2(2) := '00';
  gv_req_status_off       CONSTANT VARCHAR2(2) := '99';
  gv_category_code_rtn    CONSTANT VARCHAR2(9) := 'RETURN';
  gv_shikyu_class         CONSTANT VARCHAR2(1) := '2';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- 対象データ
  TYPE masters_rec IS RECORD(
    order_header_id    xxwsh_order_headers_all.order_header_id%TYPE,  -- 受注ヘッダアドオンID
    spare2             xxcmn_vendors_v.spare2%TYPE,                   -- 取引先別価格表ID
    arrival_date       xxwsh_order_headers_all.arrival_date%TYPE,     -- 着荷日
    item_class_code    xxcmn_item_categories3_v.item_class_code%TYPE, -- 品目区分
    item_no            xxcmn_item_mst_v.item_no%TYPE,                 -- OPM品目コード
--
    request_no         xxwsh_order_headers_all.request_no%TYPE,       -- 依頼No
    vendor_code        xxwsh_order_headers_all.vendor_code%TYPE,      -- 取引先
--
    exec_flg           NUMBER                                         -- 処理フラグ
  );
--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      項目格納テーブル型定義     ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;  -- 各マスタへ登録するデータ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_xxpo_price_list_id       VARCHAR2(20);               -- XXPO:代表価格表
  gv_org_id                   VARCHAR2(20);               -- MO:営業単位
  gv_close_date               VARCHAR2(6);                -- CLOSE年月日
--
  gd_from_date                DATE;
  gd_to_date                  DATE;
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
  gn_keep_cnt                 NUMBER;                     -- 保持件数
  gn_other_cnt                NUMBER;                     -- その他件数
--
  /***********************************************************************************
   * Procedure Name   : tbl_lock
   * Description      : 受注明細アドオンのロック
   ***********************************************************************************/
  PROCEDURE tbl_lock(
    ir_mst_rec      IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_tbl_name     CONSTANT VARCHAR2(100) := '受注明細アドオン';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT xola.order_line_id
      FROM   xxwsh_order_lines_all xola
      WHERE  xola.order_header_id = ir_mst_rec.order_header_id   -- 受注ヘッダアドオンID
      AND    NVL(xola.delete_flag,gv_flg_off) = gv_flg_off       -- 削除フラグ
      AND    xola.shipping_item_code = ir_mst_rec.item_no        -- 出荷品目コード
      FOR UPDATE OF xola.order_line_id NOWAIT;
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
    -- 受注明細アドオンのロック
    OPEN lock_cur;
--
  EXCEPTION
    -- *** ロック獲得失敗ハンドラ ***
    WHEN lock_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10027',
                                            gv_tkn_table,
                                            lv_tbl_name);
      ov_errbuf  := ov_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||ov_errbuf,1,5000);
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
  END tbl_lock;
--
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 前処理(O-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    iv_dept_code   IN            VARCHAR2,     -- 1.担当部署コード(必須)
    iv_from_date   IN            VARCHAR2,     -- 2.入庫日(FROM)(任意)
    iv_to_date     IN            VARCHAR2,     -- 3.入庫日(TO)(任意)
    iv_prod_class  IN            VARCHAR2,     -- 4.商品区分(必須)
    iv_item_class  IN            VARCHAR2,     -- 5.品目区分(任意)
    iv_vendor_code IN            VARCHAR2,     -- 6.取引先コード(任意)
    iv_item_code   IN            VARCHAR2,     -- 7.品目コード(任意)
    iv_request_no  IN            VARCHAR2,     -- 8.依頼No(任意)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- XXPO:代表価格表
    gv_xxpo_price_list_id := FND_PROFILE.VALUE('XXPO_PRICE_LIST_ID');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_xxpo_price_list_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10113');
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- MO:営業単位
    gv_org_id := FND_PROFILE.VALUE('ORG_ID');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_org_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10005');
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
    gv_close_date             := xxcmn_common_pkg.get_opminv_close_period;  -- CLOSE年月日
--
    -- パラメータ出力:担当部署コード
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_dept_code,
                                          gv_tkn_data,
                                          iv_dept_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- パラメータ出力:入庫日_FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_from_date,
                                          gv_tkn_data,
                                          iv_from_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- パラメータ出力:入庫日_TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_to_date,
                                          gv_tkn_data,
                                          iv_to_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- パラメータ出力:商品区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_prod_class,
                                          gv_tkn_data,
                                          iv_prod_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- パラメータ出力:品目区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_item_class,
                                          gv_tkn_data,
                                          iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- パラメータ出力:取引先コード
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_vendor_code,
                                          gv_tkn_data,
                                          iv_vendor_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- パラメータ出力:品目コード
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_item_code,
                                          gv_tkn_data,
                                          iv_item_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- パラメータ出力:依頼No
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_request_no,
                                          gv_tkn_data,
                                          iv_request_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END init_proc;
--
  /***********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(O-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_dept_code   IN            VARCHAR2,     -- 1.担当部署コード(必須)
    iv_from_date   IN            VARCHAR2,     -- 2.入庫日(FROM)(任意)
    iv_to_date     IN            VARCHAR2,     -- 3.入庫日(TO)(任意)
    iv_prod_class  IN            VARCHAR2,     -- 4.商品区分(必須)
    iv_item_class  IN            VARCHAR2,     -- 5.品目区分(任意)
    iv_vendor_code IN            VARCHAR2,     -- 6.取引先コード(任意)
    iv_item_code   IN            VARCHAR2,     -- 7.品目コード(任意)
    iv_request_no  IN            VARCHAR2,     -- 8.依頼No(任意)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    ln_cnt               NUMBER;
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
    -- 担当部署に設定があるかどうか必須チェック
    IF (iv_dept_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10096',
                                            gv_tkn_entry,
                                            gv_tkn_name_dept_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 商品区分に設定があるかどうか必須チェック
    IF (iv_prod_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10096',
                                            gv_tkn_entry,
                                            gv_tkn_name_prod_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 商品区分がXXPOカテゴリ情報VIEWに定義されているかチェック
    SELECT COUNT(xcv.category_set_id)
    INTO   ln_cnt
    FROM   xxpo_categories_v xcv
    WHERE  xcv.category_set_name = gv_tkn_name_prod_class             -- 商品区分
    AND    xcv.enable_flag       = gv_flg_on                          -- Y
    AND    xcv.category_code     = iv_prod_class
    AND    ROWNUM                = 1;
--
    -- 存在しない
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10103',
                                            gv_tkn_param_name,
                                            gv_tkn_name_prod_class,
                                            gv_tkn_param_value,
                                            iv_prod_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 入庫日(FROM)の入力あり
    IF (iv_from_date IS NOT NULL) THEN
--
      -- 日付に変換
      gd_from_date := FND_DATE.STRING_TO_DATE(iv_from_date,'YYYY/MM/DD');
--
      -- 日付として妥当でない
      IF (gd_from_date IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10034',
                                              gv_tkn_param,
                                              gv_tkn_name_from_date,
                                              gv_tkn_format,
                                              'YYYY/MM/DD');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 入庫日(TO)の入力あり
    IF (iv_to_date IS NOT NULL) THEN
--
      -- 日付に変換
      gd_to_date := FND_DATE.STRING_TO_DATE(iv_to_date,'YYYY/MM/DD');
--
      -- 日付として妥当でない
      IF (gd_to_date IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10034',
                                              gv_tkn_param,
                                              gv_tkn_name_to_date,
                                              gv_tkn_format,
                                              'YYYY/MM/DD');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 入庫日入力あり
    IF ((iv_from_date IS NOT NULL) AND (iv_to_date IS NOT NULL)) THEN
--
      -- 入庫日（FROM）と入庫日（TO）が逆転していないか大小比較チェック
      IF (gd_from_date > gd_to_date) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10139',
                                              gv_tkn_param,
                                              gv_tkn_name_to_date);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
   * Procedure Name   : get_data
   * Description      : 支給データ取得(O-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_dept_code   IN            VARCHAR2,     -- 1.担当部署コード(必須)
    iv_from_date   IN            VARCHAR2,     -- 2.入庫日(FROM)(任意)
    iv_to_date     IN            VARCHAR2,     -- 3.入庫日(TO)(任意)
    iv_prod_class  IN            VARCHAR2,     -- 4.商品区分(必須)
    iv_item_class  IN            VARCHAR2,     -- 5.品目区分(任意)
    iv_vendor_code IN            VARCHAR2,     -- 6.取引先コード(任意)
    iv_item_code   IN            VARCHAR2,     -- 7.品目コード(任意)
    iv_request_no  IN            VARCHAR2,     -- 8.依頼No(任意)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    lv_tbl_name     CONSTANT VARCHAR2(100) := '受注明細アドオン';
--
    -- *** ローカル変数 ***
    ln_cnt              NUMBER;
    ln_order_line_id    xxwsh_order_lines_all.order_line_id%TYPE;
    mst_rec             masters_rec;
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
      SELECT xoha.order_header_id                       -- 受注ヘッダアドオンID
            ,xoha.arrival_date                          -- 着荷日
            ,xoha.schedule_arrival_date                 -- 着荷予定日
            ,xoha.request_no                            -- 依頼No
            ,xoha.vendor_code                           -- 取引先
            ,xvv.spare2                                 -- 取引先別価格表ID
            ,xicv.item_class_code                       -- 品目区分
            ,ximv.item_no                               -- OPM品目コード
      FROM   xxwsh_order_headers_all      xoha   -- 受注ヘッダアドオン
            ,oe_transaction_types_all     ota    -- 受注タイプ
            ,xxcmn_item_mst_v             ximv   -- OPM品目情報VIEW
            ,xxcmn_item_categories3_v     xicv   -- OPM品目カテゴリ割当情報VIEW3
            ,xxcmn_vendors_v              xvv    -- 仕入先情報VIEW
            ,xxwsh_oe_transaction_types_v xotv   -- 受注タイプ情報VIEW
      WHERE  ota.transaction_type_id  = xoha.order_type_id
      AND    ximv.item_id             = xicv.item_id
      AND    xoha.vendor_id           = xvv.vendor_id
      AND    ota.transaction_type_id  = xotv.transaction_type_id
      AND    NVL(xoha.latest_external_flag,gv_flg_off) = gv_flg_on            -- 最新
      AND    NVL(xoha.amount_fix_class,gv_fix_class_off) <> gv_fix_class_on   -- 確定以外
      AND    NVL(xoha.req_status,gv_req_status_on) <> gv_req_status_off       -- 取消以外
      AND    xotv.shipping_shikyu_class = gv_shikyu_class                     -- 支給依頼
      AND    xotv.order_category_code <> gv_category_code_rtn                 -- 返品以外
      AND    EXISTS (
        SELECT xola.order_header_id
        FROM   xxwsh_order_lines_all xola        -- 受注明細アドオン
        WHERE  xola.order_header_id            = xoha.order_header_id
        AND    xola.shipping_inventory_item_id = ximv.inventory_item_id
        AND    NVL(xola.delete_flag,gv_flg_off) = gv_flg_off                  -- 未削除
        AND    ((iv_item_code IS NULL) OR (xola.shipping_item_code = iv_item_code)))
      AND    TO_CHAR(xoha.shipped_date,'YYYYMM') > gv_close_date
      AND    ota.org_id = gv_org_id
      AND    xoha.performance_management_dept = iv_dept_code
      AND    ((xicv.prod_class_code IS NOT NULL)
      AND     (xicv.prod_class_code = iv_prod_class))
      AND    ((iv_from_date IS NULL)
      OR      (NVL(xoha.arrival_date,xoha.schedule_arrival_date) >= iv_from_date))
      AND    ((iv_to_date IS NULL)
      OR      (NVL(xoha.arrival_date,xoha.schedule_arrival_date) <= iv_to_date))
      AND   ((iv_item_class IS NULL)
      OR     ((xicv.item_class_code IS NOT NULL)
      AND     (xicv.item_class_code = iv_item_class)))
      AND   ((iv_vendor_code IS NULL) OR (xoha.vendor_code = iv_vendor_code))
      AND   ((iv_request_no IS NULL)  OR (xoha.request_no  = iv_request_no))
      ;
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
    ln_cnt := 0;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.order_header_id := lr_mst_data_rec.order_header_id;
      mst_rec.spare2          := lr_mst_data_rec.spare2;
      mst_rec.arrival_date    := lr_mst_data_rec.arrival_date;
      mst_rec.item_class_code := lr_mst_data_rec.item_class_code;
      mst_rec.item_no         := lr_mst_data_rec.item_no;
      mst_rec.request_no      := lr_mst_data_rec.request_no;
      mst_rec.vendor_code     := lr_mst_data_rec.vendor_code;
--
      -- 着荷日がNULLなら着荷予定日を設定
      IF (mst_rec.arrival_date IS NULL) THEN
        mst_rec.arrival_date := lr_mst_data_rec.schedule_arrival_date;
      END IF;
--
      gt_master_tbl(ln_cnt)   := mst_rec;
--
      -- 受注明細アドオンのロック
      IF (mst_rec.order_header_id IS NOT NULL) THEN
--
        -- テーブルのロック
        tbl_lock(mst_rec,
                 lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                 lv_retcode,         -- リターン・コード             --# 固定 #
                 lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10026',
                                            'TABLE',
                                            lv_tbl_name);
      lv_errbuf := lv_errmsg;
      RAISE get_data_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN get_data_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
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
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_lines
   * Description      : 受注明細更新(O-6)
   ***********************************************************************************/
  PROCEDURE upd_lines(
    ir_mst_rec      IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lines'; -- プログラム名
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
    lv_msg_num         VARCHAR2(20);
    lv_date            VARCHAR2(10);
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
    -- 受注明細アドオン単価更新処理
    xxpo_common2_pkg.update_order_unit_price(
      in_order_header_id    => ir_mst_rec.order_header_id     -- 受注ヘッダアドオンID
     ,iv_list_id_vendor     => ir_mst_rec.spare2              -- 取引先別価格表ID
     ,iv_list_id_represent  => gv_xxpo_price_list_id          -- 代表価格表ID
     ,id_arrival_date       => ir_mst_rec.arrival_date        -- 適用日(入庫日)
     ,iv_return_flag        => 'N'                            -- 返品フラグ
     ,iv_item_class_code    => ir_mst_rec.item_class_code     -- 品目区分
     ,iv_item_no            => ir_mst_rec.item_no             -- OPM品目コード
     ,ov_retcode            => lv_retcode                     -- エラーコード
     ,ov_errmsg             => lv_errbuf                      -- エラーメッセージ
     ,ov_system_msg         => lv_errmsg                      -- システムメッセージ
    );
--
    -- 処理成功
    IF (lv_retcode = gv_status_normal) THEN
--
      -- 更新対象
      IF (lv_errbuf IS NULL) THEN
        lv_msg_num := 'APP-XXPO-30048';
        gn_keep_cnt := gn_keep_cnt + 1;
--
      -- 更新対象外
      ELSE
        lv_msg_num := 'APP-XXPO-30049';
        gn_other_cnt := gn_other_cnt + 1;
      END IF;
--
    -- 単価取得エラー
    ELSIF (lv_retcode = gv_status_warn) THEN
      lv_msg_num := 'APP-XXPO-30049';
      gn_other_cnt := gn_other_cnt + 1;
--
    -- 処理失敗
    ELSE
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    lv_date := TO_CHAR(ir_mst_rec.arrival_date,'YYYY/MM/DD');
--
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          lv_msg_num,
                                          gv_tkn_i_no,
                                          ir_mst_rec.request_no,
                                          gv_tkn_vendor_cd,
                                          ir_mst_rec.vendor_code,
                                          gv_tkn_date,
                                          lv_date,
                                          gv_tkn_item_no,
                                          ir_mst_rec.item_no);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END upd_lines;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : 処理結果情報出力(O-7)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
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
    -- 支給データ抽出件数
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30044',
                                          gv_tkn_cnt_all,
                                          gt_master_tbl.COUNT);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 単価更新対象外件数
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30045',
                                          gv_tkn_cnt_out,
                                          gn_other_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 単価更新対象件数
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30046',
                                          gv_tkn_cnt_in,
                                          gn_keep_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_dept_code   IN            VARCHAR2,     -- 1.担当部署コード
    iv_from_date   IN            VARCHAR2,     -- 2.入庫日(FROM)
    iv_to_date     IN            VARCHAR2,     -- 3.入庫日(TO)
    iv_prod_class  IN            VARCHAR2,     -- 4.商品区分
    iv_item_class  IN            VARCHAR2,     -- 5.品目区分
    iv_vendor_code IN            VARCHAR2,     -- 6.取引先コード
    iv_item_code   IN            VARCHAR2,     -- 7.品目コード
    iv_request_no  IN            VARCHAR2,     -- 8.依頼No
    ov_errbuf         OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lr_mst_rec         masters_rec;
    ld_from_date       DATE;
    ld_to_date         DATE;
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_keep_cnt   := 0;
    gn_other_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ================================
    -- O-1.前処理
    -- ================================
    init_proc(
      iv_dept_code,       -- 1.担当部署コード
      iv_from_date,       -- 2.入庫日(FROM)
      iv_to_date,         -- 3.入庫日(TO)
      iv_prod_class,      -- 4.商品区分
      iv_item_class,      -- 5.品目区分
      iv_vendor_code,     -- 6.取引先コード
      iv_item_code,       -- 7.品目コード
      iv_request_no,      -- 8.依頼No
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- O-2.パラメータチェック
    -- ================================
    parameter_check(
      iv_dept_code,       -- 1.担当部署コード
      iv_from_date,       -- 2.入庫日(FROM)
      iv_to_date,         -- 3.入庫日(TO)
      iv_prod_class,      -- 4.商品区分
      iv_item_class,      -- 5.品目区分
      iv_vendor_code,     -- 6.取引先コード
      iv_item_code,       -- 7.品目コード
      iv_request_no,      -- 8.依頼No
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- O-3.支給データ取得
    -- ================================
    get_data(
      iv_dept_code,       -- 1.担当部署コード
      gd_from_date,       -- 2.入庫日(FROM)
      gd_to_date,         -- 3.入庫日(TO)
      iv_prod_class,      -- 4.商品区分
      iv_item_class,      -- 5.品目区分
      iv_vendor_code,     -- 6.取引先コード
      iv_item_code,       -- 7.品目コード
      iv_request_no,      -- 8.依頼No
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
    END IF;
--
    -- 対象データあり
    IF (gt_master_tbl.COUNT > 0) THEN
--
      <<upd_loop>>
      FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
        lr_mst_rec := gt_master_tbl(i);
--
        -- ================================
        -- O-6.受注明細更新
        -- ================================
        upd_lines(
          lr_mst_rec,         -- 対象データ
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP upd_loop;
    END IF;
--
    -- ================================
    -- O-7.処理結果情報出力
    -- ================================
    disp_report(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
    errbuf            OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode           OUT NOCOPY VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_dept_code   IN            VARCHAR2,      -- 1.担当部署コード
    iv_from_date   IN            VARCHAR2,      -- 2.入庫日(FROM)
    iv_to_date     IN            VARCHAR2,      -- 3.入庫日(TO)
    iv_prod_class  IN            VARCHAR2,      -- 4.商品区分
    iv_item_class  IN            VARCHAR2,      -- 5.品目区分
    iv_vendor_code IN            VARCHAR2,      -- 6.取引先コード
    iv_item_code   IN            VARCHAR2,      -- 7.品目コード
    iv_request_no  IN            VARCHAR2)      -- 8.依頼No
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_dept_code,    -- 1.担当部署コード
      iv_from_date,    -- 2.入庫日(FROM)
      iv_to_date,      -- 3.入庫日(TO)
      iv_prod_class,   -- 4.商品区分
      iv_item_class,   -- 5.品目区分
      iv_vendor_code,  -- 6.取引先コード
      iv_item_code,    -- 7.品目コード
      iv_request_no,   -- 8.依頼No
      lv_errbuf,       -- エラー・メッセージ           --# 固定 #
      lv_retcode,      -- リターン・コード             --# 固定 #
      lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxpo440007c;
/
