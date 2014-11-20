CREATE OR REPLACE PACKAGE BODY XXCOI008A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A05C(body)
 * Description      : 情報系システムへの連携の為、EBSのVDコラムマスタ(アドオン)をCSVファイルに出力
 * MD.050           : VDコラムマスタ情報系連携 <MD050_COI_008_A05>
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  create_csv_p           VDコラムマスタCSVの作成(A-4)
 *  vd_column_cur_p        VDコラムマスタ情報の抽出(A-3)
 *  submain                メイン処理プロシージャ
 *                           ・ファイルオープン(A-2)
 *                           ・ファイルクローズ(A-5) 
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/24    1.0   S.Kanda          新規作成
 *  2009/06/11    1.1   H.Sasaki         [T1_1416]携抽出対象顧客ステータスを変更
 *  2009/07/13    1.2   H.Sasaki         [0000494]VDコラムマスタ情報取得のPT対応
 *  2009/08/14    1.3   N.Abe            [0000891]VDコラムマスタ情報取得の修正
 *  2009/09/11    1.4   H.Sasaki         [0001352]PT対応（ヒント句leadingを追加）
 *  2009/09/17    1.5   N.Abe            [0001411]VDコラムマスタ物件なし対応
 *  2009/10/21    1.6   N.Abe            [E_最終移行リハ_00502]物件マスタの機器区分を参照する修正
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
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A05C';
  cv_appl_short_name_ccp    CONSTANT VARCHAR2(10)  := 'XXCCP';         -- アドオン：共通・IF領域
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCOI';         -- アドオン：共通・IF領域
  cv_file_slash             CONSTANT VARCHAR2(2)   := '/';             -- ファイル区切り用
  cv_file_encloser          CONSTANT VARCHAR2(2)   := '"';             -- 文字データ括り用
  --
  -- メッセージ定数
  cv_msg_xxcoi_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';
  cv_msg_xxcoi_00004        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';
  cv_msg_xxcoi_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00007';
  cv_msg_xxcoi_00008        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';
  cv_msg_xxcoi_00023        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00023';
  cv_msg_xxcoi_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';
  cv_msg_xxcoi_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';
  cv_msg_xxcoi_00029        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';
  --
  --トークン
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- プロファイル名用
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- プロファイル名用
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- 件数メッセージ用
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- ファイル名用
  -- SQL記述用
  cv_duns_number_90         CONSTANT VARCHAR2(30)  := '90';            -- 顧客ステータス：中止決裁済
-- == 2009/06/11 V1.1 Added START ===============================================================
  cv_duns_number_80         CONSTANT VARCHAR2(30)  := '80';            -- 顧客ステータス：更生債権
-- == 2009/06/11 V1.1 Added END   ===============================================================
  cn_inv_quantity_0         CONSTANT NUMBER        := 0;               -- 基準在庫数 比較値
  --
  --ファイルオープンモード
  cv_file_mode              CONSTANT VARCHAR2(2)   := 'W';             -- オープンモード
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;                                  -- 業務処理日付取得用
  gv_dire_pass          VARCHAR2(100);                         -- ディレクトリパス名用
  gv_file_vd_column     VARCHAR2(50);                          -- VDコラムマスタファイル名用
  gv_company_code       VARCHAR2(50);                          -- 会社コード取得用
  gv_file_name          VARCHAR2(150);                         -- ファイルパス名取得用
  gv_activ_file_h       UTL_FILE.FILE_TYPE;                    -- ファイルハンドル取得用
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    --プロファイル取得用定数
    cv_pro_dire_out_info    CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_INFO';
    cv_pro_file_vdinfo      CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_VDINFO';
    cv_pro_company_code     CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';
--
    -- *** ローカル変数 ***
    lv_directory_path       VARCHAR2(100);     -- ディレクトリパス取得用
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
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===============================
    --  初期化処理
    -- ===============================
    gd_process_date       :=  NULL;          -- 業務日付
    gv_dire_pass          :=  NULL;          -- ディレクトリパス名
    gv_file_vd_column     :=  NULL;          -- VDコラムマスタファイル名
    gv_company_code       :=  NULL;          -- 会社コード名
    gv_file_name          :=  NULL;          -- ファイルパス名
    lv_directory_path     :=  NULL;
    --
    -- ===============================
    --  1.SYSDATE取得
    -- ===============================
    gd_process_date   :=  sysdate;
    --
    -- ====================================================
    -- 2.情報系_OUTBOUND格納ディレクトリ名情報を取得
    -- ====================================================
    gv_dire_pass      := fnd_profile.value( cv_pro_dire_out_info );
--
    -- ディレクトリ名情報が取得できなかった場合
    IF ( gv_dire_pass IS NULL ) THEN
      -- ディレクトリ名取得エラーメッセージ
      -- 「プロファイル:ディレクトリ名( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00003
                      , iv_token_name1  => cv_tkn_pro
                      , iv_token_value1 => cv_pro_dire_out_info
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 3.VDコラムマスタファイル名を取得
    -- =======================================
    gv_file_vd_column   := fnd_profile.value( cv_pro_file_vdinfo );
    --
    -- VDコラムマスタファイル名が取得できなかった場合
    IF ( gv_file_vd_column IS NULL ) THEN
      -- ファイル名取得エラーメッセージ
      -- 「プロファイル:ファイル名( PRO_TOK )の取得に失敗しました。」
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_vdinfo
                      );
      lv_errbuf    := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 4.会社コードを取得
    -- =====================================
    gv_company_code  := fnd_profile.value( cv_pro_company_code );
    --
    -- 会社コードが取得できなかった場合
    IF  ( gv_company_code  IS NULL ) THEN
      -- 会社コード取得エラーメッセージ
      -- 「プロファイル:会社コード( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00007
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_company_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 5.メッセージの出力①
    -- =====================================
    -- コンカレント入力パラメータなしメッセージを出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00023
                    );
    --
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    --
    -- =====================================
    -- 6.メッセージの出力②
    -- =====================================
    --
    -- 2.で取得したプロファイル値よりディレクトリパスを取得
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- ディレクトリ情報
      WHERE  directory_name = gv_dire_pass;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ディレクトリフルパス取得エラーメッセージ
        -- 「このディレクトリ名ではディレクトリパスは取得できません。
        -- （ディレクトリ名 = DIR_TOK ）」
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00029
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_pass
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    -- IFファイル名（IFファイルのフルパス情報）を出力
    -- 'ディレクトリパス'と'/'と‘ファイル名'を結合
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_vd_column;
    --「ファイル： FILE_NAME 」
    --ファイル名出力メッセージ
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00028
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_file_name
                    );
    --
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : create_csv_p
   * Description      : VDコラムマスタCSVの作成(A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     in_column_no          IN  VARCHAR2    -- コラムNO.
   , in_price              IN  NUMBER      -- 単価
   , in_inventory_quantity IN  NUMBER      -- 基準在庫数
   , in_last_month_inv_q   IN  NUMBER      -- 前月基準在庫数
   , iv_hot_cold           IN  VARCHAR2    -- HOT/COLD区分
   , iv_account_number     IN  VARCHAR2    -- 顧客コード
   , iv_segment1           IN  VARCHAR2    -- 商品コード
   , iv_external_reference IN  VARCHAR2    -- 物件コード
   , ov_errbuf             OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
   , ov_retcode            OUT VARCHAR2    -- リターン・コード             --# 固定 #
   , ov_errmsg             OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_p'; -- プログラム名
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
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ローカル変数 ***
    lv_vd_column     VARCHAR2(3000);
    lv_process_date  VARCHAR2(14);
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
    -- 変数の初期化
    lv_vd_column      := NULL;
    lv_process_date   := NULL;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 連携日時
    lv_process_date := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );
    --
    -- カーソルで取得した値をCSVファイルに格納します
    lv_vd_column := cv_file_encloser || gv_company_code       || cv_file_encloser || cv_csv_com ||  -- 会社コード
                    cv_file_encloser || iv_account_number     || cv_file_encloser || cv_csv_com ||  -- 顧客コード
                    cv_file_encloser || in_column_no          || cv_file_encloser || cv_csv_com ||  -- コラムNO.
                    cv_file_encloser || iv_segment1           || cv_file_encloser || cv_csv_com ||  -- 品目コード
                                        in_price                                  || cv_csv_com ||  -- 単価
                                        in_inventory_quantity                     || cv_csv_com ||  -- 基準在庫数
                                        in_last_month_inv_q                       || cv_csv_com ||  -- 前月基準在庫数
                    cv_file_encloser || iv_hot_cold           || cv_file_encloser || cv_csv_com ||  -- HOT/COLD区分
                    cv_file_encloser || iv_external_reference || cv_file_encloser || cv_csv_com ||  -- 物件コード                                                            -- 物件コード
                                        lv_process_date;                                            -- 連携日時
--
    UTL_FILE.PUT_LINE(
        gv_activ_file_h     -- A-3.で取得したファイルハンドル
      , lv_vd_column        -- デリミタ＋上記CSV出力項目
      );
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
  END create_csv_p;
--
  /**********************************************************************************
   * Procedure Name   : vd_column_cur_p
   * Description      : VDコラムマスタ情報の抽出(A-3)
   ***********************************************************************************/
  PROCEDURE vd_column_cur_p(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   , ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'vd_column_cur_p'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode VARCHAR2(1);      -- リターン・コード
    lv_errmsg  VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- == 2009/09/17 V1.5 Deleted START ===============================================================
-- == 2009/08/14 V1.3 Added START ===============================================================
--   cv_zero_10   CONSTANT VARCHAR2(10) := '0000000000';
-- == 2009/08/14 V1.3 Added END   ===============================================================
-- == 2009/09/17 V1.5 Deleted END   ===============================================================
--
    -- *** ローカル変数 ***
-- == 2009/08/14 V1.3 Added START ===============================================================
   ln_column_no          xxcoi_mst_vd_column.column_no%TYPE;
   lv_account_number     hz_cust_accounts.account_number%TYPE;
-- == 2009/08/14 V1.3 Added END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- VDコラムマスタ情報取得
    CURSOR vd_column_cur
    IS
      SELECT
-- == 2009/07/13 V1.2+V1.4 Added START ===============================================================
              /*+ leading(hp) use_nl(hp hca cii xmvc msib) index( hp hz_parties_n17 ) */
-- == 2009/07/13 V1.2+V1.4 Added END   ===============================================================
              xmvc.column_no                      -- コラムNO.
            , xmvc.price                          -- 単価
            , xmvc.inventory_quantity             -- 基準在庫数
            , xmvc.last_month_inventory_quantity  -- 前月基準在庫数
            , xmvc.hot_cold                       -- HOT/COLD区分
            , hca.account_number                  -- 顧客コード
            , msib.segment1                       -- 品目コード
-- == 2009/09/17 V1.5 Modified START ===============================================================
-- == 2009/08/14 V1.3 Modified START ===============================================================
--            , cii.external_reference              -- 物件コード
--            , NVL(cii.external_reference, cv_zero_10) external_reference  -- 物件コード
            , cii.external_reference              -- 物件コード
-- == 2009/08/14 V1.3 Modified END   ===============================================================
-- == 2009/09/17 V1.5 Modified END   ===============================================================
      FROM    xxcoi_mst_vd_column  xmvc        -- VDコラムマスタ
            , hz_cust_accounts     hca         -- 顧客マスタ
            , mtl_system_items_b   msib        -- 品目マスタ
            , csi_item_instances   cii         -- 物件マスタ
            , hz_parties           hp          -- パーティ
-- == 2009/07/13 V1.2 Modified START ===============================================================
---- == 2009/06/11 V1.1 Modified START ===============================================================
----      WHERE  hp.duns_number_c         <>  cv_duns_number_90           -- 顧客ステータス：中止決裁済
--      WHERE  hp.duns_number_c         NOT IN ( cv_duns_number_90 , cv_duns_number_80 )  -- 顧客ステータス
---- == 2009/06/11 V1.1 Modified END   ===============================================================
      WHERE  hp.duns_number_c         <   cv_duns_number_80           -- 顧客ステータス
-- == 2009/07/13 V1.2 Modified END   ===============================================================
      AND    hp.party_id              =   hca.party_id                -- パーティID
      AND    xmvc.inventory_quantity  <>  cn_inv_quantity_0           -- 基準在庫数が'0'以外
      AND    hca.cust_account_id      =   xmvc.customer_id            -- 顧客ID
      AND    msib.inventory_item_id   =   xmvc.item_id                -- 品目ID
      AND    msib.organization_id     =   xmvc.organization_id        -- 組織ID
-- == 2009/09/17 V1.5 Modified START ===============================================================
-- == 2009/08/14 V1.3 Modified START ===============================================================
--      AND    hca.cust_account_id      =   cii.owner_party_account_id; -- 所有者アカウントID
--      AND    hca.cust_account_id      =   cii.owner_party_account_id(+) -- 所有者アカウントID
      AND    hca.cust_account_id      =   cii.owner_party_account_id    -- 所有者アカウントID
-- == 2009/10/21 V1.6 Added START ===============================================================
      AND    cii.instance_type_code   =   '1'                           -- 機器区分:自販機
-- == 2009/10/21 V1.6 Added END   ===============================================================
      ORDER BY hca.account_number
              ,xmvc.column_no;
-- == 2009/08/14 V1.3 Modified END   ===============================================================
-- == 2009/09/17 V1.5 Modified END   ===============================================================
      --
      -- vd_columnレコード型
      vd_column_rec  vd_column_cur%ROWTYPE;
--
      -- ===============================
      -- ユーザー定義例外
      -- ===============================
    NO_DATA_ERR         EXCEPTION;     -- 取得データ０件エラー
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    --VDコラムマスタデータ取得カーソルオープン
    OPEN vd_column_cur;
      --
      <<vd_column_loop>>
      LOOP
        FETCH vd_column_cur INTO vd_column_rec;
        --次データがなくなったら終了
        EXIT WHEN vd_column_cur%NOTFOUND;
        --対象件数加算
        gn_target_cnt := gn_target_cnt + 1;
--
-- == 2009/08/14 V1.3 Added START ===============================================================
        IF    (ln_column_no IS NOT NULL)
          AND (ln_column_no = vd_column_rec.column_no)
          AND (lv_account_number IS NOT NULL)
          AND (lv_account_number = vd_column_rec.account_number)
        THEN
          --コラムNoと顧客コードが前レコードの値と一致した場合は次レコードへ進む
          NULL;
        ELSE
-- == 2009/08/14 V1.3 Added END   ===============================================================
          -- ===============================
          -- A-4．VDコラムマスタCSVの作成
          -- ===============================
          create_csv_p(
              in_column_no          => vd_column_rec.column_no                      -- コラムNO.
            , in_price              => vd_column_rec.price                          -- 単価
            , in_inventory_quantity => vd_column_rec.inventory_quantity             -- 基準在庫数
            , in_last_month_inv_q   => vd_column_rec.last_month_inventory_quantity  -- 前月基準在庫数
            , iv_hot_cold           => vd_column_rec.hot_cold                       -- HOT/COLD区分
            , iv_account_number     => vd_column_rec.account_number                 -- 顧客コード
            , iv_segment1           => vd_column_rec.segment1                       -- 商品コード
            , iv_external_reference => vd_column_rec.external_reference             -- 物件コード
            , ov_errbuf             => lv_errbuf                             -- エラー・メッセージ           --# 固定 #
            , ov_retcode            => lv_retcode                            -- リターン・コード             --# 固定 #
            , ov_errmsg             => lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
          );
  --
          IF (lv_retcode = cv_status_error) THEN
            -- エラー処理
            RAISE global_process_expt;
          END IF;
  --
          -- 正常件数に加算
          gn_normal_cnt := gn_normal_cnt + 1;
        --
-- == 2009/08/14 V1.3 Added START ===============================================================
        END IF;
        --変数に上書き
        ln_column_no      := vd_column_rec.column_no;
        lv_account_number := vd_column_rec.account_number;
-- == 2009/08/14 V1.3 Added END   ===============================================================
      --ループの終了
      END LOOP vd_column_loop;
      --
    --カーソルのクローズ
    CLOSE vd_column_cur;
    --
    -- データが０件で終了した場合は
    IF ( gn_target_cnt = 0 ) THEN
      RAISE NO_DATA_ERR;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_ERR THEN
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      -- 対象データ無しメッセージ
      -- 「対象データはありません。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00008
                      );
      lv_errbuf   := lv_errmsg;
      --
      -- エラーメッセージ
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      -- エラーメッセージ
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがオープンしている場合はクローズする
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END vd_column_cur_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode    OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg     OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)  := 'submain'; -- プログラム名
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767;
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);                   -- リターン・コード
    lv_errmsg       VARCHAR2(5000);                -- ユーザー・エラー・メッセージ
    --
    -- ファイルの存在チェック用変数
    lb_exists       BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
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
    -- *** ローカル例外 ***
    remain_file_expt           EXCEPTION;
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
    -- 初期化処理
    -- ===============================
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gv_activ_file_h  := NULL;            -- ファイルハンドル
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ========================================
    --  A-1. 初期処理
    -- ========================================
    init(
        ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2．ファイルオープン処理
    -- ========================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_pass
      , filename     =>  gv_file_vd_column
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
--
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
--
    ELSE
      -- ファイルオープン処理実行
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_pass        -- ディレクトリパス
                          , filename     => gv_file_vd_column   -- ファイル名
                          , open_mode    => cv_file_mode        -- オープンモード
                          , max_linesize => cn_max_linesize     -- ファイルサイズ
                         );
    END IF;
    --
    -- ========================================
    -- A-3．VDコラムマスタ情報の抽出
    -- ========================================
    -- A-3の処理内部でA-4を処理
    vd_column_cur_p(
        ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-5．ファイルのクローズ処理
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gv_activ_file_h
      );
--
  EXCEPTION
    -- カーソルのクローズをここに記述する
    -- *** ファイル存在チェックエラー ***
    -- 「ファイル「 FILE_NAME 」はすでに存在します。」
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00027
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_file_vd_column
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
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
    -- ===============================
    -- 変数の初期化
    -- ===============================
    lv_errbuf    := NULL;   -- エラー・メッセージ
    lv_retcode   := NULL;   -- リターン・コード
    lv_errmsg    := NULL;   -- ユーザー・エラー・メッセージ
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        ov_retcode => lv_retcode  -- エラー・メッセージ           --# 固定 #
      , ov_errbuf  => lv_errbuf   -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
    --
    --==============================================================
    -- A-6．件数表示処理
    --==============================================================
    -- エラー時は成功件数出力を０にセット
    --           エラー件数出力を１にセット
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      -- 正常終了メッセージ
      -- 「処理が正常終了しました。」
      lv_message_code := cv_normal_msg;
    --
    ELSIF(lv_retcode = cv_status_error) THEN
      -- エラー終了全ロールバックメッセージ
      -- 「処理がエラー終了しました。データは全件処理前の状態に戻しました。」
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      --
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
END XXCOI008A05C;
/
