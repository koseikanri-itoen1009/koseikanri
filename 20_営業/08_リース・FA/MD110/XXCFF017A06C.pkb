CREATE OR REPLACE PACKAGE BODY APPS.XXCFF017A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A06C (spec)
 * Description      : 資産精算勘定消込リスト
 * MD.050           : 資産精算勘定消込リスト (MD050_CFF_017A06)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_csv             資産台帳情報抽出処理(A-2)、資産精算勘定消込リスト出力処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/06/17    1.0   T.Kobori         main新規作成
 *  2014/07/04    1.1   T.Kobori         項目追加  1.仕入先コード
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  init_err_expt               EXCEPTION;      -- 初期処理エラー
  no_data_warn_expt           EXCEPTION;      -- 対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF017A06C';              -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcff          CONSTANT VARCHAR2(10)  := 'XXCFF';                     -- XXCFF
  -- 日付書式
  cv_format_YMD               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_format_std               CONSTANT VARCHAR2(50)  := 'yyyy/mm/dd hh24:mi:ss';
  -- 括り文字
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- 文字列括り
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- カンマ
  -- メッセージコード
  cv_msg_cff_00020            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00020';          -- プロファイル取得エラー
  cv_msg_cff_00062            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00062';          -- 対象データ無し
  cv_msg_cff_00092            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00092';          -- 業務処理日付取得エラー
  cv_msg_cff_00220            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00220';          -- 入力パラメータ
  cv_msg_cff_00230            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00230';          -- 入力パラメータチェックエラー
  cv_msg_cff_50241            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50241';          -- メッセージ用文字列(資産番号)
  cv_msg_cff_50010            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50010';          -- メッセージ用文字列(物件コード)
  cv_msg_cff_50274            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50274';          -- メッセージ用文字列(会社コード)
  cv_msg_cff_50276            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50276';          -- メッセージ用文字列(仕入先コード)
  cv_msg_cff_50242            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50242';          -- メッセージ用文字列(摘要)
  cv_msg_cff_50247            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50247';          -- メッセージ用文字列(事業供用日 FROM)
  cv_msg_cff_50248            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50248';          -- メッセージ用文字列(事業供用日 TO)
  cv_msg_cff_50244            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50244';          -- メッセージ用文字列(取得価格 FROM)
  cv_msg_cff_50245            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50245';          -- メッセージ用文字列(取得価格 TO)
  cv_msg_cff_50270            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50270';          -- メッセージ用文字列(資産勘定)
  cv_msg_cff_50271            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50271';          -- 資産台帳CSV出力ヘッダノート
  cv_msg_cff_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- 対象件数メッセージ
  cv_msg_cff_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- 成功件数メッセージ
  cv_msg_cff_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- エラー件数メッセージ
  cv_msg_cff_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';          -- スキップ件数メッセージ
  cv_msg_cff_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- 正常終了メッセージ
  cv_msg_cff_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- 警告メッセージ
  cv_msg_cff_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバックメッセージ
  -- トークン
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- 入力パラメータ名
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- 入力パラメータ値
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';                 -- プロファイル名
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- 件数
  -- プロファイル名
  cv_prof_fixed_assets_books  CONSTANT VARCHAR2(50)  := 'XXCFF1_FIXED_ASSETS_BOOKS'; -- 台帳名
  -- 固定値
  cv_language_ja              CONSTANT VARCHAR2(2)   := 'JA';                        -- 日本語
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_asset_number                    FA_ADDITIONS_B.ASSET_NUMBER%TYPE;         -- 資産番号
  gt_object_code                     FA_ADDITIONS_B.TAG_NUMBER%TYPE;           -- 物件コード
  gt_segment1                        GL_CODE_COMBINATIONS.SEGMENT1%TYPE;       -- 会社コード
  gt_vendor_code                     PO_VENDORS.SEGMENT1%TYPE;                 -- 仕入先コード
  gt_description                     FA_ADDITIONS_TL.DESCRIPTION%TYPE;         -- 摘要
  gd_date_placed_in_service_from     DATE;                                     -- 事業供用日 FROM
  gd_date_placed_in_service_to       DATE;                                     -- 事業供用日 TO
  gt_original_cost_from              FA_BOOKS.ORIGINAL_COST%TYPE;              -- 取得価格 FROM
  gt_original_cost_to                FA_BOOKS.ORIGINAL_COST%TYPE;              -- 取得価格 TO
  gt_segment3                        FA_CATEGORIES_VL.SEGMENT3%TYPE;           -- 資産科目
  gt_book_type_code                  FA_BOOKS.BOOK_TYPE_CODE%TYPE;             -- 台帳名
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 資産台帳情報取得カーソル
  CURSOR get_fa_books_info_cur
  IS
    SELECT
        fab.asset_number           AS asset_number                         -- 資産番号
       ,fab.tag_number             AS tag_number                           -- 物件コード
       ,gcc.segment1               AS segment1                             -- 本社工場
 -- 2014/07/04 ADD START
       ,vohd.vendor_code           AS vendor_code                          -- 仕入先コード
 -- 2014/07/04 ADD END
       ,fat.description            AS description                          -- 摘要
       ,fb.date_placed_in_service  AS date_placed_in_service               -- 事業供用日
       ,fb.original_cost           AS original_cost                        -- 取得価格
    FROM
        APPS.FA_ADDITIONS_B fab                                            -- 資産詳細情報
       ,APPS.FA_BOOKS fb                                                   -- 資産台帳情報
       ,APPS.FA_ADDITIONS_TL fat                                           -- 資産摘要情報
       ,APPS.FA_DISTRIBUTION_HISTORY fdh                                   -- 資産割当履歴情報
       ,APPS.FA_CATEGORIES_VL fcv                                          -- 資産カテゴリマスタビュー
       ,APPS.GL_CODE_COMBINATIONS gcc                                      -- GL組合せ
 -- 2014/07/04 ADD START
       ,xxcff_vd_object_headers vohd                                       -- 自販機物件管理
 -- 2014/07/04 ADD END
    WHERE fab.ASSET_ID = fb.ASSET_ID                                   -- 資産番号ID
    AND fat.ASSET_ID = fab.ASSET_ID                                    -- 資産番号ID
    AND fab.asset_id = fdh.asset_id                                    -- 資産番号ID
    AND fat.LANGUAGE = cv_language_ja                                  -- 言語
    AND fb.BOOK_TYPE_CODE = gt_book_type_code                          -- プロファイル値（'固定資産台帳'）
    AND fcv.CATEGORY_ID = fab.ASSET_CATEGORY_ID                        -- 資産カテゴリID
    AND fb.DATE_INEFFECTIVE IS NULL                                    -- 無効日
    AND fcv.DATE_INEFFECTIVE IS NULL                                   -- 無効日
    AND fdh.date_ineffective IS NULL                                   -- 無効日
    AND gcc.code_combination_id  = fdh.code_combination_id             -- 組合せID
 -- 2014/07/04 ADD START
    AND fab.tag_number = vohd.object_code (+)                          -- 物件コード
 -- 2014/07/04 ADD END
    AND fab.asset_number               = NVL(gt_asset_number,fab.asset_number)       -- 資産番号
    AND (  gt_object_code IS NULL
        OR fab.tag_number              = gt_object_code            -- 物件コード
        )
    AND (  gt_segment1 IS NULL
        OR gcc.segment1                = gt_segment1               -- 会社コード
        )
 -- 2014/07/04 ADD START
    AND (  gt_vendor_code IS NULL
        OR vohd.vendor_code            = gt_vendor_code            -- 仕入先コード
        )
 -- 2014/07/04 ADD END
    AND (  gt_description IS NULL
        OR fat.description             LIKE gt_description         -- 摘要
        )
    AND fb.date_placed_in_service     >= NVL(gd_date_placed_in_service_from,fb.date_placed_in_service)   -- 事業供用日 FROM
    AND fb.date_placed_in_service     <= NVL(gd_date_placed_in_service_to,fb.date_placed_in_service)     -- 事業供用日 TO
    AND fb.original_cost              >= NVL(gt_original_cost_from,fb.original_cost)                     -- 取得価格 FROM
    AND fb.original_cost              <= NVL(gt_original_cost_to,fb.original_cost)                       -- 取得価格 TO
    AND fcv.segment3                   = NVL(gt_segment3,fcv.segment3)                                   -- 資産科目
    ORDER BY tag_number           -- 物件コード
            ,asset_number         -- 資産番号
    ;
    -- 資産台帳情報カーソルレコード型
    get_fa_books_info_rec get_fa_books_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_asset_number                 IN  VARCHAR2      -- 1.資産番号
   ,iv_object_code                  IN  VARCHAR2      -- 2.物件コード
   ,iv_segment1                     IN  VARCHAR2      -- 3.会社コード
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN  VARCHAR2      -- 10.仕入先コード
 -- 2014/07/04 ADD END
   ,iv_description                  IN  VARCHAR2      -- 4.摘要
   ,iv_date_placed_in_service_from  IN  DATE          -- 5.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN  DATE          -- 6.事業供用日 TO
   ,iv_original_cost_from           IN  VARCHAR2      -- 7.取得価格 FROM
   ,iv_original_cost_to             IN  VARCHAR2      -- 8.取得価格 TO
   ,iv_segment3                     IN  VARCHAR2      -- 9.資産勘定
   ,ov_errbuf                       OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    lv_param_name1                  VARCHAR2(1000);  -- 入力パラメータ名1
    lv_param_name2                  VARCHAR2(1000);  -- 入力パラメータ名2
    lv_param_name3                  VARCHAR2(1000);  -- 入力パラメータ名3
    lv_param_name4                  VARCHAR2(1000);  -- 入力パラメータ名4
    lv_param_name5                  VARCHAR2(1000);  -- 入力パラメータ名5
    lv_param_name6                  VARCHAR2(1000);  -- 入力パラメータ名6
    lv_param_name7                  VARCHAR2(1000);  -- 入力パラメータ名7
    lv_param_name8                  VARCHAR2(1000);  -- 入力パラメータ名8
    lv_param_name9                  VARCHAR2(1000);  -- 入力パラメータ名9
 -- 2014/07/04 ADD START
    lv_param_name10                 VARCHAR2(1000);  -- 入力パラメータ名10
 -- 2014/07/04 ADD END
    lv_asset_number                 VARCHAR2(1000);  -- 1.資産番号
    lv_object_code                  VARCHAR2(1000);  -- 2.物件コード
    lv_segment1                     VARCHAR2(1000);  -- 3.会社コード
    lv_description                  VARCHAR2(1000);  -- 4.摘要
    lv_date_placed_in_service_from  VARCHAR2(1000);  -- 5.事業供用日 FROM
    lv_date_placed_in_service_to    VARCHAR2(1000);  -- 6.事業供用日 TO
    lv_original_cost_from           VARCHAR2(1000);  -- 7.取得価格 FROM
    lv_original_cost_to             VARCHAR2(1000);  -- 8.取得価格 TO
    lv_segment3                     VARCHAR2(1000);  -- 9.資産勘定
 -- 2014/07/04 ADD START
    lv_vendor_code                  VARCHAR2(1000);  -- 10.仕入先コード
 -- 2014/07/04 ADD END
    lv_csv_header                   VARCHAR2(5000);  -- CSVヘッダ項目出力用
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
    -- 0.入力パラメータ格納
    --==============================================================
    gt_asset_number                 := iv_asset_number;                           --1.資産番号
    gt_object_code                  := iv_object_code;                            --2.物件コード
    gt_segment1                     := iv_segment1;                               --3.会社コード
    gt_description                  := iv_description;                            --4.摘要
    gd_date_placed_in_service_from  := iv_date_placed_in_service_from;            --5.事業供用日 FROM
    gd_date_placed_in_service_to    := iv_date_placed_in_service_to;              --6.事業供用日 TO
    gt_original_cost_from           := TO_NUMBER(iv_original_cost_from);          --7.取得価格 FROM
    gt_original_cost_to             := TO_NUMBER(iv_original_cost_to);            --8.取得価格 TO
    gt_segment3                     := iv_segment3;                               --9.資産勘定
 -- 2014/07/04 ADD START
    gt_vendor_code                     := iv_vendor_code;                               --10.仕入先コード
 -- 2014/07/04 ADD END
--
    --==============================================================
    -- 1.入力パラメータ出力
    --==============================================================
    -- 1.資産番号
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50241               -- メッセージコード
                      );
    lv_asset_number := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name1                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_asset_number                -- トークン値2
                      );
--
    -- 2.物件コード
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50010               -- メッセージコード
                      );
    lv_object_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name2                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_object_code                 -- トークン値2
                      );
--
    -- 3.会社コード
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50274               -- メッセージコード
                      );
    lv_segment1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name3                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_segment1                    -- トークン値2
                      );
--
    -- 4.摘要
    lv_param_name4 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50242               -- メッセージコード
                      );
    lv_description := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name4                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_description                 -- トークン値2
                      );
--
    -- 5.事業供用日 FROM
    lv_param_name5 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50247               -- メッセージコード
                      );
    lv_date_placed_in_service_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name5                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_date_placed_in_service_from -- トークン値2
                      );
--
    -- 6.事業供用日 TO
    lv_param_name6 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50248               -- メッセージコード
                      );
    lv_date_placed_in_service_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name6                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_date_placed_in_service_to   -- トークン値2
                      );
--
    -- 7.取得価格 FROM
    lv_param_name7 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50244               -- メッセージコード
                      );
    lv_original_cost_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name7                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_original_cost_from          -- トークン値2
                      );
--
    -- 8.取得価格 TO
    lv_param_name8 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50245               -- メッセージコード
                      );
    lv_original_cost_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name8                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_original_cost_to            -- ト ークン値2
                      );
--
    -- 9.資産勘定
    lv_param_name9 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50270               -- メッセージコード
                      );
    lv_segment3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name9                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_segment3                    -- トークン値2
                      );
--
 -- 2014/07/04 ADD START
    -- 10.仕入先コード
    lv_param_name10 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50276               -- メッセージコード
                      );
    lv_vendor_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name10                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_vendor_code                    -- トークン値2
                      );
 -- 2014/07/04 ADD END
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''                             || CHR(10) ||
                 lv_asset_number                || CHR(10) ||      -- 1.資産番号
                 lv_object_code                 || CHR(10) ||      -- 2.物件コード
                 lv_segment1                    || CHR(10) ||      -- 3.会社コード
 -- 2014/07/04 ADD START
                 lv_vendor_code                 || CHR(10) ||      -- 10.仕入先コード
 -- 2014/07/04 ADD END
                 lv_description                 || CHR(10) ||      -- 4.摘要
                 lv_date_placed_in_service_from || CHR(10) ||      -- 5.事業供用日 FROM
                 lv_date_placed_in_service_to   || CHR(10) ||      -- 6.事業供用日 TO
                 lv_original_cost_from          || CHR(10) ||      -- 7.取得価格 FROM
                 lv_original_cost_to            || CHR(10) ||      -- 8.取得価格 TO
                 lv_segment3                    || CHR(10)         -- 9.資産勘定
    );
--
    --==================================================
    -- 2.プロファイル値取得
    --==================================================
    gt_book_type_code := FND_PROFILE.VALUE( cv_prof_fixed_assets_books );
    -- プロファイルの取得に失敗した場合はエラー
    IF( gt_book_type_code IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcff         -- アプリケーション短縮名
         ,iv_name         => cv_msg_cff_00020           -- メッセージコード
         ,iv_token_name1  => cv_tkn_prof_name           -- トークンコード1
         ,iv_token_value1 => cv_prof_fixed_assets_books -- トークン値1
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.入力パラメータ有無チェック
    --==================================================
    -- 入力パラメータが全て未入力の場合はエラー
    IF( gt_asset_number                IS NULL AND     -- 1.資産番号
        gt_object_code                 IS NULL AND     -- 2.物件コード
        gt_segment1                    IS NULL AND     -- 3.会社コード
 -- 2014/07/04 ADD START
        gt_vendor_code                 IS NULL AND     -- 10.仕入先コード
 -- 2014/07/04 ADD END
        gt_description                 IS NULL AND     -- 4.摘要
        gd_date_placed_in_service_from IS NULL AND     -- 5.事業供用日 FROM
        gd_date_placed_in_service_to   IS NULL AND     -- 6.事業供用日 TO
        gt_original_cost_from          IS NULL AND     -- 7.取得価格 FROM
        gt_original_cost_to            IS NULL AND     -- 8.取得価格 TO
        gt_segment3                    IS NULL )       -- 9.資産勘定
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcff   -- アプリケーション短縮名
         ,iv_name         => cv_msg_cff_00230     -- メッセージコード
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 4.CSVヘッダ項目出力
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcff   -- アプリケーション短縮名
                    ,iv_name         => cv_msg_cff_50271     -- メッセージコード
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : 資産台帳情報抽出処理(A-2)、資産精算勘定消込リスト出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_op_str            VARCHAR2(5000)  := NULL;   -- 出力文字列格納用変数
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 資産台帳情報抽出処理(A-2)
    -- ===============================
    << fa_books_info_loop >>
    FOR get_fa_books_info_rec IN get_fa_books_info_cur
    LOOP
      -- ===============================
      -- CSVファイル出力(A-3)
      -- ===============================
      -- 対象件数
      gn_target_cnt := gn_target_cnt + 1;
--
      --出力文字列作成
      lv_op_str :=                          cv_dqu || get_fa_books_info_rec.asset_number           || cv_dqu ;   -- 資産番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.tag_number             || cv_dqu ;   -- 物件コード
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.segment1               || cv_dqu ;   -- 会社コード
 -- 2014/07/04 ADD START
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.vendor_code            || cv_dqu ;   -- 仕入先コード
 -- 2014/07/04 ADD END
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.description            || cv_dqu ;   -- 摘要
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.date_placed_in_service || cv_dqu ;   -- 事業供用日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.original_cost          || cv_dqu ;   -- 取得価格
--
      -- ===============================
      -- 2.CSVファイル出力
      -- ===============================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- 成功件数
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP fa_books_info_loop;
--
    -- 対象データなし警告
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcff
                      ,iv_name         => cv_msg_cff_00062
                     );
      ov_errbuf  := gv_out_msg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_asset_number                 IN  VARCHAR2     -- 1.資産番号
   ,iv_object_code                  IN  VARCHAR2     -- 2.物件コード
   ,iv_segment1                     IN  VARCHAR2     -- 3.会社コード
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 10.仕入先コード
 -- 2014/07/04 ADD END
   ,iv_description                  IN  VARCHAR2     -- 4.摘要
   ,iv_date_placed_in_service_from  IN  DATE         -- 5.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN  DATE         -- 6.事業供用日 TO
   ,iv_original_cost_from           IN  VARCHAR2     -- 7.取得価格 FROM
   ,iv_original_cost_to             IN  VARCHAR2     -- 8.取得価格 TO
   ,iv_segment3                     IN  VARCHAR2     -- 9.資産勘定
   ,ov_errbuf                       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_asset_number                => iv_asset_number                -- 1.資産番号
     ,iv_object_code                 => iv_object_code                 -- 2.物件コード
     ,iv_segment1                    => iv_segment1                    -- 3.会社コード
 -- 2014/07/04 ADD START
     ,iv_vendor_code                 => iv_vendor_code                 -- 10.仕入先コード
 -- 2014/07/04 ADD END
     ,iv_description                 => iv_description                 -- 4.摘要
     ,iv_date_placed_in_service_from => iv_date_placed_in_service_from -- 5.事業供用日 FROM
     ,iv_date_placed_in_service_to   => iv_date_placed_in_service_to   -- 6.事業供用日 TO
     ,iv_original_cost_from          => iv_original_cost_from          -- 7.取得価格 FROM
     ,iv_original_cost_to            => iv_original_cost_to            -- 8.取得価格 TO
     ,iv_segment3                    => iv_segment3                    -- 9.資産勘定
     ,ov_errbuf                      => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
     ,ov_retcode                     => lv_retcode                     -- リターン・コード             --# 固定 #
     ,ov_errmsg                      => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 資産台帳情報抽出処理(A-2)、資産精算勘定消込リスト出力処理(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE no_data_warn_expt;
    END IF;
--
  EXCEPTION
    -- 対象データなし警告
    WHEN no_data_warn_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf                          OUT VARCHAR2     -- エラー・メッセージ  --# 固定 #
   ,retcode                         OUT VARCHAR2     -- リターン・コード    --# 固定 #
   ,iv_asset_number                 IN  VARCHAR2     -- 1.資産番号
   ,iv_object_code                  IN  VARCHAR2     -- 2.物件コード
   ,iv_segment1                     IN  VARCHAR2     -- 3.会社コード
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 10.仕入先コード
 -- 2014/07/04 ADD END
   ,iv_description                  IN  VARCHAR2     -- 4.摘要
   ,iv_date_placed_in_service_from  IN  VARCHAR2     -- 5.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN  VARCHAR2     -- 6.事業供用日 TO
   ,iv_original_cost_from           IN  VARCHAR2     -- 7.取得価格 FROM
   ,iv_original_cost_to             IN  VARCHAR2     -- 8.取得価格 TO
   ,iv_segment3                     IN  VARCHAR2     -- 9.資産勘定
  )
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_asset_number                => iv_asset_number                    -- 1.資産番号
      ,iv_object_code                 => iv_object_code                     -- 2.物件コード
      ,iv_segment1                    => iv_segment1                        -- 3.会社コード
 -- 2014/07/04 ADD START
      ,iv_vendor_code                 => iv_vendor_code                     -- 10.仕入先コード
 -- 2014/07/04 ADD END
      ,iv_description                 => iv_description                     -- 4.摘要
      ,iv_date_placed_in_service_from => TO_DATE(iv_date_placed_in_service_from,cv_format_std)
                                                                            -- 5.事業供用日 FROM
      ,iv_date_placed_in_service_to   => TO_DATE(iv_date_placed_in_service_to,cv_format_std)
                                                                            -- 6.事業供用日 TO
      ,iv_original_cost_from          => iv_original_cost_from              -- 7.取得価格 FROM
      ,iv_original_cost_to            => iv_original_cost_to                -- 8.取得価格 TO
      ,iv_segment3                    => iv_segment3                        -- 9.資産勘定
      ,ov_errbuf                      => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode                     => lv_retcode                     -- リターン・コード             --# 固定 #
      ,ov_errmsg                      => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- 対象件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- 成功件数出力
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- エラー件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_msg_cff_90004;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_msg_cff_90005;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_msg_cff_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error)
    THEN
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
END XXCFF017A06C;
/
