CREATE OR REPLACE PACKAGE BODY XXCOI008A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A04C(body)
 * Description      : 情報系システムへの連携の為、EBSの保管場所(標準)をCSVファイルに出力
 * MD.050           : 保管場所情報系連携 <MD050_COI_008_A04>
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  create_csv_p           保管場所マスタCSVの作成(A-4)
 *  sec_inv_cur_p          保管場所情報の抽出(A-3)
 *  submain                メイン処理プロシージャ
 *                           ・ファイルオープン(A-2)
 *                           ・ファイルクローズ(A-5) 
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   S.Kanda          新規作成
 *  2009/03/30    1.1   T.Nakamura       [障害T1_0121]保管場所情報の抽出条件を追加
 *  2010/05/02    1.2   H.Sasaki         [E_本稼動_02545]保管場所コードの全角文字チェックを追加
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
-- == 2010/05/02 V1.2 Added START ===============================================================
  gn_warn_cnt      NUMBER;                    -- 警告件数
-- == 2010/05/02 V1.2 Added END   ===============================================================

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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A04C';
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
-- == 2010/05/02 V1.2 Added START ===============================================================
  cv_msg_xxcoi_10427        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10427';
-- == 2010/05/02 V1.2 Added END   ===============================================================
  --
  --トークン
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- プロファイル名用
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- プロファイル名用
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- 件数メッセージ用
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- ファイル名用
-- == 2009/03/30 V1.1 Added START ===============================================================
  cv_tkn_org_code           CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';  -- 在庫組織コード用
-- == 2009/03/30 V1.1 Added END   ===============================================================
-- == 2010/05/02 V1.2 Added START ===============================================================
  cv_tkn_10427              CONSTANT VARCHAR2(15)  := 'SUBINV_CODE';
-- == 2010/05/02 V1.2 Added END   ===============================================================
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
  gv_file_sec_inv       VARCHAR2(50);                          -- 保管場所ファイル名用
  gv_company_code       VARCHAR2(50);                          -- 会社コード取得用
  gv_file_name          VARCHAR2(150);                         -- ファイルパス名取得用
  gv_activ_file_h       UTL_FILE.FILE_TYPE;                    -- ファイルハンドル取得用
-- == 2009/03/30 V1.1 Added START ===============================================================
  gv_organization_code  VARCHAR2(50);                          -- 在庫組織コード取得用
  gn_organization_id    mtl_parameters.organization_id%TYPE;   -- 在庫組織ID取得用
-- == 2009/03/30 V1.1 Added END   ===============================================================
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
    cv_pro_file_sec_inv     CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_SEC_INV';
    cv_pro_company_code     CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';
-- == 2009/03/30 V1.1 Added START ===============================================================
    cv_pro_org_code         CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';
-- == 2009/03/30 V1.1 Added END   ===============================================================
--
    -- *** ローカル変数 ***
    lv_directory_path       VARCHAR2(100);
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
    gv_dire_pass          :=  NULL;          -- ディレクトリ名
    gv_file_sec_inv       :=  NULL;          -- 保管場所ファイル名
    gv_company_code       :=  NULL;          -- 会社コード名
    gv_file_name          :=  NULL;          -- ファイルパス名
    lv_directory_path     :=  NULL;          -- ディレクトリパス名
    --
    -- ===============================
    --  1.SYSDATE取得
    -- ===============================
    gd_process_date   :=  sysdate;
    --
    -- ====================================================
    -- 2.情報系_OUTBOUND格納ディレクトリ名を取得
    -- ====================================================
    gv_dire_pass      := fnd_profile.value( cv_pro_dire_out_info );
--
    -- ディレクトリ名が取得できなかった場合
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
    -- 3.保管場所ファイル名を取得
    -- =======================================
    gv_file_sec_inv  := fnd_profile.value( cv_pro_file_sec_inv );
    --
    -- 保管場所ファイル名が取得できなかった場合
    IF ( gv_file_sec_inv IS NULL ) THEN
      -- ファイル名取得エラーメッセージ
      -- 「プロファイル:ファイル名( PRO_TOK )の取得に失敗しました。」
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_sec_inv
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
-- == 2009/03/30 V1.1 Added START ===============================================================
    -- =====================================
    -- 4.在庫組織コードを取得
    -- =====================================
    gv_organization_code := fnd_profile.value( cv_pro_org_code );
    --
    -- 在庫組織コードが取得できなかった場合
    IF  ( gv_organization_code  IS NULL ) THEN
      -- 在庫組織コード取得エラーメッセージ
      -- 「プロファイル:在庫組織コード( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00005
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_org_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 在庫組織ID取得
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_organization_code );
    --
    -- 共通関数のリターンコードが取得できなかった場合
    IF ( gn_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      -- 「在庫組織コード( ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。」
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/03/30 V1.1 Added END   ===============================================================
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
    -- =====================================
    -- 6.メッセージの出力②
    -- =====================================
    -- 2.で取得したプロファイル値よりディレクトリパスを取得
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- ディレクトリ情報
      WHERE  directory_name  =  gv_dire_pass;
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
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_sec_inv;
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
   * Description      : 保管場所マスタCSVの作成(A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     iv_sec_inv_name IN  VARCHAR2    -- 保管場所コード
   , iv_description  IN  VARCHAR2    -- 保管場所名称
   , iv_disable_date IN  DATE        -- 無効日
   , iv_attribute1   IN  VARCHAR2    -- 保管場所区分(DFF1)
   , iv_attribute3   IN  VARCHAR2    -- 従業員コード(DFF3)
   , iv_attribute4   IN  VARCHAR2    -- 顧客コード(DFF4)
   , iv_attribute7   IN  VARCHAR2    -- 拠点コード(DFF7)
   , ov_errbuf       OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
   , ov_retcode      OUT VARCHAR2    -- リターン・コード             --# 固定 #
   , ov_errmsg       OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_csv_com      CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ローカル変数 ***
    lv_sec_inv       VARCHAR2(3000);
    lv_disable_date  VARCHAR2(8);
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
    lv_sec_inv       := NULL;
    lv_disable_date  := NULL;
    lv_process_date  := NULL;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 無効日
    lv_disable_date := TO_CHAR( iv_disable_date , 'YYYYMMDD' );
    -- 連携日時
    lv_process_date := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );
    --
    -- カーソルで取得した値をCSVファイルに格納します
    lv_sec_inv := cv_file_encloser || gv_company_code || cv_file_encloser || cv_csv_com ||  -- 会社コード
                  cv_file_encloser || iv_sec_inv_name || cv_file_encloser || cv_csv_com ||  -- 保管場所コード
                  cv_file_encloser || iv_description  || cv_file_encloser || cv_csv_com ||  -- 保管場所名称
                                      lv_disable_date                     || cv_csv_com ||  -- 無効日
                  cv_file_encloser || iv_attribute1   || cv_file_encloser || cv_csv_com ||  -- 保管場所区分(DFF1)
                  cv_file_encloser || iv_attribute3   || cv_file_encloser || cv_csv_com ||  -- 従業員コード(DFF3)
                  cv_file_encloser || iv_attribute4   || cv_file_encloser || cv_csv_com ||  -- 顧客コード(DFF4)
                  cv_file_encloser || iv_attribute7   || cv_file_encloser || cv_csv_com ||  -- 拠点コード(DFF7)
                                      lv_process_date;                                      -- 連携日時
--
    UTL_FILE.PUT_LINE(
        gv_activ_file_h     -- A-3.で取得したファイルハンドル
      , lv_sec_inv          -- デリミタ＋上記CSV出力項目
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
   * Procedure Name   : sec_inv_cur_p
   * Description      : 保管場所情報の抽出(A-3)
   ***********************************************************************************/
  PROCEDURE sec_inv_cur_p(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   , ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sec_inv_cur_p'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 保管場所情報取得
    CURSOR sec_inv_cur
    IS
      SELECT  msi.secondary_inventory_name    -- 保管場所コード
            , msi.description                 -- 保管場所名称
            , msi.disable_date                -- 無効日
            , msi.attribute1                  -- 保管場所区分(DFF1)
            , msi.attribute3                  -- 従業員コード(DFF3)
            , msi.attribute4                  -- 顧客コード(DFF4)
            , msi.attribute7                  -- 拠点コード(DFF7)
-- == 2009/03/30 V1.1 Moded START ===============================================================
--      FROM    mtl_secondary_inventories msi;  -- 保管場所マスタ
      FROM    mtl_secondary_inventories   msi                 -- 保管場所マスタ
      WHERE   msi.organization_id       = gn_organization_id; -- A-1.で取得した在庫組織ID
-- == 2009/03/30 V1.1 Moded END   ===============================================================
      --
      -- sec_invレコード型
      sec_inv_rec  sec_inv_cur%ROWTYPE;
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
    --保管場所データ取得カーソルオープン
    OPEN sec_inv_cur;
      --
      <<sec_inv_loop>>
      LOOP
        FETCH sec_inv_cur INTO sec_inv_rec;
        --次データがなくなったら終了
        EXIT WHEN sec_inv_cur%NOTFOUND;
        --対象件数加算
        gn_target_cnt := gn_target_cnt + 1;
--
-- == 2010/05/02 V1.2 Added START ===============================================================
        IF (LENGTH(sec_inv_rec.secondary_inventory_name) = LENGTHB(sec_inv_rec.secondary_inventory_name)) THEN
          -- 文字数と文字バイト数が一致する場合CSVファイルを作成
-- == 2010/05/02 V1.2 Added END   ===============================================================
          -- ===============================
          -- A-4．保管場所マスタCSVの作成
          -- ===============================
          create_csv_p(
              iv_sec_inv_name => sec_inv_rec.secondary_inventory_name -- 保管場所コード
            , iv_description  => sec_inv_rec.description              -- 保管場所名称
            , iv_disable_date => sec_inv_rec.disable_date             -- 無効日
            , iv_attribute1   => sec_inv_rec.attribute1               -- 保管場所区分(DFF1)
            , iv_attribute3   => sec_inv_rec.attribute3               -- 従業員コード(DFF3)
            , iv_attribute4   => sec_inv_rec.attribute4               -- 顧客コード(DFF4)
            , iv_attribute7   => sec_inv_rec.attribute7               -- 拠点コード(DFF7)
            , ov_errbuf       => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
            , ov_retcode      => lv_retcode                         -- リターン・コード             --# 固定 #
            , ov_errmsg       => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
          );
  --
          IF (lv_retcode = cv_status_error) THEN
            -- エラー処理
            RAISE global_process_expt;
          END IF;
  --
          -- 正常件数に加算
          gn_normal_cnt := gn_normal_cnt + 1;
-- == 2010/05/02 V1.2 Added START ===============================================================
      ELSE
        -- 文字数と文字バイト数が不一致の場合スキップ
        -- 処理は正常終了。保管場所不正件数をカウント
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_appl_short_name
                        , iv_name           =>  cv_msg_xxcoi_10427
                        , iv_token_name1    =>  cv_tkn_10427
                        , iv_token_value1   =>  sec_inv_rec.secondary_inventory_name
                        );
        lv_errbuf   := lv_errmsg;
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_errbuf --エラーメッセージ
        );
        --
        gn_warn_cnt  :=  gn_warn_cnt + 1;
      END IF;
-- == 2010/05/02 V1.2 Added END   ===============================================================
      --
      --ループの終了
      END LOOP sec_inv_loop;
      --
    --カーソルのクローズ
    CLOSE sec_inv_cur;
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
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
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
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
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
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがオープンしている場合はクローズする
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END sec_inv_cur_p;
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
-- == 2010/05/02 V1.2 Added START ===============================================================
    gn_warn_cnt      := 0;
-- == 2010/05/02 V1.2 Added END   ===============================================================
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
      , filename     =>  gv_file_sec_inv
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
                          , filename     => gv_file_sec_inv     -- ファイル名
                          , open_mode    => cv_file_mode        -- オープンモード
                          , max_linesize => cn_max_linesize     -- ファイルサイズ
                         );
    END IF;
    --
    -- ========================================
    -- A-3．保管場所情報の抽出
    -- ========================================
    -- A-3の処理内部でA-4を処理
    sec_inv_cur_p(
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
                        , iv_token_value1 => gv_file_sec_inv
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
    retcode       OUT VARCHAR2      --   リターン・コード    --# 固定 #
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
-- == 2010/05/02 V1.2 Added START ===============================================================
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
-- == 2010/05/02 V1.2 Added END   ===============================================================
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
    -- A-7.件数表示処理
    --==============================================================
    -- エラー時は成功件数出力を０にセット
    --           エラー件数出力を１にセット
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
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
-- == 2010/05/02 V1.2 Added START ===============================================================
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- == 2010/05/02 V1.2 Added START ===============================================================
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
END XXCOI008A04C;
/
