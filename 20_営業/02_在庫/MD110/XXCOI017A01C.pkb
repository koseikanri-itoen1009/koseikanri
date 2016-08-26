CREATE OR REPLACE PACKAGE BODY XXCOI017A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI017A01C(body)
 * Description      : ロット別入出庫情報をワークフロー形式で配信します。
 * MD.050           : ロット別入出庫情報配信<MD050_COI_017_A01>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                              (A-1)
 *  output_data            CSV出力処理                           (A-2)
 *  upd_lot_transactions   ロット別取引明細更新処理              (A-3)
 *  submain                メイン処理プロシージャ
 *                         終了処理                              (A-4)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/08/03    1.0   S.Yamashita      新規作成
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
  cv_msg_sla                CONSTANT VARCHAR2(3) := '／';
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
  --*** ロックエラー ***
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI017A01C';              -- パッケージ名
  -- プロファイル
  cv_organization_code  CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  -- メッセージ関連
  cv_app_xxcoi          CONSTANT VARCHAR2(30)  := 'XXCOI';                -- アプリケーション短縮名(在庫)
  cv_msg_xxcoi_00005    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-00005';     -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi_00006    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-00006';     -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi_10039    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10039';     -- ロック取得エラーメッセージ
  cv_msg_xxcoi_10711    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10711';     -- ロット別入出庫情報配信コンカレント入力パラメータ
  cv_msg_xxcoi_10712    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10712';     -- ロット別取引明細テーブル更新エラー
  cv_msg_xxcoi_10715    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10715';     -- 日付逆転エラー
  cv_msg_xxcoi_10716    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10716';     -- 配信対象データなしエラーメッセージ
  -- トークン用メッセージ
  cv_msg_xxcoi_10713    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10713';     -- 取引日(From)
  cv_msg_xxcoi_10714    CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10714';     -- 取引日(To)
--
  --トークン
  cv_tkn_pro_tok         CONSTANT VARCHAR2(100) := 'PRO_TOK';            -- プロファイル
  cv_tkn_org_code_tok    CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';       -- 在庫組織コード
  cv_tkn_p_base_code     CONSTANT VARCHAR2(100) := 'P_BASE_CODE';        -- 入力パラメータ（拠点）
  cv_tkn_p_base_name     CONSTANT VARCHAR2(100) := 'P_BASE_NAME';        -- 入力パラメータ（拠点名）
  cv_tkn_p_trx_date_from CONSTANT VARCHAR2(100) := 'P_TRX_DATE_FROM';    -- 入力パラメータ（取引日(From)）
  cv_tkn_p_trx_date_to   CONSTANT VARCHAR2(100) := 'P_TRX_DATE_TO';      -- 入力パラメータ（取引日(To)）
  cv_tkn_item            CONSTANT VARCHAR2(100) := 'ITEM';               -- 項目名
  cv_tkn_err_msg         CONSTANT VARCHAR2(100) := 'ERR_MSG';            -- エラー内容
  cv_tkn_date_from       CONSTANT VARCHAR2(100) := 'DATE_FROM';          -- 日付(From)
  cv_tkn_date_to         CONSTANT VARCHAR2(100) := 'DATE_TO';            -- 日付(To)
--
  -- 参照タイプ
  cv_xxcoi017a01_target_type CONSTANT VARCHAR2(100) := 'XXCOI1_XXCOI017A01_TARGET_TYPE'; -- 参照タイプ:ロット別入出庫情報配信_対象取引タイプ
  -- 言語コード
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  --フォーマット
  cv_fmt_date           CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';
  cv_fmt_datetime       CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';
  -- 顧客関連
  cv_cust_cls_cd_base   CONSTANT VARCHAR2(1)   := '1';   -- 顧客区分:1(拠点)
  -- その他
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';   -- フラグ:'Y'
  cv_space              CONSTANT VARCHAR2(1)   := ' ';   -- 半角スペース１桁
  cv_separate_code      CONSTANT VARCHAR2(1)   := ',';   -- 区切り文字（カンマ）
  cv_sign_div_0         CONSTANT VARCHAR2(1)   := '0';   -- 符号区分:0(出庫)
  cv_sign_div_1         CONSTANT VARCHAR2(1)   := '1';   -- 符号区分:1(入庫)
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  -- 在庫組織コード
  gt_organization_id    mtl_parameters.organization_id%TYPE   DEFAULT NULL;  -- 在庫組織ID
  TYPE upd_trx_id_ttype IS TABLE OF xxcoi_lot_transactions.transaction_id%TYPE INDEX BY PLS_INTEGER;
  g_upd_trx_id_tab      upd_trx_id_ttype;               -- ロット別取引明細IDテーブル
--
  -- ===============================
  -- カーソル定義
  -- ===============================
  -- ロット別入出庫情報抽出
  CURSOR g_tran_info_cur (
    iv_p_base_code      xxcoi_hht_inv_transactions.base_code%TYPE -- 拠点コード
   ,id_p_trx_date_from  DATE -- 取引日(From)
   ,id_p_trx_date_to    DATE -- 取引日(To)
  )
  IS
    SELECT /*+ INDEX (xlt xxcoi_lot_transactions_n01) 
               LEADING (xlt) */
           xlt.transaction_id          AS transaction_id
          ,xlt.slip_num                AS slip_num
          ,TO_CHAR( xlt.transaction_date, cv_fmt_date ) AS transaction_date
          ,xlt.transaction_type_code   AS transaction_type_code
          ,CASE WHEN ( xlt.summary_qty < 0 ) THEN
             cv_sign_div_0  -- 0:出庫
           ELSE
             cv_sign_div_1  -- 1:入庫
           END                         AS conf_sign_div
          ,xlt.base_code               AS base_code
          ,xlt.subinventory_code       AS subinventory_code
          ,xlt.transfer_subinventory   AS transfer_subinventory
          ,msib.segment1               AS cild_item_code
          ,xlt.lot                     AS lot
          ,xlt.difference_summary_code AS difference_summary_code
          ,xlt.case_in_qty             AS case_in_qty
          ,xlt.case_qty                AS case_qty
          ,xlt.singly_qty              AS singly_qty
          ,xlt.summary_qty             AS summary_qty
          ,xlt.transaction_uom         AS transaction_uom
    FROM   xxcoi_lot_transactions     xlt   -- ロット別取引明細
          ,mtl_secondary_inventories  msi   -- 保管場所マスタ
          ,mtl_system_items_b         msib  -- DISC品目マスタ
          ,fnd_lookup_values          flv   -- 参照タイプ
    WHERE  xlt.child_item_id     = msib.inventory_item_id         -- 子品目ID
    AND    xlt.organization_id   = gt_organization_id             -- 組織ID
    AND    xlt.organization_id   = msib.organization_id           -- 組織ID
    AND    xlt.organization_id   = msi.organization_id            -- 組織ID
    AND    xlt.subinventory_code = msi.secondary_inventory_name   -- 保管場所
    AND    xlt.wf_delivery_flag  IS NULL                          -- WF配信済フラグ(未配信)
    AND    flv.lookup_type       = cv_xxcoi017a01_target_type
    AND    flv.lookup_code       = xlt.transaction_type_code      -- 対象取引タイプ
    AND    flv.language          = ct_lang                        -- 言語
    AND    flv.enabled_flag      = cv_y                           -- 有効フラグ
    AND    xlt.transaction_date  BETWEEN flv.start_date_active
                                   AND NVL(flv.end_date_active, xlt.transaction_date ) -- 有効日
    AND    xlt.transaction_date  BETWEEN id_p_trx_date_from AND id_p_trx_date_to  -- 取引日
    AND    xlt.base_code         = iv_p_base_code                -- 拠点
    AND    msi.attribute15       = cv_y                          -- WF配信対象フラグ(配信対象)
    ORDER BY
           xlt.slip_num                ASC -- 伝票No
          ,xlt.subinventory_code       ASC -- 保管場所コード
          ,conf_sign_div               ASC -- 符号区分
          ,msib.segment1               ASC -- 子品目コード
          ,xlt.lot                     ASC -- 賞味期限
          ,xlt.difference_summary_code ASC -- 固有記号
    FOR UPDATE OF
           xlt.transaction_id
    NOWAIT
  ;
  -- レコード型
  g_tran_info_rec  g_tran_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code       IN  VARCHAR2  -- 1.拠点
   ,id_trx_date_from   IN  DATE      -- 2.取引日(From)
   ,id_trx_date_to     IN  DATE      -- 3.取引日(To)
   ,ov_errbuf          OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lt_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  -- 在庫組織コード
    lt_base_name          hz_parties.party_name%TYPE            DEFAULT NULL;  -- 拠点名称
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
    -- 初期化
    lt_organization_code := NULL;
    lt_base_name         := NULL;
--
    --==================================
    -- 在庫組織ID取得
    --==================================
--
    -- 在庫組織コード取得
    lt_organization_code := FND_PROFILE.VALUE( cv_organization_code );
--
    IF ( lt_organization_code IS NULL ) THEN
      -- 在庫組織コード取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00005
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 在庫組織ID取得
    gt_organization_id := xxcoi_common_pkg.get_organization_id( lt_organization_code );
--
    IF ( gt_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00006
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => lt_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 拠点名称取得
    --==================================
    BEGIN
      SELECT hp.party_name AS base_name
      INTO   lt_base_name
      FROM   hz_parties       hp   -- パーティ
            ,hz_cust_accounts hca  -- 顧客マスタ
      WHERE  hca.customer_class_code = cv_cust_cls_cd_base
      AND    hca.account_number      = iv_base_code
      AND    hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_base_name := NULL;
    END;
--
    --==================================
    -- パラメータ出力
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => cv_app_xxcoi
                  ,iv_name               => cv_msg_xxcoi_10711
                  ,iv_token_name1        => cv_tkn_p_base_code
                  ,iv_token_value1       => iv_base_code
                  ,iv_token_name2        => cv_tkn_p_base_name
                  ,iv_token_value2       => lt_base_name
                  ,iv_token_name3        => cv_tkn_p_trx_date_from
                  ,iv_token_value3       => TO_CHAR( id_trx_date_from, cv_fmt_date )
                  ,iv_token_name4        => cv_tkn_p_trx_date_to
                  ,iv_token_value4       => TO_CHAR( id_trx_date_to, cv_fmt_date )
                 );
--
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => NULL
    );
--
    --==================================
    -- 日付逆転チェック
    --==================================
    IF ( id_trx_date_from > id_trx_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_app_xxcoi
                    ,iv_name               => cv_msg_xxcoi_10715
                    ,iv_token_name1        => cv_tkn_date_from
                    ,iv_token_value1       => cv_msg_xxcoi_10713
                    ,iv_token_name2        => cv_tkn_date_to
                    ,iv_token_value2       => cv_msg_xxcoi_10714
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : CSV出力処理 (A-2)
   ***********************************************************************************/
  PROCEDURE output_data(
    iv_base_code       IN  VARCHAR2  -- 1.拠点
   ,id_trx_date_from   IN  VARCHAR2  -- 2.取引日(From)
   ,id_trx_date_to     IN  VARCHAR2  -- 3.取引日(To)
   ,ov_errbuf          OUT VARCHAR2  -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT VARCHAR2  -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT VARCHAR2  -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    -- WF関連
    cv_ope_div_13         CONSTANT VARCHAR2(2)   := '13';  -- 処理区分:13(ロット別入出庫情報)
    cv_wf_class_8         CONSTANT VARCHAR2(1)   := '8';   -- 対象:8(拠点)
    -- IF項目
    cv_coop_name_itoen    CONSTANT VARCHAR2(5)   := 'ITOEN'; -- 会社名:ITOEN
    cv_data_type_600      CONSTANT VARCHAR2(3)   := '600';   -- データ種別:600(出庫)
    cv_data_type_610      CONSTANT VARCHAR2(3)   := '610';   -- データ種別:610(入庫)
    cv_branch_no_10       CONSTANT VARCHAR2(2)   := '10';    -- 伝送用枝番:10(ヘッダ)
    cv_branch_no_20       CONSTANT VARCHAR2(2)   := '20';    -- 伝送用枝番:20(明細)
    cv_data_kbn_0         CONSTANT VARCHAR2(1)   := '0';     -- データ区分:0(追加)
--
    -- *** ローカル変数 ***
    lr_wf_whs_rec        xxwsh_common3_pkg.wf_whs_rec; -- ファイル情報格納レコード
    lf_file_hand         UTL_FILE.FILE_TYPE;           -- ファイル・ハンドル
    lv_wf_notification   VARCHAR2(100);  -- 宛先
    lv_file_name         VARCHAR2(150);  -- ファイル名
    lv_csv_data          VARCHAR2(4000); -- CSV文字列
    lv_data_type         VARCHAR2(3);    -- データ種別
    lt_prev_slip_num     xxcoi_lot_transactions.slip_num%TYPE;          -- 前レコードの伝票番号
    lt_subinventory_code xxcoi_lot_transactions.subinventory_code%TYPE; -- 前レコードの保管場所コード
    lt_sign_div          xxcoi_lot_transactions.sign_div%TYPE;          -- 前レコードの符号区分
    ln_loop_cnt          NUMBER;         -- ループカウント
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
    -- 変数初期化
    lv_csv_data          := NULL;
    lt_prev_slip_num     := NULL;
    lt_subinventory_code := NULL;
    lt_sign_div          := NULL;
    ln_loop_cnt          := 0;
--
    --==================================
    -- ワークフロー情報取得
    --==================================
    lv_wf_notification := iv_base_code;        -- 宛先:対象拠点
--
    -- 共通関数「アウトバウンド処理取得関数」呼出
    xxwsh_common3_pkg.get_wsh_wf_info(
      iv_wf_ope_div       => cv_ope_div_13        -- 処理区分
     ,iv_wf_class         => cv_wf_class_8        -- 対象:'8'(拠点(ロット別入出庫情報配信))
     ,iv_wf_notification  => lv_wf_notification   -- 宛先
     ,or_wf_whs_rec       => lr_wf_whs_rec        -- ファイル情報
     ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ
     ,ov_retcode          => lv_retcode           -- リターン・コード
     ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ
    );
    IF
     ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ファイル名編集
    --==================================
    lv_file_name := cv_ope_div_13                                     -- 処理区分
                    || '-' || lv_wf_notification                      -- 宛先
                    || '_' || TO_CHAR( SYSDATE, 'YYYYMMDDHH24MISS' )  -- 処理時刻
                    || lr_wf_whs_rec.file_name                        -- ファイル名
    ;
--
    -- WFオーナーを起動ユーザへ変更
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    --==================================
    -- ファイルオープン
    --==================================
    lf_file_hand := UTL_FILE.FOPEN( lr_wf_whs_rec.directory -- ディレクトリ
                                   ,lv_file_name            -- ファイル名
                                   ,'w' )                   -- モード（上書）
    ;
--
    --==================================
    -- ロット別入出庫情報抽出
    --==================================
    <<tran_info_loop>>
    FOR g_tran_info_rec IN g_tran_info_cur ( iv_p_base_code     => iv_base_code      -- 拠点コード
                                            ,id_p_trx_date_from => id_trx_date_from  -- 取引日(From)
                                            ,id_p_trx_date_to   => id_trx_date_to    -- 取引日(To)
                                           )
    LOOP
      -- 終了判定
      EXIT tran_info_loop WHEN g_tran_info_cur%NOTFOUND;
--
      --==================================
      -- ロット別入出庫情報 CSV出力
      --==================================
--
      -- データ種別の設定
      IF ( g_tran_info_rec.conf_sign_div = cv_sign_div_0 ) THEN
        -- 出庫
        lv_data_type := cv_data_type_600;
        -- 数量をプラスに変換
        g_tran_info_rec.case_qty    := g_tran_info_rec.case_qty    * (-1);
        g_tran_info_rec.singly_qty  := g_tran_info_rec.singly_qty  * (-1);
        g_tran_info_rec.summary_qty := g_tran_info_rec.summary_qty * (-1);
      ELSE
        -- 入庫
        lv_data_type := cv_data_type_610;
      END IF;
--
      -- 1レコード目の場合、
      -- または前レコードとキー項目（伝票No、保管場所コード、符号区分）が異なる場合、
      -- または伝票NoがNULL(在庫調整)の場合
      IF (( lt_prev_slip_num IS NULL )
        OR ( g_tran_info_rec.slip_num          <> lt_prev_slip_num )
        OR ( g_tran_info_rec.subinventory_code <> lt_subinventory_code )
        OR ( g_tran_info_rec.conf_sign_div     <> lt_sign_div )
        OR ( g_tran_info_rec.slip_num IS NULL ))
      THEN
        -- ヘッダ行
        lv_csv_data := cv_coop_name_itoen                    -- 会社名
                    || cv_separate_code
                    || lv_data_type                          -- データ種別
                    || cv_separate_code
                    || cv_branch_no_10                       -- 伝送用枝番
                    || cv_separate_code
                    || g_tran_info_rec.slip_num              -- 伝票No
                    || cv_separate_code
                    || g_tran_info_rec.transaction_date      -- 取引日
                    || cv_separate_code
                    || g_tran_info_rec.transaction_type_code -- 取引タイプコード
                    || cv_separate_code
                    || g_tran_info_rec.conf_sign_div         -- 符号区分
                    || cv_separate_code
                    || g_tran_info_rec.base_code             -- 拠点コード
                    || cv_separate_code
                    || g_tran_info_rec.subinventory_code     -- 保管場所コード
                    || cv_separate_code
                    || g_tran_info_rec.transfer_subinventory -- 転送先保管場所コード
                    || cv_separate_code
                    || '' -- 子品目コード
                    || cv_separate_code
                    || '' -- 賞味期限
                    || cv_separate_code
                    || '' -- 固有記号
                    || cv_separate_code
                    || '' -- 入数
                    || cv_separate_code
                    || '' -- ケース数
                    || cv_separate_code
                    || '' -- バラ数
                    || cv_separate_code
                    || '' -- 取引数量
                    || cv_separate_code
                    || '' -- 基準単位
                    || cv_separate_code
                    || '' -- データ区分
                    || cv_separate_code
                    || TO_CHAR( SYSDATE, cv_fmt_datetime )   -- 更新日時
        ;
--
        -- ファイル出力
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
      END IF;
--
      -- 明細行
      lv_csv_data := cv_coop_name_itoen                    -- 会社名
                  || cv_separate_code
                  || lv_data_type                          -- データ種別
                  || cv_separate_code
                  || cv_branch_no_20                       -- 伝送用枝番
                  || cv_separate_code
                  || g_tran_info_rec.slip_num              -- 伝票No
                  || cv_separate_code
                  || '' -- 取引日
                  || cv_separate_code
                  || '' -- 取引タイプコード
                  || cv_separate_code
                  || '' -- 符号区分
                  || cv_separate_code
                  || '' -- 拠点コード
                  || cv_separate_code
                  || '' -- 保管場所コード
                  || cv_separate_code
                  || '' -- 転送先保管場所コード
                  || cv_separate_code
                  || g_tran_info_rec.cild_item_code          -- 子品目コード
                  || cv_separate_code
                  || g_tran_info_rec.lot                     -- 賞味期限
                  || cv_separate_code
                  || g_tran_info_rec.difference_summary_code -- 固有記号
                  || cv_separate_code
                  || g_tran_info_rec.case_in_qty             -- 入数
                  || cv_separate_code
                  || g_tran_info_rec.case_qty                -- ケース数
                  || cv_separate_code
                  || g_tran_info_rec.singly_qty              -- バラ数
                  || cv_separate_code
                  || g_tran_info_rec.summary_qty             -- 取引数量
                  || cv_separate_code
                  || g_tran_info_rec.transaction_uom         -- 基準単位
                  || cv_separate_code
                  || cv_data_kbn_0                           -- データ区分
                  || cv_separate_code
                  || TO_CHAR( SYSDATE, cv_fmt_datetime )     -- 更新日時
      ;
--
      -- ファイル出力
      UTL_FILE.PUT_LINE(
        lf_file_hand
       ,lv_csv_data
      );
--
      -- キー項目を保持
      lt_prev_slip_num     := g_tran_info_rec.slip_num;
      lt_subinventory_code := g_tran_info_rec.subinventory_code;
      lt_sign_div          := g_tran_info_rec.conf_sign_div;
      -- 取引IDを保持(フラグ更新用)
      g_upd_trx_id_tab(ln_loop_cnt)  := g_tran_info_rec.transaction_id;
--
      -- 件数カウント
      ln_loop_cnt := ln_loop_cnt + 1;
--
    END LOOP tran_info_loop;
--
    -- 対象件数カウント
    gn_target_cnt := ln_loop_cnt;
--
    --==================================
    -- ファイルクローズ
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- 対象件数が存在する場合はワークフロー通知を実行
    IF ( gn_target_cnt <> 0 ) THEN
      --==================================
      -- ワークフロー通知
      --==================================
      xxwsh_common3_pkg.wf_whs_start(
        ir_wf_whs_rec => lr_wf_whs_rec      -- ワークフロー関連情報
       ,iv_filename   => lv_file_name       -- ファイル名
       ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ
       ,ov_retcode    => lv_retcode         -- リターン・コード
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
    ELSE
      -- 対象件数が0件の場合は警告
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10716
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ロック例外ハンドラ ***--
    WHEN global_lock_expt THEN
      -- ファイルクローズ
      UTL_FILE.FCLOSE( lf_file_hand );
      -- メッセー取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10039
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_transactions
   * Description      : ロット別取引明細更新 (A-3)
   ***********************************************************************************/
  PROCEDURE upd_lot_transactions(
    ov_errbuf          OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2    -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
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
    --==================================
    -- ロット別取引明細更新
    --==================================
    << update_loop >>
    FOR i IN 0 .. g_upd_trx_id_tab.COUNT -1 LOOP
      BEGIN
        UPDATE  xxcoi_lot_transactions xlt
        SET     xlt.wf_delivery_flag          =   cv_y --WF配信済フラグ(配信済)
               ,xlt.last_update_date          =   cd_last_update_date
               ,xlt.last_updated_by           =   cn_last_updated_by
               ,xlt.last_update_login         =   cn_last_update_login
               ,xlt.request_id                =   cn_request_id
               ,xlt.program_id                =   cn_program_id
               ,xlt.program_application_id    =   cn_program_application_id
               ,xlt.program_update_date       =   cd_last_update_date
        WHERE   xlt.transaction_id  =  g_upd_trx_id_tab(i)
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ロット別取引明細更新エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_xxcoi
                 ,iv_name         => cv_msg_xxcoi_10712
                 ,iv_token_name1  => cv_tkn_err_msg
                 ,iv_token_value1 => SQLERRM
               );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END LOOP update_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
  END upd_lot_transactions;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   *                    終了処理 (A-3)
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2    -- 1.拠点
   ,id_trx_date_from   IN  DATE        -- 2.取引日(From)
   ,id_trx_date_to     IN  DATE        -- 3.取引日(To)
   ,ov_errbuf          OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2    -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  初期処理(A-1)
    -- ===============================
    init(
      iv_base_code      =>  iv_base_code      -- 1.拠点
     ,id_trx_date_from  =>  id_trx_date_from  -- 2.取引日(From)
     ,id_trx_date_to    =>  id_trx_date_to    -- 3.取引日(To)
     ,ov_errbuf         =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        =>  lv_retcode        -- リターン・コード             --# 固定 #
     ,ov_errmsg         =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- CSV出力処理(A-2)
    --==================================
    output_data(
      iv_base_code          =>  iv_base_code      -- 1.拠点
     ,id_trx_date_from      =>  id_trx_date_from  -- 2.取引日(From)
     ,id_trx_date_to        =>  id_trx_date_to    -- 3.取引日(To)
     ,ov_errbuf             =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            =>  lv_retcode        -- リターン・コード             --# 固定 #
     ,ov_errmsg             =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラーの場合
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      -- 警告(配信対象データなし)の場合
      ov_retcode := lv_retcode;
    ELSE
      -- 正常の場合
      --==================================
      -- ロット別取引明細更新処理(A-3)
      --==================================
      upd_lot_transactions(
        ov_errbuf             =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            =>  lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg             =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
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
    errbuf                OUT VARCHAR2    -- エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2    -- リターン・コード    --# 固定 #
   ,iv_base_code          IN  VARCHAR2    -- 1.拠点
   ,iv_trx_date_from      IN  VARCHAR2    -- 2.取引日(From)
   ,iv_trx_date_to        IN  VARCHAR2    -- 3.取引日(To)
   
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
       ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
        iv_base_code       =>  iv_base_code      -- 1.拠点
       ,id_trx_date_from   =>  TO_DATE(iv_trx_date_from, cv_fmt_datetime ) -- 2.取引日(From)
       ,id_trx_date_to     =>  TO_DATE(iv_trx_date_to, cv_fmt_datetime )   -- 3.取引日(To)
       ,ov_errbuf          =>  lv_errbuf         -- エラー・メッセージ             --# 固定 #
       ,ov_retcode         =>  lv_retcode        -- リターン・コード               --# 固定 #
       ,ov_errmsg          =>  lv_errmsg         -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- 処理件数(エラー)
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- 処理件数(警告)
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
    ELSE
      -- 処理件数(正常)
      gn_normal_cnt := gn_target_cnt;
    END IF;
    --
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
    -- 空行を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
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
END XXCOI017A01C;
/
