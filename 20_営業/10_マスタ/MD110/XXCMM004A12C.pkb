CREATE OR REPLACE PACKAGE BODY      APPS.XXCMM004A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A12C(body)
 * Description      : 品目マスタIF出力（HHT）
 *                      営業品目として登録された品目（カテゴリマスタの商品製品区分が2:製品）のみを抽出し、
 *                      HHT向けのCSVファイルを提供します。
 * MD.050           : 品目マスタIF出力（HHT） CMM_004_A12
 * Version          : 1.11
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            初期処理(A-1)
 *
 *  submain              メイン処理プロシージャ
 *                          ・proc_init
 *                       品目情報の取得(A-2)
 *                       品目マスタ（HHT）出力処理(A-3)
 *
 *  main                 コンカレント実行ファイル登録プロシージャ
 *                          ・submain
 *                       終了処理(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   R.Takigawa       main新規作成
 *  2009/01/28    1.1   R.Takigawa       対象データなしエラーを削除
 *                                       更新日時書式の桁数を修正
 *                                       品目機能定数共通化
 *  2009/01/30    1.2   R.Takigawa       エラーメッセージのトークン値指定無しを修正
 *  2009/02/05    1.3   R.Takigawa       TE070不具合修正
 *  2009/02/10    1.4   R.Takigawa       出力結果、ログに対象期間の表示
 *  2009/02/10    1.5   R.Takigawa       先頭２桁(00)をカット(品目コード)
 *  2009/02/16    1.6   K.Ito            OUTBOUND用CSVファイル作成場所、ファイル名共通化
 *                                       ファイル名を出力するように修正
 *                                       コンカレントパラメータの値セット変更(XXCMN_S_10_DATE -> XXCMN_YYYYMMDD) パラメータ結果に時分秒除外
 *  2009/04/02    1.7   Y.Kuboshima      障害T1_0153,T1_0154の対応
 *  2009/05/22    1.8   H.Yoshikawa      障害T1_0317の対応 製品商品区分の条件削除し
 *                                                         品目コードの先導２桁が「00」に変更
 *  2009/09/03    1.9   Y.Kuboshima      障害0001255の対応 メインカーソルにヒント句を追加
 *  2017/08/29    1.10  S.Niki           E_本稼動_14486の対応
 *  2019/07/30    1.11  N.Abe            E_本稼動_15472 軽減税率対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error              CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --WHOカラム
  cn_created_by                CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date             CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by           CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date          CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login         CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id    CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date       CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                  CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                  CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                   VARCHAR2(2000);
  gv_sep_msg                   VARCHAR2(2000);
  gv_exec_user                 VARCHAR2(100);
  gv_conc_name                 VARCHAR2(30);
  gv_conc_status               VARCHAR2(30);
  gn_target_cnt                NUMBER;                    -- 対象件数
  gn_normal_cnt                NUMBER;                    -- 正常件数
  gn_error_cnt                 NUMBER;                    -- エラー件数
  gn_warn_cnt                  NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt          EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt              EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt       EXCEPTION;
  global_check_lock_expt       EXCEPTION;                 -- ロック取得エラー
  --
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(30)  := 'XXCMM004A12C';        -- パッケージ名
-- Ver1.6 Mod 20090216 START
  cv_appl_name_xxcmm    CONSTANT VARCHAR2(5)   := 'XXCMM';               -- アプリケーション短縮名
--  cv_app_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';               -- アプリケーション短縮名
-- Ver1.6 Mod 20090216 END
  -- メッセージ
-- Ver1.1
--  cv_msg_xxcmm_00001    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';    -- 対象データなし
-- End1.1
  cv_msg_xxcmm_00002    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';    -- プロファイル取得エラー
  cv_msg_xxcmm_00019    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';    -- 対象期間指定エラー
--
-- Ver1.6 Add 20090216
  cv_msg_xxcmm_00022    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';    -- CSVファイル名ノート
--
-- Ver1.4 Add 対象期間の表示 2009/2/10
  cv_msg_xxcmm_00473    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00473';    -- 入力パラメータ
-- End1.4
-- Ver1.3 Mod CSVファイル存在エラーの変更 2009/2/5
  --cv_msg_xxcmm_00484    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00484';    -- CSVファイル存在エラー
  cv_msg_xxcmm_00490    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00490';    -- CSVファイル存在エラー
-- End1.3
  cv_msg_xxcmm_00487    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00487';    -- ファイルオープンエラー
  cv_msg_xxcmm_00488    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00488';    -- ファイル書き込みエラー
  cv_msg_xxcmm_00489    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00489';    -- ファイルクローズエラー
--
  -- トークン
  cv_tkn_profile        CONSTANT VARCHAR2(10)  := 'NG_PROFILE';          -- トークン：プロファイル名
  cv_tkn_sqlerrm        CONSTANT VARCHAR2(10)  := 'SQLERRM';             -- トークン：SQLエラー
  cv_tkn_start_date     CONSTANT VARCHAR2(10)  := 'START_DATE';          -- トークン：対象期間指定エラー（開始）
  cv_tkn_last_date      CONSTANT VARCHAR2(10)  := 'LAST_DATE';           -- トークン：対象期間指定エラー（終了）
-- Ver1.4 Add 対象期間の表示 2009/2/10
  cv_tkn_name           CONSTANT VARCHAR2(10)  := 'NAME';                -- トークン：NAME
  cv_tkn_value          CONSTANT VARCHAR2(10)  := 'VALUE';               -- トークン：VALUE
-- Ver1.6 Add 20090216
  cv_tkn_file_name      CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- トークン：SQLエラー
--
  -- 入力項目
  cv_inp_date_from      CONSTANT VARCHAR2(30)  := '対象期間開始';        -- 対象期間開始
  cv_inp_date_to        CONSTANT VARCHAR2(30)  := '対象期間終了';        -- 対象期間終了
-- End1.4
-- Ver1.1
--  cv_date_format_all    CONSTANT VARCHAR2(20)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_format_all    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
-- End                                                                   -- 更新日時書式
  cv_date_fmt_ymd       CONSTANT VARCHAR2(10)  := 'YYYYMMDD';            -- 日付書式
-- Ver1.4 Add 対象期間の表示 2009/2/10
  cv_date_fmt_std         CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                         -- 日付書式
-- End1.4
-- Ver1.6 Mod 20090216
  cv_csv_fl_name        CONSTANT VARCHAR2(30)  := 'XXCMM1_004A12_OUT_FILE';
--  cv_csv_fl_name        CONSTANT VARCHAR2(30)  := 'XXCMM1_004A12_CSV_FILE_FIL';
                                                                         -- 品目マスタ（HHT）連携用CSVファイル名
-- Ver1.6 Mod 20090216
  cv_csv_fl_dir         CONSTANT VARCHAR2(30)  := 'XXCMM1_HHT_OUT_DIR';
--  cv_csv_fl_dir         CONSTANT VARCHAR2(30)  := 'XXCMM1_004A12_CSV_FILE_DIR';
                                                                         -- 品目マスタ（HHT）連携用CSVファイル出力先
  cv_user_csv_fl_name   CONSTANT VARCHAR2(100) := '品目マスタ（HHT）連携用CSVファイル名';
                                                                         -- 品目マスタ（HHT）連携用CSVファイル名
  cv_user_csv_fl_dir    CONSTANT VARCHAR2(100) := '品目マスタ（HHT）連携用CSVファイル出力先';
                                                                         -- 品目マスタ（HHT）連携用CSVファイル出力先
  cv_dqu                CONSTANT VARCHAR2(1)   := '"';
  cv_sep                CONSTANT VARCHAR2(1)   := ',';
  cn_tax_rate           CONSTANT NUMBER(4,2)   := 0;                     -- 消費税率
  cv_tax_div            CONSTANT VARCHAR2(1)   := '0';                   -- 税区分
-- Ver1.5 Mod 先頭２桁(00)をカット(品目、親コード) 2009/2/12
  cv_item_code_cut      CONSTANT VARCHAR2(2)   := '00';                  -- 先頭２桁(00)
-- End
  cv_hon_product_class  CONSTANT VARCHAR2(12)  := '本社商品区分';        -- 本社商品区分
  cv_item_product_class CONSTANT VARCHAR2(12)  := '商品製品区分';        -- 商品製品区分
  cv_csv_mode           CONSTANT VARCHAR2(1)   := 'w';                   -- csvファイルオープン時のモード
-- Ver1.8  2009/05/22 Del  商品製品区分の条件を削除
--  cv_product_div        CONSTANT VARCHAR2(1)   := '2';                   -- 製品(2)
--
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  -- 品目マスタIF出力（HHT）レイアウト
  TYPE xxcmm004a12c_rtype IS RECORD
  (
     item_code                  ic_item_mst_b.item_no%TYPE                        -- 品目コード
    ,item_short_name            xxcmn_item_mst_b.item_short_name%TYPE             -- 略称
    ,baracha_div                xxcmm_system_items_b.baracha_div%TYPE             -- バラ茶区分
    ,sell_start_date            VARCHAR2(240)                                     -- 発売開始日【YYYYMMDD】
    ,opt_cost_new               VARCHAR2(240)                                     -- 営業原価（新）
    ,price_new                  VARCHAR2(240)                                     -- 定価（新）
    ,tax_rate                   NUMBER(4,2)                                       -- 消費税率
    ,num_of_cases               VARCHAR2(240)                                     -- ケース入数
    ,hon_product_class          mtl_categories.segment1%TYPE                      -- 本社商品区分
    ,vessel_group               xxcmm_system_items_b.vessel_group%TYPE            -- 容器群
    ,palette_max_cs_qty         xxcmn_item_mst_b.palette_max_cs_qty%TYPE          -- 配数
    ,palette_max_step_qty       xxcmn_item_mst_b.palette_max_step_qty%TYPE        -- パレット当り最大段数
    ,item_status                xxcmm_system_items_b.item_status%TYPE             -- 品目ステータス
    ,tax_div                    VARCHAR2(1)                                       -- 税区分
    ,sales_div                  VARCHAR2(240)                                     -- 売上対象区分
    ,jan_code                   VARCHAR2(240)                                     -- JANコード
    ,case_jan_code              xxcmm_system_items_b.case_jan_code%TYPE           -- ケースJANコード
    ,parent_item_code           ic_item_mst_b.item_no%TYPE                        -- 親商品コード
    ,search_update_date         xxcmm_system_items_b.search_update_date%TYPE      -- 検索対象更新日
--Ver1.10 Add
    ,crowd_code                 ic_item_mst_b.attribute2%TYPE                     -- 政策群コード
    ,renewal_item_code          xxcmm_system_items_b.renewal_item_code%TYPE       -- リニューアル元商品コード
--End 1.10
  );
--
  -- 品目マスタIF出力（HHT）レイアウト テーブルタイプ
  TYPE xxcmm004a12c_ttype IS TABLE OF xxcmm004a12c_rtype INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
    gd_process_date                    DATE;                  -- 業務日付
    gv_csv_file_dir                    VARCHAR2(1000);        -- 品目マスタ（HHT）連携用CSVファイル出力先の取得
    gv_file_name                       VARCHAR2(30);          -- 品目マスタ（HHT）連携用CSVファイル名
    gf_file_hand                       UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
    --
    gd_date_from                       DATE;                  -- 対象期間（開始）
    gd_date_to                         DATE;                  -- 対象期間（終了）
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
     iv_date_from  IN  VARCHAR2             --   最終更新日（開始）
    ,iv_date_to    IN  VARCHAR2             --   最終更新日（終了）
    ,ov_errbuf     OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2             --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2             --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
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
    lv_step                            VARCHAR2(100);         -- ステップ
    lv_message_token                   VARCHAR2(100);         -- メッセージトークン
    lb_fexists                         BOOLEAN;               -- ファイル存在判断
    ln_file_length                     NUMBER;                -- ファイルの文字列数
    lbi_block_size                     BINARY_INTEGER;        -- ブロックサイズ
    --
-- Ver1.6 Del 20090216
---- Ver1.4 Add 対象期間の表示 2009/2/10
--    lv_date_output                     VARCHAR2(100);         -- 対象期間表示
---- End1.4
    ld_date_from                       DATE;                  -- 対象期間（開始）
    ld_date_to                         DATE;                  -- 対象期間（終了）
-- Ver1.6 Add 20090216
    lv_prm_date                        VARCHAR2(1000);        -- パラメータ出力用変数
    lv_csv_file                        VARCHAR2(1000);        -- csvファイル名
    --
    -- *** ユーザー定義例外 ***
    object_term_expt                   EXCEPTION;             -- 対象期間指定エラー
    profile_expt                       EXCEPTION;             -- プロファイル取得例外
    csv_file_exst_expt                 EXCEPTION;             -- CSVファイル存在エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-1 初期処理
    --==============================================================
    --==============================================================
    --A-1.1 業務日付取得
    --==============================================================
    lv_step := 'A-1.1';
    lv_message_token := '業務日付の取得';
    gd_process_date  := xxccp_common_pkg2.get_process_date;
    --
    --==============================================================
    --A-1.2 対象期間チェック
    --==============================================================
    lv_step := 'A-1.2';
    lv_message_token := '対象期間チェック';
    ld_date_from := NVL( FND_DATE.CANONICAL_TO_DATE( iv_date_from ), gd_process_date );      -- 対象期間（開始）
    ld_date_to   := NVL( FND_DATE.CANONICAL_TO_DATE( iv_date_to   ), gd_process_date );      -- 対象期間（終了）
    --
-- Ver1.6 Mod 20090216 START
---- Ver1.4 Add 対象期間の表示 2009/2/10
--    -- 対象期間開始
--    lv_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_appl_name_xxcmm,
--                   iv_name         => cv_msg_xxcmm_00473,
--                   iv_token_name1  => cv_tkn_name,
--                   iv_token_value1 => cv_inp_date_from,
--                   iv_token_name2  => cv_tkn_value,
---- Ver1.5 入力パラメータの表示 2009/2/13
----                   iv_token_value2 => TO_CHAR( ld_date_from, cv_date_fmt_std )
--                   iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_from ), cv_date_fmt_std )
---- End1.5
--                 );
--    -- 出力表示
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => lv_errmsg
--    );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.LOG,
--      buff   => lv_errmsg
--    );
--    -- 対象期間終了
--    lv_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_appl_name_xxcmm,
--                   iv_name         => cv_msg_xxcmm_00473,
--                   iv_token_name1  => cv_tkn_name,
--                   iv_token_value1 => cv_inp_date_to,
--                   iv_token_name2  => cv_tkn_value,
---- Ver1.5 入力パラメータの表示 2009/2/13
----                   iv_token_value2 => TO_CHAR( ld_date_to, cv_date_fmt_std )
--                   iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_to ), cv_date_fmt_std )
---- End1.5
--                 );
--    -- 出力表示
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => lv_errmsg
--    );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.LOG,
--      buff   => lv_errmsg
--    );
---- End1.4
    -- 対象期間開始
    lv_prm_date := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm,
                     iv_name         => cv_msg_xxcmm_00473,
                     iv_token_name1  => cv_tkn_name,
                     iv_token_value1 => cv_inp_date_from,
                     iv_token_name2  => cv_tkn_value,
                     iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_from ), cv_date_fmt_std )
                   );
    -- 対象期間開始出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_prm_date
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    --
    -- 対象期間終了
    lv_prm_date := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm,
                     iv_name         => cv_msg_xxcmm_00473,
                     iv_token_name1  => cv_tkn_name,
                     iv_token_value1 => cv_inp_date_to,
                     iv_token_name2  => cv_tkn_value,
                     iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_to ), cv_date_fmt_std )
                   );
    -- 対象期間終了出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_prm_date
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
-- Ver1.6 Mod 20090216 END
    --
    IF ( ld_date_from > ld_date_to ) THEN
      RAISE object_term_expt;
    END IF;
    --
    gd_date_from := ld_date_from;                  -- 対象期間（開始）
    gd_date_to   := ld_date_to;                    -- 対象期間（終了）
    --
    --==============================================================
    --A-1.3 プロファイルの取得
    --==============================================================
    lv_step := 'A-1.3a';
    -- 品目マスタ（HHT）連携用CSVファイル名の取得
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- 取得エラー時
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_name;
      RAISE profile_expt;
    END IF;
    --
-- Ver1.6 Mod 20090216 START
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- アップロード名称の出力
                    iv_application  => cv_appl_name_xxcmm                       -- アプリケーション短縮名
                   ,iv_name         => cv_msg_xxcmm_00022                       -- メッセージコード
                   ,iv_token_name1  => cv_tkn_file_name                         -- トークンコード1
                   ,iv_token_value1 => gv_file_name                             -- トークン値1
                  );
    -- ファイル名出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_csv_file
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
-- Ver1.6 Mod 20090216 END
    --
    lv_step := 'A-1.3b';
    -- 品目マスタ（HHT）連携用CSVファイル出力先の取得
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- 取得エラー時
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_dir;
      RAISE profile_expt;
    END IF;
    --
    --==============================================================
    --A-1.4 CSVファイル存在チェック
    --==============================================================
    lv_step := 'A-1.4';
    lv_message_token := 'CSVファイル存在チェック';
    -- CSVファイル存在チェック
    UTL_FILE.FGETATTR(
       location    => gv_csv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_fexists
      ,file_length => ln_file_length
      ,block_size  => lbi_block_size
    );
    -- ファイル存在時
    IF ( lb_fexists = TRUE ) THEN
      RAISE csv_file_exst_expt;
    END IF;
    --
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    --*** 対象期間指定エラー ***
    WHEN object_term_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00019            -- メッセージ：APP-XXCMM1-00019 対象期間指定エラー
-- Ver1.4 Del 2009/2/10
/*
                     ,iv_token_name1  => cv_tkn_start_date             -- トークンコード1：START_DATE
                     ,iv_token_value1 => TO_CHAR( ld_date_from
                                                 ,cv_date_fmt_ymd )    -- トークン値1    ：対象期間（開始）【ld_date_from】
                     ,iv_token_name2  => cv_tkn_last_date              -- トークンコード2：LAST_DATE
                     ,iv_token_value2 => TO_CHAR( ld_date_to
                                                 ,cv_date_fmt_ymd )    -- トークン値2    ：対象期間（終了）【ld_date_to】
*/
-- End1.4
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00002            -- メッセージ：APP-XXCMM1-00002 プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_profile                -- トークン：NG_PROFILE
                     ,iv_token_value1 => lv_message_token              -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** CSVファイル存在エラー ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名：XXCMM マスタ
-- Ver1.3 Mod CSVCSVファイル存在エラーの変更 2009/2/5
--                     ,iv_name         => cv_msg_xxcmm_00484            -- メッセージ：APP-XXCMM1-00484 CSVファイル存在エラー
                     ,iv_name         => cv_msg_xxcmm_00490            -- メッセージ：APP-XXCMM1-00490 CSVファイル存在エラー
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_date_from   IN     VARCHAR2         --   最終更新日（開始）
    ,iv_date_to     IN     VARCHAR2         --   最終更新日（終了）
    ,ov_errbuf      OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
    ,ov_retcode     OUT    VARCHAR2         --   リターン・コード             --# 固定 #
    ,ov_errmsg      OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                          VARCHAR2(5000);        -- エラー・メッセージ
    lv_retcode                         VARCHAR2(1);           -- リターン・コード
    lv_errmsg                          VARCHAR2(5000);        -- ユーザー・エラー・メッセージ
    lv_step                            VARCHAR2(100);         -- ステップ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザーローカル変数
    -- ===============================
-- Ver1.2
    lv_sqlerrm                         VARCHAR2(5000);        -- エラー・メッセージ
-- End
    lv_message_token                   VARCHAR2(100);         -- メッセージトークン
    ln_data_index                      NUMBER;                -- データ用索引
    lv_out_csv_line                    VARCHAR2(1000);        -- 出力行
    lv_hon_product_class               VARCHAR2(1);           -- 本社商品区分
    --
    -- 品目マスタ（HHT）情報カーソル
    --lv_step := 'A-2.1a';
    CURSOR csv_item_cur
    IS
-- 2009/09/03 Ver1.9 modify start by Yutaka.Kuboshima
--      SELECT      xoiv.item_id                                               -- 品目ID
      SELECT      /*+ FIRST_ROWS USE_NL(xoiv.xsib)*/
                  xoiv.item_id                                               -- 品目ID
-- 2009/09/03 Ver1.9 modify end by Yutaka.Kuboshima
                 ,xoiv.item_no                                               -- 品目コード
--Ver1.3 Mod
--                 ,TO_CHAR( FND_DATE.CANONICAL_TO_DATE( xoiv.sell_start_date ), cv_date_fmt_ymd )
--                             AS sell_start_date                              -- 発売開始日
                 ,xoiv.sell_start_date                                       -- 発売開始日
--End1.3
                 ,xoiv.price_new                                             -- 定価（新）
                 ,xoiv.jan_code                                              -- JANコード
                 ,xoiv.opt_cost_new                                          -- 営業原価（新）
                 ,xoiv.sales_div                                             -- 売上対象区分
                 ,xoiv.num_of_cases                                          -- ケース入数
                 ,xoiv.item_short_name                                       -- 略称
                 ,xoiv.palette_max_cs_qty                                    -- 配数
                 ,xoiv.palette_max_step_qty                                  -- パレット当り最大段数
                 ,xoiv.parent_item_id                                        -- 親品目ID
                 ,xoiv.baracha_div                                           -- バラ茶区分
                 ,xoiv.vessel_group                                          -- 容器群
                 ,xoiv.case_jan_code                                         -- ケースJANコード
--Ver1.3 Add
                 ,parent_iimb.item_no        AS parent_item_code             -- 親商品コード
--End1.3
                 ,xoiv.item_status                                           -- 品目ステータス
                 ,xoiv.search_update_date                                    -- 検索対象更新日
--Ver1.10 Add
                 ,xoiv.crowd_code_new        AS crowd_code                   -- 政策群コード
                 ,xoiv.renewal_item_code     AS renewal_item_code            -- リニューアル元商品コード
--End 1.10
-- Ver1.11 2019/07/30 Add Start
                 ,(SELECT xrtrv.tax_rate
                   FROM   xxcos_reduced_tax_rate_v xrtrv                     -- 品目別消費税率View
                   WHERE  xoiv.item_code                                 = xrtrv.item_code
                   AND    xrtrv.start_date                              <= gd_date_to + 1
                   AND    NVL(xrtrv.end_date, gd_date_to + 1)           >= gd_date_to + 1
                   AND    xrtrv.start_date_histories                    <= gd_date_to + 1
                   AND    NVL(xrtrv.end_date_histories, gd_date_to + 1) >= gd_date_to + 1
                  )                          AS tax_rate                     -- 消費税率
-- Ver1.11 2019/07/30 Add End
      FROM        xxcmm_opmmtl_items_v    xoiv                               --
                 ,ic_item_mst_b           parent_iimb                        -- OPM品目（親品目）
-- Ver1.8  2009/05/22 Del  商品製品区分の条件を削除
--                 ,gmi_item_categories     gic_sales                          -- OPM品目カテゴリ割当（商品製品区分）
--                 ,mtl_category_sets_vl    mcsv_sales                         -- カテゴリセットビュー（商品製品区分）
--                 ,mtl_categories_vl       mcv_sales                          -- カテゴリビュー（商品製品区分）
--      WHERE       xoiv.item_id                 = gic_sales.item_id           -- 商品製品区分
--      AND         gic_sales.category_set_id    = mcsv_sales.category_set_id  -- 商品製品区分
--      AND         gic_sales.category_id        = mcv_sales.category_id       -- 商品製品区分
--      AND         mcsv_sales.category_set_name = cv_item_product_class       -- 商品製品区分
--      AND         mcv_sales.segment1           = cv_product_div              -- カテゴリ．商品製品区分＝２（製品）
-- End
-- Ver1.8  2009/05/22 Add  品目コードの先頭２桁が「00」を対象とするよう条件を追加
      WHERE       SUBSTRB( xoiv.item_no, 1, 2 ) = cv_item_code_cut           -- 品目コードの先頭２桁が「00」
-- End
-- Ver1.4 Mod 親品目が設定されていない品目を抽出対象とするよう修正 2009/2/10
--      AND         xoiv.parent_item_id           = parent_iimb.item_id         -- 親品目ID＝品目ID
      AND         xoiv.parent_item_id           = parent_iimb.item_id(+)     -- 親品目ID＝品目ID
-- End
      AND         xoiv.search_update_date      >= gd_date_from               -- 検索対象更新日 >= 入力パラメータの最終更新日（開始）
      AND         xoiv.search_update_date      <= gd_date_to                 -- 検索対象更新日 <= 入力パラメータの最終更新日（終了）
      AND         xoiv.start_date_active       <= gd_date_to + 1             -- 適用開始日     <= 入力パラメータの最終更新日（終了）＋1日
      AND         xoiv.end_date_active         >= gd_date_to + 1             -- 適用終了日     >= 入力パラメータの最終更新日（終了）＋1日
      ORDER BY    xoiv.item_no;
    --
    l_csv_item_tab                     xxcmm004a12c_ttype;                  -- 商品IF出力データ
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    sub_proc_expt                      EXCEPTION;       -- サブプログラムエラー
    file_open_expt                     EXCEPTION;       -- ファイルオープンエラー
    file_output_expt                   EXCEPTION;       -- ファイル書き込みエラー
    file_close_expt                    EXCEPTION;       -- ファイルクローズエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    -- ===============================================
    -- proc_initの呼び出し（初期処理はproc_initで行う）
    -- ===============================================
    proc_init(
       iv_date_from   => iv_date_from    -- 最終更新日（開始）
      ,iv_date_to     => iv_date_to      -- 最終更新日（終了）
      ,ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --
    -----------------------------------
    -- A-2.品目情報の取得
    -----------------------------------
    lv_step := 'A-2.1b';
    ln_data_index := 0;
    --
    --
    <<csv_item_loop>>
    FOR l_csv_item_rec IN csv_item_cur LOOP
      --
      ln_data_index := ln_data_index + 1;
      --
      BEGIN
        -- 本社商品区分の取得
        SELECT      mcv_hon.segment1  AS hon_product_class                     -- 本社商品区分
        INTO        lv_hon_product_class                                       -- 本社商品区分
        FROM        gmi_item_categories     gic_hon                            -- OPM品目カテゴリ割当（本社商品区分）
                   ,mtl_category_sets_vl    mcsv_hon                           -- カテゴリセットビュー（本社商品区分）
                   ,mtl_categories_vl       mcv_hon                            -- カテゴリビュー（本社商品区分）
        WHERE       mcsv_hon.category_set_name   = cv_hon_product_class        -- 本社商品区分
        AND         gic_hon.item_id              = l_csv_item_rec.item_id      -- 品目
        AND         gic_hon.category_set_id      = mcsv_hon.category_set_id    -- カテゴリセットID
        AND         gic_hon.category_id          = mcv_hon.category_id;        -- カテゴリID
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_hon_product_class := '';
      END;
      --
      -- 配列に設定
-- Ver1.5 Mod 先頭２桁(00)をカット(品目コード) 2009/2/12
--      lv_step := 'A-2.item_code';
--      lv_message_token := '品目コード';
--      l_csv_item_tab( ln_data_index ).item_code            := l_csv_item_rec.item_no;               -- 品目コード
      lv_step := 'A-2.item_code';
      lv_message_token := '品目コード';
--      l_csv_item_tab( ln_data_index ).item_code            := TO_CHAR( TO_NUMBER( l_csv_item_rec.item_no , cv_number_fmt) );
                                                                                                    -- 品目コード
-- Ver1.7 Mod 先頭２桁(00)をカットをしない 2009/04/02 by Y.Kuboshima
--      IF SUBSTRB( l_csv_item_rec.item_no , 1 , 2 ) = cv_item_code_cut THEN
--        l_csv_item_tab( ln_data_index ).item_code            := SUBSTRB( l_csv_item_rec.item_no , 3 );
--      ELSE
--        l_csv_item_tab( ln_data_index ).item_code            := l_csv_item_rec.item_no;
--      END IF;
      l_csv_item_tab( ln_data_index ).item_code            := l_csv_item_rec.item_no;
--End1.7 by Y.Kuboshima
--End
      lv_step := 'A-2.item_short_name';
      lv_message_token := '略称';
      l_csv_item_tab( ln_data_index ).item_short_name      := l_csv_item_rec.item_short_name;       -- 略称
      lv_step := 'A-2.baracha_div';
      lv_message_token := 'バラ茶区分';
      l_csv_item_tab( ln_data_index ).baracha_div          := l_csv_item_rec.baracha_div;           -- バラ茶区分
      lv_step := 'A-2.sell_start_date';
      lv_message_token := '発売開始日';
--Ver1.3 発売開始日のフォーマットを指定 2009/2/5
--      l_csv_item_tab( ln_data_index ).sell_start_date      := l_csv_item_rec.sell_start_date;       -- 発売開始日【YYYYMMDD】
      l_csv_item_tab( ln_data_index ).sell_start_date      := TO_CHAR( l_csv_item_rec.sell_start_date , cv_date_fmt_ymd );       -- 発売開始日【YYYYMMDD】
--End1.3
      lv_step := 'A-2.opt_cost_new';
      lv_message_token := '営業原価（新）';
      l_csv_item_tab( ln_data_index ).opt_cost_new         := TO_CHAR( l_csv_item_rec.opt_cost_new );
                                                                                                    -- 営業原価（新）
      lv_step := 'A-2.price_new';
      lv_message_token := '定価（新）';
      l_csv_item_tab( ln_data_index ).price_new            := TO_CHAR( l_csv_item_rec.price_new );  -- 定価（新）
      lv_step := 'A-2.tax_rate';
      lv_message_token := '消費税率';
-- Ver1.11 2019/07/30 Add Start
--      l_csv_item_tab( ln_data_index ).tax_rate             := cn_tax_rate;                          -- 消費税
      l_csv_item_tab( ln_data_index ).tax_rate             := l_csv_item_rec.tax_rate;              -- 消費税
-- Ver1.11 2019/07/30 Add End
      lv_step := 'A-2.num_of_cases';
      lv_message_token := 'ケース入数';
      l_csv_item_tab( ln_data_index ).num_of_cases         := TO_CHAR( l_csv_item_rec.num_of_cases );
                                                                                                    -- ケース入数
--Ver1.3 Add 本社商品区分を追加
      lv_step := 'A-2.parent_item_code';
      lv_message_token := '本社商品区分';
      l_csv_item_tab( ln_data_index ).hon_product_class    := lv_hon_product_class;  -- 本社商品区分
--End1.3
      lv_step := 'A-2.vessel_group';
      lv_message_token := '容器群';
      l_csv_item_tab( ln_data_index ).vessel_group         := l_csv_item_rec.vessel_group;          -- 容器群
      lv_step := 'A-2.palette_max_cs_qty';
      lv_message_token := '配数';
      l_csv_item_tab( ln_data_index ).palette_max_cs_qty   := l_csv_item_rec.palette_max_cs_qty;    -- 配数
      lv_step := 'A-2.palette_max_step_qty';
      lv_message_token := 'パレット当り最大段数';
      l_csv_item_tab( ln_data_index ).palette_max_step_qty := l_csv_item_rec.palette_max_step_qty;  -- パレット当り最大段数
      lv_step := 'A-2.item_status';
      lv_message_token := '品目ステータス';
      l_csv_item_tab( ln_data_index ).item_status          := l_csv_item_rec.item_status;           -- 品目ステータス
      lv_step := 'A-2.tax_div';
      lv_message_token := '税区分';
      l_csv_item_tab( ln_data_index ).tax_div              := cv_tax_div;                           -- 税区分
      lv_step := 'A-2.sales_div';
      lv_message_token := '売上対象区分';
      l_csv_item_tab( ln_data_index ).sales_div            := l_csv_item_rec.sales_div;             -- 売上対象区分
      lv_step := 'A-2.jan_code';
      lv_message_token := 'JANコード';
      l_csv_item_tab( ln_data_index ).jan_code             := l_csv_item_rec.jan_code;              -- JANコード
      lv_step := 'A-2.case_jan_code';
      lv_message_token := 'ケースJANコード';
      l_csv_item_tab( ln_data_index ).case_jan_code        := l_csv_item_rec.case_jan_code;         -- ケースJANコード
--Ver1.3 Add 親商品コードを追加
-- Ver1.5 Mod 先頭２桁(00)をカット(親コード) 2009/2/12
      lv_step := 'A-2.parent_item_code';
      lv_message_token := '親商品コード';
--      l_csv_item_tab( ln_data_index ).parent_item_code     := l_csv_item_rec.parent_item_code;       -- 親商品コード
-- Ver1.7 Mod 先頭２桁(00)をカットしない 2009/04/02 by Y.Kuboshima
--      IF SUBSTRB( l_csv_item_rec.item_no , 1 , 2 ) = cv_item_code_cut THEN
--          l_csv_item_tab( ln_data_index ).parent_item_code            := SUBSTRB( l_csv_item_rec.parent_item_code , 3 );
--      ELSE
--        l_csv_item_tab( ln_data_index ).parent_item_code            := l_csv_item_rec.parent_item_code;
--      END IF;
      l_csv_item_tab( ln_data_index ).parent_item_code            := l_csv_item_rec.parent_item_code;
--End1.7
--End1.5
--End1.3
      lv_step := 'A-2.search_update_date';
      lv_message_token := '更新日時';
      l_csv_item_tab( ln_data_index ).search_update_date   := l_csv_item_rec.search_update_date;    -- 検索対象更新日
--Ver1.10 Add
      lv_step := 'A-2.crowd_code';
      l_csv_item_tab( ln_data_index ).crowd_code           := l_csv_item_rec.crowd_code;            -- 政策群コード
      lv_step := 'A-2.renewal_item_code';
      l_csv_item_tab( ln_data_index ).renewal_item_code    := l_csv_item_rec.renewal_item_code;     -- リニューアル元商品コード
--End1.10
      --
    END LOOP csv_item_loop;
    --
    --
    -----------------------------------------------
    -- A-3.品目マスタ（HHT）出力処理
    -----------------------------------------------
    lv_step := 'A-3';
-- Ver1.1
/*
    IF ( ln_data_index = 0 ) THEN
      -- 対象データなし
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm
                     ,iv_name         => cv_msg_xxcmm_00001
                     );
      -- 出力表示
      lv_step := 'A-1.5';
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
    ELSE
*/
-- End
      -- CSVファイルオープン
      lv_step := 'A-1.6';
      BEGIN
        gf_file_hand := UTL_FILE.FOPEN(  location  => gv_csv_file_dir  -- 出力先
                                        ,filename  => gv_file_name     -- CSVファイル名
                                        ,open_mode => cv_csv_mode      -- モード
                                       );
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.2
          lv_sqlerrm := SQLERRM;
-- End
          RAISE file_open_expt;
      END;
      -- ファイル出力
      lv_step := 'A-3.1a';
      <<out_csv_loop>>
      FOR ln_index IN 1..l_csv_item_tab.COUNT LOOP
        --
        lv_out_csv_line := '';
        -- 品目コード
        lv_step := 'A-3.item_code';
        lv_out_csv_line := cv_dqu || l_csv_item_tab( ln_index ).item_code || cv_dqu;
        -- 略称
        lv_step := 'A-3.item_short_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).item_short_name || cv_dqu;
        -- バラ茶区分
-- Ver1.5 Mod 2009/2/12
        lv_step := 'A-3.baracha_div';
-- Ver1.7 Mod バラ茶区分はダブルコーテーションで括る 2009/04/02 by Y.Kuboshima
--        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
--          TO_CHAR( l_csv_item_tab( ln_index ).baracha_div || cv_dqu );
--          l_csv_item_tab( ln_index ).baracha_div;
          TO_CHAR( l_csv_item_tab( ln_index ).baracha_div ) || cv_dqu;
-- End1.5
-- End1.7 by Y.Kuboshima
        -- 発売開始日【YYYYMMDD】
        lv_step := 'A-3.sell_start_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          l_csv_item_tab( ln_index ).sell_start_date;
        -- 営業原価（新）
        lv_step := 'A-3.opt_cost_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep || l_csv_item_tab( ln_index ).opt_cost_new;
        -- 定価（新）
        lv_step := 'A-3.price_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep || l_csv_item_tab( ln_index ).price_new;
        -- 消費税率
        lv_step := 'A-3.tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep || TO_CHAR( l_csv_item_tab( ln_index ).tax_rate );
        -- ケース入数
        lv_step := 'A-3.num_of_cases';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          l_csv_item_tab( ln_index ).num_of_cases;
        -- 本社商品区分
        lv_step := 'A-3.hon_product_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).hon_product_class || cv_dqu;
        -- 容器群
        lv_step := 'A-3.vessel_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).vessel_group || cv_dqu;
        -- 配数
        lv_step := 'A-3.palette_max_cs_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          TO_CHAR( l_csv_item_tab( ln_index ).palette_max_cs_qty );
        -- パレット当り最大段数
        lv_step := 'A-3.palette_max_step_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          TO_CHAR( l_csv_item_tab( ln_index ).palette_max_step_qty );
        -- 品目ステータス
        lv_step := 'A-3.item_status';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          TO_CHAR( l_csv_item_tab( ln_index ).item_status ) || cv_dqu;
        -- 税区分
        lv_step := 'A-3.tax_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).tax_div || cv_dqu;
        -- 売上対象区分
        lv_step := 'A-3.sales_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).sales_div || cv_dqu;
        -- JANコード
        lv_step := 'A-3.jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).jan_code || cv_dqu;
        -- ケースJANコード
        lv_step := 'A-3.case_jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).case_jan_code || cv_dqu;
--Ver1.3 Add
        -- 親商品コード
        lv_step := 'A-3.parent_item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).parent_item_code || cv_dqu;
--End1.3
        -- 更新日時【YYYY/MM/DD HH:MM:SS】
-- Ver1.7 Mod 更新日時はダブルコーテーションで括る 2009/04/02 by Y.Kuboshima
        lv_step := 'A-3.search_update_date';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
--          TO_CHAR( l_csv_item_tab( ln_index ).search_update_date , cv_date_format_all );
          TO_CHAR( l_csv_item_tab( ln_index ).search_update_date , cv_date_format_all ) || cv_dqu;
--End1.7 by Y.Kuboshima
--Ver1.10 Add
        -- 政策群コード
        lv_step := 'A-3.crowd_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).crowd_code || cv_dqu;
        -- リニューアル元商品コード
        lv_step := 'A-3.renewal_item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).renewal_item_code || cv_dqu;
--End1.10
        --
        -- CSVファイル出力
        lv_step := 'A-3.1b';
        BEGIN
          UTL_FILE.PUT_LINE( gf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
-- Ver1.2
            lv_sqlerrm := SQLERRM;
-- End
            RAISE file_output_expt;
        END;
        --
        -- 対象件数
        gn_target_cnt := gn_target_cnt + 1;
        -- 成功件数
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      END LOOP out_csv_loop;
      --
      -----------------------------------------------
      -- A-4.終了処理
      -----------------------------------------------
      -- ファイルクローズ
      lv_step := 'A-4.1';
      --
      --ファイルクローズ失敗
      BEGIN
        UTL_FILE.FCLOSE( gf_file_hand );
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.2
            lv_sqlerrm := SQLERRM;
-- End
          RAISE file_close_expt;
      END;
      --
-- Ver1.1
/*
    END IF;
*/
-- End
    --
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- *** サブプログラム例外ハンドラ ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --*** ファイルオープンエラー ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00487             -- メッセージ：APP-XXCMM1-00487 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークンコード：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- トークン値：SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End1.1
      ov_retcode := cv_status_error;
    --*** ファイル書き込みエラー ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00488             -- メッセージ：APP-XXCMM1-00488 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークンコード：SQLERRM
-- Ver1.3 Mod lv_sqlerrmを表示させるように修正
--                     ,iv_token_value1 => SQLERRM                        -- トークン値：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- トークン値：SQLERRM
-- End1.3
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End1.1
      ov_retcode := cv_status_error;
    --*** ファイルクローズエラー ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00489             -- メッセージ：APP-XXCMM1-00489 ファイルクローズエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークンコード：SQLERRM
-- Ver1.3 Mod lv_sqlerrmを表示させるように修正
--                     ,iv_token_value1 => SQLERRM                        -- トークン値：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- トークン値：SQLERRM
-- End1.3
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
        cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
        cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      gn_error_cnt := gn_target_cnt;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
        cv_msg_part||SQLERRM;
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
    errbuf         OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode        OUT    VARCHAR2         --   エラーコード     #固定#
   ,iv_date_from   IN     VARCHAR2         --   最終更新日（開始）
   ,iv_date_to     IN     VARCHAR2         --   最終更新日（終了）
  )
--
--###########################  固定部 START   ###########################
--
  IS
  --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
    cv_log               CONSTANT VARCHAR2(100) := 'LOG';               -- ログ
    cv_output            CONSTANT VARCHAR2(100) := 'OUTPUT';            -- アウトプット
    cv_app_name_xxccp    CONSTANT VARCHAR2(100) := 'XXCCP';             -- アプリケーション短縮名
    cv_target_cnt_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_cnt_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_cnt_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_normal_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- 警告終了メッセージ
    cv_token_name1       CONSTANT VARCHAR2(100) := 'COUNT';             -- 処理件数
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_step                VARCHAR2(10);    -- ステップ
    lv_message_code        VARCHAR2(100);   -- メッセージコード
    --
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
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
       iv_date_from   => iv_date_from    -- 最終更新日（開始）
      ,iv_date_to     => iv_date_to      -- 最終更新日（終了）
      ,ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザーエラーメッセージ
      );
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMM004A12C;
/
