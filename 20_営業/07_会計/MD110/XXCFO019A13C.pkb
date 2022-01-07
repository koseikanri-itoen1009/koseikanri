CREATE OR REPLACE PACKAGE BODY XXCFO019A13C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCFO019A13C(body)
 * Description      : 電子帳簿請求の情報系システム連携
 * MD.050           : MD050_CFO_019_A13_電子帳簿請求の情報系システム連携
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    初期処理(A-1)
 *  get_invoice             対象データ取得(A-2)
 *  chk_item                項目チェック処理(A-3)
 *  out_csv                 ＣＳＶ出力処理(A-4)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ・終了処理(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021-12-23    1.0   K.Tomie         新規作成 (E_本稼動_17770対応)
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
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                    -- 対象件数
  gn_normal_cnt      NUMBER;                    -- 正常件数
  gn_error_cnt       NUMBER;                    -- エラー件数
  gn_warn_cnt        NUMBER;                    -- スキップ件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A13C'; -- パッケージ名
  --アプリケーション短縮名
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp              CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';     -- 電子帳簿データファイル格納パス
  cv_filename                 CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_INV_DATA_FILENAME'; -- 電子帳簿請求データファイル名
  cv_prf_org_id               CONSTANT VARCHAR2(50)  := 'ORG_ID';                                 -- MO:営業単位
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                       -- GL会計帳簿ID
  --メッセージ
  cv_msg_ccp_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-00001';   --警告件数メッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';   --参照タイプ取得エラー
  cv_msg_coi_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10025';   --取得対象データ無しエラーメッセージ
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';   --プロファイル名取得エラーメッセージ
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00002';   --ファイル名出力メッセージ
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';   --業務日付取得エラーメッセージ
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027';   --ファイル存在エラー
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029';   --ファイルオープンエラーメッセージ
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030';   --ファイル書き込みエラー
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  --トークンコード
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';    -- ルックアップタイプ名
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';      -- プロファイル名
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';        -- ディレクトリ名
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';      -- ファイル名
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';       -- テーブル名
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- エラー情報
  --メッセージ出力用文字列(トークン)
  cv_msgtkn_cfo_11178         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11178'; -- 請求情報
  cv_msgtkn_cfo_11179         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11179'; -- 一括請求書ID
  cv_msgtkn_cfo_11180         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11180'; -- 一括請求書明細No
  --参照タイプ
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      --電子帳簿処理実行日
  cv_lookup_item_chk_invoice  CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_ITEM_CHK_ARINV'; --電子帳簿項目チェック（請求）
  cv_lookup_syohizei_kbn      CONSTANT VARCHAR2(30)  := 'XXCMM_CSUT_SYOHIZEI_KBN';        --消費税区分
  cv_lookup_vd_customer_kbn   CONSTANT VARCHAR2(30)  := 'XXCFO1_VD_CUSTOMER_KBN';         --VD顧客区分
  cv_lookup_invoice_kbn       CONSTANT VARCHAR2(30)  := 'XXCFO1_INVOICE_KBN';             --請求区分
  cv_lookup_delivery_slip     CONSTANT VARCHAR2(30)  := 'XXCOS1_DELIVERY_SLIP_CLASS';     --売上返品区分
  cv_lookup_chain_code        CONSTANT VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';               --納品先チェーンコード
  --値セット
  cv_flex_value_department    CONSTANT VARCHAR2(30)  := 'XX03_DEPARTMENT';                  --入金拠点コード
  --ＣＳＶ出力フォーマット
  cv_date_format_ymdhms       CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';          --ＣＳＶ出力フォーマット
  cv_date_format_ymdshms      CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';     --ＣＳＶ出力フォーマット
  --ＣＳＶ
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- カンマ
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- 文字括り
  --情報抽出用
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --言語
  cv_1                        CONSTANT VARCHAR2(1)   := '1';   --'1'
  cv_2                        CONSTANT VARCHAR2(1)   := '2';   --'2'
  cv_18                       CONSTANT VARCHAR2(2)   := '18';  --'18'
  --固定値
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- スラッシュ
  --ファイル出力
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
  cn_max_linesize             CONSTANT BINARY_INTEGER := 32767;               -- ファイルサイズ
  --項目属性
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2（属性チェックなし）
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  （数値チェック）
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    （日付型チェック）
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   （チェック）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)   INDEX BY PLS_INTEGER;
  gt_data_tab                  g_layout_ttype;              --出力データ情報
  --項目チェック
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.attribute1%type  
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute2%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute3%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute4%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype      IS TABLE OF fnd_lookup_values.attribute6%type
                                            INDEX BY PLS_INTEGER;
  --
  gt_item_name                  g_item_name_ttype;          -- 項目名称
  gt_item_len                   g_item_len_ttype;           -- 項目の長さ
  gt_item_decimal               g_item_decimal_ttype;       -- 項目（小数点以下の長さ）
  gt_item_nullflg               g_item_nullflg_ttype;       -- 必須項目フラグ
  gt_item_attr                  g_item_attr_ttype;          -- 項目属性
  gt_item_cutflg                g_item_cutflg_ttype;        -- 切捨てフラグ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             DATE;                                -- 業務日付
  gv_coop_date                VARCHAR2(14);                        -- 連携日時
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;   -- 電子帳簿処理実行日数
  gt_proc_target_time         fnd_lookup_values.attribute2%TYPE;   -- 処理対象時刻
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --ファイルパス
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --電子帳簿取引データ追加ファイル
  gn_org_id                   NUMBER;                       --組織ID(営業単位)
  gn_set_of_bks_id            NUMBER;                       --GL会計帳簿ID
  gn_item_cnt                 NUMBER;             --チェック項目件数
  gv_0file_flg                VARCHAR2(1) DEFAULT cv_flag_n; --0Byteファイル上書きフラグ
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
--
  -- ===============================
  -- グローバル例外
  -- ===============================
  global_lock_expt  EXCEPTION; -- ロック(ビジー)エラー
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_cutoff_date IN  VARCHAR2, -- 1.締日
    iv_file_name   IN  VARCHAR2, -- 2.ファイル名
    ov_errbuf      OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_profile_name           fnd_profile_options.profile_option_name%TYPE;
    lv_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    -- *** ファイル存在チェック用 ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
    lv_msg          VARCHAR2(3000);
    lv_full_name    VARCHAR2(200) DEFAULT NULL;    --ディレクトリ名＋ファイル名連結値
    lt_dir_path     all_directories.directory_path%TYPE DEFAULT NULL; --ディレクトリパス
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             meaning    --項目名称
              , flv.attribute1          attribute1 --項目の長さ
              , flv.attribute2          attribute2 --項目の長さ（小数点以下）
              , flv.attribute3          attribute3 --必須フラグ
              , flv.attribute4          attribute4 --属性
              , flv.attribute5          attribute5 --切捨てフラグ
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_invoice --電子帳簿項目チェック（請求）
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        = cv_flag_y
      AND       flv.language            = cv_lang
      ORDER BY  flv.lookup_code
      ;
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
    -- パラメータ出力
    --==============================================================
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out                                 -- メッセージ出力
      ,iv_conc_param1  => iv_cutoff_date                                   -- 締日
      ,iv_conc_param2  => iv_file_name                                     -- ファイル名      
      ,ov_errbuf       => lv_errbuf                                        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode                                       -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);                                      -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log                                -- ログ出力
      ,iv_conc_param1  => iv_cutoff_date                                  -- 締日
      ,iv_conc_param2  => iv_file_name                                    -- ファイル名
      ,ov_errbuf       => lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode                                      -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);                                     -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00015 -- 業務日付取得エラー
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 連携日時用日付取得
    --==============================================================
    gv_coop_date := TO_CHAR(SYSDATE, cv_date_format_ymdhms);
--
    --==================================
    -- クイックコード(項目チェック処理用)情報の取得
    --==================================
    OPEN get_chk_item_cur;
    -- データの一括取得
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- 対象件数のセット
    gn_item_cnt := gt_item_name.COUNT;
--
    -- カーソルクローズ
    CLOSE get_chk_item_cur;
    --
    IF ( gn_item_cnt = 0 ) THEN
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- 参照タイプ取得エラー
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_item_chk_invoice -- 'XXCFO1_ELECTRIC_ITEM_CHK_INVOICE'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
--
    --==================================
    -- クイックコード
    --==================================
    --電子帳簿処理実行日数情報
    BEGIN
      SELECT    flv.attribute1 attribute1-- 電子帳簿処理実行日数
      INTO      gt_electric_exec_days
      FROM      fnd_lookup_values  flv
      WHERE     flv.lookup_type    = cv_lookup_book_date
      AND       flv.lookup_code    = cv_pkg_name
      AND       gd_process_date    BETWEEN NVL(flv.start_date_active, gd_process_date)
                                   AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag   = cv_flag_y
      AND       flv.language       = cv_lang
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- 参照タイプ取得エラー
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_book_date     -- 'XXCFO1_ELECTRIC_BOOK_DATE'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END;
--
    --==================================
    -- プロファイルの取得
    --==================================
    --ファイル格納パス
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_data_filepath -- 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --ファイル名
    IF ( iv_file_name IS NOT NULL ) THEN
      --パラメータ「ファイル名」が入力済の場合は、入力値をファイル名として使用
      gv_file_name  :=  iv_file_name;
    ELSIF ( iv_file_name IS NULL ) THEN
      --パラメータ「ファイル名」が未入力の場合は、プロファイルからファイル名を取得
      gv_file_name  := FND_PROFILE.VALUE( cv_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_filename  -- 'XXCFO1_ELECTRIC_BOOK_INV_DATA_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    
    -- プロファイルの取得(MO:営業単位)
    gn_org_id := apps.FND_PROFILE.VALUE( cv_prf_org_id );
    -- プロファイル取得エラーの場合
    IF ( gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001
                                                    ,cv_tkn_prof_name
                                                    ,cv_prf_org_id
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- プロファイルの取得(GL会計帳簿ID)
    gn_set_of_bks_id := TO_NUMBER(apps.FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- プロファイル取得エラーの場合
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00001  -- プロファイル取得エラー
                                                    ,cv_tkn_prof_name       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id )  -- GL会計帳簿ID
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ディレクトリパス取得
    --==================================
    BEGIN
      SELECT    ad.directory_path directory_path
      INTO      lt_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                    ,cv_msg_coi_00029 -- ディレクトリパス取得エラー
                                                    ,cv_tkn_dir_tok   -- 'DIR_TOK'
                                                    ,gt_file_path     -- ファイル格納パス
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    --==================================
    -- IFファイル名出力
    --==================================
    --取得したディレクトリパスの末尾に'/'(スラッシュ)が存在する場合、
    --ディレクトリとファイル名の間に'/'連結は行わずにファイル名を出力する
    IF  SUBSTRB(lt_dir_path, -1, 1) = cv_slash    THEN
      lv_full_name :=  lt_dir_path || gv_file_name;
    ELSE
      lv_full_name :=  lt_dir_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                               ,cv_msg_cfo_00002 -- ファイル名出力メッセージ
                                               ,cv_tkn_file_name -- 'FILE_NAME'
                                               ,lv_full_name     -- 格納パスとファイル名の連結文字
                                              )
                      ,1
                      ,5000);
    -- ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- 同一ファイル存在チェック
    --==================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gt_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00027 -- 同一ファイルあり
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --ファイルオープン
    --==============================================================
    BEGIN
      gv_file_hand := UTL_FILE.FOPEN( 
                        location     => gt_file_path
                       ,filename     => gv_file_name
                       ,open_mode    => cv_open_mode_w
                       ,max_linesize => cn_max_linesize
                                   );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029 -- ファイルオープンエラー
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
      -- カーソルクローズ
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_msgcode            OUT VARCHAR2,   --   メッセージコード
    ov_errbuf             OUT VARCHAR2,   --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT VARCHAR2,   --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT VARCHAR2)   --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'chk_item'; -- プログラム名
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
--
    lv_invoice_id_name         VARCHAR2(12);                    --一括請求書IDメッセージ出力用
    lv_invoice_detail_num_name VARCHAR2(16);                    --一括請求書明細Noメッセージ出力用
    lv_invoice_id              VARCHAR2(500);                    --一括請求書IDの値メッセージ出力用(文字列)
    lv_invoice_detail_num      VARCHAR2(500);                    --一括請求書明細Noの値メッセージ出力用(文字列)
    lv_data_mess               VARCHAR2(500);                   --項目の値メッセージ出力用(文字列)
    -- ===============================
    -- ローカル定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    ov_msgcode := NULL;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 項目桁チェック
    --==============================================================
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      --変更前の値を格納
      lv_invoice_id := gt_data_tab(1);
      lv_invoice_detail_num := gt_data_tab(42);
      lv_data_mess := gt_data_tab(ln_cnt);
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --項目名称
        , iv_item_value                 =>        gt_data_tab(ln_cnt)               --変更前の値
        , in_item_len                   =>        gt_item_len(ln_cnt)               --項目の長さ
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --項目の長さ(小数点以下)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --必須フラグ
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --項目属性
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --切捨てフラグ
        , ov_item_value                 =>        gt_data_tab(ln_cnt)               --項目の値
        , ov_errbuf                     =>        lv_errbuf                         --エラーメッセージ
        , ov_retcode                    =>        lv_retcode                        --リターンコード
        , ov_errmsg                     =>        lv_errmsg                         --ユーザー・エラーメッセージ
        );
      IF ( lv_retcode = cv_status_warn ) THEN
        -- メッセージトークン取得
        lv_invoice_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                        ,cv_msgtkn_cfo_11179);         -- 一括請求書ID
        --
        lv_invoice_detail_num_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                          ,cv_msgtkn_cfo_11180); -- 一括請求書明細No
        IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
          --桁数超過エラーの場合、メッセージを出力
          lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo     -- 'XXCFO'
                                      ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                      ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                      ,lv_invoice_id_name || cv_msg_part || lv_invoice_id  || ' ' || lv_invoice_detail_num_name || cv_msg_part || lv_invoice_detail_num
                                         || ' ' || gt_item_name(ln_cnt) || cv_msg_part || lv_data_mess--一括請求書ID,一括請求書明細No,対象項目
                                      )
                                     ,1
                                     ,5000);
        ELSE
          --型桁チェックにて、警告内容が桁数超過以外の場合、戻りメッセージに一括請求書ID,一括請求書明細No,,対象項目を追加出力
          lv_errmsg := lv_errmsg || ' ' || lv_invoice_id_name || cv_msg_part || lv_invoice_id  || ' ' || lv_invoice_detail_num_name || cv_msg_part || lv_invoice_detail_num
                         || ' ' || gt_item_name(ln_cnt) || cv_msg_part || lv_data_mess;--一括請求書ID,一括請求書明細No,対象項目
        END IF;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        --
        ov_retcode          := lv_retcode;
        ov_msgcode          := lv_errbuf;        --戻りメッセージコード
        ov_errmsg           := lv_errmsg;        --戻りメッセージ
      ELSIF ( lv_retcode = cv_status_error ) THEN
        ov_errmsg   := lv_errmsg;
        RAISE global_api_others_expt;
      END IF;
      --
    END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : ＣＳＶ出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- プログラム名
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
    lv_delimit                VARCHAR2(1);
    lv_file_data              VARCHAR2(30000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
--
    --データ編集
    lv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP
      IF  gt_item_attr(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) THEN
        --VARCHAR2,CHAR2
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_quot ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab(ln_cnt),CHR(10),' '), cv_quot, ' '), cv_delimit, ' ') || cv_quot;
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_num ) THEN
        --NUMBER
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(ln_cnt);
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_dat ) THEN
        --DATE
        lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(ln_cnt);
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --連携日時
    lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(90);
    --
    -- ====================================================
    -- ファイル書き込み
    -- ====================================================
    BEGIN
    UTL_FILE.PUT_LINE(gv_file_hand
                     ,lv_file_data
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfo
                                ,cv_msg_cfo_00030)
                              ,1
                              ,5000
                              );
        --
      lv_errbuf  := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END;
    --成功件数カウント
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : get_invoice
   * Description      : 対象データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_invoice(
    iv_cutoff_date IN  VARCHAR2, --   締日
    ov_errbuf      OUT VARCHAR2, --   エラー・メッセージ                  --# 固定 #
    ov_retcode     OUT VARCHAR2, --   リターン・コード                    --# 固定 #
    ov_errmsg      OUT VARCHAR2) --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_invoice'; -- プログラム名
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
    lv_msgcode                 VARCHAR2(5000);                  -- A-4の戻りメッセージコード(型桁チェック)
    ld_cutoff_date             DATE;                            --処理対象締日
    lv_invoice_info_name       VARCHAR2(12);                    --請求情報メッセージ出力用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    CURSOR get_invoice_fixed_cur
    IS
    SELECT /*+ LEADING(xih) */
           xih.invoice_id                      AS  invoice_id                           --一括請求書ID
          ,xih.set_of_books_id                 AS  set_of_books_id                      --会計帳簿ID
          ,xih.cutoff_date                     AS  cutoff_date                          --締日
          ,xih.term_name                       AS  term_name                            --支払条件
          ,xih.term_id                         AS  term_id                              --支払条件ID
          ,xih.due_months_forword              AS  due_months_forword                   --サイト月数
          ,xih.month_remit                     AS  month_remit                          --月限
          ,xih.payment_date                    AS  payment_date                         --支払日
          ,xih.tax_type                        AS  tax_type                             --消費税区分
          ,flv1.meaning                        AS  tax_div_name                         --消費税区分名
          ,xih.tax_gap_trx_id                  AS  tax_gap_trx_id                       --税差額取引ID
          ,xih.tax_gap_amount                  AS  tax_gap_amount                       --税差額
          ,xih.inv_amount_no_tax               AS  inv_amount_no_tax                    --税抜請求金額合計
          ,xih.tax_amount_sum                  AS  tax_amount_sum                       --税額合計
          ,xih.inv_amount_includ_tax           AS  inv_amount_includ_tax                --税込請求金額合計
          ,xih.itoen_name                      AS  itoen_name                           --取引先名
          ,xih.postal_code                     AS  postal_code                          --送付先郵便番号
          ,xih.send_address1                   AS  send_address1                        --送付先住所1
          ,xih.send_address2                   AS  send_address2                        --送付先住所2
          ,xih.send_address3                   AS  send_address3                        --送付先住所3
          ,xih.send_to_name                    AS  send_to_name                         --送付先名
          ,xih.inv_creation_date               AS  inv_creation_date                    --作成日
          ,xih.object_month                    AS  object_month                         --対象年月
          ,xih.object_date_from                AS  object_date_from                     --対象期間（自）
          ,xih.object_date_to                  AS  object_date_to                       --対象期間（至）
          ,xih.vender_code                     AS  vender_code                          --仕入先コード
          ,xih.receipt_location_code           AS  receipt_location_code                --入金拠点コード
          ,ffv1.base_name                      AS  base_name                            --入金拠点名
          ,xih.bill_location_code              AS  bill_location_code                   --請求拠点コード
          ,xih.bill_location_name              AS  bill_location_name                   --請求拠点名
          ,xih.bill_cust_code                  AS  bill_cust_code                       --請求先顧客コード
          ,xih.bill_cust_name                  AS  bill_cust_name                       --請求先顧客名
          ,xih.bill_cust_kana_name             AS  bill_cust_kana_name                  --請求先顧客カナ名
          ,xih.bill_cust_account_id            AS  bill_cust_account_id                 --請求先顧客ID
          ,xih.bill_cust_acct_site_id          AS  bill_cust_acct_site_id               --請求先顧客所在地ID
          ,xih.bill_shop_code                  AS  bill_shop_code                       --請求先店舗コード
          ,xih.bill_shop_name                  AS  bill_shop_name                       --請求先店名
          ,xih.credit_receiv_code2             AS  credit_receiv_code2                  --売掛コード2（事業所）
          ,xih.credit_receiv_name2             AS  credit_receiv_name2                  --売掛コード2（事業所）名称
          ,xih.credit_receiv_code3             AS  credit_receiv_code3                  --売掛コード3（その他）
          ,xih.credit_receiv_name3             AS  credit_receiv_name3                  --売掛コード3（その他）名称
          ,xil.invoice_detail_num              AS  invoice_detail_num                   --一括請求書明細No
          ,xil.note_line_id                    AS  note_line_id                         --伝票明細No
          ,xil.ship_cust_code                  AS  ship_cust_code                       --納品先顧客コード
          ,xil.ship_cust_name                  AS  ship_cust_name                       --納品先顧客名
          ,xil.ship_cust_kana_name             AS  ship_cust_kana_name                  --納品先顧客カナ名
          ,xil.sold_location_code              AS  sold_location_code                   --売上拠点コード
          ,xil.sold_location_name              AS  sold_location_name                   --売上拠点名
          ,xil.ship_shop_code                  AS  ship_shop_code                       --納品先店舗コード
          ,xil.ship_shop_name                  AS  ship_shop_name                       --納品先店名
          ,xil.inv_type                        AS  inv_type                             --請求区分
          ,flv2.meaning                        AS  inv_name                             --請求区分名
          ,xil.vd_cust_type                    AS  vd_cust_type                         --VD顧客区分
          ,flv3.meaning                        AS  vd_cust_name                         --VD顧客区分名
          ,xil.chain_shop_code                 AS  chain_shop_code                      --チェーン店コード
          ,hp.party_name                       AS  edi_chain_code_name                  --チェーン店名
          ,xil.delivery_date                   AS  delivery_date                        --納品日
          ,xil.slip_num                        AS  slip_num                             --伝票番号
          ,xil.order_num                       AS  order_num                            --オーダーNO
          ,xil.slip_type                       AS  slip_type                            --伝票区分
          ,xil.classify_type                   AS  classify_type                        --分類区分
          ,xil.customer_dept_code              AS  customer_dept_code                   --お客様部門コード
          ,xil.customer_division_code          AS  customer_division_code               --お客様課コード
          ,xil.sold_return_type                AS  sold_return_type                     --売上返品区分
          ,flv4.meaning                        AS  sold_return_name                     --売上返品区分名
          ,xil.nichiriu_by_way_type            AS  nichiriu_by_way_type                 --ニチリウ経由区分
          ,xil.sale_type                       AS  sale_type                            --特売区分
          ,xil.direct_num                      AS  direct_num                           --便No
          ,xil.po_date                         AS  po_date                              --発注日
          ,xil.acceptance_date                 AS  acceptance_date                      --検収日
          ,xil.item_code                       AS  item_code                            --商品CD
          ,xil.item_name                       AS  item_name                            --商品名
          ,xil.item_kana_name                  AS  item_kana_name                       --商品カナ名
          ,xil.policy_group                    AS  policy_group                         --政策群コード
          ,mc.policy_group_name                AS  policy_group_name                    --政策群コード名
          ,xil.jan_code                        AS  jan_code                             --JANコード
          ,xil.quantity                        AS  quantity                             --数量
          ,xil.unit_price                      AS  unit_price                           --単価
          ,xil.dlv_qty                         AS  dlv_qty                              --納品数量
          ,xil.dlv_unit_price                  AS  dlv_unit_price                       --納品単価
          ,xil.tax_amount                      AS  tax_amount                           --消費税金額
          ,xil.tax_rate                        AS  tax_rate                             --消費税率
          ,xil.ship_amount                     AS  ship_amount                          --納品金額
          ,xil.sold_amount                     AS  sold_amount                          --売上金額
          ,xil.red_black_slip_type             AS  red_black_slip_type                  --赤伝黒伝区分
          ,xil.delivery_chain_code             AS  delivery_chain_code                  --納品先チェーンコード
          ,flv5.description                    AS  delivery_chain_name                  --納品先チェーン名
          ,xil.tax_code                        AS  tax_code                             --税金コード
          ,avtab.description                   AS  description                          --税金名
          ,gv_coop_date                        AS  cool_date                            --連携日時
    FROM   apps.xxcfr_invoice_headers      xih    --請求ヘッダ情報テーブル
          ,apps.xxcfr_invoice_lines        xil    --請求明細情報テーブル
          ,apps.fnd_lookup_values          flv1   --消費税区分名取得用
          ,(
             SELECT ffvl.flex_value  base_code    --入金拠点コード
                   ,ffvl.attribute4  base_name    --入金拠点名
             FROM   apps.fnd_flex_value_sets           ffvs
                   ,apps.fnd_flex_values               ffvl
                   ,apps.fnd_flex_values_tl            ffvt
             WHERE  ffvl.flex_value_set_id    =  ffvs.flex_value_set_id
               AND  ffvt.flex_value_id        =  ffvl.flex_value_id
               AND  ffvt.language             =  cv_lang
               AND  ffvl.summary_flag         =  cv_flag_n
               AND  ffvs.flex_value_set_name  =  cv_flex_value_department
           ) ffv1                                 --入金拠点名取得用
          ,apps.fnd_lookup_values          flv2   --請求区分名取得用
          ,apps.fnd_lookup_values          flv3   --VD顧客区分名取得用
          ,apps.xxcmm_cust_accounts        xca    --顧客追加情報(チェーン店名取得用)
          ,apps.hz_cust_accounts           hca    --顧客マスタ(チェーン店名取得用)
          ,apps.hz_parties                 hp     --パーティマスタ(チェーン店名取得用)
          ,apps.fnd_lookup_values          flv4   --売上返品区分名取得用
          ,(
             SELECT mcb.segment1     policy_group
                   ,mct.description  policy_group_name
             FROM   apps.mtl_categories_b           mcb    --カテゴリマスタ(政策群コード名取得用)
                   ,apps.mtl_category_sets_b        mcsb   --カテゴリセットマスタ(政策群コード名取得用)
                   ,apps.mtl_categories_tl          mct    --カテゴリ日本語マスタ(政策群コード名取得用)
             WHERE  mcb.structure_id            = mcsb.structure_id
             AND    mcsb.category_set_id        = 1100000022
             AND    mcb.category_id             = mct.category_id
             AND    mct.language                = cv_lang
             AND    mct.source_lang             = cv_lang
           ) mc                                   --政策群コード名取得用
          ,apps.fnd_lookup_values          flv5   --納品先チェーン名取得用
          ,apps.ar_vat_tax_all_b           avtab  --税コード名取得用
    WHERE  xih.invoice_id             = xil.invoice_id
      AND  xih.cutoff_date            = ld_cutoff_date               --処理対象日付
      AND  xih.tax_type               = flv1.lookup_code(+)          --消費税区分名取得
      AND  flv1.language(+)           = cv_lang                      --消費税区分名取得
      AND  flv1.lookup_type(+)        = cv_lookup_syohizei_kbn       --消費税区分名取得
      AND  flv1.enabled_flag(+)       = cv_flag_y                    --消費税区分名取得
      AND  xih.receipt_location_code  = ffv1.base_code (+)           --入金拠点名取得
      AND  xil.inv_type               = flv2.lookup_code(+)          --請求区分名取得
      AND  flv2.language(+)           = cv_lang                      --請求区分名取得
      AND  flv2.lookup_type(+)        = cv_lookup_invoice_kbn        --請求区分名取得
      AND  flv2.enabled_flag(+)       = cv_flag_y                    --請求区分名取得
      AND  xil.vd_cust_type           = flv3.lookup_code(+)          --VD顧客区分名取得
      AND  flv3.language(+)           = cv_lang                      --VD顧客区分名取得
      AND  flv3.lookup_type(+)        = cv_lookup_vd_customer_kbn    --VD顧客区分名取得
      AND  flv3.enabled_flag(+)       = cv_flag_y                    --VD顧客区分名取得
      AND  xil.chain_shop_code        = xca.edi_chain_code(+)        --チェーン店名取得
      AND  xca.customer_id            = hca.cust_account_id(+)       --チェーン店名取得
      AND  hca.party_id               = hp.party_id(+)               --チェーン店名取得
      AND  hca.customer_class_code(+) = cv_18                        --チェーン店名取得
      AND  xil.sold_return_type       = flv4.attribute1(+)           --売上返品区分名取得
      AND  flv4.lookup_type(+)        = cv_lookup_delivery_slip      --売上返品区分名取得
      AND  flv4.language(+)           = cv_lang                      --売上返品区分名取得
      AND  flv4.lookup_code(+)        IN (cv_1,cv_2)                 --売上返品区分名取得
      AND  xil.policy_group           = mc.policy_group(+)           --政策群コード名取得
      AND  xil.delivery_chain_code    = flv5.lookup_code(+)          --納品先チェーン名取得用
      AND  flv5.language(+)           = cv_lang                      --納品先チェーン名取得用
      AND  flv5.lookup_type(+)        = cv_lookup_chain_code         --納品先チェーン名取得用
      AND  flv5.enabled_flag(+)       = cv_flag_y                    --納品先チェーン名取得用
      AND  xil.tax_code               = avtab.tax_code(+)            --税コード名取得用
      AND  avtab.set_of_books_id(+)   = gn_set_of_bks_id             --税コード名取得用
      AND  avtab.org_id(+)            = gn_org_id                    --税コード名取得用
      AND  avtab.enabled_flag(+)      = cv_flag_y                    --税コード名取得用
    ;
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
    --メッセージトークン取得
    --==============================================================
--
    lv_invoice_info_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                      ,cv_msgtkn_cfo_11178);         -- 一括情報
--
    --==============================================================
    --対象データ取得
    --==============================================================
      --処理対象締日計算
      IF (iv_cutoff_date IS NULL) THEN
        --業務日付 - 電子帳簿処理実行日数
        ld_cutoff_date := gd_process_date - TO_NUMBER(gt_electric_exec_days);
      ELSE
        --締日(インパラメータ)
        ld_cutoff_date := TO_DATE( iv_cutoff_date , cv_date_format_ymdshms );
      END IF;
      --カーソルオープン
      OPEN get_invoice_fixed_cur;
      <<main_loop>>
      LOOP
      FETCH get_invoice_fixed_cur INTO
            gt_data_tab(1)  --一括請求書ID
          , gt_data_tab(2)  --会計帳簿ID
          , gt_data_tab(3)  --締日
          , gt_data_tab(4)  --支払条件
          , gt_data_tab(5)  --支払条件ID
          , gt_data_tab(6)  --サイト月数
          , gt_data_tab(7)  --月限
          , gt_data_tab(8)  --支払日
          , gt_data_tab(9)  --消費税区分
          , gt_data_tab(10) --消費税区分名
          , gt_data_tab(11) --税差額取引ID
          , gt_data_tab(12) --税差額
          , gt_data_tab(13) --税抜請求金額合計
          , gt_data_tab(14) --税額合計
          , gt_data_tab(15) --税込請求金額合計
          , gt_data_tab(16) --取引先名
          , gt_data_tab(17) --送付先郵便番号
          , gt_data_tab(18) --送付先住所1
          , gt_data_tab(19) --送付先住所2
          , gt_data_tab(20) --送付先住所3
          , gt_data_tab(21) --送付先名
          , gt_data_tab(22) --作成日
          , gt_data_tab(23) --対象年月
          , gt_data_tab(24) --対象期間（自）
          , gt_data_tab(25) --対象期間（至）
          , gt_data_tab(26) --仕入先コード
          , gt_data_tab(27) --入金拠点コード
          , gt_data_tab(28) --拠点名
          , gt_data_tab(29) --請求拠点コード
          , gt_data_tab(30) --請求拠点名
          , gt_data_tab(31) --請求先顧客コード
          , gt_data_tab(32) --請求先顧客名
          , gt_data_tab(33) --請求先顧客カナ名
          , gt_data_tab(34) --請求先顧客ID
          , gt_data_tab(35) --請求先顧客所在地ID
          , gt_data_tab(36) --請求先店舗コード
          , gt_data_tab(37) --請求先店名
          , gt_data_tab(38) --売掛コード2（事業所）
          , gt_data_tab(39) --売掛コード2（事業所）名称
          , gt_data_tab(40) --売掛コード3（その他）
          , gt_data_tab(41) --売掛コード3（その他）名称
          , gt_data_tab(42) --一括請求書明細No
          , gt_data_tab(43) --伝票明細No
          , gt_data_tab(44) --納品先顧客コード
          , gt_data_tab(45) --納品先顧客名
          , gt_data_tab(46) --納品先顧客カナ名
          , gt_data_tab(47) --売上拠点コード
          , gt_data_tab(48) --売上拠点名
          , gt_data_tab(49) --納品先店舗コード
          , gt_data_tab(50) --納品先店名
          , gt_data_tab(51) --請求区分
          , gt_data_tab(52) --請求区分名
          , gt_data_tab(53) --VD顧客区分
          , gt_data_tab(54) --VD顧客区分名
          , gt_data_tab(55) --チェーン店コード
          , gt_data_tab(56) --チェーン店名
          , gt_data_tab(57) --納品日
          , gt_data_tab(58) --伝票番号
          , gt_data_tab(59) --オーダーNO
          , gt_data_tab(60) --伝票区分
          , gt_data_tab(61) --分類区分
          , gt_data_tab(62) --お客様部門コード
          , gt_data_tab(63) --お客様課コード
          , gt_data_tab(64) --売上返品区分
          , gt_data_tab(65) --売上返品区分名
          , gt_data_tab(66) --ニチリウ経由区分
          , gt_data_tab(67) --特売区分
          , gt_data_tab(68) --便No
          , gt_data_tab(69) --発注日
          , gt_data_tab(70) --検収日
          , gt_data_tab(71) --商品CD
          , gt_data_tab(72) --商品名
          , gt_data_tab(73) --商品カナ名
          , gt_data_tab(74) --政策群コード
          , gt_data_tab(75) --政策群コード名
          , gt_data_tab(76) --JANコード
          , gt_data_tab(77) --数量
          , gt_data_tab(78) --単価
          , gt_data_tab(79) --納品数量
          , gt_data_tab(80) --納品単価
          , gt_data_tab(81) --消費税金額
          , gt_data_tab(82) --消費税率
          , gt_data_tab(83) --納品金額
          , gt_data_tab(84) --売上金額
          , gt_data_tab(85) --赤伝黒伝区分
          , gt_data_tab(86) --納品先チェーンコード
          , gt_data_tab(87) --納品先チェーン名
          , gt_data_tab(88) --税金コード
          , gt_data_tab(89) --税金名
          , gt_data_tab(90) --連携日時
          ;
        EXIT WHEN get_invoice_fixed_cur%NOTFOUND;
--
        --
        --==============================================================
        --項目チェック処理(A-3)
        --==============================================================
        chk_item(
          ov_msgcode                    =>        lv_msgcode     -- メッセージコード
         ,ov_errbuf                     =>        lv_errbuf      -- エラー・メッセージ
         ,ov_retcode                    =>        lv_retcode     -- リターン・コード
         ,ov_errmsg                     =>        lv_errmsg);    -- ユーザー・エラー・メッセージ
        IF ( ( lv_retcode = cv_status_normal ) AND ( gn_warn_cnt = 0 ) ) THEN
          -- 項目チェックの戻りが正常かつ0Byteファイル上書きフラグが'N'の場合、CSV出力を行う
          --==============================================================
          -- CSV出力処理(A-4)
          --==============================================================
          out_csv (
            ov_errbuf                   =>        lv_errbuf
           ,ov_retcode                  =>        lv_retcode
           ,ov_errmsg                   =>        lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --処理を中断
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        --対象件数に1カウント
        gn_target_cnt      := gn_target_cnt + 1;
--
      END LOOP main_loop;
      CLOSE get_invoice_fixed_cur;
--
    --==================================================================
    -- 0件の場合はメッセージ出力
    --==================================================================
    IF gn_target_cnt = 0 THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,cv_msg_cfo_10025      -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data       -- トークン'GET_DATA' 
                                                     ,lv_invoice_info_name  -- 請求情報
                                                    )
                            ,1
                            ,5000
                          );
      --ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_invoice;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_cutoff_date        IN  VARCHAR2, --   1.締日
    iv_file_name          IN  VARCHAR2, --   2.ファイル名
    ov_errbuf             OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ローカル・カーソル
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
--
    -- グローバル変数の初期化
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_cutoff_date      -- 1.締日
      ,iv_file_name        -- 2.ファイル名
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象データ取得(A-2)
    -- ===============================
    get_invoice(
      iv_cutoff_date      -- 締日
     ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,lv_retcode          -- リターン・コード             --# 固定 #
     ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      gv_0file_flg := cv_flag_y;
      RAISE global_process_expt;
    ELSIF ( gn_warn_cnt <> 0 ) THEN
      gv_0file_flg := cv_flag_y;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    errbuf                OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_cutoff_date        IN  VARCHAR2,      -- 1.締日
    iv_file_name          IN  VARCHAR2       -- 2.ファイル名
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_cutoff_date                              -- 1.締日
      ,iv_file_name                                -- 2.ファイル名
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      -- 会計チーム標準：異常終了時の件数設定
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
    END IF;
--
    IF ( lv_retcode = cv_status_warn ) THEN
      -- 会計チーム標準：警告終了時の件数設定
      gn_normal_cnt := 0;
    END IF;
--
    -- ====================================================
    -- ファイルクローズ
    -- ====================================================
    -- ファイルがオープンされている場合はクローズする
    IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    -- ====================================================
    -- ファイル0Byte更新
    -- ====================================================
    -- A-2以降の処理でエラーが発生していた場合、
    -- ファイルを再度オープン＆クローズし、0Byteに更新する
    IF ( ( ( lv_retcode = cv_status_error ) OR ( lv_retcode = cv_status_warn ) ) 
         AND ( gv_0file_flg = cv_flag_y ) ) THEN
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gt_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                       ,cn_max_linesize
                                      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- ファイルオープンエラー
                                                       )
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
      END;
      --ファイルクローズ
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_ccp_00001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
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
END XXCFO019A13C;
/
