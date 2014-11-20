CREATE OR REPLACE PACKAGE BODY XXCSM004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A06C(Body)
 * Description      : EBS(ファイルアップロードIF)に取込まれた什器ポイントデータを
 *                  : 新規獲得ポイント顧客別履歴テーブルに取込みます。
 * MD.050           : MD050_CSM_004_A06_什器ポイント一括取込
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_if_data            ファイルアップロードIFデータ取得(A-2)
 *  check_year_month       年月チェック(A-4)
 *  delete_old_data        データ削除(A-5)
 *  check_item             項目妥当性チェック(A-7)
 *  insert_data            登録処理(A-8)
 *  loop_main              LOOP、什器ポイントデータ取得、セーブポイントの設定(A-3,A-6)
 *                            ・check_year_month
 *                            ・delete_old_data
 *                            ・check_item
 *                            ・insert_data
 *  final                  終了処理(A-9)
 *  submain                メイン処理プロシージャ
 *                            ・init
 *                            ・get_if_data
 *                            ・loop_main
 *                            ・final
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                            ・main
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/03    1.0   SCS M.Ohtsuki    新規作成
 *  2009/04/06    1.1   SCS M.Ohtsuki    [障害T1_0241]開始日取得NVL対応
 *  2009/04/09    1.2   SCS M.Ohtsuki    [障害T1_0416]業務日付とシステム日付比較の不具合
 *  2009/04/14    1.3   SCS M.Ohtsuki    [障害T1_0500]年月チェック条件の不具合対応
 *  2009/08/19    1.4   SCS T.Tsukino    [障害0001111]警告終了のエラーメッセージログ出力の変更対応
 *  2010/01/18    1.5   SCS T.Nakano     [E_本稼動_01039]データ区分チェック追加対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;           -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;             -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;            -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                           -- CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                                      -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                           -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                                      -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;                   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;                      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;                   -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                                      -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- 想定外エラーメッセージ
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- 対象件数
  gn_normal_cnt             NUMBER;                                                                 -- 正常件数
  gn_error_cnt              NUMBER;                                                                 -- エラー件数
  gn_warn_cnt               NUMBER;                                                                 -- スキップ件数
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM004A06C';                               -- パッケージ名
  cv_param_msg_1            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00101';                           -- パラメータ出力用メッセージ
  cv_param_msg_2            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00102';                           -- パラメータ出力用メッセージ
  cv_file_name              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00109';                           -- インターフェースファイル名
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                                          -- カンマ
  --エラーメッセージコード
  cv_csm_msg_005            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- プロファイル取得エラーメッセージ
  cv_csm_msg_022            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00022';                           -- ファイルアップロードIFテーブルロック取得エラーメッセージ
  cv_csm_msg_108            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00108';                           -- ファイルアップロード名称
  cv_csm_msg_139            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10139';                           -- 獲得年月チェックエラーメッセージ
  cv_csm_msg_140            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10140';                           -- 新規獲得ポイント顧客別履歴テーブルロック取得エラーメッセージ
  cv_csm_msg_141            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10141';                           -- 年月空白チェックエラーメッセージ
  cv_csm_msg_142            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10142';                           -- ポイント取込不可能期間メッセージ
  cv_csm_msg_143            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10143';                           -- 拠点コードチェックエラーメッセージ
  cv_csm_msg_144            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10144';                           -- 顧客コードチェックエラーメッセージ
  cv_csm_msg_145            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10145';                           -- 従業員チェックエラーメッセージ
  cv_csm_msg_146            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10146';                           -- ポイントチェックエラーメッセージ
  cv_csm_msg_147            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10147';                           -- 獲得・紹介区分チェックエラーメッセージ
  cv_csm_msg_148            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10148';                           -- 廃止拠点チェックエラーメッセージ
  cv_csm_msg_149            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10149';                           -- 什器ポイントデータフォーマットチェックエラーメッセージ
  cv_csm_msg_151            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10151';                           -- 什器ポイント項目属性チェックエラーメッセージ
  cv_csm_msg_152            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10152';                           -- 登録データ0件メッセージ
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
  cv_csm_msg_158            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10158';                           -- データ区分エラーメッセージ
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
--//+ADD START 2009/04/14 T1_0500 M.Ohtsuki
  cv_csm_msg_021            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00021';                           -- 年度取得エラーメッセージ
--//+ADD END   2009/04/14 T1_0500 M.Ohtsuki
--
  --トークンコード
  cv_tkn_prf_nm             CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- プロファイル名
  cv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';                                      -- 処理件数
  cv_tkn_file_id            CONSTANT VARCHAR2(100) := 'FILE_ID';                                    -- ファイルID
  cv_tkn_format             CONSTANT VARCHAR2(100) := 'FORMAT';                                     -- フォーマット
  cv_tkn_up_name            CONSTANT VARCHAR2(100) := 'UPLOAD_NAME';                                -- ファイルアップロード名称
  cv_tkn_file_name          CONSTANT VARCHAR2(100) := 'FILE_NAME';                                  -- ファイル名
  cv_tkn_yyyymm             CONSTANT VARCHAR2(100) := 'YYYYMM';                                     -- 年月
  cv_tkn_emp_cd             CONSTANT VARCHAR2(100) := 'EMPLOYEE_CD';                                -- 従業員コード
  cv_tkn_loc_cd             CONSTANT VARCHAR2(100) := 'LOCATION_CD';                                -- 拠点コード
  cv_tkn_cust_cd            CONSTANT VARCHAR2(100) := 'CUSTOMER_CD';                                -- 顧客コード
--//+ADD START 2010/01/18 E_本稼動_01039 T.Nakano
  cv_data_kbn               CONSTANT VARCHAR2(100) := 'DATA_KBN';                                   -- データ区分
--//+ADD END 2010/01/18 E_本稼動_01039 T.Nakano
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(100) := 'ERR_MSG';                                    -- SQLエラーメッセージ
  --アプリケーション短縮名
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                                      -- アプリケーション短縮名
  cv_chk_warning            CONSTANT VARCHAR2(1)   := '1';                                          -- 警告
  cv_chk_normal             CONSTANT VARCHAR2(1)   := '0';                                          -- 正常
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  TYPE gr_def_info_rtype IS RECORD                                                                  -- レコード型を宣言
      (meaning    VARCHAR2(100)                                                                     -- 項目名
      ,attribute  VARCHAR2(100)                                                                     -- 項目属性
      ,essential  VARCHAR2(100)                                                                     -- 必須フラグ
      ,figures    NUMBER                                                                            -- 項目の長さ
      );
  TYPE gt_def_info_ttype IS TABLE OF gr_def_info_rtype                                              -- テーブル型の宣言
    INDEX BY BINARY_INTEGER;
--
  TYPE gt_check_data_ttype IS TABLE OF VARCHAR2(4000)                                               -- テーブル型の宣言
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  --テーブル型変数の宣言
  gt_def_info_tab           gt_def_info_ttype;                                                      -- テーブル型変数の宣言
  --
  gn_counter                NUMBER;                                                                 -- 処理件数カウンター
  gn_file_id                NUMBER;                                                                 -- パラメータ(ファイルID)格納用変数
  gv_format                 VARCHAR2(100);                                                          -- パラメータ(フォーマット)格納用変数
  gn_item_num               NUMBER;                                                                 -- 什器ポイント項目数格納用
  gn_set_of_bks_id          NUMBER;                                                                 -- 会計帳簿ID格納用
  gv_appl_ar                VARCHAR2(100);                                                          -- ARアプリケーション短縮名格納用
  gv_subject_year           VARCHAR2(100);                                                          -- 対象年度格納用
  gd_process_date           DATE;                                                                   -- 業務日付
  gv_warnig_flg             VARCHAR2(1);                                                            -- 警告フラグ
  gv_check_flag             VARCHAR2(1);                                                            -- チェックフラグ
  gv_low_type               VARCHAR2(10);                                                           -- 業態（小分類）
  gn_canncel_flg            NUMBER;                                                                 -- 廃止拠点チェック
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    ov_errbuf               OUT NOCOPY VARCHAR2                                                     -- エラー・メッセージ
   ,ov_retcode              OUT NOCOPY VARCHAR2                                                     -- リターン・コード
   ,ov_errmsg               OUT NOCOPY VARCHAR2                                                     -- ユーザー・エラー・メッセージ
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';                                       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode              VARCHAR2(1);                                                            -- リターン・コード
    lv_errbuf               VARCHAR2(4000);                                                         -- エラー・メッセージ
    lv_errmsg               VARCHAR2(4000);                                                         -- ユーザー・エラー・メッセージ
    lv_tkn_value            VARCHAR2(4000);                                                         -- トークン値
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--プロファイル取得用
    cv_item_num             CONSTANT VARCHAR2(100) := 'XXCSM1_VENDING_PNT_ITEM_NUM';                -- 什器ポイントデータ項目数
    cv_set_of_bks_id        CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                           -- 会計帳簿ID
--
    cv_upload_obj           CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';                     -- ファイルアップロードオブジェクト
    cv_vending_item         CONSTANT VARCHAR2(100) := 'XXCSM1_VENDING_PNT_ITEM';                    -- 什器ポイントデータ項目定義
    cv_null_ok              CONSTANT VARCHAR2(100) := 'NULL_OK';                                    -- 任意項目
    cv_null_ng              CONSTANT VARCHAR2(100) := 'NULL_NG';                                    -- 必須項目
    cv_varchar              CONSTANT VARCHAR2(100) := 'VARCHAR2';                                   -- 文字列
    cv_number               CONSTANT VARCHAR2(100) := 'NUMBER';                                     -- 数値
    cv_date                 CONSTANT VARCHAR2(100) := 'DATE';                                       -- 日付
    cv_varchar_cd           CONSTANT VARCHAR2(100) := '0';                                          -- 文字列項目
    cv_number_cd            CONSTANT VARCHAR2(100) := '1';                                          -- 数値項目
    cv_date_cd              CONSTANT VARCHAR2(100) := '2';                                          -- 日付項目
    cv_not_null             CONSTANT VARCHAR2(100) := '1';                                          -- 必須
    cv_appl_ar              CONSTANT VARCHAR2(100) := 'AR';                                         -- アプリケーション短縮名
--
    -- *** ローカル変数 ***
    ln_cnt                  NUMBER;                                                                 -- カウンタ
    lv_up_name              VARCHAR2(1000);                                                         -- アップロード名称出力用
    lv_in_file_id           VARCHAR2(1000);                                                         -- ファイルＩＤ出力用
    lv_in_format            VARCHAR2(1000);                                                         -- フォーマット出力用
    lv_upload_obj           VARCHAR2(100);                                                          -- ファイルアップロード名称
--
    get_err_expt            EXCEPTION;
    -- *** ローカル・カーソル ***
    CURSOR   get_def_info_cur                                                                       -- データ項目定義取得用カーソル
    IS
      SELECT   flv.meaning                                               meaning                    -- 内容
              ,DECODE(flv.attribute1,cv_varchar,cv_varchar_cd
                                    ,cv_number,cv_number_cd,cv_date_cd)  attribute                  -- 項目属性
              ,DECODE(flv.attribute2,cv_not_null,cv_null_ng,cv_null_ok)  essential                  -- 必須フラグ
              ,TO_NUMBER(flv.attribute3)                                 figures                    -- 項目の長さ
      FROM     fnd_lookup_values  flv                                                               -- クイックコード値
      WHERE    flv.lookup_type        = cv_vending_item                                             -- 什器ポイントデータ項目定義
        AND    flv.language           = USERENV('LANG')                                             -- 言語('JA')
        AND    flv.enabled_flag       = 'Y'                                                         -- 使用可能フラグ
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--        AND    flv.start_date_active <= gd_process_date                                             -- 適用開始日
--        AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date                                -- 適用終了日
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
        AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                        -- 適用開始日
        AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date                        -- 適用終了日
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
      ORDER BY flv.lookup_code   ASC;                                                               -- ルックアップコード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode    := cv_status_normal;
    lv_tkn_value  := NULL;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-1 ①業務日付の取得
    --==============================================================
--
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- 業務日付取得
--
    --==============================================================
    --A-1 ②プロファイル値取得
    --==============================================================
--
    gn_item_num      := FND_PROFILE.VALUE(cv_item_num);                                             -- 什器ポイントデータ項目数
    gn_set_of_bks_id := FND_PROFILE.VALUE(cv_set_of_bks_id);                                        -- 会計帳簿ID
--
    IF (gn_item_num IS NULL) THEN                                                                   -- 什器ポイントデータ項目数の取得失敗
      lv_tkn_value    := cv_item_num;
    ELSIF (gn_set_of_bks_id IS NULL) THEN                                                           -- 会計帳簿IDの取得失敗
      lv_tkn_value    := cv_set_of_bks_id;
    END IF;
--
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm                             -- XXCSM
                                           ,iv_name         => cv_csm_msg_005                       -- プロファイル取得エラーメッセージ
                                           ,iv_token_name1  => cv_tkn_prf_nm                        -- PROF_NAME
                                           ,iv_token_value1 => lv_tkn_value                         -- プロファイル名称
                                           );
      lv_errbuf := lv_errmsg;
      RAISE get_err_expt;
    END IF;
--
    --==============================================================
    --A-1  ③ARアプリケーションIDの取得
    --==============================================================
--
    gv_appl_ar := xxccp_common_pkg.get_application(cv_appl_ar);                                     -- ARアプリケーションID取得
--
    --==============================================================
    --A-1  ④什器ポイントデータ定義情報取得
    --==============================================================
--
    ln_cnt := 0;                                                                                    -- 変数の初期化
    <<def_info_loop>>                                                                               -- テーブル定義取得LOOP
    FOR rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_def_info_tab(ln_cnt).meaning   := rec.meaning;                                             -- 項目名
      gt_def_info_tab(ln_cnt).attribute := rec.attribute;                                           -- 項目属性
      gt_def_info_tab(ln_cnt).essential := rec.essential;                                           -- 必須フラグ
      gt_def_info_tab(ln_cnt).figures   := rec.figures;                                             -- 項目の長さ
    END LOOP def_info_loop;
--
    --==============================================================
    --A-1  ⑤ファイルアップロード名称の取得
    --==============================================================
--
    SELECT   flv.meaning  meaning
    INTO     lv_upload_obj
    FROM     fnd_lookup_values flv
    WHERE    flv.lookup_type        = cv_upload_obj                                                 -- ファイルアップロードオブジェクト
      AND    flv.lookup_code        = TO_CHAR(gv_format)
      AND    flv.language           = USERENV('LANG')                                               -- 言語('JA')
      AND    flv.enabled_flag       = 'Y'                                                           -- 使用可能フラグ
--//+UPD START 2009/04/06 T1_0241 M.Ohtsuki
--      AND    flv.start_date_active <= gd_process_date                                               -- 適用開始日
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓適用開始日NVL対応
      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                          -- 適用開始日
--//+UPD END   2009/04/06 T1_0241 M.Ohtsuki
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--      AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date;                                 -- 適用終了日
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓適用開始日NVL対応
      AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date;                                 -- 適用終了日
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
--
    --==============================================================
    --A-1 ⑥INパラメータの出力
    --==============================================================
--
    lv_up_name    := xxccp_common_pkg.get_msg(                                                      -- アップロード名称の出力
                       iv_application  => cv_xxcsm                                                  -- XXCSM
                      ,iv_name         => cv_csm_msg_108                                            -- ファイルアップロード名称
                      ,iv_token_name1  => cv_tkn_up_name                                            -- UPLOAD_NAME
                      ,iv_token_value1 => lv_upload_obj                                             -- アップロード名称
                      );
    lv_in_file_id := xxccp_common_pkg.get_msg(                                                      -- ファイルIDの出力
                       iv_application  => cv_xxcsm                                                  -- XXCSM
                      ,iv_name         => cv_param_msg_1                                            -- コンカレント入力パラメータメッセージ(ファイルID)
                      ,iv_token_name1  => cv_tkn_file_id                                            -- FILE_ID
                      ,iv_token_value1 => gn_file_id                                                -- ファイルID1
                      );
    lv_in_format  := xxccp_common_pkg.get_msg(                                                      -- フォーマットの出力
                       iv_application  => cv_xxcsm                                                  -- XXCSM
                      ,iv_name         => cv_param_msg_2                                            -- コンカレント入力パラメータメッセージ(フォーマット)
                      ,iv_token_name1  => cv_tkn_format                                             -- FORMAT
                      ,iv_token_value1 => gv_format                                                 -- フォーマット
                      );
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- 出力に表示
                     ,buff   => lv_up_name    || CHR(10) ||
                                lv_in_file_id || CHR(10) ||
                                lv_in_format
                                );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ログに表示
                     ,buff   => lv_up_name    || CHR(10) ||
                                lv_in_file_id || CHR(10) ||
                                lv_in_format
                                );
--
  EXCEPTION
    WHEN get_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_if_data(
    ov_errbuf     OUT NOCOPY   VARCHAR2                                                             -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY   VARCHAR2                                                             -- リターン・コード
   ,ov_errmsg     OUT NOCOPY   VARCHAR2)                                                            -- ユーザー・エラー・メッセージ
  IS
--
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';                                      -- プログラム名
--
    lv_errbuf         VARCHAR2(4000);                                                               -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);                                                                  -- リターン・コード
    lv_errmsg         VARCHAR2(4000);                                                               -- ユーザー・エラー・メッセージ
--
    ln_cnt_a          NUMBER;                                                                       -- カウンタを宣言
    ln_cnt_b          NUMBER;                                                                       -- カウンタを宣言
    ln_item_cnt       NUMBER;                                                                       -- カウンタを宣言
    lv_file_name      VARCHAR2(100);                                                                -- ファイル名格納用
    lv_created_by     VARCHAR2(100);                                                                -- 作成者格納用
    lv_creation_date  VARCHAR2(100);                                                                -- 作成日格納用
    lv_fname_op       VARCHAR2(100);                                                                -- ファイル名出力用
--
    lt_data_item_tab  gt_check_data_ttype;                                                          -- テーブル型変数を宣言
    lt_if_data_tab    xxccp_common_pkg2.g_file_data_tbl;                                            -- テーブル型変数を宣言
--
    get_if_data_expt  EXCEPTION;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-2 対象データロックの取得
    --==============================================================
--
    BEGIN
      SELECT   fui.file_name         file_name                                                      -- ファイル名
              ,fui.created_by        created_by                                                     -- 作成者
              ,fui.creation_date     creation_date                                                  -- 作成日
      INTO     lv_file_name   
              ,lv_created_by
              ,lv_creation_date
      FROM     xxccp_mrp_file_ul_interface  fui                                                     -- ファイルアップロードIFテーブル
      WHERE    fui.file_id = gn_file_id                                                             -- ファイルID
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN                                                                              -- ロックに失敗した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm                           -- XXCSM
                                             ,iv_name         => cv_csm_msg_022                     -- ファイルアップロードIFロック取得エラーメッセージ
                                             );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
    END;
--
    lv_fname_op := xxccp_common_pkg.get_msg(                                                        -- ファイル名の出力
                      iv_application  => cv_xxcsm                                                   -- XXCSM
                     ,iv_name         => cv_file_name                                               -- インターフェースファイル名
                     ,iv_token_name1  => cv_tkn_file_name                                           -- FILENAME
                     ,iv_token_value1 => lv_file_name                                               -- ファイル名
                     );
--
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- 出力に表示
                     ,buff   => lv_fname_op || CHR(10)
                     );
--
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ログに表示
                     ,buff   => lv_fname_op || CHR(10)
                     );
--
    xxccp_common_pkg2.blob_to_varchar2(                                                             -- BLOBデータ変換共通関数
                                   in_file_id    => gn_file_id                                      -- INパラメータ(ファイルID)
                                   ,ov_file_data => lt_if_data_tab                                  -- テーブル型変数
                                   ,ov_errbuf    => lv_errbuf                                       -- エラー・メッセージ
                                   ,ov_retcode   => lv_retcode                                      -- リターン・コード
                                   ,ov_errmsg    => lv_errmsg                                       -- ユーザー・エラー・メッセージ
                                   );
--
    gn_target_cnt := lt_if_data_tab.COUNT;                                                          -- 処理対象件数を格納
    ln_cnt_a      := 0;                                                                             -- カウンタを初期化
--
    <<ins_wk_loop>>                                                                                 -- ワークテーブル登録LOOP
    LOOP
      EXIT WHEN ln_cnt_a >= gn_target_cnt;
      ln_cnt_a := ln_cnt_a + 1;                                                                     -- 処理カウンタをインクリメント
      --項目数のチェック
      ln_item_cnt := (LENGTHB(lt_if_data_tab(ln_cnt_a)) -
                     (LENGTHB(REPLACE(lt_if_data_tab(ln_cnt_a),cv_msg_comma,''))) + 1);             -- データ項目数を格納
      --
      IF (gn_item_num <> ln_item_cnt) THEN                                                          -- 項目数が一致しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm                            -- アプリケーション短縮名
                                            ,iv_name         => cv_csm_msg_149                      -- メッセージコード
                                            );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
      END IF;
      --
      ln_cnt_b := 0;                                                                                -- カウンタを初期化
--
      <<get_column_loop>>                                                                           -- 項目値取得LOOP
      LOOP
        EXIT WHEN ln_cnt_b >= gn_item_num;                                                          -- 項目数分LOOP
        ln_cnt_b := ln_cnt_b + 1;                                                                   -- カウンタをインクリメント
        lt_data_item_tab(ln_cnt_b) := xxccp_common_pkg.char_delim_partition(                        -- デリミタ文字変換共通関数
                                                       iv_char     =>  lt_if_data_tab(ln_cnt_a)
                                                      ,iv_delim    =>  cv_msg_comma
                                                      ,in_part_num =>  (ln_cnt_b)
                                                       );                                           -- 変数に項目の値を格納
--
      END LOOP get_column_loop;
      INSERT INTO  
        xxcsm_wk_vending_pnt(                                                                       -- 什器ポイントワークテーブル
          year_month                                                                                -- 獲得年月
         ,customer_cd                                                                               -- 顧客コード
         ,location_cd                                                                               -- 拠点コード
         ,employee_cd                                                                               -- 従業員コード
         ,get_intro_kbn                                                                             -- 獲得・紹介区分
         ,point                                                                                     -- ポイント
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
         ,data_kbn                                                                                  -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
          )
        VALUES(
          lt_data_item_tab(1)                                                                       -- 獲得年月
         ,lt_data_item_tab(2)                                                                       -- 顧客コード
         ,lt_data_item_tab(3)                                                                       -- 拠点コード
         ,lt_data_item_tab(4)                                                                       -- 従業員コード
         ,lt_data_item_tab(5)                                                                       -- 獲得・紹介区分
         ,lt_data_item_tab(6)                                                                       -- ポイント
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
         ,lt_data_item_tab(7)                                                                       -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
        );
    END LOOP ins_wk_loop;
--
  EXCEPTION
    WHEN get_if_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END  get_if_data;
--
  /**********************************************************************************
   * Procedure Name   :  check_year_month
   * Description      :  年月チェック(A-4)
   ***********************************************************************************/
--
  PROCEDURE check_year_month(
    iv_year_month   IN  VARCHAR2                                                                    -- 年月
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
   ,iv_data_kbn     IN  VARCHAR2                                                                    -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
   ,ov_errbuf       OUT NOCOPY VARCHAR2                                                             -- エラー・メッセージ
   ,ov_retcode      OUT NOCOPY VARCHAR2                                                             -- リターン・コード
   ,ov_errmsg       OUT NOCOPY VARCHAR2)                                                            -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'check_year_month';                                   -- プログラム名
    cv_open         CONSTANT VARCHAR2(1)   := 'O';                                                  -- ステータス(O = オープン)
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf       VARCHAR2(4000);                                                                 -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);                                                                    -- リターン・コード
    lv_errmsg       VARCHAR2(4000);                                                                 -- ユーザー・エラー・メッセージ
--
    lv_year_month   VARCHAR2(1000);                                                                 -- 年月格納用
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
    lv_data_kbn_no  VARCHAR2(1);                                                                    -- データ区分格納用
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
    ln_cnt          NUMBER;                                                                         -- 件数確認用
    ld_year_month   DATE;                                                                           -- フォーマットチェック用
--//+ADD START 2009/04/14 T1_0500 M.Ohtsuki
    lv_year         VARCHAR2(10);                                                                   -- 年度格納用
    lv_month        VARCHAR2(10);                                                                   -- 月格納用
--//+ADD END   2009/04/14 T1_0500 M.Ohtsuki
--
    check_err_expt  EXCEPTION;                                                                      -- チェックエラー例外
--
  BEGIN
--
    ov_retcode      := cv_status_normal;                                                            -- 変数の初期化
    lv_year_month   := iv_year_month;                                                               -- INパラメータの格納
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
    lv_data_kbn_no  := iv_data_kbn;                                                                 -- データ区分を格納
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
--
    --年月が空白の場合はエラー
    IF (lv_year_month IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm_msg_141                                              -- メッセージコード
                    );
      lv_errbuf := lv_errmsg;
      RAISE check_err_expt;
    END IF;
--
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
    --データ区分が2,3以外はエラー
    IF (lv_data_kbn_no <> '2' AND
        lv_data_kbn_no <> '3') THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm_msg_158                                              -- メッセージコード
                    );
      lv_errbuf := lv_errmsg;
      RAISE check_err_expt;
    END IF;
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
    --年月が'YYYYMM'形式で年月として存在する事。それ以外はエラー
    BEGIN
      SELECT TO_DATE(lv_year_month,'YYYYMM')
      INTO   ld_year_month
      FROM   DUAL;
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm_msg_139                                              -- メッセージコード
                    ,iv_token_name1  => cv_tkn_yyyymm                                               -- トークンコード1
                    ,iv_token_value1 => lv_year_month                                               -- トークン値1
                    );
      lv_errbuf := lv_errmsg;
      RAISE check_err_expt;
    END;
--
    --年月が登録・修正可能な会計期間である事。それ以外はエラー
--//+ADD START 2009/04/14 T1_0500 M.Ohtsuki
    xxcsm_common_pkg.get_year_month(iv_process_years => lv_year_month                               -- 年月
                                   ,ov_year          => lv_year                                     -- 年度
                                   ,ov_month         => lv_month                                    -- 月
                                   ,ov_retcode       => lv_retcode                                  -- リターン・コード
                                   ,ov_errbuf        => lv_errbuf                                   -- エラー・メッセージ
                                   ,ov_errmsg        => lv_errmsg                                   -- ユーザー・エラー・メッセージ
                                   );
    IF (lv_retcode <> cv_status_normal ) THEN                                                        -- 処理結果が(異常 = 1)の場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application     => cv_xxcsm                                    -- アプリケーション短縮名
                                 ,iv_name            => cv_csm_msg_021                              -- メッセージコード
                                 ,iv_token_name1     => cv_tkn_yyyymm                               -- トークンコード1
                                 ,iv_token_value1    => lv_year_month                               -- トークン値1
                                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--//+ADD END   2009/04/14 T1_0500 M.Ohtsuki
--
--//+UPD START 2009/04/14 T1_0500 M.Ohtsuki
--    BEGIN
--      SELECT  gps.period_year                                                                       -- 対象年度
--      INTO    gv_subject_year
--      FROM     gl_period_statuses   gps                                                             -- 会計期間ステータステーブル
--      WHERE    gps.set_of_books_id = gn_set_of_bks_id                                               -- 会計帳簿ID
--        AND    gps.application_id  = gv_appl_ar                                                     -- アプリケーションID
--        AND    gps.closing_status  = cv_open                                                        -- ステータス = オープン
--        AND    gps.period_name     = TO_CHAR(ld_year_month,'YYYY-MM');                                               -- 年月
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    BEGIN
      SELECT   DISTINCT gps.period_year                                                             -- 対象年度
      INTO     gv_subject_year
      FROM     gl_period_statuses   gps                                                             -- 会計期間ステータステーブル
      WHERE    gps.set_of_books_id = gn_set_of_bks_id                                               -- 会計帳簿ID
        AND    gps.application_id  = gv_appl_ar                                                     -- アプリケーションID
        AND    gps.closing_status  = cv_open                                                        -- ステータス = オープン
        AND    gps.period_year     = lv_year;                                                       -- 年度
--//+UPD END 2009/04/14 T1_0500 M.Ohtsuki
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_csm_msg_142                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_yyyymm                                             -- トークンコード1
                      ,iv_token_value1 => lv_year_month                                             -- トークン値1
                      );
        lv_errbuf := lv_errmsg;
        RAISE check_err_expt;
    END;
  EXCEPTION
--
    -- *** 共通関数例外ハンドラ ***
    WHEN check_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_year_month;
--
  /**********************************************************************************
   * Procedure Name   :  delete_old_data
   * Description      :  データ削除(A-5)
   ***********************************************************************************/
--
  PROCEDURE delete_old_data(
    iv_year_month   IN  VARCHAR2                                                                    -- 年月
   ,ov_errbuf       OUT NOCOPY VARCHAR2                                                             -- エラー・メッセージ
   ,ov_retcode      OUT NOCOPY VARCHAR2                                                             -- リターン・コード
   ,ov_errmsg       OUT NOCOPY VARCHAR2)                                                            -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'delete_old_data';                                    -- プログラム名
--//+UPD START 2010/01/14 E_本稼動_01039 T.Nakano
--    cn_jyuki        CONSTANT NUMBER(1)   := 2;                                                      -- データ区分(什器ポイント = 2)
    cn_jyuki_2      CONSTANT NUMBER(1)     := 2;                                                      -- データ区分(什器ポイント = 2)
    cn_jyuki_3      CONSTANT NUMBER(1)     := 3;                                                      -- データ区分(什器ポイント = 3)
--//+UPD END 2010/01/14 E_本稼動_01039 T.Nakano
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf       VARCHAR2(4000);                                                                 -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);                                                                    -- リターン・コード
    lv_errmsg       VARCHAR2(4000);                                                                 -- ユーザー・エラー・メッセージ
--
    ln_month_no     NUMBER;                                                                         -- 月格納用
    ln_cnt          NUMBER;                                                                         -- 件数確認用
    ld_year_month   DATE;                                                                           -- フォーマットチェック用
--
    CURSOR data_lock_cur(in_month_no IN NUMBER)                                                     -- ロック取得用カーソル
    IS
      SELECT  ncp.year_month
      FROM    xxcsm_new_cust_point_hst  ncp                                                         -- 新規獲得ポイント顧客別履歴テーブル
      WHERE   ncp.subject_year = TO_NUMBER(gv_subject_year)                                         -- 対象年度
        AND   ncp.month_no     = in_month_no                                                        -- 月
--//+UPD START 2010/01/14 E_本稼動_01039 T.Nakano
--        AND   ncp.data_kbn     = cn_jyuki                                                           -- データ区分
        AND   ncp.data_kbn in (cn_jyuki_2,cn_jyuki_3)                                               -- データ区分
--//+UPD END 2010/01/14 E_本稼動_01039 T.Nakano
      FOR UPDATE NOWAIT;
--
    lock_err_expt   EXCEPTION;                                                                      -- ロックエラー例外
--
  BEGIN
--
    ln_month_no := TO_NUMBER(SUBSTR(iv_year_month,5));                                              -- 月を格納
      --==============================================================
      --  A-5   新規獲得ポイント顧客別履歴テーブル既存データのロック
      --==============================================================
--
    BEGIN
      OPEN  data_lock_cur(ln_month_no);
      CLOSE data_lock_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF (data_lock_cur%ISOPEN) THEN
          CLOSE data_lock_cur;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_csm_msg_140                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_yyyymm                                             -- トークンコード1
                      ,iv_token_value1 => iv_year_month                                             -- トークン値1
                      );
        lv_errbuf := lv_errmsg;
        RAISE lock_err_expt;
    END;
--
      --==============================================================
      --  A-5   新規獲得ポイント顧客別履歴テーブル
      --==============================================================
--
    DELETE  FROM  xxcsm_new_cust_point_hst    ncp                                                   -- 新規獲得ポイント顧客別履歴テーブル
    WHERE   ncp.subject_year = TO_NUMBER(gv_subject_year)                                           -- 対象年度
      AND   ncp.month_no     = ln_month_no                                                          -- 月
--//+UPD START 2010/01/14 E_本稼動_01039 T.Nakano
--      AND   ncp.data_kbn     = cn_jyuki;                                                            -- データ区分
      AND   ncp.data_kbn     in (cn_jyuki_2,cn_jyuki_3);                                            -- データ区分
--//+UPD END 2010/01/14 E_本稼動_01039 T.Nakano
--
  EXCEPTION
--
    -- *** 共通関数例外ハンドラ ***
    WHEN lock_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_old_data;
--
  /**********************************************************************************
   * Procedure Name   : check_item
   * Description      : 項目妥当性チェック(A-7)
   ***********************************************************************************/
--
  PROCEDURE check_item(
    ir_data_rec   IN  xxcsm_wk_vending_pnt%ROWTYPE                                                  -- 対象レコード
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item';                                           -- プログラム名
    cv_location   CONSTANT VARCHAR2(100) := '1';                                                    -- 顧客区分(1 = 拠点コード) 
    cv_cust_show  CONSTANT VARCHAR2(100) := 'XXCSM1_SHOWCASE_CUST_STATUS';                          -- 顧客状態
    cv_flg_y      CONSTANT VARCHAR2(100) := 'Y';                                                    -- 有効フラグ
    cv_canncel    CONSTANT VARCHAR2(100) := '90';                                                   -- 中止決済
    cv_minus      CONSTANT VARCHAR2(100) := '-';                                                    -- マイナス
    cn_zero       CONSTANT NUMBER := 0;
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
--
    lv_location   VARCHAR2(100);
    lv_point      VARCHAR2(100);
    ln_check_cnt  NUMBER;
    ln_loc_cnt    NUMBER;
    ln_emp_cnt    NUMBER;
--
    lt_check_data_tab gt_check_data_ttype;                                                          -- テーブル型変数の宣言
    chk_warning_expt  EXCEPTION;
--
  BEGIN
--
    ov_retcode    := cv_status_normal;                                                              -- 変数の初期化
    lv_location   := NULL;                                                                          -- 変数の初期化
    ln_check_cnt  := 0;                                                                             -- 変数の初期化
    ln_loc_cnt    := 0;                                                                             -- 変数の初期化
    gv_low_type   := NULL;                                                                          -- 変数の初期化
--
    IF (SUBSTR(ir_data_rec.point,1,1)  = cv_minus) THEN                                             -- ポイントがマイナスの場合
      lv_point   := SUBSTR(ir_data_rec.point,2);                                                    -- ポイントの絶対値部分を変数に格納
    ELSE
      lv_point   := ir_data_rec.point;                                                              -- ポイントを変数に格納
    END IF;
--
    lt_check_data_tab(1)  := ir_data_rec.year_month;                                                -- 獲得年月
    lt_check_data_tab(2)  := ir_data_rec.customer_cd;                                               -- 顧客コード
    lt_check_data_tab(3)  := ir_data_rec.location_cd;                                               -- 拠点コード
    lt_check_data_tab(4)  := ir_data_rec.employee_cd;                                               -- 従業員コード
    lt_check_data_tab(5)  := ir_data_rec.get_intro_kbn;                                             -- 獲得・紹介区分
    lt_check_data_tab(6)  := lv_point;                                                              -- ポイント
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
    lt_check_data_tab(7)  := ir_data_rec.data_kbn;                                                  -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakno
--
    ln_check_cnt := 0;                                                                              -- カウンタの初期化
--
    --==============================================================
    --A-7 ①項目妥当性チェック
    --==============================================================
--
    <<chk_column_loop>>                                                                             -- 項目妥当性チェックLOOP
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      ln_check_cnt := ln_check_cnt + 1;                                                             -- カウンタを加算
      xxccp_common_pkg2.upload_item_check(
                        iv_item_name    => gt_def_info_tab(ln_check_cnt).meaning                    -- 項目名称
                       ,iv_item_value   => lt_check_data_tab(ln_check_cnt)                          -- 項目の値
                       ,in_item_len     => gt_def_info_tab(ln_check_cnt).figures                    -- 項目の長さ(整数部分)
                       ,in_item_decimal => cn_zero                                                  -- 項目の長さ(小数点以下)
                       ,iv_item_nullflg => gt_def_info_tab(ln_check_cnt).essential                  -- 必須フラグ
                       ,iv_item_attr    => gt_def_info_tab(ln_check_cnt).attribute                  -- 項目の属性
                       ,ov_errbuf       => lv_errbuf
                       ,ov_retcode      => lv_retcode
                       ,ov_errmsg       => lv_errmsg 
                       );
      IF (lv_retcode <> cv_status_normal) THEN                                                      -- 戻り値が異常の場合
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm                                                 -- アプリケーション短縮名
                       ,iv_name         => cv_csm_msg_151                                           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_yyyymm                                            -- トークンコード1
                       ,iv_token_name2  => cv_tkn_emp_cd                                            -- トークンコード2
                       ,iv_token_name3  => cv_tkn_loc_cd                                            -- トークンコード3
                       ,iv_token_name4  => cv_tkn_cust_cd                                           -- トークンコード4
--//+UPD START 2010/01/18 E_本稼動_01039 T.Nakano
--                       ,iv_token_name5  => cv_tkn_sqlerrm                                           -- トークンコード5
                       ,iv_token_name5  => cv_data_kbn                                              -- トークンコード5
                       ,iv_token_name6  => cv_tkn_sqlerrm                                           -- トークンコード6
--//+UPD END 2010/01/18 E_本稼動_01039 T.Nakano
                       ,iv_token_value1 => ir_data_rec.year_month                                   -- 獲得年月
                       ,iv_token_value2 => ir_data_rec.employee_cd                                  -- 従業員コード
                       ,iv_token_value3 => ir_data_rec.location_cd                                  -- 拠点コード
                       ,iv_token_value4 => ir_data_rec.customer_cd                                  -- 顧客コード
--//+UPD START 2010/01/18 E_本稼動_01039 T.Nakano
--                       ,iv_token_value5 => lv_errmsg                                                -- 共通関数からのメッセージ
                       ,iv_token_value5 => ir_data_rec.data_kbn                                     -- データ区分
                       ,iv_token_value6 => lv_errmsg                                                -- 共通関数からのメッセージ
--//+UPD END 2010/01/18 E_本稼動_01039 T.Nakano
                       );
         fnd_file.put_line(
                           which  => FND_FILE.OUTPUT                                                -- 出力に表示
                          ,buff   => lv_errmsg                                                      -- ユーザー・エラーメッセージ
                          );
        gv_check_flag := cv_chk_warning;                                                            -- チェックフラグ→ON
        RAISE chk_warning_expt;
      END IF;
    END LOOP chk_column_loop;
--
    --==============================================================
    --A-7 ②従業員コードチェック
    --==============================================================
--
    SELECT   COUNT(1)
    INTO     ln_emp_cnt
    FROM     per_people_f            ppf                                                            -- 従業員マスタ
            ,per_periods_of_service  pps                                                            -- 従業員サービスマスタ
    WHERE    ppf.person_id = pps.person_id                                                          -- 従業員ID
      AND    pps.date_start <= gd_process_date                                                      -- 入社年月日
      AND    NVL(pps.actual_termination_date,gd_process_date) >= gd_process_date                    -- 退職年月日
      AND    ppf.employee_number = ir_data_rec.employee_cd;                                         -- 従業員コード
--
    IF (ln_emp_cnt = 0) THEN                                                                        -- データ0件の場合
       lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm_msg_145                                             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_yyyymm                                              -- トークンコード1
                     ,iv_token_name2  => cv_tkn_emp_cd                                              -- トークンコード2
                     ,iv_token_name3  => cv_tkn_loc_cd                                              -- トークンコード3
                     ,iv_token_name4  => cv_tkn_cust_cd                                             -- トークンコード4
                     ,iv_token_value1 => ir_data_rec.year_month                                     -- トークン値1
                     ,iv_token_value2 => ir_data_rec.employee_cd                                    -- トークン値2
                     ,iv_token_value3 => ir_data_rec.location_cd                                    -- トークン値3
                     ,iv_token_value4 => ir_data_rec.customer_cd                                    -- トークン値4
                     );
       fnd_file.put_line(
                         which  => FND_FILE.OUTPUT                                                  -- 出力に表示
                        ,buff   => lv_errmsg                                                        -- ユーザー・エラーメッセージ
                        );
      gv_check_flag := cv_chk_warning;                                                              -- チェックフラグ→ON
      RAISE chk_warning_expt;
    END IF;
--
    --==============================================================
    --A-7 ③拠点コードチェック
    --==============================================================
--
    -- 拠点コード存在チェック
    SELECT   COUNT(1)                                                                               -- 件数
    INTO     ln_loc_cnt
    FROM     hz_cust_accounts     hca                                                               -- 顧客マスタ
    WHERE    hca.customer_class_code = cv_location                                                  -- 顧客区分
      AND    hca.account_number      = ir_data_rec.location_cd                                      -- 顧客コード
      AND    ROWNUM = 1;
--
    IF (ln_loc_cnt = 0) THEN                                                                        -- データ0件の場合
       lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm_msg_143                                             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_yyyymm                                              -- トークンコード1
                     ,iv_token_name2  => cv_tkn_emp_cd                                              -- トークンコード2
                     ,iv_token_name3  => cv_tkn_loc_cd                                              -- トークンコード3
                     ,iv_token_name4  => cv_tkn_cust_cd                                             -- トークンコード4
                     ,iv_token_value1 => ir_data_rec.year_month                                     -- トークン値1
                     ,iv_token_value2 => ir_data_rec.employee_cd                                    -- トークン値2
                     ,iv_token_value3 => ir_data_rec.location_cd                                    -- トークン値3
                     ,iv_token_value4 => ir_data_rec.customer_cd                                    -- トークン値4
                     );
       fnd_file.put_line(
                         which  => FND_FILE.OUTPUT                                                  -- 出力に表示
                        ,buff   => lv_errmsg                                                        -- ユーザー・エラーメッセージ
                        );
      gv_check_flag := cv_chk_warning;                                                              -- チェックフラグ→ON
      RAISE chk_warning_expt;
    ELSE
      -- 廃止拠点チェック
      BEGIN
        SELECT  hca.account_number                                                                  -- 拠点コード
        INTO    lv_location
        FROM    hz_cust_accounts     hca                                                            -- 顧客マスタ
               ,hz_parties           hpa                                                            -- パーティマスタ
        WHERE   hca.customer_class_code = cv_location                                               -- 顧客区分
          AND   hca.account_number      = ir_data_rec.location_cd                                   -- 顧客コード
          AND   hca.party_id            = hpa.party_id                                              -- パーティID
          AND   hpa.duns_number_c       = cv_canncel                                                -- 顧客ステータス
          AND   ROWNUM = 1;                                                                         -- 1件目
--
        IF (lv_location IS NOT NULL) THEN                                                           -- 廃止拠点の場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm                                                -- アプリケーション短縮名
                        ,iv_name         => cv_csm_msg_148                                          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_yyyymm                                           -- トークンコード1
                        ,iv_token_name2  => cv_tkn_emp_cd                                           -- トークンコード2
                        ,iv_token_name3  => cv_tkn_loc_cd                                           -- トークンコード3
                        ,iv_token_name4  => cv_tkn_cust_cd                                          -- トークンコード4
                        ,iv_token_value1 => ir_data_rec.year_month                                  -- トークン値1
                        ,iv_token_value2 => ir_data_rec.employee_cd                                 -- トークン値2
                        ,iv_token_value3 => ir_data_rec.location_cd                                 -- トークン値3
                        ,iv_token_value4 => ir_data_rec.customer_cd                                 -- トークン値4
                        );
           fnd_file.put_line(
                             which  => FND_FILE.OUTPUT                                              -- 出力に表示
                            ,buff   => lv_errmsg                                                    -- ユーザー・エラーメッセージ
                            );
           gn_canncel_flg := 1;                                                                     -- 廃止拠点フラグ→ON
--//+ADD START 2009/08/19 0001111 T.Tsukino
          lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
          fnd_file.put_line(
                         which  => FND_FILE.LOG                                                       -- ログに表示
                        ,buff   => lv_errbuf                                                          -- ユーザー・エラーメッセージ
                         );
--//+ADD END 2009/08/19 0001111 T.Tsukino
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN                                                                     -- 廃止拠点では無い場合
          NULL;
      END;
    END IF;
--
    --==============================================================
    --A-7 ④顧客コードチェック
    --==============================================================
--
    BEGIN
      SELECT   xca.business_low_type   business_low_type                                            -- 業態(小分類)
      INTO     gv_low_type
      FROM     hz_cust_accounts     hca                                                             -- 顧客マスタ
              ,xxcmm_cust_accounts  xca                                                             -- 追加顧客情報テーブル
              ,hz_parties           hpa                                                             -- パーティマスタ
      WHERE    hca.account_number       =  ir_data_rec.customer_cd                                  -- 顧客コード
        AND    hca.cust_account_id      =  xca.customer_id                                          -- 顧客ID
        AND    xca.start_tran_date     <=  gd_process_date                                          -- 初回取引日
        AND    (xca.stop_approval_date >=  ADD_MONTHS(TO_DATE(ir_data_rec.year_month,'RRRRMM'),1)   -- 中止決済日
               OR xca.stop_approval_date IS NULL)
        AND    hca.party_id             = hpa.party_id                                              -- パーティID
        AND    NOT EXISTS
                 (SELECT  flv.lookup_code     lookup_code                                           -- ルックアップコード
                  FROM    fnd_lookup_values   flv                                                   -- クイックコード値
                  WHERE   flv.lookup_type  = cv_cust_show                                           -- 顧客状態
                    AND   flv.enabled_flag = cv_flg_y                                               -- 有効フラグ
                    AND   flv.language     = USERENV('LANG')                                        -- 言語
                    AND   NVL(flv.start_date_active,gd_process_date)  <= gd_process_date            -- 開始日
                    AND   NVL(flv.end_date_active,gd_process_date)    >= gd_process_date            -- 終了日
                    AND   hpa.duns_number_c = flv.lookup_code
                  )
        AND     ROWNUM = 1;
--
    EXCEPTION                                                                                       -- 業態(小分類)が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_csm_msg_144                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_yyyymm                                             -- トークンコード1
                      ,iv_token_name2  => cv_tkn_emp_cd                                             -- トークンコード2
                      ,iv_token_name3  => cv_tkn_loc_cd                                             -- トークンコード3
                      ,iv_token_name4  => cv_tkn_cust_cd                                            -- トークンコード4
                      ,iv_token_value1 => ir_data_rec.year_month                                    -- トークン値1
                      ,iv_token_value2 => ir_data_rec.employee_cd                                   -- トークン値2
                      ,iv_token_value3 => ir_data_rec.location_cd                                   -- トークン値3
                      ,iv_token_value4 => ir_data_rec.customer_cd                                   -- トークン値4
                      );
        fnd_file.put_line(
                          which  => FND_FILE.OUTPUT                                                 -- 出力に表示
                         ,buff   => lv_errmsg                                                       -- ユーザー・エラーメッセージ
                         );
        gv_check_flag := cv_chk_warning;                                                            -- チェックフラグ→ON
        RAISE chk_warning_expt;
    END;
--
    --==============================================================
    --A-7 ⑥獲得・紹介区分チェック
    --==============================================================
--
    IF (ir_data_rec.get_intro_kbn <> '0'
        AND ir_data_rec.get_intro_kbn <> '1') THEN                                                  -- 獲得・紹介区分が'0'、'1'以外
       lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm_msg_147                                             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_yyyymm                                              -- トークンコード1
                     ,iv_token_name2  => cv_tkn_emp_cd                                              -- トークンコード2
                     ,iv_token_name3  => cv_tkn_loc_cd                                              -- トークンコード3
                     ,iv_token_name4  => cv_tkn_cust_cd                                             -- トークンコード4
                     ,iv_token_value1 => ir_data_rec.year_month                                     -- トークン値1
                     ,iv_token_value2 => ir_data_rec.employee_cd                                    -- トークン値2
                     ,iv_token_value3 => ir_data_rec.location_cd                                    -- トークン値3
                     ,iv_token_value4 => ir_data_rec.customer_cd                                    -- トークン値4
                     );
       fnd_file.put_line(
                         which  => FND_FILE.OUTPUT                                                  -- 出力に表示
                        ,buff   => lv_errmsg                                                        -- ユーザー・エラーメッセージ
                        );
      gv_check_flag := cv_chk_warning;                                                              -- チェックフラグ→ON
      RAISE chk_warning_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN chk_warning_expt THEN
--//+ADD START 2009/08/19 0001111 T.Tsukino
      lv_errbuf := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      fnd_file.put_line(
                     which  => FND_FILE.LOG                                                       -- ログに表示
                    ,buff   => ov_errbuf                                                          -- ユーザー・エラーメッセージ
                     );
--//+ADD END 2009/08/19 0001111 T.Tsukino      
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_item;
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : データ登録 (A-8)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_data_rec   IN  xxcsm_wk_vending_pnt%ROWTYPE                                                  -- 対象レコード
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data';                                          -- プログラム名
    cv_achieve    CONSTANT VARCHAR2(100) := '0';                                                    -- 新規評価対象区分(達成 = 0)
    cv_first_day  CONSTANT VARCHAR2(100) := '01';                                                   -- 一日
    cn_jyuki      CONSTANT NUMBER := 2;                                                             -- データ区分(什器ポイント = 2)
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
/***************************************************************************************************
  ↓↓当プログラムは項目の妥当性チェックを行うため、インサート時は暗黙変換が行われる。
****************************************************************************************************/
    INSERT INTO
      xxcsm_new_cust_point_hst(                                                                     -- 新規獲得ポイント顧客別履歴テーブル
        employee_number                                                                             -- 従業員コード
       ,subject_year                                                                                -- 対象年度
       ,month_no                                                                                    -- 月
       ,account_number                                                                              -- 顧客コード
       ,data_kbn                                                                                    -- データ区分
       ,year_month                                                                                  -- 年月
       ,point                                                                                       -- ポイント
       ,post_cd                                                                                     -- 部署コード
       ,duties_cd                                                                                   -- 職務コード
       ,qualificate_cd                                                                              -- 資格コード
       ,location_cd                                                                                 -- 拠点コード
       ,get_intro_kbn                                                                               -- 獲得・紹介区分
       ,get_custom_date                                                                             -- 顧客獲得日
       ,custom_condition_cd                                                                         -- 顧客業態コード
       ,business_low_type                                                                           -- 業態（小分類）
       ,evaluration_kbn                                                                             -- 新規評価対象区分
       ,created_by                                                                                  -- 作成者
       ,creation_date                                                                               -- 作成日
       ,last_updated_by                                                                             -- 最終更新者
       ,last_update_date                                                                            -- 最終更新日
       ,last_update_login                                                                           -- 最終更新ログイン
       ,request_id                                                                                  -- 要求ID
       ,program_application_id                                                                      -- コンカレント・プログラム・アプリケーションID
       ,program_id                                                                                  -- コンカレント・プログラムID
       ,program_update_date                                                                         -- プログラム更新日
       )
      VALUES(
        ir_data_rec.employee_cd                                                                     -- 従業員コード
       ,TO_NUMBER(gv_subject_year)                                                                  -- 対象年度
       ,TO_NUMBER(SUBSTR(ir_data_rec.year_month,5))                                                 -- 月
       ,ir_data_rec.customer_cd                                                                     -- 顧客コード
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
--       ,cn_jyuki                                                                                    -- データ区分
       ,TO_NUMBER(ir_data_rec.data_kbn)                                                             -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
       ,TO_NUMBER(ir_data_rec.year_month)                                                           -- 年月
       ,TO_NUMBER(ir_data_rec.point)                                                                -- ポイント
       ,NULL                                                                                        -- 部署コード
       ,NULL                                                                                        -- 職務コード
       ,NULL                                                                                        -- 資格コード
       ,ir_data_rec.location_cd                                                                     -- 拠点コード
       ,NVL(ir_data_rec.get_intro_kbn,'0')                                                          -- 獲得・紹介区分
       ,TO_DATE(ir_data_rec.year_month || cv_first_day,'YYYYMMDD')                                  -- 顧客獲得日
       ,NULL                                                                                        -- 顧客業態コード
       ,gv_low_type                                                                                 -- 業態（小分類）
       ,cv_achieve                                                                                  -- 新規評価対象区分
       ,cn_created_by                                                                               -- 作成者
       ,cd_creation_date                                                                            -- 作成日
       ,cn_last_updated_by                                                                          -- 最終更新者
       ,cd_last_update_date                                                                         -- 最終更新日
       ,cn_last_update_login                                                                        -- 最終更新ログイン
       ,cn_request_id                                                                               -- 要求ID
       ,cn_program_application_id                                                                   -- コンカレント・プログラム・アプリケーションID
       ,cn_program_id                                                                               -- コンカレント・プログラムID
       ,cd_program_update_date                                                                      -- プログラム更新日
       );
/***************************************************************************************************
****************************************************************************************************/
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 年間計画データ取得、セーブポイントの設定 (A-3,A-6)
   ***********************************************************************************/
--
  PROCEDURE loop_main(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
--
    cv_prg_name          CONSTANT VARCHAR2(100) := 'loop_main';                                     -- プログラム名
    cv_null              CONSTANT VARCHAR2(100) := 'Null';                                          -- NULL
    sub_proc_other_expt  EXCEPTION;
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
    lv_year_month        VARCHAR2(100);                                                             -- 判断用_獲得年月
    lv_location_cd       VARCHAR2(100);                                                             -- 判断用_拠点コード
    lv_employee_cd       VARCHAR2(100);                                                             -- 判断用_従業員コード
    lv_customer_cd       VARCHAR2(100);                                                             -- 判断用_顧客コード
    ln_nodata_cnt        VARCHAR2(100);
--
    lr_data_rec          xxcsm_wk_vending_pnt%ROWTYPE;                                              -- テーブル型変数を宣言
--
    CURSOR get_data_cur                                                                             -- 什器ポイントデータ取得カーソル
    IS
      SELECT    wvp.year_month                            year_month                                -- 獲得年月
               ,wvp.customer_cd                           customer_cd                               -- 顧客コード
               ,wvp.location_cd                           location_cd                               -- 拠点コード
               ,wvp.employee_cd                           employee_cd                               -- 従業員コード
               ,wvp.get_intro_kbn                         get_intro_kbn                             -- 獲得・紹介区分
               ,wvp.point                                 point                                     -- ポイント
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
               ,wvp.data_kbn                              data_kbn                                  -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
      FROM      xxcsm_wk_vending_pnt                      wvp                                       -- 什器ポイントデータワークテーブル
      ORDER BY  wvp.year_month                            ASC                                       -- 獲得年月
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
               ,wvp.data_kbn                              ASC                                       -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
               ,wvp.location_cd                           ASC                                       -- 拠点コード
               ,wvp.employee_cd                           ASC                                       -- 従業員コード
               ,wvp.customer_cd                           ASC;                                      -- 顧客コード
--
    get_data_rec  get_data_cur%ROWTYPE;                                                             -- 什器ポイントデータ取得 レコード型
  BEGIN
--
    ov_retcode    := cv_status_normal;                                                              -- 変数の初期化
--
    gn_normal_cnt := 0;                                                                             -- 正常件数の初期化
    gn_warn_cnt   := 0;                                                                             -- スキップ件数の初期化
    gn_counter    := 0;                                                                             -- 件数の初期化
    ln_nodata_cnt := 0;                                                                             -- データ0件チェック用カウンターを初期化
    gv_check_flag := cv_chk_normal;                                                                 -- チェックフラグの初期化
--
    OPEN get_data_cur;
    <<main_loop>>                                                                                   -- メイン処理LOOP
    LOOP
      FETCH get_data_cur INTO get_data_rec;
      EXIT WHEN get_data_cur%NOTFOUND;                                                              -- 対象データ件数処理を繰り返す
--
      IF ((get_data_cur%ROWCOUNT = 1)                                                               -- 1件目
        OR (lv_year_month  <> NVL(get_data_rec.year_month,cv_null))) THEN                           -- 獲得年月ブレイク時
--
        IF (get_data_cur%ROWCOUNT <> 1) THEN                                                        -- 1件目以外
          IF (ln_nodata_cnt = 0) THEN                                                               -- 年月単位の登録件数が0件だった場合
--
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm                                              -- アプリケーション短縮名
                          ,iv_name         => cv_csm_msg_152                                        -- データ0件メッセージ
                          ,iv_token_name1  => cv_tkn_yyyymm                                         -- トークンコード1
                          ,iv_token_value1 => lv_year_month                                         -- 獲得年月
                          );
--//+UPD START 2009/08/19 0001111 T.Tsukino
--            lv_errbuf := lv_errmsg;
            lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
--//+UPD END 2009/08/19 0001111 T.Tsukino
--
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT                                             -- 出力に表示
                             ,buff   => lv_errmsg                                                   -- ユーザー・エラーメッセージ
                             );
--
--//+ADD START 2009/08/19 0001111 T.Tsukino
            fnd_file.put_line(
                           which  => FND_FILE.LOG                                                       -- ログに表示
                          ,buff   => lv_errbuf                                                          -- ユーザー・エラーメッセージ
                           );
--//+ADD END 2009/08/19 0001111 T.Tsukino      
          ELSE
            ln_nodata_cnt := 0;                                                                     -- データ0件チェック用カウンターを初期化
          END IF;
        END IF; 
    --==============================================================
    -- A-4 年月チェック
    --==============================================================
--
        check_year_month(                                                                           -- 年月チェックをコール
            iv_year_month => get_data_rec.year_month
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
           ,iv_data_kbn   => get_data_rec.data_kbn
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
           );
--
        IF (lv_retcode <> cv_status_normal) THEN                                                    -- 戻り値が正常以外の場合
            RAISE sub_proc_other_expt;
        END IF;
--
    --==============================================================
    -- A-5 新規獲得ポイント顧客別履歴テーブル既存データの削除
    --==============================================================
--
        delete_old_data(                                                                            -- データ削除をコール
            iv_year_month => get_data_rec.year_month
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
           );
--
        IF (lv_retcode <> cv_status_normal) THEN                                                    -- 戻り値が正常以外の場合
          RAISE sub_proc_other_expt;
        END IF;
      END IF;
--
      IF ((get_data_cur%ROWCOUNT = 1)                                                               -- 1件目
         OR (lv_year_month  <> NVL(get_data_rec.year_month,cv_null))                                -- 獲得年月ブレイク時
         OR (lv_location_cd <> NVL(get_data_rec.location_cd,cv_null))                               -- 拠点コードブレイク時
         OR (lv_employee_cd <> NVL(get_data_rec.employee_cd,cv_null))                               -- 従業員コードブレイク時
         OR (lv_customer_cd <> NVL(get_data_rec.customer_cd,cv_null))) THEN                         -- 顧客コードブレイク時
--
        IF (gv_check_flag = cv_chk_normal)THEN                                                      -- チェックフラグが（正常 = 0)の場合
          gn_normal_cnt := (gn_normal_cnt + gn_counter);                                            -- 正常処理件数を加算
        ELSIF (gv_check_flag = cv_chk_warning) THEN                                                 -- チェックフラグが（エラー = 1)の場合
          gn_error_cnt := (gn_error_cnt + gn_counter);                                              -- スキップ件数を加算
        END IF;
--
        gv_check_flag  := cv_chk_normal;                                                            -- チェックフラグの初期化
        gn_counter := 0;                                                                            -- 処理件数を初期化
--
    --==============================================================
    -- A-6 セーブポイントの設定
    --==============================================================
--
        SAVEPOINT check_warning;                                                                    -- セーブポイントの設定
--
      END IF;
    --==============================================================
    -- A-7 項目妥当性チェック
    --==============================================================
--
      IF (gv_check_flag = cv_chk_normal) THEN                                                       -- チェックフラグが(正常=0)の場合
        lr_data_rec.year_month      := get_data_rec.year_month;                                     -- 獲得年月
        lr_data_rec.location_cd     := get_data_rec.location_cd;                                    -- 拠点コード
        lr_data_rec.customer_cd     := get_data_rec.customer_cd;                                    -- 顧客コード
        lr_data_rec.employee_cd     := get_data_rec.employee_cd;                                    -- 従業員コード
        lr_data_rec.get_intro_kbn   := get_data_rec.get_intro_kbn;                                  -- 獲得・紹介区分
        lr_data_rec.point           := get_data_rec.point;                                          -- ポイント
--//+ADD START 2010/01/14 E_本稼動_01039 T.Nakano
        lr_data_rec.data_kbn        := get_data_rec.data_kbn;                                       -- データ区分
--//+ADD END 2010/01/14 E_本稼動_01039 T.Nakano
--
        check_item(                                                                                 -- check_itemをコール
           ir_data_rec => lr_data_rec
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
          );
--
        IF (lv_retcode = cv_status_error) THEN                                                      -- 戻り値がエラーの場合
          RAISE sub_proc_other_expt;
        END IF;
--
        IF (lv_retcode = cv_status_warn) THEN                                                       -- 戻り値が警告の場合
          gv_warnig_flg := cv_status_warn;
          ln_nodata_cnt := 0;                                                                       -- データ0件カウンターの初期化
          ROLLBACK TO check_warning;                                                                -- セーブポイントへロールバック
        END IF;
--
--
    --==============================================================
    -- A-8 データ登録
    --==============================================================
--

        IF (gv_check_flag = cv_chk_normal) THEN                                                     -- チェックフラグが(正常=0)の場合
          insert_data(                                                                              -- insert_dataをコール
            ir_data_rec => lr_data_rec
           ,ov_errbuf   => lv_errbuf
           ,ov_retcode  => lv_retcode
           ,ov_errmsg   => lv_errmsg
           );
--
          IF (lv_retcode <> cv_status_normal) THEN                                                  -- 戻り値が正常以外の場合
            RAISE sub_proc_other_expt;
          END IF;
          ln_nodata_cnt := (ln_nodata_cnt + 1);                                                     -- データ0件チェック用カウンターを加算
        END IF;
      END IF;
--
      lv_year_month  := get_data_rec.year_month;                                                    -- 獲得年月を変数に保持
      lv_location_cd := get_data_rec.location_cd;                                                   -- 拠点コードを変数に保持
      lv_employee_cd := get_data_rec.employee_cd;                                                   -- 従業員コードを変数に保持
      lv_customer_cd := get_data_rec.customer_cd;                                                   -- 顧客コードを変数に保持
--
      gn_counter     := gn_counter + 1;                                                             -- 処理件数を加算
--
    END LOOP main_loop;
--
    IF (ln_nodata_cnt = 0) THEN                                                                     -- 年月単位の登録件数が0件だった場合
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm_msg_152                                              -- データ0件メッセージ
                    ,iv_token_name1  => cv_tkn_yyyymm                                               -- トークンコード1
                    ,iv_token_value1 => lv_year_month                                               -- 獲得年月
                    );
--//+UPD START 2009/08/19 0001111 T.Tsukino
--      lv_errbuf := lv_errmsg;
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
--//+UPD END 2009/08/19 0001111 T.Tsukino
--
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- 出力に表示
                       ,buff   => lv_errmsg                                                         -- ユーザー・エラーメッセージ
                       );
--//+ADD START 2009/08/19 0001111 T.Tsukino
      fnd_file.put_line(
                     which  => FND_FILE.LOG                                                       -- ログに表示
                    ,buff   => lv_errbuf                                                          -- ユーザー・エラーメッセージ
                     );
--//+ADD END 2009/08/19 0001111 T.Tsukino      
--
    END IF;
--
    IF (gv_check_flag = cv_chk_normal)THEN                                                          -- チェックフラグが（正常 = 0)の場合
      gn_normal_cnt := (gn_normal_cnt + gn_counter);                                                -- 正常処理件数を加算
    ELSIF (gv_check_flag = cv_chk_warning) THEN                                                     -- チェックフラグが（エラー = 1)の場合
      gn_error_cnt := (gn_error_cnt + gn_counter);                                                  -- スキップ件数を加算
    END IF;
--
    CLOSE  get_data_cur;
--
    IF ((gn_error_cnt >= 1)                                                                         -- スキップしたデータが存在する場合
      OR (gn_canncel_flg = 1 )) THEN                                                                -- 廃止拠点が存在した場合
      ov_retcode := cv_status_warn;                                                                 -- 終了ステータスを警告に設定
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_other_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode    := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : final
   * Description      : 終了処理 (A-9)
   ***********************************************************************************/
  PROCEDURE final(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'final';                                                -- プログラム名
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
      --==============================================================
      --  A-9    販売計画ワークテーブルデータ削除
      --==============================================================
--
    DELETE  FROM    xxcsm_wk_vending_pnt;                                                           -- 什器ポイントデータワークテーブル
--
      --==============================================================
      --  A-9    ファイルアップロードIFテーブルデータ削除
      --==============================================================
--
    DELETE  FROM    xxccp_mrp_file_ul_interface  fui                                                -- ファイルアップロードIFテーブル
    WHERE   fui.file_id = gn_file_id;                                                               -- ファイルID
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END final;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                              -- プログラム名
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode     := cv_status_normal;                                                             -- リターンコードを初期化
--
    gn_target_cnt  := 0;                                                                            -- 件数カウンタの初期化
    gn_normal_cnt  := 0;                                                                            -- 件数カウンタの初期化
    gn_error_cnt   := 0;                                                                            -- 件数カウンタの初期化
    gn_warn_cnt    := 0;                                                                            -- 件数カウンタの初期化
    gn_canncel_flg := 0;                                                                            -- 廃止拠点フラグの初期化
--
    init(                                                                                           -- initをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
--
    get_if_data(                                                                                    -- get_if_dataをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
--
    loop_main(                                                                                      -- loop_mainをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
--
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
--
    final(                                                                                          -- finalをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
    ov_retcode := lv_retcode;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,retcode       OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,iv_file_id    IN         VARCHAR2                                                               -- ファイルID
   ,iv_format     IN         VARCHAR2                                                               -- フォーマットパターン
    )
--
  IS
--
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- 件数メッセージ用トークン名
--
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(5000);                                                              -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);                                                               -- 終了メッセージコード
--
  BEGIN
--
    xxccp_common_pkg.put_log_header(                                                                -- ヘッダー情報の出力
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    gn_file_id := TO_NUMBER(iv_file_id);                                                            -- INパラメータを格納
    gv_format  := iv_format;                                                                        -- INパラメータを格納
--
    submain(                                                                                        -- submainをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- 空行の挿入
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
    --
    IF (gv_warnig_flg = cv_status_warn
      AND lv_retcode = cv_status_normal) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- 空行の挿入
    );
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
    fnd_file.put_line(
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
END XXCSM004A06C;
/

