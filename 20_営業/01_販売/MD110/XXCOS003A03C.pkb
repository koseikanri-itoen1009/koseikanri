CREATE OR REPLACE PACKAGE BODY XXCOS003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A03C(body)
 * Description      : ベンダ納品実績情報作成
 * MD.050           : ベンダ納品実績情報作成 MD050_COS_003_A03
 * Version          : 1.3
 *
 * Program List     
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      A-1．初期処理
 *  proc_vd_deli_h_dataset    A-4．ベンダ納品実績情報ヘッダテーブルデータ設定
 *  proc_inv_item_select      A-6．品目マスタデータ抽出
 *  proc_vd_deli_l_dataset    A-7．ベンダ納品実績情報明細テーブルデータ設定
 *  proc_status_update        A-8．VDコラム別取引ヘッダテーブルレコードロック
 *                            A-9．VDコラム別取引ヘッダテーブルステータス更新
 *  proc_main_loop            A-2．VDコラム別取引ヘッダテーブルデータ抽出
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05   1.0    K.Okaguchi       新規作成
 *  2009/02/24   1.1    T.Nakamura       [障害COS_130] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/06/10   1.2    T.Tominaga       [障害T1_1408] エラーメッセージの納品日の書式を’YYYY/MM/DD’に変更
 *  2009/12/11   1.3    N.Yoshida        [本稼動_00399] 訂正・取消データ時はマイナス金額を設定するよう修正
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt    NUMBER DEFAULT 0;                    -- 対象件数
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- 正常件数
  gn_error_cnt     NUMBER DEFAULT 0;                    -- エラー件数
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- スキップ件数
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
  global_data_check_expt    EXCEPTION;     -- データチェック時のエラー
  update_error_expt         EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A03C'; -- パッケージ名
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- アプリケーション名(販売)
  cv_application_coi      CONSTANT VARCHAR2(5)  := 'XXCOI';        -- アプリケーション名(在庫)
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- アドオン：共通・IF領域
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
-- 2009/12/11 N.Yoshida Ver.1.3 Add Start
  cv_flag_red             CONSTANT VARCHAR2(1)  := '0';            -- 赤黒フラグ(赤)
  cn_num_conv             CONSTANT NUMBER       := -1;             -- マイナス値算出用
-- 2009/12/11 N.Yoshida Ver.1.3 Add End
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ロックエラー
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ロック取得エラー
  cv_msg_pro              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    -- プロファイル取得エラー
  cv_msg_organization_id  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';    -- 在庫組織ID取得エラー
  cv_msg_insert_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';    -- データ登録エラーメッセージ
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- データ更新エラーメッセージ
  cv_msg_select_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- データ抽出エラーメッセージ
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- パラメータなし
  
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- 顧客コード
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- 品名コード
  cv_tkn_organization_cd  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00048';    -- XXCOI:在庫組織コード
  cv_tkn_vd_deliv_h       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10751';    -- ベンダ納品実績情報ヘッダテーブル
  cv_tkn_dlv_date         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10752';    -- 納品日
  cv_tkn_item_id          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00139';    -- 品目ID
  cv_tkn_inventory_id     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00063';    -- 在庫組織ID
  cv_tkn_system_item      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00050';    -- 品目マスタ
  cv_tkn_vd_deliv_l       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10753';    -- ベンダ納品実績情報明細テーブル
  cv_tkn_column_no        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10754';    -- コラムNo
  cv_tkn_vd_column_l      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10755';    -- VDコラム別取引ヘッダテーブル
  cv_tkn_order_no_hht     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10756';    -- 受注No.（HHT)
  cv_tkn_digestion_ln_no  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10757';    -- 枝番
  cv_tkn_sub_main_cur     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10758';    --顧客マスタおよび、VDコラムマスタ

  cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';             -- プロファイル名
  cv_tkn_org_code_tok     CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';        -- 在庫組織コード

  cv_lookup_type_gyotai   CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03'; -- 参照タイプ　業態小分類
  cv_organization_code    CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- 在庫組織コード
  
  cv_blank_column_code    CONSTANT VARCHAR2(7)  := 'BLANK_C'; 
   --ブランクコラム用ダミー品目（ベンダ納品実績処理内のみで使用する。ＨＨＴファイルには出力されない）
   
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ; --メッセージ出力用キー情報
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ; --顧客コード
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ; --品名コード
  gv_msg_tkn_organization_cd  fnd_new_messages.message_text%TYPE   ; --在庫組織コード
  gv_msg_tkn_vd_deliv_h       fnd_new_messages.message_text%TYPE   ; --ベンダ納品実績情報ヘッダテーブル
  gv_msg_tkn_dlv_date         fnd_new_messages.message_text%TYPE   ; --納品日
  gv_msg_tkn_item_id          fnd_new_messages.message_text%TYPE   ; --品目ID
  gv_msg_tkn_inventory_id     fnd_new_messages.message_text%TYPE   ; --在庫組織ID
  gv_msg_tkn_system_item      fnd_new_messages.message_text%TYPE   ; --品目マスタ
  gv_msg_tkn_vd_deliv_l       fnd_new_messages.message_text%TYPE   ; --ベンダ納品実績情報明細テーブル
  gv_msg_tkn_column_no        fnd_new_messages.message_text%TYPE   ; --コラムNo
  gv_msg_tkn_vd_column_h      fnd_new_messages.message_text%TYPE   ; --VDコラム別取引ヘッダテーブル
  gv_msg_tkn_order_no_hht     fnd_new_messages.message_text%TYPE   ; --受注No.（HHT)
  gv_msg_tkn_digestion_ln_no  fnd_new_messages.message_text%TYPE   ; --枝番
  gv_msg_tkn_sub_main_cur     fnd_new_messages.message_text%TYPE   ; --顧客マスタおよび、VDコラムマスタ
  
  gv_bf_customer_number       xxcos_vd_column_headers.customer_number%TYPE   ;
  
  gv_customer_number          xxcos_unit_price_mst_work.customer_number%TYPE;
  gv_tkn_lock_table           fnd_new_messages.message_text%TYPE   ;

  gv_organization_code        mtl_parameters.organization_code%TYPE; --在庫組織コード
  gv_organization_id          mtl_parameters.organization_id%TYPE;   --在庫組織ID


  gv_search_item_code         mtl_system_items_b.segment1%TYPE;      --検索用　品目コード
  
  gn_warn_tran_count          NUMBER DEFAULT 0;
  gn_tran_count               NUMBER DEFAULT 0;
  gn_unit_price               NUMBER;
  gn_skip_cnt                 NUMBER DEFAULT 0;                      -- 単価マスタ更新対象外件数
  gn_main_loop_cnt            NUMBER DEFAULT 0;
  gn_sub_main_count           NUMBER;
--
--カーソル
  CURSOR main_cur
  IS
    SELECT xvch.customer_number     customer_number       --顧客コード
          ,xvch.dlv_date            dlv_date              --納品日
          ,xvch.dlv_time            dlv_time              --時間
-- 2009/12/11 N.Yoshida Ver.1.3 Mod Start
--          ,xvch.total_amount        total_amount          --合計金額
          ,CASE WHEN xvch.red_black_flag = cv_flag_red
                THEN xvch.total_amount * cn_num_conv
                ELSE xvch.total_amount
           END                      total_amount          --合計金額
-- 2009/12/11 N.Yoshida Ver.1.3 Mod End
          ,xvch.order_no_hht        order_no_hht          --受注No.（HHT）
          ,xvch.digestion_ln_number digestion_ln_number   --枝番
          ,xvch.base_code           base_code             --拠点コード
    FROM   xxcos_vd_column_headers xvch
          ,fnd_lookup_values       flvl
    WHERE  xvch.vd_results_forward_flag = cv_flag_off
    AND    xvch.system_class            = flvl.meaning
    AND    flvl.lookup_type             = cv_lookup_type_gyotai
    AND    flvl.security_group_id       = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
    AND    flvl.language                = USERENV('LANG')
    AND    TRUNC(SYSDATE)               BETWEEN flvl.start_date_active
                                          AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
    AND    flvl.enabled_flag            = cv_flag_on
    ORDER BY xvch.customer_number
    ;
    
  main_rec main_cur%ROWTYPE;

  CURSOR sub_main_cur
  IS
    SELECT xmvc.column_no            column_no           --VDコラムマスタ	コラムNo
          ,xvcl.item_code_self       item_code_self      --VDコラム別取引明細テーブル	品名コード（自社）
          ,xmvc.item_id              item_id             --VDコラムマスタ	品目ID
          ,xvcl.replenish_number     replenish_number    --VDコラム別取引明細テーブル	補充数
          ,xmvc.inventory_quantity   inventory_quantity  --VDコラムマスタ	基準在庫数
          ,xvcl.h_and_c              h_and_c             --VDコラム別取引明細テーブル	H/C
          ,xmvc.hot_cold             hot_cold            --VDコラムマスタ	H/C
    FROM   xxcoi_mst_vd_column   xmvc
          ,xxcos_vd_column_lines xvcl
          ,hz_cust_accounts      hzca
    WHERE  hzca.account_number          = main_rec.customer_number
    AND    hzca.cust_account_id         = xmvc.customer_id
    AND    xmvc.column_no               = xvcl.column_no(+)
    AND    main_rec.order_no_hht        = xvcl.order_no_hht(+)
    AND    main_rec.digestion_ln_number = xvcl.digestion_ln_number(+)
    ;
  sub_main_rec sub_main_cur%ROWTYPE;
  
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
    
    TYPE g_rec_key_rtype IS RECORD
    (
      order_no_hht         main_rec.order_no_hht%TYPE,        -- 受注No.（HHT)
      digestion_ln_number  main_rec.digestion_ln_number%TYPE  -- 枝番
    );
    
    TYPE g_tab_key_ttype IS TABLE OF g_rec_key_rtype INDEX BY PLS_INTEGER;

    gt_key         g_tab_key_ttype; 

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2 ,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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

    -- *** ローカル変数 ***
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

-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --空行
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --空行
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- マルチバイトの固定値をメッセージより取得
    --==============================================================
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
    gv_msg_tkn_organization_cd  := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                                           ,iv_name         => cv_tkn_organization_cd
                                                           );
    gv_msg_tkn_vd_deliv_h      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_deliv_h
                                                           );
    gv_msg_tkn_dlv_date        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_dlv_date
                                                           );
    gv_msg_tkn_item_id         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_id
                                                           );
    gv_msg_tkn_inventory_id    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_inventory_id
                                                           );
    gv_msg_tkn_system_item     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_system_item
                                                           );
    gv_msg_tkn_vd_deliv_l      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_deliv_l
                                                           );
    gv_msg_tkn_column_no       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_column_no
                                                           );
    gv_msg_tkn_vd_column_h     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_column_l
                                                           );
    gv_msg_tkn_order_no_hht    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_order_no_hht
                                                           );
    gv_msg_tkn_digestion_ln_no := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_digestion_ln_no
                                                           );
    gv_msg_tkn_sub_main_cur := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sub_main_cur
                                                           );                                                           
    --==============================================================
    -- プロファイルの取得(在庫組織コード)
    --==============================================================
    gv_organization_code := FND_PROFILE.VALUE(cv_organization_code);
--
    -- プロファイル取得エラーの場合
    IF (gv_organization_code IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_organization_cd);
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    -- 在庫組織コードより在庫組織IDを導出
    --==============================================================
    gv_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
--
    -- 在庫組織ID取得エラーの場合
    IF (gv_organization_id IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application_coi
                                          , cv_msg_organization_id
                                          , cv_tkn_org_code_tok
                                          , gv_organization_code);
      RAISE global_api_others_expt;
    END IF;
                                                         
--
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
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
--
  /**********************************************************************************
   * Procedure Name   : proc_vd_deli_h_dataset
   * Description      : A-4．ベンダ納品実績情報ヘッダテーブルデータ設定
   ***********************************************************************************/
  PROCEDURE proc_vd_deli_h_dataset(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_vd_deli_h_dataset'; -- プログラム名
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
    lv_visit_time     xxcos_vd_deliv_headers.visit_time%TYPE;
    lv_set_visit_time xxcos_vd_deliv_headers.visit_time%TYPE;
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
    BEGIN
      SELECT  visit_time
      INTO    lv_visit_time
      FROM    xxcos_vd_deliv_headers xvdh
      WHERE   xvdh.customer_number = main_rec.customer_number
      AND     xvdh.dlv_date        = main_rec.dlv_date       
      FOR UPDATE NOWAIT
      ;
      
      -- ===============================
      --ベンダ納品実績情報ヘッダテーブル更新
      -- ===============================
      --訪問時刻判定
      IF lv_visit_time > main_rec.dlv_time THEN
        lv_set_visit_time := lv_visit_time;
      ELSE
        lv_set_visit_time := main_rec.dlv_time;
      END IF;
    
      BEGIN
        UPDATE xxcos_vd_deliv_headers
        SET    visit_time                 = lv_set_visit_time                    --訪問時刻
              ,total_amount               = total_amount + main_rec.total_amount --合計金額
              ,last_updated_by            = cn_last_updated_by       
              ,last_update_date           = cd_last_update_date      
              ,last_update_login          = cn_last_update_login     
              ,request_id                 = cn_request_id            
              ,program_application_id     = cn_program_application_id
              ,program_id                 = cn_program_id            
              ,program_update_date        = cd_program_update_date   
        WHERE  customer_number = main_rec.customer_number
        AND    dlv_date        = main_rec.dlv_date       
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                          ,ov_retcode     => lv_retcode                 --リターン・コード
                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                          ,ov_key_info    => gv_key_info                --キー情報
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                          ,iv_data_value1 => main_rec.customer_number   --データの値1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --項目名称2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD START  ******************************************
--                                          ,iv_data_value2 => main_rec.dlv_date          --データの値2
                                          ,iv_data_value2 => TO_CHAR(main_rec.dlv_date, 'YYYY/MM/DD')   --データの値2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD END    ******************************************
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_update_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_h
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errbuf --エラーメッセージ
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --エラーメッセージ
                           );
          ov_retcode := cv_status_error;
          RAISE update_error_expt;

      END;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN

    -- ===============================
    --ベンダ納品実績情報ヘッダテーブル登録
    -- ===============================
        BEGIN
          INSERT INTO xxcos_vd_deliv_headers(
             customer_number          --顧客コード
            ,dlv_date                 --納品日
            ,visit_time               --訪問時刻
            ,total_amount             --合計金額
            ,base_code                --拠点コード
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )VALUES(
             main_rec.customer_number --顧客コード
            ,main_rec.dlv_date        --納品日
            ,main_rec.dlv_time        --訪問時刻
            ,main_rec.total_amount    --合計金額
            ,main_rec.base_code       --拠点コード
            ,cn_created_by
            ,cd_creation_date
            ,cn_last_updated_by
            ,cd_last_update_date
            ,cn_last_update_login
            ,cn_request_id
            ,cn_program_application_id
            ,cn_program_id
            ,cd_program_update_date
           );
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                            ,ov_retcode     => lv_retcode                 --リターン・コード
                                            ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info                --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                            ,iv_data_value1 => main_rec.customer_number   --データの値1
                                            ,iv_item_name2  => gv_msg_tkn_dlv_date        --項目名称2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD START  ******************************************
--                                            ,iv_data_value2 => main_rec.dlv_date          --データの値2
                                            ,iv_data_value2 => TO_CHAR(main_rec.dlv_date, 'YYYY/MM/DD')   --データの値2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD END    ******************************************
                                            );
            
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_insert_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_deliv_h
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --エラーメッセージ
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --エラーメッセージ
                             );
            ov_retcode := cv_status_error;
            RAISE global_api_others_expt;
        END;
      WHEN update_error_expt THEN
        RAISE global_api_others_expt;
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        IF (SQLCODE = cn_lock_error_code) THEN
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_lock
                                              , cv_tkn_lock
                                              , gv_msg_tkn_vd_deliv_h
                                               );
        ELSE
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                          ,ov_retcode     => lv_retcode                 --リターン・コード
                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                          ,ov_key_info    => gv_key_info                --キー情報
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                          ,iv_data_value1 => main_rec.customer_number   --データの値1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --項目名称2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD START  ******************************************
--                                          ,iv_data_value2 => main_rec.dlv_date          --データの値2
                                          ,iv_data_value2 => TO_CHAR(main_rec.dlv_date, 'YYYY/MM/DD')   --データの値2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD END    ******************************************
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_h
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );

        END IF;
        
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.LOG
                         ,buff   => ov_errbuf --エラーメッセージ
                         );
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.OUTPUT
                         ,buff   => ov_errmsg --エラーメッセージ
                         );
        ov_retcode := cv_status_warn;
    END;
    
--
  EXCEPTION
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
  END proc_vd_deli_h_dataset;


  /**********************************************************************************
   * Procedure Name   : proc_inv_item_select
   * Description      : A-6．品目マスタデータ抽出
   ***********************************************************************************/
  PROCEDURE proc_inv_item_select(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_inv_item_select'; -- プログラム名
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
    SELECT msib.segment1 segment1             --VDコラムマスタ	H/C
    INTO   gv_search_item_code
    FROM   mtl_system_items_b  msib
    WHERE  msib.inventory_item_id       = sub_main_rec.item_id
    AND    msib.organization_id         = gv_organization_id
    ;
    
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
      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                      ,ov_retcode     => lv_retcode                 --リターン・コード
                                      ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                      ,ov_key_info    => gv_key_info                --キー情報
                                      ,iv_item_name1  => gv_msg_tkn_item_id         --項目名称1
                                      ,iv_data_value1 => sub_main_rec.item_id       --データの値1
                                      ,iv_item_name2  => gv_msg_tkn_inventory_id    --項目名称2
                                      ,iv_data_value2 => gv_organization_id         --データの値2
                                      );
      
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_select_err
                                          , cv_tkn_table_name
                                          , gv_msg_tkn_system_item
                                          , cv_tkn_key_data
                                          , gv_key_info
                                          );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => ov_errbuf --エラーメッセージ
                       );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.OUTPUT
                       ,buff   => ov_errmsg --エラーメッセージ
                       );
      ov_retcode := cv_status_warn;
      
--
--#####################################  固定部 END   ##########################################
--
  END proc_inv_item_select;


  /**********************************************************************************
   * Procedure Name   : proc_vd_deli_l_dataset
   * Description      : A-7．ベンダ納品実績情報明細テーブルデータ設定
   ***********************************************************************************/
  PROCEDURE proc_vd_deli_l_dataset(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_vd_deli_l_dataset'; -- プログラム名
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
    lv_dlv_date_time     xxcos_vd_deliv_lines.dlv_date_time%TYPE;
    lv_set_dlv_date_time xxcos_vd_deliv_lines.dlv_date_time%TYPE;
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
    BEGIN
    
      SELECT  dlv_date_time
      INTO    lv_dlv_date_time
      FROM    xxcos_vd_deliv_lines xvdl
      WHERE   xvdl.customer_number = main_rec.customer_number
      AND     xvdl.dlv_date        = main_rec.dlv_date       
      AND     xvdl.column_num      = sub_main_rec.column_no
      AND     xvdl.item_code       = gv_search_item_code
      FOR UPDATE NOWAIT
      ;
      -- ===============================
      --ベンダ納品実績情報明細テーブル更新
      -- ===============================
      --訪問時刻判定
      IF lv_dlv_date_time > TO_DATE(TO_CHAR(main_rec.dlv_date,'YYYYMMDD') || NVL(main_rec.dlv_time,'0000') , 'YYYYMMDDHH24MI') THEN
        lv_set_dlv_date_time := lv_dlv_date_time;
      ELSE
        lv_set_dlv_date_time := TO_DATE(TO_CHAR(main_rec.dlv_date,'YYYYMMDD') || NVL(main_rec.dlv_time,'0000') , 'YYYYMMDDHH24MI');
      END IF;
    
      -- ===============================
      --ベンダ納品実績情報明細テーブル更新
      -- ===============================
      BEGIN
        UPDATE xxcos_vd_deliv_lines
        SET    sales_qty                  = sales_qty + NVL(sub_main_rec.replenish_number,0) --売上数
              ,dlv_date_time              = lv_set_dlv_date_time                      --納品日時
              ,last_updated_by            = cn_last_updated_by       
              ,last_update_date           = cd_last_update_date      
              ,last_update_login          = cn_last_update_login     
              ,request_id                 = cn_request_id            
              ,program_application_id     = cn_program_application_id
              ,program_id                 = cn_program_id            
              ,program_update_date        = cd_program_update_date   
        WHERE  customer_number            = main_rec.customer_number
        AND    dlv_date                   = main_rec.dlv_date       
        AND    column_num                 = sub_main_rec.column_no
        AND    item_code                  = gv_search_item_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                          ,ov_retcode     => lv_retcode                 --リターン・コード
                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                          ,ov_key_info    => gv_key_info                --キー情報
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                          ,iv_data_value1 => main_rec.customer_number   --データの値1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --項目名称2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD START  ******************************************
--                                          ,iv_data_value2 => main_rec.dlv_date          --データの値2
                                          ,iv_data_value2 => TO_CHAR(main_rec.dlv_date, 'YYYY/MM/DD')   --データの値2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD END    ******************************************
                                          ,iv_item_name3  => gv_msg_tkn_column_no       --項目名称3
                                          ,iv_data_value3 => sub_main_rec.column_no     --データの値3
                                          ,iv_item_name4  => gv_msg_tkn_item_code       --項目名称4
                                          ,iv_data_value4 => gv_search_item_code        --データの値4                                          
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_update_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_l
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errbuf --エラーメッセージ
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --エラーメッセージ
                           );
          RAISE update_error_expt;
      END;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- ===============================
      --ベンダ納品実績情報明細テーブル登録
      -- ===============================
        BEGIN
          lv_set_dlv_date_time := TO_DATE(TO_CHAR(main_rec.dlv_date,'YYYYMMDD') || NVL(main_rec.dlv_time,'0000') , 'YYYYMMDDHH24MI');
          
          INSERT INTO xxcos_vd_deliv_lines(
             customer_number          --顧客コード
            ,dlv_date                 --納品日
            ,column_num               --コラム№
            ,item_code                --品目コード
            ,standard_inv_qty         --基準在庫数
            ,hot_cold_type            --H/C
            ,sales_qty                --売上数
            ,dlv_date_time            --納品日時
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )VALUES(
             main_rec.customer_number        --顧客コード
            ,main_rec.dlv_date               --納品日
            ,sub_main_rec.column_no          --コラム№
            ,gv_search_item_code             --品目コード
            ,sub_main_rec.inventory_quantity --基準在庫数
            ,NVL(sub_main_rec.h_and_c,sub_main_rec.hot_cold) --H/C
            ,NVL(sub_main_rec.replenish_number,0)            --売上数
            ,lv_set_dlv_date_time   --納品日時
            ,cn_created_by
            ,cd_creation_date
            ,cn_last_updated_by
            ,cd_last_update_date
            ,cn_last_update_login
            ,cn_request_id
            ,cn_program_application_id
            ,cn_program_id
            ,cd_program_update_date
           );
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                            ,ov_retcode     => lv_retcode                 --リターン・コード
                                            ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info                --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                            ,iv_data_value1 => main_rec.customer_number   --データの値1
                                            ,iv_item_name2  => gv_msg_tkn_dlv_date        --項目名称2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD START  ******************************************
--                                            ,iv_data_value2 => main_rec.dlv_date          --データの値2
                                            ,iv_data_value2 => TO_CHAR(main_rec.dlv_date, 'YYYY/MM/DD')   --データの値2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD END    ******************************************
                                            ,iv_item_name3  => gv_msg_tkn_column_no       --項目名称3
                                            ,iv_data_value3 => sub_main_rec.column_no     --データの値3
                                            ,iv_item_name4  => gv_msg_tkn_item_code       --項目名称4
                                            ,iv_data_value4 => gv_search_item_code        --データの値4                                          
                                            );
            
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_insert_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_deliv_l
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --エラーメッセージ
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --エラーメッセージ
                             );
            RAISE global_api_others_expt;
        END;
      WHEN update_error_expt THEN
        RAISE global_api_others_expt;
        
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        IF (SQLCODE = cn_lock_error_code) THEN
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_lock
                                              , cv_tkn_lock
                                              , gv_msg_tkn_vd_deliv_l
                                               );
        ELSE
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                          ,ov_retcode     => lv_retcode                 --リターン・コード
                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                          ,ov_key_info    => gv_key_info                --キー情報
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                          ,iv_data_value1 => main_rec.customer_number   --データの値1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --項目名称2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD START  ******************************************
--                                          ,iv_data_value2 => main_rec.dlv_date          --データの値2
                                          ,iv_data_value2 => TO_CHAR(main_rec.dlv_date, 'YYYY/MM/DD')   --データの値2
-- ******************** 2009/06/10 Var.1.2 T.Tominaga MOD END    ******************************************
                                          ,iv_item_name3  => gv_msg_tkn_column_no       --項目名称3
                                          ,iv_data_value3 => sub_main_rec.column_no     --データの値3
                                          ,iv_item_name4  => gv_msg_tkn_item_code       --項目名称4
                                          ,iv_data_value4 => gv_search_item_code        --データの値4                                            
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_l
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
        END IF;
        
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.LOG
                         ,buff   => ov_errbuf --エラーメッセージ
                         );
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.OUTPUT
                         ,buff   => ov_errmsg --エラーメッセージ
                         );
        ov_retcode := cv_status_warn;
    END;
--
  EXCEPTION
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
  END proc_vd_deli_l_dataset;


  /**********************************************************************************
   * Procedure Name   : proc_status_update
   * Description      : A-8．VDコラム別取引ヘッダテーブルレコードロック
   *                    A-9．VDコラム別取引ヘッダテーブルステータス更新
   *
   ***********************************************************************************/
  PROCEDURE proc_status_update(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_status_update'; -- メインループ処理
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
    lv_rowid VARCHAR2(100);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

  
    <<lins_status_update>>
    FOR i IN 1..gn_main_loop_cnt LOOP
      -- ================================================
      -- A-8．VDコラム別取引ヘッダテーブルレコードロック
      -- ================================================    
      BEGIN
      
        SELECT ROWID
        INTO   lv_rowid
        FROM   xxcos_vd_column_headers xvch
        WHERE  xvch.order_no_hht        = gt_key(i).order_no_hht
        AND    xvch.digestion_ln_number = gt_key(i).digestion_ln_number
        FOR UPDATE NOWAIT;
        
        -- ================================================
        -- A-9．VDコラム別取引ヘッダテーブルステータス更新
        -- ================================================
        BEGIN
          UPDATE xxcos_vd_column_headers
          SET    vd_results_forward_flag    = cv_flag_on
                ,last_updated_by            = cn_last_updated_by       
                ,last_update_date           = cd_last_update_date      
                ,last_update_login          = cn_last_update_login     
                ,request_id                 = cn_request_id            
                ,program_application_id     = cn_program_application_id
                ,program_id                 = cn_program_id            
                ,program_update_date        = cd_program_update_date   
          WHERE  order_no_hht        = gt_key(i).order_no_hht
          AND    digestion_ln_number = gt_key(i).digestion_ln_number
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                            ,ov_retcode     => lv_retcode                 --リターン・コード
                                            ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info                --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_order_no_hht    --項目名称1
                                            ,iv_data_value1 => gt_key(i).order_no_hht     --データの値1
                                            ,iv_item_name2  => gv_msg_tkn_digestion_ln_no --項目名称2
                                            ,iv_data_value2 => gt_key(i).digestion_ln_number --データの値2
                                            );

            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_column_h
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
                                                
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --エラーメッセージ
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --エラーメッセージ
                             );
            gn_warn_tran_count := gn_warn_tran_count + 1;
            RAISE update_error_expt;
        END;

      EXCEPTION
        WHEN update_error_expt THEN
          RAISE global_api_others_expt;
        WHEN OTHERS THEN
          ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          IF (SQLCODE = cn_lock_error_code) THEN
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_lock
                                                , cv_tkn_lock
                                                , gv_msg_tkn_vd_column_h
                                                 );
          ELSE
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                            ,ov_retcode     => lv_retcode                 --リターン・コード
                                            ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info                --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_order_no_hht    --項目名称1
                                            ,iv_data_value1 => gt_key(i).order_no_hht     --データの値1
                                            ,iv_item_name2  => gv_msg_tkn_digestion_ln_no --項目名称2
                                            ,iv_data_value2 => gt_key(i).digestion_ln_number --データの値2
                                            );
            
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_select_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_column_h
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
          END IF;
          
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errbuf --エラーメッセージ
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --エラーメッセージ
                           );
          ov_retcode := cv_status_warn;
          gn_warn_tran_count := gn_warn_tran_count + 1;
      END;
      
    END LOOP lins_status_update;

    

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
  END proc_status_update;

  /**********************************************************************************
   * Procedure Name   : proc_main_loop（ループ部）
   * Description      : A-2．VDコラム別取引ヘッダテーブルデータ抽出
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- メインループ処理
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
    tran_in_exp      EXCEPTION;
    sub_tran_in_exp  EXCEPTION;
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message_code          VARCHAR2(20);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<main_loop>>
    FOR l_main_rec IN main_cur LOOP 
      main_rec := l_main_rec;
      gn_target_cnt := gn_target_cnt + 1;
      
      BEGIN
      -- ==================================================
      --A-9．VDコラム別取引ヘッダテーブルステータス更新
      -- ==================================================
        IF (main_rec.customer_number <> gv_bf_customer_number) THEN
          proc_status_update(
                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
                              ,lv_retcode  -- リターン・コード             --# 固定 #
                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                              );

          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- ================================================
          -- トランザクション制御
          -- ================================================
          --エラーカウント
          
          IF (gn_warn_tran_count > 0) THEN
            ROLLBACK;
            gn_warn_cnt := gn_warn_cnt + gn_tran_count;
            ov_errmsg := NULL;
            ov_errbuf := NULL;
          ELSE
            COMMIT;
            gn_normal_cnt := gn_normal_cnt + gn_tran_count;
          END IF;
          gn_warn_tran_count := 0;
          gn_tran_count      := 0;
          --PL/SQL表の初期化
          gt_key.DELETE;
          gn_main_loop_cnt := 0;
        END IF;

        -- ==================================================
        --A-3．ベンダ納品実績情報ヘッダテーブルキー情報保持
        -- ==================================================
        gn_main_loop_cnt := gn_main_loop_cnt + 1;
        gt_key(gn_main_loop_cnt).order_no_hht        := main_rec.order_no_hht;       
        gt_key(gn_main_loop_cnt).digestion_ln_number := main_rec.digestion_ln_number;

        -- ===============================
        --顧客コードブレイク判定
        -- ===============================
        --ブレイク判定キー入れ替え
        gv_bf_customer_number := main_rec.customer_number;
        
        gn_tran_count := gn_tran_count + 1;
        
        -- ===============================
        --A-4．ベンダ納品実績情報ヘッダテーブルデータ設定
        -- ===============================
        proc_vd_deli_h_dataset(
                             lv_errbuf   -- エラー・メッセージ           --# 固定 #
                            ,lv_retcode  -- リターン・コード             --# 固定 #
                            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                            );
        IF (lv_retcode = cv_status_warn) THEN
          RAISE tran_in_exp;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_api_others_expt;
        END IF;
                  
        -- ===============================
        --A-5．VDコラム別取引明細テーブルデータ抽出
        -- ===============================
        gn_sub_main_count := 0;
        <<sub_main_loop>>
        FOR l_sub_main_rec IN sub_main_cur LOOP
          sub_main_rec := l_sub_main_rec;
          gn_sub_main_count := gn_sub_main_count + 1;
          IF sub_main_rec.item_code_self IS NULL AND sub_main_rec.item_id IS NOT NULL THEN
          -- ===============================
          --A-6．品目マスタデータ抽出
          -- ===============================
            proc_inv_item_select(
                                 lv_errbuf   -- エラー・メッセージ           --# 固定 #
                                ,lv_retcode  -- リターン・コード             --# 固定 #
                                ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE tran_in_exp;
            END IF;
          ELSIF sub_main_rec.item_code_self IS NULL AND sub_main_rec.item_id IS NULL THEN
            gv_search_item_code := cv_blank_column_code;
          ELSE
            gv_search_item_code := sub_main_rec.item_code_self;
          END IF;
          -- ===============================
          --A-7．ベンダ納品実績情報明細テーブルデータ設定
          -- ===============================
          proc_vd_deli_l_dataset(
                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
                              ,lv_retcode  -- リターン・コード             --# 固定 #
                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                              );
          IF (lv_retcode = cv_status_warn) THEN
            RAISE tran_in_exp;
          ELSIF (lv_retcode = cv_status_error) THEN
            RAISE global_api_others_expt;
          END IF;
        END LOOP sub_main_loop;
        
        IF gn_sub_main_count = 0 THEN
        
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                          ,ov_retcode     => lv_retcode                 --リターン・コード
                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                          ,ov_key_info    => gv_key_info                --キー情報
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                          ,iv_data_value1 => main_rec.customer_number   --データの値1
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_sub_main_cur
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --エラーメッセージ
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errmsg --エラーメッセージ
                           );                           
          RAISE tran_in_exp;
        END IF;
        
      EXCEPTION
        WHEN tran_in_exp THEN
        --スキップ件数の加算
          gn_warn_tran_count := gn_warn_tran_count + 1;
          ov_retcode := cv_status_warn;
      END;
    END LOOP main_loop;
    IF gn_tran_count > 0 THEN
      proc_status_update(
                           lv_errbuf   -- エラー・メッセージ           --# 固定 #
                          ,lv_retcode  -- リターン・コード             --# 固定 #
                          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                          );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;                    

      -- ================================================
      -- トランザクション制御
      -- ================================================
      --エラーカウント
      
      IF (gn_warn_tran_count > 0) THEN
        ROLLBACK;
        gn_warn_cnt := gn_warn_cnt + gn_tran_count;
        ov_errmsg := NULL;
        ov_errbuf := NULL;
      ELSE
        COMMIT;
        gn_normal_cnt := gn_normal_cnt + gn_tran_count;
      END IF;
    END IF;

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
  END proc_main_loop;
--

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- <カーソル名>
--
    -- <カーソル名>レコード型
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
    -- ===============================
    -- Loop1 メイン　A-1データ抽出
    -- ===============================
    proc_main_loop(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_api_others_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)

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
       iv_which   => cv_log_header_out    
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
--
    -- ===============================================
    -- A-0．初期処理
    -- ===============================================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submainの呼び出し（実際の処理はsubmainで行う）
      -- ===============================================
      submain(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;

--
    -- ===============================================
    -- A-7．終了処理
    -- ===============================================
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCOS003A03C;
/
