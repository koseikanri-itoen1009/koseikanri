create or replace
PACKAGE BODY XXCOI009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A03R(body)
 * Description      : 工場入庫明細リスト
 * MD.050           : 工場入庫明細リスト MD050_COI_009_A03
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ワークテーブルデータ削除(A-6)
 *  svf_request            SVF起動(A-5)
 *  ins_work               ワークテーブルデータ登録(A-4)
 *  get_kojo_data          工場入庫明細情報取得処理(A-3)
 *  get_base_data          拠点情報取得処理(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   K.Tsuboi         新規作成
 *  2009/03/02    1.1   K.Tsuboi         [障害番号028]品目コードに対応する略称が表示されない点について修正
 *                                       [障害番号029]標準原価額に取引数量×標準原価の計算値を設定する
 *  2009/04/22    1.2   T.Nakamura       [障害T1_0491]資材品目のみ抽出対象となる取引タイプを変更
 *  2009/05/21    1.3   T.Nakamura       [障害T1_1111]取引タイプの絞込条件から梱包材料原価振替、梱包材料原価振替振戻を除外
 *  2009/07/22    1.4   N.Abe            [障害0000785]リーフ資材品を商品、製品抽出時の除外条件に追加
 *  2009/08/05    1.5   H.Sasaki         [障害0000926]品目カテゴリの印字制御のための修正
 *  2009/09/08    1.6   H.Sasaki         [障害0001266]OPM品目アドオンの版管理対応
 *  2009/10/22    1.7   H.Sasaki         [障害E_T4_00057]資材品目の取得方法変更
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
  get_value_expt            EXCEPTION;    -- 値取得エラー
  lock_expt                 EXCEPTION;    -- ロック取得エラー
  get_no_data_expt          EXCEPTION;    -- 取得データ0件
  get_no_data_expt          EXCEPTION;    -- 対象データ0件
  svf_request_err_expt      EXCEPTION;    -- SVF起動APIエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI009A03R';   -- パッケージ名
  cv_app_name      CONSTANT VARCHAR2(5)   := 'XXCOI';          -- アプリケーション短縮名
  cv_0             CONSTANT VARCHAR2(1)   := '0';              -- 定数
  cv_1             CONSTANT VARCHAR2(1)   := '1';              -- 定数
  cv_2             CONSTANT VARCHAR2(1)   := '2';              -- 定数
  cv_3             CONSTANT VARCHAR2(1)   := '3';              -- 定数
  cv_4             CONSTANT VARCHAR2(1)   := '4';              -- 定数
  cv_log               CONSTANT VARCHAR2(3)   := 'LOG';            -- コンカレントヘッダ出力先
--
  -- メッセージ
  cv_msg_xxcoi00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0件メッセージ
  cv_msg_xxcoi10003  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10003';   -- 日付入力エラー
  cv_msg_xxcoi00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- 在庫組織コード取得エラー
  cv_msg_xxcoi00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- 在庫組織ID取得エラー
  cv_msg_xxcoi00011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';   -- 業務日付取得エラー
  cv_msg_xxcoi10022  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00022';   -- 取引タイプ名取得エラー
  cv_msg_xxcoi10012  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00012';   -- 取引タイプ取得エラー
  cv_msg_xxcoi10069  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10069';   -- 日付範囲(年月)エラー
  cv_msg_xxcoi10092  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10092';   -- 所属拠点取得エラー
  cv_msg_xxcoi10081  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10081';   -- パラメータ.年月メッセージ
  cv_msg_xxcoi10082  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10082';   -- パラメータ.入庫拠点メッセージ
  cv_msg_xxcoi10083  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10083';   -- パラメータ.品目カテゴリメッセージ
  cv_msg_xxcoi10285  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10285';   -- 標準原価取得失敗エラー
--
  -- トークン名
  cv_token_pro       CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code  CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_date      CONSTANT VARCHAR2(30) := 'P_DATE';
  cv_token_base_code CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_token_item_ctg  CONSTANT VARCHAR2(30) := 'P_ITEM_CTG';
  cv_tkn_lookup_type CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';            -- 参照タイプ
  cv_tkn_lookup_code CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';            -- 参照コード
  cv_tkn_tran_type   CONSTANT VARCHAR2(20) := 'TRANSACTION_TYPE_TOK';   -- 取引タイプ
  cv_tkn_item_code   CONSTANT VARCHAR2(20) := 'ITEM_CODE';
--
    -- カテゴリセット名
  cv_category_hinmoku  CONSTANT VARCHAR2(8)   := '品目区分';
  cv_category_seishou  CONSTANT VARCHAR2(12)  := '商品製品区分';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE gr_param_rec  IS RECORD(
      year_month        VARCHAR2(7)       -- 01 : 処理年月    （必須)
     ,in_kyoten         VARCHAR2(4)       -- 02 : 入庫拠点    （任意)
     ,item_ctg          VARCHAR2(1)       -- 03 : カテゴリコード(任意)
     ,output_dpt        VARCHAR2(1)       -- 04 : 帳票出力場所(任意)
    );
--
  -- 拠点情報格納用レコード変数
  TYPE gr_base_num_rec IS RECORD
    (
      hca_cust_num                   hz_cust_accounts.account_number%TYPE    -- 拠点コード
    );
--
  --  拠点情報格納用テーブル
  TYPE gt_base_num_ttype IS TABLE OF gr_base_num_rec INDEX BY BINARY_INTEGER;
--
  -- 工場入庫情報格納用レコード変数
  TYPE gr_kojo_nyuko_rec IS RECORD
    (
      msi_attribute7                mtl_secondary_inventories.attribute7%TYPE            -- 入庫拠点コード
     ,hca_account_number            hz_cust_accounts.account_number%TYPE                -- 入庫拠点名
     ,mmt_inventory_item_id         mtl_material_transactions.inventory_item_id%TYPE     -- 品目ID
     ,mmt_transaction_quantity      mtl_material_transactions.transaction_quantity%TYPE  -- 取引数量
     ,mmt_transaction_date          mtl_material_transactions.transaction_date%TYPE      -- 取引日
     ,msib_segment1                 mtl_system_items_b.segment1%TYPE                     -- 品目名
     ,ximb_item_short_name          xxcmn_item_mst_b.item_short_name%TYPE                -- 品目略称
--     ,                              --品目カテゴリコード
--
    );
  --  工場入庫情報格納用テーブル
  TYPE gt_kojo_nyuko_ttype IS TABLE OF gr_kojo_nyuko_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE;                                           -- 業務日付
  gv_base_code              hz_cust_accounts.account_number%TYPE;           -- 拠点コード
  -- カウンタ
  gn_base_cnt               NUMBER;                                         -- 拠点コード件数
  gn_base_loop_cnt          NUMBER;                                         -- 拠点コードループカウンタ
  gn_kojo_nyuko_cnt         NUMBER;                                         -- 工場入庫情報件数
  gn_kojo_nyuko_loop_cnt    NUMBER;                                         -- 工場入庫情報ループカウンタ
  gn_organization_id        mtl_parameters.organization_id%TYPE;            -- 在庫組織ID
  --
  gr_param                  gr_param_rec;
  gt_base_num_tab           gt_base_num_ttype;
  gt_kojo_nyuko_tab         gt_kojo_nyuko_ttype;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ワークテーブルデータ削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_work(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_work'; -- プログラム名
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
    --帳票用ワークテーブルから削除
    DELETE xxcoi_rep_factory_store_list xrw
    WHERE  xrw.request_id = cn_request_id
    ;
--
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
  END del_work;
--
  /**********************************************************************************
   * Procedure Name   : svf_request
   * Description      : SVF起動(A-5)
   ***********************************************************************************/
  PROCEDURE svf_request(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_request'; -- プログラム名
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
    cv_output_mode  CONSTANT VARCHAR2(1)  := '1';                    -- 出力区分(PDF出力)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI009A03S.xml';   -- フォーム様式ファイル名
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI009A03S.vrq';   -- クエリー様式ファイル名
    cv_api_name     CONSTANT VARCHAR2(7)  := 'SVF起動';              -- SVF起動API名
--
    -- エラーコード
    cv_msg_xxcoi00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- APIエラー
--
    -- トークン名
    cv_token_name_1  CONSTANT VARCHAR2(30) := 'API_NAME';
--
    -- *** ローカル変数 ***
    ld_date       VARCHAR2(8);   -- 日付
    lv_file_name  VARCHAR2(100); -- 出力ファイル名
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
    -- 日付書式変換
    ld_date := TO_CHAR( cd_creation_date, 'YYYYMMDD' );
--
    -- 出力ファイル名
    lv_file_name := cv_pkg_name || ld_date || TO_CHAR(cn_request_id);
--
    --SVF起動処理
      xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode      => lv_retcode            -- リターンコード
     ,ov_errbuf       => lv_errbuf             -- エラーメッセージ
     ,ov_errmsg       => lv_errmsg             -- ユーザー・エラーメッセージ
     ,iv_conc_name    => cv_pkg_name           -- コンカレント名
     ,iv_file_name    => lv_file_name          -- 出力ファイル名
     ,iv_file_id      => cv_pkg_name           -- 帳票ID
     ,iv_output_mode  => cv_output_mode        -- 出力区分
     ,iv_frm_file     => cv_frm_file           -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_vrq_file           -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => fnd_global.user_name  -- ログイン・ユーザ名
     ,iv_resp_name    => fnd_global.resp_name  -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
    );
--
    --==============================================================
    --エラーメッセージ出力
    --==============================================================
    IF lv_retcode <> cv_status_normal THEN
      RAISE svf_request_err_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** SVF起動APIエラー ***
    WHEN svf_request_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                    , iv_name         => cv_msg_xxcoi00010
                    , iv_token_name1  => cv_token_name_1
                    , iv_token_value1 => cv_api_name
                   );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END svf_request;
--
  /**********************************************************************************
   * Procedure Name   : ins_work
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work(
    iv_store_base_code    IN mtl_secondary_inventories.attribute1%TYPE,
    iv_store_base_name    IN hz_cust_accounts.account_name%TYPE,
    iv_item_ctg           IN mtl_categories_b.segment1%TYPE,
    iv_item_code          IN mtl_system_items_b.segment1%TYPE,
    iv_item_name          IN xxcmn_item_mst_b.item_short_name%TYPE,
    in_trn_qty            IN mtl_material_transactions.transaction_quantity%TYPE,
    in_stand_cost         IN NUMBER,
    iv_prm_flg            IN VARCHAR2,
    iv_nodata_msg         IN VARCHAR2,
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --工場入庫明細リスト帳票ワークテーブル登録処理
    INSERT INTO xxcoi_rep_factory_store_list(
       target_term
      ,store_base_code
      ,store_base_name
      ,item_ctg
      ,item_code
      ,item_name
      ,trn_qty
      ,stand_cost
      ,prm_flg
      ,nodata_msg
      --WHOカラム
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
       gr_param.year_month                       -- 対象年月
      ,iv_store_base_code                        -- 入庫拠点
      ,iv_store_base_name                        -- 入庫拠点名
      ,iv_item_ctg                               -- 品目カテゴリコード
      ,iv_item_code                              -- 商品
      ,iv_item_name                              -- 略称
      ,in_trn_qty                                -- 取引数量
      ,in_stand_cost                             -- 原価額
      ,iv_prm_flg                                -- パラメータフラグ
      ,iv_nodata_msg                             -- 0件メッセージ
      --WHOカラム
      ,cn_created_by
      ,sysdate
      ,cn_last_updated_by
      ,sysdate
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,sysdate
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
  END ins_work;
--
  /**********************************************************************************
   * Procedure Name   : get_kojo_data（ループ部）
   * Description      : 工場入庫明細情報(A-3)
   ***********************************************************************************/
  PROCEDURE get_kojo_data(
    gn_base_loop_cnt IN NUMBER,       --   カウント
    ov_errbuf        OUT VARCHAR2,    --   エラー・メッセージ                --# 固定 #
    ov_retcode       OUT VARCHAR2,    --   リターン・コード                  --# 固定 #
    ov_errmsg        OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fact_data'; -- プログラム名
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
    -- 参照タイプ
    -- ユーザー定義取引タイプ名称
    cv_tran_type                   CONSTANT VARCHAR2(30)  := 'XXCOI1_TRANSACTION_TYPE_NAME';
--
    -- 参照コード
    cv_tran_type_factory_store     CONSTANT VARCHAR2(3)   := '150';  -- 取引タイプコード 工場入庫
    cv_tran_type_factory_store_b   CONSTANT VARCHAR2(3)   := '160';  -- 取引タイプコード 工場入庫振戻
-- == 2009/04/22 V1.2 Added START ===============================================================
    cv_tran_type_packing_temp      CONSTANT VARCHAR2(3)   := '250';  -- 取引タイプコード 梱包材料一時受入
    cv_tran_type_packing_temp_b    CONSTANT VARCHAR2(3)   := '260';  -- 取引タイプコード 梱包材料一時受入振戻
-- == 2009/05/21 V1.3 Deleted START =============================================================
--    cv_tran_type_packing_cost      CONSTANT VARCHAR2(3)   := '270';  -- 取引タイプコード 梱包材料原価振替
--    cv_tran_type_packing_cost_b    CONSTANT VARCHAR2(3)   := '280';  -- 取引タイプコード 梱包材料原価振替振戻
-- == 2009/05/21 V1.3 Deleted END   =============================================================
-- == 2009/04/22 V1.2 Added END   ===============================================================
--
    -- *** ローカル変数 ***
    lv_tran_type_factory_store     mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 工場入庫
    ln_tran_type_factory_store     mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 工場入庫
    lv_tran_type_factory_store_b   mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 工場入庫振戻
    ln_tran_type_factory_store_b   mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 工場入庫振戻
    lv_base_code                   hz_cust_accounts.account_number%TYPE DEFAULT  NULL; -- 入庫拠点コード判別用
    lv_item_code                   mtl_system_items_b.segment1%TYPE DEFAULT  NULL;     -- 商品コード判別用
    lv_item_short_name             xxcmn_item_mst_b.item_short_name%TYPE DEFAULT  NULL; -- 商品略称保持用
    lv_item_category               mtl_categories_b.segment1%TYPE DEFAULT  NULL;        -- カテゴリコード保持用
    ln_tran_qty                    mtl_material_transactions.transaction_quantity%TYPE DEFAULT  0; -- 取引数量
    lv_cmpnt_cost                  VARCHAR2(30) DEFAULT  NULL;                                       -- 標準原価
    ln_cmpnt_cost_sum              NUMBER       DEFAULT  0;                                       -- 標準原価
    ln_cnt                         NUMBER       DEFAULT  0;          -- ループカウンタ
    lv_zero_message                VARCHAR2(30) DEFAULT  NULL;       -- ゼロ件メッセージ
    ln_sql_cnt                     NUMBER       DEFAULT  0;
    ln_cmpnt_cost                  NUMBER       DEFAULT  0;                                       -- 標準原価
-- == 2009/04/22 V1.2 Added START ===============================================================
    lv_tran_type_packing_temp      mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 梱包材料一時受入
    ln_tran_type_packing_temp      mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 梱包材料一時受入
    lv_tran_type_packing_temp_b    mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 梱包材料一時受入振戻
    ln_tran_type_packing_temp_b    mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 梱包材料一時受入振戻
-- == 2009/05/21 V1.3 Deleted START =============================================================
--    lv_tran_type_packing_cost      mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 梱包材料原価振替
--    ln_tran_type_packing_cost      mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 梱包材料原価振替
--    lv_tran_type_packing_cost_b    mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 梱包材料原価振替振戻
--    ln_tran_type_packing_cost_b    mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 梱包材料原価振替振戻
-- == 2009/05/21 V1.3 Deleted END   =============================================================
-- == 2009/04/22 V1.2 Added END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 工場入庫明細情報
-- == 2009/04/22 V1.2 Moded START ===============================================================
--    CURSOR info_fact_cur(tran_type1 NUMBER,tran_type2 NUMBER)
    CURSOR info_fact_cur(
               tran_type1 NUMBER
             , tran_type2 NUMBER
             , tran_type3 NUMBER
             , tran_type4 NUMBER
-- == 2009/05/21 V1.3 Deleted START =============================================================
--             , tran_type5 NUMBER
--             , tran_type6 NUMBER
-- == 2009/05/21 V1.3 Deleted END   =============================================================
           )
-- == 2009/04/22 V1.2 Moded END   ===============================================================
    IS
      SELECT  msi.attribute7                in_base_code                   -- 入庫拠点
             ,SUBSTRB(hca.account_name,1,8) account_name                   -- 入庫拠点名
             ,mmt.inventory_item_id         inventory_item_id              -- 品目ID
             ,mmt.transaction_quantity      transaction_qty                -- 取引数量
             ,mmt.transaction_date          transaction_date               -- 取引日
             ,msib.segment1                 item_no                        -- 品目コード
             ,ximb.item_short_name          item_short_name                -- 略称
             ,cat.item_category             item_category                  -- 品目カテゴリコード
      FROM    mtl_secondary_inventories     msi                            -- 保管場所マスタ
             ,hz_cust_accounts              hca                            -- 顧客マスタ
             ,mtl_material_transactions     mmt                            -- 資材取引
             ,mtl_system_items_b            msib                           -- 品目マスタ
             ,ic_item_mst_b                 iimb                           -- OPM品目マスタ
             ,xxcmn_item_mst_b              ximb                           -- OPM品目アドオンマスタ
             ,( 
-- == 2009/10/22 V1.7 Modified START ===============================================================
--               SELECT msib.segment1          item_no                    -- 品目コード
--                      ,decode(mcb.segment1,cv_2,cv_3 )   item_category  -- 品目カテゴリコード
--               FROM   mtl_system_items_b     msib                  -- 品目マスタ
--                     ,mtl_category_sets_b    mcsb                  -- 品目カテゴリセット
--                     ,mtl_category_sets_tl   mcst                  -- 品目カテゴリセット日本語
--                     ,mtl_categories_b       mcb                   -- 品目カテゴリマスタ
--                     ,mtl_item_categories    mic                   -- 品目カテゴリ割当
--               WHERE  msib.inventory_item_id =  mic.inventory_item_id
--                 AND  mcb.category_id        =  mic.category_id
--                 AND  mcsb.category_set_id   =  mic.category_set_id
--                 AND  mcb.structure_id       =  mcsb.structure_id
--                 AND  mcst.category_set_id   =  mcsb.category_set_id
--                 AND  mcst.language          =  USERENV( 'LANG' )
--                 AND  mcst.category_set_name =  cv_category_hinmoku
--                 AND  mcb.segment1           =  cv_2
--                 AND  mic.organization_id    =  gn_organization_id
--                 AND  msib.organization_id   =   mic.organization_id
               SELECT msib.segment1                       item_no         -- 品目コード
                     ,cv_3                                item_category   -- 品目カテゴリコード
               FROM   mtl_system_items_b      msib                        -- 品目マスタ
               WHERE  msib.organization_id    =   gn_organization_id
               AND    (   msib.segment1 LIKE '5%'
                       OR msib.segment1 LIKE '6%'
                      )
-- == 2009/10/22 V1.7 Modified END   ===============================================================
             UNION
               SELECT msib.segment1          item_no               -- 品目コード
                     ,mcb.segment1           item_category         -- 品目カテゴリコード
               FROM   mtl_system_items_b     msib                  -- 品目マスタ
                     ,mtl_category_sets_b    mcsb                  -- 品目カテゴリセット
                     ,mtl_category_sets_tl   mcst                  -- 品目カテゴリセット日本語
                     ,mtl_categories_b       mcb                   -- 品目カテゴリマスタ
                     ,mtl_item_categories    mic                   -- 品目カテゴリ割当
               WHERE  msib.inventory_item_id =  mic.inventory_item_id
                 AND  mcb.category_id        =  mic.category_id
                 AND  mcsb.category_set_id   =  mic.category_set_id
                 AND  mcb.structure_id       =  mcsb.structure_id
                 AND  mcst.category_set_id   =  mcsb.category_set_id
                 AND  mcst.language          =  USERENV( 'LANG' )
                 AND  mcst.category_set_name =  cv_category_seishou
                 AND  mic.organization_id    =  gn_organization_id
                 AND  msib.organization_id   =   mic.organization_id
-- == 2009/04/22 V1.2 Added START ===============================================================
                 AND NOT EXISTS( SELECT '1'
                                 FROM   mtl_system_items_b     msib2
                                 WHERE  msib.inventory_item_id =  msib2.inventory_item_id
                                 AND    msib.organization_id   =  msib2.organization_id
-- == 2009/07/22 V1.4 Moded START ===============================================================
--                                 AND    msib2.segment1         LIKE  '6%'
                                 AND    (msib2.segment1         LIKE  '6%'
                                   OR    msib2.segment1         LIKE  '5%'
                                        )
-- == 2009/07/22 V1.4 Moded END   ===============================================================
                               )
-- == 2009/04/22 V1.2 Added END   ===============================================================
               ) cat
      WHERE  TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month
-- == 2009/04/22 V1.2 Moded START ===============================================================
--        AND  mmt.transaction_type_id IN (tran_type1, tran_type2)
-- == 2009/05/21 V1.3 Moded START ===============================================================
        AND ( ( cat.item_category       IN (cv_1, cv_2)
            AND mmt.transaction_type_id IN (tran_type1, tran_type2) )
          OR  ( cat.item_category       =   cv_3
--            AND mmt.transaction_type_id IN (tran_type3, tran_type4, tran_type5, tran_type6) ) )
            AND mmt.transaction_type_id IN (tran_type3, tran_type4) ) )
-- == 2009/05/21 V1.3 Moded END   ===============================================================
-- == 2009/04/22 V1.2 Moded END   ===============================================================
        AND  mmt.subinventory_code               =  msi.secondary_inventory_name
        AND  msi.attribute7                      =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca.account_number                  =  msi.attribute7
        AND  hca.customer_class_code             =  cv_1
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  cat.item_no                         =  msib.segment1
        AND  cat.item_category                   =  NVL ( gr_param.item_ctg,cat.item_category )
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
-- == 2009/09/08 V1.6 Added START ===============================================================
        AND  mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     NVL(ximb.end_date_active, mmt.transaction_date)
-- == 2009/09/08 V1.6 Added END   ===============================================================
      ORDER BY msi.attribute7
              ,cat.item_category
              ,msib.segment1
      ;
--
    -- ローカル・レコード
    lr_info_fact_rec info_fact_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 取引タイプ名取得：工場入庫
    -- ===============================
    lv_tran_type_factory_store := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_factory_store);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_factory_store IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_factory_store
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：工場入庫
    -- ===============================
    ln_tran_type_factory_store := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_factory_store);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_factory_store IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_factory_store
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：工場入庫振戻
    -- ===============================
    lv_tran_type_factory_store_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_factory_store_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_factory_store_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_factory_store_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：工場入庫振戻
    -- ===============================
    ln_tran_type_factory_store_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_factory_store_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_factory_store_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_factory_store_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- == 2009/04/22 V1.2 Added START ===============================================================
    -- ===============================
    -- 取引タイプ名取得：梱包材料一時受入
    -- ===============================
    lv_tran_type_packing_temp := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_temp);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_packing_temp IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_packing_temp
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：梱包材料一時受入
    -- ===============================
    ln_tran_type_packing_temp := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_temp);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_packing_temp IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_packing_temp
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：梱包材料一時受入振戻
    -- ===============================
    lv_tran_type_packing_temp_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_temp_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_packing_temp_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10022
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_tran_type_packing_temp_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：梱包材料一時受入振戻
    -- ===============================
    ln_tran_type_packing_temp_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_temp_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_packing_temp_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10012
                     ,iv_token_name1  => cv_tkn_tran_type
                     ,iv_token_value1 => lv_tran_type_packing_temp_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- == 2009/05/21 V1.3 Deleted START =============================================================
--    -- ===============================
--    -- 取引タイプ名取得：梱包材料原価振替
--    -- ===============================
--    lv_tran_type_packing_cost := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_cost);
--    --
--    -- リターンコードがNULLの場合はエラー
--    IF ( lv_tran_type_packing_cost IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10022
--                     ,iv_token_name1  => cv_tkn_lookup_type
--                     ,iv_token_value1 => cv_tran_type
--                     ,iv_token_name2  => cv_tkn_lookup_code
--                     ,iv_token_value2 => cv_tran_type_packing_cost
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- ===============================
--    -- 取引タイプID取得：梱包材料原価振替
--    -- ===============================
--    ln_tran_type_packing_cost := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_cost);
--    --
--    -- リターンコードがNULLの場合はエラー
--    IF ( ln_tran_type_packing_cost IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10012
--                     ,iv_token_name1  => cv_tkn_tran_type
--                     ,iv_token_value1 => lv_tran_type_packing_cost
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- ===============================
--    -- 取引タイプ名取得：梱包材料原価振替振戻
--    -- ===============================
--    lv_tran_type_packing_cost_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_packing_cost_b);
--    --
--    -- リターンコードがNULLの場合はエラー
--    IF ( lv_tran_type_packing_cost_b IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10022
--                     ,iv_token_name1  => cv_tkn_lookup_type
--                     ,iv_token_value1 => cv_tran_type
--                     ,iv_token_name2  => cv_tkn_lookup_code
--                     ,iv_token_value2 => cv_tran_type_packing_cost_b
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- ===============================
--    -- 取引タイプID取得：梱包材料原価振替振戻
--    -- ===============================
--    ln_tran_type_packing_cost_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_packing_cost_b);
--    --
--    -- リターンコードがNULLの場合はエラー
--    IF ( ln_tran_type_packing_cost_b IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10012
--                     ,iv_token_name1  => cv_tkn_tran_type
--                     ,iv_token_value1 => lv_tran_type_packing_cost_b
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
-- == 2009/05/21 V1.3 Deleted END   =============================================================
-- == 2009/04/22 V1.2 Added END   ===============================================================
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- カーソルオープン
-- == 2009/04/22 V1.2 Moded START ===============================================================
--    OPEN  info_fact_cur(ln_tran_type_factory_store,ln_tran_type_factory_store_b);
    OPEN  info_fact_cur(
              tran_type1 => ln_tran_type_factory_store
            , tran_type2 => ln_tran_type_factory_store_b
            , tran_type3 => ln_tran_type_packing_temp
            , tran_type4 => ln_tran_type_packing_temp_b
-- == 2009/05/21 V1.3 Deleted START =============================================================
--            , tran_type5 => ln_tran_type_packing_cost
--            , tran_type6 => ln_tran_type_packing_cost_b
-- == 2009/05/21 V1.3 Deleted END   =============================================================
          );
-- == 2009/04/22 V1.2 Moded END   ===============================================================
    --
    <<ins_work_loop>>
    LOOP
    FETCH info_fact_cur INTO lr_info_fact_rec;
    EXIT WHEN info_fact_cur%NOTFOUND;
--
    -- 対象件数カウント
      ln_sql_cnt := ln_sql_cnt + 1;
      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- ==============================================
      --  標準原価取得
      -- ==============================================
      xxcoi_common_pkg.get_cmpnt_cost(in_item_id     => lr_info_fact_rec.inventory_item_id   -- 品目ID
                                     ,in_org_id      => gn_organization_id                   -- 在庫組織ID
                                     ,id_period_date => lr_info_fact_rec.transaction_date    -- 取引日
                                     ,ov_cmpnt_cost  => lv_cmpnt_cost                        -- 標準原価
                                     ,ov_retcode     => lv_retcode                           -- リターンコード
                                     ,ov_errbuf      => lv_errbuf                            -- エラーメッセージ
                                     ,ov_errmsg      => lv_errmsg);                          -- エラーメッセージ
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10285
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 原価額計算
      ln_cmpnt_cost := NVL(TO_NUMBER(lv_cmpnt_cost),0) * lr_info_fact_rec.transaction_qty;
--
      -- 最初のレコードの場合、自データを設定
      IF ln_sql_cnt = 1 THEN
        -- 商品コード設定
        lv_item_code := lr_info_fact_rec.item_no;
      END IF;
--
      -- 商品コードが前レコードと違う場合,ワークテーブルに登録
      IF ( lv_item_code = lr_info_fact_rec.item_no ) THEN
--
        -- 数量加算
        ln_tran_qty := ln_tran_qty + lr_info_fact_rec.transaction_qty;
        -- 標準原価加算
        ln_cmpnt_cost_sum := ln_cmpnt_cost_sum + ln_cmpnt_cost;
        -- 商品コード設定
        lv_item_code := lr_info_fact_rec.item_no;
        -- 商品略称設定
        lv_item_short_name := lr_info_fact_rec.item_short_name;
        -- カテゴリ設定
        lv_item_category := lr_info_fact_rec.item_category;
--
      ELSIF ( lv_item_code <> lr_info_fact_rec.item_no ) THEN
--
        -- ==============================================
        --  ワークテーブルデータ登録(A-4)
        -- ==============================================
        ins_work(
            lr_info_fact_rec.in_base_code                        -- 入庫拠点
           ,lr_info_fact_rec.account_name                        -- 入庫拠点名
           ,lv_item_category                                     -- 品目カテゴリコード
           ,lv_item_code                                         -- 商品
           ,lv_item_short_name                                   -- 略称
           ,ln_tran_qty                                          -- 取引数量
           ,ln_cmpnt_cost_sum                                    -- 原価額
-- == 2009/08/05 V1.5 Modified START ===============================================================
--           ,cv_1                                                 -- パラメータフラグ
           ,CASE  WHEN  gr_param.item_ctg IS NULL THEN cv_1
                  ELSE  cv_2
            END
-- == 2009/08/05 V1.5 Modified END   ===============================================================
           ,NULL
           ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
           ,lv_retcode           -- リターン・コード             --# 固定 #
           ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error )
         OR ( lv_retcode = cv_status_warn ) THEN
          RAISE global_process_expt ;
        END IF;
--
        -- 数量設定
        ln_tran_qty := lr_info_fact_rec.transaction_qty;
        -- 標準原価設定
        ln_cmpnt_cost_sum := ln_cmpnt_cost;
        -- 商品コード設定
        lv_item_code := lr_info_fact_rec.item_no;
        -- 商品略称設定
        lv_item_short_name := lr_info_fact_rec.item_short_name;
        -- カテゴリ設定
        lv_item_category := lr_info_fact_rec.item_category;
--
      END IF;
--
    END LOOP ins_work_loop;
--
    -- 最終レコードの場合こちらで登録
    IF ln_sql_cnt > 0 THEN
        -- ==============================================
        --  ワークテーブルデータ登録(A-4)
        -- ==============================================
        ins_work(
            lr_info_fact_rec.in_base_code                        -- 入庫拠点
           ,lr_info_fact_rec.account_name                        -- 入庫拠点名
           ,lv_item_category                                     -- 品目カテゴリコード
           ,lv_item_code                                         -- 商品
           ,lv_item_short_name                                   -- 略称
           ,ln_tran_qty                                          -- 取引数量
           ,ln_cmpnt_cost_sum                                    -- 原価額
-- == 2009/08/05 V1.5 Modified START ===============================================================
--           ,cv_1                                                 -- パラメータフラグ
           ,CASE  WHEN  gr_param.item_ctg IS NULL THEN cv_1
                  ELSE  cv_2
            END
-- == 2009/08/05 V1.5 Modified END   ===============================================================
           ,NULL
           ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
           ,lv_retcode           -- リターン・コード             --# 固定 #
           ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error )
         OR ( lv_retcode = cv_status_warn ) THEN
          RAISE global_process_expt ;
        END IF;
--
    END IF;
--
    -- カーソルクローズ
    CLOSE info_fact_cur;
--
    -- コミット処理
    COMMIT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_fact_cur%ISOPEN ) THEN
        CLOSE info_fact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_kojo_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 拠点情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_data'; -- プログラム名
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
    -- 拠点情報(専門店)
    CURSOR info_base1_cur
    IS
      SELECT hca.account_number account_num                         -- 顧客コード
      FROM   hz_cust_accounts hca                                   -- 顧客マスタ
            ,xxcmm_cust_accounts xca                                                    -- 顧客追加情報アドオンマスタ
      WHERE  hca.cust_account_id = xca.customer_id
        AND  hca.customer_class_code = cv_1
        AND  hca.account_number = NVL( gr_param.in_kyoten,hca.account_number )
        AND  xca.management_base_code = gv_base_code
      ORDER BY hca.account_number
    ;
--
    -- 拠点情報(商品部)
    CURSOR info_base2_cur
    IS
      SELECT  hca.account_number account_num                         -- 顧客コード
        FROM  hz_cust_accounts hca                                   -- 顧客マスタ
       WHERE  hca.customer_class_code = cv_1
         AND  hca.account_number = NVL( gr_param.in_kyoten,hca.account_number )
       ORDER BY hca.account_number
    ;
--
    -- *** ローカル・レコード ***
    lr_info_base1_rec   info_base1_cur%ROWTYPE;
    lr_info_base2_rec   info_base2_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 専門店で起動の時
    IF ( gr_param.output_dpt = cv_2 ) THEN
      OPEN info_base1_cur;
--
      -- レコード読み込み
      FETCH info_base1_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base1_cur;
--
    -- 商品部で起動の時
    ELSIF ( gr_param.output_dpt = cv_3 ) THEN
      OPEN info_base2_cur;
      -- レコード読み込み
      FETCH info_base2_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base2_cur;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_base_data;
--
    /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'init';                      -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 定数
    cv_01              CONSTANT VARCHAR2(2)    := '01';                        -- 妥当性チェック用(1月)
    cv_12              CONSTANT VARCHAR2(2)    := '12';                        -- 妥当性チェック用(12月)
    cv_profile_name    CONSTANT VARCHAR2(24)   := 'XXCOI1_ORGANIZATION_CODE';  -- プロファイル名(在庫組織コード)
--
    -- *** ローカル変数 ***
    lv_organization_code mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
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
    -- =====================================
    -- 業務日付取得(共通関数)
    -- =====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
      -- 業務日付が取得できない場合はエラー
      IF ( gd_process_date IS NULL ) THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi00011
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- =====================================
    -- パラメータ妥当性チェック(年月)
    -- =====================================
    IF ( ( SUBSTRB(gr_param.year_month,5,6) < cv_01 ) OR ( SUBSTRB ( gr_param.year_month,5,6 ) > cv_12 ) ) THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10069
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
    ELSIF ( TO_CHAR( ( gd_process_date ), 'YYYYMM' ) < gr_param.year_month ) THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10003
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
    END IF;
--
    -- =====================================
    -- プロファイル値取得(在庫組織コード)
    -- =====================================
    lv_organization_code := FND_PROFILE.VALUE(cv_profile_name);
    IF ( lv_organization_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00005
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_profile_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 在庫組織ID取得
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    IF ( gn_organization_id IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00006
                     ,iv_token_name1  => cv_token_org_code
                     ,iv_token_value1 => lv_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 所属拠点取得
    -- =====================================
    gv_base_code := xxcoi_common_pkg.get_base_code(
                        in_user_id     => cn_created_by     -- ユーザーID
                       ,id_target_date => gd_process_date); -- 対象日
    IF ( gv_base_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10092);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- コンカレント入力パラメータ出力
    --==============================================================
    -- パラメータ.年月
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application =>  cv_app_name
                    ,iv_name        =>  cv_msg_xxcoi10081
                    ,iv_token_name1  => cv_token_date
                    ,iv_token_value1 => gr_param.year_month
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.入庫拠点
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application =>  cv_app_name
                    ,iv_name        =>  cv_msg_xxcoi10082
                    ,iv_token_name1  => cv_token_base_code
                    ,iv_token_value1 => gr_param.in_kyoten
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.カテゴリ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application =>  cv_app_name
                    ,iv_name        =>  cv_msg_xxcoi10083
                    ,iv_token_name1  => cv_token_item_ctg
                    ,iv_token_value1 => gr_param.item_ctg
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    --*** 値エラー ***
    WHEN get_value_expt THEN
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_year_month  IN  VARCHAR2,     --   1.年月
    iv_in_kyoten   IN  VARCHAR2,     --   2.入庫拠点
    iv_item_ctgr   IN  VARCHAR2,     --   3.品目カテゴリ
    iv_output_dpt  IN  VARCHAR2,     --   4.帳票出力場所
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_nodata_msg VARCHAR2(50);
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
    -- =====================================================
    -- パラメータ値の格納
    -- =====================================================
    gr_param.year_month    := SUBSTRB(iv_year_month,1,4)
                            ||SUBSTRB(iv_year_month,6,7);
                                                   -- 01 : 処理年月      (必須)
    gr_param.in_kyoten     := iv_in_kyoten;        -- 02 : 入庫拠点     （任意)
    gr_param.item_ctg      := iv_item_ctgr;        -- 03 : カテゴリコード(任意)
    gr_param.output_dpt    := iv_output_dpt;       -- 04 : 出力場所(任意)
--
    -- =====================================================
    -- 初期処理(A-1)
    -- =====================================================
    init(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error )
     OR ( lv_retcode = cv_status_warn ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- 拠点情報取得処理(A-2)
    -- =====================================================
    get_base_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error )
     OR ( lv_retcode = cv_status_warn ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- 拠点情報が１件以上取得出来た場合
    IF ( gn_base_cnt > 0 ) THEN
--
      -- 拠点単位ループ開始
      <<gt_param_tab_loop>>
       FOR gn_base_loop_cnt IN 1 .. gn_base_cnt LOOP
--
         -- =====================================================
         -- 工場入庫明細情報取得処理(A-3)
         -- =====================================================
         get_kojo_data(
             gn_base_loop_cnt
            ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
            ,lv_retcode           -- リターン・コード             --# 固定 #
            ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
         );
         IF ( lv_retcode = cv_status_error )
          OR ( lv_retcode = cv_status_warn ) THEN
           RAISE global_process_expt ;
         END IF;
--
       END LOOP gt_param_tab_loop;
    END IF;
--
    -- 出力対象件数が0件の場合、ワークテーブルにパラメータ情報のみを登録
    IF (gn_target_cnt = 0) THEN
--
      -- 0件メッセージの取得
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi00008
                         );
--
      -- ==============================================
      --  ワークテーブルデータ登録(A-4)
      -- ==============================================
      ins_work(
          NULL                                                 -- 入庫拠点
         ,NULL                                                 -- 入庫拠点名
         ,NULL                                                 -- 品目カテゴリコード
         ,NULL                                                 -- 商品
         ,NULL                                                 -- 略称
         ,NULL                                                 -- 取引数量
         ,NULL                                                 -- 原価額
         ,cv_0                                                 -- パラメータフラグ
         ,lv_nodata_msg                                        -- 0件メッセージ
         ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
         ,lv_retcode           -- リターン・コード             --# 固定 #
         ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error)
       OR (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt ;
      END IF;
    END IF;
--
    -- =====================================================
    -- SVF起動(A-5)
    -- =====================================================
    svf_request(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- ワークテーブルデータ削除(A-6)
    -- =====================================================
    del_work(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- 正常終了件数
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_year_month IN  VARCHAR2,      --   1.年月
    iv_in_kyoten  IN  VARCHAR2,      --   2.入庫拠点
    iv_item_ctgr  IN  VARCHAR2,      --   3.品目カテゴリ
    iv_output_dpt  IN  VARCHAR2      --   4.帳票出力場所
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
       iv_which   =>  cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
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
       iv_year_month   --   1.年月
      ,iv_in_kyoten    --   2.入庫拠点
      ,iv_item_ctgr    --   3.品目カテゴリ
      ,iv_output_dpt   --   4.帳票出力場所
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg --ユーザー・エラーメッセージ
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --エラーメッセージ
    );
 --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
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
END XXCOI009A03R;
/
