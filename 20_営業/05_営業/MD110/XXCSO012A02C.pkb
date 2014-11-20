CREATE OR REPLACE PACKAGE BODY APPS.XXCSO012A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO012A02C(body)
 * Description      : ファイルアップロードIFに取込まれたデータを
 *                    物件マスタ情報(IB)に登録します。
 * MD.050           : MD050_CSO_012_A02_自動販売機データ格納
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_item_instances     物件情報抽出 (A-2)
 *  chk_data_validate      データ妥当性チェック処理 (A-3)
 *  chk_data_master        データマスタチェック処理 (A-4)
 *  get_custmer_data       顧客情報取得処理 (A-5)
 *  insert_item_instances  物件データ登録処理 (A-6)
 *  rock_file_interface    ファイルアップロードIFロック処理 (A-7)
 *  delete_in_item_data    物件データワークテーブル削除処理 (A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-03-18    1.0   T.Matsunaka      新規作成
 *  2009-03-26    1.1   T.Matsunaka      【ST障害対応183】自動販売機データ格納でIB拡張属性値テーブル登録不正
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009-05-22    1.3   M.Ohtsuki        T1_1141対応      廃棄フラグに0を設定
 *  2009-01-13    1.4   K.Hosoi          E_本稼動_00443対応
 *  2014-05-19    1.5   K.Nakamura       E_本稼動_11853対応 ベンダー購入対応
 *  2014-08-27    1.6   S.Yamashita      E_本稼動_11719対応 ベンダー購入対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSO012A02C';      -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  -- メッセージコード
  cv_tkn_number_33        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- ファイルID出力
  cv_tkn_number_34        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- フォーマットパターン出力
  cv_tkn_number_01        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  cv_tkn_number_02        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_03        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_35        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- アップロードファイル名称取得エラー
  cv_tkn_number_36        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- アップロードファイル名称出力
  cv_tkn_number_04        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00092';  -- 組織ID取得エラー
  cv_tkn_number_05        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00093';  -- 組織ID抽出エラー
  cv_tkn_number_06        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00094';  -- 品目ID取得エラー
  cv_tkn_number_07        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00095';  -- 品目ID抽出エラー
  cv_tkn_number_08        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00163';  -- ステータスID取得エラー
  cv_tkn_number_09        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00164';  -- ステータスID抽出エラー
  cv_tkn_number_10        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- 取引タイプID取得エラー
  cv_tkn_number_11        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- 取引タイプID抽出エラー
  cv_tkn_number_12        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- 追加属性ID抽出エラー
  cv_tkn_number_37        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00254';  -- 値セット取得エラー
  cv_tkn_number_38        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00255';  -- 値セット抽出エラー
  cv_tkn_number_49        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- データ削除エラー
  cv_tkn_number_40        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00554';  -- BLOB変換エラー
  cv_tkn_number_39        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- アップロードファイル名称出力
  cv_tkn_number_41        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00181';  -- 必須チェックエラー
  cv_tkn_number_43        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00317';  -- 半角英数字エラー
  cv_tkn_number_42        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00551';  -- 物件コード書式エラー
  cv_tkn_number_44        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00183';  -- LENGTHエラー
  cv_tkn_number_45        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00118';  -- データ抽出、登録警告メッセージ
  cv_tkn_number_46        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00552';  -- 物件マスタ重複エラー
  cv_tkn_number_47        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00553';  -- 機種マスタ取得エラー
  cv_tkn_number_48        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- データ削除エラー
  cv_tkn_number_50        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00557';  -- 機器区分取得エラー
  cv_tkn_number_32        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00518';  -- データ抽出0件メッセージ
  cv_tkn_number_51        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00550';  -- CSVデータフォーマットエラー
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
  cv_tkn_number_52        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00670';  -- リース区分
  cv_tkn_number_53        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- 申告地
  cv_tkn_number_54        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00675';  -- 取得価格
  cv_tkn_number_55        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00678';  -- 機種マスタビュー
  cv_tkn_number_56        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- 存在エラー
  cv_tkn_number_57        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00680';  -- 参照タイプ ：
  cv_tkn_number_58        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00681';  -- 値セット ：
  cv_tkn_number_59        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00682';  -- 固定資産時必須エラー
  cv_tkn_number_60        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00268';  -- マイナス値エラーメッセージ
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
  cv_target_rec_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_success_rec_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_error_rec_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_normal_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
  cv_warn_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
  cv_error_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
--
  -- トークンコード
  cv_tkn_file_id          CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_format           CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_upload           CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_task_nm          CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_organization     CONSTANT VARCHAR2(20) := 'ORGANIZATION_CODE';
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_segment          CONSTANT VARCHAR2(20) := 'SEGMENT';
  cv_tkn_organization_id  CONSTANT VARCHAR2(20) := 'ORGANIZATION_ID';
  cv_tkn_status_name      CONSTANT VARCHAR2(20) := 'STATUS_NAME';
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  cv_tkn_attribute_name   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_attribute_code   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_value_set_name   CONSTANT VARCHAR2(20) := 'VALUE_SET_NAME';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_csv_upload       CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_value            CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_value2           CONSTANT VARCHAR2(20) := 'VALUE2';
  cv_tkn_bukken           CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_cnt_token            CONSTANT VARCHAR2(10) := 'COUNT';           -- 件数メッセージ用トークン名
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_eigyo            CONSTANT VARCHAR2(20) := 'EIGYO';
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
  cv_encoded_f            CONSTANT VARCHAR2(1)   := 'F';              -- FALSE
--
  cv_msg_conm             CONSTANT VARCHAR2(1)   := ',';              -- カンマ
--
/* 2014-08-27 S.Yamashita E_本稼動_11719対応 START */
  cv_msg_part_only        CONSTANT VARCHAR2(1) := ':';
/* 2014-08-27 S.Yamashita E_本稼動_11719対応 END */
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
  cv_hyphen               CONSTANT VARCHAR2(1)   := '-';                -- ハイフン
  -- 値セット
  cv_xxcff_dclr_place     CONSTANT VARCHAR2(30) := 'XXCFF_DCLR_PLACE';  -- 申告地
  -- 参照タイプ
  cv_xxcso1_lease_kbn     CONSTANT VARCHAR2(30) := 'XXCSO1_LEASE_KBN';  -- リース区分
  --
  cv_fixed_assets         CONSTANT VARCHAR2(1)  := '4';                 -- リース区分「固定資産」
  cv_y                    CONSTANT VARCHAR2(1)  := 'Y';                 -- 有効フラグY
  ct_language             CONSTANT fnd_flex_values_tl.language%TYPE := USERENV('LANG'); -- 言語
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gt_inv_mst_org_id       mtl_parameters.organization_id%TYPE;                 -- 組織ID
  gt_vld_org_id           mtl_parameters.organization_id%TYPE;                 -- 検証組織ID
  gt_txn_type_id          csi_txn_types.transaction_type_id%TYPE;              -- 取引タイプID
  gt_bukken_item_id       mtl_system_items_b.inventory_item_id%TYPE;           -- 物件用品目ID
  gt_instance_status_id_2 csi_instance_statuses.instance_status_id%TYPE;       -- 使用可
  gd_process_date         DATE;                                                -- 業務日付
  gv_owner_company        fnd_flex_values_vl.flex_value%TYPE;                  -- 本社/工場区分
  gn_account_id           xxcso_cust_acct_sites_v.cust_account_id%TYPE;        -- アカウントID
  gn_locatoin_id          xxcso_cust_acct_sites_v.location_id%TYPE;            -- ロケーションID
  gn_party_id             xxcso_cust_acct_sites_v.party_id%TYPE;               -- パーティID
  gn_party_site_id        xxcso_cust_acct_sites_v.party_site_id%TYPE;          -- パーティサイトID
  /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
  --gv_established_site     xxcso_cust_acct_sites_v.established_site_name%TYPE;  -- 設置先名
  gv_established_site     xxcso_cust_acct_sites_v.party_name%TYPE;             -- 設置先名
  /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
  gv_address              VARCHAR2(1000);                                      -- 設置先住所
  gv_address3             VARCHAR2(1000);                                      -- 地区コード
  gv_file_name            VARCHAR2(1000);                                      -- 入力ファイル名
  gv_hazard_class         po_hazard_classes_vl.hazard_class%TYPE;              -- 機器区分
  gv_maker_name           fnd_lookup_values.meaning%TYPE;                      -- メーカー名
  gv_age_type             po_un_numbers_vl.attribute3%TYPE;                    -- 年式
--
  -- 追加属性ID格納用レコード型定義
  TYPE gr_ib_ext_attribs_id_rtype IS RECORD(
     jotai_kbn1            NUMBER               -- 機器状態1（稼動状態）
    ,jotai_kbn2            NUMBER               -- 機器状態2（状態詳細）
    ,jotai_kbn3            NUMBER               -- 機器状態3（廃棄情報）
    ,lease_kbn             NUMBER               -- リース区分
/*20090326_matsunaka_ST183 START*/
--    ,chiku_cd              VARCHAR2(150)        -- 地区コード
    ,chiku_cd              NUMBER               -- 地区コード
    ,count_no              NUMBER               -- カウンターNo.
    ,sagyougaisya_cd       NUMBER               -- 作業会社コード
    ,jigyousyo_cd          NUMBER               -- 事業所コード
    ,den_no                NUMBER               -- 最終作業伝票No.
    ,job_kbn               NUMBER               -- 最終作業区分
    ,sintyoku_kbn          NUMBER               -- 最終作業進捗
    ,yotei_dt              NUMBER               -- 最終作業完了予定日
    ,kanryo_dt             NUMBER               -- 最終作業完了日
    ,sagyo_level           NUMBER               -- 最終整備内容
    ,den_no2               NUMBER               -- 最終設置伝票No.
    ,job_kbn2              NUMBER               -- 最終設置区分
    ,sintyoku_kbn2         NUMBER               -- 最終設置進捗
    ,nyuko_dt              NUMBER               -- 入庫日
    ,hikisakigaisya_cd     NUMBER               -- 引揚会社コード
    ,hikisakijigyosyo_cd   NUMBER               -- 引揚事業所コード
    ,setti_tanto           NUMBER               -- 設置先担当者名
    ,setti_tel1            NUMBER               -- 設置先tel1
    ,setti_tel2            NUMBER               -- 設置先tel2
    ,setti_tel3            NUMBER               -- 設置先tel3
    ,haikikessai_dt        NUMBER               -- 廃棄決裁日
    ,tenhai_tanto          NUMBER               -- 転売廃棄業者
    ,tenhai_den_no         NUMBER               -- 転売廃棄伝票№
    ,syoyu_cd              NUMBER               -- 所有者
    ,tenhai_flg            NUMBER               -- 転売廃棄状況フラグ
    ,kanryo_kbn            NUMBER               -- 転売完了区分
    ,sakujo_flg            NUMBER               -- 削除フラグ
    ,ven_kyaku_last        NUMBER               -- 最終顧客コード
    ,ven_tasya_cd01        NUMBER               -- 他社コード１
    ,ven_tasya_daisu01     NUMBER               -- 他社台数１
    ,ven_tasya_cd02        NUMBER               -- 他社コード２
    ,ven_tasya_daisu02     NUMBER               -- 他社台数２
    ,ven_tasya_cd03        NUMBER               -- 他社コード３
    ,ven_tasya_daisu03     NUMBER               -- 他社台数３
    ,ven_tasya_cd04        NUMBER               -- 他社コード４
    ,ven_tasya_daisu04     NUMBER               -- 他社台数４
    ,ven_tasya_cd05        NUMBER               -- 他社コード５
    ,ven_tasya_daisu05     NUMBER               -- 他社台数５
    ,ven_haiki_flg         NUMBER               -- 廃棄フラグ
    ,ven_sisan_kbn         NUMBER               -- 資産区分
    ,ven_kobai_ymd         NUMBER               -- 購買日付
    ,ven_kobai_kg          NUMBER               -- 購買金額
    ,safty_level           NUMBER               -- 安全設置基準
    ,last_inst_cust_code   NUMBER               -- 先月末設置先顧客コード
    ,last_jotai_kbn        NUMBER               -- 先月末機器状態
    ,last_year_month       NUMBER               -- 先月末年月
/*20090326_matsunaka_ST183 END*/
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    ,vd_shutoku_kg         NUMBER               -- 取得価格
    ,dclr_place            NUMBER               -- 申告地
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
  );
  -- 追加属性ID格納用レコード変数
  gr_ext_attribs_id_rec   gr_ib_ext_attribs_id_rtype;
--
  --BLOBデータ格納配列
  gr_file_data_tbl         xxccp_common_pkg2.g_file_data_tbl;
--
  --BLOBデータ分割データ格納
  TYPE gr_blob_data_rtype IS RECORD(
    object_code          VARCHAR2(10)            -- 物件コード
   ,serial_code          VARCHAR2(15)            -- 機種コード
   ,base_code            VARCHAR2(4)             -- 拠点コード
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
   ,lease_kbn            VARCHAR2(1)             -- リース区分
   ,dclr_place           VARCHAR2(5)             -- 申告地
   ,vd_shutoku_kg        VARCHAR2(10)            -- 取得価格
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
  );
  gr_blob_data gr_blob_data_rtype;
--  
  -- *** ユーザー定義グローバル例外 ***
  global_lock_expt        EXCEPTION;                                 -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     in_file_id           IN  NUMBER               -- ファイルID
    ,iv_format            IN  VARCHAR2             -- フォーマットパターン
    ,ov_errbuf            OUT NOCOPY VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- アプリケーション短縮名
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
    -- XXCSO:在庫マスタ組織
    cv_inv_mst_org_code       CONSTANT VARCHAR2(30)  := 'XXCSO1_INV_MST_ORG_CODE';
    -- XXCSO:検証組織
    cv_vld_org_code           CONSTANT VARCHAR2(30)  := 'XXCSO1_VLD_ORG_CODE';
    -- XXCSO:物件用品目
    cv_bukken_item            CONSTANT VARCHAR2(30)  := 'XXCSO1_BUKKEN_ITEM';
    -- ファイルアップロード名称
    cv_xxcso1_file_name       CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';
    -- 参照タイプのIBステータスタイプコード
    cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
    -- XXCSO:本社/工場区分(本社)参照タイプ
    cv_cso_owner_company_type CONSTANT VARCHAR2(30)  := 'XXCSO1_OWNER_COMPANY';
    -- XXCFF:本社/工場区分(本社)
    cv_cff_owner_company_type CONSTANT VARCHAR2(30)  := 'XXCFF_OWNER_COMPANY';
    -- 参照タイプのIBステータス(使用可)コード
    cv_instance_status_2      CONSTANT VARCHAR2(1)   := '2';
    -- ソーストランザクションタイプ
    cv_src_transaction_type   CONSTANT VARCHAR2(30)  := 'IB_UI';
    -- ファイルアップロードコード
    cv_xxcso1_file_code       CONSTANT VARCHAR2(30)  := '640';
    -- XXCSO:本社/工場区分(本社)参照コード
    cv_cso_owner_company_code CONSTANT VARCHAR2(1)  := '1';
    -- 抽出内容名(在庫マスタの組織ID)
    cv_mtl_parameters_info    CONSTANT VARCHAR2(100) := '在庫マスタの組織ID';
    -- 抽出内容名(在庫マスタの検証組織ID)
    cv_mtl_parameters_vld     CONSTANT VARCHAR2(100) := '在庫マスタの検証組織ID';
    -- 抽出内容名(品目マスタの品目ID)
    cv_mtl_system_items_id    CONSTANT VARCHAR2(100) := '品目マスタの品目ID';
    -- 抽出内容名(インスタンスステータスマスタのステータスID)
    cv_csi_instance_statuses  CONSTANT VARCHAR2(100) := 'インスタンスステータスマスタのステータスID';
    -- 抽出内容名(取引タイプの取引タイプID)
    cv_csi_txn_types          CONSTANT VARCHAR2(100) := '取引タイプの取引タイプID';
    -- 抽出内容名(設置機器拡張属性定義情報の追加属性ID)
    cv_attribute_id_info      CONSTANT VARCHAR2(100) := '設置機器拡張属性定義情報の追加属性ID';
    -- ステータス名(使用可)
    cv_statuses_name02        CONSTANT VARCHAR2(100) := '使用可';
    -- 値セット
    cv_csi_txn_flex           CONSTANT VARCHAR2(100) := '値セット';
    -- 機器状態1（稼動状態）
    cv_i_ext_jotai_kbn1       CONSTANT VARCHAR2(100) := '機器状態1（稼動状態）';
    -- 機器状態2（状態詳細）
    cv_i_ext_jotai_kbn2       CONSTANT VARCHAR2(100) := '機器状態2（状態詳細）';
    -- 機器状態3（廃棄情報）
    cv_i_ext_jotai_kbn3       CONSTANT VARCHAR2(100) := '機器状態3（廃棄情報）';
    -- リース区分
    cv_i_ext_lease_kbn        CONSTANT VARCHAR2(100) := 'リース区分';
    -- 地区コード
    cv_i_ext_chiku_cd         CONSTANT VARCHAR2(100) := '地区コード';
    -- 機器状態1（稼動状態）
    cv_jotai_kbn1             CONSTANT VARCHAR2(100) := 'JOTAI_KBN1';
    -- 機器状態2（状態詳細）
    cv_jotai_kbn2             CONSTANT VARCHAR2(100) := 'JOTAI_KBN2';
    -- 機器状態2（廃棄情報）
    cv_jotai_kbn3             CONSTANT VARCHAR2(100) := 'JOTAI_KBN3';
    -- リース区分
    cv_lease_kbn              CONSTANT VARCHAR2(100) := 'LEASE_KBN';
    -- 地区コード
    cv_chiku_cd               CONSTANT VARCHAR2(100) := 'CHIKU_CD';
    -- 本社/工場区分
    cv_owner_company          CONSTANT VARCHAR2(100) := '本社/工場区分';
--
/*20090326_matsunaka_ST183 START*/
    -- カウンターNo.
    cv_i_ext_count_no         CONSTANT VARCHAR2(100) := 'カウンターNo.';
    -- 作業会社コード
    cv_i_ext_sagyougaisya_cd  CONSTANT VARCHAR2(100) := '作業会社コード';
    -- 事業所コード
    cv_i_ext_jigyousyo_cd     CONSTANT VARCHAR2(100) := '事業所コード';
    -- 最終作業伝票No.
    cv_i_ext_den_no           CONSTANT VARCHAR2(100) := '最終作業伝票No.';
    -- 最終作業区分
    cv_i_ext_job_kbn          CONSTANT VARCHAR2(100) := '最終作業区分';
    -- 最終作業進捗
    cv_i_ext_sintyoku_kbn     CONSTANT VARCHAR2(100) := '最終作業進捗';
    -- 最終作業完了予定日
    cv_i_ext_yotei_dt         CONSTANT VARCHAR2(100) := '最終作業完了予定日';
    -- 最終作業完了日
    cv_i_ext_kanryo_dt        CONSTANT VARCHAR2(100) := '最終作業完了日';
    -- 最終整備内容
    cv_i_ext_sagyo_level      CONSTANT VARCHAR2(100) := '最終整備内容';
    -- 最終設置伝票No.
    cv_i_ext_den_no2          CONSTANT VARCHAR2(100) := '最終設置伝票No.';
    -- 最終設置区分
    cv_i_ext_job_kbn2         CONSTANT VARCHAR2(100) := '最終設置区分';
    -- 最終設置進捗
    cv_i_ext_sintyoku_kbn2    CONSTANT VARCHAR2(100) := '最終設置進捗';
    -- 入庫日
    cv_i_ext_nyuko_dt         CONSTANT VARCHAR2(100) := '入庫日';
    -- 引揚会社コード
    cv_i_ext_hikisakicmy_cd   CONSTANT VARCHAR2(100) := '引揚会社コード';
    -- 引揚事業所コード
    cv_i_ext_hikisakilct_cd   CONSTANT VARCHAR2(100) := '引揚事業所コード';
    -- 設置先担当者名
    cv_i_ext_setti_tanto      CONSTANT VARCHAR2(100) := '設置先担当者名';
    -- 設置先tel1
    cv_i_ext_setti_tel1       CONSTANT VARCHAR2(100) := '設置先tel1';
    -- 設置先tel2
    cv_i_ext_setti_tel2       CONSTANT VARCHAR2(100) := '設置先tel2';
    -- 設置先tel3
    cv_i_ext_setti_tel3       CONSTANT VARCHAR2(100) := '設置先tel3';
    -- 廃棄決裁日
    cv_i_ext_haikikessai_dt   CONSTANT VARCHAR2(100) := '廃棄決裁日';
    -- 転売廃棄業者
    cv_i_ext_tenhai_tanto     CONSTANT VARCHAR2(100) := '転売廃棄業者';
    -- 転売廃棄伝票№
    cv_i_ext_tenhai_den_no    CONSTANT VARCHAR2(100) := '転売廃棄伝票№';
    -- 所有者
    cv_i_ext_syoyu_cd         CONSTANT VARCHAR2(100) := '所有者';
    -- 転売廃棄状況フラグ
    cv_i_ext_tenhai_flg       CONSTANT VARCHAR2(100) := '転売廃棄状況フラグ';
    -- 転売完了区分
    cv_i_ext_kanryo_kbn       CONSTANT VARCHAR2(100) := '転売完了区分';
    -- 削除フラグ
    cv_i_ext_sakujo_flg       CONSTANT VARCHAR2(100) := '削除フラグ';
    -- 最終顧客コード
    cv_i_ext_ven_kyaku_last   CONSTANT VARCHAR2(100) := '最終顧客コード';
    -- 他社コード１
    cv_i_ext_ven_tasya_cd01   CONSTANT VARCHAR2(100) := '他社コード１';
    -- 他社台数１
    cv_i_ext_ven_tasya_ds01   CONSTANT VARCHAR2(100) := '他社台数１';
    -- 他社コード２
    cv_i_ext_ven_tasya_cd02   CONSTANT VARCHAR2(100) := '他社コード２';
    -- 他社台数２
    cv_i_ext_ven_tasya_ds02   CONSTANT VARCHAR2(100) := '他社台数２';
    -- 他社コード３
    cv_i_ext_ven_tasya_cd03   CONSTANT VARCHAR2(100) := '他社コード３';
    -- 他社台数３
    cv_i_ext_ven_tasya_ds03   CONSTANT VARCHAR2(100) := '他社台数３';
    -- 他社コード４
    cv_i_ext_ven_tasya_cd04   CONSTANT VARCHAR2(100) := '他社コード４';
    -- 他社台数４
    cv_i_ext_ven_tasya_ds04   CONSTANT VARCHAR2(100) := '他社台数４';
    -- 他社コード５
    cv_i_ext_ven_tasya_cd05   CONSTANT VARCHAR2(100) := '他社コード５';
    -- 他社台数５
    cv_i_ext_ven_tasya_ds05   CONSTANT VARCHAR2(100) := '他社台数５';
    -- 廃棄フラグ
    cv_i_ext_ven_haiki_flg    CONSTANT VARCHAR2(100) := '廃棄フラグ';
    -- 資産区分
    cv_i_ext_ven_sisan_kbn    CONSTANT VARCHAR2(100) := '資産区分';
    -- 購買日付
    cv_i_ext_ven_kobai_ymd    CONSTANT VARCHAR2(100) := '購買日付';
    -- 購買金額
    cv_i_ext_ven_kobai_kg     CONSTANT VARCHAR2(100) := '購買金額';
    -- 安全設置基準
    cv_i_ext_safty_level      CONSTANT VARCHAR2(100) := '安全設置基準';
    -- 先月末設置先顧客コード
    cv_i_ext_last_inst_cust_code  CONSTANT VARCHAR2(100) := '先月末設置先顧客コード';
    -- 先月末機器状態
    cv_i_ext_last_jotai_kbn   CONSTANT VARCHAR2(100) := '先月末機器状態';
    -- 先月末年月
    cv_i_ext_last_year_month  CONSTANT VARCHAR2(100) := '先月末年月';
    -- カウンターNo.
    cv_count_no               CONSTANT VARCHAR2(100) := 'COUNT_NO';
    -- 作業会社コード
    cv_sagyougaisya_cd        CONSTANT VARCHAR2(100) := 'SAGYOUGAISYA_CD'; 
    -- 事業所コード
    cv_jigyousyo_cd           CONSTANT VARCHAR2(100) := 'JIGYOUSYO_CD';
    -- 最終作業伝票No.
    cv_den_no                 CONSTANT VARCHAR2(100) := 'DEN_NO';
    -- 最終作業区分
    cv_job_kbn                CONSTANT VARCHAR2(100) := 'JOB_KBN';
    -- 最終作業進捗
    cv_sintyoku_kbn           CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN';
    -- 最終作業完了予定日
    cv_yotei_dt               CONSTANT VARCHAR2(100) := 'YOTEI_DT';
    -- 最終作業完了日
    cv_kanryo_dt              CONSTANT VARCHAR2(100) := 'KANRYO_DT';
    -- 最終整備内容
    cv_sagyo_level            CONSTANT VARCHAR2(100) := 'SAGYO_LEVEL';
    -- 最終設置伝票No.
    cv_den_no2                CONSTANT VARCHAR2(100) := 'DEN_NO2';
    -- 最終設置区分
    cv_job_kbn2               CONSTANT VARCHAR2(100) := 'JOB_KBN2';
    -- 最終設置進捗
    cv_sintyoku_kbn2          CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN2';
    -- 入庫日
    cv_nyuko_dt               CONSTANT VARCHAR2(100) := 'NYUKO_DT';
    -- 引揚会社コード
    cv_hikisakigaisya_cd      CONSTANT VARCHAR2(100) := 'HIKISAKIGAISYA_CD';
    -- 引揚事業所コード
    cv_hikisakijigyosyo_cd    CONSTANT VARCHAR2(100) := 'HIKISAKIJIGYOSYO_CD';
    -- 設置先担当者名
    cv_setti_tanto            CONSTANT VARCHAR2(100) := 'SETTI_TANTO';
    -- 設置先tel1
    cv_setti_tel1             CONSTANT VARCHAR2(100) := 'SETTI_TEL1';
    -- 設置先tel2
    cv_setti_tel2             CONSTANT VARCHAR2(100) := 'SETTI_TEL2';
    -- 設置先tel3
    cv_setti_tel3             CONSTANT VARCHAR2(100) := 'SETTI_TEL3';
    -- 廃棄決裁日
    cv_haikikessai_dt         CONSTANT VARCHAR2(100) := 'HAIKIKESSAI_DT';
    -- 転売廃棄業者
    cv_tenhai_tanto           CONSTANT VARCHAR2(100) := 'TENHAI_TANTO';
    -- 転売廃棄伝票№
    cv_tenhai_den_no          CONSTANT VARCHAR2(100) := 'TENHAI_DEN_NO';
    -- 所有者
    cv_syoyu_cd               CONSTANT VARCHAR2(100) := 'SYOYU_CD';
    -- 転売廃棄状況フラグ
    cv_tenhai_flg             CONSTANT VARCHAR2(100) := 'TENHAI_FLG';
    -- 転売完了区分
    cv_kanryo_kbn             CONSTANT VARCHAR2(100) := 'KANRYO_KBN';
    -- 削除フラグ
    cv_sakujo_flg             CONSTANT VARCHAR2(100) := 'SAKUJO_FLG';
    -- 最終顧客コード
    cv_ven_kyaku_last         CONSTANT VARCHAR2(100) := 'VEN_KYAKU_LAST';
    -- 他社コード１
    cv_ven_tasya_cd01         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD01';
    -- 他社台数１
    cv_ven_tasya_daisu01      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU01';
    -- 他社コード2
    cv_ven_tasya_cd02         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD02';
    -- 他社台数2
    cv_ven_tasya_daisu02      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU02';
    -- 他社コード3
    cv_ven_tasya_cd03         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD03';
    -- 他社台数3
    cv_ven_tasya_daisu03      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU03';
    -- 他社コード4
    cv_ven_tasya_cd04         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD04';
    -- 他社台数4
    cv_ven_tasya_daisu04      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU04';
    -- 他社コード5
    cv_ven_tasya_cd05         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD05';
    -- 他社台数5
    cv_ven_tasya_daisu05      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU05';
    -- 廃棄フラグ
    cv_ven_haiki_flg          CONSTANT VARCHAR2(100) := 'VEN_HAIKI_FLG';
    -- 資産区分
    cv_ven_sisan_kbn          CONSTANT VARCHAR2(100) := 'VEN_SISAN_KBN';
    -- 購買日付
    cv_ven_kobai_ymd          CONSTANT VARCHAR2(100) := 'VEN_KOBAI_YMD';
    -- 購買金額
    cv_ven_kobai_kg           CONSTANT VARCHAR2(100) := 'VEN_KOBAI_KG';
    -- 安全設置基準
    cv_safty_level            CONSTANT VARCHAR2(100) := 'SAFTY_LEVEL';
    -- 先月末設置先顧客コード
    cv_last_inst_cust_code    CONSTANT VARCHAR2(100) := 'LAST_INST_CUST_CODE';
    -- 先月末機器状態
    cv_last_jotai_kbn         CONSTANT VARCHAR2(100) := 'LAST_JOTAI_KBN';
    -- 先月末年月
    cv_last_year_month        CONSTANT VARCHAR2(100) := 'LAST_YEAR_MONTH';
/*20090326_matsunaka_ST183 END*/
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    -- 取得価格
    cv_vd_shutoku_kg          CONSTANT VARCHAR2(100) := 'VD_SHUTOKU_KG';
    -- 申告地
    cv_dclr_place             CONSTANT VARCHAR2(100) := 'DCLR_PLACE';
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- *** ローカル変数 ***
    -- 業務処理日
    ld_process_date           DATE;
    -- コンカレント入力パラメータなしメッセージ格納用
    lv_noprm_msg              VARCHAR2(5000);  
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value              VARCHAR2(1000);
    -- 登録用組織コード
    lv_inv_mst_org_code       VARCHAR2(100);
    -- 登録用検証組織コード
    lv_vld_org_code           VARCHAR2(100);
    -- 登録用セグメント
    lv_bukken_item            VARCHAR2(100);
    -- ステータス名
    lv_status_name            VARCHAR2(100);
    -- 取得データメッセージ出力用
    lv_msg                    VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    
    -- ============================
    -- 入力パラメータメッセージ出力
    -- ============================
    --ファイルID
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_33             --メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id
                       ,iv_token_value1 => in_file_id
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    --フォーマットパターン
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_34             --メッセージコード
                       ,iv_token_name1  => cv_tkn_format
                       ,iv_token_value1 => iv_format
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- ==========================
    -- 入力パラメータ必須チェック
    -- ==========================
    --ファイルID
    IF (in_file_id IS NULL) THEN
      -- =================================
      -- 入力パラメータなしメッセージ出力(異常終了させること) 
      -- =================================
      lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name           --アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_01             --メッセージコード
                        );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日付取得に失敗した場合
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    ld_process_date :=TRUNC(gd_process_date);
--
    -- ====================
    -- 変数初期化処理 
    -- ====================
    lv_tkn_value := NULL;
--
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
                    cv_inv_mst_org_code
                   ,lv_inv_mst_org_code
                   ); -- 在庫マスタ組織
    FND_PROFILE.GET(
                    cv_vld_org_code
                   ,lv_vld_org_code
                   ); -- 検証組織
    FND_PROFILE.GET(
                    cv_bukken_item
                   ,lv_bukken_item
                   ); -- 物件用品目
--
    -- プロファイル値取得に失敗した場合
    -- 在庫マスタ組織取得失敗時
    IF (lv_inv_mst_org_code IS NULL) THEN
      lv_tkn_value := cv_inv_mst_org_code;
    -- 検証組織取得失敗時
    ELSIF (lv_vld_org_code IS NULL) THEN
      lv_tkn_value := cv_vld_org_code;
    -- 物件用品目
    ELSIF (lv_bukken_item IS NULL) THEN
      lv_tkn_value := cv_bukken_item;
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_03             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- =================================
    -- ファイルアップロード名称取得処理 
    -- =================================
    BEGIN
      SELECT flvv.meaning          -- ファイルアップロード名称
      INTO   gv_file_name
      FROM   fnd_lookup_values_vl  flvv                               -- 参照タイプ
      WHERE  flvv.lookup_type      = cv_xxcso1_file_name
      AND    flvv.lookup_code      = cv_xxcso1_file_code
      AND    flvv.enabled_flag     = 'Y'
      AND    NVL(flvv.start_date_active, ld_process_date) <= ld_process_date
      AND    NVL(flvv.end_date_active,   ld_process_date) >= ld_process_date;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_35             -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --取得したファイルアップロード名称をファイル出力
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_36             --メッセージコード
                       ,iv_token_name1  => cv_tkn_upload
                       ,iv_token_value1 => gv_file_name
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    -- ===========================
    -- 在庫マスタの組織ID取得処理 
    -- ===========================
    BEGIN
      SELECT  mp.organization_id                                      -- 組織ID
      INTO    gt_inv_mst_org_id
      FROM    mtl_parameters  mp                                      -- 在庫組織マスタ
      WHERE   mp.organization_code = lv_inv_mst_org_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_mtl_parameters_info       -- トークン値1
                       ,iv_token_name2  => cv_tkn_organization          -- トークンコード2
                       ,iv_token_value2 => lv_inv_mst_org_code          -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_mtl_parameters_info       -- トークン値1
                       ,iv_token_name2  => cv_tkn_organization          -- トークンコード2
                       ,iv_token_value2 => lv_inv_mst_org_code          -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- 在庫マスタの検証組織ID取得処理 
    -- ===============================
    BEGIN
      SELECT  mp.organization_id                                        -- 組織ID
      INTO    gt_vld_org_id
      FROM    mtl_parameters  mp                                        -- 在庫組織マスタ
      WHERE   mp.organization_code = lv_vld_org_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_mtl_parameters_vld        -- トークン値1
                       ,iv_token_name2  => cv_tkn_organization          -- トークンコード2
                       ,iv_token_value2 => lv_vld_org_code              -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_mtl_parameters_vld        -- トークン値1
                       ,iv_token_name2  => cv_tkn_organization          -- トークンコード2
                       ,iv_token_value2 => lv_vld_org_code              -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- 物件用品目ID取得処理 
    -- ====================
    BEGIN
      SELECT msib.inventory_item_id                                     -- 品目ID
      INTO   gt_bukken_item_id
      FROM   mtl_system_items_b msib                                    -- 品目マスタ
      WHERE  msib.segment1 = lv_bukken_item
        AND  msib.organization_id = gt_inv_mst_org_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_mtl_system_items_id       -- トークン値1
                       ,iv_token_name2  => cv_tkn_segment               -- トークンコード2
                       ,iv_token_value2 => lv_bukken_item               -- トークン値2
                       ,iv_token_name3  => cv_tkn_organization_id       -- トークンコード3
                       ,iv_token_value3 => gt_inv_mst_org_id            -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_mtl_system_items_id       -- トークン値1
                       ,iv_token_name2  => cv_tkn_segment               -- トークンコード2
                       ,iv_token_value2 => lv_bukken_item               -- トークン値2
                       ,iv_token_name3  => cv_tkn_organization_id       -- トークンコード3
                       ,iv_token_value3 => gt_inv_mst_org_id            -- トークン値3
                       ,iv_token_name4  => cv_tkn_errmsg                -- トークンコード4
                       ,iv_token_value4 => SQLERRM                      -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--    
    -- =================================
    -- インスタンスステータスID取得処理 
    -- =================================
    -- 初期化
    lv_status_name   := '';
    -- 「使用可」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_2
                          ,ld_process_date);
--
      SELECT cis.instance_status_id                                     -- インスタンスステータスID
      INTO   gt_instance_status_id_2
      FROM   csi_instance_statuses cis                                  -- インスタンスステータスマスタ
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, ld_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- トークン値1
                       ,iv_token_name2  => cv_tkn_status_name           -- トークンコード2
                       ,iv_token_value2 => cv_statuses_name02           -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_09             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- トークン値1
                       ,iv_token_name2  => cv_tkn_status_name           -- トークンコード2
                       ,iv_token_value2 => cv_statuses_name02           -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- 取引タイプID取得処理 
    -- ====================
    BEGIN
      SELECT ctt.transaction_type_id                                    -- トランザクションタイプID
      INTO   gt_txn_type_id
      FROM   csi_txn_types ctt                                          -- 取引タイプ
      WHERE  ctt.source_transaction_type  = cv_src_transaction_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_csi_txn_types             -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- トークンコード2
                       ,iv_token_value2 => cv_src_transaction_type      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_11             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_csi_txn_types             -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- トークンコード2
                       ,iv_token_value2 => cv_src_transaction_type      -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- 追加属性ID取得処理 
    -- ====================
    -- 初期化
    gr_ext_attribs_id_rec := NULL;
--
    -- 追加属性ID(機器状態1（稼動状態）)
    gr_ext_attribs_id_rec.jotai_kbn1 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn1
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn1 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn1          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_jotai_kbn1                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(機器状態2（状態詳細）)
    gr_ext_attribs_id_rec.jotai_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn2
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn2          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_jotai_kbn2                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(機器状態3（廃棄情報）)
    gr_ext_attribs_id_rec.jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn3
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn3 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn3          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_jotai_kbn3                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(リース区分)
    gr_ext_attribs_id_rec.lease_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_lease_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.lease_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_lease_kbn           -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_lease_kbn                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(地区コード)
    gr_ext_attribs_id_rec.chiku_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_chiku_cd
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.chiku_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_chiku_cd            -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_chiku_cd                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/*20090326_matsunaka_ST183 START*/
    -- 追加属性ID(カウンターNo.)
    gr_ext_attribs_id_rec.count_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_count_no
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.count_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_count_no            -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_count_no                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(作業会社コード)
    gr_ext_attribs_id_rec.sagyougaisya_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                cv_sagyougaisya_cd
                                               ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sagyougaisya_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_sagyougaisya_cd     -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_sagyougaisya_cd                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(事業所コード)
    gr_ext_attribs_id_rec.jigyousyo_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_jigyousyo_cd
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jigyousyo_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_jigyousyo_cd        -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_jigyousyo_cd                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終作業伝票No.)
    gr_ext_attribs_id_rec.den_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                       cv_den_no
                                      ,ld_process_date);
    IF (gr_ext_attribs_id_rec.den_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_den_no              -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_den_no                    -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終作業区分)
    gr_ext_attribs_id_rec.job_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                        cv_job_kbn
                                       ,ld_process_date);
    IF (gr_ext_attribs_id_rec.job_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_job_kbn             -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_job_kbn                   -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終作業進捗)
    gr_ext_attribs_id_rec.sintyoku_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_sintyoku_kbn
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sintyoku_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_sintyoku_kbn        -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_sintyoku_kbn              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終作業完了予定日)
    gr_ext_attribs_id_rec.yotei_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_yotei_dt
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.yotei_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_yotei_dt            -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_yotei_dt                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終作業完了日)
    gr_ext_attribs_id_rec.kanryo_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_kanryo_dt
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.kanryo_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_kanryo_dt           -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_kanryo_dt                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終整備内容)
    gr_ext_attribs_id_rec.sagyo_level := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                            cv_sagyo_level
                                           ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sagyo_level IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_sagyo_level         -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_sagyo_level               -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 最終設置伝票No.
    gr_ext_attribs_id_rec.den_no2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                        cv_den_no2
                                       ,ld_process_date);
    IF (gr_ext_attribs_id_rec.den_no2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_den_no2             -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_den_no2                   -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終設置区分)
    gr_ext_attribs_id_rec.job_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_job_kbn2
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.job_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_job_kbn2            -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_job_kbn2                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終設置進捗)
    gr_ext_attribs_id_rec.sintyoku_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_sintyoku_kbn2
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sintyoku_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_sintyoku_kbn2       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_sintyoku_kbn2             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(入庫日)
    gr_ext_attribs_id_rec.nyuko_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_nyuko_dt
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.nyuko_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_nyuko_dt            -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_nyuko_dt                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(引揚会社コード)
    gr_ext_attribs_id_rec.hikisakigaisya_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                  cv_hikisakigaisya_cd
                                                 ,ld_process_date);
    IF (gr_ext_attribs_id_rec.hikisakigaisya_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_hikisakicmy_cd      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_hikisakigaisya_cd                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(引揚事業所コード)
    gr_ext_attribs_id_rec.hikisakijigyosyo_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                    cv_hikisakijigyosyo_cd
                                                   ,ld_process_date);
    IF (gr_ext_attribs_id_rec.hikisakijigyosyo_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_hikisakilct_cd      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_hikisakijigyosyo_cd       -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(設置先担当者名)
    gr_ext_attribs_id_rec.setti_tanto := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tanto
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tanto IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_setti_tanto         -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_setti_tanto               -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(設置先tel1)
    gr_ext_attribs_id_rec.setti_tel1 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel1
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel1 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_setti_tel1          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_setti_tel1                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(設置先tel2)
    gr_ext_attribs_id_rec.setti_tel2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel2
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_setti_tel2          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_setti_tel2                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(設置先tel3)
    gr_ext_attribs_id_rec.setti_tel3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel3
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel3 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_setti_tel3          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_setti_tel3                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(廃棄決裁日)
    gr_ext_attribs_id_rec.haikikessai_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_haikikessai_dt
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.haikikessai_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_haikikessai_dt      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_haikikessai_dt            -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(転売廃棄業者)
    gr_ext_attribs_id_rec.tenhai_tanto := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_tenhai_tanto
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_tanto IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_tenhai_tanto        -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_tenhai_tanto              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(転売廃棄伝票№)
    gr_ext_attribs_id_rec.tenhai_den_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_tenhai_den_no
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_den_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_tenhai_den_no       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_tenhai_den_no             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(所有者)
    gr_ext_attribs_id_rec.syoyu_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_syoyu_cd
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.syoyu_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_syoyu_cd            -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_syoyu_cd                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(転売廃棄状況フラグ)
    gr_ext_attribs_id_rec.tenhai_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_tenhai_flg
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_tenhai_flg          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_tenhai_flg                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(転売完了区分)
    gr_ext_attribs_id_rec.kanryo_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_kanryo_kbn
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.kanryo_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_kanryo_kbn          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_kanryo_kbn                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(削除フラグ)
    gr_ext_attribs_id_rec.sakujo_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_sakujo_flg
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sakujo_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_sakujo_flg          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_sakujo_flg                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(最終顧客コード)
    gr_ext_attribs_id_rec.ven_kyaku_last := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_kyaku_last
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kyaku_last IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_kyaku_last      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_kyaku_last            -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社コード１)
    gr_ext_attribs_id_rec.ven_tasya_cd01 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd01
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd01      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_cd01            -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社台数１)
    gr_ext_attribs_id_rec.ven_tasya_daisu01 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu01
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds01      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_daisu01         -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社コード2)
    gr_ext_attribs_id_rec.ven_tasya_cd02 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd02
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd02 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd02      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_cd02                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社台数2)
    gr_ext_attribs_id_rec.ven_tasya_daisu02 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu02
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu02 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds02      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_daisu02         -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社コード3)
    gr_ext_attribs_id_rec.ven_tasya_cd03 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd03
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd03 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd03      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_cd03            -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社台数3)
    gr_ext_attribs_id_rec.ven_tasya_daisu03 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu03
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu03 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds03      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_daisu03         -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社コード4)
    gr_ext_attribs_id_rec.ven_tasya_cd04 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd04
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd04 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd04      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_cd04                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社台数4)
    gr_ext_attribs_id_rec.ven_tasya_daisu04 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu04
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu04 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds04          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_daisu04             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社コード5)
    gr_ext_attribs_id_rec.ven_tasya_cd05 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd05
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd05 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd05      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_cd05                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(他社台数5)
    gr_ext_attribs_id_rec.ven_tasya_daisu05 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu05
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds05          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_tasya_daisu05             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(廃棄フラグ)
    gr_ext_attribs_id_rec.ven_haiki_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_haiki_flg
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_haiki_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_haiki_flg       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_haiki_flg             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(資産区分)
    gr_ext_attribs_id_rec.ven_sisan_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_sisan_kbn
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_sisan_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_sisan_kbn       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_sisan_kbn             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(購買日付)
    gr_ext_attribs_id_rec.ven_kobai_ymd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_kobai_ymd
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kobai_ymd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_kobai_ymd       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_kobai_ymd             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(購買金額)
    gr_ext_attribs_id_rec.ven_kobai_kg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_kobai_kg
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kobai_kg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_ven_kobai_kg        -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_ven_kobai_kg              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(安全設置基準)
    gr_ext_attribs_id_rec.safty_level := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                            cv_safty_level
                                           ,ld_process_date);
    IF (gr_ext_attribs_id_rec.safty_level IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_safty_level         -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_safty_level               -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(先月末設置先顧客コード)
    gr_ext_attribs_id_rec.last_inst_cust_code := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_inst_cust_code
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_inst_cust_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_last_inst_cust_code -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_last_inst_cust_code       -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(先月末機器状態)
    gr_ext_attribs_id_rec.last_jotai_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_jotai_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_jotai_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_last_jotai_kbn      -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_last_jotai_kbn            -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(先月末年月)
    gr_ext_attribs_id_rec.last_year_month := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_year_month
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_year_month IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_last_year_month     -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_last_year_month           -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/*20090326_matsunaka_ST183 END*/
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    -- 追加属性ID(取得価格)
    gr_ext_attribs_id_rec.vd_shutoku_kg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_vd_shutoku_kg
                                             ,ld_process_date
                                           );
    IF ( gr_ext_attribs_id_rec.vd_shutoku_kg IS NULL ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_54 -- メッセージ
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => lv_msg                       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_vd_shutoku_kg             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- 追加属性ID(申告地)
    gr_ext_attribs_id_rec.dclr_place := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_dclr_place
                                          ,ld_process_date
                                        );
    IF ( gr_ext_attribs_id_rec.dclr_place IS NULL ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_53 -- メッセージ
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => lv_msg                       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_dclr_place                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- ========================
    -- 本社/工場区分(本社)取得 
    -- ========================
    BEGIN
      SELECT ffvv.flex_value
      INTO   gv_owner_company
      FROM   fnd_flex_values_vl  ffvv
            ,fnd_flex_value_sets ffvs
      WHERE  ffvv.flex_value_set_id = ffvs.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_cff_owner_company_type
      AND    ffvv.enabled_flag = 'Y'
      AND    ld_process_date BETWEEN NVL(ffvv.start_date_active,ld_process_date) 
                             AND     NVL(ffvv.end_date_active,ld_process_date)
      AND    ffvv.flex_value_meaning = (SELECT flvv1.meaning
                                        FROM   fnd_lookup_values_vl flvv1
                                        WHERE  flvv1.lookup_type = cv_cso_owner_company_type
                                        AND    flvv1.lookup_code = cv_cso_owner_company_code
                                        AND    ld_process_date BETWEEN NVL(flvv1.start_date_active,ld_process_date) 
                                                               AND     NVL(flvv1.end_date_active,ld_process_date)
                                        AND    flvv1.enabled_flag = 'Y');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_37             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_csi_txn_flex              -- トークン値1
                       ,iv_token_name2  => cv_tkn_value_set_name        -- トークンコード2
                       ,iv_token_value2 => cv_owner_company             -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_38             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_csi_txn_flex              -- トークン値1
                       ,iv_token_name2  => cv_tkn_value_set_name        -- トークンコード2
                       ,iv_token_value2 => cv_owner_company             -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--    
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
   * Procedure Name   : get_item_instances
   * Description      : 物件情報抽出 (A-2)
   ***********************************************************************************/
  PROCEDURE get_item_instances(
     in_file_id              IN     NUMBER                  -- ファイルID
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_instances'; -- プログラム名
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
    -- テーブル名
    cv_table_name            CONSTANT VARCHAR2(100) := 'ファイルアップロードIF';
--
    -- *** ローカル変数 ***
    lv_file_name             xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSVファイル名
    lv_msg                   VARCHAR2(5000);
--
    -- *** ローカル例外 ***
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
  -- ***************************************************
  -- 1.CSVファイル名取得
  -- ***************************************************
    SELECT   xciwd.file_name
    INTO     lv_file_name
    FROM     xxccp_mrp_file_ul_interface    xciwd
    WHERE    xciwd.file_id = in_file_id;
--
    --取得したCSVファイル名をファイル出力
    lv_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_39             --メッセージコード
                       ,iv_token_name1  => cv_tkn_csv_upload
                       ,iv_token_value1 => lv_file_name
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_msg       || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    -- ***************************************************
    -- 2.BLOBデータ変換
    -- ***************************************************
    --共通アップロードデータ変換処理
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id       -- ファイルＩＤ
     ,ov_file_data => gr_file_data_tbl -- 変換後VARCHAR2データ
     ,ov_retcode   => lv_retcode
     ,ov_errbuf    => lv_errbuf
     ,ov_errmsg    => lv_errmsg
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_40,    -- メッセージ：データ変換エラー
                     cv_tkn_table,
                     cv_table_name,
                     cv_tkn_file_id,
                     in_file_id,
                     cv_tkn_errmsg,
                     SQLERRM);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END get_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_validate
   * Description      : データ妥当性チェック (A-3)
   ***********************************************************************************/
  PROCEDURE chk_data_validate(
     it_blob_data            IN     xxccp_common_pkg2.g_file_data_tbl                  -- blobデータ(行単位)
    ,in_data_num             IN     NUMBER                  -- 配列番号
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_validate'; -- プログラム名
    -- 物件コード
    cv_object_code  CONSTANT VARCHAR2(100) := '物件コード';
    -- 機種コード
    cv_serial_code  CONSTANT VARCHAR2(100) := '機種コード';
    -- 拠点コード
    cv_base_code    CONSTANT VARCHAR2(100) := '拠点コード';
    -- 物件データ
    cv_object_data  CONSTANT VARCHAR2(100) := '物件データ';

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
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
--    cn_format_col_cnt        CONSTANT NUMBER := 3;  -- 項目数
    cn_format_col_cnt        CONSTANT NUMBER := 6;  -- 項目数
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- *** ローカル変数 ***
    lv_object_front          VARCHAR2(3);
    lv_object_tail           VARCHAR2(6);
    lv_substr                VARCHAR2(1);
    lb_ret                   BOOLEAN;
    lb_format_flag           BOOLEAN := TRUE;
    lv_tmp                   VARCHAR2(2000);
    ln_pos                   NUMBER;
    ln_cnt                   NUMBER := 1;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    lv_msg                   VARCHAR2(5000);
    lv_vd_shutoku_kg         VARCHAR2(2000); -- チェック用
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- *** ローカル例外 ***
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- ***************************************************
    -- 1.項目数取得
    -- ***************************************************
    IF (it_blob_data(in_data_num) IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := it_blob_data(in_data_num);
      LOOP
        ln_pos := INSTR(lv_tmp, cv_msg_conm);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.項目数チェック
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_51           -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm             -- トークンコード1
                     ,iv_token_value1 => cv_object_data             -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_value          -- トークンコード1
                     ,iv_token_value2 => it_blob_data(in_data_num)  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- ***************************************************
    -- 2.blobデータ分割
    -- ***************************************************
    --物件コード
    gr_blob_data.object_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,1);
    IF (gr_blob_data.object_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_object_code,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --機種コード
    gr_blob_data.serial_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,2);
    IF (gr_blob_data.serial_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_serial_code,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --拠点コード
    gr_blob_data.base_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                   ,cv_msg_conm
                                                                   ,3);
    IF (gr_blob_data.base_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_base_code,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    -- リース区分
    gr_blob_data.lease_kbn := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                   ,cv_msg_conm
                                                                   ,4);
--
    -- 申告地
    gr_blob_data.dclr_place := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                    ,cv_msg_conm
                                                                    ,5);
--
    -- 取得価格
    lv_vd_shutoku_kg := NULL;
    lv_vd_shutoku_kg := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                             ,cv_msg_conm
                                                             ,6);
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- ***************************************************
    -- 3.項目値妥当性チェック
    -- ***************************************************
    --物件コード書式チェック
    lv_substr := SUBSTRB(gr_blob_data.object_code,4,1);
    IF (lv_substr = '-') THEN
      lv_object_front := SUBSTRB(gr_blob_data.object_code,1,3);
      lv_object_tail  := SUBSTRB(gr_blob_data.object_code,5);
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                   cv_app_name,         -- アプリケーション短縮名：XXCSO
                   cv_tkn_number_42,
                   cv_tkn_base_value,
                   gr_blob_data.object_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    -- 取得価格マイナス値チェック
    lv_substr := SUBSTRB(lv_vd_shutoku_kg,1,1);
    IF ( lv_substr = cv_hyphen ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_54 -- メッセージ
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_app_name
                     ,cv_tkn_number_60
                     ,cv_tkn_eigyo
                     ,lv_msg
                     ,cv_tkn_base_value
                     ,lv_vd_shutoku_kg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    --物件コード半角数字チェック
    lb_ret := xxccp_common_pkg.chk_number(
                iv_check_char   => lv_object_front||lv_object_tail);
    IF (lb_ret = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_43,
                     cv_tkn_item,
                     cv_object_code,
                     cv_tkn_base_value,
                     gr_blob_data.object_code
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    -- 取得価格半角数字チェック
    lb_ret := xxccp_common_pkg.chk_number(
                iv_check_char   => lv_vd_shutoku_kg
              );
    IF ( lb_ret = FALSE ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_54 -- メッセージ
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_app_name
                     ,cv_tkn_number_43
                     ,cv_tkn_item
                     ,lv_msg
                     ,cv_tkn_base_value
                     ,lv_vd_shutoku_kg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    --物件コードLENGTHチェック
    IF (LENGTHB(gr_blob_data.object_code) <> 10) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_44,
                     cv_tkn_item,
                     cv_object_code,
                     cv_tkn_base_value,
                     gr_blob_data.object_code
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --機種コードLENGTHチェック
    IF (LENGTHB(gr_blob_data.serial_code) > 14) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_44,
                     cv_tkn_item,
                     cv_serial_code,
                     cv_tkn_base_value,
                     gr_blob_data.serial_code
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    -- 取得価格LENGTHチェック
    IF ( LENGTHB(lv_vd_shutoku_kg) > 10 ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_54 -- メッセージ
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_app_name
                     ,cv_tkn_number_44
                     ,cv_tkn_item
                     ,lv_msg
                     ,cv_tkn_base_value
                     ,lv_vd_shutoku_kg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    gr_blob_data.vd_shutoku_kg := lv_vd_shutoku_kg;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END chk_data_validate;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_master
   * Description      : データマスタチェック (A-4)
   ***********************************************************************************/
  PROCEDURE chk_data_master(
     ov_errbuf               OUT    NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_master'; -- プログラム名
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
    -- テーブル名
    cv_table_object          CONSTANT VARCHAR2(100) := 'インストールベースマスタ';
    cv_table_serial          CONSTANT VARCHAR2(100) := '機種マスタビュー';
    cv_table_hazard          CONSTANT VARCHAR2(100) := '機器区分マスタビュー';
    cv_select_process        CONSTANT VARCHAR2(100) := '抽出';
    cv_object_code           CONSTANT VARCHAR2(100) := '物件コード';
    cv_serial_code           CONSTANT VARCHAR2(100) := '機種コード';
--
    -- *** ローカル変数 ***
    ln_cnt          NUMBER;
    lv_hazard_class po_un_numbers_vl.hazard_class_id%TYPE;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    lv_msg                   VARCHAR2(5000);
    lv_msg2                  VARCHAR2(5000);
    lb_ret                   BOOLEAN DEFAULT TRUE;
    lt_lease_kbn             po_un_numbers_vl.attribute13%TYPE; -- リース区分
    lt_vd_shutoku_kg         po_un_numbers_vl.attribute14%TYPE; -- 取得価格
    lt_dclr_place            fnd_flex_values.flex_value%TYPE;   -- 申告地
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- *** ローカル例外 ***
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
  -- ***************************************************
  -- 1.物件コード重複チェック
  -- ***************************************************
    BEGIN
      SELECT COUNT(instance_id)
      INTO   ln_cnt
      FROM   csi_item_instances
      WHERE  external_reference = gr_blob_data.object_code;
--
    EXCEPTION
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_table_object               -- トークン値1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2  => SQLERRM                       -- トークン値2
                       ,iv_token_name3   => cv_tkn_process                -- トークンコード3
                       ,iv_token_value3  => cv_select_process             -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF (ln_cnt > 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_app_name                   -- アプリケーション短縮名
                     ,iv_name          => cv_tkn_number_46              -- メッセージコード
                     ,iv_token_name1   => cv_tkn_bukken                 -- トークンコード1
                     ,iv_token_value1  => gr_blob_data.object_code      -- トークン値1
                     ,iv_token_name2   => cv_tkn_base_value             -- トークンコード2
                     ,iv_token_value2  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                          cv_msg_conm||gr_blob_data.base_code             -- トークン値2
      );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  -- ***************************************************
  -- 2.機種マスタ存在チェック
  -- ***************************************************
    BEGIN
      SELECT flvv.meaning
            ,punv.attribute3
            ,punv.hazard_class_id
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
            ,punv.attribute13
            ,punv.attribute14
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
      INTO   gv_maker_name
            ,gv_age_type
            ,lv_hazard_class
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
            ,lt_lease_kbn
            ,lt_vd_shutoku_kg
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
      FROM   po_un_numbers_vl punv
            ,fnd_lookup_values_vl flvv
      WHERE  punv.un_number = gr_blob_data.serial_code
      AND    TRUNC(NVL(punv.inactive_date,gd_process_date + 1)) > TRUNC(gd_process_date)
      AND    flvv.lookup_type = 'XXCSO_CSI_MAKER_CODE'
      AND    flvv.lookup_code(+) = punv.attribute2
      AND    TRUNC(gd_process_date) BETWEEN NVL(flvv.start_date_active, TRUNC(gd_process_date))
                                   AND     NVL(flvv.end_date_active, TRUNC(gd_process_date))
      AND    flvv.enabled_flag = 'Y';
--
    EXCEPTION
      -- 抽出できなかった場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_47              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_item                   -- トークンコード1
                       ,iv_token_value1  => cv_serial_code                -- トークン値1
                       ,iv_token_name2   => cv_tkn_value                  -- トークンコード2
                       ,iv_token_value2  => gr_blob_data.serial_code      -- トークン値2
                       ,iv_token_name3   => cv_tkn_table                  -- トークンコード3
                       ,iv_token_value3  => cv_table_serial               -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_table_serial               -- トークン値1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2  => SQLERRM                       -- トークン値2
                       ,iv_token_name3   => cv_tkn_process                -- トークンコード3
                       ,iv_token_value3  => cv_select_process             -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  -- ***************************************************
  -- 3.機器区分マスタ存在チェック
  -- ***************************************************
    BEGIN
      SELECT phcv.hazard_class
      INTO   gv_hazard_class
      FROM   po_hazard_classes_vl phcv
      WHERE  phcv.hazard_class_id = lv_hazard_class
      AND    TRUNC(NVL(phcv.inactive_date,gd_process_date + 1)) > TRUNC(gd_process_date);
--
    EXCEPTION
      -- 抽出できなかった場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_50              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_value                  -- トークンコード1
                       ,iv_token_value1  => gr_blob_data.serial_code      -- トークン値1
                       ,iv_token_name2   => cv_tkn_value2                 -- トークンコード2
                       ,iv_token_value2  => lv_hazard_class               -- トークン値2
                       ,iv_token_name3   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value3  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_table_hazard               -- トークン値1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2  => SQLERRM                       -- トークン値2
                       ,iv_token_name3   => cv_tkn_process                -- トークンコード3
                       ,iv_token_value3  => cv_select_process             -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
  -- ***************************************************
  -- 4.リース区分チェック
  -- ***************************************************
    -- 分割データのリース区分に値が設定されていない場合
    IF ( gr_blob_data.lease_kbn IS NULL ) THEN
      -- 機種マスタの値を設定
      gr_blob_data.lease_kbn := lt_lease_kbn;
    END IF;
    --
    -- 機種マスタのリース区分もNULLである場合
    IF ( gr_blob_data.lease_kbn IS NULL ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_52 -- メッセージ
                   );
      lv_msg2   := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_55 -- メッセージ
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_56               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                     ,iv_token_value1 => lv_msg                         -- トークン値1
                     ,iv_token_name2  => cv_tkn_table                   -- トークンコード2
                     ,iv_token_value2 => lv_msg2                        -- トークン値2
                     ,iv_token_name3  => cv_tkn_base_value              -- トークンコード3
                     ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                         gr_blob_data.serial_code || cv_msg_conm ||
                                         gr_blob_data.base_code   || cv_msg_conm ||
                                         gr_blob_data.lease_kbn   || cv_msg_conm ||
                                         gr_blob_data.dclr_place  || cv_msg_conm ||
                                         gr_blob_data.vd_shutoku_kg     -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- リース区分のマスタチェック
    BEGIN
      SELECT flvv.lookup_code     lookup_code
      INTO   lt_lease_kbn
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type  = cv_xxcso1_lease_kbn
      AND    flvv.lookup_code  = gr_blob_data.lease_kbn
      AND    flvv.enabled_flag = cv_y
      AND    gd_process_date   BETWEEN NVL(flvv.start_date_active, gd_process_date)
                               AND     NVL(flvv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_52               -- メッセージ
                     );
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_57               -- メッセージ
                       ,iv_token_name1  => cv_tkn_lookup_type_name        -- トークンコード1
                       ,iv_token_value1 => cv_xxcso1_lease_kbn            -- トークン値1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_56               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                       ,iv_token_value1 => lv_msg                         -- トークン値1
                       ,iv_token_name2  => cv_tkn_table                   -- トークンコード2
                       ,iv_token_value2 => lv_msg2                        -- トークン値2
                       ,iv_token_name3  => cv_tkn_base_value              -- トークンコード3
                       ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg     -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_57               -- メッセージ
                       ,iv_token_name1  => cv_tkn_lookup_type_name        -- トークンコード1
                       ,iv_token_value1 => cv_xxcso1_lease_kbn            -- トークン値1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_45               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                   -- トークンコード1
                       ,iv_token_value1 => lv_msg2                        -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg                  -- トークンコード2
                       ,iv_token_value2 => SQLERRM                        -- トークン値2
                       ,iv_token_name3  => cv_tkn_process                 -- トークンコード3
                       ,iv_token_value3 => cv_select_process              -- トークン値3
                       ,iv_token_name4  => cv_tkn_base_value              -- トークンコード4
                       ,iv_token_value4 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg      -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  -- ***************************************************
  -- 5.申告地チェック
  -- ***************************************************
    -- リース区分が固定資産以外の場合
    IF ( gr_blob_data.lease_kbn <> cv_fixed_assets ) THEN
      -- NULLを設定
      gr_blob_data.dclr_place := NULL;
    -- リース区分が固定資産の場合
    ELSIF ( gr_blob_data.lease_kbn = cv_fixed_assets ) THEN
      -- 申告地に値が設定されていない場合
      IF ( gr_blob_data.dclr_place IS NULL ) THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_53               -- メッセージ
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_59               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                       ,iv_token_value1 => lv_msg                         -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_value              -- トークンコード2
                       ,iv_token_value2 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg     -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
      --
      -- 申告地のマスタチェック
      BEGIN
        SELECT ffv.flex_value       flex_value
        INTO   lt_dclr_place
        FROM   fnd_flex_values      ffv
              ,fnd_flex_values_tl   ffvt
              ,fnd_flex_value_sets  ffvs
        WHERE  ffv.flex_value_id        = ffvt.flex_value_id
        AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
        AND    ffvs.flex_value_set_name = cv_xxcff_dclr_place
        AND    gd_process_date BETWEEN NVL(ffv.start_date_active, gd_process_date)
                               AND     NVL(ffv.end_date_active, gd_process_date)
        AND    ffv.enabled_flag         = cv_y
        AND    ffvt.language            = ct_language
        AND    ffv.flex_value           = gr_blob_data.dclr_place
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_53               -- メッセージ
                       );
          lv_msg2   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_58               -- メッセージ
                         ,iv_token_name1  => cv_tkn_value_set_name          -- トークンコード1
                         ,iv_token_value1 => cv_xxcff_dclr_place            -- トークン値1
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_56               -- メッセージコード
                         ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                         ,iv_token_value1 => lv_msg                         -- トークン値1
                         ,iv_token_name2  => cv_tkn_table                   -- トークンコード2
                         ,iv_token_value2 => lv_msg2                        -- トークン値2
                         ,iv_token_name3  => cv_tkn_base_value              -- トークンコード3
                         ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                             gr_blob_data.serial_code || cv_msg_conm ||
                                             gr_blob_data.base_code   || cv_msg_conm ||
                                             gr_blob_data.lease_kbn   || cv_msg_conm ||
                                             gr_blob_data.dclr_place  || cv_msg_conm ||
                                             gr_blob_data.vd_shutoku_kg     -- トークン値3
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_msg2   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_58               -- メッセージ
                         ,iv_token_name1  => cv_tkn_value_set_name          -- トークンコード1
                         ,iv_token_value1 => cv_xxcff_dclr_place            -- トークン値1
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_45               -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                   -- トークンコード1
                         ,iv_token_value1 => lv_msg2                        -- トークン値1
                         ,iv_token_name2  => cv_tkn_errmsg                  -- トークンコード2
                         ,iv_token_value2 => SQLERRM                        -- トークン値2
                         ,iv_token_name3  => cv_tkn_process                 -- トークンコード3
                         ,iv_token_value3 => cv_select_process              -- トークン値3
                         ,iv_token_name4  => cv_tkn_base_value              -- トークンコード4
                         ,iv_token_value4 => gr_blob_data.object_code || cv_msg_conm ||
                                             gr_blob_data.serial_code || cv_msg_conm ||
                                             gr_blob_data.base_code   || cv_msg_conm ||
                                             gr_blob_data.lease_kbn   || cv_msg_conm ||
                                             gr_blob_data.dclr_place  || cv_msg_conm ||
                                             gr_blob_data.vd_shutoku_kg     -- トークン値4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  -- ***************************************************
  -- 6.取得価格チェック
  -- ***************************************************
    -- リース区分が固定資産以外の場合
    IF ( gr_blob_data.lease_kbn <> cv_fixed_assets ) THEN
      -- NULLを設定
      gr_blob_data.vd_shutoku_kg := NULL;
    -- リース区分が固定資産の場合
    ELSIF ( gr_blob_data.lease_kbn = cv_fixed_assets ) THEN
      -- 分割データの取得価格に値が設定されていない場合
      IF ( gr_blob_data.vd_shutoku_kg IS NULL ) THEN
        -- 機種マスタの値を設定
        gr_blob_data.vd_shutoku_kg := lt_vd_shutoku_kg;
      END IF;
      --
      -- 取得価格に値が設定されていない場合
      IF ( gr_blob_data.vd_shutoku_kg IS NULL ) THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_54               -- メッセージ
                     );
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_55               -- メッセージ
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_56               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                       ,iv_token_value1 => lv_msg                         -- トークン値1
                       ,iv_token_name2  => cv_tkn_table                   -- トークンコード2
                       ,iv_token_value2 => lv_msg2                        -- トークン値2
                       ,iv_token_name3  => cv_tkn_base_value              -- トークンコード3
                       ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg     -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END chk_data_master;
--
  /**********************************************************************************
   * Procedure Name   : get_custmer_data
   * Description      : 顧客情報取得処理 (A-5)
   ***********************************************************************************/
  PROCEDURE get_custmer_data(
     ov_errbuf               OUT    NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_custmer_data'; -- プログラム名
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
    cv_table_cust            CONSTANT VARCHAR2(100) := '顧客マスタサイトビュー';
    cv_select_process        CONSTANT VARCHAR2(100) := '抽出';
    cv_item_cust             CONSTANT VARCHAR2(100) := '顧客コード';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
  -- ***************************************************
  -- 1.顧客情報取得
  -- ***************************************************
    BEGIN
      SELECT casv.cust_account_id                                   -- アカウントID
            ,casv.location_id                                       -- ロケーションID
            ,casv.party_id                                          -- パーティID
            ,casv.party_site_id                                     -- パーティサイトID
            /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
            --,casv.established_site_name                             -- 設置先名
            ,casv.party_name                                        -- 設置先名
            /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
            ,casv.state||casv.city||casv.address1||casv.address2    -- 設置先住所
            ,casv.area_code                                         -- 地区コード
      INTO   gn_account_id
            ,gn_locatoin_id
            ,gn_party_id
            ,gn_party_site_id
            ,gv_established_site
            ,gv_address
            ,gv_address3
      FROM   xxcso_cust_acct_sites_v casv                           -- 顧客マスタサイトビュー
      WHERE  casv.account_number    = gr_blob_data.base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_47              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_item                   -- トークンコード1
                       ,iv_token_value1  => cv_item_cust                  -- トークン値1
                       ,iv_token_name2   => cv_tkn_value                  -- トークンコード2
                       ,iv_token_value2  => gr_blob_data.base_code        -- トークン値2
                       ,iv_token_name3   => cv_tkn_table                  -- トークンコード3
                       ,iv_token_value3  => cv_table_cust                 -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_table_cust                 -- トークン値1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2  => SQLERRM                       -- トークン値2
                       ,iv_token_name3   => cv_tkn_process                -- トークンコード3
                       ,iv_token_value3  => cv_select_process             -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END get_custmer_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_item_instances
   * Description      : 物件データ登録処理 (A-7)
   ***********************************************************************************/
  PROCEDURE insert_item_instances(
     ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_item_instances'; -- プログラム名
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
    cn_num1                  CONSTANT NUMBER        := 1;
    cn_api_version           CONSTANT NUMBER        := 1.0;
    cv_kbn0                  CONSTANT NUMBER        := '0';
    cv_kbn1                  CONSTANT VARCHAR2(1)   := '1'; 
    cv_kbn2                  CONSTANT VARCHAR2(1)   := '2'; 
    cv_unit_of_measure       CONSTANT VARCHAR2(10)  := '台';                -- 単位
    cv_xxcso_ib_info_h       CONSTANT VARCHAR2(100) := '物件関連情報変更履歴テーブル';    -- 抽出内容
    cv_inst_base_insert      CONSTANT VARCHAR2(100) := 'インストールベースマスタ';
    cv_insert_process        CONSTANT VARCHAR2(100) := '登録';
    cv_location_type_code    CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';    -- 現行事業所タイプ
    cv_instance_usage_code   CONSTANT VARCHAR2(100) := 'OUT_OF_ENTERPRISE'; -- インスタンス使用コード
    cv_party_source_table    CONSTANT VARCHAR2(100) := 'HZ_PARTIES';        -- パーティソーステーブル
    cv_relatnsh_type_code    CONSTANT VARCHAR2(100) := 'OWNER';             -- リレーションタイプ
    cv_flg_no                CONSTANT VARCHAR2(1)   := 'N';                 -- フラグNO
    /*20090326_matsunaka_ST183 START*/
    cv_flg_yes               CONSTANT VARCHAR2(1)   := 'Y';                 -- フラグYES
    /*20090326_matsunaka_ST183 END*/
--
    -- *** ローカル変数 ***
    ln_validation_level        NUMBER;                  -- バリデーションレーベル
    lv_commit                  VARCHAR2(1);             -- コミットフラグ
    lv_init_msg_list           VARCHAR2(2000);          -- メッセージリスト
    ln_cnt                     NUMBER;                  -- 配列番号
--
    -- API戻り値格納用
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
--
    -- API入出力レコード値格納用
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
--
    -- *** ローカル例外 ***
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- データの格納
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;

    -- ================================
    -- 1.インスタンスレコード作成
    -- ================================
    l_instance_rec.external_reference         := gr_blob_data.object_code;     -- 外部参照
    l_instance_rec.inventory_item_id          := gt_bukken_item_id;            -- 在庫品目ID
    l_instance_rec.vld_organization_id        := gt_vld_org_id;                -- 検証組織ID
    l_instance_rec.inv_master_organization_id := gt_inv_mst_org_id;            -- 在庫マスター組織ID
    l_instance_rec.quantity                   := cn_num1;                      -- 数量
    l_instance_rec.unit_of_measure            := cv_unit_of_measure;           -- 単位
    l_instance_rec.instance_status_id         := gt_instance_status_id_2;      -- インスタンスステータスID
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 START */
--    l_instance_rec.instance_type_code         := SUBSTRB(gv_hazard_class,1,1); -- インスタンスタイプコード
    l_instance_rec.instance_type_code         := SUBSTRB(gv_hazard_class,1,INSTRB(gv_hazard_class,cv_msg_part_only,1,1)-1); -- インスタンスタイプコード
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 END */
    l_instance_rec.location_type_code         := cv_location_type_code;        -- 現行事業所タイプ
    l_instance_rec.location_id                := gn_party_site_id;             -- 現行事業所ID
    l_instance_rec.install_date               := gd_process_date;              -- 導入日
    l_instance_rec.attribute1                 := gr_blob_data.serial_code;     -- 機種(コード)
    l_instance_rec.attribute4                 := cv_flg_no;                    -- 作業依頼中フラグ
    /*20090326_matsunaka_ST183 START*/
    l_instance_rec.attribute5                 := cv_flg_yes;                   -- 新古台フラグ
    /*20090326_matsunaka_ST183 END*/
    l_instance_rec.instance_usage_code        := cv_instance_usage_code;       -- インスタンス使用コード
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
--
    -- ==================================
    -- 2.登録用設置機器拡張属性値情報作成
    -- ==================================
    -- 機器状態1（稼動状態）
    ln_cnt := 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn2;
--
    -- 機器状態2（状態詳細）
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;
--
    -- 機器状態3（廃棄情報）
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn3;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;
--
    -- リース区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.lease_kbn;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
--    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gr_blob_data.lease_kbn;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- 地区コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.chiku_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gv_address3;
--
/*20090326_matsunaka_ST183 START*/
    -- カウンターNo.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.count_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 作業会社コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyougaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 事業所コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jigyousyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終作業伝票No.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終作業区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終作業進捗
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終作業完了予定日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.yotei_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終作業完了日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終整備内容
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyo_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終設置伝票No.2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終設置区分2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終設置進捗2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 入庫日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.nyuko_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 引揚会社コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakigaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 引揚事業所コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakijigyosyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 設置先担当者名
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 設置先tel1
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 設置先tel2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 設置先tel3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel3;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 廃棄決裁日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.haikikessai_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 転売廃棄業者
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 転売廃棄伝票№
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 所有者
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.syoyu_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 転売廃棄状況フラグ
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 転売完了区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 削除フラグ
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sakujo_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 最終顧客コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kyaku_last;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社コード１
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社台数１
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社コード２
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社台数２
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社コード３
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社台数３
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社コード４
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社台数４
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社コード５
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 他社台数５
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 廃棄フラグ
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_haiki_flg;
    /*20090522_Ohtsuki_T1_1141 START*/
--    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;                                     --( 0 = 未設定 )
    /*20090522_Ohtsuki_T1_1141 END  */
--
    -- 資産区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_sisan_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 購買日付
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_ymd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 購買金額
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_kg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 安全設置基準
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.safty_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 先月末設置先顧客コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_inst_cust_code;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 先月末機器状態
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_jotai_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- 先月末年月
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_year_month;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
/*20090326_matsunaka_ST183 END*/
--
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
    -- 取得価格
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.vd_shutoku_kg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gr_blob_data.vd_shutoku_kg;
--
    -- 申告地
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.dclr_place;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gr_blob_data.dclr_place;
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
--
    -- ====================
    -- 3.パーティデータ作成
    -- ====================
--
    ln_cnt := 1;
    l_party_tab(ln_cnt).party_source_table       := cv_party_source_table;
    l_party_tab(ln_cnt).party_id                 := gn_party_id;
    l_party_tab(ln_cnt).relationship_type_code   := cv_relatnsh_type_code;
    l_party_tab(ln_cnt).contact_flag             := cv_flg_no;
--
    -- ===============================
    -- 4.パーティアカウントデータ作成
    -- ===============================
--
    ln_cnt := 1;
    l_account_tab(ln_cnt).parent_tbl_index       := cn_num1;
    l_account_tab(ln_cnt).party_account_id       := gn_account_id;
    l_account_tab(ln_cnt).relationship_type_code := cv_relatnsh_type_code;
--
    -- ===============================
    -- 5.取引レコードデータ作成
    -- ===============================
--
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;
--
    -- =================================
    -- 6.標準APIより、物件登録処理を行う
    -- =================================
--
    CSI_ITEM_INSTANCE_PUB.create_item_instance(
       p_api_version           => cn_api_version
      ,p_commit                => lv_commit
      ,p_init_msg_list         => lv_init_msg_list
      ,p_validation_level      => ln_validation_level
      ,p_instance_rec          => l_instance_rec
      ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      ,p_party_tbl             => l_party_tab
      ,p_account_tbl           => l_account_tab
      ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
      ,p_org_assignments_tbl   => l_org_assignments_tab
      ,p_asset_assignment_tbl  => l_asset_assignment_tab
      ,p_txn_rec               => l_txn_rec
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
--
    -- 正常終了でない場合
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      IF (FND_MSG_PUB.Count_Msg > 0) THEN
        FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.Get(
             p_msg_index     => i
            ,p_encoded       => cv_encoded_f
            ,p_data          => lv_io_msg_data
            ,p_msg_index_out => ln_io_msg_count
          );
          lv_msg_data := lv_msg_data || lv_io_msg_data;
        END LOOP;
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_app_name                   -- アプリケーション短縮名
                     ,iv_name          => cv_tkn_number_45              -- メッセージコード
                     ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1  => cv_inst_base_insert           -- トークン値1
                     ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                     ,iv_token_value2  => cv_insert_process             -- トークン値2
                     ,iv_token_name3   => cv_tkn_errmsg                 -- トークンコード3
                     ,iv_token_value3  => lv_msg_data                       -- トークン値3
                     ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                     ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                          cv_msg_conm||gr_blob_data.base_code   -- トークン値4
                   );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      END IF;
    END IF;
--
    -- ========================================
    -- 7.物件関連情報変更履歴テーブルの登録処理
    -- ========================================
    BEGIN
      INSERT INTO xxcso_ib_info_h(
         install_code                           -- 物件コード
        ,history_creation_date                  -- 履歴作成日
        ,interface_flag                         -- 連携済フラグ
        ,po_number                              -- 発注番号
        ,manufacturer_name                      -- メーカー名
        ,age_type                               -- 年式
        ,un_number                              -- 機種
        ,install_number                         -- 機番
        ,quantity                               -- 数量
        ,base_code                              -- 拠点コード
        ,owner_company_type                     -- 本社／工場区分
        ,install_name                           -- 設置先名
        ,install_address                        -- 設置先住所
        ,logical_delete_flag                    -- 論理削除フラグ
        ,account_number                         -- 顧客コード
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
        ,declaration_place                       -- 申告地
        ,disposal_intaface_flag                  -- 廃棄連携フラグ
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
        ,created_by                             -- 作成者
        ,creation_date                          -- 作成日
        ,last_updated_by                        -- 最終更新者
        ,last_update_date                       -- 最終更新日
        ,last_update_login                      -- 最終更新ログイン
        ,request_id                             -- 要求ID
        ,program_application_id                 -- コンカレント・プログラム・アプリケーションID
        ,program_id                             -- コンカレント・プログラムID	PROGRAM_ID
        ,program_update_date                    -- プログラム更新日
      )VALUES(
         gr_blob_data.object_code               -- 物件コード
        ,gd_process_date                        -- 履歴作成日
        ,cv_flg_no                              -- 連携済フラグ
        ,NULL                                   -- 発注番号
        ,gv_maker_name                          -- メーカー名
        ,gv_age_type                            -- 年式
        ,gr_blob_data.serial_code               -- 機種
        ,NULL                                   -- 機番
        ,cn_num1                                -- 数量
        ,gr_blob_data.base_code                 -- 拠点コード
        ,gv_owner_company                       -- 本社／工場区分
        ,gv_established_site                    -- 設置先名
        ,gv_address                             -- 設置先住所
        ,cv_flg_no                              -- 論理削除フラグ
        ,gr_blob_data.base_code                 -- 顧客コード
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 START */
        ,gr_blob_data.dclr_place                -- 申告地
        ,cv_flg_no                              -- 廃棄連携フラグ
/* 2014-05-19 K.Nakamura E_本稼動_11853対応 END */
        ,cn_created_by                          -- 作成者
        ,SYSDATE                                -- 作成日
        ,cn_last_updated_by                     -- 最終更新者
        ,SYSDATE                                -- 最終更新日
        ,cn_last_update_login                   -- 最終更新ログイン
        ,cn_request_id                          -- 要求ID
        ,cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                          -- コンカレント・プログラムID	PROGRAM_ID
        ,SYSDATE                                -- プログラム更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_xxcso_ib_info_h            -- トークン値1
                       ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                       ,iv_token_value2  => cv_insert_process             -- トークン値2
                       ,iv_token_name3   => cv_tkn_errmsg                 -- トークンコード3
                       ,iv_token_value3  => SQLERRM                       -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code   -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
  EXCEPTION
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                   'エラー：'||lv_errmsg|| CHR(10) ||
                   ''                           -- 空行の挿入
      );
--
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
  END insert_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : rock_file_interface
   * Description      : ファイルアップロードIFロック処理 (A-8)
   ***********************************************************************************/
  PROCEDURE rock_file_interface(
     in_file_id              IN  NUMBER                  -- ファイルID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rock_file_interface'; -- プログラム名
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
    cv_table_name              CONSTANT VARCHAR2(100)   := 'ファイルアップロードIF';
    cv_lock_process            CONSTANT VARCHAR2(100)   := 'ロック';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・レコード ***
    CURSOR rock_interface_cur IS
      SELECT xmfui.file_id
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
--
   rock_interface_rec rock_interface_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- ファイルアップロードIF抽出
    BEGIN
--
      OPEN rock_interface_cur;
      FETCH rock_interface_cur INTO rock_interface_rec;
      CLOSE rock_interface_cur;
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_49              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => cv_table_name                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2 => SQLERRM                       -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_table_name                 -- トークン値1
                       ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                       ,iv_token_value2  => cv_lock_process               -- トークン値2
                       ,iv_token_name3   => cv_tkn_errmsg                 -- トークンコード3
                       ,iv_token_value3  => SQLERRM                       -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code   -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END rock_file_interface;
--
   /**********************************************************************************
   * Procedure Name   : delete_in_item_data
   * Description      : 物件データワークテーブル削除処理(A-9)
   ***********************************************************************************/
  PROCEDURE delete_in_item_data(
     in_file_id              IN  NUMBER                  -- ファイルID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_in_item_data';  -- プログラム名
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
    cv_table_name            CONSTANT  VARCHAR2(100)  := 'ファイルアップロードIF';
    -- *** ローカル変数 ***
    -- *** ローカル・例外 ***
    delete_error_expt        EXCEPTION;
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
      -- ==========================================
      -- 物件ワークテーブル削除処理 
      -- ==========================================
      DELETE  
      FROM xxccp_mrp_file_ul_interface                  -- 物件ワークテーブル
      WHERE file_id = in_file_id;
--
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_48             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1 => cv_table_name                -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id               -- トークンコード2
                       ,iv_token_value2 => in_file_id                   -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード2
                       ,iv_token_value3 => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_error_expt;
    END;
--
  EXCEPTION
--
    -- *** データ更新例外ハンドラ ***
    WHEN delete_error_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理例外ハンドラ ***
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
--#####################################  固定部 END   ##########################################
--
  END delete_in_item_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2,     --   ユーザー・エラー・メッセージ --# 固定 #
    in_file_id    IN  NUMBER,       --   ファイルID
    iv_format     IN  VARCHAR2)     --   フォーマットパターン
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
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    skip_process_expt       EXCEPTION;
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
    -- ================================
    -- A-1.初期処理 
    -- ================================
--
    init(
       in_file_id            => in_file_id          -- ファイルID
      ,iv_format             => iv_format           -- フォーマットパターン
      ,ov_errbuf             => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode            => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg             => lv_errmsg           -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.物件マスタ情報抽出処理
    -- ========================================
    get_item_instances(
       in_file_id       => in_file_id     -- ファイルID
      ,ov_errbuf        => lv_errbuf      -- エラー・メッセージ            --# 固定 #
      ,ov_retcode       => lv_retcode     -- リターン・コード              --# 固定 #
      ,ov_errmsg        => lv_errmsg      -- ユーザー・エラー・メッセージ    --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 処理対象件数格納
    gn_target_cnt := gr_file_data_tbl.COUNT;
--
    FOR i IN gr_file_data_tbl.FIRST..gr_file_data_tbl.LAST LOOP
      -- ===========================
      -- A-3データ妥当性チェック処理
      -- ===========================
      chk_data_validate(
        it_blob_data => gr_file_data_tbl
       ,in_data_num  => i
       ,ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ    --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===========================
      -- A-4データマスタチェック処理
      -- ===========================
      chk_data_master(
        ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ    --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===========================
      -- A-5顧客情報取得処理
      -- ===========================
      get_custmer_data(
        ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ    --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-7.物件データ登録処理
      -- ========================================
      insert_item_instances(
        ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ    --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- 正常件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP;
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_32             --メッセージコード
                   );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- エラーメッセージ
      );
--     
    ELSE 
      -- ========================================
      -- A-8.ファイルアップロードIFロック処理
      -- ========================================
      rock_file_interface(
        in_file_id   => in_file_id     -- ファイルID
       ,ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ    --# 固定 #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
  --
      -- ========================================
      -- A-9.物件データワークテーブル削除処理
      -- ========================================
      delete_in_item_data(
        in_file_id   => in_file_id     -- ファイルID
       ,ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ    --# 固定 #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT  NOCOPY  VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id    IN   NUMBER,                --   ファイルID
    iv_format     IN   VARCHAR2               --   フォーマットパターン
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
      ov_errbuf   => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode  => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg   => lv_errmsg,           -- ユーザー・エラー・メッセージ  --# 固定 #
      in_file_id  => in_file_id,          -- ファイルID
      iv_format   => iv_format            -- ファイルフォーマット
    );
--
 --
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-13.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO012A02C;
/
