CREATE OR REPLACE PACKAGE BODY XXCSM002A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A08C(body)
 * Description      : 月別商品計画(営業原価)チェックリスト出力
 * MD.050           : 月別商品計画(営業原価)チェックリスト出力 MD050_CSM_002_A08
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                        初期処理(A-1)
 *  do_check                    年間商品計画データ存在チェック(A-3)
 *                              按分処理済データ存在チェック(A-4)
 *  item_plan_select            商品計画データ抽出(A-5)
 *  group3_month_count          商品群別月別集計(A-6)
 *                              月別商品群データ登録(A-7)
 *  group1_month_count          商品区分月別集計(A-8)
 *                              月別商品区分データ登録(A-9)
 *  all_item_month_count        商品合計月別集計(A-10)
 *                              月別商品合計データ登録(A-11)
 *  item_month_count            商品別月別集計(A-12)
 *                              月別商品別データ登録(A-13)
 *  reduce_price_count          値引月別集計(A-14)
 *                              月別値引データ登録(A-15)
 *  kyoten_month_count          拠点別月別集計(A-16)
 *                              月別拠点別データ、H基準登録(A-17)
 *  write_csv_file              チェックリストデータ出力(A-18)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   S.Son            新規作成
 *  2009/02/12    1.1   SCS H.Yoshitake [障害CT_013]  類似機能動作統一対応
 *  2009/02/13    1.2   SCS S.Son       [障害CT_015]  新商品対応
 *  2009/02/16    1.3   SCS S.Son       [障害CT_021]  分母0の不具合対応
 *  2009/02/19    1.4   SCS K.Yamada    [障害CT_037]  エラー件数不具合の対応
 *                                      [障害CT_038]  年間売上0不具合の対応
 *                                      [障害CT_048]  ヘッダ出力不具合の対応
 *  2009/02/27    1.5   SCS T.Tsukino   [障害CT_070]  対象0件時のヘッダ出力不具合対応
 *  2009/05/07    1.6   SCS M.Ohtsuki   [障害T1_0858] 共通関数修正に伴うパラメータの追加
 *  2009/05/21    1.7   SCS M.Ohtsuki   [障害T1_1101] 売上金額不正(値引額含む)
 *  2009/07/13    1.8   SCS M.Ohtsuki   [SCS障害管理番号0000657] ヘッダ出力時不具合
 *  2011/01/05    1.9   SCS OuKou       [E_本稼動_05803]
 *  2011/01/13    1.10  SCS Y.Kanami    [E_本稼動_05803]PT対応
 *  2011/12/14    1.11  SCSK K.Nakamura [E_本稼動_08817]出力判定修正
 *  2012/12/13    1.12  SCSK K.Taniguchi[E_本稼動_09949]新旧原価選択可能対応
 *  2013/01/31    1.13  SCSK K.Taniguchi[E_本稼動_09949]年度開始日取得の不具合対応
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_comma              constant varchar2(1) := ',';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
  --メッセージーコード
  cv_msg_10003              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';       --コンカレント入力パラメータメッセージ(対象年度)
  cv_msg_00048              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';       --コンカレント入力パラメータメッセージ(拠点コード)
  cv_msg_10004              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10004';       --コンカレント入力パラメータメッセージ(階層)
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_msg_10167              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10167';       --コンカレント入力パラメータメッセージ(新旧原価区分)
--//+ADD END E_本稼動_09949 K.Taniguchi
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --想定外エラーメッセージ
  cv_chk_err_00005          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';       --プロファイル取得エラーメッセージ
  cv_chk_err_00087          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';       --商品計画未設定メッセージ
  cv_chk_err_00098          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00098';       --月別商品計画(営業原価)チェックリストヘッダ用メッセージ
  cv_chk_err_00088          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';       --商品計画単品別按分処理未完了メッセージ
  cv_chk_err_10001          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';       --取得データ0件エラーメッセージ
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_chk_err_10168          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10168';       --GLカレンダ年度開始日取得エラーメッセージ
--//+ADD END E_本稼動_09949 K.Taniguchi
  --トークン
  cv_tkn_prof               CONSTANT VARCHAR2(100) := 'PROF_NAME';               --カスタム・プロファイル・オプションの英名
  cv_tkn_kyoten_cd          CONSTANT VARCHAR2(100) := 'KYOTEN_CD';               --拠点コード
  cv_tkn_kyoten_nm          CONSTANT VARCHAR2(100) := 'KYOTEN_NM';               --拠点名
  cv_tkn_year               CONSTANT VARCHAR2(100) := 'TAISYOU_YM';               --対象年度
  cv_tkn_yyyy               CONSTANT VARCHAR2(100) := 'YYYY';                    --入力パラメータ対象年度
  cv_tkn_level              CONSTANT VARCHAR2(100) := 'HIERARCHY_LEVEL';         --入力パラメータの階層
  cv_tkn_nichiji            CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';         --作成日時  
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_tkn_cost_class         CONSTANT VARCHAR2(100) := 'NEW_OLD_COST_CLASS';      --新旧原価区分
  cv_tkn_sobid              CONSTANT VARCHAR2(100) := 'SET_OF_BOOKS_ID';         --会計帳簿ID
  cv_tkn_process_date       CONSTANT VARCHAR2(100) := 'PROCESS_DATE';            --業務日付
--//+ADD END E_本稼動_09949 K.Taniguchi
  --
  cv_language_ja            CONSTANT VARCHAR2(2)   := USERENV('LANG');           --言語(日本語)
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                       --フラグY
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                       --フラグN
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
  cv_whick_log              CONSTANT VARCHAR2(3)   := 'LOG';                       --ログ
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
  gn_seq_no        NUMBER;                    -- 出力順
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
  year_plan_check_expt          EXCEPTION;              --年間商品計画データ存在チェック
  assin_end_check_expt          EXCEPTION;              --商品計画単品別按分処理未完了チェック
  kyoten_skip_expt              EXCEPTION;              --拠点単位でスキップ

  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCSM002A08C';                -- パッケージ名
  cv_item_sum_profile            CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';     --商品合計プロファイル名
  cv_sales_dis_profile           CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';     --売上値引プロファイル名
  cv_receipt_dis_profile         CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';     --入金値引プロファイル名
  cv_h_standard_profile          CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_4';     --H基準プロファイル名
  cv_amount_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';      --数量プロファイル名
  cv_budget_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';      --売上プロファイル名
  cv_margin_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';     --粗利益額プロファイル名
  cv_credit_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';      --掛率プロファイル名
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_gl_set_of_bks_id_profile    CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';            --会計帳簿IDプロファイル名
--//+ADD END E_本稼動_09949 K.Taniguchi
  cv_group_d                     CONSTANT VARCHAR2(1)   := 'D';                           --商品コード1桁D(その他)
  cv_location_1                  CONSTANT VARCHAR2(1)   := '1';                            --入力パラメータ拠点コード’1’
  cv_location_1_nm               CONSTANT VARCHAR2(100)   := '全拠点';                     --入力パラメータ拠点コード’1’
--//+ADD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
  cv_sgun_code                  CONSTANT VARCHAR2(15)  := 'XXCMN_SGUN_CODE';          
  cv_item_group                 CONSTANT VARCHAR2(17)  := 'XXCSM1_ITEM_GROUP';
  cv_mcat                       CONSTANT VARCHAR2(4)   := 'MCAT';
  cn_appl_id                    CONSTANT NUMBER        := 401;
  cv_ja                         CONSTANT VARCHAR2(4)   := 'JA';
  cv_item_status_30             CONSTANT VARCHAR2(4)   := '30';
  cv_item_kbn                   CONSTANT VARCHAR2(4)   := '0';
  cv_percent                    CONSTANT VARCHAR2(1)   := '%';
  cv_whse_code                  CONSTANT VARCHAR2(3)   := '000';
  cv_group_3                    CONSTANT VARCHAR2(1)   := '*';
  cv_group_1                    CONSTANT VARCHAR2(3)   := '***';
  cv_bar                        CONSTANT VARCHAR2(1)   := '_';
--//+ADD END 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_new_cost                   CONSTANT VARCHAR2(10)  := '10'; -- パラメータ：新旧原価区分（新原価）
  cv_old_cost                   CONSTANT VARCHAR2(10)  := '20'; -- パラメータ：新旧原価区分（旧原価）
--//+ADD END E_本稼動_09949 K.Taniguchi
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_item_sum_name       VARCHAR2(50);         --商品合計(プロファイル名)
  gv_sales_dis_name      VARCHAR2(50);         --売上値引(プロファイル名)
  gv_receipt_dis_name    VARCHAR2(50);         --入金値引(プロファイル名)
  gv_h_standard_name     VARCHAR2(50);         --H基準(プロファイル名)
  gv_amount_name         VARCHAR2(50);         --数量(プロファイル名)
  gv_budget_name         VARCHAR2(50);         --売上(プロファイル名)
  gv_margin_name         VARCHAR2(50);         --粗利益額(プロファイル名)
  gv_credit_name         VARCHAR2(50);         --掛率(プロファイル名)
--//+ADD START E_本稼動_09949 K.Taniguchi
  gn_gl_set_of_bks_id    NUMBER;               --会計帳簿ID(プロファイル)
--//+ADD END E_本稼動_09949 K.Taniguchi
  gn_subject_year        NUMBER;               --入力パラメータ．対象年度
  gv_location_cd         VARCHAR2(4);          --入力パラメータ．拠点コード
  gv_hierarchy_level     VARCHAR2(2);          --入力パラメータ．階層
--//+ADD START E_本稼動_09949 K.Taniguchi
  gv_new_old_cost_class  VARCHAR2(10);         --入力パラメータ．新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
--//+ADD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami  
  gd_process_date        DATE := xxccp_common_pkg2.get_process_date;                      -- 業務日付を変数に格納-
--//+ADD END 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami  
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
  gv_group_flag          VARCHAR2(1);          --群出力フラグ
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--//+ADD START E_本稼動_09949 K.Taniguchi
  gd_gl_start_date       DATE;                 --起動時の年度開始日
--//+ADD END E_本稼動_09949 K.Taniguchi
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT NOCOPY VARCHAR2,       -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,       -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);     -- リターン・コード
    lv_errmsg         VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn_value      VARCHAR2(4000);  --トークン値

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
    lv_pram_year          VARCHAR2(100);     -- パラメータメッセージ出力(対象年度)
    lv_pram_location      VARCHAR2(100);     -- パラメータメッセージ出力(拠点コード)
    lv_pram_level         VARCHAR2(100);     -- パラメータメッセージ出力(階層)
--//+ADD START E_本稼動_09949 K.Taniguchi
    lv_new_old_cost_class VARCHAR2(100);     -- パラメータメッセージ出力(新旧原価区分)
--//+ADD END E_本稼動_09949 K.Taniguchi

    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** ローカル変数初期化 ***

    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--①入力パラメータをメッセージ出力
    --対象年度
    lv_pram_year := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_msg_10003
                                            ,iv_token_name1  => cv_tkn_yyyy
                                            ,iv_token_value1 => gn_subject_year
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_year);
    --拠点コード
    lv_pram_location := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_msg_00048
                                            ,iv_token_name1  => cv_tkn_kyoten_cd
                                            ,iv_token_value1 => gv_location_cd
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_location);
    --階層
    lv_pram_level := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_msg_10004
                                           ,iv_token_name1  => cv_tkn_level
                                           ,iv_token_value1 => gv_hierarchy_level
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_level);
--//+ADD START E_本稼動_09949 K.Taniguchi
    --新旧原価区分
    lv_new_old_cost_class := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_msg_10167
                                           ,iv_token_name1  => cv_tkn_cost_class
                                           ,iv_token_value1 => gv_new_old_cost_class
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_new_old_cost_class);
    --空行
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
--//+ADD END E_本稼動_09949 K.Taniguchi
--③ プロファイル値取得
    --チェックリスト項目名(商品合計)
    gv_item_sum_name := FND_PROFILE.VALUE(cv_item_sum_profile);
    IF gv_item_sum_name IS NULL THEN
        lv_tkn_value := cv_item_sum_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --チェックリスト項目名(売上値引)
    gv_sales_dis_name := FND_PROFILE.VALUE(cv_sales_dis_profile);
    IF gv_sales_dis_name IS NULL THEN
        lv_tkn_value := cv_sales_dis_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --チェックリスト項目名(入金値引)
    gv_receipt_dis_name := FND_PROFILE.VALUE(cv_receipt_dis_profile);
    IF gv_receipt_dis_name IS NULL THEN
        lv_tkn_value := cv_receipt_dis_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --チェックリスト項目名(H基準)
    gv_h_standard_name := FND_PROFILE.VALUE(cv_h_standard_profile);
    IF gv_h_standard_name IS NULL THEN
        lv_tkn_value := cv_h_standard_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --商品計画リスト項目名(数量)
    gv_amount_name := FND_PROFILE.VALUE(cv_amount_profile);
    IF gv_amount_name IS NULL THEN
        lv_tkn_value := cv_amount_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --商品計画リスト項目名(売上)
    gv_budget_name := FND_PROFILE.VALUE(cv_budget_profile);
    IF gv_budget_name IS NULL THEN
        lv_tkn_value := cv_budget_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --チェックリスト項目名(粗利益額)
    gv_margin_name := FND_PROFILE.VALUE(cv_margin_profile);
    IF gv_margin_name IS NULL THEN
        lv_tkn_value := cv_margin_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --商品計画リスト項目名(掛率)
    gv_credit_name := FND_PROFILE.VALUE(cv_credit_profile);
    IF gv_credit_name IS NULL THEN
        lv_tkn_value := cv_credit_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--//+ADD START E_本稼動_09949 K.Taniguchi
    --会計帳簿ID
    gn_gl_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_gl_set_of_bks_id_profile));
    IF gn_gl_set_of_bks_id IS NULL THEN
        lv_tkn_value := cv_gl_set_of_bks_id_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--//+ADD END E_本稼動_09949 K.Taniguchi

--//+ADD START E_本稼動_09949 K.Taniguchi
    --起動時の年度開始日取得
    BEGIN
      -- 年度開始日
      SELECT  gp.start_date             AS start_date           -- 年度開始日
      INTO    gd_gl_start_date                                  -- 起動時の年度開始日
      FROM    gl_sets_of_books          gsob                    -- 会計帳簿マスタ
             ,gl_periods                gp                      -- 会計カレンダ
      WHERE   gsob.set_of_books_id      = gn_gl_set_of_bks_id   -- 会計帳簿ID
      AND     gp.period_set_name        = gsob.period_set_name  -- カレンダ名
      AND     gp.period_year            = (
                                            -- 起動時の年度
                                            SELECT  gp2.period_year           AS period_year          -- 年度
                                            FROM    gl_sets_of_books          gsob2                   -- 会計帳簿マスタ
                                                   ,gl_periods                gp2                     -- 会計カレンダ
                                            WHERE   gsob2.set_of_books_id     = gn_gl_set_of_bks_id   -- 会計帳簿ID
                                            AND     gp2.period_set_name       = gsob2.period_set_name -- カレンダ名
--//+ADD START E_本稼動_09949 K.Taniguchi
                                            AND     gp2.adjustment_period_flag = cv_flg_n             -- 調整会計期間外
--//+ADD END E_本稼動_09949 K.Taniguchi
                                            AND     gd_process_date           BETWEEN gp2.start_date  -- 業務日付時点
                                                                              AND     gp2.end_date
                                          )
      AND     gp.adjustment_period_flag = cv_flg_n              -- 調整会計期間外
      AND     gp.period_num             = 1                     -- 年度開始月
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_10168
                                             ,iv_token_name1  => cv_tkn_sobid
                                             ,iv_token_value1 => TO_CHAR(gn_gl_set_of_bks_id)           --会計帳簿ID
                                             ,iv_token_name2  => cv_tkn_process_date
                                             ,iv_token_value2 => TO_CHAR(gd_process_date, 'YYYY/MM/DD') --業務日付
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--//+ADD END E_本稼動_09949 K.Taniguchi
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  /****************************************************************************
  * Procedure Name   : do_check
  * Description      : 年間商品計画データ存在チェック(A-3)
  *                  : 按分処理済データ存在チェック(A-4)            
  ****************************************************************************/
  PROCEDURE do_check (
       iv_kyoten_cd     IN  VARCHAR2                  --A-2で取得した拠点コード
      ,ov_errbuf     OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode    OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg     OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--

--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'do_check'; -- プログラム名
    
--  ===============================
--  固定ローカル変数
--  ===============================
    -- データ存在チェック用
    ln_counts                 NUMBER(1,0) := 0;
--
--  ===============================
--  ローカル・カーソル
--  ===============================

--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

    -- =========================================================================
    -- 年間商品計画データ存在チェック(A-3)
    -- =========================================================================
      -- 再設定
    ln_counts := 0;
    BEGIN
      SELECT   COUNT(xiph.plan_year)
      INTO     ln_counts
      FROM     xxcsm_item_plan_lines          xipl                     -- 商品計画明細テーブル
               ,xxcsm_item_plan_headers       xiph                     -- 商品計画ヘッダテーブル
      WHERE    xiph.plan_year = gn_subject_year
      AND      xiph.location_cd = iv_kyoten_cd
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id
      AND      ROWNUM = 1;      
      -- 件数が0の場合、エラーメッセージを出して、処理が中止します。
      IF (ln_counts = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                          -- アプリケーション短縮名
                      ,iv_name         => cv_chk_err_00087                  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_year                       -- トークンコード1（対象年度）
                      ,iv_token_value1 => gn_subject_year                   -- トークン値1
                      ,iv_token_name2  => cv_tkn_kyoten_cd                  -- トークンコード2（拠点コード）
                      ,iv_token_value2 => iv_kyoten_cd                      -- トークン値2
                     );
          lv_errbuf := lv_errmsg;
          RAISE year_plan_check_expt;
      END IF;
    END;
    
    -- =========================================================================
    -- 按分処理済データ存在チェック(A-4)
    -- =========================================================================
      -- 再設定
    ln_counts := 0;
    BEGIN
      SELECT COUNT(xiph.plan_year)
      INTO   ln_counts
      FROM     xxcsm_item_plan_lines          xipl                     -- 商品計画明細テーブル
               ,xxcsm_item_plan_headers       xiph                     -- 商品計画ヘッダテーブル
      WHERE    xiph.plan_year = gn_subject_year
      AND      xiph.location_cd = iv_kyoten_cd
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id
--//+UPD START 2009/02/13 CT015 S.Son
    --AND      xipl.item_kbn = '1'                                     --商品区分(1：商品単品)
      AND      xipl.item_kbn <> '0'                                    --商品区分(1：商品単品、2：新商品)
--//+UPD END 2009/02/13 CT015 S.Son
      AND      ROWNUM = 1;      
      
      IF (ln_counts = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                          -- アプリケーション短縮名
                      ,iv_name         => cv_chk_err_00088                  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_year                       -- トークンコード1（対象年度）
                      ,iv_token_value1 => gn_subject_year                   -- トークン値1
                      ,iv_token_name2  => cv_tkn_kyoten_cd                  -- トークンコード2（拠点コード）
                      ,iv_token_value2 => iv_kyoten_cd                      -- トークン値2
                     );
          lv_errbuf := lv_errmsg;
          RAISE assin_end_check_expt;
      END IF;
    END;
--
  EXCEPTION
    -- *** 年間商品計画データ存在チェック ***
    WHEN year_plan_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 按分処理済データ存在チェック ***
    WHEN assin_end_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部  #############################

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
--#####################################  固定部 END   ###########################
--
  END do_check;
--
  /****************************************************************************
  * Procedure Name   : group3_month_count
  * Description      : 商品群別月別集計(A-6)
  *                  : 月別商品群データ登録(A-7)
  ****************************************************************************/
  PROCEDURE group3_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2で取得した拠点コード
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2で取得した拠点名称
      ,iv_group3_cd     IN  VARCHAR2                     --A-5で取得した政策群コード3
      ,iv_group3_nm     IN  VARCHAR2                     --A-5で取得した政策群名3
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--

--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'group3_month_count'; -- プログラム名
    
--  ===============================
--  固定ローカル変数
--  ===============================
    ln_month_sale_budget       NUMBER;         --月別商品群別売上
    ln_month_amount            NUMBER;         --月別商品群別数量
    ln_month_sub_margin        NUMBER;         --月別商品群別粗利益減数部分
    ln_year_month              NUMBER;         --年月
    ln_month_margin            NUMBER;         --月別商品群別粗利益額
    ln_month_credit_bunbo      NUMBER;         --月別商品群別掛率分母
    ln_month_credit            NUMBER;         --月別商品群別掛率
    ln_year_sale_budget        NUMBER;         --年間商品群別売上
    ln_year_amount             NUMBER;         --年間商品群別数量
    ln_year_margin             NUMBER;         --年間商品群別粗利益額
    ln_year_credit_bunbo       NUMBER;         --年間商品群別掛率分母
    ln_year_credit             NUMBER;         --年間商品群別掛率
    ln_sale_budget_5           NUMBER;         --5月売上
    ln_sale_budget_6           NUMBER;         --6月売上
    ln_sale_budget_7           NUMBER;         --7月売上
    ln_sale_budget_8           NUMBER;         --8月売上
    ln_sale_budget_9           NUMBER;         --9月売上
    ln_sale_budget_10          NUMBER;         --10月売上
    ln_sale_budget_11          NUMBER;         --11月売上
    ln_sale_budget_12          NUMBER;         --12月売上
    ln_sale_budget_1           NUMBER;         --1月売上
    ln_sale_budget_2           NUMBER;         --2月売上
    ln_sale_budget_3           NUMBER;         --3月売上
    ln_sale_budget_4           NUMBER;         --4月売上
    ln_amount_5                NUMBER;         --5月数量
    ln_amount_6                NUMBER;         --6月数量
    ln_amount_7                NUMBER;         --7月数量
    ln_amount_8                NUMBER;         --8月数量
    ln_amount_9                NUMBER;         --9月数量
    ln_amount_10               NUMBER;         --10月数量
    ln_amount_11               NUMBER;         --11月数量
    ln_amount_12               NUMBER;         --12月数量
    ln_amount_1                NUMBER;         --1月数量
    ln_amount_2                NUMBER;         --2月数量
    ln_amount_3                NUMBER;         --3月数量
    ln_amount_4                NUMBER;         --4月数量
    ln_margin_5                NUMBER;         --5月粗利益額
    ln_margin_6                NUMBER;         --6月粗利益額
    ln_margin_7                NUMBER;         --7月粗利益額
    ln_margin_8                NUMBER;         --8月粗利益額
    ln_margin_9                NUMBER;         --9月粗利益額
    ln_margin_10               NUMBER;         --10月粗利益額
    ln_margin_11               NUMBER;         --11月粗利益額
    ln_margin_12               NUMBER;         --12月粗利益額
    ln_margin_1                NUMBER;         --1月粗利益額
    ln_margin_2                NUMBER;         --2月粗利益額
    ln_margin_3                NUMBER;         --3月粗利益額
    ln_margin_4                NUMBER;         --4月粗利益額
    ln_credit_5                NUMBER;         --5月掛率
    ln_credit_6                NUMBER;         --6月掛率
    ln_credit_7                NUMBER;         --7月掛率
    ln_credit_8                NUMBER;         --8月掛率
    ln_credit_9                NUMBER;         --9月掛率
    ln_credit_10               NUMBER;         --10月掛率
    ln_credit_11               NUMBER;         --11月掛率
    ln_credit_12               NUMBER;         --12月掛率
    ln_credit_1                NUMBER;         --1月掛率
    ln_credit_2                NUMBER;         --2月掛率
    ln_credit_3                NUMBER;         --3月掛率
    ln_credit_4                NUMBER;         --4月掛率
    ln_month_no                NUMBER;         --月
--
--  ===============================
--  ローカル・カーソル
--  ===============================
    --商品群月別データ抽出
    CURSOR   group3_month_cur
    IS
--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT  SUM(xipl.sales_budget)  sales_budget_sum                 --売上金額
--             ,SUM(xipl.amount)        amount_sum                       --数量
--             ,SUM(xipl.amount * xcgv.now_business_cost) sub_margin     --粗利益減数
--             ,SUM(xipl.amount * xcgv.now_unit_price)    credit_bunbo   --掛率分母
--             ,xipl.year_month                                          --年月
--      FROM    xxcsm_item_plan_lines       xipl                         -- 商品計画明細テーブル
--             ,xxcsm_item_plan_headers     xiph                         -- 商品計画ヘッダテーブル
--             ,xxcsm_commodity_group3_v    xcgv                         -- 政策群コード３ビュー
--      WHERE   xiph.plan_year = gn_subject_year                         --対象年度
--      AND     xiph.location_cd = iv_kyoten_cd                          --拠点コード
--      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
--      AND     xipl.item_group_no LIKE REPLACE(iv_group3_cd,'*','_')    --政策群コード3桁     
----//+UPD START 2009/02/13 CT015 S.Son
--    --AND     xipl.item_kbn = '1'                                      --商品区分(1：商品単品)
--      AND     xipl.item_kbn <> '0'                                     --商品区分(1：商品単品、2：新商品)
----//+UPD END 2009/02/13 CT015 S.Son
--      AND     xipl.item_no = xcgv.item_cd
--      GROUP BY xipl.year_month
--      ORDER BY xipl.year_month
--    ;
      SELECT  sub.year_month                          year_month       --年月
             ,SUM(sub.sales_budget)                   sales_budget_sum --売上金額
             ,SUM(sub.amount)                         amount_sum       --数量
             ,SUM(sub.amount * sub.now_business_cost) sub_margin       --粗利益減数
             ,SUM(sub.amount * sub.now_unit_price)    credit_bunbo     --掛率分母
      FROM   (
              SELECT 
                  xipl.year_month                     year_month
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute8, 0)             now_business_cost
                  --
                  -- 営業原価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute8, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の営業原価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- 営業原価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                              WHERE   xsibh.item_hst_id   =
                                (
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.discrete_cost  IS NOT NULL             -- 営業原価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_business_cost
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                  --
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute5, 0)             now_unit_price
                  --
                  -- 定価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute5, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の定価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- 定価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                              WHERE   xsibh.item_hst_id   =
                                (
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.fixed_price    IS NOT NULL             -- 定価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_unit_price    -- 定価
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                , xipl.amount                         amount
                , xipl.sales_budget                   sales_budget
              FROM    mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , mtl_categories_tl           mct
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_lines       xipl
                    , xxcsm_item_plan_headers     xiph
              WHERE   mcsb2.structure_id                        =   mcb2.structure_id
              AND     mcb2.enabled_flag                         =   cv_flg_y
              AND     NVL(mcb2.disable_date, gd_process_date)   <=  gd_process_date
              AND     fifs2.id_flex_structure_code              =   cv_sgun_code
              AND     fifs2.application_id                      =   cn_appl_id
              AND     fifs2.id_flex_code                        =   cv_mcat
              AND     fifs2.id_flex_num                         =   mcsb2.structure_id
              AND     gic.category_id                           =   mcb2.category_id
              AND     gic.category_set_id                       =   mcsb2.category_set_id
              AND     gic.item_id                               =   iimb.item_id
              AND     iimb.item_id                              =   xsib.item_id
              AND     xsib.item_status                          =   cv_item_status_30
              AND     mcb2.category_id                          =   mct.category_id
              AND     mct.language                              =   cv_ja
              AND     xiph.plan_year                            =   gn_subject_year           --対象年度
              AND     xiph.location_cd                          =   iv_kyoten_cd              --拠点コード
              AND     xiph.item_plan_header_id                  =   xipl.item_plan_header_id
              AND     xipl.item_group_no LIKE REPLACE(iv_group3_cd, cv_group_3, cv_bar)     --政策群コード3桁     
              AND     xipl.item_kbn <> cv_item_kbn                                          --商品区分(1：商品単品、2：新商品)
              AND     xipl.item_no = iimb.item_no
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, '*', 1, 1)          =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)             =   SUBSTRB(mcb2.segment1, 1, 1)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                         =   cv_item_group
                        AND     flv.language                            =   cv_ja
                        AND     flv.enabled_flag                        =   cv_flg_y
                        AND     INSTR(flv.lookup_code, '*', 1, 1)       =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)          =   SUBSTRB(mcb2.segment1, 1, 1)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                    )
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   4
                        AND     SUBSTRB(mcb.segment1, 1, 3)             =   SUBSTRB(mcb2.segment1, 1, 3)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   4
                        AND     SUBSTRB(flv.lookup_code, 1, 3)            =   SUBSTRB(mcb2.segment1, 1, 3)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                   )
        ) sub
      GROUP BY year_month
      ORDER BY year_month
      ;
--//+UPD END 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami    
    group3_month_cur_rec group3_month_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--ローカル変数初期化
    ln_month_sale_budget    := 0;              --月別商品群別売上
    ln_month_amount         := 0;              --月別商品群別数量
    ln_month_margin         := 0;              --月別商品群別粗利益額
    ln_month_credit_bunbo   := 0;              --月別商品群別掛率分母
    ln_month_credit         := 0;              --月別商品群別掛率
    ln_month_sub_margin     := 0;              --月別商品群別粗利益減数
    ln_year_sale_budget     := 0;              --年間商品群別売上
    ln_year_amount          := 0;              --年間商品群別数量
    ln_year_margin          := 0;              --年間商品群別粗利益額
    ln_year_credit_bunbo    := 0;              --年間商品群別掛率分母
    ln_year_credit          := 0;              --年間商品群別掛率
    OPEN group3_month_cur;
    <<group3_month_loop>>
    LOOP
      FETCH group3_month_cur INTO group3_month_cur_rec;
      EXIT WHEN group3_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  group3_month_cur_rec.sales_budget_sum;                          --月別商品群別売上
        ln_month_amount         :=  group3_month_cur_rec.amount_sum;                                --月別商品群別数量
        ln_month_sub_margin     :=  group3_month_cur_rec.sub_margin;                                --月別商品群別粗利益減数
        ln_month_credit_bunbo   :=  group3_month_cur_rec.credit_bunbo;                              --月別商品群別掛率分母
        ln_year_month           :=  group3_month_cur_rec.year_month;                                --年月
        --商品群月別データ算出
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --月別商品群別粗利益額
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --月別商品群別掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --年間商品群別売上
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --年間商品群別数量
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --年間商品群別粗利益額
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --年間商品群別掛率分母
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --年間商品群別掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --各月データ保存
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP group3_month_loop;
    CLOSE group3_month_cur;
--
-- MODIFY START 2011/12/14 E_本稼動_08817 K.Nakamura
----//+ADD START 2009/02/19 CT038 K.Yamada
---- MODIFY  START  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
----    IF ln_year_sale_budget <> 0 THEN
----   IF ln_year_sale_budget <> 0 OR ln_year_amount <> 0 THEN
---- MODIFY  END  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
----//+ADD END   2009/02/19 CT038 K.Yamada
    -- 群出力フラグがONの場合
    IF (gv_group_flag = cv_flg_y) THEN
-- MODIFY  END  2011/12/14 E_本稼動_08817 K.Nakamura
      --月別商品群データ登録
      --1行目：数量
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,iv_group3_cd
      ,iv_group3_nm
      ,gv_amount_name
      ,NVL(ln_amount_5,0)
      ,NVL(ln_amount_6,0)
      ,NVL(ln_amount_7,0)
      ,NVL(ln_amount_8,0)
      ,NVL(ln_amount_9,0)
      ,NVL(ln_amount_10,0)
      ,NVL(ln_amount_11,0)
      ,NVL(ln_amount_12,0)
      ,NVL(ln_amount_1,0)
      ,NVL(ln_amount_2,0)
      ,NVL(ln_amount_3,0)
      ,NVL(ln_amount_4,0)
      ,NVL(ln_year_amount,0)
      );
      --2行目：売上
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_budget_name
      ,NVL(ROUND(ln_sale_budget_5/1000),0)
      ,NVL(ROUND(ln_sale_budget_6/1000),0)
      ,NVL(ROUND(ln_sale_budget_7/1000),0)
      ,NVL(ROUND(ln_sale_budget_8/1000),0)
      ,NVL(ROUND(ln_sale_budget_9/1000),0)
      ,NVL(ROUND(ln_sale_budget_10/1000),0)
      ,NVL(ROUND(ln_sale_budget_11/1000),0)
      ,NVL(ROUND(ln_sale_budget_12/1000),0)
      ,NVL(ROUND(ln_sale_budget_1/1000),0)
      ,NVL(ROUND(ln_sale_budget_2/1000),0)
      ,NVL(ROUND(ln_sale_budget_3/1000),0)
      ,NVL(ROUND(ln_sale_budget_4/1000),0)
      ,NVL(ROUND(ln_year_sale_budget/1000),0)
      );
      --3行目：粗利益額
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_margin_name
      ,NVL(ROUND(ln_margin_5/1000),0)
      ,NVL(ROUND(ln_margin_6/1000),0)
      ,NVL(ROUND(ln_margin_7/1000),0)
      ,NVL(ROUND(ln_margin_8/1000),0)
      ,NVL(ROUND(ln_margin_9/1000),0)
      ,NVL(ROUND(ln_margin_10/1000),0)
      ,NVL(ROUND(ln_margin_11/1000),0)
      ,NVL(ROUND(ln_margin_12/1000),0)
      ,NVL(ROUND(ln_margin_1/1000),0)
      ,NVL(ROUND(ln_margin_2/1000),0)
      ,NVL(ROUND(ln_margin_3/1000),0)
      ,NVL(ROUND(ln_margin_4/1000),0)
      ,NVL(ROUND(ln_year_margin/1000),0)
      );
      --4行目：掛率
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_credit_name
      ,NVL(ln_credit_5,0)
      ,NVL(ln_credit_6,0)
      ,NVL(ln_credit_7,0)
      ,NVL(ln_credit_8,0)
      ,NVL(ln_credit_9,0)
      ,NVL(ln_credit_10,0)
      ,NVL(ln_credit_11,0)
      ,NVL(ln_credit_12,0)
      ,NVL(ln_credit_1,0)
      ,NVL(ln_credit_2,0)
      ,NVL(ln_credit_3,0)
      ,NVL(ln_credit_4,0)
      ,NVL(ln_year_credit,0)
      );
--//+ADD START 2009/02/19 CT038 K.Yamada
    END IF;
    -- 群出力フラグをOFFにする
    gv_group_flag := cv_flg_n;
--//+ADD END   2009/02/19 CT038 K.Yamada
--
--#################################  固定例外処理部  #############################
  EXCEPTION
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
--#####################################  固定部 END   ###########################
--
  END group3_month_count;
--
  /****************************************************************************
  * Procedure Name   : group1_month_count
  * Description      : 商品区分月別集計(A-8)
  *                  : 月別商品区分データ登録(A-9)
  ****************************************************************************/
  PROCEDURE group1_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     -- A-2で取得した拠点コード
      ,iv_kyoten_nm     IN  VARCHAR2                     -- A-2で取得した拠点名称
      ,iv_group1_cd     IN  VARCHAR2                     -- A-5で取得した政策群コード1
      ,iv_group1_nm     IN  VARCHAR2                     -- A-5で取得した政策群名1
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--

--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'group1_month_count'; -- プログラム名
--  ===============================
--  固定ローカル変数
--  ===============================
    ln_month_sale_budget       NUMBER;         --月別商品区分売上
    ln_month_amount            NUMBER;         --月別商品区分数量
    ln_month_sub_margin        NUMBER;         --月別商品区分粗利益減数
    ln_year_month              NUMBER;         --年月
    ln_month_margin            NUMBER;         --月別商品区分粗利益額
    ln_month_credit_bunbo      NUMBER;         --月別商品区分掛率分母
    ln_month_credit            NUMBER;         --月別商品区分掛率
    ln_year_sale_budget        NUMBER;         --年間商品区分売上
    ln_year_amount             NUMBER;         --年間商品区分数量
    ln_year_margin             NUMBER;         --年間商品区分粗利益額
    ln_year_credit_bunbo       NUMBER;         --年間商品区分掛率分母
    ln_year_credit             NUMBER;         --年間商品区分掛率
    ln_sale_budget_5           NUMBER;         --5月売上
    ln_sale_budget_6           NUMBER;         --6月売上
    ln_sale_budget_7           NUMBER;         --7月売上
    ln_sale_budget_8           NUMBER;         --8月売上
    ln_sale_budget_9           NUMBER;         --9月売上
    ln_sale_budget_10          NUMBER;         --10月売上
    ln_sale_budget_11          NUMBER;         --11月売上
    ln_sale_budget_12          NUMBER;         --12月売上
    ln_sale_budget_1           NUMBER;         --1月売上
    ln_sale_budget_2           NUMBER;         --2月売上
    ln_sale_budget_3           NUMBER;         --3月売上
    ln_sale_budget_4           NUMBER;         --4月売上
    ln_amount_5                NUMBER;         --5月数量
    ln_amount_6                NUMBER;         --6月数量
    ln_amount_7                NUMBER;         --7月数量
    ln_amount_8                NUMBER;         --8月数量
    ln_amount_9                NUMBER;         --9月数量
    ln_amount_10               NUMBER;         --10月数量
    ln_amount_11               NUMBER;         --11月数量
    ln_amount_12               NUMBER;         --12月数量
    ln_amount_1                NUMBER;         --1月数量
    ln_amount_2                NUMBER;         --2月数量
    ln_amount_3                NUMBER;         --3月数量
    ln_amount_4                NUMBER;         --4月数量
    ln_margin_5                NUMBER;         --5月粗利益額
    ln_margin_6                NUMBER;         --6月粗利益額
    ln_margin_7                NUMBER;         --7月粗利益額
    ln_margin_8                NUMBER;         --8月粗利益額
    ln_margin_9                NUMBER;         --9月粗利益額
    ln_margin_10               NUMBER;         --10月粗利益額
    ln_margin_11               NUMBER;         --11月粗利益額
    ln_margin_12               NUMBER;         --12月粗利益額
    ln_margin_1                NUMBER;         --1月粗利益額
    ln_margin_2                NUMBER;         --2月粗利益額
    ln_margin_3                NUMBER;         --3月粗利益額
    ln_margin_4                NUMBER;         --4月粗利益額
    ln_credit_5                NUMBER;         --5月掛率
    ln_credit_6                NUMBER;         --6月掛率
    ln_credit_7                NUMBER;         --7月掛率
    ln_credit_8                NUMBER;         --8月掛率
    ln_credit_9                NUMBER;         --9月掛率
    ln_credit_10               NUMBER;         --10月掛率
    ln_credit_11               NUMBER;         --11月掛率
    ln_credit_12               NUMBER;         --12月掛率
    ln_credit_1                NUMBER;         --1月掛率
    ln_credit_2                NUMBER;         --2月掛率
    ln_credit_3                NUMBER;         --3月掛率
    ln_credit_4                NUMBER;         --4月掛率
    ln_month_no                NUMBER;         --月
--
--  ===============================
--  ローカル・カーソル
--  ===============================
    --商品区分月別データ抽出
    CURSOR   group1_month_cur
    IS
--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT  SUM(xipl.sales_budget)  sales_budget_sum               --売上金額
--             ,SUM(xipl.amount)        amount_sum                     --数量
--             ,SUM(xipl.amount * xcgv.now_business_cost) sub_margin   --
--             ,SUM(xipl.amount * xcgv.now_unit_price)    credit_bunbo --
--             ,xipl.year_month                                        --年月
--      FROM    xxcsm_item_plan_lines       xipl                       -- 商品計画明細テーブル
--             ,xxcsm_item_plan_headers     xiph                       -- 商品計画ヘッダテーブル
--             ,xxcsm_commodity_group3_v    xcgv                       -- 政策群コード３ビュー
--      WHERE   xiph.plan_year = gn_subject_year                       --対象年度
--      AND     xiph.location_cd = iv_kyoten_cd                        --拠点コード
--      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
--      AND     xipl.item_group_no LIKE iv_group1_cd||'%'              --政策群コード1桁
----//+UPD START 2009/02/13 CT015 S.Son
--    --AND     xipl.item_kbn = '1'                                    --商品区分(1：商品単品)
--      AND     xipl.item_kbn <> '0'                                   --商品区分(1：商品単品、2：新商品)
----//+UPD END 2009/02/13 CT015 S.Son
--      AND     xipl.item_no = xcgv.item_cd                           
--      GROUP BY xipl.year_month
--      ORDER BY xipl.year_month
--    ;
      SELECT  sub.year_month                          year_month       --年月
             ,SUM(sub.sales_budget)                   sales_budget_sum --売上金額
             ,SUM(sub.amount)                         amount_sum       --数量
             ,SUM(sub.amount * sub.now_business_cost) sub_margin       --粗利益減数
             ,SUM(sub.amount * sub.now_unit_price)    credit_bunbo     --掛率分母
      FROM   (
              SELECT 
                  xipl.year_month                     year_month
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute8, 0)             now_business_cost
                  --
                  -- 営業原価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute8, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の営業原価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- 営業原価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                              WHERE   xsibh.item_hst_id   =
                                (
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.discrete_cost  IS NOT NULL             -- 営業原価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_business_cost
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                  --
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute5, 0)             now_unit_price
                  --
                  -- 定価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute5, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の定価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- 定価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                              WHERE   xsibh.item_hst_id   =
                                (
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.fixed_price    IS NOT NULL             -- 定価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_unit_price    -- 定価
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                , xipl.amount                         amount
                , xipl.sales_budget                   sales_budget
              FROM    mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , mtl_categories_tl           mct
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_lines       xipl
                    , xxcsm_item_plan_headers     xiph
              WHERE   mcsb2.structure_id                        =   mcb2.structure_id
              AND     mcb2.enabled_flag                         =   cv_flg_y
              AND     NVL(mcb2.disable_date, gd_process_date)   <=  gd_process_date
              AND     fifs2.id_flex_structure_code              =   cv_sgun_code
              AND     fifs2.application_id                      =   cn_appl_id
              AND     fifs2.id_flex_code                        =   cv_mcat
              AND     fifs2.id_flex_num                         =   mcsb2.structure_id
              AND     gic.category_id                           =   mcb2.category_id
              AND     gic.category_set_id                       =   mcsb2.category_set_id
              AND     gic.item_id                               =   iimb.item_id
              AND     iimb.item_id                              =   xsib.item_id
              AND     xsib.item_status                          =   cv_item_status_30
              AND     mcb2.category_id                          =   mct.category_id
              AND     mct.language                              =   cv_ja
              AND     xiph.plan_year = gn_subject_year                         --対象年度
              AND     xiph.location_cd = iv_kyoten_cd                          --拠点コード
              AND     xiph.item_plan_header_id = xipl.item_plan_header_id
              AND     xipl.item_group_no LIKE iv_group1_cd || cv_percent     
              AND     xipl.item_kbn <> cv_item_kbn                             --商品区分(1：商品単品、2：新商品)
              AND     xipl.item_no = iimb.item_no
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)             =   SUBSTRB(mcb2.segment1, 1, 1)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)            =   SUBSTRB(mcb2.segment1, 1, 1)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                    )
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   4
                        AND     SUBSTRB(mcb.segment1, 1, 3)             =   SUBSTRB(mcb2.segment1, 1, 3)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   4
                        AND     SUBSTRB(flv.lookup_code, 1, 3)            =   SUBSTRB(mcb2.segment1, 1, 3)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                    )  
        ) sub
      GROUP BY year_month
      ORDER BY year_month
      ;
--//+UPD END 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
    group1_month_cur_rec group1_month_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--ローカル変数初期化
    ln_month_sale_budget    := 0;              --月別商品区分売上
    ln_month_amount         := 0;              --月別商品区分数量
    ln_month_margin         := 0;              --月別商品区分粗利益額
    ln_month_credit_bunbo   := 0;              --月別商品区分掛率分母
    ln_month_credit         := 0;              --月別商品区分掛率
    ln_month_sub_margin     := 0;              --月別商品区分粗利益減数
    ln_year_sale_budget     := 0;              --年間商品区分売上
    ln_year_amount          := 0;              --年間商品区分数量
    ln_year_margin          := 0;              --年間商品区分粗利益額
    ln_year_credit_bunbo    := 0;              --年間商品区分掛率分母
    ln_year_credit          := 0;              --年間商品区分掛率
    
    OPEN group1_month_cur;
    <<group1_month_loop>>
    LOOP
      FETCH group1_month_cur INTO group1_month_cur_rec;
      EXIT WHEN group1_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  group1_month_cur_rec.sales_budget_sum;                          --月別商品区分売上
        ln_month_amount         :=  group1_month_cur_rec.amount_sum;                                --月別商品区分数量
        ln_month_sub_margin     :=  group1_month_cur_rec.sub_margin;
        ln_month_credit_bunbo   :=  group1_month_cur_rec.credit_bunbo;
        ln_year_month           :=  group1_month_cur_rec.year_month;                                --年月
        --商品区分月別データ算出
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --月別商品区分粗利益額
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --月別商品区分掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --年間商品区分売上
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --年間商品区分数量
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --年間商品区分粗利益額
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --年間商品区分掛率分母
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --年間商品区分掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --各月データ保存
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP group1_month_loop;
    CLOSE group1_month_cur;
--
    --月別商品区分データ登録
    --1行目：数量
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,iv_group1_cd
    ,iv_group1_nm
    ,gv_amount_name
    ,NVL(ln_amount_5,0)
    ,NVL(ln_amount_6,0)
    ,NVL(ln_amount_7,0)
    ,NVL(ln_amount_8,0)
    ,NVL(ln_amount_9,0)
    ,NVL(ln_amount_10,0)
    ,NVL(ln_amount_11,0)
    ,NVL(ln_amount_12,0)
    ,NVL(ln_amount_1,0)
    ,NVL(ln_amount_2,0)
    ,NVL(ln_amount_3,0)
    ,NVL(ln_amount_4,0)
    ,NVL(ln_year_amount,0)
    );
    --2行目：売上
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_sale_budget_5/1000),0)
    ,NVL(ROUND(ln_sale_budget_6/1000),0)
    ,NVL(ROUND(ln_sale_budget_7/1000),0)
    ,NVL(ROUND(ln_sale_budget_8/1000),0)
    ,NVL(ROUND(ln_sale_budget_9/1000),0)
    ,NVL(ROUND(ln_sale_budget_10/1000),0)
    ,NVL(ROUND(ln_sale_budget_11/1000),0)
    ,NVL(ROUND(ln_sale_budget_12/1000),0)
    ,NVL(ROUND(ln_sale_budget_1/1000),0)
    ,NVL(ROUND(ln_sale_budget_2/1000),0)
    ,NVL(ROUND(ln_sale_budget_3/1000),0)
    ,NVL(ROUND(ln_sale_budget_4/1000),0)
    ,NVL(ROUND(ln_year_sale_budget/1000),0)
    );
    --3行目：粗利益額
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_margin_5/1000),0)
    ,NVL(ROUND(ln_margin_6/1000),0)
    ,NVL(ROUND(ln_margin_7/1000),0)
    ,NVL(ROUND(ln_margin_8/1000),0)
    ,NVL(ROUND(ln_margin_9/1000),0)
    ,NVL(ROUND(ln_margin_10/1000),0)
    ,NVL(ROUND(ln_margin_11/1000),0)
    ,NVL(ROUND(ln_margin_12/1000),0)
    ,NVL(ROUND(ln_margin_1/1000),0)
    ,NVL(ROUND(ln_margin_2/1000),0)
    ,NVL(ROUND(ln_margin_3/1000),0)
    ,NVL(ROUND(ln_margin_4/1000),0)
    ,NVL(ROUND(ln_year_margin/1000),0)
    );
    --4行目：掛率
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,NVL(ln_credit_5,0)
    ,NVL(ln_credit_6,0)
    ,NVL(ln_credit_7,0)
    ,NVL(ln_credit_8,0)
    ,NVL(ln_credit_9,0)
    ,NVL(ln_credit_10,0)
    ,NVL(ln_credit_11,0)
    ,NVL(ln_credit_12,0)
    ,NVL(ln_credit_1,0)
    ,NVL(ln_credit_2,0)
    ,NVL(ln_credit_3,0)
    ,NVL(ln_credit_4,0)
    ,NVL(ln_year_credit,0)
    );
--
--#################################  固定例外処理部  #############################
  EXCEPTION
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
--#####################################  固定部 END   ###########################
--
  END group1_month_count;
--
  /****************************************************************************
  * Procedure Name   : all_item_month_count
  * Description      : 商品合計月別集計(A-10)
  *                  : 月別商品合計データ登録(A-11)
  ****************************************************************************/
  PROCEDURE all_item_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     -- A-2で取得した拠点コード
      ,iv_kyoten_nm     IN  VARCHAR2                     -- A-2で取得した拠点名称
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--

--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'all_item_month_count'; -- プログラム名
    
--  ===============================
--  固定ローカル変数
--  ===============================
    ln_month_sale_budget       NUMBER;         --月別商品合計売上
    ln_month_amount            NUMBER;         --月別商品合計数量
    ln_month_sub_margin        NUMBER;         --月別商品合計粗利益減数
    ln_year_month              NUMBER;         --年月
    ln_month_margin            NUMBER;         --月別商品合計粗利益額
    ln_month_credit_bunbo      NUMBER;         --月別商品合計掛率分母
    ln_month_credit            NUMBER;         --月別商品合計掛率
    ln_year_sale_budget        NUMBER;         --年間商品合計売上
    ln_year_amount             NUMBER;         --年間商品合計数量
    ln_year_margin             NUMBER;         --年間商品合計粗利益額
    ln_year_credit_bunbo       NUMBER;         --年間商品合計掛率分母
    ln_year_credit             NUMBER;         --年間商品合計掛率
    ln_sale_budget_5           NUMBER;         --5月売上
    ln_sale_budget_6           NUMBER;         --6月売上
    ln_sale_budget_7           NUMBER;         --7月売上
    ln_sale_budget_8           NUMBER;         --8月売上
    ln_sale_budget_9           NUMBER;         --9月売上
    ln_sale_budget_10          NUMBER;         --10月売上
    ln_sale_budget_11          NUMBER;         --11月売上
    ln_sale_budget_12          NUMBER;         --12月売上
    ln_sale_budget_1           NUMBER;         --1月売上
    ln_sale_budget_2           NUMBER;         --2月売上
    ln_sale_budget_3           NUMBER;         --3月売上
    ln_sale_budget_4           NUMBER;         --4月売上
    ln_amount_5                NUMBER;         --5月数量
    ln_amount_6                NUMBER;         --6月数量
    ln_amount_7                NUMBER;         --7月数量
    ln_amount_8                NUMBER;         --8月数量
    ln_amount_9                NUMBER;         --9月数量
    ln_amount_10               NUMBER;         --10月数量
    ln_amount_11               NUMBER;         --11月数量
    ln_amount_12               NUMBER;         --12月数量
    ln_amount_1                NUMBER;         --1月数量
    ln_amount_2                NUMBER;         --2月数量
    ln_amount_3                NUMBER;         --3月数量
    ln_amount_4                NUMBER;         --4月数量
    ln_margin_5                NUMBER;         --5月粗利益額
    ln_margin_6                NUMBER;         --6月粗利益額
    ln_margin_7                NUMBER;         --7月粗利益額
    ln_margin_8                NUMBER;         --8月粗利益額
    ln_margin_9                NUMBER;         --9月粗利益額
    ln_margin_10               NUMBER;         --10月粗利益額
    ln_margin_11               NUMBER;         --11月粗利益額
    ln_margin_12               NUMBER;         --12月粗利益額
    ln_margin_1                NUMBER;         --1月粗利益額
    ln_margin_2                NUMBER;         --2月粗利益額
    ln_margin_3                NUMBER;         --3月粗利益額
    ln_margin_4                NUMBER;         --4月粗利益額
    ln_credit_5                NUMBER;         --5月掛率
    ln_credit_6                NUMBER;         --6月掛率
    ln_credit_7                NUMBER;         --7月掛率
    ln_credit_8                NUMBER;         --8月掛率
    ln_credit_9                NUMBER;         --9月掛率
    ln_credit_10               NUMBER;         --10月掛率
    ln_credit_11               NUMBER;         --11月掛率
    ln_credit_12               NUMBER;         --12月掛率
    ln_credit_1                NUMBER;         --1月掛率
    ln_credit_2                NUMBER;         --2月掛率
    ln_credit_3                NUMBER;         --3月掛率
    ln_credit_4                NUMBER;         --4月掛率
    ln_month_no                NUMBER;         --月
--
--  ===============================
--  ローカル・カーソル
--  ===============================
    --商品合計月別データ抽出
    CURSOR   all_item_month_cur
    IS
--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT  SUM(xipl.sales_budget)  sales_budget_sum               --売上金額
--             ,SUM(xipl.amount)        amount_sum                     --数量
--             ,SUM(xipl.amount * now_business_cost)  sub_margin       --粗利益減数
--             ,SUM(xipl.amount * now_unit_price)     credit_bunbo     --掛率分母
--             ,xipl.year_month                                        --年月
--      FROM    xxcsm_item_plan_lines       xipl                       -- 商品計画明細テーブル
--             ,xxcsm_item_plan_headers     xiph                       -- 商品計画ヘッダテーブル
--             ,xxcsm_commodity_group3_v    xcgv                       -- 政策群コード３ビュー
--      WHERE   xiph.plan_year = gn_subject_year                       --対象年度
--      AND     xiph.location_cd = iv_kyoten_cd                        --拠点コード
--      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
--      AND     xipl.item_group_no NOT LIKE cv_group_d||'%'            --政策群コード1桁≠D(その他以外)
----//+UPD START 2009/02/13 CT015 S.Son
--    --AND     xipl.item_kbn = '1'                                    --商品区分(1：商品単品)
--      AND     xipl.item_kbn <> '0'                                   --商品区分(1：商品単品、2：新商品)
----//+UPD END 2009/02/13 CT015 S.Son
--      AND     xipl.item_no = xcgv.item_cd
--      GROUP BY xipl.year_month
--      ORDER BY xipl.year_month
--    ;
--
      SELECT  sub.year_month                          year_month       --年月
             ,SUM(sub.sales_budget)                   sales_budget_sum --売上金額
             ,SUM(sub.amount)                         amount_sum       --数量
             ,SUM(sub.amount * sub.now_business_cost) sub_margin       --粗利益減数
             ,SUM(sub.amount * sub.now_unit_price)    credit_bunbo     --掛率分母
      FROM   (
              SELECT 
                  xipl.year_month                     year_month
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute8, 0)             now_business_cost
                  --
                  -- 営業原価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute8, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の営業原価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- 営業原価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                              WHERE   xsibh.item_hst_id   =
                                (
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.discrete_cost  IS NOT NULL             -- 営業原価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_business_cost
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                  --
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute5, 0)             now_unit_price
                  --
                  -- 定価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute5, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の定価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- 定価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                              WHERE   xsibh.item_hst_id   = 
                                ( 
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.fixed_price    IS NOT NULL             -- 定価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_unit_price    -- 定価
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                , xipl.amount                         amount
                , xipl.sales_budget                   sales_budget
              FROM    mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , mtl_categories_tl           mct
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_lines       xipl
                    , xxcsm_item_plan_headers     xiph
              WHERE   mcsb2.structure_id                        =   mcb2.structure_id
              AND     mcb2.enabled_flag                         =   cv_flg_y
              AND     NVL(mcb2.disable_date, gd_process_date)   <=  gd_process_date
              AND     fifs2.id_flex_structure_code              =   cv_sgun_code
              AND     fifs2.application_id                      =   cn_appl_id
              AND     fifs2.id_flex_code                        =   cv_mcat
              AND     fifs2.id_flex_num                         =   mcsb2.structure_id
              AND     gic.category_id                           =   mcb2.category_id
              AND     gic.category_set_id                       =   mcsb2.category_set_id
              AND     gic.item_id                               =   iimb.item_id
              AND     iimb.item_id                              =   xsib.item_id
              AND     xsib.item_status                          =   cv_item_status_30
              AND     mcb2.category_id                          =   mct.category_id
              AND     mct.language                              =   cv_ja
              AND     xiph.plan_year = gn_subject_year                         --対象年度
              AND     xiph.location_cd = iv_kyoten_cd                          --拠点コード
              AND     xiph.item_plan_header_id = xipl.item_plan_header_id
              AND     xipl.item_group_no NOT LIKE cv_group_d || cv_percent     
              AND     xipl.item_kbn <> cv_item_kbn                             --商品区分(1：商品単品、2：新商品)
              AND     xipl.item_no = iimb.item_no
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)             =   SUBSTRB(mcb2.segment1, 1, 1)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)            =   SUBSTRB(mcb2.segment1, 1, 1)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                    )
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   4
                        AND     SUBSTRB(mcb.segment1, 1, 3)             =   SUBSTRB(mcb2.segment1, 1, 3)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   4
                        AND     SUBSTRB(flv.lookup_code, 1, 3)            =   SUBSTRB(mcb2.segment1, 1, 3)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                  )
        ) sub
      GROUP BY year_month
      ORDER BY year_month
      ;
--//+UPD END 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
    all_item_month_cur_rec all_item_month_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--ローカル変数初期化
    ln_month_sale_budget    := 0;              --月別商品合計売上
    ln_month_amount         := 0;              --月別商品合計数量
    ln_month_margin         := 0;              --月別商品合計粗利益額
    ln_month_credit_bunbo   := 0;              --月別商品合計掛率分母
    ln_month_credit         := 0;              --月別商品合計掛率
    ln_month_sub_margin     := 0;              --月別商品合計粗利益減数
    ln_year_sale_budget     := 0;              --年間商品合計売上
    ln_year_amount          := 0;              --年間商品合計数量
    ln_year_margin          := 0;              --年間商品合計粗利益額
    ln_year_credit_bunbo    := 0;              --年間商品合計掛率分母
    ln_year_credit          := 0;              --年間商品合計掛率

    OPEN all_item_month_cur;
    <<all_item_month_loop>>
    LOOP
      FETCH all_item_month_cur INTO all_item_month_cur_rec;
      EXIT WHEN all_item_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  all_item_month_cur_rec.sales_budget_sum;                        --月別商品合計売上
        ln_month_amount         :=  all_item_month_cur_rec.amount_sum;                              --月別商品合計数量
        ln_month_sub_margin     :=  all_item_month_cur_rec.sub_margin;
        ln_month_credit_bunbo   :=  all_item_month_cur_rec.credit_bunbo;
        ln_year_month           :=  all_item_month_cur_rec.year_month;                              --年月
        --商品合計月別データ算出
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --月別商品合計粗利益額
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --月別商品合計掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --年間商品合計売上
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --年間商品合計数量
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --年間商品合計粗利益額
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --年間商品合計掛率分母
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --年間商品合計掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --各月データ保存
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP all_item_month_loop;
    CLOSE all_item_month_cur;
--
    --月別商品合計データ登録
    --1行目：数量
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_item_sum_name
    ,gv_amount_name
    ,NVL(ln_amount_5,0)
    ,NVL(ln_amount_6,0)
    ,NVL(ln_amount_7,0)
    ,NVL(ln_amount_8,0)
    ,NVL(ln_amount_9,0)
    ,NVL(ln_amount_10,0)
    ,NVL(ln_amount_11,0)
    ,NVL(ln_amount_12,0)
    ,NVL(ln_amount_1,0)
    ,NVL(ln_amount_2,0)
    ,NVL(ln_amount_3,0)
    ,NVL(ln_amount_4,0)
    ,NVL(ln_year_amount,0)
    );
    --2行目：売上
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,ROUND(ln_sale_budget_5/1000)
    ,ROUND(ln_sale_budget_6/1000)
    ,ROUND(ln_sale_budget_7/1000)
    ,ROUND(ln_sale_budget_8/1000)
    ,ROUND(ln_sale_budget_9/1000)
    ,ROUND(ln_sale_budget_10/1000)
    ,ROUND(ln_sale_budget_11/1000)
    ,ROUND(ln_sale_budget_12/1000)
    ,ROUND(ln_sale_budget_1/1000)
    ,ROUND(ln_sale_budget_2/1000)
    ,ROUND(ln_sale_budget_3/1000)
    ,ROUND(ln_sale_budget_4/1000)
    ,ROUND(ln_year_sale_budget/1000)
    );
    --3行目：粗利益額
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,ROUND(ln_margin_5/1000)
    ,ROUND(ln_margin_6/1000)
    ,ROUND(ln_margin_7/1000)
    ,ROUND(ln_margin_8/1000)
    ,ROUND(ln_margin_9/1000)
    ,ROUND(ln_margin_10/1000)
    ,ROUND(ln_margin_11/1000)
    ,ROUND(ln_margin_12/1000)
    ,ROUND(ln_margin_1/1000)
    ,ROUND(ln_margin_2/1000)
    ,ROUND(ln_margin_3/1000)
    ,ROUND(ln_margin_4/1000)
    ,ROUND(ln_year_margin/1000)
    );
    --4行目：掛率
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,NVL(ln_credit_5,0)
    ,NVL(ln_credit_6,0)
    ,NVL(ln_credit_7,0)
    ,NVL(ln_credit_8,0)
    ,NVL(ln_credit_9,0)
    ,NVL(ln_credit_10,0)
    ,NVL(ln_credit_11,0)
    ,NVL(ln_credit_12,0)
    ,NVL(ln_credit_1,0)
    ,NVL(ln_credit_2,0)
    ,NVL(ln_credit_3,0)
    ,NVL(ln_credit_4,0)
    ,NVL(ln_year_credit,0)
    );
--
--#################################  固定例外処理部  #############################
  EXCEPTION
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
--#####################################  固定部 END   ###########################
--
  END all_item_month_count;
--
  /****************************************************************************
  * Procedure Name   : item_month_count
  * Description      : 商品別月別集計(A-12)
  *                  : 月別商品別データ登録(A-13)
  ****************************************************************************/
  PROCEDURE item_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2で取得した拠点コード
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2で取得した拠点名称
      ,iv_item_cd       IN  VARCHAR2                     --A-5で取得した品目コード
      ,iv_item_nm       IN  VARCHAR2                     --A-5で取得した品目名
      ,in_amount_year   IN  NUMBER                       --A-5で取得した数量
      ,in_budget_year   IN  NUMBER                       --A-5で取得した売上
      ,in_cost          IN  NUMBER                       --A-5で取得した営業原価
      ,in_price         IN  NUMBER                       --A-5で取得した定価
      ,ov_errbuf        OUT NOCOPY VARCHAR2              --共通・エラー・メッセージ
      ,ov_retcode       OUT NOCOPY VARCHAR2              --リターン・コード
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             --ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--

--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'item_month_count'; -- プログラム名
    
--  ===============================
--  固定ローカル変数
--  ===============================
    ln_month_sale_budget       NUMBER;         --月別商品別売上
    ln_month_amount            NUMBER;         --月別商品別数量
    ln_year_month              NUMBER;         --年月
    ln_month_margin            NUMBER;         --月別商品別粗利益額
    ln_month_credit_bunbo      NUMBER;         --月別商品別掛率分母
    ln_month_credit            NUMBER;         --月別商品別掛率
    ln_year_sale_budget        NUMBER;         --年間商品別売上
    ln_year_amount             NUMBER;         --年間商品別数量
    ln_year_margin             NUMBER;         --年間商品別粗利益額
    ln_year_credit_bunbo       NUMBER;         --年間商品別掛率分母
    ln_year_credit             NUMBER;         --年間商品別掛率
    ln_cost                    NUMBER;         --営業原価
    ln_price                   NUMBER;         --定価
    ln_sale_budget_5           NUMBER;         --5月売上
    ln_sale_budget_6           NUMBER;         --6月売上
    ln_sale_budget_7           NUMBER;         --7月売上
    ln_sale_budget_8           NUMBER;         --8月売上
    ln_sale_budget_9           NUMBER;         --9月売上
    ln_sale_budget_10          NUMBER;         --10月売上
    ln_sale_budget_11          NUMBER;         --11月売上
    ln_sale_budget_12          NUMBER;         --12月売上
    ln_sale_budget_1           NUMBER;         --1月売上
    ln_sale_budget_2           NUMBER;         --2月売上
    ln_sale_budget_3           NUMBER;         --3月売上
    ln_sale_budget_4           NUMBER;         --4月売上
    ln_amount_5                NUMBER;         --5月数量
    ln_amount_6                NUMBER;         --6月数量
    ln_amount_7                NUMBER;         --7月数量
    ln_amount_8                NUMBER;         --8月数量
    ln_amount_9                NUMBER;         --9月数量
    ln_amount_10               NUMBER;         --10月数量
    ln_amount_11               NUMBER;         --11月数量
    ln_amount_12               NUMBER;         --12月数量
    ln_amount_1                NUMBER;         --1月数量
    ln_amount_2                NUMBER;         --2月数量
    ln_amount_3                NUMBER;         --3月数量
    ln_amount_4                NUMBER;         --4月数量
    ln_margin_5                NUMBER;         --5月粗利益額
    ln_margin_6                NUMBER;         --6月粗利益額
    ln_margin_7                NUMBER;         --7月粗利益額
    ln_margin_8                NUMBER;         --8月粗利益額
    ln_margin_9                NUMBER;         --9月粗利益額
    ln_margin_10               NUMBER;         --10月粗利益額
    ln_margin_11               NUMBER;         --11月粗利益額
    ln_margin_12               NUMBER;         --12月粗利益額
    ln_margin_1                NUMBER;         --1月粗利益額
    ln_margin_2                NUMBER;         --2月粗利益額
    ln_margin_3                NUMBER;         --3月粗利益額
    ln_margin_4                NUMBER;         --4月粗利益額
    ln_credit_5                NUMBER;         --5月掛率
    ln_credit_6                NUMBER;         --6月掛率
    ln_credit_7                NUMBER;         --7月掛率
    ln_credit_8                NUMBER;         --8月掛率
    ln_credit_9                NUMBER;         --9月掛率
    ln_credit_10               NUMBER;         --10月掛率
    ln_credit_11               NUMBER;         --11月掛率
    ln_credit_12               NUMBER;         --12月掛率
    ln_credit_1                NUMBER;         --1月掛率
    ln_credit_2                NUMBER;         --2月掛率
    ln_credit_3                NUMBER;         --3月掛率
    ln_credit_4                NUMBER;         --4月掛率
    ln_month_no                NUMBER;         --月
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    ln_chk_budget              NUMBER;         --売上(判定用)
    ln_chk_amount              NUMBER;         --数量(判定用)
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--
--  ===============================
--  ローカル・カーソル
--  ===============================
    --商品別月別データ抽出
    CURSOR   item_month_cur
    IS
      SELECT  xipl.sales_budget                                      --売上金額
             ,xipl.amount                                            --数量
             ,xipl.year_month                                        --年月
      FROM    xxcsm_item_plan_lines       xipl                       -- 商品計画明細テーブル
             ,xxcsm_item_plan_headers     xiph                       -- 商品計画ヘッダテーブル
      WHERE   xiph.plan_year = gn_subject_year                       --対象年度
      AND     xiph.location_cd = iv_kyoten_cd                        --拠点コード
      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
      AND     xipl.item_no = iv_item_cd                              --商品コード
--//+UPD START 2009/02/13 CT015 S.Son
    --AND     xipl.item_kbn = '1'                                    --商品区分(1：商品単品)
      AND     xipl.item_kbn <> '0'                                   --商品区分(1：商品単品、2：新商品)
--//+UPD END 2009/02/13 CT015 S.Son
      ORDER BY xipl.year_month
    ;
    item_month_cur_rec item_month_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--ローカル変数初期化
    ln_month_sale_budget    := 0;               --月別商品別売上
    ln_month_amount         := 0;               --月別商品別数量
    ln_month_margin         := 0;               --月別商品別粗利益額
    ln_month_credit_bunbo   := 0;               --月別商品別掛率分母
    ln_month_credit         := 0;               --月別商品別掛率
    ln_year_sale_budget     := in_budget_year;  --年間商品別売上
    ln_year_amount          := in_amount_year;  --年間商品別数量
    ln_year_margin          := 0;               --年間商品別粗利益額
    ln_year_credit_bunbo    := 0;               --年間商品別掛率分母
    ln_year_credit          := 0;               --年間商品別掛率
    ln_cost                 := in_cost;         --営業原価
    ln_price                := in_price;        --定価
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    ln_chk_budget           := 0;               --売上(判定用)
    ln_chk_amount           := 0;               --数量(判定用)
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--
    OPEN item_month_cur;
    <<item_month_loop>>
    LOOP
      FETCH item_month_cur INTO item_month_cur_rec;
      EXIT WHEN item_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  item_month_cur_rec.sales_budget;                                --月別商品別売上
        ln_month_amount         :=  item_month_cur_rec.amount;                                      --月別商品別数量
        ln_year_month           :=  item_month_cur_rec.year_month;                                  --年月
        --商品別月別データ算出
        ln_month_margin         := ln_month_sale_budget -(ln_month_amount * ln_cost);               --月別商品別粗利益額
        ln_month_credit_bunbo   := ln_month_amount * ln_price;                                      --月別商品別掛率分母
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --月別商品別掛率
        END IF;
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
        ln_chk_budget           := ln_chk_budget + ABS(ln_month_sale_budget);                       --売上(判定用)
        ln_chk_amount           := ln_chk_amount + ABS(ln_month_amount);                            --数量(判定用)
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --年間商品別粗利益額
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --年間商品別掛率分母
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --年間商品別掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --各月データ保存
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP item_month_loop;
    CLOSE item_month_cur;
--
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    -- 12ヶ月の売上および数量が0の場合
    IF (ln_chk_budget = 0) AND (ln_chk_amount = 0) THEN
      -- 群出力フラグがOFF(または初回設定時)の場合
      IF (gv_group_flag = cv_flg_n) THEN
        -- 群出力フラグをOFF
        gv_group_flag := cv_flg_n;
      END IF;
    -- 12ヶ月の売上または数量が0以外の場合
    ELSE
      -- 群出力フラグをON
      gv_group_flag := cv_flg_y;
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
      --月別商品別データ登録
      --1行目：数量
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,iv_item_cd
      ,iv_item_nm
      ,gv_amount_name
      ,NVL(ln_amount_5,0)
      ,NVL(ln_amount_6,0)
      ,NVL(ln_amount_7,0)
      ,NVL(ln_amount_8,0)
      ,NVL(ln_amount_9,0)
      ,NVL(ln_amount_10,0)
      ,NVL(ln_amount_11,0)
      ,NVL(ln_amount_12,0)
      ,NVL(ln_amount_1,0)
      ,NVL(ln_amount_2,0)
      ,NVL(ln_amount_3,0)
      ,NVL(ln_amount_4,0)
      ,NVL(ln_year_amount,0)
      );
      --2行目：売上
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_budget_name
      ,NVL(ROUND(ln_sale_budget_5/1000),0)
      ,NVL(ROUND(ln_sale_budget_6/1000),0)
      ,NVL(ROUND(ln_sale_budget_7/1000),0)
      ,NVL(ROUND(ln_sale_budget_8/1000),0)
      ,NVL(ROUND(ln_sale_budget_9/1000),0)
      ,NVL(ROUND(ln_sale_budget_10/1000),0)
      ,NVL(ROUND(ln_sale_budget_11/1000),0)
      ,NVL(ROUND(ln_sale_budget_12/1000),0)
      ,NVL(ROUND(ln_sale_budget_1/1000),0)
      ,NVL(ROUND(ln_sale_budget_2/1000),0)
      ,NVL(ROUND(ln_sale_budget_3/1000),0)
      ,NVL(ROUND(ln_sale_budget_4/1000),0)
      ,NVL(ROUND(ln_year_sale_budget/1000),0)
      );
      --3行目：粗利益額
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_margin_name
      ,NVL(ROUND(ln_margin_5/1000),0)
      ,NVL(ROUND(ln_margin_6/1000),0)
      ,NVL(ROUND(ln_margin_7/1000),0)
      ,NVL(ROUND(ln_margin_8/1000),0)
      ,NVL(ROUND(ln_margin_9/1000),0)
      ,NVL(ROUND(ln_margin_10/1000),0)
      ,NVL(ROUND(ln_margin_11/1000),0)
      ,NVL(ROUND(ln_margin_12/1000),0)
      ,NVL(ROUND(ln_margin_1/1000),0)
      ,NVL(ROUND(ln_margin_2/1000),0)
      ,NVL(ROUND(ln_margin_3/1000),0)
      ,NVL(ROUND(ln_margin_4/1000),0)
      ,NVL(ROUND(ln_year_margin/1000),0)
      );
      --4行目：掛率
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_credit_name
      ,NVL(ln_credit_5,0)
      ,NVL(ln_credit_6,0)
      ,NVL(ln_credit_7,0)
      ,NVL(ln_credit_8,0)
      ,NVL(ln_credit_9,0)
      ,NVL(ln_credit_10,0)
      ,NVL(ln_credit_11,0)
      ,NVL(ln_credit_12,0)
      ,NVL(ln_credit_1,0)
      ,NVL(ln_credit_2,0)
      ,NVL(ln_credit_3,0)
      ,NVL(ln_credit_4,0)
      ,NVL(ln_year_credit,0)
      );
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    END IF;
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--
--#################################  固定例外処理部  #############################
  EXCEPTION
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
--#####################################  固定部 END   ###########################
--
  END item_month_count;
--
  /****************************************************************************
  * Procedure Name   : reduce_price_count
  * Description      : 値引月別集計(A-14)
  *                  : 月別値引データ登録(A-15)
  ****************************************************************************/
  PROCEDURE reduce_price_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2で取得した拠点コード
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2で取得した拠点名称
      ,ov_errbuf        OUT NOCOPY VARCHAR2              --共通・エラー・メッセージ
      ,ov_retcode       OUT NOCOPY VARCHAR2              --リターン・コード
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             --ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'reduce_price_count'; -- プログラム名
--
--  ===============================
--  固定ローカル変数
--  ===============================
    ln_month_sales_discount       NUMBER;         --月別売上値引
    ln_month_receipt_discount     NUMBER;         --月別入金値引
    ln_month_no                   NUMBER;         --月
    ln_year_sales_discount        NUMBER;         --年間売上値引
    ln_year_receipt_discount      NUMBER;         --年間入金値引
    ln_sales_discount_5           NUMBER;         --5月売上値引
    ln_sales_discount_6           NUMBER;         --6月売上値引
    ln_sales_discount_7           NUMBER;         --7月売上値引
    ln_sales_discount_8           NUMBER;         --8月売上値引
    ln_sales_discount_9           NUMBER;         --9月売上値引
    ln_sales_discount_10          NUMBER;         --10月売上値引
    ln_sales_discount_11          NUMBER;         --11月売上値引
    ln_sales_discount_12          NUMBER;         --12月売上値引
    ln_sales_discount_1           NUMBER;         --1月売上値引
    ln_sales_discount_2           NUMBER;         --2月売上値引
    ln_sales_discount_3           NUMBER;         --3月売上値引
    ln_sales_discount_4           NUMBER;         --4月売上値引
    ln_receipt_discount_5         NUMBER;         --5月入金値引
    ln_receipt_discount_6         NUMBER;         --6月入金値引
    ln_receipt_discount_7         NUMBER;         --7月入金値引
    ln_receipt_discount_8         NUMBER;         --8月入金値引
    ln_receipt_discount_9         NUMBER;         --9月入金値引
    ln_receipt_discount_10        NUMBER;         --10月入金値引
    ln_receipt_discount_11        NUMBER;         --11月入金値引
    ln_receipt_discount_12        NUMBER;         --12月入金値引
    ln_receipt_discount_1         NUMBER;         --1月入金値引
    ln_receipt_discount_2         NUMBER;         --2月入金値引
    ln_receipt_discount_3         NUMBER;         --3月入金値引
    ln_receipt_discount_4         NUMBER;         --4月入金値引
--
--  ===============================
--  ローカル・カーソル
--  ===============================
    --値引月別データ抽出
    CURSOR   reduce_price_cur
    IS
      SELECT  xiplb.sales_discount                                   --売上値引
             ,xiplb.receipt_discount                                 --入金値引
             ,xiplb.month_no                                         --年月
      FROM    xxcsm_item_plan_loc_bdgt    xiplb                      -- 商品計画拠点別予算テーブル
             ,xxcsm_item_plan_headers     xiph                       -- 商品計画ヘッダテーブル
      WHERE   xiph.plan_year = gn_subject_year                       --対象年度
      AND     xiph.location_cd = iv_kyoten_cd                        --拠点コード
      AND     xiph.item_plan_header_id = xiplb.item_plan_header_id
    ;
    reduce_price_cur_rec reduce_price_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--ローカル変数初期化
    ln_month_sales_discount    := 0;              --月別売上値引
    ln_month_receipt_discount  := 0;              --月別入金値引
    ln_year_sales_discount     := 0;              --年間売上値引
    ln_year_receipt_discount   := 0;              --年間入金値引

    OPEN reduce_price_cur;
    <<reduce_price_loop>>
    LOOP
      FETCH reduce_price_cur INTO reduce_price_cur_rec;
      EXIT WHEN reduce_price_cur%NOTFOUND;
        ln_month_sales_discount     :=  reduce_price_cur_rec.sales_discount;                         --月別売上値引
        ln_month_receipt_discount   :=  reduce_price_cur_rec.receipt_discount;                       --月別入金値引
        ln_month_no                 :=  reduce_price_cur_rec.month_no;                               --月
        --値引年間データ算出
        ln_year_sales_discount      := ln_year_sales_discount + ln_month_sales_discount;              --年間売上値引
        ln_year_receipt_discount    := ln_year_receipt_discount + ln_month_receipt_discount;          --年間入金値引
        
        --各月データ保存
        IF    ln_month_no = 5 THEN
          ln_sales_discount_5        := ln_month_sales_discount;
          ln_receipt_discount_5      := ln_month_receipt_discount;
        ELSIF ln_month_no = 6 THEN
          ln_sales_discount_6        := ln_month_sales_discount;
          ln_receipt_discount_6      := ln_month_receipt_discount;
        ELSIF ln_month_no = 7 THEN
          ln_sales_discount_7        := ln_month_sales_discount;
          ln_receipt_discount_7      := ln_month_receipt_discount;
        ELSIF ln_month_no = 8 THEN
          ln_sales_discount_8        := ln_month_sales_discount;
          ln_receipt_discount_8      := ln_month_receipt_discount;
        ELSIF ln_month_no = 9 THEN
          ln_sales_discount_9        := ln_month_sales_discount;
          ln_receipt_discount_9      := ln_month_receipt_discount;
        ELSIF ln_month_no = 10 THEN
          ln_sales_discount_10        := ln_month_sales_discount;
          ln_receipt_discount_10      := ln_month_receipt_discount;
        ELSIF ln_month_no = 11 THEN
          ln_sales_discount_11        := ln_month_sales_discount;
          ln_receipt_discount_11      := ln_month_receipt_discount;
        ELSIF ln_month_no = 12 THEN
          ln_sales_discount_12        := ln_month_sales_discount;
          ln_receipt_discount_12      := ln_month_receipt_discount;
        ELSIF ln_month_no = 1 THEN
          ln_sales_discount_1        := ln_month_sales_discount;
          ln_receipt_discount_1      := ln_month_receipt_discount;
        ELSIF ln_month_no = 2 THEN
          ln_sales_discount_2        := ln_month_sales_discount;
          ln_receipt_discount_2      := ln_month_receipt_discount;
        ELSIF ln_month_no = 3 THEN
          ln_sales_discount_3        := ln_month_sales_discount;
          ln_receipt_discount_3      := ln_month_receipt_discount;
        ELSIF ln_month_no = 4 THEN
          ln_sales_discount_4        := ln_month_sales_discount;
          ln_receipt_discount_4      := ln_month_receipt_discount;
        END IF;
    END LOOP reduce_price_loop;
    CLOSE reduce_price_cur;
--
    --月別売上値引データ登録
    --1行目：数量
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_sales_dis_name
    ,gv_amount_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    --2行目：売上
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_sales_discount_5/1000),0)
    ,NVL(ROUND(ln_sales_discount_6/1000),0)
    ,NVL(ROUND(ln_sales_discount_7/1000),0)
    ,NVL(ROUND(ln_sales_discount_8/1000),0)
    ,NVL(ROUND(ln_sales_discount_9/1000),0)
    ,NVL(ROUND(ln_sales_discount_10/1000),0)
    ,NVL(ROUND(ln_sales_discount_11/1000),0)
    ,NVL(ROUND(ln_sales_discount_12/1000),0)
    ,NVL(ROUND(ln_sales_discount_1/1000),0)
    ,NVL(ROUND(ln_sales_discount_2/1000),0)
    ,NVL(ROUND(ln_sales_discount_3/1000),0)
    ,NVL(ROUND(ln_sales_discount_4/1000),0)
    ,NVL(ROUND(ln_year_sales_discount/1000),0)
    );
    --3行目：粗利益額
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_sales_discount_5/1000),0)
    ,NVL(ROUND(ln_sales_discount_6/1000),0)
    ,NVL(ROUND(ln_sales_discount_7/1000),0)
    ,NVL(ROUND(ln_sales_discount_8/1000),0)
    ,NVL(ROUND(ln_sales_discount_9/1000),0)
    ,NVL(ROUND(ln_sales_discount_10/1000),0)
    ,NVL(ROUND(ln_sales_discount_11/1000),0)
    ,NVL(ROUND(ln_sales_discount_12/1000),0)
    ,NVL(ROUND(ln_sales_discount_1/1000),0)
    ,NVL(ROUND(ln_sales_discount_2/1000),0)
    ,NVL(ROUND(ln_sales_discount_3/1000),0)
    ,NVL(ROUND(ln_sales_discount_4/1000),0)
    ,NVL(ROUND(ln_year_sales_discount/1000),0)
    );
    --4行目：掛率
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    --月別入金値引データ登録
    --1行目：数量
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_receipt_dis_name
    ,gv_amount_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    --2行目：売上
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_receipt_discount_5/1000),0)
    ,NVL(ROUND(ln_receipt_discount_6/1000),0)
    ,NVL(ROUND(ln_receipt_discount_7/1000),0)
    ,NVL(ROUND(ln_receipt_discount_8/1000),0)
    ,NVL(ROUND(ln_receipt_discount_9/1000),0)
    ,NVL(ROUND(ln_receipt_discount_10/1000),0)
    ,NVL(ROUND(ln_receipt_discount_11/1000),0)
    ,NVL(ROUND(ln_receipt_discount_12/1000),0)
    ,NVL(ROUND(ln_receipt_discount_1/1000),0)
    ,NVL(ROUND(ln_receipt_discount_2/1000),0)
    ,NVL(ROUND(ln_receipt_discount_3/1000),0)
    ,NVL(ROUND(ln_receipt_discount_4/1000),0)
    ,NVL(ROUND(ln_year_receipt_discount/1000),0)
    );
    --3行目：粗利益額
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_receipt_discount_5/1000),0)
    ,NVL(ROUND(ln_receipt_discount_6/1000),0)
    ,NVL(ROUND(ln_receipt_discount_7/1000),0)
    ,NVL(ROUND(ln_receipt_discount_8/1000),0)
    ,NVL(ROUND(ln_receipt_discount_9/1000),0)
    ,NVL(ROUND(ln_receipt_discount_10/1000),0)
    ,NVL(ROUND(ln_receipt_discount_11/1000),0)
    ,NVL(ROUND(ln_receipt_discount_12/1000),0)
    ,NVL(ROUND(ln_receipt_discount_1/1000),0)
    ,NVL(ROUND(ln_receipt_discount_2/1000),0)
    ,NVL(ROUND(ln_receipt_discount_3/1000),0)
    ,NVL(ROUND(ln_receipt_discount_4/1000),0)
    ,NVL(ROUND(ln_year_receipt_discount/1000),0)
    );
    --4行目：掛率
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    
--
--#################################  固定例外処理部  #############################
  EXCEPTION
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
--#####################################  固定部 END   ###########################
--
  END reduce_price_count;
--
  /****************************************************************************
  * Procedure Name   : kyoten_month_count
  * Description      : 拠点別月別集計(A-16)
  *                  : 月別拠点別データ、H基準登録(A-17)
  ****************************************************************************/
  PROCEDURE kyoten_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2で取得した拠点コード
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2で取得した拠点名称
      ,ov_errbuf        OUT NOCOPY VARCHAR2              --共通・エラー・メッセージ
      ,ov_retcode       OUT NOCOPY VARCHAR2              --リターン・コード
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             --ユーザー・エラー・メッセージ
  IS
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'kyoten_month_count'; -- プログラム名
--  ===============================
--  固定ローカル変数
--  ===============================
    ln_month_sale_budget       NUMBER;         --月別拠点別売上
    ln_month_amount            NUMBER;         --月別拠点別数量
    ln_month_sub_margin        NUMBER;         --月別拠点別粗利益減数
    ln_month_h_standard        NUMBER;         --月別拠点別H基準算出用データ
    ln_year_month              NUMBER;         --年月
    ln_month_margin            NUMBER;         --月別拠点別粗利益額
    ln_month_credit_bunbo      NUMBER;         --月別拠点別掛率分母
    ln_month_credit            NUMBER;         --月別拠点別掛率
    ln_year_sale_budget        NUMBER;         --年間拠点別売上
    ln_year_amount             NUMBER;         --年間拠点別数量
    ln_year_margin             NUMBER;         --年間拠点別粗利益額
    ln_year_credit_bunbo       NUMBER;         --年間拠点別掛率分母
    ln_year_credit             NUMBER;         --年間拠点別掛率
    ln_year_h_standard         NUMBER;         --年間拠点別H基準算出用減数
    ln_cost                    NUMBER;         --営業原価
    ln_price                   NUMBER;         --定価
    ln_sale_budget_5           NUMBER;         --5月売上
    ln_sale_budget_6           NUMBER;         --6月売上
    ln_sale_budget_7           NUMBER;         --7月売上
    ln_sale_budget_8           NUMBER;         --8月売上
    ln_sale_budget_9           NUMBER;         --9月売上
    ln_sale_budget_10          NUMBER;         --10月売上
    ln_sale_budget_11          NUMBER;         --11月売上
    ln_sale_budget_12          NUMBER;         --12月売上
    ln_sale_budget_1           NUMBER;         --1月売上
    ln_sale_budget_2           NUMBER;         --2月売上
    ln_sale_budget_3           NUMBER;         --3月売上
    ln_sale_budget_4           NUMBER;         --4月売上
    ln_amount_5                NUMBER;         --5月数量
    ln_amount_6                NUMBER;         --6月数量
    ln_amount_7                NUMBER;         --7月数量
    ln_amount_8                NUMBER;         --8月数量
    ln_amount_9                NUMBER;         --9月数量
    ln_amount_10               NUMBER;         --10月数量
    ln_amount_11               NUMBER;         --11月数量
    ln_amount_12               NUMBER;         --12月数量
    ln_amount_1                NUMBER;         --1月数量
    ln_amount_2                NUMBER;         --2月数量
    ln_amount_3                NUMBER;         --3月数量
    ln_amount_4                NUMBER;         --4月数量
    ln_margin_5                NUMBER;         --5月粗利益額
    ln_margin_6                NUMBER;         --6月粗利益額
    ln_margin_7                NUMBER;         --7月粗利益額
    ln_margin_8                NUMBER;         --8月粗利益額
    ln_margin_9                NUMBER;         --9月粗利益額
    ln_margin_10               NUMBER;         --10月粗利益額
    ln_margin_11               NUMBER;         --11月粗利益額
    ln_margin_12               NUMBER;         --12月粗利益額
    ln_margin_1                NUMBER;         --1月粗利益額
    ln_margin_2                NUMBER;         --2月粗利益額
    ln_margin_3                NUMBER;         --3月粗利益額
    ln_margin_4                NUMBER;         --4月粗利益額
    ln_credit_5                NUMBER;         --5月掛率
    ln_credit_6                NUMBER;         --6月掛率
    ln_credit_7                NUMBER;         --7月掛率
    ln_credit_8                NUMBER;         --8月掛率
    ln_credit_9                NUMBER;         --9月掛率
    ln_credit_10               NUMBER;         --10月掛率
    ln_credit_11               NUMBER;         --11月掛率
    ln_credit_12               NUMBER;         --12月掛率
    ln_credit_1                NUMBER;         --1月掛率
    ln_credit_2                NUMBER;         --2月掛率
    ln_credit_3                NUMBER;         --3月掛率
    ln_credit_4                NUMBER;         --4月掛率
    ln_h_standard              NUMBER;         --H基準
    ln_month_no                NUMBER;         --月
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
    ln_discount                NUMBER;         --値引額
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--
--  ===============================
--  ローカル・カーソル
--  ===============================
    --拠点別月別データ抽出
    CURSOR   kyoten_month_cur
    IS
--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT  SUM(xipl.sales_budget)  sales_budget_sum               --売上金額
--             ,SUM(xipl.amount)        amount_sum                     --数量
--             ,SUM(xipl.amount * xcgv.now_business_cost)  sub_margin  --粗利益減数
--             ,SUM(xipl.amount * xcgv.now_unit_price)  credit_bunbo   --掛率分母
--             ,SUM(xipl.amount * xcgv.now_item_cost) h_standard       --H基準算出用減数
--             ,xipl.year_month                                        --年月
----//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
--             ,xiph.item_plan_header_id              haeder_id        --ヘッダID
----//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--      FROM    xxcsm_item_plan_lines       xipl                       --商品計画明細テーブル
--             ,xxcsm_item_plan_headers     xiph                       --商品計画ヘッダテーブル
--             ,xxcsm_commodity_group3_v    xcgv                       --政策群コード３ビュー
--      WHERE   xiph.plan_year = gn_subject_year                       --対象年度
--      AND     xiph.location_cd = iv_kyoten_cd                        --拠点コード
--      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
----//+UPD START 2009/02/13 CT015 S.Son
--    --AND     xipl.item_kbn = '1'                                    --商品区分(1：商品単品)
--      AND     xipl.item_kbn <> '0'                                   --商品区分(1：商品単品、2：新商品)
----//+UPD END 2009/02/13 CT015 S.Son
--      AND     xipl.item_no = xcgv.item_cd
--      GROUP BY xipl.year_month
----//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
--             ,xiph.item_plan_header_id
----//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--      ORDER BY xipl.year_month
--    ;
--
      SELECT  sub.year_month                          year_month       --年月
             ,SUM(sub.sales_budget)                   sales_budget_sum --売上金額
             ,SUM(sub.amount)                         amount_sum       --数量
             ,SUM(sub.amount * sub.now_business_cost) sub_margin       --粗利益減数
             ,SUM(sub.amount * sub.now_unit_price)    credit_bunbo     --掛率分母
             ,SUM(sub.amount * sub.now_item_cost)     h_standard       --H基準算出用減数
             ,sub.item_plan_header_id                 header_id        --ヘッダID
      FROM   (
              SELECT 
                  xipl.year_month                     year_month
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL( 
--                        ( 
--                          SELECT SUM(ccmd.cmpnt_cost)
--                          FROM   cm_cmpt_dtl     ccmd
--                                ,cm_cldr_dtl     ccld
--                          WHERE  ccmd.calendar_code = ccld.calendar_code
--                          AND    ccmd.whse_code     = cv_whse_code
--                          AND    ccmd.period_code   = ccld.period_code
--                          AND    ccld.start_date   <= gd_process_date
--                          AND    ccld.end_date     >= gd_process_date
--                          AND    ccmd.item_id       = iimb.item_id
--                        )
--                    , 0
--                  )                                   now_item_cost
                  --
                  -- 標準原価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(
                            (
                              SELECT SUM(ccmd.cmpnt_cost)
                              FROM   cm_cmpt_dtl     ccmd
                                    ,cm_cldr_dtl     ccld
                              WHERE  ccmd.calendar_code = ccld.calendar_code
                              AND    ccmd.whse_code     = cv_whse_code
                              AND    ccmd.period_code   = ccld.period_code
                              AND    ccld.start_date   <= gd_process_date
                              AND    ccld.end_date     >= gd_process_date
                              AND    ccmd.item_id       = iimb.item_id
                            )
                        , 0
                      )
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              SELECT SUM(ccmd.cmpnt_cost)
                              FROM   cm_cmpt_dtl     ccmd
                                    ,cm_cldr_dtl     ccld
                              WHERE  ccmd.calendar_code = ccld.calendar_code
                              AND    ccmd.whse_code     = cv_whse_code
                              AND    ccmd.period_code   = ccld.period_code
                              AND    ccld.start_date   <= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                              AND    ccld.end_date     >= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                              AND    ccmd.item_id       = iimb.item_id
                            )
                        , 0
                      )
                  END                                 now_item_cost
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                  --
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute8, 0)             now_business_cost
                  --
                  -- 営業原価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute8, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の営業原価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- 営業原価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴テーブル
                              WHERE   xsibh.item_hst_id   =
                                (
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.discrete_cost  IS NOT NULL             -- 営業原価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_business_cost
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                  --
                  --//+UPD START E_本稼動_09949 K.Taniguchi
--                , NVL(iimb.attribute5, 0)             now_unit_price
                  --
                  -- 定価
                  -- パラメータ：新旧原価区分
                , CASE gv_new_old_cost_class
                    --
                    -- 10：新原価 選択時
                    WHEN cv_new_cost THEN
                      NVL(iimb.attribute5, 0)
                    --
                    -- 20：旧原価 選択時
                    WHEN cv_old_cost THEN
                      NVL(
                            (
                              -- 前年度の定価を品目変更履歴から取得
                              SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- 定価
                              FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                              WHERE   xsibh.item_hst_id   =
                                (
                                  -- 前年度の品目変更履歴ID
                                  SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                  FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                  WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                  AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                  AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                  AND     xsibh2.fixed_price    IS NOT NULL             -- 定価 IS NOT NULL
                                )
                            )
                        , 0
                      )
                  END                                 now_unit_price    -- 定価
                  --//+UPD END E_本稼動_09949 K.Taniguchi
                , xipl.amount                         amount
                , xipl.sales_budget                   sales_budget
                , xiph.item_plan_header_id            item_plan_header_id
              FROM    mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , mtl_categories_tl           mct
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_lines       xipl
                    , xxcsm_item_plan_headers     xiph
              WHERE   mcsb2.structure_id                        =   mcb2.structure_id
              AND     mcb2.enabled_flag                         =   cv_flg_y
              AND     NVL(mcb2.disable_date, gd_process_date)   <=  gd_process_date
              AND     fifs2.id_flex_structure_code              =   cv_sgun_code
              AND     fifs2.application_id                      =   cn_appl_id
              AND     fifs2.id_flex_code                        =   cv_mcat
              AND     fifs2.id_flex_num                         =   mcsb2.structure_id
              AND     gic.category_id                           =   mcb2.category_id
              AND     gic.category_set_id                       =   mcsb2.category_set_id
              AND     gic.item_id                               =   iimb.item_id
              AND     iimb.item_id                              =   xsib.item_id
              AND     xsib.item_status                          =   cv_item_status_30
              AND     mcb2.category_id                          =   mct.category_id
              AND     mct.language                              =   cv_ja
              AND     xiph.plan_year = gn_subject_year                         --対象年度
              AND     xiph.location_cd = iv_kyoten_cd                          --拠点コード
              AND     xiph.item_plan_header_id = xipl.item_plan_header_id
              AND     xipl.item_kbn <> cv_item_kbn                             --商品区分(1：商品単品、2：新商品)
              AND     xipl.item_no = iimb.item_no
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)             =   SUBSTRB(mcb2.segment1, 1, 1)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)            =   SUBSTRB(mcb2.segment1, 1, 1)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                    )
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   4
                        AND     SUBSTRB(mcb.segment1, 1, 3)             =   SUBSTRB(mcb2.segment1, 1, 3)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   4
                        AND     SUBSTRB(flv.lookup_code, 1, 3)            =   SUBSTRB(mcb2.segment1, 1, 3)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                  )
        ) sub
      GROUP BY year_month
              ,item_plan_header_id
      ORDER BY year_month
      ;
--//+UPD END 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
    kyoten_month_cur_rec kyoten_month_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--ローカル変数初期化
    ln_month_sale_budget    := 0;              --月別拠点別売上
    ln_month_amount         := 0;              --月別拠点別数量
    ln_month_margin         := 0;              --月別拠点別粗利益額
    ln_month_credit_bunbo   := 0;              --月別拠点別掛率分母
    ln_month_credit         := 0;              --月別拠点別掛率
    ln_month_sub_margin     := 0;              --月別拠点別粗利益減数
    ln_month_h_standard     := 0;
    ln_year_amount          := 0;              --年間拠点別数量
    ln_year_sale_budget     := 0;              --年間拠点別売上
    ln_year_margin          := 0;              --年間拠点別粗利益額
    ln_year_credit_bunbo    := 0;              --年間拠点別掛率分母
    ln_year_credit          := 0;              --年間拠点別掛率
    ln_year_h_standard      := 0;
    ln_h_standard           := 0;              --H基準
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
    ln_discount             := 0;              --値引額
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--
    OPEN kyoten_month_cur;
    <<kyoten_month_loop>>
    LOOP
      FETCH kyoten_month_cur INTO kyoten_month_cur_rec;
      EXIT WHEN kyoten_month_cur%NOTFOUND;
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
        SELECT (xiplb.sales_discount + xiplb.receipt_discount)  discount                            --(売上値引 + 入金値引)
        INTO   ln_discount
        FROM   xxcsm_item_plan_loc_bdgt    xiplb                                                    -- 商品計画拠点別予算テーブル
--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
--        WHERE  xiplb.item_plan_header_id  = kyoten_month_cur_rec.haeder_id                          -- ヘッダID
        WHERE  xiplb.item_plan_header_id  = kyoten_month_cur_rec.header_id                          -- ヘッダID
--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
        AND    xiplb.year_month           = kyoten_month_cur_rec.year_month;                        -- 年月
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--//+UPD START 2009/05/21 T1_1101 M.Ohtsuki
--        ln_month_sale_budget    :=  kyoten_month_cur_rec.sales_budget_sum;                          --月別拠点合計売上
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
        ln_month_sale_budget    :=  (kyoten_month_cur_rec.sales_budget_sum + ln_discount);          --月別拠点合計売上
--//+UPD END   2009/05/21 T1_1101 M.Ohtsuki
        ln_month_amount         :=  kyoten_month_cur_rec.amount_sum;                                --月別拠点合計数量
        ln_month_sub_margin     :=  kyoten_month_cur_rec.sub_margin;
        ln_month_credit_bunbo   :=  kyoten_month_cur_rec.credit_bunbo;
        ln_month_h_standard     :=  kyoten_month_cur_rec.h_standard;
        ln_year_month           :=  kyoten_month_cur_rec.year_month;                                --年月
        --拠点合計月別データ算出
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --月別拠点合計粗利益額
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --月別拠点合計掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --年間拠点合計売上
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --年間拠点合計数量
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --年間拠点合計粗利益額
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --年間拠点合計掛率分母
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit          := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --年間拠点合計掛率
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_h_standard      := ln_year_h_standard + ln_month_h_standard;                        --H基準算出用年間減数
        
        --各月データ保存
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP kyoten_month_loop;
    CLOSE kyoten_month_cur;
--
    --H基準の算出
    ln_h_standard := ln_year_sale_budget - ln_year_h_standard;
    --月別拠点別データ登録
    --1行目：数量
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,gv_amount_name
    ,NVL(ln_amount_5,0)
    ,NVL(ln_amount_6,0)
    ,NVL(ln_amount_7,0)
    ,NVL(ln_amount_8,0)
    ,NVL(ln_amount_9,0)
    ,NVL(ln_amount_10,0)
    ,NVL(ln_amount_11,0)
    ,NVL(ln_amount_12,0)
    ,NVL(ln_amount_1,0)
    ,NVL(ln_amount_2,0)
    ,NVL(ln_amount_3,0)
    ,NVL(ln_amount_4,0)
    ,NVL(ln_year_amount,0)
    );
    --2行目：売上
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_sale_budget_5/1000),0)
    ,NVL(ROUND(ln_sale_budget_6/1000),0)
    ,NVL(ROUND(ln_sale_budget_7/1000),0)
    ,NVL(ROUND(ln_sale_budget_8/1000),0)
    ,NVL(ROUND(ln_sale_budget_9/1000),0)
    ,NVL(ROUND(ln_sale_budget_10/1000),0)
    ,NVL(ROUND(ln_sale_budget_11/1000),0)
    ,NVL(ROUND(ln_sale_budget_12/1000),0)
    ,NVL(ROUND(ln_sale_budget_1/1000),0)
    ,NVL(ROUND(ln_sale_budget_2/1000),0)
    ,NVL(ROUND(ln_sale_budget_3/1000),0)
    ,NVL(ROUND(ln_sale_budget_4/1000),0)
    ,NVL(ROUND(ln_year_sale_budget/1000),0)
    );
    --3行目：粗利益額
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_margin_5/1000),0)
    ,NVL(ROUND(ln_margin_6/1000),0)
    ,NVL(ROUND(ln_margin_7/1000),0)
    ,NVL(ROUND(ln_margin_8/1000),0)
    ,NVL(ROUND(ln_margin_9/1000),0)
    ,NVL(ROUND(ln_margin_10/1000),0)
    ,NVL(ROUND(ln_margin_11/1000),0)
    ,NVL(ROUND(ln_margin_12/1000),0)
    ,NVL(ROUND(ln_margin_1/1000),0)
    ,NVL(ROUND(ln_margin_2/1000),0)
    ,NVL(ROUND(ln_margin_3/1000),0)
    ,NVL(ROUND(ln_margin_4/1000),0)
    ,NVL(ROUND(ln_year_margin/1000),0)
    );
    --4行目：掛率
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,ln_credit_5
    ,ln_credit_6
    ,ln_credit_7
    ,ln_credit_8
    ,ln_credit_9
    ,ln_credit_10
    ,ln_credit_11
    ,ln_credit_12
    ,ln_credit_1
    ,ln_credit_2
    ,ln_credit_3
    ,ln_credit_4
    ,ln_year_credit
    );
    --H基準の登録
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_h_standard_name
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,ROUND(ln_h_standard/1000)
    );
--
--#################################  固定例外処理部  #############################
  EXCEPTION
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
--#####################################  固定部 END   ###########################
--
  END kyoten_month_count;
--
  /****************************************************************************
  * Procedure Name   : item_plan_select
  * Description      : 商品計画データ抽出(A-5)
  ****************************************************************************/
  PROCEDURE item_plan_select (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2で取得した拠点コード
      ,iv_kyoten_nm     IN  VARCHAR2
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'item_plan_select'; -- プログラム名
--
--  ===============================
--  固定ローカル変数
--  ===============================
    lv_group1_cd                  VARCHAR2(4);         --政策群コード1
    lv_group1_nm                  VARCHAR2(100);       --政策群名称1
    lv_group3_cd                  VARCHAR2(4);         --政策群コード
    lv_group3_nm                  VARCHAR2(100);       --政策群名称3
    lv_item_cd                    VARCHAR2(32);        --品目コード
    lv_item_nm                    VARCHAR2(100);       --品目名称
    ln_base_price                 NUMBER;              --標準原価
    ln_bus_price                  NUMBER;              --営業原価
    ln_con_price                  NUMBER;              --定価
    ln_sales_budget_sum           NUMBER;              --売上金額
    ln_amount_sum                 NUMBER;              --数量
    ln_kyoten_h_standard_you      NUMBER;              --拠点別H基準算出用データ
    ln_item_h_standard_you        NUMBER;              --商品別H基準算出用データ
    lv_group3_cd_pre              VARCHAR2(4);         --保存用政策群コード3
    lv_group1_cd_pre              VARCHAR2(4);         --保存用政策群コード1
    lv_group3_nm_pre              VARCHAR2(100);       --保存用政策群名3
    lv_group1_nm_pre              VARCHAR2(100);       --保存用政策群名1
    lv_kyoten_cd                  VARCHAR2(4);         --A-2で取得した拠点コード
    lv_kyoten_nm                  VARCHAR2(100);       --A-2で取得した拠点名
--
--  ===============================
--  ローカル・カーソル
--  ===============================
    CURSOR   item_plan_select_cur
    IS
--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT  xcgv.group1_cd                             --政策群コード1
--             ,xcgv.group1_nm                             --政策群名称1
--             ,xcgv.group3_cd                             --政策群コード3
--             ,xcgv.group3_nm                             --政策群名称3
--             ,xcgv.item_cd                               --品目コード
--             ,xcgv.item_nm                               --品目名称
--             ,xcgv.now_item_cost                         --標準原価
--             ,xcgv.now_business_cost                     --営業原価
--             ,xcgv.now_unit_price                        --定価
--             ,SUM(xipl.sales_budget)  sales_budget_sum   --売上金額
--             ,SUM(xipl.amount)        amount_sum         --数量
--      FROM    xxcsm_commodity_group3_v    xcgv           --政策群3ビュー
--             ,xxcsm_item_plan_lines       xipl           -- 商品計画明細テーブル
--             ,xxcsm_item_plan_headers     xiph           -- 商品計画ヘッダテーブル
--      WHERE   xiph.plan_year = gn_subject_year           --対象年度
--      AND     xiph.location_cd = iv_kyoten_cd            --拠点コード
--      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
----//+UPD START 2009/02/13 CT015 S.Son
--    --AND     xipl.item_kbn = '1'                        --商品区分(1：商品単品)
--      AND     xipl.item_kbn <> '0'                       --商品区分(1：商品単品、2：新商品)
----//+UPD END 2009/02/13 CT015 S.Son
--      AND     xipl.item_no = xcgv.item_cd
--      GROUP BY   xcgv.group1_cd 
--                ,xcgv.group1_nm 
--                ,xcgv.group3_cd 
--                ,xcgv.group3_nm 
--                ,xcgv.item_cd   
--                ,xcgv.item_nm   
--                ,xcgv.now_item_cost
--                ,xcgv.now_business_cost 
--                ,xcgv.now_unit_price 
--      ORDER BY   xcgv.group1_cd
--                ,xcgv.group3_cd
--                ,xcgv.item_cd
--    ;
--
      SELECT  sub.group1_cd          group1_cd            -- 政策群コード1
             ,sub.group1_nm          group1_nm            -- 政策群名称1
             ,sub.group3_cd          group3_cd            -- 政策群コード3
             ,sub.group3_nm          group3_nm            -- 政策群名称3
             ,sub.item_cd            item_cd              -- 品目コード
             ,sub.item_nm            item_nm              -- 品目名称
             ,sub.now_item_cost      now_item_cost        -- 標準原価
             ,sub.now_business_cost  now_business_cost    -- 営業原価
             ,sub.now_unit_price     now_unit_price       -- 定価
             ,SUM(sub.sales_budget)  sales_budget_sum     -- 売上金額
             ,SUM(sub.amount)        amount_sum           -- 数量
      FROM (
              SELECT
                      iimb.item_no                    AS  item_cd  -- "品目コード"
                    , iimb.item_desc1                 AS  item_nm  -- "品名"
                    , SUBSTRB(mcb2.segment1, 1, 1)    AS  group1_cd -- "１桁群"
                    , ( SELECT  mct_g1.description    description
                        FROM    mtl_categories_b      mcb_g1
                              , mtl_categories_tl     mct_g1
                        WHERE   mcb_g1.category_id    = mct_g1.category_id
                        AND     mct_g1.language       = cv_ja
                        AND     mcb_g1.segment1       = SUBSTRB(mcb2.segment1, 1, 1)  ||  cv_group_1
                        UNION
                        SELECT  flv.meaning           description
                        FROM    fnd_lookup_values     flv
                        WHERE   flv.lookup_type       =   cv_item_group
                        AND     flv.language          =   cv_ja
                        AND     flv.enabled_flag      =   cv_flg_y
                        AND     flv.lookup_code       =   SUBSTRB(mcb2.segment1, 1, 1)  ||  cv_group_1
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                      )                                             AS  group1_nm -- １桁群（名称）
                    , SUBSTRB(mcb2.segment1, 1, 3)  ||  cv_group_3  AS  group3_cd -- "３桁群"
                    , ( SELECT  mct_g3.description    description
                        FROM    mtl_categories_b      mcb_g3
                              , mtl_categories_tl     mct_g3
                        WHERE   mcb_g3.category_id    = mct_g3.category_id
                        AND     mct_g3.language       = cv_ja
                        AND     mcb_g3.segment1       = SUBSTRB(mcb2.segment1, 1, 3)  ||  cv_group_3
                        UNION
                        SELECT  flv.meaning           description
                        FROM    fnd_lookup_values     flv
                        WHERE   flv.lookup_type       =   cv_item_group
                        AND     flv.language          =   cv_ja
                        AND     flv.enabled_flag      =   cv_flg_y
                        AND     flv.lookup_code       =   SUBSTRB(mcb2.segment1, 1, 3)  ||  cv_group_3
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                      )                                             AS  group3_nm  --"３桁群（名称）"
                      --//+UPD START E_本稼動_09949 K.Taniguchi
--                    , NVL( 
--                            ( 
--                              SELECT SUM(ccmd.cmpnt_cost)
--                              FROM   cm_cmpt_dtl     ccmd
--                                    ,cm_cldr_dtl     ccld
--                              WHERE  ccmd.calendar_code = ccld.calendar_code
--                              AND    ccmd.whse_code     = cv_whse_code
--                              AND    ccmd.period_code   = ccld.period_code
--                              AND    ccld.start_date   <= gd_process_date
--                              AND    ccld.end_date     >= gd_process_date
--                              AND    ccmd.item_id       = iimb.item_id
--                            )
--                        , NVL(iimb.attribute8, 0)
--                      )                                             now_item_cost     -- 標準原価
                      --
                      -- 標準原価
                      -- パラメータ：新旧原価区分
                    , CASE gv_new_old_cost_class
                        --
                        -- 10：新原価 選択時
                        WHEN cv_new_cost THEN
                          NVL(
                                (
                                  SELECT SUM(ccmd.cmpnt_cost)
                                  FROM   cm_cmpt_dtl     ccmd
                                        ,cm_cldr_dtl     ccld
                                  WHERE  ccmd.calendar_code = ccld.calendar_code
                                  AND    ccmd.whse_code     = cv_whse_code
                                  AND    ccmd.period_code   = ccld.period_code
                                  AND    ccld.start_date   <= gd_process_date
                                  AND    ccld.end_date     >= gd_process_date
                                  AND    ccmd.item_id       = iimb.item_id
                                )
                            , NVL(iimb.attribute8, 0)
                          )
                        --
                        -- 20：旧原価 選択時
                        WHEN cv_old_cost THEN
                          NVL(
                                (
                                  SELECT SUM(ccmd.cmpnt_cost)
                                  FROM   cm_cmpt_dtl     ccmd
                                        ,cm_cldr_dtl     ccld
                                  WHERE  ccmd.calendar_code = ccld.calendar_code
                                  AND    ccmd.whse_code     = cv_whse_code
                                  AND    ccmd.period_code   = ccld.period_code
                                  AND    ccld.start_date   <= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                                  AND    ccld.end_date     >= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                                  AND    ccmd.item_id       = iimb.item_id
                                )
                            , 0
                          )
                      END                                           now_item_cost     -- 標準原価
                      --//+UPD END E_本稼動_09949 K.Taniguchi
                      --
                      --//+UPD START E_本稼動_09949 K.Taniguchi
--                    , NVL(iimb.attribute8, 0)                       now_business_cost -- 営業原価
                      --
                      -- 営業原価
                      -- パラメータ：新旧原価区分
                    , CASE gv_new_old_cost_class
                        --
                        -- 10：新原価 選択時
                        WHEN cv_new_cost THEN
                          NVL(iimb.attribute8, 0)
                        --
                        -- 20：旧原価 選択時
                        WHEN cv_old_cost THEN
                          NVL(
                                (
                                  -- 前年度の営業原価を品目変更履歴から取得
                                  SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- 営業原価
                                  FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                                  WHERE   xsibh.item_hst_id   =
                                    (
                                      -- 前年度の品目変更履歴ID
                                      SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                      FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                      WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                      AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                      AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                      AND     xsibh2.discrete_cost  IS NOT NULL             -- 営業原価 IS NOT NULL
                                    )
                                )
                            , 0
                          )
                      END                                           now_business_cost -- 営業原価
                      --//+UPD END E_本稼動_09949 K.Taniguchi
                      --
                      --//+UPD START E_本稼動_09949 K.Taniguchi
--                    , NVL(iimb.attribute5, 0)                       now_unit_price    -- 定価
                      --
                      -- 定価
                      -- パラメータ：新旧原価区分
                    , CASE gv_new_old_cost_class
                        --
                        -- 10：新原価 選択時
                        WHEN cv_new_cost THEN
                          NVL(iimb.attribute5, 0)
                        --
                        -- 20：旧原価 選択時
                        WHEN cv_old_cost THEN
                          NVL(
                                (
                                  -- 前年度の定価を品目変更履歴から取得
                                  SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- 定価
                                  FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                                  WHERE   xsibh.item_hst_id   =
                                    (
                                      -- 前年度の品目変更履歴ID
                                      SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                      FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                      WHERE   xsibh2.item_code      =  iimb.item_no         -- 品目コード
                                      AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                      AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                      AND     xsibh2.fixed_price    IS NOT NULL             -- 定価 IS NOT NULL
                                    )
                                )
                            , 0
                          )
                      END                                           now_unit_price    -- 定価
                      --//+UPD END E_本稼動_09949 K.Taniguchi                    
                    , xipl.amount                                   amount            -- 数量
                    , xipl.sales_budget                             sales_budget      -- 売上原価
                    , mcb2.segment1                                 AS  "４桁群"
                    , mct.description                               AS  "４桁群（名称）"
              FROM    mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , mtl_categories_tl           mct
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_lines       xipl           -- 商品計画明細テーブル
                    , xxcsm_item_plan_headers     xiph           -- 商品計画ヘッダテーブル
              WHERE   mcsb2.structure_id                        =   mcb2.structure_id
              AND     mcb2.enabled_flag                         =   cv_flg_y
              AND     NVL(mcb2.disable_date, gd_process_date)   <=  gd_process_date
              AND     fifs2.id_flex_structure_code              =   cv_sgun_code
              AND     fifs2.application_id                      =   cn_appl_id
              AND     fifs2.id_flex_code                        =   cv_mcat
              AND     fifs2.id_flex_num                         =   mcsb2.structure_id
              AND     gic.category_id                           =   mcb2.category_id
              AND     gic.category_set_id                       =   mcsb2.category_set_id
              AND     gic.item_id                               =   iimb.item_id
              AND     iimb.item_id                              =   xsib.item_id
              AND     xsib.item_status                          =   cv_item_status_30
              AND     mcb2.category_id                          =   mct.category_id
              AND     mct.language                              =   cv_ja
              AND     xiph.plan_year                            =   gn_subject_year       --対象年度
              AND     xiph.location_cd                          = iv_kyoten_cd            --拠点コード
              AND     xiph.item_plan_header_id = xipl.item_plan_header_id
              AND     xipl.item_kbn <> cv_item_kbn                       --商品区分(1：商品単品、2：新商品)
              AND     xipl.item_no = iimb.item_no
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)             =   SUBSTRB(mcb2.segment1, 1, 1)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)            =   SUBSTRB(mcb2.segment1, 1, 1)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                    )
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id                       =   mcb.structure_id
                        AND     mcb.enabled_flag                        =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date)  <=  gd_process_date
                        AND     fifs.id_flex_structure_code             =   cv_sgun_code
                        AND     fifs.application_id                     =   cn_appl_id
                        AND     fifs.id_flex_code                       =   cv_mcat
                        AND     fifs.id_flex_num                        =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, cv_group_3, 1, 1)   =   4
                        AND     SUBSTRB(mcb.segment1, 1, 3)             =   SUBSTRB(mcb2.segment1, 1, 3)
                        UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type                           =   cv_item_group
                        AND     flv.language                              =   cv_ja
                        AND     flv.enabled_flag                          =   cv_flg_y
                        AND     INSTR(flv.lookup_code, cv_group_3, 1, 1)  =   4
                        AND     SUBSTRB(flv.lookup_code, 1, 3)            =   SUBSTRB(mcb2.segment1, 1, 3)
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                    )
          ) sub
     GROUP BY   group1_cd 
               ,group1_nm 
               ,group3_cd 
               ,group3_nm 
               ,item_cd   
               ,item_nm   
               ,now_item_cost
               ,now_business_cost 
               ,now_unit_price 
     ORDER BY   group1_cd
               ,group3_cd
               ,item_cd
     ;

--//+UPD START 2011/01/13 E_本稼動_05803 PT対応 Y.Kanami
    item_plan_select_cur_rec item_plan_select_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  ===============================
--  ローカル・変数初期化
--  ===============================
    lv_group3_cd_pre  := NULL;             --保存用政策群コード3
    lv_group1_cd_pre  := NULL;             --保存用政策群コード1
    lv_kyoten_cd      := iv_kyoten_cd;     --A-2で取得した拠点コード
    lv_kyoten_nm      := iv_kyoten_nm;     --A-2で取得した拠点名
--
    --商品計画データ品目単位でLOOP
    OPEN item_plan_select_cur;
    <<item_plan_select_loop>>
    LOOP
      FETCH item_plan_select_cur INTO item_plan_select_cur_rec;
      EXIT WHEN item_plan_select_cur%NOTFOUND;
        lv_group1_cd        := item_plan_select_cur_rec.group1_cd;        --政策群コード1
        lv_group1_nm        := item_plan_select_cur_rec.group1_nm;        --政策群名称1
        lv_group3_cd        := item_plan_select_cur_rec.group3_cd;        --政策群コード3
        lv_group3_nm        := item_plan_select_cur_rec.group3_nm;        --政策群名称3
        lv_item_cd          := item_plan_select_cur_rec.item_cd;          --品目コード
        lv_item_nm          := item_plan_select_cur_rec.item_nm;          --品目名称
        ln_base_price       := item_plan_select_cur_rec.now_item_cost;    --標準原価
        ln_bus_price        := item_plan_select_cur_rec.now_business_cost;--営業原価
        ln_con_price        := item_plan_select_cur_rec.now_unit_price;   --定価
        ln_sales_budget_sum := item_plan_select_cur_rec.sales_budget_sum; --売上金額
        ln_amount_sum       := item_plan_select_cur_rec.amount_sum;       --数量
--
        --政策群コード1は変わっていない場合
        IF (lv_group1_cd_pre IS NOT NULL) AND (lv_group1_cd = lv_group1_cd_pre ) THEN
          --政策群コード3は変わったら、商品群計のみをします。
          IF (lv_group3_cd_pre IS NOT NULL) AND (lv_group3_cd_pre <> lv_group3_cd) THEN
            --  ===============================
            --  商品群月別集計(A-6)
            --  月別商品群データ登録(A-7)
            --  ===============================
            group3_month_count (
                                lv_kyoten_cd               --A-2で取得した拠点コード
                               ,lv_kyoten_nm               --A-2で取得した拠点名称
                               ,lv_group3_cd_pre               --A-5で取得した政策群コード3
                               ,lv_group3_nm_pre               --A-5で取得した政策群名3
                               ,lv_errbuf                  -- 共通・エラー・メッセージ
                               ,lv_retcode                 -- リターン・コード
                               ,lv_errmsg);                -- ユーザー・エラー・メッセージ
            -- 例外処理
            IF (lv_retcode <> cv_status_normal) THEN
              --(エラー処理)
              RAISE global_api_expt;
            END IF;
          END IF;
        --政策群コード1が変わった場合：商品群計、商品区分計を集計します。
        ELSIF (lv_group1_cd_pre IS NOT NULL) AND (lv_group1_cd <> lv_group1_cd_pre ) THEN
          --  ===============================
          --  商品群月別集計(A-6)
          --  月別商品群データ登録(A-7)
          --  ===============================
          group3_month_count (
                              lv_kyoten_cd               --A-2で取得した拠点コード
                             ,lv_kyoten_nm               --A-2で取得した拠点名称
                             ,lv_group3_cd_pre               --A-5で取得した政策群コード3
                             ,lv_group3_nm_pre               --A-5で取得した政策群名3
                             ,lv_errbuf                  --共通・エラー・メッセージ
                             ,lv_retcode                 --リターン・コード
                             ,lv_errmsg);                --ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
          END IF;
          --  ===============================
          --  商品区分月別集計(A-8)
          --  月別商品区分データ登録(A-9)
          --  ===============================
          group1_month_count (
                              lv_kyoten_cd              --A-2で取得した拠点コード
                             ,lv_kyoten_nm              --A-2で取得した拠点名称
                             ,lv_group1_cd_pre              --A-5で取得した政策群コード1
                             ,lv_group1_nm_pre              --A-5で取得した政策群名1
                             ,lv_errbuf                 --共通・エラー・メッセージ
                             ,lv_retcode                --リターン・コード
                             ,lv_errmsg);               --ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
          END IF;
          --政策群コード1がDに変わった場合：商品合計を集計します。
          IF (lv_group1_cd = cv_group_d) THEN
            --  ===============================
            --  商品合計月別集計(A-10)
            --  月別商品合計データ登録(A-11)
            --  ===============================
            all_item_month_count (
                                  lv_kyoten_cd              --A-2で取得した拠点コード
                                 ,lv_kyoten_nm              --A-2で取得した拠点名称
                                 ,lv_errbuf                 --共通・エラー・メッセージ
                                 ,lv_retcode                --リターン・コード
                                 ,lv_errmsg);               --ユーザー・エラー・メッセージ
            -- 例外処理
            IF (lv_retcode <> cv_status_normal) THEN
              --(エラー処理)
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
        --品目コード単位で一回LOOPして、無条件に商品計を一回します。
        --  ===============================
        --  商品別月別集計(A-12)
        --  月別商品別データ登録(A-13)
        --  ===============================
-- DEL START 2011/12/14 E_本稼動_08817 K.Nakamura
----//+ADD START 2009/02/19 CT038 K.Yamada
---- MODIFY  START  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
----        IF ln_sales_budget_sum <> 0 THEN
----        IF ln_sales_budget_sum <> 0 OR ln_amount_sum <> 0 THEN
---- MODIFY  END  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
----//+ADD END   2009/02/19 CT038 K.Yamada
-- DEL  END  2011/12/14 E_本稼動_08817 K.Nakamura
        item_month_count (
                          lv_kyoten_cd                --A-2で取得した拠点コード
                         ,lv_kyoten_nm                --A-2で取得した拠点名称
                         ,lv_item_cd                  --A-5で取得した品目コード
                         ,lv_item_nm                  --A-5で取得した品目名
                         ,ln_amount_sum               --A-5で取得した数量
                         ,ln_sales_budget_sum         --A-5で取得した売上
                         ,ln_bus_price                --A-5で取得した営業原価
                         ,ln_con_price                --A-5で取得した定価
                         ,lv_errbuf                   --共通・エラー・メッセージ
                         ,lv_retcode                  --リターン・コード
                         ,lv_errmsg);                 --ユーザー・エラー・メッセージ
        -- 例外処理
        IF (lv_retcode <> cv_status_normal) THEN
          --(エラー処理)
          RAISE global_api_expt;
        END IF;
-- DEL START 2011/12/14 E_本稼動_08817 K.Nakamura
----//+ADD START 2009/02/19 CT038 K.Yamada
--        END IF;
----//+ADD END   2009/02/19 CT038 K.Yamada
-- DEL  END  2011/12/14 E_本稼動_08817 K.Nakamura
        lv_group3_cd_pre := lv_group3_cd;
        lv_group3_nm_pre := lv_group3_nm;
        lv_group1_cd_pre := lv_group1_cd;
        lv_group1_nm_pre := lv_group1_nm;
    END LOOP item_plan_select_loop;
--*** 最後の商品群計 ***
      --  ===============================
      --  商品群月別集計(A-6)
      --  月別商品群データ登録(A-7)
      --  ===============================
      group3_month_count (
                          lv_kyoten_cd               --A-2で取得した拠点コード
                         ,lv_kyoten_nm               --A-2で取得した拠点名称
                         ,lv_group3_cd_pre           --A-5で取得した政策群コード3
                         ,lv_group3_nm_pre           --A-5で取得した政策群名3
                         ,lv_errbuf                  --共通・エラー・メッセージ
                         ,lv_retcode                 --リターン・コード
                         ,lv_errmsg);                --ユーザー・エラー・メッセージ
      -- 例外処理
      IF (lv_retcode <> cv_status_normal) THEN
        --(エラー処理)
        RAISE global_api_expt;
      END IF;
      --  ===============================
      --  商品区分月別集計(A-8)
      --  月別商品区分データ登録(A-9)
      --  ===============================
      group1_month_count (
                          lv_kyoten_cd              --A-2で取得した拠点コード
                         ,lv_kyoten_nm              --A-2で取得した拠点名称
                         ,lv_group1_cd_pre              --A-5で取得した政策群コード1
                         ,lv_group1_nm_pre              --A-5で取得した政策群名1
                         ,lv_errbuf                 --共通・エラー・メッセージ
                         ,lv_retcode                --リターン・コード
                         ,lv_errmsg);               --ユーザー・エラー・メッセージ
      -- 例外処理
      IF (lv_retcode <> cv_status_normal) THEN
        --(エラー処理)
        RAISE global_api_expt;
      END IF;
    IF (lv_group1_cd <> cv_group_d) THEN
      --  ===============================
      --  商品合計月別集計(A-10)
      --  月別商品合計データ登録(A-11)
      --  ===============================
      all_item_month_count (
                            lv_kyoten_cd              --A-2で取得した拠点コード
                           ,lv_kyoten_nm              --A-2で取得した拠点名称
                           ,lv_errbuf                 --共通・エラー・メッセージ
                           ,lv_retcode                --リターン・コード
                           ,lv_errmsg);               --ユーザー・エラー・メッセージ
      -- 例外処理
      IF (lv_retcode <> cv_status_normal) THEN
        --(エラー処理)
        RAISE global_api_expt;
      END IF;
    END IF;
    --  ===============================
    --  値引月別集計(A-14)
    --  月別値引データ登録(A-15)
    --  ===============================
    reduce_price_count (
                        lv_kyoten_cd              --A-2で取得した拠点コード
                       ,lv_kyoten_nm              --A-2で取得した拠点名称
                       ,lv_errbuf                 --共通・エラー・メッセージ
                       ,lv_retcode                --リターン・コード
                       ,lv_errmsg);               --ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
    --  ===============================
    --  拠点別月別集計(A-16)
    --  月別拠点別データ、H基準登録(A-17)
    --  ===============================
    kyoten_month_count (
                        lv_kyoten_cd            --A-2で取得した拠点コード
                       ,lv_kyoten_nm            --A-2で取得した拠点名称
                       ,lv_errbuf               --共通・エラー・メッセージ
                       ,lv_retcode              --リターン・コード
                       ,lv_errmsg );            --ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
    CLOSE item_plan_select_cur;
--
--#################################  固定例外処理部  #############################
  EXCEPTION
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
--#####################################  固定部 END   ###########################
--
  END item_plan_select;
--
   /****************************************************************************
   * Procedure Name   : write_csv_file
   * Description      : チェックリストデータ出力(A-18)
   ****************************************************************************/
   PROCEDURE write_csv_file (  
         ov_errbuf     OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'write_csv_file';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--//+ADD START 2009/02/19 CT048 K.Yamada
    -- ===============================
    -- ユーザー定義ローカル定数
    -- ===============================
    cv_1st_location                 CONSTANT VARCHAR2(1)   := '0';             -- 拠点コード初期値
--//+ADD END   2009/02/19 CT048 K.Yamada

    -- ===============================
    -- ユーザー定義ローカル変数
    -- ===============================
    -- ヘッダ情報
    lv_data_head                   VARCHAR2(4000);   --ヘッダ
    -- ボディ情報
    lv_data_body                   VARCHAR2(30000);  --ボディ
    lv_item_plan_data              VARCHAR2(4000);   --行情報
    lv_location_nm                 VARCHAR2(100);    --入力パラメータ拠点名
    lv_code                        VARCHAR2(100);    --コード
    lv_name                        VARCHAR2(100);    --名称
    lv_kbn_nm                      VARCHAR2(100);    --出力区分名
    lt_plan_data5                  xxcsm_tmp_month_item_plan.plan_data5%TYPE;    --5月データ
    lt_plan_data6                  xxcsm_tmp_month_item_plan.plan_data6%TYPE;    --6月データ
    lt_plan_data7                  xxcsm_tmp_month_item_plan.plan_data7%TYPE;    --7月データ
    lt_plan_data8                  xxcsm_tmp_month_item_plan.plan_data8%TYPE;    --8月データ
    lt_plan_data9                  xxcsm_tmp_month_item_plan.plan_data9%TYPE;    --9月データ
    lt_plan_data10                 xxcsm_tmp_month_item_plan.plan_data10%TYPE;    --10月データ
    lt_plan_data11                 xxcsm_tmp_month_item_plan.plan_data11%TYPE;    --11月データ
    lt_plan_data12                 xxcsm_tmp_month_item_plan.plan_data12%TYPE;    --12月データ
    lt_plan_data1                  xxcsm_tmp_month_item_plan.plan_data1%TYPE;    --1月データ
    lt_plan_data2                  xxcsm_tmp_month_item_plan.plan_data2%TYPE;    --2月データ
    lt_plan_data3                  xxcsm_tmp_month_item_plan.plan_data3%TYPE;    --3月データ
    lt_plan_data4                  xxcsm_tmp_month_item_plan.plan_data4%TYPE;    --4月データ
    lt_plan_year                   xxcsm_tmp_month_item_plan.plan_year%TYPE;    --年間データ
--//+ADD START 2009/02/19 CT048 K.Yamada
    lt_location_cd                 xxcsm_tmp_month_item_plan.location_cd%TYPE;    --拠点コード
    lt_pre_location_cd             xxcsm_tmp_month_item_plan.location_cd%TYPE;    --拠点コード
    lt_location_nm                 xxcsm_tmp_month_item_plan.location_nm%TYPE;    --拠点名
--//+ADD END   2009/02/19 CT048 K.Yamada
--
--============================================
--ローカル・カーソル
--============================================ 
    CURSOR  check_list_data_cur
    IS
      SELECT    code                         --出力コード
               ,name                         --出力名
               ,kbn_nm                       --出力区分名
               ,plan_data5                   --5月データ
               ,plan_data6                   --6月データ
               ,plan_data7                   --7月データ
               ,plan_data8                   --8月データ
               ,plan_data9                   --9月データ
               ,plan_data10                  --10月データ
               ,plan_data11                  --11月データ
               ,plan_data12                  --12月データ
               ,plan_data1                   --1月データ
               ,plan_data2                   --2月データ
               ,plan_data3                   --3月データ
               ,plan_data4                   --4月データ
               ,plan_year                    --年間データ
--//+ADD START 2009/02/19 CT048 K.Yamada
               ,location_cd                  --拠点コード
               ,location_nm                  --拠点名
--//+ADD END   2009/02/19 CT048 K.Yamada
      FROM      xxcsm_tmp_month_item_plan     --月別商品計画ワークテーブル
      ORDER BY  seq_no           --出力順
    ;
    check_list_data_cur_rec  check_list_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

    lv_data_head := NULL;
    lv_data_body := NULL;
    lv_item_plan_data := NULL;
--//+ADD START 2009/02/19 CT048 K.Yamada
    lt_pre_location_cd := cv_1st_location;    --拠点コード
--//+ADD END   2009/02/19 CT048 K.Yamada
--//+ADD START 2009/02/19 CT048 K.Yamada
    -- 営業企画部「全拠点」の場合
    IF (gv_location_cd = cv_location_1) THEN
--//+ADD END   2009/02/19 CT048 K.Yamada
    -- ヘッダ情報の抽出
      BEGIN
        SELECT location_nm 
        INTO   lv_location_nm
        FROM   xxcsm_location_all_v  
        WHERE location_cd = gv_location_cd;
      END;
      lv_data_head := xxccp_common_pkg.get_msg(                                   -- 拠点コードの出力
                        iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                       ,iv_name         => cv_chk_err_00098                       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_kyoten_cd                       -- トークンコード1（拠点コード）
                       ,iv_token_value1 => gv_location_cd                         -- トークン値1
                       ,iv_token_name2  => cv_tkn_kyoten_nm                       -- トークンコード2（拠点コード名称）
                       ,iv_token_value2 => lv_location_nm                         -- トークン値2
                       ,iv_token_name3  => cv_tkn_year                            -- トークンコード3（対象年度）
                       ,iv_token_value3 => gn_subject_year                        -- トークン値3
                       ,iv_token_name4  => cv_tkn_nichiji                         -- トークンコード4（業務日付）
                       ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')  -- トークン値4
                       );
       -- ヘッダ情報の出力
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_data_head
                       );
--//+ADD START 2009/02/19 CT048 K.Yamada
    END IF;
--//+ADD END   2009/02/19 CT048 K.Yamada
--
    -- =========================================================================
    -- ボディ情報の出力
    -- =========================================================================
    OPEN check_list_data_cur;
    LOOP
      FETCH check_list_data_cur INTO check_list_data_cur_rec;
      EXIT WHEN check_list_data_cur%NOTFOUND;
        lv_code        := check_list_data_cur_rec.code;                  --出力コード
        lv_name        := check_list_data_cur_rec.name;                  --出力名
        lv_kbn_nm      := check_list_data_cur_rec.kbn_nm;                --出力区分名
        lt_plan_data5  := check_list_data_cur_rec.plan_data5;            --5月データ
        lt_plan_data6  := check_list_data_cur_rec.plan_data6;            --6月データ
        lt_plan_data7  := check_list_data_cur_rec.plan_data7;            --7月データ
        lt_plan_data8  := check_list_data_cur_rec.plan_data8;            --8月データ
        lt_plan_data9  := check_list_data_cur_rec.plan_data9;            --9月データ
        lt_plan_data10 := check_list_data_cur_rec.plan_data10;           --10月データ
        lt_plan_data11 := check_list_data_cur_rec.plan_data11;           --11月データ
        lt_plan_data12 := check_list_data_cur_rec.plan_data12;           --12月データ
        lt_plan_data1  := check_list_data_cur_rec.plan_data1;            --1月データ
        lt_plan_data2  := check_list_data_cur_rec.plan_data2;            --2月データ
        lt_plan_data3  := check_list_data_cur_rec.plan_data3;            --3月データ
        lt_plan_data4  := check_list_data_cur_rec.plan_data4;            --4月データ
        lt_plan_year   := check_list_data_cur_rec.plan_year;             --年間データ
--//+ADD START 2009/02/19 CT048 K.Yamada
        lt_location_cd := check_list_data_cur_rec.location_cd;           --拠点コード
        lt_location_nm := check_list_data_cur_rec.location_nm;           --拠点名
--//+ADD END   2009/02/19 CT048 K.Yamada
        --行情報設定
        lv_item_plan_data := lv_code||cv_msg_comma||lv_name||cv_msg_comma||lv_kbn_nm||cv_msg_comma||lt_plan_data5||
                           cv_msg_comma||lt_plan_data6||cv_msg_comma||lt_plan_data7||cv_msg_comma||lt_plan_data8||
                           cv_msg_comma||lt_plan_data9||cv_msg_comma||lt_plan_data10||cv_msg_comma||lt_plan_data11||
                           cv_msg_comma||lt_plan_data12||cv_msg_comma||lt_plan_data1||cv_msg_comma||lt_plan_data2||
                           cv_msg_comma||lt_plan_data3||cv_msg_comma||lt_plan_data4||cv_msg_comma||lt_plan_year;
        --行情報をボディ情報に追加
--//+ADD START 2009/02/19 CT048 K.Yamada
      -- 営業企画部「全拠点」でない場合
      IF (gv_location_cd <> cv_location_1) THEN
        -- 拠点コードが変わったら
        IF (lt_location_cd <> lt_pre_location_cd) THEN
          -- ２つ目以降の拠点の場合
          IF (lt_pre_location_cd <> cv_1st_location) THEN
            -- １行空ける
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ''
                             );
          END IF;
          -- 拠点毎のヘッダ情報出力
          lv_data_head := xxccp_common_pkg.get_msg(                                   -- 拠点コードの出力
                            iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                           ,iv_name         => cv_chk_err_00098                       -- メッセージコード
                           ,iv_token_name1  => cv_tkn_kyoten_cd                       -- トークンコード1（拠点コード）
                           ,iv_token_value1 => lt_location_cd                         -- トークン値1
                           ,iv_token_name2  => cv_tkn_kyoten_nm                       -- トークンコード2（拠点コード名称）
                           ,iv_token_value2 => lt_location_nm                         -- トークン値2
                           ,iv_token_name3  => cv_tkn_year                            -- トークンコード3（対象年度）
                          ,iv_token_value3 => gn_subject_year                        -- トークン値3
                           ,iv_token_name4  => cv_tkn_nichiji                         -- トークンコード4（業務日付）
                           ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')  -- トークン値4
                           );
           -- ヘッダ情報の出力
          fnd_file.put_line(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_data_head
                           );
          lt_pre_location_cd := lt_location_cd;
        END IF;
      END IF;
--//+ADD END   2009/02/19 CT048 K.Yamada
        -- ボディ情報の出力
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_item_plan_data
                       );
    END LOOP;
    CLOSE check_list_data_cur;
    IF lv_item_plan_data IS NULL THEN
--//+ADD START   2009/07/13 0000657 M.Ohtsuki
    IF (gv_location_cd <> cv_location_1) THEN                                                       --「全拠点」以外の場合
--//+ADD END     2009/07/13 0000657 M.Ohtsuki
--//+ADD START   2009/02/27 CT070 T.Tsukino
      BEGIN
        SELECT location_nm 
        INTO   lv_location_nm
        FROM   xxcsm_location_all_v  
        WHERE location_cd = gv_location_cd;
      END;
      lv_data_head := xxccp_common_pkg.get_msg(                                   -- 拠点コードの出力
                        iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                       ,iv_name         => cv_chk_err_00098                       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_kyoten_cd                       -- トークンコード1（拠点コード）
                       ,iv_token_value1 => gv_location_cd                         -- トークン値1
                       ,iv_token_name2  => cv_tkn_kyoten_nm                       -- トークンコード2（拠点コード名称）
                       ,iv_token_value2 => lv_location_nm                         -- トークン値2
                       ,iv_token_name3  => cv_tkn_year                            -- トークンコード3（対象年度）
                       ,iv_token_value3 => gn_subject_year                        -- トークン値3
                       ,iv_token_name4  => cv_tkn_nichiji                         -- トークンコード4（業務日付）
                       ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')  -- トークン値4
                       );
       -- ヘッダ情報の出力
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_data_head
                       );
--//+ADD END     2009/02/27 CT070 T.Tsukino
--//+ADD START   2009/07/13 0000657 M.Ohtsuki
      END IF;
--//+ADD END     2009/07/13 0000657 M.Ohtsuki
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_10001
                                           );
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_errmsg
                       );
      --//+ADD START 2009/02/12 CT013 H.Yoshitake
      -- 戻りステータス警告設定
      ov_retcode := cv_status_warn;
      --//+ADD END   2009/02/12 CT013 H.Yoshitake
    END IF;
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    WHEN global_api_expt THEN
      IF (check_list_data_cur%ISOPEN) THEN
        CLOSE check_list_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (check_list_data_cur%ISOPEN) THEN
        CLOSE check_list_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (check_list_data_cur%ISOPEN) THEN
        CLOSE check_list_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ###########################
--
  END write_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     --  エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,     --  リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)     --  ユーザー・エラー・メッセージ 
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';          -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                   --エラー・メッセージ
    lv_retcode                VARCHAR2(1);                      --リターン・コード
    lv_errmsg                 VARCHAR2(5000);                   --ユーザー・エラー・メッセージ
    lv_location_cd            VARCHAR2(4);                      --全拠点取得した拠点コード
    lv_location_nm            VARCHAR2(100);                    --全拠点取得した拠点名称
    lv_get_loc_tab            xxcsm_common_pkg.g_kyoten_ttype;  --拠点コードリスト
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    gn_seq_no      := 0;                --シーケンス番号
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    gv_group_flag  := cv_flg_n;         --群出力フラグ
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
    -- ローカル変数初期化
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
          lv_errbuf         -- エラー・メッセージ
         ,lv_retcode        -- リターン・コード
         ,lv_errmsg );
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 全拠点取得(A-2)(共通関数を呼び出す)
    -- ===============================
    xxcsm_common_pkg.get_kyoten_cd_lv6(
                                      iv_kyoten_cd      => gv_location_cd
                                     ,iv_kaisou         => gv_hierarchy_level
--//ADD START 2009/05/07 T1_0858 M.Ohtsuki
                                     ,iv_subject_year   => gn_subject_year
--//ADD END   2009/05/07 T1_0858 M.Ohtsuki
                                     ,o_kyoten_list_tab => lv_get_loc_tab
                                     ,ov_retcode        => lv_retcode
                                     ,ov_errbuf         => lv_errbuf 
                                     ,ov_errmsg         => lv_errmsg 
                                     );
    -- 例外処理(取得したデータが0件の場合、エラーコードがWARNINGで、
    --         チェックリストのヘッダと対象データ無しのメッセージだけ出力し、正常終了します。)
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    <<kyoten_list_loop>>
    FOR ln_count IN 1..lv_get_loc_tab.COUNT LOOP
      BEGIN
        -- 拠点コード
        lv_location_cd := lv_get_loc_tab(ln_count).kyoten_cd;
        -- 拠点名称
        lv_location_nm := lv_get_loc_tab(ln_count).kyoten_nm;
        --対象件数を設定
        gn_target_cnt := gn_target_cnt + 1;
        -- ===================================
        --年間商品計画データ存在チェック(A-3)
        --按分処理済データ存在チェック(A-4)
        -- ===================================
        do_check (
                  lv_location_cd                  --A-2で取得した拠点コード
                 ,lv_errbuf                       --エラー・メッセージ
                 ,lv_retcode                      --リターン・コード
                 ,lv_errmsg );                    --ユーザー・エラー・メッセージ
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE kyoten_skip_expt;
        END IF;
        --*** 入力パラメータ．拠点コードは'1'の場合、拠点計、H基準だけ出します。 ***
        IF (gv_location_cd = cv_location_1) THEN
          --  ===============================
          --  拠点別月別集計(A-16)
          --  月別拠点別データ、H基準登録(A-17)
          --  ===============================
          kyoten_month_count (
                              lv_location_cd                  --A-2で取得した拠点コード
                             ,lv_location_nm                  --A-2で取得した拠点名称
                             ,lv_errbuf                       --共通・エラー・メッセージ
                             ,lv_retcode                      --リターン・コード
                             ,lv_errmsg );                    --ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
          END IF;
        ELSE
          --*** 入力パラメータ．拠点コードは1以外の場合 ***
          -- ===================================
          -- 商品計画データを抽出(A-5)
          -- ===================================
          item_plan_select (
                            lv_location_cd            --A-2で取得した拠点コード
                           ,lv_location_nm            --A-2で取得した拠点名
                           ,lv_errbuf                 --共通・エラー・メッセージ
                           ,lv_retcode                --リターン・コード
                           ,lv_errmsg);               --ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
        END IF;
        gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
        WHEN kyoten_skip_expt THEN
          fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg        --エラーメッセージ
          );
--//+UPD START 2009/02/19 CT037 K.Yamada
--          gn_error_cnt := gn_error_cnt + 1;
          gn_warn_cnt := gn_warn_cnt + 1;
--//+UPD END   2009/02/19 CT037 K.Yamada
          ov_retcode := cv_status_warn;
      END;
    END LOOP kyoten_list_loop;
    -- ===================================
    -- チェックリストデータ出力(A-18)
    -- ===================================
    write_csv_file (
                    lv_errbuf                --共通・エラー・メッセージ
                   ,lv_retcode               --リターン・コード
                   ,lv_errmsg);              --ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
    ov_retcode := lv_retcode;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf                  OUT  NOCOPY VARCHAR2,     --   エラー・メッセージ
    retcode                 OUT  NOCOPY VARCHAR2,     --   リターン・コード
    iv_subject_year         IN   VARCHAR2,            --   対象年度
    iv_location_cd          IN   VARCHAR2,            --   拠点コード
--//+UPD START E_本稼動_09949 K.Taniguchi
--    iv_hierarchy_level      IN   VARCHAR2             --   階層
    iv_hierarchy_level      IN   VARCHAR2,            --   階層
    iv_new_old_cost_class   IN   VARCHAR2             --   新旧原価区分
--//+UPD END E_本稼動_09949 K.Taniguchi
  )
--
--###########################  固定部 START   ###########################
--
  IS
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
       iv_which   => cv_whick_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
    --入力パラメータ
    gn_subject_year    := TO_NUMBER(iv_subject_year);
    gv_location_cd     := iv_location_cd;
    gv_hierarchy_level := iv_hierarchy_level;
--//+ADD START E_本稼動_09949 K.Taniguchi
    gv_new_old_cost_class := iv_new_old_cost_class;
--//+ADD END E_本稼動_09949 K.Taniguchi
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf        -- エラー・メッセージ 
      ,lv_retcode       -- リターン・コード  
      ,lv_errmsg        -- ユーザー・エラー・メッセージ 
    );
--
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_xxcsm
                                                ,iv_name         => cv_msg_00111
                                               );
      END IF;
    --エラー出力
      fnd_file.put_line(
--//+UPD START 2009/02/12 CT013 SCS H.Yoshitake
--         which  => FND_FILE.LOG
         which  => FND_FILE.OUTPUT
--//+UPD END   2009/02/12 CT013 SCS H.Yoshitake
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
       which  => FND_FILE.LOG
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
END XXCSM002A08C;
/
