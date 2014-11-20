CREATE OR REPLACE PACKAGE BODY xxinv990006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990006c(body)
 * Description      : 物流構成アドオンのアップロード
 * MD.050           : ファイルアップロード T_MD050_BPO_990
 * MD.070           : 物流構成アドオンのアップロード T_MD070_BPO_99G
 * Version          : 1.4
 *
 * Program List
 * ----------------------- ----------------------------------------------------------
 *  Name                    Description
 * ----------------------- ----------------------------------------------------------
 *  set_data_proc           登録データ設定
 *  init_proc               関連データ取得 (G-1)
 *  get_upload_data_proc    ファイルアップロードインタフェースデータ取得 (G-2)
 *  check_proc              妥当性チェック (G-3)
 *  insert_sr_lines_if_proc データ登録 (G-4)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/06    1.0   ORACLE 青木祐介   main 新規作成
 *  2008/04/18    1.1   Oracle 山根 一浩  変更要求No63対応
 *  2008/07/08    1.2   Oracle 山根 一浩  I_S_192対応
 *  2009/06/10    1.3   SCS 丸下          本番障害1204、1439対応
 *  2009/06/22    1.4   SCS 丸下          本番障害1204、1439追加対応
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
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
  no_data_if_expt           EXCEPTION;     -- 対象データなし
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxinv990006c'; -- パッケージ名
--
  gv_msg_kbn        CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- メッセージ番号
  gv_msg_ng_profile CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- プロファイル取得エラー
  gv_msg_ng_lock    CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ロックエラー
  gv_msg_ng_data    CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- 対象データなし
  gv_msg_ng_format  CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- フォーマットチェックエラーメッセージ
--
  gv_msg_file_name  CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- ファイル名
  gv_msg_up_date    CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- アップロード日時
  gv_msg_up_name    CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- ファイルアップロード名称
--
  -- トークン
  gv_tkn_ng_profile         CONSTANT VARCHAR2(10)   := 'NAME';
  gv_tkn_table              CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_tkn_item               CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_tkn_value              CONSTANT VARCHAR2(15)   := 'VALUE';
  -- プロファイル
  gv_parge_term_sr_if       CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_006';
  gv_parge_term_name        CONSTANT VARCHAR2(36)   := 'パージ対象期間:物流構成アドオン';
  -- クイックコード タイプ
  gv_lookup_type            CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_format_type            CONSTANT VARCHAR2(20)  := 'フォーマットパターン';
  -- 対象DB名
  gv_xxinv_mrp_file_ul_name CONSTANT VARCHAR2(100)
                                            := 'ファイルアップロードインタフェーステーブル';
--
  gv_file_id_name           CONSTANT VARCHAR2(24)   := 'FILE_ID';
  -- *** 物流構成アドオンインタフェース項目名 ***
  gv_item_code_n            CONSTANT VARCHAR2(24)   := '品目コード';
  gv_base_code_n            CONSTANT VARCHAR2(24)   := '拠点コード';
  gv_ship_to_code_n         CONSTANT VARCHAR2(24)   := '配送先コード';
  gv_start_date_active_n    CONSTANT VARCHAR2(24)   := '適用開始日';
  gv_end_date_active_n      CONSTANT VARCHAR2(24)   := '適用終了日';
  gv_delivery_whse_n        CONSTANT VARCHAR2(24)   := '出庫倉庫コード';
  gv_move_whse1_n           CONSTANT VARCHAR2(24)   := '移動元倉庫コード1';
  gv_move_whse2_n           CONSTANT VARCHAR2(24)   := '移動元倉庫コード2';
  gv_vender_site1_n         CONSTANT VARCHAR2(24)   := '仕入先サイトコード1';
  gv_vender_site2_n         CONSTANT VARCHAR2(24)   := '仕入先サイトコード2';
  gv_plan_item_flag_n       CONSTANT VARCHAR2(24)   := '計画商品フラグ';
-- 2009/06/10 ADD START
  gv_sourcing_rules_id_n    CONSTANT VARCHAR2(24)   := '削除キー';
  gv_sourcing_rules         CONSTANT VARCHAR2(24)   := '物流構成アドオンマスタ';
-- 2009/06/10 ADD END
  -- *** 物流構成アドオンインタフェース桁数 ***
  gn_item_code_l            CONSTANT NUMBER         := 7; -- 品目コード
  gn_base_code_l            CONSTANT NUMBER         := 4; -- 拠点コード
  gn_ship_to_code_l         CONSTANT NUMBER         := 9; -- 配送先コード
  gn_delivery_whse_l        CONSTANT NUMBER         := 4; -- 出庫倉庫コード
  gn_move_whse1_l           CONSTANT NUMBER         := 4; -- 移動元倉庫コード1
  gn_move_whse2_l           CONSTANT NUMBER         := 4; -- 移動元倉庫コード2
  gn_vender_site1_l         CONSTANT NUMBER         := 4; -- 仕入先サイトコード1
  gn_vender_site2_l         CONSTANT NUMBER         := 4; -- 仕入先サイトコード2
  gn_plan_item_flag_l       CONSTANT NUMBER         := 1; -- 計画商品フラグ
  gn_plan_item_flag_d       CONSTANT NUMBER         := 0; -- 計画商品フラグ(小数点以下)
--
  gv_comma                  CONSTANT VARCHAR2(1)    := ',';      -- カンマ
  gv_space                  CONSTANT VARCHAR2(1)    := ' ';      -- スペース
  gv_err_msg_space          CONSTANT VARCHAR2(6)    := '      '; -- スペース（6byte）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE file_data_rec IS RECORD(
    item_code               VARCHAR2(32767), -- 品目コード
    base_code               VARCHAR2(32767), -- 拠点コード
    ship_to_code            VARCHAR2(32767), -- 配送先コード
    start_date_active       VARCHAR2(32767), -- 適用開始日
    end_date_active         VARCHAR2(32767), -- 適用終了日
    delivery_whse_code      VARCHAR2(32767), -- 出荷保管倉庫コード
    move_from_whse_code1    VARCHAR2(32767), -- 移動元保管倉庫コード1
    move_from_whse_code2    VARCHAR2(32767), -- 移動元保管倉庫コード2
    vendor_site_code1       VARCHAR2(32767), -- 仕入先サイトコード1
    vendor_site_code2       VARCHAR2(32767), -- 仕入先サイトコード2
    plan_item_flag          VARCHAR2(32767), -- 計画商品フラグ
-- 2009/06/10 ADD START
    sourcing_rules_id       VARCHAR2(32767), -- 削除キー
-- 2009/06/10 ADD END
    line                    VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message             VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
  -- CSVを格納する結合配列
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- 登録用PL/SQL表型
  TYPE item_code_type            IS TABLE OF
    xxcmn_sr_lines_if.item_code%TYPE            INDEX BY BINARY_INTEGER;  -- 品目コード
  TYPE base_code_type           IS TABLE OF
    xxcmn_sr_lines_if.base_code%TYPE            INDEX BY BINARY_INTEGER;  -- 拠点コード
  TYPE ship_to_code_type         IS TABLE OF
    xxcmn_sr_lines_if.ship_to_code%TYPE         INDEX BY BINARY_INTEGER;  -- 配送先コード
  TYPE start_date_active_type    IS TABLE OF
    xxcmn_sr_lines_if.start_date_active%TYPE    INDEX BY BINARY_INTEGER;  -- 適用開始日
  TYPE end_date_active_type      IS TABLE OF
    xxcmn_sr_lines_if.end_date_active%TYPE      INDEX BY BINARY_INTEGER;  -- 適用終了日
  TYPE delivery_whse_code_type   IS TABLE OF
    xxcmn_sr_lines_if.delivery_whse_code%TYPE   INDEX BY BINARY_INTEGER;  -- 出荷保管倉庫
  TYPE move_from_whse_code1_type IS TABLE OF
    xxcmn_sr_lines_if.move_from_whse_code1%TYPE INDEX BY BINARY_INTEGER;  -- 移動元保管倉庫コード1
  TYPE move_from_whse_code2_type IS TABLE OF
    xxcmn_sr_lines_if.move_from_whse_code2%TYPE INDEX BY BINARY_INTEGER;  -- 移動元保管倉庫コード2
  TYPE vendor_site_code1_type    IS TABLE OF
    xxcmn_sr_lines_if.vendor_site_code1%TYPE    INDEX BY BINARY_INTEGER;  -- 仕入先サイトコード1
  TYPE vendor_site_code2_type    IS TABLE OF
    xxcmn_sr_lines_if.vendor_site_code2%TYPE    INDEX BY BINARY_INTEGER;  -- 仕入先サイトコード2
  TYPE plan_item_flag_type       IS TABLE OF
    xxcmn_sr_lines_if.plan_item_flag%TYPE       INDEX BY BINARY_INTEGER;  -- 計画商品フラグ
-- 2009/06/10 ADD START
  TYPE sourcing_rules_id_type       IS TABLE OF
    xxcmn_sr_lines_if.sourcing_rules_id%TYPE    INDEX BY BINARY_INTEGER;  -- 削除キー
-- 2009/06/10 ADD END
--
  gt_item_code_tab            item_code_type;             -- 品目コード
  gt_base_code_tab            base_code_type;             -- 拠点コード
  gt_ship_to_code_tab         ship_to_code_type;          -- 配送先コード
  gt_start_date_active_tab    start_date_active_type;     -- 適用開始日
  gt_end_date_active_tab      end_date_active_type;       -- 適用終了日
  gt_delivery_whse_code_tab   delivery_whse_code_type;    -- 出荷保管倉庫
  gt_move_from_whse_code1_tab move_from_whse_code1_type;  -- 移動元保管倉庫
  gt_move_from_whse_code2_tab move_from_whse_code2_type;  -- 移動元保管倉庫
  gt_vendor_site_code1_tab    vendor_site_code1_type;     -- 仕入先サイトコード1
  gt_vendor_site_code2_tab    vendor_site_code2_type;     -- 仕入先サイトコード2
  gt_plan_item_flag_tab       plan_item_flag_type;        -- 計画商品フラグ
-- 2009/06/10 ADD START
  gt_sourcing_rules_id_tab    sourcing_rules_id_type;     -- 削除キー
-- 2009/06/10 ADD END
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_sysdate                DATE;          -- システム日付
  gn_user_id                NUMBER;        -- ユーザID
  gn_login_id               NUMBER;        -- 最終更新ログイン
  gn_conc_request_id        NUMBER;        -- 要求ID
  gn_prog_appl_id           NUMBER;        -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id        NUMBER;        -- コンカレント・プログラムID
--
  gn_xxinv_parge_term       NUMBER;        -- パージ対象期間
  gv_file_name              VARCHAR2(256); -- ファイル名
  gn_created_by             NUMBER(15);    -- 作成者
  gd_creation_date          DATE;          -- 作成日
  gv_file_up_name           VARCHAR2(30);  -- ファイルアップロード名
  gv_check_proc_retcode     VARCHAR2(1);   -- 妥当性チェックステータス
--
  /**********************************************************************************
   * Procedure Name   : insert_sr_lines_if_proc
   * Description      : データ登録 (G-4)
   ***********************************************************************************/
  PROCEDURE insert_sr_lines_if_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sr_lines_if_proc'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- *** 物流構成アドオンインタフェース登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_item_code_tab.COUNT
      INSERT INTO xxcmn_sr_lines_if
      ( item_code                               -- 品目コード
      , base_code                               -- 拠点コード
      , ship_to_code                            -- 配送先コード
      , start_date_active                       -- 適用開始日
      , end_date_active                         -- 適用終了日
      , delivery_whse_code                      -- 出荷保管倉庫コード
      , move_from_whse_code1                    -- 移動元保管倉庫コード1
      , move_from_whse_code2                    -- 移動元保管倉庫コード2
      , vendor_site_code1                       -- 仕入先サイトコード1
      , vendor_site_code2                       -- 仕入先サイトコード2
      , plan_item_flag                          -- 計画商品フラグ
-- 2009/06/10 ADD START
      , sourcing_rules_id                       -- 削除キー
-- 2009/06/10 ADD END
      , created_by                              -- 作成者
      , creation_date                           -- 作成日
      , last_updated_by                         -- 最終更新者
      , last_update_date                        -- 最終更新日
      , last_update_login                       -- 最終更新ログイン
      , request_id                              -- 要求ID
      , program_application_id                  -- コンカレント・プログラム・アプリケーションID
      , program_id                              -- コンカレント・プログラムID
      , program_update_date                     -- プログラム更新日
      ) VALUES (
          gt_item_code_tab(item_cnt)            -- 品目コード
        , gt_base_code_tab(item_cnt)            -- 拠点コード
        , gt_ship_to_code_tab(item_cnt)         -- 配送先コード
        , gt_start_date_active_tab(item_cnt)    -- 適用開始日
        , gt_end_date_active_tab(item_cnt)      -- 適用終了日
        , gt_delivery_whse_code_tab(item_cnt)   -- 出荷保管倉庫コード
        , gt_move_from_whse_code1_tab(item_cnt) -- 移動元保管倉庫コード1
        , gt_move_from_whse_code2_tab(item_cnt) -- 移動元保管倉庫コード2
        , gt_vendor_site_code1_tab(item_cnt)    -- 仕入先サイトコード1
        , gt_vendor_site_code2_tab(item_cnt)    -- 仕入先サイトコード2
        , gt_plan_item_flag_tab(item_cnt)       -- 計画商品フラグ
-- 2009/06/10 ADD START
        , gt_sourcing_rules_id_tab(item_cnt)    -- 削除キー
-- 2009/06/10 ADD END
        , gn_user_id                            -- 作成者
        , gd_sysdate                            -- 作成日
        , gn_user_id                            -- 最終更新者
        , gd_sysdate                            -- 最終更新日
        , gn_login_id                           -- 最終更新ログイン
        , gn_conc_request_id                    -- 要求ID
        , gn_prog_appl_id                       -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
        , gn_conc_program_id                    -- コンカレント・プログラムID
        , gd_sysdate                            -- プログラムによる更新日
      );
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_sr_lines_if_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : 登録データ設定
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- *** 登録用PL/SQL表編集（2行目から）
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      gt_item_code_tab(ln_index)
        := fdata_tbl(ln_index).item_code;                                -- 品目コード
      gt_base_code_tab(ln_index)
        := fdata_tbl(ln_index).base_code;                                -- 拠点コード
      gt_ship_to_code_tab(ln_index)
        := fdata_tbl(ln_index).ship_to_code;                             -- 配送先コード
      -- 適用開始日
      gt_start_date_active_tab(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).start_date_active, 'RR/MM/DD');
      -- 適用終了日
      gt_end_date_active_tab(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).end_date_active, 'RR/MM/DD');
      gt_delivery_whse_code_tab(ln_index)
        := fdata_tbl(ln_index).delivery_whse_code;                       -- 出荷保管倉庫コード
      gt_move_from_whse_code1_tab(ln_index)
        := fdata_tbl(ln_index).move_from_whse_code1;                     -- 移動元保管倉庫コード1
      gt_move_from_whse_code2_tab(ln_index)
        := fdata_tbl(ln_index).move_from_whse_code2;                     -- 移動元保管倉庫コード2
      gt_vendor_site_code1_tab(ln_index)
        := fdata_tbl(ln_index).vendor_site_code1;                        -- 仕入先サイトコード1
      gt_vendor_site_code2_tab(ln_index)
        := fdata_tbl(ln_index).vendor_site_code2;                        -- 仕入先サイトコード2
      gt_plan_item_flag_tab(ln_index)
        := TO_NUMBER(fdata_tbl(ln_index).plan_item_flag);                -- 計画商品フラグ
-- 2009/06/10 ADD START
      gt_sourcing_rules_id_tab(ln_index)
        := fdata_tbl(ln_index).sourcing_rules_id;                        -- 削除キー
-- 2009/06/10 ADD END
--
    END LOOP fdata_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : 妥当性チェック (G-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- プログラム名
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
--
    lv_line_feed    VARCHAR2(1); -- 改行コード
--
    -- 総項目数
-- 2009/06/10 MOD START
--    cn_col          CONSTANT NUMBER := 11;
    cn_col          CONSTANT NUMBER := 12;
-- 2009/06/10 MOD END
--
    -- *** ローカル変数 ***
    lv_log_data     VARCHAR2(32767);  -- LOGデータ部退避用
-- 2009/06/10 ADD START
    ln_xsr_cnt      NUMBER;  -- 物流構成存在チェック用
-- 2009/06/10 ADD END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 初期化
    gv_check_proc_retcode := gv_status_normal; -- 妥当性チェックステータス
    lv_line_feed := CHR(10);                   -- 改行コード
--
    -- **************************************************
    -- *** 取得したレコード毎に項目チェックを行う。
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- **************************************************
      -- *** 項目数チェック
      -- **************************************************
      -- （行全体の長さ－行からカンマを抜いた長さ＝カンマの数） <> （正式な項目数－１＝正式なカンマの数）
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line),0) - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_comma,NULL)),0))
          <> (cn_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_err_msg_space
                                           || gv_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                                       gv_msg_ng_format)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** 項目チェック
        -- **************************************************
        -- ==============================
        --  品目コード
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_item_code_n,
                                            fdata_tbl(ln_index).item_code,
                                            gn_item_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  拠点コード
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_base_code_n,
                                            fdata_tbl(ln_index).base_code,
                                            gn_base_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  配送先コード
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_ship_to_code_n,
                                            fdata_tbl(ln_index).ship_to_code,
                                            gn_ship_to_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  適用開始日
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_start_date_active_n,
                                            fdata_tbl(ln_index).start_date_active,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  適用終了日
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_end_date_active_n,
                                            fdata_tbl(ln_index).end_date_active,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  出庫倉庫コード
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_delivery_whse_n,
                                            fdata_tbl(ln_index).delivery_whse_code,
                                            gn_delivery_whse_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  移動元倉庫コード1
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_move_whse1_n,
                                            fdata_tbl(ln_index).move_from_whse_code1,
                                            gn_move_whse1_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  移動元倉庫コード2
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_move_whse2_n,
                                            fdata_tbl(ln_index).move_from_whse_code2,
                                            gn_move_whse2_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  仕入先サイトコード1
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_vender_site1_n,
                                            fdata_tbl(ln_index).vendor_site_code1,
                                            gn_vender_site1_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  仕入先サイトコード2
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_vender_site2_n,
                                            fdata_tbl(ln_index).vendor_site_code2,
                                            gn_vender_site2_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  計画商品フラグ
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_plan_item_flag_n,
                                            fdata_tbl(ln_index).plan_item_flag,
                                            gn_plan_item_flag_l,
                                            gn_plan_item_flag_d,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
-- 2009/06/10 ADD START
        -- ==============================
        --  削除キー
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_sourcing_rules_id_n,
                                            fdata_tbl(ln_index).sourcing_rules_id,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        --物流構成マスタ存在チェック
        IF (lv_retcode = gv_status_normal AND 
            fdata_tbl(ln_index).sourcing_rules_id IS NOT NULL) THEN
          BEGIN
            SELECT COUNT(1)
            INTO   ln_xsr_cnt
            FROM   xxcmn_sourcing_rules xsr
            WHERE  xsr.sourcing_rules_id = fdata_tbl(ln_index).sourcing_rules_id;
          END;
--
          -- 該当データなしは項目チェックエラー
          IF (ln_xsr_cnt = 0 ) THEN
            lv_retcode := gv_status_warn;
            lv_errmsg  := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10001',
              'TABLE',gv_sourcing_rules,
              'KEY'  ,fdata_tbl(ln_index).sourcing_rules_id);
          END IF;
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || gv_err_msg_space
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
-- 2009/06/10 ADD END
--
      END IF;
--
      -- **************************************************
      -- *** エラー制御
      -- **************************************************
      -- チェックエラーありの場合
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** データ部出力準備（行数 + SPACE + 行全体のデータ）
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- エラーメッセージ部出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- 妥当性チェックステータス
        gv_check_proc_retcode := gv_status_error;
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
--
      -- チェックエラーなしの場合
      ELSE
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : ファイルアップロードインタフェースデータ取得 (G-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id    IN  NUMBER,           --   ファイルＩＤ
    ov_errbuf     OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data_proc'; -- プログラム名
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
    lv_line       VARCHAR2(32767);    -- 改行コード迄の情報
    ln_col        NUMBER;             -- カラム
    lb_col        BOOLEAN  := TRUE;   -- カラム作成継続
    ln_length     NUMBER;             -- 長さ保管用
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- 行テーブル格納領域
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ファイルアップロードインタフェースデータ取得
    -- 行ロック処理
    SELECT xmf.file_name,    -- ファイル名
           xmf.created_by,   -- 作成者
           xmf.creation_date -- 作成日
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- **************************************************
    -- *** ファイルアップロードインターフェースデータ取得
    -- **************************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,         -- ファイルＩＤ
      lt_file_line_data,  -- 変換後VARCHAR2データ
      lv_errbuf,          -- エラー・メッセージ             --# 固定 #
      lv_retcode,         -- リターン・コード               --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ   --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみ、又は、2行目が改行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_data,
                                            gv_tkn_item,
                                            gv_file_id_name,
                                            gv_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    -- **************************************************
    -- *** 取得したデータを行毎のループ（2行目から）
    -- **************************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 行毎に作業領域に格納
      lv_line := lt_file_line_data(ln_index);
--
      -- 1行の内容を line に格納
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- カラム番号初期化
      ln_col := 0;    --カラム
      lb_col := TRUE; --カラム作成継続
--
      -- **************************************************
      -- *** 1行をカンマ毎に分解
      -- **************************************************
      <<comma_loop>>
      LOOP
        --lv_lineの長さが0なら終了
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- カラム番号をカウント
        ln_col := ln_col + 1;
--
        -- カンマの位置を取得
        ln_length := INSTR(lv_line, gv_comma);
        -- カンマがない
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- カンマがある
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
/* 2009/06/22 DEL START
        -- CSV形式を項目ごとにレコードに格納
        IF (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).item_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).base_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).ship_to_code         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).start_date_active    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).end_date_active      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).delivery_whse_code   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code1 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code2 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code1    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code2    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).plan_item_flag       := SUBSTR(lv_line, 1, ln_length);
-- 2009/06/10 ADD START
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).sourcing_rules_id    := SUBSTR(lv_line, 1, ln_length);
-- 2009/06/10 ADD END
        END IF;
  2009/06/22 DEL END */
-- 2009/06/22 ADD START
        -- CSV形式を項目ごとにレコードに格納
        -- 項目位置変更
        IF (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).item_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).base_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).ship_to_code         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).start_date_active    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).end_date_active      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).delivery_whse_code   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code1 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code2 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code1    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code2    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).plan_item_flag       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).sourcing_rules_id    := SUBSTR(lv_line, 1, ln_length);
        END IF;
-- 2009/06/22 ADD END
--
        -- strは今回取得した行を除く（カンマはのぞくため、ln_length + 2）
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN check_lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_lock,
                                            gv_tkn_table,
                                            gv_xxinv_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_data,
                                            gv_tkn_item,
                                            gv_file_id_name,
                                            gv_tkn_value,
                                            in_file_id);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_data_proc;
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 関連データ取得 (G-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,          -- フォーマットパターン
    ov_errbuf       OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_parge_term       VARCHAR2(100);    -- プロファイル格納場所
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- システム日付取得
    gd_sysdate := SYSDATE;
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- コンカレント・プログラムID
--
    -- プロファイル「パージ対象期間」取得
    lv_parge_term := FND_PROFILE.VALUE(gv_parge_term_sr_if);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_profile,
                                            gv_tkn_ng_profile,
                                            gv_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値チェック
    BEGIN
      -- TO_NUMBERできなければエラー
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_profile,
                                            gv_tkn_ng_profile,
                                            gv_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- ファイルアップロード名称取得
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- クイックコードVIEW
      WHERE   xlvv.lookup_type = gv_lookup_type         -- タイプ
      AND     xlvv.lookup_code = in_file_format         -- コード
      AND     ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                              gv_msg_ng_data,
                                              gv_tkn_item,
                                              gv_format_type,
                                              gv_tkn_value,
                                              in_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,          --   ファイルＩＤ
    in_file_format IN  VARCHAR2,        --   フォーマットパターン
    ov_errbuf      OUT NOCOPY VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_out_rep VARCHAR2(32767);  -- レポート出力
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- 初期化
    gv_check_proc_retcode := gv_status_normal; -- 妥当性チェックステータス
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 関連データ取得 (G-1)
    -- ===============================
    init_proc(
      in_file_format,    -- フォーマットパターン
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードインタフェースデータ取得 (G-2)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- ファイルＩＤ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
--#################################  アップロード固定メッセージ START  ###################################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                              gv_msg_file_name,
                                              gv_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                              gv_msg_up_date,
                                              gv_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                              gv_msg_up_name,
                                              gv_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  アップロード固定メッセージ END   ###################################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 2008/07/08 Add ↓
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    -- 2008/07/08 Add ↑
    END IF;
--
    -- ===============================
    -- 妥当性チェック (G-3)
    -- ===============================
    check_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 妥当性チェックでエラーがなかった場合
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
--
      -- ===============================
      -- 登録データセット
      -- ===============================
      set_data_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- データ登録 (G-4)
      -- ===============================
      insert_sr_lines_if_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- ファイルアップロードインタフェースデータ削除 (G-5)
    -- ===============================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- フォーマットパターン
      gd_sysdate,                     -- 対象日付
      gn_xxinv_parge_term,            -- パージ対象期間
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      -- main側でROLLBACK処理を行う為、normalを代入
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- チェック処理エラー
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- 固定のエラーメッセージの出力をしないようにする
      lv_errmsg := gv_space;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf         OUT NOCOPY VARCHAR2, --   エラー・メッセージ  --# 固定 #
    retcode        OUT NOCOPY VARCHAR2, --   リターン・コード    --# 固定 #
    in_file_id     IN  VARCHAR2,        --   ファイルＩＤ 2008/04/18 変更
    in_file_format IN  VARCHAR2         --   フォーマットパターン
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      TO_NUMBER(in_file_id),     -- ファイルＩＤ 2008/04/18 変更
      in_file_format, -- フォーマットパターン
      lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      lv_retcode,     -- リターン・コード             --# 固定 #
      lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
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
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
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
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxinv990006c;
/
