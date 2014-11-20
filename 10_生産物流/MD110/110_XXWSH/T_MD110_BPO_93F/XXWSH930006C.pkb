CREATE OR REPLACE PACKAGE BODY xxwsh930006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930006C(body)
 * Description      : インタフェースデータ削除処理
 * MD.050           : 生産物流共通                  T_MD050_BPO_935
 * MD.070           : インタフェースデータ削除処理  T_MD070_BPO_93F
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              初期処理                     (A-1)
 *  get_del_data           パージ対象抽出処理           (A-2)
 *  del_proc               パージ処理                   (A-3)
 *  term_proc              終了処理                     (A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/22    1.0   Oracle 山根 一浩 初回作成
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
  lock_expt                 EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxwsh930006c';  -- パッケージ名
  gv_app_name       CONSTANT VARCHAR2(5)   := 'XXWSH';         -- アプリケーション短縮名
  gv_com_name       CONSTANT VARCHAR2(5)   := 'XXCMN';         -- アプリケーション短縮名
--
  gv_lookup_type    CONSTANT VARCHAR2(20) := 'XXCMN_D17';
--
  gv_tkn_table      CONSTANT VARCHAR2(20) := 'TABLE';
  gv_tkn_item       CONSTANT VARCHAR2(20) := 'ITEM';
  gv_tkn_key        CONSTANT VARCHAR2(20) := 'KEY';
  gv_tkn_input      CONSTANT VARCHAR2(20) := 'INPUT';
--
  gv_tkn_number_93f_01        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10089'; -- 必須エラー
  gv_tkn_number_93f_02        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10003'; -- テーブル取得エラー
  gv_tkn_number_93f_03        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019'; -- ロックエラー
--
  gv_tkn_name_location_code   CONSTANT VARCHAR2(50) := '報告部署';
  gv_tkn_name_eos_data_type   CONSTANT VARCHAR2(50) := 'EOSデータ種別';
  gv_tkn_name_order_ref       CONSTANT VARCHAR2(50) := '依頼No/移動No';
  gv_tkn_name_delivery_no     CONSTANT VARCHAR2(50) := '配送No';
--
  gv_tkn_tbl_location_code    CONSTANT VARCHAR2(50) := '事業所';
  gv_tkn_tbl_eos_data_type    CONSTANT VARCHAR2(50) := 'EOSデータ種別';
--
  gv_tkn_itm_location_code    CONSTANT VARCHAR2(50) := '事業所コード';
  gv_tkn_itm_eos_data_type    CONSTANT VARCHAR2(50) := 'コード';
--
  gv_tbl_name_head            CONSTANT VARCHAR2(100) := '出荷依頼インタフェースヘッダ(アドオン)';
  gv_tbl_name_line            CONSTANT VARCHAR2(100) := '出荷依頼インタフェース明細(アドオン)';
--
  gv_title_head               CONSTANT VARCHAR2(50) := 'ヘッダ削除件数';
  gv_title_line               CONSTANT VARCHAR2(50) := '明細削除件数';
  gv_title_count              CONSTANT VARCHAR2(50) := '件';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE header_id_ttype        IS TABLE OF
    xxwsh_shipping_headers_if.header_id        %TYPE INDEX BY BINARY_INTEGER;  -- ヘッダID
  TYPE order_source_ref_ttype IS TABLE OF
    xxwsh_shipping_headers_if.order_source_ref %TYPE INDEX BY BINARY_INTEGER;  -- 受注ソース参照
  TYPE delivery_no_ttype      IS TABLE OF
    xxwsh_shipping_headers_if.delivery_no      %TYPE INDEX BY BINARY_INTEGER;  -- 配送No
  TYPE line_id_ttype          IS TABLE OF
    xxwsh_shipping_lines_if.line_id            %TYPE INDEX BY BINARY_INTEGER;  -- 明細ID
--
  gt_header_id_del_tab      header_id_ttype;            -- ヘッダID
  gt_order_ref_del_tab      order_source_ref_ttype;     -- 受注ソース参照
  gt_delivery_no_del_tab    delivery_no_ttype;          -- 配送No
  gt_line_id_del_tab        line_id_ttype;              -- 明細ID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理                 (A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    iv_location_code IN            VARCHAR2,   -- 1.報告部署                   --# 必須 #
    iv_eos_data_type IN            VARCHAR2,   -- 2.EOSデータ種別              --# 必須 #
    iv_order_ref     IN            VARCHAR2,   -- 3.依頼No/移動No              --# 任意 #
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    lv_description       xxcmn_locations_v.description%TYPE;   -- 報告部署名
    lv_meaning           xxcmn_lookup_values_v.meaning%TYPE;   -- EOSデータ種別名
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 報告部署がNULL
    IF (iv_location_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_01,
                                            gv_tkn_input,
                                            gv_tkn_name_location_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- EOSデータ種別がNULL
    IF (iv_eos_data_type IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_01,
                                            gv_tkn_input,
                                            gv_tkn_name_eos_data_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 報告部署名取得
    BEGIN
      SELECT xlv.description
      INTO   lv_description
      FROM   xxcmn_locations_v xlv
      WHERE  xlv.location_code = iv_location_code
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_description := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 報告部署名が存在しない
    IF (lv_description IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_02,
                                            gv_tkn_table,
                                            gv_tkn_tbl_location_code,
                                            gv_tkn_item,
                                            gv_tkn_itm_location_code,
                                            gv_tkn_key,
                                            iv_location_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- EOSデータ種別名取得
    BEGIN
      SELECT xlvv.meaning
      INTO   lv_meaning
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = gv_lookup_type
      AND    xlvv.lookup_code = iv_eos_data_type
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_meaning := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- EOSデータ種別名が存在しない
    IF (lv_meaning IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_02,
                                            gv_tkn_table,
                                            gv_tkn_tbl_eos_data_type,
                                            gv_tkn_item,
                                            gv_tkn_itm_eos_data_type,
                                            gv_tkn_key,
                                            iv_eos_data_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 入力パラメータ出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_location_code||gv_msg_part||iv_location_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_eos_data_type||gv_msg_part||iv_eos_data_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_order_ref    ||gv_msg_part||iv_order_ref);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_del_data
   * Description      : パージ対象抽出処理       (A-2)
   ***********************************************************************************/
  PROCEDURE get_del_data(
    iv_location_code IN            VARCHAR2,   -- 1.報告部署                   --# 必須 #
    iv_eos_data_type IN            VARCHAR2,   -- 2.EOSデータ種別              --# 必須 #
    iv_order_ref     IN            VARCHAR2,   -- 3.依頼No/移動No              --# 任意 #
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_del_data'; -- プログラム名
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
    lv_tbl_name        VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 出荷依頼インタフェースヘッダ(アドオン)対象取得
    BEGIN
      SELECT del.header_id                        -- ヘッダID
            ,del.order_source_ref                 -- 受注ソース参照
            ,del.delivery_no                      -- 配送No
      BULK COLLECT INTO gt_header_id_del_tab
                       ,gt_order_ref_del_tab
                       ,gt_delivery_no_del_tab
      FROM   xxwsh_shipping_headers_if base    -- 基準データ
            ,xxwsh_shipping_headers_if del     -- 削除対象
      WHERE  base.report_post_code = del.report_post_code                    -- 報告部署
      AND    base.eos_data_type    = del.eos_data_type                       -- EOSデータ種別
      AND    base.delivery_no      = del.delivery_no                         -- 配送No
      AND    base.report_post_code = iv_location_code                        -- 1.報告部署
      AND    base.eos_data_type    = iv_eos_data_type                        -- 2.EOSデータ種別
      AND    base.order_source_ref = NVL(iv_order_ref,base.order_source_ref) -- 3.依頼No/移動No
      FOR UPDATE OF del.header_id NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_93f_03,
                                              gv_tkn_table,
                                              gv_tbl_name_head);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 出荷依頼インタフェース明細(アドオン)対象取得
    BEGIN
      SELECT line.line_id                         -- 明細ID
      BULK COLLECT INTO gt_line_id_del_tab
      FROM   xxwsh_shipping_headers_if base    -- 基準データ
            ,xxwsh_shipping_headers_if del     -- 削除対象
            ,xxwsh_shipping_lines_if   line
      WHERE  base.report_post_code = del.report_post_code                    -- 報告部署
      AND    base.eos_data_type    = del.eos_data_type                       -- EOSデータ種別
      AND    base.delivery_no      = del.delivery_no                         -- 配送No
      AND    line.header_id        = del.header_id                           -- ヘッダID
      AND    base.report_post_code = iv_location_code                        -- 1.報告部署
      AND    base.eos_data_type    = iv_eos_data_type                        -- 2.EOSデータ種別
      AND    base.order_source_ref = NVL(iv_order_ref,base.order_source_ref) -- 3.依頼No/移動No
      FOR UPDATE OF line.line_id NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_93f_03,
                                              gv_tkn_table,
                                              gv_tbl_name_line);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END get_del_data;
--
  /**********************************************************************************
   * Procedure Name   : del_proc
   * Description      : パージ処理               (A-3)
   ***********************************************************************************/
  PROCEDURE del_proc(
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_proc'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 出荷依頼インタフェース明細(アドオン)削除
    FORALL item_cnt IN 1 .. gt_line_id_del_tab.COUNT
      DELETE FROM xxwsh_shipping_lines_if xslif
      WHERE xslif.line_id = gt_line_id_del_tab(item_cnt);
--
    -- 出荷依頼インタフェースヘッダ(アドオン)削除
    FORALL item_cnt IN 1 .. gt_header_id_del_tab.COUNT
      DELETE FROM xxwsh_shipping_headers_if xshif
      WHERE xshif.header_id = gt_header_id_del_tab(item_cnt);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END del_proc;
--
  /**********************************************************************************
   * Procedure Name   : term_proc
   * Description      : 終了処理                 (A-4)
   ***********************************************************************************/
  PROCEDURE term_proc(
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'term_proc'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_title_head||gv_msg_part||
                                      gt_header_id_del_tab.COUNT||gv_title_count);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_title_line||gv_msg_part||
                                      gt_line_id_del_tab.COUNT  ||gv_title_count);
--
    <<log_disp_loop>>
    FOR i IN 1 .. gt_header_id_del_tab.COUNT LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_delivery_no||gv_msg_part||
                                        gt_order_ref_del_tab(i));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_order_ref  ||gv_msg_part||
                                        gt_delivery_no_del_tab(i));
    END LOOP log_disp_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END term_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_location_code IN            VARCHAR2,   -- 1.報告部署                     --# 必須 #
    iv_eos_data_type IN            VARCHAR2,   -- 2.EOSデータ種別                --# 必須 #
    iv_order_ref     IN            VARCHAR2,   -- 3.依頼No/移動No                --# 任意 #
    ov_errbuf           OUT NOCOPY VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
--
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    --*********************************************
    --***      初期処理(A-1)                    ***
    --*********************************************
    init_proc(
      iv_location_code,  -- 1.報告部署
      iv_eos_data_type,  -- 2.EOSデータ種別
      iv_order_ref,      -- 3.依頼No/移動No
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      パージ対象抽出処理(A-2)          ***
    --*********************************************
    get_del_data(
      iv_location_code,  -- 1.報告部署
      iv_eos_data_type,  -- 2.EOSデータ種別
      iv_order_ref,      -- 3.依頼No/移動No
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      パージ処理(A-3)                  ***
    --*********************************************
    del_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      終了処理(A-4)                    ***
    --*********************************************
    term_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
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
    errbuf              OUT NOCOPY VARCHAR2,        --   エラーメッセージ #固定#
    retcode             OUT NOCOPY VARCHAR2,        --   エラーコード     #固定#
    iv_location_code IN            VARCHAR2,        -- 1.報告部署         #必須#
    iv_eos_data_type IN            VARCHAR2,        -- 2.EOSデータ種別    #必須#
    iv_order_ref     IN            VARCHAR2)        -- 3.依頼No/移動No    #任意#
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
    --区切り文字取得
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_location_code, -- 1.報告部署
      iv_eos_data_type, -- 2.EOSデータ種別
      iv_order_ref,     -- 3.依頼No/移動No
      lv_errbuf,        -- エラー・メッセージ           --# 固定 #
      lv_retcode,       -- リターン・コード             --# 固定 #
      lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxwsh930006c;
/
