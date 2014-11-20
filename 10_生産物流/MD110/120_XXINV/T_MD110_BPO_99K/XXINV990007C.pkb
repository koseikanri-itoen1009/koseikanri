CREATE OR REPLACE PACKAGE BODY xxinv990007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990007c(body)
 * Description      : 運賃情報取込処理のアップロード
 * MD.050           : ファイルアップロード            T_MD050_BPO_990
 * MD.070           : 運賃情報取込処理のアップロード  T_MD070_BPO_99K
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  set_data_proc          登録データの設定
 *  parameter_check        パラメータチェック                              (K-1)
 *  relat_data_get         関連データ取得                                  (K-2)
 *  get_upload_data_proc   ファイルアップロードIFデータ取得                (K-3)
 *  proper_check           妥当性チェック                                  (K-4)
 *  insert_data            データ登録                                      (K-5)
 *  delete_tbl             ファイルアップロードIFテーブル削除              (K-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/10    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/25    1.1   Oracle 山根 一浩 変更要求No68対応
 *  2008/04/25    1.1   Oracle 山根 一浩 変更要求No70対応
 *  2008/04/28    1.2   Y.Kawano         内部変更要求No74対応
 *  2008/05/28    1.3   Oracle 山根 一浩 変更要求No124対応
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
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxinv990007c';  -- パッケージ名
  gv_c_msg_kbn     CONSTANT VARCHAR2(5)   := 'XXINV';         -- アプリケーション短縮名
--
  -- フォーマットパターン識別コード
  gv_format_code_01      CONSTANT VARCHAR2(2) := '13';         -- 運賃
  gv_format_code_02      CONSTANT VARCHAR2(2) := '14';         -- 支払運賃
  gv_format_code_03      CONSTANT VARCHAR2(2) := '15';         -- 請求運賃
  gv_format_pat_01       CONSTANT VARCHAR2(1) := '1';          -- 外部用
  gv_format_pat_02       CONSTANT VARCHAR2(1) := '2';          -- 伊藤園産業用
--
  -- メッセージ番号
  gv_c_msg_99k_008       CONSTANT VARCHAR2(15) := 'APP-XXINV-10008'; -- データ取得エラー
  gv_c_msg_99k_016       CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- パラメータエラー
  gv_c_msg_99k_024       CONSTANT VARCHAR2(15) := 'APP-XXINV-10024'; -- フォーマットエラー
  gv_c_msg_99k_025       CONSTANT VARCHAR2(15) := 'APP-XXINV-10025'; -- プロファイル取得エラー
  gv_c_msg_99k_032       CONSTANT VARCHAR2(15) := 'APP-XXINV-10032'; -- ロックエラー
--
  gv_c_msg_99k_101       CONSTANT VARCHAR2(15) := 'APP-XXINV-00001'; -- ファイル名
  gv_c_msg_99k_103       CONSTANT VARCHAR2(15) := 'APP-XXINV-00003'; -- アップロード日時
  gv_c_msg_99k_104       CONSTANT VARCHAR2(15) := 'APP-XXINV-00004'; -- ファイルアップロード名称
  gv_c_msg_99k_106       CONSTANT VARCHAR2(15) := 'APP-XXINV-00006'; -- フォーマットパターン
--
  -- トークン
  gv_c_tkn_param         CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_c_tkn_value         CONSTANT VARCHAR2(15) := 'VALUE';
  gv_c_tkn_name          CONSTANT VARCHAR2(15) := 'NAME';
  gv_c_tkn_item          CONSTANT VARCHAR2(15) := 'ITEM';
  gv_c_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
--
  -- プロファイル
  gv_c_parge_term_009    CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_009';
  gv_c_parge_term_name   CONSTANT VARCHAR2(40) := 'パージ対象期間：運賃アドオン';
--
  -- クイックコード タイプ
  gv_c_lookup_type       CONSTANT VARCHAR2(30) := 'XXINV_FILE_OBJECT';
  gv_c_format_type       CONSTANT VARCHAR2(20) := 'フォーマットパターン';
--
  gv_user_id_name        CONSTANT VARCHAR2(10) := 'ユーザーID';
  gv_file_id_name        CONSTANT VARCHAR2(24) := 'FILE_ID';
  gv_file_up_if_tbl      CONSTANT VARCHAR2(50) := 'ファイルアップロードインタフェーステーブル';
--
  gv_period              CONSTANT VARCHAR2(1) := '.';      -- ピリオド
  gv_comma               CONSTANT VARCHAR2(1) := ',';      -- カンマ
  gv_space               CONSTANT VARCHAR2(1) := ' ';      -- スペース
  gv_err_msg_space       CONSTANT VARCHAR2(6) := '      '; -- スペース（6byte）
  gv_classe_pay          CONSTANT VARCHAR2(1) := '1';      -- 支払
  gv_classe_ord          CONSTANT VARCHAR2(1) := '2';      -- 請求
--
  -- 運賃アドオンインタフェーステーブル：項目名
  gv_delivery_code_n     CONSTANT VARCHAR2(50) := '運送業者';
  gv_delivery_no_n       CONSTANT VARCHAR2(50) := '配送No';
  gv_invoice_no_n        CONSTANT VARCHAR2(50) := '送り状No';
  gv_delivery_classe_n   CONSTANT VARCHAR2(50) := '配送区分';
  gv_charged_amount_n    CONSTANT VARCHAR2(50) := '請求運賃';
  gv_qty_n               CONSTANT VARCHAR2(50) := '個数';
  gv_weight_n            CONSTANT VARCHAR2(50) := '重量';
  gv_distance_n          CONSTANT VARCHAR2(50) := '距離';
  gv_many_rate_n         CONSTANT VARCHAR2(50) := '諸料金';
  gv_congestion_n        CONSTANT VARCHAR2(50) := '通行料';
  gv_picking_n           CONSTANT VARCHAR2(50) := 'ピッキング料';
  gv_consolid_n          CONSTANT VARCHAR2(50) := '混載割増金額';
  gv_total_amount_n      CONSTANT VARCHAR2(50) := '合計';
--
  -- 運賃アドオンインタフェーステーブル：項目桁数
  gv_delivery_code_l     CONSTANT NUMBER := 4;   -- 運送業者
  gv_delivery_no_l       CONSTANT NUMBER := 12;  -- 配送No
  gv_invoice_no_l        CONSTANT NUMBER := 20;  -- 送り状No
  gv_delivery_classe_l   CONSTANT NUMBER := 2;   -- 配送区分
  gv_charged_amount_l    CONSTANT NUMBER := 7;   -- 請求運賃
  gv_qty_l               CONSTANT NUMBER := 4;   -- 個数
  gv_weight_l            CONSTANT NUMBER := 6;   -- 重量
  gv_distance_l          CONSTANT NUMBER := 4;   -- 距離
  gv_many_rate_l         CONSTANT NUMBER := 7;   -- 諸料金
  gv_congestion_l        CONSTANT NUMBER := 7;   -- 通行料
  gv_picking_l           CONSTANT NUMBER := 7;   -- ピッキング料
  gv_consolid_l          CONSTANT NUMBER := 7;   -- 混載割増金額
  gv_total_amount_l      CONSTANT NUMBER := 7;   -- 合計
--
  gv_decimal_len         CONSTANT NUMBER := 0;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- CSVを格納するレコード
  TYPE file_data_rec IS RECORD(
    delivery_code     VARCHAR2(32767), -- 運送業者
    delivery_no       VARCHAR2(32767), -- 配送No
    invoice_no        VARCHAR2(32767), -- 送り状No
    delivery_classe   VARCHAR2(32767), -- 配送区分
    charged_amount    VARCHAR2(32767), -- 請求運賃
    qty               VARCHAR2(32767), -- 個数
    weight            VARCHAR2(32767), -- 重量
    distance          VARCHAR2(32767), -- 距離
    many_rate         VARCHAR2(32767), -- 諸料金
    congestion        VARCHAR2(32767), -- 通行料
    picking           VARCHAR2(32767), -- ピッキング料
    consolid          VARCHAR2(32767), -- 混載割増金額
    total_amount      VARCHAR2(32767), -- 合計
--
    charged_amount_n  NUMBER, -- 請求運賃
    qty_n             NUMBER, -- 個数
    many_rate_n       NUMBER, -- 諸料金
    congestion_n      NUMBER, -- 通行料
    picking_n         NUMBER, -- ピッキング料
    weight_n          NUMBER, -- 重量
    distance_n        NUMBER, -- 距離
    consolid_n        NUMBER, -- 混載割増金額
    total_amount_n    NUMBER, -- 合計
--
    line              VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message       VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
--
  -- CSVを格納する結合配列
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
--
-- パターン区分
  TYPE reg_pattern_flag    IS TABLE OF xxwip_deliverys_if.pattern_flag          %TYPE INDEX BY BINARY_INTEGER;
-- 運送業者
  TYPE reg_delivery_code   IS TABLE OF xxwip_deliverys_if.delivery_company_code %TYPE INDEX BY BINARY_INTEGER;
-- 配送No
  TYPE reg_delivery_no     IS TABLE OF xxwip_deliverys_if.delivery_no           %TYPE INDEX BY BINARY_INTEGER;
-- 送り状No
  TYPE reg_invoice_no      IS TABLE OF xxwip_deliverys_if.invoice_no            %TYPE INDEX BY BINARY_INTEGER;
-- 支払請求区分
  TYPE reg_p_b_classe      IS TABLE OF xxwip_deliverys_if.p_b_classe            %TYPE INDEX BY BINARY_INTEGER;
-- 配送区分
  TYPE reg_delivery_classe IS TABLE OF xxwip_deliverys_if.delivery_classe       %TYPE INDEX BY BINARY_INTEGER;
-- 請求運賃
  TYPE reg_charged_amount  IS TABLE OF xxwip_deliverys_if.charged_amount        %TYPE INDEX BY BINARY_INTEGER;
-- 個数１
  TYPE reg_qty1            IS TABLE OF xxwip_deliverys_if.qty1                  %TYPE INDEX BY BINARY_INTEGER;
-- 個数２
  TYPE reg_qty2            IS TABLE OF xxwip_deliverys_if.qty2                  %TYPE INDEX BY BINARY_INTEGER;
-- 重量１
  TYPE reg_weight1         IS TABLE OF xxwip_deliverys_if.delivery_weight1      %TYPE INDEX BY BINARY_INTEGER;
-- 重量２
  TYPE reg_weight2         IS TABLE OF xxwip_deliverys_if.delivery_weight2      %TYPE INDEX BY BINARY_INTEGER;
-- 距離
  TYPE reg_distance        IS TABLE OF xxwip_deliverys_if.distance              %TYPE INDEX BY BINARY_INTEGER;
-- 諸料金
  TYPE reg_many_rate       IS TABLE OF xxwip_deliverys_if.many_rate             %TYPE INDEX BY BINARY_INTEGER;
-- 通行料
  TYPE reg_congestion      IS TABLE OF xxwip_deliverys_if.congestion_charge     %TYPE INDEX BY BINARY_INTEGER;
-- ピッキング料
  TYPE reg_picking         IS TABLE OF xxwip_deliverys_if.picking_charge        %TYPE INDEX BY BINARY_INTEGER;
-- 混載割増金額
  TYPE reg_consolid        IS TABLE OF xxwip_deliverys_if.consolid_surcharge    %TYPE INDEX BY BINARY_INTEGER;
-- 合計
  TYPE reg_total           IS TABLE OF xxwip_deliverys_if.total_amount          %TYPE INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***      項目格納テーブル型定義     ***
  -- ***************************************
--
  gr_fdata_tbl                file_data_tbl;  -- CSVファイル格納
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_purge_term               NUMBER;          -- パージ対象期間
  gv_file_name                VARCHAR2(256);   -- ファイル名
  gv_file_up_name             VARCHAR2(256);   -- ファイルアップロード名称
  gv_file_content_type        VARCHAR2(256);   -- ファイル交換方式オブジェクトタイプコード
  gv_proper_check_retcode     VARCHAR2(1);     -- 妥当性チェックステータス
  gv_delivery_code            VARCHAR2(100);   -- 運送業者
--
  -- 定数
  gn_created_by               NUMBER;          -- 作成者
  gd_creation_date            DATE;            -- 作成日
--
  gd_sysdate                  DATE;            -- システム日付
  gn_user_id                  NUMBER;          -- ユーザID
  gn_login_id                 NUMBER;          -- 最終更新ログイン
  gn_conc_request_id          NUMBER;          -- 要求ID
  gn_prog_appl_id             NUMBER;          -- コンカレント・プログラムのアプリケーションID
  gn_conc_program_id          NUMBER;          -- コンカレント・プログラムID
--
  -- 項目テーブル型定義
  gt_pattern_flag          reg_pattern_flag;          -- パターン区分
  gt_delivery_code         reg_delivery_code;         -- 運送業者
  gt_delivery_no           reg_delivery_no;           -- 配送No
  gt_invoice_no            reg_invoice_no;            -- 送り状No
  gt_p_b_classe            reg_p_b_classe;            -- 支払請求区分
  gt_delivery_classe       reg_delivery_classe;       -- 配送区分
  gt_charged_amount        reg_charged_amount;        -- 請求運賃
  gt_qty1                  reg_qty1;                  -- 個数１
  gt_qty2                  reg_qty2;                  -- 個数２
  gt_weight1               reg_weight1;               -- 重量１
  gt_weight2               reg_weight2;               -- 重量２
  gt_distance              reg_distance;              -- 距離
  gt_many_rate             reg_many_rate;             -- 諸料金
  gt_congestion            reg_congestion;            -- 通行料
  gt_picking               reg_picking;               -- ピッキング料
  gt_consolid              reg_consolid;              -- 混載割増金額
  gt_total                 reg_total;                 -- 合計
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : 登録データの設定
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    iv_file_format IN            VARCHAR2,   -- フォーマットパターン
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lr_file_rec         file_data_rec;
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
    <<data_set_loop>>
    FOR ln_index IN 1 .. gr_fdata_tbl.LAST LOOP
--
      lr_file_rec := gr_fdata_tbl(ln_index);
--
      gt_delivery_no(ln_index)    := lr_file_rec.delivery_no;           -- 配送No
      gt_invoice_no(ln_index)     := lr_file_rec.invoice_no;            -- 送り状No
      gt_charged_amount(ln_index) := lr_file_rec.charged_amount_n;      -- 請求運賃
      gt_congestion(ln_index)     := lr_file_rec.congestion_n;          -- 通行料
--
      -- 運賃用
      IF (iv_file_format = gv_format_code_01) THEN
        gt_pattern_flag(ln_index)    := gv_format_pat_01;                -- パターン区分
        gt_delivery_code(ln_index)   := gv_delivery_code;                -- 運送業者
        gt_p_b_classe(ln_index)      := gv_classe_pay;                   -- 支払請求区分
        gt_delivery_classe(ln_index) := NULL;                            -- 配送区分
        gt_qty1(ln_index)            := NULL;                            -- 個数１
        gt_qty2(ln_index)            := lr_file_rec.qty_n;               -- 個数２
        gt_weight1(ln_index)         := NULL;                            -- 重量１
        gt_weight2(ln_index)         := lr_file_rec.weight_n;            -- 重量２
        gt_distance(ln_index)        := NULL;                            -- 距離
        gt_many_rate(ln_index)       := NULL;                            -- 諸料金
        gt_picking(ln_index)         := NULL;                            -- ピッキング料
        gt_consolid(ln_index)        := NULL;                            -- 混載割増金額
        gt_total(ln_index)           := NULL;                            -- 合計
--
      -- 支払運賃用
      ELSIF (iv_file_format = gv_format_code_02) THEN
        gt_pattern_flag(ln_index)    := gv_format_pat_02;                -- パターン区分
        gt_delivery_code(ln_index)   := lr_file_rec.delivery_code;       -- 運送業者
        gt_p_b_classe(ln_index)      := gv_classe_pay;                   -- 支払請求区分
        gt_delivery_classe(ln_index) := lr_file_rec.delivery_classe;     -- 配送区分
        gt_qty1(ln_index)            := lr_file_rec.qty_n;               -- 個数１
        gt_qty2(ln_index)            := NULL;                            -- 個数２
        gt_weight1(ln_index)         := lr_file_rec.weight_n;            -- 重量１
        gt_weight2(ln_index)         := NULL;                            -- 重量２
        gt_distance(ln_index)        := lr_file_rec.distance_n;          -- 距離
        gt_many_rate(ln_index)       := lr_file_rec.many_rate_n;         -- 諸料金
        gt_picking(ln_index)         := lr_file_rec.picking_n;           -- ピッキング料
        gt_consolid(ln_index)        := lr_file_rec.consolid;            -- 混載割増金額
        gt_total(ln_index)           := lr_file_rec.total_amount_n;      -- 合計
--
      -- 請求運賃用
      ELSIF (iv_file_format = gv_format_code_03) THEN
        gt_pattern_flag(ln_index)    := gv_format_pat_02;                -- パターン区分
        gt_delivery_code(ln_index)   := lr_file_rec.delivery_code;       -- 運送業者
        gt_p_b_classe(ln_index)      := gv_classe_ord;                   -- 支払請求区分
        gt_delivery_classe(ln_index) := NULL;                            -- 配送区分
        gt_qty1(ln_index)            := NULL;                            -- 個数１
        gt_qty2(ln_index)            := NULL;                            -- 個数２
        gt_weight1(ln_index)         := NULL;                            -- 重量１
        gt_weight2(ln_index)         := NULL;                            -- 重量２
        gt_distance(ln_index)        := NULL;                            -- 距離
        gt_many_rate(ln_index)       := lr_file_rec.many_rate_n;         -- 諸料金
        gt_picking(ln_index)         := lr_file_rec.picking_n;           -- ピッキング料
        gt_consolid(ln_index)        := lr_file_rec.consolid;            -- 混載割増金額
        gt_total(ln_index)           := lr_file_rec.total_amount_n;      -- 合計
      END IF;
--
    END LOOP data_set_loop;
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
  END set_data_proc;
--
  /***********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(K-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_file_format IN            VARCHAR2,     -- 2.フォーマットパターン
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
    ln_param_count   NUMBER;   -- パラメータ
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
    -- フォーマットパターンチェック
    SELECT COUNT(xlvv.lookup_code)
    INTO   ln_param_count
    FROM   xxcmn_lookup_values_v xlvv          -- クイックコードVIEW
    WHERE  xlvv.lookup_type = gv_c_lookup_type
    AND    xlvv.lookup_code = iv_file_format
    AND    ROWNUM           = 1;
--
    -- フォーマットパターンがクイックコードに登録されていない場合
    IF (ln_param_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_016,
                                            gv_c_tkn_param,
                                            gv_c_format_type,
                                            gv_c_tkn_value,
                                            iv_file_format);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END parameter_check;
--
  /***********************************************************************************
   * Procedure Name   : relat_data_get
   * Description      : 関連データ取得(K-2)
   ***********************************************************************************/
  PROCEDURE relat_data_get(
    iv_file_format IN            VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'relat_data_get'; -- プログラム名
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
    lv_purge_term               VARCHAR2(20);    -- パージ対象期間
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
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    gd_sysdate                := SYSDATE;
--
    -- パージ対象期間：運賃アドオン
    lv_purge_term := FND_PROFILE.VALUE(gv_c_parge_term_009);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_purge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_025,
                                            gv_c_tkn_name,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値チェック
    BEGIN
      gv_purge_term := TO_NUMBER(lv_purge_term);
--
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_025,
                                              gv_c_tkn_name,
                                              gv_c_parge_term_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ファイルアップロード名称取得
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- クイックコードVIEW
      WHERE   xlvv.lookup_type = gv_c_lookup_type       -- タイプ
      AND     xlvv.lookup_code = iv_file_format         -- コード
      AND     ROWNUM           = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_008,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
                                              iv_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- フォーマットパターンが「13」の場合
    IF (iv_file_format = gv_format_code_01) THEN
--
      -- 運送業者コード取得
      BEGIN
        SELECT papf.attribute5
        INTO   gv_delivery_code
        FROM   fnd_user          fu
              ,per_all_people_f  papf
        WHERE  fu.employee_id = papf.person_id
        AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date AND papf.effective_end_date
        AND    fu.user_id     = gn_user_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gv_delivery_code := NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 事業所コードが取得できない場合はエラー
      IF (gv_delivery_code IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_008,
                                              gv_c_tkn_item,
                                              gv_user_id_name,
                                              gv_c_tkn_value,
                                              gn_user_id);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
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
  END relat_data_get;
--
  /***********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : ファイルアップロードIFデータ取得(K-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    iv_file_id      IN            VARCHAR2,   -- 1.FILE_ID
    iv_file_format  IN            VARCHAR2,   -- 2.フォーマットパターン
    ov_errbuf          OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(25) := 'get_upload_data_proc';  -- プログラム名
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
    lv_line       VARCHAR2(32767);   -- 改行コード迄の情報
    ln_col        NUMBER;            -- カラム
    lb_col        BOOLEAN := TRUE;   -- カラム作成継続
    ln_length     NUMBER;            -- 長さ保管用
    ln_file_id    NUMBER;
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;   -- 行テーブル格納領域
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
    ln_file_id := TO_NUMBER(iv_file_id);
--
    -- ***************************************
    -- ***     インタフェース情報取得      ***
    -- ***************************************
    -- ファイルアップロードインタフェースデータ取得
    -- 行ロック処理
    SELECT xmf.file_content_type,  -- ファイル交換方式オブジェクトタイプコード
           xmf.file_name,          -- ファイル名
           xmf.created_by,         -- 作成者
           xmf.creation_date       -- 作成日
    INTO   gv_file_content_type,
           gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = ln_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- ***************************************
    -- ***    インタフェースデータ取得     ***
    -- ***************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      ln_file_id,                              -- ファイルID
      lt_file_line_data,                       -- 変換後VARCHAR2データ
      lv_errbuf,                               -- エラー・メッセージ           --# 固定 #
      lv_retcode,                              -- リターン・コード             --# 固定 #
      lv_errmsg);                              -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみ、又は、2行目が改行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_008,
                                            gv_c_tkn_item,
                                            gv_file_id_name,
                                            gv_c_tkn_value,
                                            iv_file_id);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- *********************************************
    -- ***  取得データを行単位で処理(2行目以降)  ***
    -- *********************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 行毎に作業領域に格納
      lv_line := lt_file_line_data(ln_index);
--
      -- 1行の内容をlineに格納
      gr_fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- カラム番号初期化
      ln_col := 0;                                      -- カラム
      lb_col := TRUE;                                   -- カラム作成継続
--
      -- ***************************************
      -- ***       1行をカンマ毎に分解       ***
      -- ***************************************
      <<comma_loop>>
      LOOP
        -- lv_lineの長さが0なら終了
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- カラム番号をカウント
        ln_col := ln_col + 1;
--
        -- カンマの位置を取得
        ln_length := INSTR(lv_line, gv_comma);
--
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
        -- ***************************************
        -- ** CSV形式を項目ごとにレコードに格納 **
        -- ***************************************
--
        -- 運賃用
        IF (iv_file_format = gv_format_code_01) THEN
--
          -- 配送NO
          IF (ln_col = 1) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_no    := SUBSTR(lv_line, 1, ln_length);
--
          -- 送り状NO
          ELSIF (ln_col = 2) THEN
            gr_fdata_tbl(gn_target_cnt).invoice_no     := SUBSTR(lv_line, 1, ln_length);
--
          -- 請求運賃
          ELSIF (ln_col = 3) THEN
            gr_fdata_tbl(gn_target_cnt).charged_amount := SUBSTR(lv_line, 1, ln_length);
--
          -- 個数
          ELSIF (ln_col = 4) THEN
            gr_fdata_tbl(gn_target_cnt).qty            := SUBSTR(lv_line, 1, ln_length);
--
          -- 重量
          ELSIF (ln_col = 5) THEN
            gr_fdata_tbl(gn_target_cnt).weight         := SUBSTR(lv_line, 1, ln_length);
--
          -- 通行料
          ELSIF (ln_col = 6) THEN
            gr_fdata_tbl(gn_target_cnt).congestion     := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- 支払運賃用
        ELSIF (iv_file_format = gv_format_code_02) THEN
--
          -- 運送業者
          IF (ln_col = 1) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_code  := SUBSTR(lv_line, 1, ln_length);
--
          -- 配送NO
          ELSIF (ln_col = 2) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_no    := SUBSTR(lv_line, 1, ln_length);
--
          -- 送り状NO
          ELSIF (ln_col = 3) THEN
            gr_fdata_tbl(gn_target_cnt).invoice_no     := SUBSTR(lv_line, 1, ln_length);
--
          -- 配送区分
          ELSIF (ln_col = 4) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_classe := SUBSTR(lv_line, 1, ln_length);
--
          -- 請求運賃
          ELSIF (ln_col = 5) THEN
            gr_fdata_tbl(gn_target_cnt).charged_amount := SUBSTR(lv_line, 1, ln_length);
--
          -- 個数
          ELSIF (ln_col = 6) THEN
            gr_fdata_tbl(gn_target_cnt).qty            := SUBSTR(lv_line, 1, ln_length);
--
          -- 重量
          ELSIF (ln_col = 7) THEN
            gr_fdata_tbl(gn_target_cnt).weight         := SUBSTR(lv_line, 1, ln_length);
--
          -- 距離
          ELSIF (ln_col = 8) THEN
            gr_fdata_tbl(gn_target_cnt).distance       := SUBSTR(lv_line, 1, ln_length);
--
          -- 諸料金
          ELSIF (ln_col = 9) THEN
            gr_fdata_tbl(gn_target_cnt).many_rate      := SUBSTR(lv_line, 1, ln_length);
--
          -- 通行料
          ELSIF (ln_col = 10) THEN
            gr_fdata_tbl(gn_target_cnt).congestion     := SUBSTR(lv_line, 1, ln_length);
--
          -- ピッキング料
          ELSIF (ln_col = 11) THEN
            gr_fdata_tbl(gn_target_cnt).picking        := SUBSTR(lv_line, 1, ln_length);
--
          -- 混載割増金額
          ELSIF (ln_col = 12) THEN
            gr_fdata_tbl(gn_target_cnt).consolid       := SUBSTR(lv_line, 1, ln_length);
--
          -- 合計
          ELSIF (ln_col = 13) THEN
            gr_fdata_tbl(gn_target_cnt).total_amount   := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- 請求運賃用
        ELSIF (iv_file_format = gv_format_code_03) THEN
--
          -- 運送業者
          IF (ln_col = 1) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_code  := SUBSTR(lv_line, 1, ln_length);
--
          -- 配送NO
          ELSIF (ln_col = 2) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_no    := SUBSTR(lv_line, 1, ln_length);
--
          -- 送り状NO
          ELSIF (ln_col = 3) THEN
            gr_fdata_tbl(gn_target_cnt).invoice_no     := SUBSTR(lv_line, 1, ln_length);
--
          -- 請求運賃
          ELSIF (ln_col = 4) THEN
            gr_fdata_tbl(gn_target_cnt).charged_amount := SUBSTR(lv_line, 1, ln_length);
--
          -- 諸料金
          ELSIF (ln_col = 5) THEN
            gr_fdata_tbl(gn_target_cnt).many_rate      := SUBSTR(lv_line, 1, ln_length);
--
          -- 通行料
          ELSIF (ln_col = 6) THEN
            gr_fdata_tbl(gn_target_cnt).congestion     := SUBSTR(lv_line, 1, ln_length);
--
          -- ピッキング料
          ELSIF (ln_col = 7) THEN
            gr_fdata_tbl(gn_target_cnt).picking        := SUBSTR(lv_line, 1, ln_length);
--
          -- 混載割増金額
          ELSIF (ln_col = 8) THEN
            gr_fdata_tbl(gn_target_cnt).consolid       := SUBSTR(lv_line, 1, ln_length);
--
          -- 合計
          ELSIF (ln_col = 9) THEN
            gr_fdata_tbl(gn_target_cnt).total_amount   := SUBSTR(lv_line, 1, ln_length);
          END IF;
        END IF;
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
  EXCEPTION
--
    WHEN lock_expt THEN   --*** ロック取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_032,
                                            gv_c_tkn_table,
                                            gv_file_up_if_tbl);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_008,
                                            gv_c_tkn_item,
                                            gv_file_id_name,
                                            gv_c_tkn_value,
                                            iv_file_id);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : proper_check
   * Description      : 妥当性チェック(K-4)
   ***********************************************************************************/
  PROCEDURE proper_check(
    iv_file_format IN            VARCHAR2,   -- フォーマットパターン
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proper_check'; -- プログラム名
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
    lv_line_feed        VARCHAR2(1);                  -- 改行コード
--
    -- *** ローカル変数 ***
    ln_c_col   NUMBER; -- 総項目数
--
    lv_log_data         VARCHAR2(32767);  -- LOGデータ部退避用
--
    lr_file_rec         file_data_rec;
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
    gv_proper_check_retcode := gv_status_normal; -- 妥当性チェックステータス
    lv_line_feed := CHR(10);                     -- 改行コード
--
    -- 総項目数の設定
--
    -- フォーマットパターンが「13」の場合
    IF (iv_file_format = gv_format_code_01) THEN
      ln_c_col := 6;
--
    -- フォーマットパターンが「14」の場合
    ELSIF (iv_file_format = gv_format_code_02) THEN
      ln_c_col := 13;
--
    -- フォーマットパターンが「15」の場合
    ELSIF (iv_file_format = gv_format_code_03) THEN
      ln_c_col := 9;
    END IF;
--
    -- **************************************************
    -- *** 取得したレコード毎に項目チェックを行う。
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. gr_fdata_tbl.LAST LOOP
--
      lr_file_rec := gr_fdata_tbl(ln_index);
--
      -- **************************************************
      -- *** 項目数チェック
      -- **************************************************
      -- (行全体の長さ - 行からカンマを抜いた長さ = カンマの数)
      --   <> (正式な項目数 - 1 = 正式なカンマの数)
      IF ((NVL(LENGTH(lr_file_rec.line) ,0)
        - NVL(LENGTH(REPLACE(lr_file_rec.line,gv_comma, NULL)),0))
          <> (ln_c_col - 1))
      THEN
--
        lr_file_rec.err_message := gv_err_msg_space || gv_err_msg_space
                                   || xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99k_024)
                                   || lv_line_feed;
      -- 項目数が同じ場合
      ELSE
        -- 共通項目チェック
--
        -- 配送No(必須)
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_delivery_no_n              -- 項目名称
               ,iv_item_value   => lr_file_rec.delivery_no       -- 項目の値
               ,in_item_len     => gv_delivery_no_l              -- 項目の長さ
               ,in_item_decimal => NULL                          -- 小数点以下の長さ
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ng  -- 必須フラグ
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- 項目属性
               ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
               ,ov_retcode      => lv_retcode                    -- リターン・コード
               ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
        );
--
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- 送り状No
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_invoice_no_n               -- 項目名称
               ,iv_item_value   => lr_file_rec.invoice_no        -- 項目の値
               ,in_item_len     => gv_invoice_no_l               -- 項目の長さ
               ,in_item_decimal => NULL                          -- 小数点以下の長さ
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- 項目属性
               ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
               ,ov_retcode      => lv_retcode                    -- リターン・コード
               ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
        );
--
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- 請求運賃(必須)
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_charged_amount_n           -- 項目名称
               ,iv_item_value   => lr_file_rec.charged_amount    -- 項目の値
               ,in_item_len     => gv_charged_amount_l           -- 項目の長さ
               ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ng  -- 必須フラグ
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
               ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
               ,ov_retcode      => lv_retcode                    -- リターン・コード
               ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
        );
--
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- 通行料
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_congestion_n               -- 項目名称
               ,iv_item_value   => lr_file_rec.congestion        -- 項目の値
               ,in_item_len     => gv_congestion_l               -- 項目の長さ
               ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
               ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
               ,ov_retcode      => lv_retcode                    -- リターン・コード
               ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
        );
--
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- フォーマットパターン「１３」 OR フォーマットパターン「１４」
        IF ((iv_file_format = gv_format_code_01) OR (iv_file_format = gv_format_code_02)) THEN
--
          -- 個数
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_qty_n                      -- 項目名称
                 ,iv_item_value   => lr_file_rec.qty               -- 項目の値
                 ,in_item_len     => gv_qty_l                      -- 項目の長さ
                 ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- 重量
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_weight_n                   -- 項目名称
                 ,iv_item_value   => lr_file_rec.weight            -- 項目の値
                 ,in_item_len     => gv_weight_l                   -- 項目の長さ
                 ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- フォーマットパターン「１４」 OR フォーマットパターン「１５」
        IF ((iv_file_format = gv_format_code_02) OR (iv_file_format = gv_format_code_03)) THEN
--
          -- 運送業者(必須)
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_delivery_code_n            -- 項目名称
                 ,iv_item_value   => lr_file_rec.delivery_code     -- 項目の値
                 ,in_item_len     => gv_delivery_code_l            -- 項目の長さ
                 ,in_item_decimal => NULL                          -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ng  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- 諸料金
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_many_rate_n                -- 項目名称
                 ,iv_item_value   => lr_file_rec.many_rate         -- 項目の値
                 ,in_item_len     => gv_many_rate_l                -- 項目の長さ
                 ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ピッキング料
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_picking_n                  -- 項目名称
                 ,iv_item_value   => lr_file_rec.picking           -- 項目の値
                 ,in_item_len     => gv_picking_l                  -- 項目の長さ
                 ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- 混載割増金額
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_consolid_n                 -- 項目名称
                 ,iv_item_value   => lr_file_rec.consolid          -- 項目の値
                 ,in_item_len     => gv_consolid_l                 -- 項目の長さ
                 ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- 合計
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_total_amount_n             -- 項目名称
                 ,iv_item_value   => lr_file_rec.total_amount      -- 項目の値
                 ,in_item_len     => gv_total_amount_l             -- 項目の長さ
                 ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- フォーマットパターン「１４」
        IF (iv_file_format = gv_format_code_02) THEN
--
          -- 配送区分
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_delivery_classe_n          -- 項目名称
                 ,iv_item_value   => lr_file_rec.delivery_classe   -- 項目の値
                 ,in_item_len     => gv_delivery_classe_l          -- 項目の長さ
                 ,in_item_decimal => NULL                          -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- 距離
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_distance_n                 -- 項目名称
                 ,iv_item_value   => lr_file_rec.distance          -- 項目の値
                 ,in_item_len     => gv_distance_l                 -- 項目の長さ
                 ,in_item_decimal => gv_decimal_len                -- 小数点以下の長さ
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- 必須フラグ
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- 項目属性
                 ,ov_errbuf       => lv_errbuf                     -- エラー・メッセージ
                 ,ov_retcode      => lv_retcode                    -- リターン・コード
                 ,ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
--
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** エラー制御
      -- **************************************************
      -- チェックエラーありの場合
      IF (lr_file_rec.err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** データ部出力準備（行数 + SPACE + 行全体のデータ）
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_space || lr_file_rec.line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- エラーメッセージ部出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(lr_file_rec.err_message, lv_line_feed));
--
        -- 妥当性チェックステータス
        gv_proper_check_retcode := gv_status_error;
--
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
--
      -- チェックエラーなしの場合
      ELSE
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
        -- 数値に変換
        lr_file_rec.charged_amount_n := TO_NUMBER(lr_file_rec.charged_amount);
        lr_file_rec.qty_n            := TO_NUMBER(lr_file_rec.qty);
        lr_file_rec.many_rate_n      := TO_NUMBER(lr_file_rec.many_rate);
        lr_file_rec.congestion_n     := TO_NUMBER(lr_file_rec.congestion);
        lr_file_rec.picking_n        := TO_NUMBER(lr_file_rec.picking);
        lr_file_rec.weight_n         := TO_NUMBER(lr_file_rec.weight);
        lr_file_rec.distance_n       := TO_NUMBER(lr_file_rec.distance);
        lr_file_rec.consolid_n       := TO_NUMBER(lr_file_rec.consolid);
        lr_file_rec.total_amount_n   := TO_NUMBER(lr_file_rec.total_amount);
      END IF;
--
      gr_fdata_tbl(ln_index) := lr_file_rec;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proper_check;
--
  /***********************************************************************************
   * Procedure Name   : insert_data
   * Description      : データ登録(K-5)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- プログラム名
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
--    FORALL itp_cnt IN 0 .. gn_target_cnt-1
    FORALL itp_cnt IN 1 .. gr_fdata_tbl.LAST
      INSERT INTO xxwip_deliverys_if
      (
           delivery_id
          ,pattern_flag
          ,delivery_company_code
          ,delivery_no
          ,invoice_no
          ,p_b_classe
          ,delivery_classe
          ,charged_amount
          ,qty1
          ,qty2
          ,delivery_weight1
          ,delivery_weight2
          ,distance
          ,many_rate
          ,congestion_charge
          ,picking_charge
          ,consolid_surcharge
          ,total_amount
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
      )
      VALUES
      (
           xxwip_deliverys_if_id_s1.NEXTVAL                -- delivery_id
          ,gt_pattern_flag(itp_cnt)                        -- pattern_flag
          ,gt_delivery_code(itp_cnt)                       -- delivery_company_code
          ,gt_delivery_no(itp_cnt)                         -- delivery_no
          ,gt_invoice_no(itp_cnt)                          -- invoice_no
          ,gt_p_b_classe(itp_cnt)                          -- p_b_classe
          ,gt_delivery_classe(itp_cnt)                     -- delivery_classe
          ,gt_charged_amount(itp_cnt)                      -- charged_amount
          ,gt_qty1(itp_cnt)                                -- qty1
          ,gt_qty2(itp_cnt)                                -- qty2
          ,gt_weight1(itp_cnt)                             -- delivery_weight1
          ,gt_weight2(itp_cnt)                             -- delivery_weight2
          ,gt_distance(itp_cnt)                            -- distance
          ,gt_many_rate(itp_cnt)                           -- many_rate
          ,gt_congestion(itp_cnt)                          -- congestion_charge
          ,gt_picking(itp_cnt)                             -- picking_charge
          ,gt_consolid(itp_cnt)                            -- consolid_surcharge
          ,gt_total(itp_cnt)                               -- total_amount
          ,gn_user_id                                      -- created_by
          ,gd_sysdate                                      -- creation_date
          ,gn_user_id                                      -- last_updated_by
          ,gd_sysdate                                      -- last_update_date
          ,gn_login_id                                     -- last_update_login
          ,gn_conc_request_id                              -- request_id
          ,gn_prog_appl_id                                 -- program_application_id
          ,gn_conc_program_id                              -- program_id
          ,gd_sysdate                                      -- program_update_date
      );
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
  END insert_data;
--
  /***********************************************************************************
   * Procedure Name   : delete_tbl
   * Description      : ファイルアップロードIFテーブル削除(K-6)
   ***********************************************************************************/
  PROCEDURE delete_tbl(
    iv_file_format  IN            VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_tbl'; -- プログラム名
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
    -- ファイルアップロードインタフェースデータ削除
    xxcmn_common3_pkg.delete_fileup_proc(iv_file_format => iv_file_format,
                                         id_now_date    => gd_sysdate,
                                         in_purge_days  => gv_purge_term,
                                         ov_errbuf      => lv_errbuf,
                                         ov_retcode     => lv_retcode,
                                         ov_errmsg      => lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
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
  END delete_tbl;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id     IN            VARCHAR2,     -- 1.FILE_ID
    iv_file_format IN            VARCHAR2,     -- 2.フォーマットパターン
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
    ln_count      NUMBER;
    lv_out_rep    VARCHAR2(5000);
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
    ln_count      := 0;
--
    -- 妥当性チェックステータスの初期化
    gv_proper_check_retcode := gv_status_normal;
--
    --*********************************************
    --***        K-1 パラメータチェック         ***
    --*********************************************
    parameter_check(
      iv_file_format,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***        K-2 関連データ取得         ***
    --*********************************************
    relat_data_get(
      iv_file_format,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --*** K-3 ファイルアップロードIFデータ取得  ***
    --*********************************************
    get_upload_data_proc(
      iv_file_id,
      iv_file_format,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
--##############################  アップロード固定メッセージ START  ##############################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_101,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_104,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- フォーマットパターン
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_106,
                                              gv_c_tkn_value,
                                              iv_file_format);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--##############################  アップロード固定メッセージ END   ##############################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***        K-4 妥当性チェック             ***
    --*********************************************
    proper_check(
      iv_file_format,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 妥当性チェックでエラーがなかった場合
    ELSIF (gv_proper_check_retcode = gv_status_normal) THEN
--
      --*********************************************
      --***        登録データの設定               ***
      --*********************************************
      set_data_proc(
        iv_file_format,
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --*********************************************
      --***        K-5 データ登録                 ***
      --*********************************************
      insert_data(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --*********************************************
    --*** K-6 ファイルアップロードIFデータ削除  ***
    --*********************************************
    delete_tbl(
      iv_file_format,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2008.04.28 Y.Kawano modify start
--    IF (lv_retcode = gv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      -- 削除処理エラー時にRollBackをする為、妥当性チェックステータスを初期化
      gv_proper_check_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- チェック処理エラー
    IF (gv_proper_check_retcode = gv_status_error) THEN
      -- 固定のエラーメッセージの出力をしないようにする
      lv_errmsg := gv_space;
      RAISE global_process_expt;
    END IF;
-- 2008.04.28 Y.Kawano modify end
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
    iv_file_id     IN            VARCHAR2,      -- 1.FILE_ID
    iv_file_format IN            VARCHAR2)      -- 2.フォーマットパターン
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
      iv_file_id,      -- 1.FILE_ID
      iv_file_format,  -- 2.フォーマットパターン
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
--2008.4.28 Y.Kawano modify start
--    IF (retcode = gv_status_error) THEN
--      ROLLBACK;
--    END IF;
    IF (retcode = gv_status_error) AND (gv_proper_check_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--2008.4.28 Y.Kawano modify end
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
END xxinv990007c;
/
