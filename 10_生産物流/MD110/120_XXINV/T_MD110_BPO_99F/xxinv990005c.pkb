CREATE OR REPLACE PACKAGE BODY xxinv990005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990005c(body)
 * Description      : 棚卸のアップロード
 * MD.050           : ファイルアップロード T_MD050_BPO_990
 * MD.070           : 棚卸のアップロード   T_MD070_BPO_99F
 * Version          : 1.0
 *
 * Program List
 * ------------------------ ----------------------------------------------------------
 *  Name                     Description
 * ------------------------ ----------------------------------------------------------
 *  init_proc                関連データ取得                               (F-1)
 *  get_upload_data_proc     ファイルアップロードインタフェースデータ取得 (F-2)
 *  check_proc               妥当性チェック                               (F-3)
 *  set_data_proc            登録データ設定
 *  insert_stc_inventory_if  データ登録                                   (F-4)
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/19    1.0   ORACLE 岩佐智治  main新規作成
 *  2008/04/04    1.0   ORACLE 椎名昭圭  内部変更要求#34
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
  gv_pkg_name             CONSTANT VARCHAR2(15) := 'xxinv990005c';      -- パッケージ名
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
  gv_parge_term_if        CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_005';
  gv_parge_term_name      CONSTANT VARCHAR2(19) := 'パージ対象期間:棚卸';
--
  -- クイックコード(参照タイプ)
  gv_lookup_type          CONSTANT VARCHAR2(17) := 'XXINV_FILE_OBJECT';
  gv_format_type          CONSTANT VARCHAR2(20) := 'フォーマットパターン';
--
  -- 対象テーブル名
  gv_xxinv_mrp_file_nm    CONSTANT VARCHAR2(100) := 'ファイルアップロードインタフェーステーブル';
--
  gv_file_id_name         CONSTANT VARCHAR2(7) := 'FILE_ID';
--
  -- 棚卸インタフェース：項目名
  gv_report_post_code_n   CONSTANT VARCHAR2(50) := '報告部署';
  gv_invent_date_n        CONSTANT VARCHAR2(50) := '棚卸日';
  gv_invent_whse_code_n   CONSTANT VARCHAR2(50) := '棚卸倉庫';
  gv_invent_seq_n         CONSTANT VARCHAR2(50) := '棚卸連番';
  gv_item_code_n          CONSTANT VARCHAR2(50) := '品目';
  gv_lot_no_n             CONSTANT VARCHAR2(50) := 'ロットNo.';
  gv_maker_date_n         CONSTANT VARCHAR2(50) := '製造日';
  gv_limit_date_n         CONSTANT VARCHAR2(50) := '賞味期限';
  gv_proper_mark_n        CONSTANT VARCHAR2(50) := '固有記号';
  gv_case_amt_n           CONSTANT VARCHAR2(50) := '棚卸ケース数';
  gv_content_n            CONSTANT VARCHAR2(50) := '入数';
  gv_loose_amt_n          CONSTANT VARCHAR2(50) := '棚卸バラ';
  gv_location_n           CONSTANT VARCHAR2(50) := 'ロケーション';
  gv_rack_no1_n           CONSTANT VARCHAR2(50) := 'ラックNo１';
  gv_rack_no2_n           CONSTANT VARCHAR2(50) := 'ラックNo２';
  gv_rack_no3_n           CONSTANT VARCHAR2(50) := 'ラックNo３';
--
  -- 棚卸インタフェース：項目桁数
  gn_report_post_code_l   CONSTANT NUMBER       := 4;                   -- 報告部署
  gn_invent_whse_code_l   CONSTANT NUMBER       := 3;                   -- 棚卸倉庫
  gn_invent_seq_l         CONSTANT NUMBER       := 12;                  -- 棚卸連番
  gn_item_code_l          CONSTANT NUMBER       := 7;                   -- 品目
  gn_lot_no_l             CONSTANT NUMBER       := 10;                  -- ロットNo.
  gn_maker_date_l         CONSTANT NUMBER       := 10;                  -- 製造日
  gn_limit_date_l         CONSTANT NUMBER       := 10;                  -- 賞味期限
  gn_proper_mark_l        CONSTANT NUMBER       := 6;                   -- 固有記号
  gn_case_amt_l           CONSTANT NUMBER       := 9;                   -- 棚卸ケース数
  gn_case_amt_d           CONSTANT NUMBER       := 0;                   -- 棚卸ケース数(小数点以下)
  gn_content_l            CONSTANT NUMBER       := 8;                   -- 入数
  gn_content_d            CONSTANT NUMBER       := 3;                   -- 入数(小数点以下)
  gn_loose_amt_l          CONSTANT NUMBER       := 12;                  -- 棚卸バラ
  gn_loose_amt_d          CONSTANT NUMBER       := 3;                   -- 棚卸バラ(小数点以下)
  gn_location_l           CONSTANT NUMBER       := 10;                  -- ロケーション
  gn_rack_no1_l           CONSTANT NUMBER       := 2;                   -- ラックNo１
  gn_rack_no2_l           CONSTANT NUMBER       := 2;                   -- ラックNo２
  gn_rack_no3_l           CONSTANT NUMBER       := 2;                   -- ラックNo３
--
  gv_comma                CONSTANT VARCHAR2(1)  := ',';                 -- カンマ
  gv_space                CONSTANT VARCHAR2(1)  := ' ';                 -- スペース
  gv_err_msg_space        CONSTANT VARCHAR2(6)  := '      ';            -- スペース（6byte）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- CSVを格納するレコード
  TYPE file_data_rec IS RECORD(
    corporation_name              VARCHAR2(32767), -- 会社名
    eos_data_type                 VARCHAR2(32767), -- データ種別
    tranceration_number           VARCHAR2(32767), -- 伝送用枝番
    report_post_code              VARCHAR2(32767), -- 報告部署
    invent_date                   VARCHAR2(32767), -- 棚卸日
    invent_whse_code              VARCHAR2(32767), -- 棚卸倉庫
    invent_seq                    VARCHAR2(32767), -- 棚卸連番
    item_code                     VARCHAR2(32767), -- 品目
    lot_no                        VARCHAR2(32767), -- ロットNo.
    maker_date                    VARCHAR2(32767), -- 製造日
    limit_date                    VARCHAR2(32767), -- 賞味期限
    proper_mark                   VARCHAR2(32767), -- 固有記号
    case_amt                      VARCHAR2(32767), -- 棚卸ケース数
    content                       VARCHAR2(32767), -- 入数
    loose_amt                     VARCHAR2(32767), -- 棚卸バラ
    location                      VARCHAR2(32767), -- ロケーション
    rack_no1                      VARCHAR2(32767), -- ラックNo１
    rack_no2                      VARCHAR2(32767), -- ラックNo２
    rack_no3                      VARCHAR2(32767), -- ラックNo３
    update_date                   VARCHAR2(32767), -- 更新日時
    line                          VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message                   VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
--
  -- CSVを格納する結合配列
  TYPE file_data_tbl  IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- 登録用PL/SQL表型
  -- 棚卸IF_ID
  TYPE invent_if_id_type     IS TABLE OF xxinv_stc_inventory_interface.invent_if_id%TYPE     INDEX BY BINARY_INTEGER;
  -- 報告部署
  TYPE report_post_code_type IS TABLE OF xxinv_stc_inventory_interface.report_post_code%TYPE INDEX BY BINARY_INTEGER;
  -- 棚卸日
  TYPE invent_date_type      IS TABLE OF xxinv_stc_inventory_interface.invent_date%TYPE      INDEX BY BINARY_INTEGER;
  -- 棚卸倉庫
  TYPE invent_whse_code_type IS TABLE OF xxinv_stc_inventory_interface.invent_whse_code%TYPE INDEX BY BINARY_INTEGER;
  -- 棚卸連番
  TYPE invent_seq_type       IS TABLE OF xxinv_stc_inventory_interface.invent_seq%TYPE       INDEX BY BINARY_INTEGER;
  -- 品目
  TYPE item_code_type        IS TABLE OF xxinv_stc_inventory_interface.item_code%TYPE        INDEX BY BINARY_INTEGER;
  -- ロットNo.
  TYPE lot_no_type           IS TABLE OF xxinv_stc_inventory_interface.lot_no%TYPE           INDEX BY BINARY_INTEGER;
  -- 製造日
  TYPE maker_date_type       IS TABLE OF xxinv_stc_inventory_interface.maker_date%TYPE       INDEX BY BINARY_INTEGER;
  -- 賞味期限
  TYPE limit_date_type       IS TABLE OF xxinv_stc_inventory_interface.limit_date%TYPE       INDEX BY BINARY_INTEGER;
  -- 固有記号
  TYPE proper_mark_type      IS TABLE OF xxinv_stc_inventory_interface.proper_mark%TYPE      INDEX BY BINARY_INTEGER;
  -- 棚卸ケース数
  TYPE case_amt_type         IS TABLE OF xxinv_stc_inventory_interface.case_amt%TYPE         INDEX BY BINARY_INTEGER;
  -- 入数
  TYPE content_type          IS TABLE OF xxinv_stc_inventory_interface.content%TYPE          INDEX BY BINARY_INTEGER;
  -- 棚卸バラ
  TYPE loose_amt_type        IS TABLE OF xxinv_stc_inventory_interface.loose_amt%TYPE        INDEX BY BINARY_INTEGER;
  -- ロケーション
  TYPE location_type         IS TABLE OF xxinv_stc_inventory_interface.location%TYPE         INDEX BY BINARY_INTEGER;
  -- ラックNo１
  TYPE rack_no1_type         IS TABLE OF xxinv_stc_inventory_interface.rack_no1%TYPE         INDEX BY BINARY_INTEGER;
  -- ラックNo２
  TYPE rack_no2_type         IS TABLE OF xxinv_stc_inventory_interface.rack_no2%TYPE         INDEX BY BINARY_INTEGER;
  -- ラックNo３
  TYPE rack_no3_type         IS TABLE OF xxinv_stc_inventory_interface.rack_no3%TYPE         INDEX BY BINARY_INTEGER;
--
  gt_invent_if_id           invent_if_id_type;                          -- 棚卸IF_ID
  gt_report_post_code       report_post_code_type;                      -- 報告部署
  gt_invent_date            invent_date_type;                           -- 棚卸日
  gt_invent_whse_code       invent_whse_code_type;                      -- 棚卸倉庫
  gt_invent_seq             invent_seq_type;                            -- 棚卸連番
  gt_item_code              item_code_type;                             -- 品目
  gt_lot_no                 lot_no_type;                                -- ロットNo.
  gt_maker_date             maker_date_type;                            -- 製造日
  gt_limit_date             limit_date_type;                            -- 賞味期限
  gt_proper_mark            proper_mark_type;                           -- 固有記号
  gt_case_amt               case_amt_type;                              -- 棚卸ケース数
  gt_content                content_type;                               -- 入数
  gt_loose_amt              loose_amt_type;                             -- 棚卸バラ
  gt_location               location_type;                              -- ロケーション
  gt_rack_no1               rack_no1_type;                              -- ラックNo１
  gt_rack_no2               rack_no2_type;                              -- ラックNo２
  gt_rack_no3               rack_no3_type;                              -- ラックNo３
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
   * Description      : 関連データ取得 (F-1)
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
    lv_parge_term           VARCHAR2(100);                        -- プロファイル：パージ対象期間
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
    gn_user_id          := FND_GLOBAL.USER_ID;                    -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;                   -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;            -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;               -- プログラムアプリケーションID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;            -- プログラムID
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
   * Description      : ファイルアップロードインタフェースデータ取得 (F-2)
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
        IF (ln_col = 1) THEN                            -- 会社名
          fdata_tbl(gn_target_cnt).corporation_name          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN                        -- データ種別
          fdata_tbl(gn_target_cnt).eos_data_type             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN                        -- 伝送用枝番
          fdata_tbl(gn_target_cnt).tranceration_number       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN                        -- 報告部署
          fdata_tbl(gn_target_cnt).report_post_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN                        -- 棚卸日
          fdata_tbl(gn_target_cnt).invent_date               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN                        -- 棚卸倉庫
          fdata_tbl(gn_target_cnt).invent_whse_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN                        -- 棚卸連番
          fdata_tbl(gn_target_cnt).invent_seq                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN                        -- 品目
          fdata_tbl(gn_target_cnt).item_code                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN                        -- ロットNo.
          fdata_tbl(gn_target_cnt).lot_no                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN                       -- 製造日
          fdata_tbl(gn_target_cnt).maker_date                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN                       -- 賞味期限
          fdata_tbl(gn_target_cnt).limit_date                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN                       -- 固有記号
          fdata_tbl(gn_target_cnt).proper_mark               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN                       -- 棚卸ケース数
          fdata_tbl(gn_target_cnt).case_amt                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN                       -- 入数
          fdata_tbl(gn_target_cnt).content                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN                       -- 棚卸バラ
          fdata_tbl(gn_target_cnt).loose_amt                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 16) THEN                       -- ロケーション
          fdata_tbl(gn_target_cnt).location                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 17) THEN                       -- ラックNo１
          fdata_tbl(gn_target_cnt).rack_no1                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 18) THEN                       -- ラックNo２
          fdata_tbl(gn_target_cnt).rack_no2                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 19) THEN                       -- ラックNo３
          fdata_tbl(gn_target_cnt).rack_no3                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 20) THEN                       -- 更新日時
          fdata_tbl(gn_target_cnt).update_date               := SUBSTR(lv_line, 1, ln_length);
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
   * Description      : 妥当性チェック (F-3)
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
    cn_col                  CONSTANT NUMBER := 20;                      -- 総項目数
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
        -- 報告部署
        xxcmn_common3_pkg.upload_item_check(gv_report_post_code_n,
                                            fdata_tbl(ln_index).report_post_code,
                                            gn_report_post_code_l,
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
        -- 棚卸日
        xxcmn_common3_pkg.upload_item_check(gv_invent_date_n,
                                            fdata_tbl(ln_index).invent_date,
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
        -- 棚卸倉庫
        xxcmn_common3_pkg.upload_item_check(gv_invent_whse_code_n,
                                            fdata_tbl(ln_index).invent_whse_code,
                                            gn_invent_whse_code_l,
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
        -- 棚卸連番
        xxcmn_common3_pkg.upload_item_check(gv_invent_seq_n,
                                            fdata_tbl(ln_index).invent_seq,
                                            gn_invent_seq_l,
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
        -- 品目
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
        -- ロットNo.
        xxcmn_common3_pkg.upload_item_check(gv_lot_no_n,
                                            fdata_tbl(ln_index).lot_no,
                                            gn_lot_no_l,
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
        -- 製造日
        xxcmn_common3_pkg.upload_item_check(gv_maker_date_n,
                                            fdata_tbl(ln_index).maker_date,
                                            gn_maker_date_l,
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
        -- 賞味期限
        xxcmn_common3_pkg.upload_item_check(gv_limit_date_n,
                                            fdata_tbl(ln_index).limit_date,
                                            gn_limit_date_l,
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
        -- 固有記号
        xxcmn_common3_pkg.upload_item_check(gv_proper_mark_n,
                                            fdata_tbl(ln_index).proper_mark,
                                            gn_proper_mark_l,
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
        -- 棚卸ケース数
        xxcmn_common3_pkg.upload_item_check(gv_case_amt_n,
                                            fdata_tbl(ln_index).case_amt,
                                            gn_case_amt_l,
                                            gn_case_amt_d,
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
        -- 入数
        xxcmn_common3_pkg.upload_item_check(gv_content_n,
                                            fdata_tbl(ln_index).content,
                                            gn_content_l,
                                            gn_content_d,
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
        -- 棚卸バラ
        xxcmn_common3_pkg.upload_item_check(gv_loose_amt_n,
                                            fdata_tbl(ln_index).loose_amt,
                                            gn_loose_amt_l,
                                            gn_loose_amt_d,
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
        -- ロケーション
        xxcmn_common3_pkg.upload_item_check(gv_location_n,
                                            fdata_tbl(ln_index).location,
                                            gn_location_l,
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
        -- ラックNo１
        xxcmn_common3_pkg.upload_item_check(gv_rack_no1_n,
                                            fdata_tbl(ln_index).rack_no1,
                                            gn_rack_no1_l,
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
        -- ラックNo２
        xxcmn_common3_pkg.upload_item_check(gv_rack_no2_n,
                                            fdata_tbl(ln_index).rack_no2,
                                            gn_rack_no2_l,
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
        -- ラックNo３
        xxcmn_common3_pkg.upload_item_check(gv_rack_no3_n,
                                            fdata_tbl(ln_index).rack_no3,
                                            gn_rack_no3_l,
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
    ln_invent_if_id         NUMBER;                                     -- 棚卸IF_ID
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
    ln_invent_if_id := NULL;
--
    -- **************************************************
    -- *** 登録用PL/SQL表編集（2行目から）
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- 棚卸IF_ID採番
      SELECT xxinv_stc_invt_if_s1.NEXTVAL 
      INTO ln_invent_if_id 
      FROM dual;
--
      -- 対象項目の格納
      -- 棚卸IF_ID
      gt_invent_if_id(ln_index)     := ln_invent_if_id;
      -- 報告部署
      gt_report_post_code(ln_index) := fdata_tbl(ln_index).report_post_code;
      -- 棚卸日
      gt_invent_date(ln_index)      := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).invent_date,'YYYY/MM/DD');
      -- 棚卸倉庫
      gt_invent_whse_code(ln_index) := fdata_tbl(ln_index).invent_whse_code;
      -- 棚卸連番
      gt_invent_seq(ln_index)       := fdata_tbl(ln_index).invent_seq;
      -- 品目
      gt_item_code(ln_index)        := fdata_tbl(ln_index).item_code;
      -- ロットNo.
      gt_lot_no(ln_index)           := fdata_tbl(ln_index).lot_no;
      -- 製造日
      gt_maker_date(ln_index)       := fdata_tbl(ln_index).maker_date;
      -- 賞味期限
      gt_limit_date(ln_index)       := fdata_tbl(ln_index).limit_date;
      -- 固有記号
      gt_proper_mark(ln_index)      := fdata_tbl(ln_index).proper_mark;
      -- 棚卸ケース数
      gt_case_amt(ln_index)         := fdata_tbl(ln_index).case_amt;
      -- 入数
      gt_content(ln_index)          := fdata_tbl(ln_index).content;
      -- 棚卸バラ
      gt_loose_amt(ln_index)        := fdata_tbl(ln_index).loose_amt;
      -- ロケーション
      gt_location(ln_index)         := fdata_tbl(ln_index).location;
      -- ラックNo１
      gt_rack_no1(ln_index)         := fdata_tbl(ln_index).rack_no1;
      -- ラックNo２
      gt_rack_no2(ln_index)         := fdata_tbl(ln_index).rack_no2;
      -- ラックNo３
      gt_rack_no3(ln_index)         := fdata_tbl(ln_index).rack_no3;
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
   * Description      : データ登録 (F-4)
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
    -- *** 物流構成アドオンインタフェース登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_invent_if_id.COUNT
      INSERT INTO xxinv_stc_inventory_interface
      ( invent_if_id                                    -- 棚卸IF_ID
       ,report_post_code                                -- 報告部署
       ,invent_date                                     -- 棚卸日
       ,invent_whse_code                                -- 棚卸倉庫
       ,invent_seq                                      -- 棚卸連番
       ,item_code                                       -- 品目
       ,lot_no                                          -- ロットNo.
       ,maker_date                                      -- 製造日
       ,limit_date                                      -- 賞味期限
       ,proper_mark                                     -- 固有記号
       ,case_amt                                        -- 棚卸ケース数
       ,content                                         -- 入数
       ,loose_amt                                       -- 棚卸バラ
       ,location                                        -- ロケーション
       ,rack_no1                                        -- ラックNo１
       ,rack_no2                                        -- ラックNo２
       ,rack_no3                                        -- ラックNo３
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
      ( gt_invent_if_id(item_cnt)                       -- 棚卸IF_ID
       ,gt_report_post_code(item_cnt)                   -- 報告部署
       ,gt_invent_date(item_cnt)                        -- 棚卸日
       ,gt_invent_whse_code(item_cnt)                   -- 棚卸倉庫
       ,gt_invent_seq(item_cnt)                         -- 棚卸連番
       ,gt_item_code(item_cnt)                          -- 品目
       ,gt_lot_no(item_cnt)                             -- ロットNo.
       ,gt_maker_date(item_cnt)                         -- 製造日
       ,gt_limit_date(item_cnt)                         -- 賞味期限
       ,gt_proper_mark(item_cnt)                        -- 固有記号
       ,gt_case_amt(item_cnt)                           -- 棚卸ケース数
       ,gt_content(item_cnt)                            -- 入数
       ,gt_loose_amt(item_cnt)                          -- 棚卸バラ
       ,gt_location(item_cnt)                           -- ロケーション
       ,gt_rack_no1(item_cnt)                           -- ラックNo１
       ,gt_rack_no2(item_cnt)                           -- ラックNo２
       ,gt_rack_no3(item_cnt)                           -- ラックNo３
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
    -- 関連データ取得 (F-1)
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
    -- ファイルアップロードインタフェースデータ取得 (F-2)
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
    -- 妥当性チェック (F-3)
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
      -- データ登録 (F-4)
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
    -- ファイルアップロードインタフェースデータ削除 (F-5)
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
END xxinv990005c;
/
