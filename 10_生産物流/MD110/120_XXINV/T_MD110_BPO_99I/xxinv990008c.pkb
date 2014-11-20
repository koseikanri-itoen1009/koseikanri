CREATE OR REPLACE PACKAGE BODY xxinv990008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990008c(body)
 * Description      : 配送距離マスタの取込
 * MD.050           : ファイルアップロード T_MD050_BPO_990
 * MD.070           : 配送距離マスタの取込 T_MD070_BPO_99I
 * Version          : 1.0
 *
 * Program List
 * ------------------------ ----------------------------------------------------------
 *  Name                     Description
 * ------------------------ ----------------------------------------------------------
 *  init_proc                関連データ取得                               (I-1)
 *  get_upload_data_proc     ファイルアップロードインタフェースデータ取得 (I-2)
 *  check_proc               妥当性チェック                               (I-3)
 *  set_data_proc            登録データ設定
 *  insert_stc_inventory_if  データ登録                                   (I-4)
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/27    1.0   R.Matusita        新規作成
 *  2008/04/18    1.1   Oracle 山根 一浩  変更要求No63対応
 *  2008/04/25    1.2   Oracle 山根 一浩  変更要求No70対応
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
  lock_expt              EXCEPTION;               -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  gv_pkg_name             CONSTANT VARCHAR2(15) := 'xxinv990008c';      -- パッケージ名
  gv_app_name             CONSTANT VARCHAR2(5)  := 'XXINV';             -- アプリケーション短縮名
--
  -- メッセージ番号
  gv_msg_ng_profile       CONSTANT VARCHAR2(15) := 'APP-XXINV-10025';   -- プロファイル取得エラー
  gv_msg_ng_lock          CONSTANT VARCHAR2(15) := 'APP-XXINV-10032';   -- ロックエラー
  gv_msg_ng_data          CONSTANT VARCHAR2(15) := 'APP-XXINV-10008';   -- 対象データなし
  gv_msg_ng_format        CONSTANT VARCHAR2(15) := 'APP-XXINV-10024';   -- フォーマットチェックエラーメッセージ
--
  gv_msg_file_name        CONSTANT VARCHAR2(15) := 'APP-XXINV-00001';   -- ファイル名
  gv_msg_up_date          CONSTANT VARCHAR2(15) := 'APP-XXINV-00003';   -- アップロード日時
  gv_msg_up_name          CONSTANT VARCHAR2(15) := 'APP-XXINV-00004';   -- ファイルアップロード名称
--
  -- トークン
  gv_tkn_ng_profile       CONSTANT VARCHAR2(10) := 'NAME';              -- トークン：プロファイル名
  gv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';             -- トークン：テーブル名
  gv_tkn_item             CONSTANT VARCHAR2(15) := 'ITEM';              -- トークン：対象名
  gv_tkn_value            CONSTANT VARCHAR2(15) := 'VALUE';             -- トークン：値
--
  -- プロファイル
  gv_parge_term_if        CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_007';
  gv_parge_term_name      CONSTANT VARCHAR2(30) := 'パージ対象期間:配送距離マスタ';
--
  -- クイックコード(参照タイプ)
  gv_lookup_type          CONSTANT VARCHAR2(17) := 'XXINV_FILE_OBJECT';
  gv_format_type          CONSTANT VARCHAR2(20) := 'フォーマットパターン';
--
  -- 対象テーブル名
  gv_xxinv_mrp_file_nm    CONSTANT VARCHAR2(100) := 'ファイルアップロードインタフェーステーブル';
--
  gv_file_id_name         CONSTANT VARCHAR2(7)   := 'FILE_ID';
--
  -- 配送距離インタフェース：項目名
  gv_goods_classe_n           CONSTANT VARCHAR2(50) := '商品区分';
  gv_delivery_company_code_n  CONSTANT VARCHAR2(50) := '運送業者コード';
  gv_origin_shipment_n        CONSTANT VARCHAR2(50) := '出庫元';
  gv_code_division_n          CONSTANT VARCHAR2(50) := 'コード区分';
  gv_shipping_address_code_n  CONSTANT VARCHAR2(50) := '配送先コード';
  gv_start_date_active_n      CONSTANT VARCHAR2(50) := '適用開始日';
  gv_post_distance_n          CONSTANT VARCHAR2(50) := '車立距離';
  gv_small_distance_n         CONSTANT VARCHAR2(50) := '小口距離';
  gv_consolid_add_distance_n  CONSTANT VARCHAR2(50) := '混載割増距離';
  gv_actual_distance_n        CONSTANT VARCHAR2(50) := '実際距離';
  gv_area_a_n                 CONSTANT VARCHAR2(50) := 'エリアA';
  gv_area_b_n                 CONSTANT VARCHAR2(50) := 'エリアB';
  gv_area_c_n                 CONSTANT VARCHAR2(50) := 'エリアC';
--
  -- 配送距離インタフェース：項目桁数
  gn_goods_classe_l           CONSTANT NUMBER       := 1;                   -- 商品区分
  gn_delivery_company_code_l  CONSTANT NUMBER       := 4;                   -- 運送業者コード
  gn_origin_shipment_l        CONSTANT NUMBER       := 4;                   -- 出庫元
  gn_code_division_l          CONSTANT NUMBER       := 1;                   -- コード区分
  gn_shipping_address_code_l  CONSTANT NUMBER       := 9;                   -- 配送先コード
  gn_start_date_active_l      CONSTANT NUMBER       := 10;                   -- 適用開始日
  gn_post_distance_l          CONSTANT NUMBER       := 4;                   -- 車立距離
  gn_small_distance_l         CONSTANT NUMBER       := 4;                   -- 小口距離
  gn_consolid_add_distance_l  CONSTANT NUMBER       := 4;                   -- 混載割増距離
  gn_actual_distance_l        CONSTANT NUMBER       := 4;                   -- 実際距離
  gn_area_a_l                 CONSTANT NUMBER       := 5;                   -- エリアA
  gn_area_b_l                 CONSTANT NUMBER       := 5;                   -- エリアB
  gn_area_c_l                 CONSTANT NUMBER       := 5;                   -- エリアC
--
  gv_comma                    CONSTANT VARCHAR2(1)  := ',';                 -- カンマ
  gv_space                    CONSTANT VARCHAR2(1)  := ' ';                 -- スペース
  gv_err_msg_space            CONSTANT VARCHAR2(6)  := '      ';            -- スペース（6byte）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- CSVを格納するレコード
  TYPE file_data_rec IS RECORD(
    goods_classe                  VARCHAR2(32767), -- 商品区分
    delivery_company_code         VARCHAR2(32767), -- 運送業者コード
    origin_shipment               VARCHAR2(32767), -- 出庫倉庫
    code_division                 VARCHAR2(32767), -- コード区分
    shipping_address_code         VARCHAR2(32767), -- 配送先コード
    start_date_active             VARCHAR2(32767), -- 適用開始日
    post_distance                 VARCHAR2(32767), -- 車立距離
    small_distance                VARCHAR2(32767), -- 小口距離
    consolid_add_distance         VARCHAR2(32767), -- ドリンク混載割増距離
    actual_distance               VARCHAR2(32767), -- 実際距離
    area_a                        VARCHAR2(32767), -- エリアA
    area_b                        VARCHAR2(32767), -- エリアB
    area_c                        VARCHAR2(32767), -- エリアC
    line                          VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message                   VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
--
  -- CSVを格納する結合配列
  TYPE file_data_tbl  IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- 登録用PL/SQL表型
  -- 配送距離アドオンマスタインタフェースID
  TYPE delivery_distance_if_id_type IS
  TABLE OF xxwip_delivery_distance_if.delivery_distance_if_id%TYPE  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE goods_classe_type          IS
  TABLE OF xxwip_delivery_distance_if.goods_classe%TYPE  INDEX BY BINARY_INTEGER;
  -- 運送業者コード
  TYPE delivery_company_code_type IS
  TABLE OF xxwip_delivery_distance_if.delivery_company_code%TYPE  INDEX BY BINARY_INTEGER;
  -- 出庫元
  TYPE origin_shipment_type       IS
  TABLE OF xxwip_delivery_distance_if.origin_shipment%TYPE  INDEX BY BINARY_INTEGER;
  -- コード区分
  TYPE code_division_type         IS
  TABLE OF xxwip_delivery_distance_if.code_division%TYPE  INDEX BY BINARY_INTEGER;
  -- 配送先コード
  TYPE shipping_address_code_type IS
  TABLE OF xxwip_delivery_distance_if.shipping_address_code%TYPE  INDEX BY BINARY_INTEGER;
  -- 適用開始日
  TYPE start_date_active_type     IS
  TABLE OF xxwip_delivery_distance_if.start_date_active%TYPE  INDEX BY BINARY_INTEGER;
  -- 車立距離
  TYPE post_distance_type         IS
  TABLE OF xxwip_delivery_distance_if.post_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- 小口距離
  TYPE small_distance_type        IS
  TABLE OF xxwip_delivery_distance_if.small_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- 混載割増距離
  TYPE consolid_add_distance_type IS
  TABLE OF xxwip_delivery_distance_if.consolid_add_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- 実際距離
  TYPE actual_distance_type       IS
  TABLE OF xxwip_delivery_distance_if.actual_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- エリアA
  TYPE area_a_type                IS
  TABLE OF xxwip_delivery_distance_if.area_a%TYPE  INDEX BY BINARY_INTEGER;
  -- エリアB
  TYPE area_b_type                IS
  TABLE OF xxwip_delivery_distance_if.area_b%TYPE  INDEX BY BINARY_INTEGER;
  -- エリアC
  TYPE area_c_type                IS
  TABLE OF xxwip_delivery_distance_if.area_c%TYPE  INDEX BY BINARY_INTEGER;
--
  gt_delivery_distance_if_id      delivery_distance_if_id_type;         -- 配送距離アドオンマスタインタフェースID
  gt_goods_classe                 goods_classe_type;                    -- 商品区分
  gt_delivery_company_code        delivery_company_code_type;           -- 運送業者コード
  gt_origin_shipment              origin_shipment_type;                 -- 出庫元
  gt_code_division                code_division_type;                   -- コード区分
  gt_shipping_address_code        shipping_address_code_type;           -- 配送先コード
  gt_start_date_active            start_date_active_type;               -- 適用開始日
  gt_post_distance                post_distance_type;                   -- 車立距離
  gt_small_distance               small_distance_type;                  -- 小口距離
  gt_consolid_add_distance        consolid_add_distance_type;           -- 混載割増距離
  gt_actual_distance              actual_distance_type;                 -- 実際距離
  gt_area_a                       area_a_type;                          -- エリアA
  gt_area_b                       area_b_type;                          -- エリアB
  gt_area_c                       area_c_type;                          -- エリアC
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_sysdate              DATE;                                         -- システム日付
  gn_user_id              NUMBER;                                       -- ユーザID
  gn_login_id             NUMBER;                                       -- 最終更新ログイン
  gn_conc_request_id      NUMBER;                                       -- 要求ID
  gn_prog_appl_id         NUMBER;                                       -- プログラムアプリケーションID
  gn_conc_program_id      NUMBER;                                       -- プログラムID
--
  gn_xxinv_parge_term     NUMBER;                                       -- パージ対象期間
  gv_file_name            VARCHAR2(256);                                -- ファイル名
  gn_created_by           NUMBER(15);                                   -- 作成者
  gd_creation_date        DATE;                                         -- 作成日
  gv_file_up_name         VARCHAR2(30);                                 -- ファイルアップロード名
  gv_check_proc_retcode   VARCHAR2(1);                                  -- 妥当性チェックステータス
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 関連データ取得 (I-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format      IN  VARCHAR2,                   -- フォーマットパターン
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'init_proc';       -- プログラム名
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
    lv_parge_term           VARCHAR2(100);                              -- プロファイル：パージ対象期間
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
    -- ***        システム日付取得         ***
    -- ***************************************
    -- システム日付取得
    gd_sysdate := SYSDATE;
--
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;                          -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;                         -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;                  -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;                     -- プログラムアプリケーションID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;                  -- プログラムID
--
    -- ***************************************
    -- ***         プロファイル取得        ***
    -- ***************************************
    -- プロファイル「パージ対象期間」取得
    lv_parge_term := FND_PROFILE.VALUE(gv_parge_term_if);
--
    -- プロファイル取得エラー時
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- アプリケーション短縮名：XXINV
                            gv_msg_ng_profile,          -- APP-XXINV-10025：プロファイル取得エラー
                            gv_tkn_ng_profile,          -- トークン：プロファイル名
                            gv_parge_term_name);        -- パージ対象期間:棚卸
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値チェック
    BEGIN
      -- 数値型以外の場合はエラー
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
--
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN           -- *** データ型エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- アプリケーション短縮名：XXINV
                            gv_msg_ng_profile,          -- APP-XXINV-10025：プロファイル取得エラー
                            gv_tkn_ng_profile,          -- トークン：プロファイル名
                            gv_parge_term_name);        -- パージ対象期間:棚卸
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
      WHEN NO_DATA_FOUND THEN                           -- *** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- アプリケーション短縮名：XXINV
                            gv_msg_ng_data,             -- APP-XXINV-10008：対象データなし
                            gv_tkn_item,                -- トークン：対象名
                            gv_format_type,             -- フォーマットパターン
                            gv_tkn_value,               -- トークン：値
                            in_file_format);            -- ファイルフォーマット
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : ファイルアップロードインタフェースデータ取得 (I-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id          IN  NUMBER,                     -- ファイルID
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_line                 VARCHAR2(32767);                            -- 改行コード迄の情報
    ln_col                  NUMBER;                                     -- カラム
    lb_col                  BOOLEAN  := TRUE;                           -- カラム作成継続
    ln_length               NUMBER;                                     -- 長さ保管用
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;              -- 行テーブル格納領域
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
    -- ***     インタフェース情報取得      ***
    -- ***************************************
    -- ファイルアップロードインタフェースデータ取得
    -- 行ロック処理
    SELECT xmf.file_name,                               -- ファイル名
           xmf.created_by,                              -- 作成者
           xmf.creation_date                            -- 作成日
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- ***************************************
    -- ***    インタフェースデータ取得     ***
    -- ***************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,                                       -- ファイルID
      lt_file_line_data,                                -- 変換後VARCHAR2データ
      lv_errbuf,                                        -- エラー・メッセージ           --# 固定 #
      lv_retcode,                                       -- リターン・コード             --# 固定 #
      lv_errmsg);                                       -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみ、又は、2行目が改行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- アプリケーション短縮名：XXINV
                            gv_msg_ng_data,             -- 対象データなし
                            gv_tkn_item,                -- トークン：対象名
                            gv_file_id_name,            -- フォーマットパターン
                            gv_tkn_value,               -- トークン：値
                            in_file_id);                -- ファイルID
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
      fdata_tbl(gn_target_cnt).line := lv_line;
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
        -- CSV形式を項目ごとにレコードに格納
        IF (ln_col = 1) THEN                            -- 商品区分
          fdata_tbl(gn_target_cnt).goods_classe             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN                        -- 運送業者コード
          fdata_tbl(gn_target_cnt).delivery_company_code    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN                        -- 出庫元
          fdata_tbl(gn_target_cnt).origin_shipment          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN                        -- コード区分
          fdata_tbl(gn_target_cnt).code_division            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN                        -- 配送先コード
          fdata_tbl(gn_target_cnt).shipping_address_code    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN                        -- 適用開始日
          fdata_tbl(gn_target_cnt).start_date_active        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN                        -- 車立距離
          fdata_tbl(gn_target_cnt).post_distance            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN                        -- 小口距離
          fdata_tbl(gn_target_cnt).small_distance           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN                        -- 混載割増距離
          fdata_tbl(gn_target_cnt).consolid_add_distance    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN                        -- 実際距離
          fdata_tbl(gn_target_cnt).actual_distance          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN                        -- エリアA
          fdata_tbl(gn_target_cnt).area_a                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN                        -- エリアB
          fdata_tbl(gn_target_cnt).area_b                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN                        -- エリアC
          fdata_tbl(gn_target_cnt).area_c                   := SUBSTR(lv_line, 1, ln_length);
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
    WHEN lock_expt THEN                                 --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- アプリケーション短縮名：XXINV
                            gv_msg_ng_lock,             -- APP-XXINV-10032：ロックエラー
                            gv_tkn_table,               -- トークン：テーブル名
                            gv_xxinv_mrp_file_nm);      -- ファイルアップロードインタフェーステーブル
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- アプリケーション短縮名：XXINV
                            gv_msg_ng_data,             -- 対象データなし
                            gv_tkn_item,                -- トークン：対象名
                            gv_file_id_name,            -- FILE_ID
                            gv_tkn_value,               -- トークン：値
                            in_file_id);                -- ファイルID
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
   * Procedure Name   : check_proc
   * Description      : 妥当性チェック (I-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'check_proc';      -- プログラム名
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
    lv_line_feed            VARCHAR2(1);                                -- 改行コード
    cn_col                  CONSTANT NUMBER := 13;                      -- 総項目数
--
    -- *** ローカル変数 ***
    lv_log_data             VARCHAR2(32767);                            -- LOGデータ部退避用
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
    gv_check_proc_retcode := gv_status_normal;                          -- 妥当性チェックステータス
    lv_line_feed := CHR(10);                                            -- 改行コード
--
    -- ******************************************
    -- *** 取得レコード毎に項目チェックを実施 ***
    -- ******************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- ***************************************
      -- ***          項目数チェック         ***
      -- ***************************************
      -- (行全体の長さ－行からカンマを抜いた長さ＝カンマの数) <> (正式な項目数－１＝正式なカンマの数)
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line),0) - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_comma,NULL)),0))
          <> (cn_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_err_msg_space
                                           || gv_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_app_name, gv_msg_ng_format)
                                           || lv_line_feed;
      ELSE
        -- ***************************************
        -- ***           項目チェック          ***
        -- ***************************************
        -- 商品区分
        xxcmn_common3_pkg.upload_item_check(gv_goods_classe_n,
                                            fdata_tbl(ln_index).goods_classe,
                                            gn_goods_classe_l,
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
        -- 運送業者コード
        xxcmn_common3_pkg.upload_item_check(gv_delivery_company_code_n,
                                            fdata_tbl(ln_index).delivery_company_code,
                                            gn_delivery_company_code_l,
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
        -- 出庫元
        xxcmn_common3_pkg.upload_item_check(gv_origin_shipment_n,
                                            fdata_tbl(ln_index).origin_shipment,
                                            gn_origin_shipment_l,
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
        -- コード区分
        xxcmn_common3_pkg.upload_item_check(gv_code_division_n,
                                            fdata_tbl(ln_index).code_division,
                                            gn_code_division_l,
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
        -- 配送先コード
        xxcmn_common3_pkg.upload_item_check(gv_shipping_address_code_n,
                                            fdata_tbl(ln_index).shipping_address_code,
                                            gn_shipping_address_code_l,
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
        -- 適用開始日
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
        -- 車立距離
        xxcmn_common3_pkg.upload_item_check(gv_post_distance_n,
                                            fdata_tbl(ln_index).post_distance,
                                            gn_post_distance_l,
                                            0,
                                            xxcmn_common3_pkg.gv_null_ng,
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
        -- 小口距離
        xxcmn_common3_pkg.upload_item_check(gv_small_distance_n,
                                            fdata_tbl(ln_index).small_distance,
                                            gn_small_distance_l,
                                            0,
                                            xxcmn_common3_pkg.gv_null_ng,
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
        -- 混載割増距離
        xxcmn_common3_pkg.upload_item_check(gv_consolid_add_distance_n,
                                            fdata_tbl(ln_index).consolid_add_distance,
                                            gn_consolid_add_distance_l,
                                            0,
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
        -- 実際距離
        xxcmn_common3_pkg.upload_item_check(gv_actual_distance_n,
                                            fdata_tbl(ln_index).actual_distance,
                                            gn_actual_distance_l,
                                            0,
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
        -- エリアA
        xxcmn_common3_pkg.upload_item_check(gv_area_a_n,
                                            fdata_tbl(ln_index).area_a,
                                            gn_area_a_l,
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
        -- エリアB
        xxcmn_common3_pkg.upload_item_check(gv_area_b_n,
                                            fdata_tbl(ln_index).area_b,
                                            gn_area_b_l,
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
        -- エリアC
        xxcmn_common3_pkg.upload_item_check(gv_area_c_n,
                                            fdata_tbl(ln_index).area_c,
                                            gn_area_c_l,
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
      END IF;
--
      -- ***************************************
      -- ***            エラー制御           ***
      -- ***************************************
      -- チェックエラーありの場合
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- *******************************************************
        -- *** データ部出力準備(行数 + SPACE + 行全体のデータ) ***
        -- *******************************************************
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
   * Procedure Name   : set_data_proc
   * Description      : 登録データ設定
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'set_data_proc';   -- プログラム名
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
    ln_delivery_distance_if_id         NUMBER;  -- 配送距離アドオンマスタインタフェースID
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
    -- ローカル変数初期化
    ln_delivery_distance_if_id := NULL;
--
    -- **************************************************
    -- *** 登録用PL/SQL表編集（2行目から）
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- 配送距離アドオンマスタインタフェースID採番
      SELECT xxwip_delivery_distance_id_s1.NEXTVAL 
      INTO ln_delivery_distance_if_id 
      FROM dual;
--
      -- 対象項目の格納
      -- 配送距離アドオンマスタインタフェースID
      gt_delivery_distance_if_id(ln_index)     := ln_delivery_distance_if_id;
      -- 商品区分
      gt_goods_classe(ln_index) := fdata_tbl(ln_index).goods_classe;
      -- 運送業者コード
      gt_delivery_company_code(ln_index) := fdata_tbl(ln_index).delivery_company_code;
      -- 出庫元
      gt_origin_shipment(ln_index) := fdata_tbl(ln_index).origin_shipment;
      -- コード区分
      gt_code_division(ln_index) := fdata_tbl(ln_index).code_division;
      -- 配送先コード
      gt_shipping_address_code(ln_index) := fdata_tbl(ln_index).shipping_address_code;
      -- 適用開始日
      gt_start_date_active(ln_index) := 
      FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).start_date_active, 'RR/MM/DD');
      -- 車立距離
      gt_post_distance(ln_index) := fdata_tbl(ln_index).post_distance;
      -- 小口距離
      gt_small_distance(ln_index) := fdata_tbl(ln_index).small_distance;
      -- 混載割増距離
      gt_consolid_add_distance(ln_index) := fdata_tbl(ln_index).consolid_add_distance;
      -- 実際距離
      gt_actual_distance(ln_index) := fdata_tbl(ln_index).actual_distance;
      -- エリアA
      gt_area_a(ln_index) := fdata_tbl(ln_index).area_a;
      -- エリアB
      gt_area_b(ln_index) := fdata_tbl(ln_index).area_b;
      -- エリアC
      gt_area_c(ln_index) := fdata_tbl(ln_index).area_c;
--
    END LOOP fdata_loop;
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
   * Procedure Name   : insert_stc_inventory_if
   * Description      : データ登録 (I-4)
   ***********************************************************************************/
  PROCEDURE insert_stc_inventory_if(
    ov_errbuf           OUT NOCOPY VARCHAR2,            --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,            --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'insert_stc_inventory_if'; -- プログラム名
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
    -- *** 配送距離アドオンマスタインタフェース登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_delivery_distance_if_id.COUNT
      INSERT INTO xxwip_delivery_distance_if
      ( delivery_distance_if_id                         -- 配送距離アドオンマスタインタフェースID
       ,goods_classe                                    -- 商品区分
       ,delivery_company_code                           -- 運送業者コード
       ,origin_shipment                                 -- 出庫元
       ,code_division                                   -- コード区分
       ,shipping_address_code                           -- 配送先コード
       ,start_date_active                               -- 適用開始日
       ,post_distance                                   -- 車立距離
       ,small_distance                                  -- 小口距離
       ,consolid_add_distance                           -- 混載割増距離
       ,actual_distance                                 -- 実際距離
       ,area_a                                          -- エリアA
       ,area_b                                          -- エリアB
       ,area_c                                          -- エリアC
       ,created_by                                      -- 作成者
       ,creation_date                                   -- 作成日
       ,last_updated_by                                 -- 最終更新者
       ,last_update_date                                -- 最終更新日
       ,last_update_login                               -- 最終更新ログイン
       ,request_id                                      -- 要求ID
       ,program_application_id                          -- プログラムアプリケーションID
       ,program_id                                      -- プログラムID
       ,program_update_date                             -- プログラム更新日
      ) VALUES
      ( gt_delivery_distance_if_id(item_cnt)            -- 配送距離アドオンマスタインタフェースID
       ,gt_goods_classe(item_cnt)                       -- 商品区分
       ,gt_delivery_company_code(item_cnt)              -- 運送業者コード
       ,gt_origin_shipment(item_cnt)                    -- 出庫元
       ,gt_code_division(item_cnt)                      -- コード区分
       ,gt_shipping_address_code(item_cnt)              -- 配送先コード
       ,gt_start_date_active(item_cnt)                  -- 適用開始日
       ,gt_post_distance(item_cnt)                      -- 車立距離
       ,gt_small_distance(item_cnt)                     -- 小口距離
       ,gt_consolid_add_distance(item_cnt)              -- 混載割増距離
       ,gt_actual_distance(item_cnt)                    -- 実際距離
       ,gt_area_a(item_cnt)                             -- エリアA
       ,gt_area_b(item_cnt)                             -- エリアB
       ,gt_area_c(item_cnt)                             -- エリアC
       ,gn_user_id                                      -- 作成者
       ,gd_sysdate                                      -- 作成日
       ,gn_user_id                                      -- 最終更新者
       ,gd_sysdate                                      -- 最終更新日
       ,gn_login_id                                     -- 最終更新ログイン
       ,gn_conc_request_id                              -- 要求ID
       ,gn_prog_appl_id                                 -- プログラムアプリケーションID
       ,gn_conc_program_id                              -- プログラムID
       ,gd_sysdate                                      -- プログラムによる更新日
      );
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
  END insert_stc_inventory_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id          IN  NUMBER,                     --   ファイルＩＤ
    in_file_format      IN  VARCHAR2,                   --   フォーマットパターン
    ov_errbuf           OUT NOCOPY VARCHAR2,            --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,            --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';       -- プログラム名
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
    lv_out_rep              VARCHAR2(32767);                            -- レポート出力
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
    -- 妥当性チェックステータスの初期化
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 関連データ取得 (I-1)
    -- ===============================
    init_proc(
      in_file_format,                 -- フォーマットパターン
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- ファイルアップロードインタフェースデータ取得 (I-2)
    -- ==================================================
    get_upload_data_proc(
      in_file_id,                     -- ファイルＩＤ
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
--#################################  アップロード固定メッセージ START  ###################################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_msg_file_name,
                                              gv_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_msg_up_date,
                                              gv_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_app_name,
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
    END IF;
--
    -- ===============================
    -- 妥当性チェック (I-3)
    -- ===============================
    check_proc(
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
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
        lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
        lv_retcode,                   -- リターン・コード             --# 固定 #
        lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- データ登録 (I-4)
      -- ===============================
      insert_stc_inventory_if(
        lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
        lv_retcode,                   -- リターン・コード             --# 固定 #
        lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ==================================================
    -- ファイルアップロードインタフェースデータ削除 (I-5)
    -- ==================================================
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
    errbuf              OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    retcode             OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    in_file_id          IN  VARCHAR2,                   -- 1.ファイルＩＤ 2008/04/18 変更
    in_file_format      IN  VARCHAR2                    -- 2.フォーマットパターン
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'main';           -- プログラム名
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
      TO_NUMBER(in_file_id),                       -- 1.ファイルＩＤ 2008/04/18 変更
      in_file_format,                              -- 2.フォーマットパターン
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
END xxinv990008c;
/
