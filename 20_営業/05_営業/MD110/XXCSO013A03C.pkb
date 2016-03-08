CREATE OR REPLACE PACKAGE BODY APPS.XXCSO013A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO013A03C(body)
 * Description      : 固定資産の物件をリース・FA領域に連携するOIFデータを作成します。
 * MD.050           : CSI→FAインタフェース：（OUT）固定資産資産情報 <MD050_CSO_013_A03>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  ins_xxcff_if           自販機物件管理インタフェース登録処理(A-8)
 *  upd_xxcso_ib_info_h    物件関連変更履歴テーブル更新処理(A-7)
 *  lock_xxcso_ib_info_h   物件関連変更履歴テーブルロック処理(A-6)
 *  chk_xxcff_if_exists    自販機物件管理インタフェース存在チェック(A-5)
 *  chk_xxcso_ib_info_h    物件関連情報変更チェック処理(A-4)
 *  get_relation_data      物件関連情報取得(A-3)
 *  get_target_data        対象物件抽出(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2014/06/10    1.0   Kazuyuki Kiriu   新規作成
 * 2016/02/09    1.1   H.Okada          E_本稼動_13456対応
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
  -- ユーザー定義例外
  -- ===============================
  global_lock_expt          EXCEPTION;       -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO013A03C';   -- パッケージ名
--
  cv_app_name               CONSTANT VARCHAR2(5)   := 'XXCSO';          -- アプリケーション短縮名
--
  --メッセージ
  cv_msg_param_date         CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00147';  -- パラメータ処理実行日
  cv_msg_proc_date_err      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- 業務処理日取得エラーメッセージ
  cv_msg_prof_err           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- プロファイル取得エラーメッセージ
  cv_msg_status_id_err      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00164';  -- ステータスID抽出エラーメッセージ
  cv_msg_lookup_err         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00253';  -- 参照タイプ抽出エラーメッセージ
  cv_tkn_lookup_no_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173';  -- 参照タイプなしエラーメッセージ
  cv_msg_no_data1_wrn       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00242';  -- データなし警告メッセージ
  cv_msg_no_data2_wrn       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00708';  -- データなしメッセージ(キー付き)
  cv_msg_get_data1_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- 抽出エラーメッセージ
  cv_msg_get_data2_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00709';  -- 抽出エラーメッセージ(キー付き)
  cv_msg_if_exists_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00701';  -- 自販機物件管理IF存在エラー
  cv_msg_data_dml_err       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00158';  -- DMLエラーメッセージ
  cv_msg_status_id          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00687';  -- インスタンスステータスマスタ(固定)
  cv_msg_status_nm          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00688';  -- 物件削除(固定)
  cv_msg_lookup_type        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00689';  -- 参照タイプ(固定)
  cv_msg_lookup_code1       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00690';  -- INV 工場返品倉替先コード(固定)
  cv_msg_inst_relat_data    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00691';  -- 物件関連情報(固定)
  cv_msg_instance_id        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00692';  -- 物件ID(固定)
  cv_msg_model              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00693';  -- 機種(固定値)
  cv_msg_model_code         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00694';  -- 機種コード(固定)
  cv_msg_instance_code      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00696';  -- 物件コード(固定)
  cv_msg_sale_base          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00697';  -- 売上拠点(固定)
  cv_msg_owner_comp_type    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00698';  -- 本社/工場区分(固定)
  cv_msg_mng_place          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00699';  -- 事業所(固定)
  cv_msg_if_name            CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00700';  -- 自販機物件管理インタフェース(固定)
  cv_msg_create             CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00702';  -- 登録(固定)
  cv_msg_update             CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00703';  -- 更新(固定)
  cv_msg_lock               CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00704';  -- ロック(固定)
  cv_msg_ib_info            CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00705';  -- 物件関連変更履歴テーブル(固定)
  cv_msg_dclr_place         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- 申告地(固定)
  cv_msg_cust_shift_err     CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00706';  -- 顧客移行情報テーブル(固定)
  cv_msg_cust_code          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00707';  -- 顧客コード(固定)
  -- トークンコード
  cv_tkn_value              CONSTANT VARCHAR2(20)  := 'VALUE';
  cv_tkn_prof_name          CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_task_name          CONSTANT VARCHAR2(20)  := 'TASK_NAME';
  cv_tkn_status_name        CONSTANT VARCHAR2(20)  := 'STATUS_NAME';
  cv_tkn_err_msg            CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_lookup_type_name   CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE_NAME';
  cv_tkn_item               CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_base_value         CONSTANT VARCHAR2(20)  := 'BASE_VALUE';
  cv_tkn_bukken             CONSTANT VARCHAR2(20)  := 'BUKKEN';
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_process            CONSTANT VARCHAR2(20)  := 'PROCESS';
  cv_tkn_key                CONSTANT VARCHAR2(20)  := 'KEY';
  cv_tkn_key_value          CONSTANT VARCHAR2(20)  := 'KEY_VALUE';
  -- プロファイル
  cv_prf_cust_cd_dammy      CONSTANT VARCHAR2(30)  := 'XXCSO1_AFF_CUST_CODE';       -- XXCSO:AFF顧客コード（定義なし）
  cv_prof_org_id            CONSTANT VARCHAR2(30)  := 'ORG_ID';                     -- MO:営業単位
  cv_attribute_level        CONSTANT VARCHAR2(30)  := 'XXCSO1_IB_ATTRIBUTE_LEVEL';  -- XXCSO:IB拡張属性テンプレートアクセスレベル
  cv_withdraw_base_code     CONSTANT VARCHAR2(30)  := 'XXCSO1_WITHDRAW_BASE_CODE';  -- XXCSO:引揚拠点コード
  -- 参照タイプ
  cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
  cv_csi_inst_type_code     CONSTANT VARCHAR2(30)  := 'CSI_INST_TYPE_CODE';
  cv_xxcoi_mfg_fctory_cd    CONSTANT VARCHAR2(30)  := 'XXCOI_MFG_FCTORY_CD';
  cv_xxcso_csi_maker_code   CONSTANT VARCHAR2(30)  := 'XXCSO_CSI_MAKER_CODE';
  cv_xxcso1_owner_company   CONSTANT VARCHAR2(30)  := 'XXCSO1_OWNER_COMPANY';
  --値セット
  cv_xxcff_owner_company    CONSTANT VARCHAR2(30)  := 'XXCFF_OWNER_COMPANY';       --本社/工場区分
  cv_xxcff_mng_place        CONSTANT VARCHAR2(30)  := 'XXCFF_MNG_PLACE';           --事業所
  cv_xxcff_dclr_place       CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';          --申告地
  -- インスタンスマスタ：ステータス
  cv_delete_code            CONSTANT VARCHAR2(1)   := '6';              -- 物件削除済コード
  -- 属性コード
  cv_lease_kbn              CONSTANT VARCHAR2(9)   := 'LEASE_KBN';      -- リース区分
  cv_disposed_flag          CONSTANT VARCHAR2(13)  := 'VEN_HAIKI_FLG';  -- 廃棄決裁フラグ
  cv_dclr_place             CONSTANT VARCHAR2(10)  := 'DCLR_PLACE';     -- 申告地
  cv_assets_cost            CONSTANT VARCHAR2(13)  := 'VD_SHUTOKU_KG';  -- 取得価格
  cv_disposed_date          CONSTANT VARCHAR2(14)  := 'HAIKIKESSAI_DT'; -- 廃棄決済日
/* 2016.02.09 H.Okada E_本稼働_13456 ADD START */
  cv_fa_move_date           CONSTANT VARCHAR2(12)  := 'FA_MOVE_DATE';   -- 固定資産移動日
/* 2016.02.09 H.Okada E_本稼働_13456 ADD END */
  -- 属性値
  cv_lease_type_assets      CONSTANT VARCHAR2(1)   := '4';              -- リース区分(固定資産税)
  cv_disposed_approve       CONSTANT VARCHAR2(1)   := '9';              -- 廃棄決裁フラグ(廃棄決裁済)
  -- 顧客関連
  cv_cust_class_10          CONSTANT VARCHAR2(2)   := '10';             -- 顧客区分(顧客)
  -- 作業関連
  cv_job_kbn_set            CONSTANT VARCHAR2(1)   := '1';              -- 作業区分(新台設置)
  cv_job_kbn_change         CONSTANT VARCHAR2(1)   := '3';              -- 作業区分(新台代替)
  cv_comp_kbn_complete      CONSTANT VARCHAR2(1)   := '1';              -- 完了区分(完了)
  -- 本社/工場区分
  cv_owner_company_h_office CONSTANT VARCHAR2(1)   := '1';              -- 本社
  cv_owner_company_fact     CONSTANT VARCHAR2(1)   := '2';              -- 工場
  -- 対象物件データタイプ
  cv_create                 CONSTANT VARCHAR2(1)   := '1';              -- 新規
  cv_update                 CONSTANT VARCHAR2(1)   := '2';              -- 更新
  cv_disposed               CONSTANT VARCHAR2(1)   := '3';              -- 廃棄
  cv_any_time               CONSTANT VARCHAR2(1)   := '4';              -- 随時
  -- 日付形式
  cv_yyyymmdd               CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_yyyymmddhhmmdd_sla     CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_yyyymmdd_sla           CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_mm                     CONSTANT VARCHAR2(2)   := 'MM';
  -- その他汎用
  cv_yes                    CONSTANT VARCHAR2(1)   := 'Y';  --汎用Y
  cv_no                     CONSTANT VARCHAR2(1)   := 'N';  --汎用N
  cv_space                  CONSTANT VARCHAR2(1)   := ' ';  --汎用スペース
  cv_0                      CONSTANT VARCHAR2(1)   := '0';  --汎用0(CHAR)
  cv_1                      CONSTANT VARCHAR2(1)   := '1';  --汎用1(CHAR)
  cn_0                      CONSTANT NUMBER        := 0;    --汎用0(NUMBRE)
  cn_1                      CONSTANT NUMBER        := 1;    --汎用1(NUMBRE)
  cn_2                      CONSTANT NUMBER        := 2;    --汎用2(NUMBRE)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- INV 工場返品倉替先コード取得用配列定義
  TYPE gt_mfg_fctory_code_ttype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE INDEX BY BINARY_INTEGER;
  -- 新旧チェック用レコード型定義
  TYPE g_check_rtype IS RECORD(
     install_code            xxcso_ib_info_h.install_code%TYPE             -- 物件番号
    ,manufacturer_name       xxcso_ib_info_h.manufacturer_name%TYPE        -- メーカー名
    ,age_type                xxcso_ib_info_h.age_type%TYPE                 -- 年式
    ,un_number               xxcso_ib_info_h.un_number%TYPE                -- 機種
    ,install_number          xxcso_ib_info_h.install_number%TYPE           -- 機番
    ,quantity                xxcso_ib_info_h.quantity%TYPE                 -- 数量
    ,base_code               xxcso_ib_info_h.base_code%TYPE                -- 拠点コード
    ,owner_company_type      xxcso_ib_info_h.owner_company_type%TYPE       -- 本社／工場区分
    ,install_name            xxcso_ib_info_h.install_name%TYPE             -- 設置先名
    ,install_address         xxcso_ib_info_h.install_address%TYPE          -- 設置先住所
    ,logical_delete_flag     xxcso_ib_info_h.logical_delete_flag%TYPE      -- 論理削除フラグ
    ,account_number          xxcso_ib_info_h.account_number%TYPE           -- 顧客コード
    ,declaration_place       xxcso_ib_info_h.declaration_place%TYPE        -- 申告地
    ,disposal_intaface_flag  xxcso_ib_info_h.disposal_intaface_flag%TYPE   -- 廃棄決裁フラグ
/* 2016.02.09 H.Okada E_本稼働_13456 ADD START */
    ,fa_move_date            DATE                                          -- 固定資産移動日
/* 2016.02.09 H.Okada E_本稼働_13456 ADD END */
  );
  -- INV 工場返品倉替先コード取得用配列変数
  g_mfg_fctory_cd      gt_mfg_fctory_code_ttype;
  -- 新旧データ比較(物件履歴テーブル更新)用レコード型
  g_new_data_rec       g_check_rtype;
  -- インターフェース登録データ格納用レコード型
  g_if_rec             xxcff_vd_object_mng_if%ROWTYPE;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- パラメータ格納用
  gv_prm_process_date         VARCHAR2(8);  -- 処理実行日
  -- 処理関連データ取得用
  gd_business_date            DATE;         -- 業務処理日付
  gd_process_date             DATE;         -- 処理日
  -- プロファイル値
  gv_customer_code_dammy      hz_cust_accounts_all.account_number%TYPE;      -- XXCSO:AFF顧客コード（定義なし）
  gn_org_id                   NUMBER;                                        -- MO:営業単位
  gt_attribute_level          csi_i_extended_attribs.attribute_level%TYPE;   -- XXCSO:IB拡張属性テンプレートアクセスレベル
  gt_withdraw_base_code       csi_i_extended_attribs.attribute_level%TYPE;   -- XXCSO:引揚拠点コード
  -- その他
  gn_instance_status_id       csi_instance_statuses.instance_status_id%TYPE; --物件ステータスID
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  --対象物件取得カーソル
  CURSOR get_target_cur
  IS
    -- 新規物件(夜間処理)
    SELECT  /*+
              LEADING(xiih)
              INDEX(xiih xxcso_ib_info_h_n02)
              USE_NL(xiih cii)
            */
            cv_create        data_type
           ,cii.instance_id  instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
    WHERE   gv_prm_process_date    IS NULL  --夜間処理
    AND     xiih.interface_flag    = cv_no  --未連携
    AND     cii.external_reference = xiih.install_code
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_lease_kbn
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_lease_type_assets
              AND     ROWNUM                  = 1
            )                               --リース区分:4(固定資産)
    AND     NOT EXISTS ( 
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_disposed_flag
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_disposed_approve
              AND     ROWNUM                  = 1
          )                                 --廃棄フラグ:9(廃棄決裁済)以外
    UNION ALL
    --更新物件(夜間処理)
    SELECT  cv_update        data_type
           ,cii.instance_id  instance_id
    FROM    csi_item_instances   cii
    WHERE   gv_prm_process_date  IS NULL    --夜間処理
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_lease_kbn
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_lease_type_assets
              AND     ROWNUM                  = 1
            )                               --リース区分:4(固定資産)
    AND     NOT EXISTS ( 
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_disposed_flag
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_disposed_approve
              AND     ROWNUM                  = 1
            )                                 --廃棄フラグ:9(廃棄決裁済)以外
    AND     EXISTS (
              SELECT  /*+
                        USE_NL(xiih hca hp xca hcas hps hl)
                      */
                      1
              FROM    xxcso_ib_info_h         xiih  -- 物件関連情報変更履歴テーブル
                     ,hz_cust_accounts_all    hca   -- 顧客マスタ
                     ,hz_parties              hp    -- パーティマスタ
                     ,xxcmm_cust_accounts     xca   -- 顧客アドオンマスタ
                     ,hz_cust_acct_sites_all  hcas  -- 顧客所在地マスタビュー
                     ,hz_party_sites          hps   -- パーティサイトマスタ
                     ,hz_locations            hl    -- 顧客事業所マスタ
              WHERE   xiih.install_code                  = cii.external_reference
              AND     xiih.interface_flag                = cv_yes                    -- 連携済
              AND     hca.cust_account_id                = cii.owner_party_account_id
              AND     hp.party_id                        = hca.party_id
              AND     xca.customer_id                    = hca.cust_account_id
              AND     hcas.cust_account_id               = hca.cust_account_id
              AND     hcas.org_id                        = gn_org_id
              AND     hps.party_id                       = hp.party_id
              AND     hps.party_site_id                  = hcas.party_site_id
              AND     hl.location_id                     = hps.location_id
              AND     (
                            (
                              (
                                (hca.customer_class_code <> cv_cust_class_10)
                                AND
                                (gv_customer_code_dammy  <> NVL(xiih.account_number, cv_space))
                              )
                              OR
                              (
                                (hca.customer_class_code =  cv_cust_class_10)
                                AND
                                (hca.account_number      <> NVL(xiih.account_number, cv_space))
                              )
                            )                                                                         -- 顧客コードチェック
                        OR  NVL(xca.sale_base_code, cv_space)  <> NVL(xiih.base_code, cv_space)       -- 売上拠点チェック
                        OR  NVL(hp.party_name, cv_space)       <> NVL(xiih.install_name, cv_space)    -- 設置先名チェック
                        OR  NVL(hl.state || hl.city || hl.address1 || hl.address2, cv_space)
                                                               <> NVL(xiih.install_address, cv_space) -- 住所チェック
                        OR  NVL(cii.attribute1, cv_space)      <> NVL(xiih.un_number, cv_space)       -- 機種チェック
                        OR  NVL(cii.attribute2, cv_space)      <> NVL(xiih.install_number, cv_space)  -- 機番チェック
                        OR  NVL(xiih.quantity, cn_0)           <> NVL(cii.quantity, cn_0)             -- 数量チェック
                        OR  NVL(xiih.manufacturer_name, cv_space)   <>
                              (
                               SELECT  NVL(
                                         xxcso_util_common_pkg.get_lookup_meaning(
                                           cv_xxcso_csi_maker_code
                                          ,punv.attribute2
                                          ,gd_process_date
                                         )
                                        ,cv_space
                                       )
                               FROM    po_un_numbers_vl   punv
                               WHERE   punv.un_number  =  cii.attribute1
                              )                                                                      -- メーカ名チェック
                        OR  NVL(xiih.age_type, cv_space)            <>
                              (
                               SELECT  NVL(punv.attribute3, cv_space)
                               FROM    po_un_numbers_vl   punv
                               WHERE   punv.un_number  =  cii.attribute1
                              )                                                                      -- 年式チェック
                        OR  NVL(xiih.logical_delete_flag, cv_space) <>
                              DECODE(cii.instance_status_id
                                ,gn_instance_status_id, cv_yes
                                ,cv_no
                              )                                                                      -- 論理削除チェック
                        OR  NVL(xiih.owner_company_type, cv_space)  <>
                              (
                                SELECT  flvv.meaning
                                FROM    fnd_lookup_values_vl  flvv
                                WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                AND     flvv.enabled_flag  = cv_yes
                                AND     gd_process_date
                                          BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                          AND     TRUNC(NVL(flvv.end_date_active,   gd_process_date))
                                AND     flvv.lookup_code   =
                                          (
                                           SELECT  DECODE(COUNT('x')
                                                     ,cn_0, cv_owner_company_h_office
                                                     ,cv_owner_company_fact
                                                   )
                                           FROM    xxcmm_cust_accounts   xca
                                                  ,fnd_lookup_values_vl  flvv
                                           WHERE   xca.customer_id   = cii.owner_party_account_id
                                           AND     flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                           AND     flvv.lookup_code  = xca.sale_base_code
                                           AND     flvv.enabled_flag = cv_yes
                                           AND     gd_process_date
                                                     BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                     AND     TRUNC(NVL(flvv.end_date_active,   gd_process_date))
                                          )
                              )                                                                      -- 本社/工場区分チェック
                        OR  NVL(xiih.declaration_place, cv_space)  <> 
                              (
                                SELECT  civ.attribute_value
                                FROM    csi_i_extended_attribs  ciea
                                       ,csi_iea_values          civ
                                WHERE   ciea.attribute_level    = gt_attribute_level
                                AND     ciea.attribute_code     = cv_dclr_place
                                AND     civ.instance_id         = cii.instance_id
                                AND     ciea.attribute_id       = civ.attribute_id
                                AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                                AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
                              )                                                                      -- 申告地チェック
                      )
                AND   ROWNUM                             = 1
            )
    UNION ALL
    --廃棄物件(夜間処理)
    SELECT  /*+
              LEADING(xiih)
              INDEX(xiih xxcso_ib_info_h_n02)
              USE_NL(cii cis)
            */
            cv_disposed      data_type
           ,cii.instance_id  instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
    WHERE   gv_prm_process_date IS NULL
    AND     xiih.interface_flag         = cv_yes  --未連済
    AND     xiih.disposal_intaface_flag = cv_no   --廃棄未連携
    AND     cii.external_reference      = xiih.install_code
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_lease_kbn
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_lease_type_assets
              AND     ROWNUM                  = 1
            )                                     --リース区分:4(固定資産)
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = 'VEN_HAIKI_FLG'
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = '9'
              AND     ROWNUM                  = 1
          )                                       --廃棄フラグ:9(廃棄決裁済)
    UNION ALL
    --再連携(随時実行)
    SELECT  /*+
              LEADING(xiih)
              USE_NL(xiih cii)
            */
            cv_any_time      data_type
           ,cii.instance_id  instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
    WHERE   gv_prm_process_date               IS NOT NULL
      AND   TRUNC(xiih.history_creation_date) = TRUNC(gd_process_date)  -- 履歴作成日がパラメータ「処理実行日」
      AND   xiih.interface_flag               = cv_yes                  -- FA連携済み
      AND   cii.external_reference            = xiih.install_code
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_lease_type_assets    -- リース区分:4(固定資産)
                AND   ROWNUM                  = 1
            )
  ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_process_date   IN  VARCHAR2      -- 1.処理実行日
    ,ov_errbuf         OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode        OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_msg_tkn_1  VARCHAR2(100);  --メッセージトークン取得用1
    lv_msg_tkn_2  VARCHAR2(100);  --メッセージトークン取得用2
    lv_warn_msg   VARCHAR2(5000); --警告出力用
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
    -- ===========================
    -- パラメータ出力
    -- ===========================
    -- 処理対象日付
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_param_date
                    ,iv_token_name1  => cv_tkn_value
                    ,iv_token_value1 => iv_process_date
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空白行挿入
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===========================
    -- 業務処理日付取得
    -- ===========================
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --取得エラーチェック
    IF (gd_business_date IS NULL) THEN
      -- 業務処理日付取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_msg_proc_date_err         --メッセージコード
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ===========================
    -- 処理日特定
    -- ===========================
    gv_prm_process_date := iv_process_date;
    -- パラメータ処理実行日が入力されている場合
    IF (gv_prm_process_date IS NOT NULL) THEN
      -- 処理日＝パラメータ処理対象日
      gd_process_date := TO_DATE(gv_prm_process_date, cv_yyyymmdd);
    ELSE
      -- 処理日＝業務日付
      gd_process_date := gd_business_date;
    END IF;
--
    -- ===============================
    -- プロファイル・オプション値取得
    -- ===============================
    --XXCSO:AFF顧客コード（定義なし）
    gv_customer_code_dammy := fnd_profile.value( cv_prf_cust_cd_dammy );
    -- 取得エラーチェック
    IF ( gv_customer_code_dammy IS NULL ) THEN
      -- AFF顧客コード取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name          --アプリケーション短縮名
                    ,iv_name         => cv_msg_prof_err      --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_prf_cust_cd_dammy
                   );
      RAISE global_api_expt;
    END IF;
    --
    -- 営業単位取得
    gn_org_id := fnd_profile.value( cv_prof_org_id );
    -- 取得エラーチェック
    IF ( gn_org_id IS NULL ) THEN
      -- 営業単位取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name          --アプリケーション短縮名
                    ,iv_name         => cv_msg_prof_err      --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_prof_org_id
                   );
      RAISE global_api_expt;
    END IF;
    --
    -- IB属性レベル取得
    gt_attribute_level := fnd_profile.value( cv_attribute_level );
    -- 取得エラーチェック
    IF ( gt_attribute_level IS NULL ) THEN
      --IB属性レベル取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name          --アプリケーション短縮名
                    ,iv_name         => cv_msg_prof_err      --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_attribute_level
                   );
      RAISE global_api_expt;
    END IF;
    --
    -- 引揚拠点コード取得
    gt_withdraw_base_code := fnd_profile.value( cv_withdraw_base_code );
    -- 取得エラーチェック
    IF ( gt_withdraw_base_code IS NULL ) THEN
      --引揚拠点コード取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name          --アプリケーション短縮名
                    ,iv_name         => cv_msg_prof_err      --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_withdraw_base_code
                   );
      RAISE global_api_expt;
    END IF;
--
    -- =============================
    -- インスタンスステータスID取得
    -- =============================
    --
    BEGIN
      -- 物件削除済
      SELECT cis.instance_status_id instance_status_id
      INTO   gn_instance_status_id
      FROM   csi_instance_statuses cis
      WHERE  cis.name IN
               (
                  SELECT flvv.description description
                  FROM   fnd_lookup_values_vl flvv
                  WHERE  gd_process_date BETWEEN TRUNC( NVL(flvv.start_date_active, gd_process_date) )
                                         AND     TRUNC( NVL(flvv.end_date_active,   gd_process_date) )
                  AND    flvv.enabled_flag = cv_yes
                  AND    flvv.lookup_code  = cv_delete_code
                  AND    flvv.lookup_type  = cv_xxcso1_instance_status
               )
      AND    gd_process_date BETWEEN TRUNC( NVL(cis.start_date_active, gd_process_date) )
                             AND     TRUNC( NVL(cis.end_date_active,   gd_process_date) )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --アプリケーション短縮名
                          ,iv_name         => cv_msg_status_id   --メッセージコード
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --アプリケーション短縮名
                          ,iv_name         => cv_msg_status_nm   --メッセージコード
                         );
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            --アプリケーション短縮名
                      ,iv_name         => cv_msg_status_id_err   --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_status_name
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        RAISE global_api_expt;
    END;
--
    -- =============================
    -- INV 工場返品倉替先コード取得
    -- =============================
    BEGIN
      --全件取得
      SELECT flvv.lookup_code lookup_code
      BULK COLLECT INTO
             g_mfg_fctory_cd
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_xxcoi_mfg_fctory_cd
      AND    gd_process_date  BETWEEN TRUNC( NVL(flvv.start_date_active, gd_process_date) )
                              AND     TRUNC( NVL(flvv.end_date_active,   gd_process_date) )
      AND    flvv.enabled_flag = cv_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name         --アプリケーション短縮名
                          ,iv_name         => cv_msg_lookup_type  --メッセージコード
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name         --アプリケーション短縮名
                          ,iv_name         => cv_msg_lookup_code1 --メッセージコード
                         );
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name             --アプリケーション短縮名
                      ,iv_name         => cv_msg_lookup_err       --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_lookup_type_name
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        RAISE global_api_expt;
    END;
    --
    -- INV 工場返品倉替先コードが0件の場合
    IF ( g_mfg_fctory_cd.COUNT = 0 ) THEN
      lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name         --アプリケーション短縮名
                        ,iv_name         => cv_msg_lookup_type  --メッセージコード
                       );
      lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name         --アプリケーション短縮名
                        ,iv_name         => cv_msg_lookup_code1 --メッセージコード
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name               --アプリケーション短縮名
                    ,iv_name         => cv_tkn_lookup_no_err      --メッセージコード
                    ,iv_token_name1  => cv_tkn_task_name
                    ,iv_token_value1 => lv_msg_tkn_1
                    ,iv_token_name2  => cv_tkn_lookup_type_name
                    ,iv_token_value2 => lv_msg_tkn_2
                   );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理エラー例外 ***
    WHEN global_api_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
   * Procedure Name   : ins_xxcff_if
   * Description      : 自販機物件管理インタフェース登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_xxcff_if(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxcff_if'; -- プログラム名
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
    lv_msg_tkn_1  VARCHAR2(100);   -- メッセージトークン取得用1
    lv_msg_tkn_2  VARCHAR2(100);   -- メッセージトークン取得用2
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
    BEGIN
      -- 自販機物件管理インタフェースデータ挿入処理
      INSERT INTO xxcff_vd_object_mng_if(
         object_code                  -- 物件コード
        ,generation_date              -- 発生日
        ,manufacturer_name            -- メーカ名
        ,age_type                     -- 年式
        ,model                        -- 機種
        ,quantity                     -- 数量
        ,department_code              -- 管理部門
        ,owner_company_type           -- 本社／工場区分
        ,installation_place           -- 現設置先
        ,installation_address         -- 現設置場所
        ,active_flag                  -- 物件有効フラグ
        ,import_status                -- 取込ステータス
        ,group_id                     -- グループID
        ,customer_code                -- 顧客コード
        ,machine_type                 -- 機器区分
        ,lease_class                  -- リース種別
        ,date_placed_in_service       -- 事業供用日
        ,assets_cost                  -- 取得価格
        ,moved_date                   -- 移動日
        ,dclr_place                   -- 申告地
        ,location                     -- 事業所
        ,date_retired                 -- 除・売却日
        ,created_by                   -- 作成者
        ,creation_date                -- 作成日
        ,last_updated_by              -- 最終更新者
        ,last_update_date             -- 最終更新日
        ,last_update_login            -- 最終更新ログイン
        ,request_id                   -- 要求ID
        ,program_application_id       -- コンカレント・プログラム・アプリケーションID
        ,program_id                   -- コンカレント・プログラムID
        ,program_update_date          -- プログラム更新日
      )VALUES(
         g_if_rec.object_code               -- 物件コード
        ,g_if_rec.generation_date           -- 発生日
        ,g_if_rec.manufacturer_name         -- メーカ名
        ,g_if_rec.age_type                  -- 年式
        ,g_if_rec.model                     -- 機種
        ,g_if_rec.quantity                  -- 数量
        ,g_if_rec.department_code           -- 管理部門
        ,g_if_rec.owner_company_type        -- 本社／工場区分
        ,g_if_rec.installation_place        -- 現設置先
        ,g_if_rec.installation_address      -- 現設置場所
        ,g_if_rec.active_flag               -- 物件有効フラグ
        ,g_if_rec.import_status             -- 取込ステータス
        ,g_if_rec.group_id                  -- グループID
        ,g_if_rec.customer_code             -- 顧客コード
        ,g_if_rec.machine_type              -- 機器区分
        ,g_if_rec.lease_class               -- リース種別
        ,g_if_rec.date_placed_in_service    -- 事業供用日
        ,g_if_rec.assets_cost               -- 取得価格
        ,g_if_rec.moved_date                -- 移動日
        ,g_if_rec.dclr_place                -- 申告地
        ,g_if_rec.location                  -- 事業所
        ,g_if_rec.date_retired              -- 除・売却日
        ,cn_created_by                      -- 作成者
        ,cd_creation_date                   -- 作成日
        ,cn_last_updated_by                 -- 最終更新者
        ,cd_last_update_date                -- 最終更新日
        ,cn_last_update_login               -- 最終更新ログイン
        ,cn_request_id                      -- 要求ID
        ,cn_program_application_id          -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                      -- コンカレント・プログラムID
        ,cd_program_update_date             -- プログラム更新日
       );
    EXCEPTION
      WHEN OTHERS THEN
        --トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --アプリケーション短縮名
                          ,iv_name         => cv_msg_if_name     --メッセージコード
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --アプリケーション短縮名
                          ,iv_name         => cv_msg_create      --メッセージコード
                         );
        --メッセージ設定
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            --アプリケーション短縮名
                      ,iv_name         => cv_msg_data_dml_err    --メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_xxcff_if;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcso_ib_info_h
   * Description      : 物件関連情報変更履歴テーブル更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE upd_xxcso_ib_info_h(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_xxcso_ib_info_h';     -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_msg_tkn_1  VARCHAR2(100);   -- メッセージトークン取得用1
    lv_msg_tkn_2  VARCHAR2(100);   -- メッセージトークン取得用2
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・カーソル ***
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
--
    -- ========================================
    -- 物件関連情報変更履歴テーブル更新処理
    -- ========================================
    BEGIN
      --
      UPDATE xxcso_ib_info_h xiih
      SET    xiih.history_creation_date   = gd_process_date                        -- 履歴作成日
            ,xiih.interface_flag          = cv_yes                                 -- 連携済フラグ
            ,xiih.manufacturer_name       = g_new_data_rec.manufacturer_name       -- メーカー名
            ,xiih.age_type                = g_new_data_rec.age_type                -- 年式
            ,xiih.un_number               = g_new_data_rec.un_number               -- 機種
            ,xiih.install_number          = g_new_data_rec.install_number          -- 機番
            ,xiih.quantity                = g_new_data_rec.quantity                -- 数量
            ,xiih.base_code               = g_new_data_rec.base_code               -- 拠点コード
            ,xiih.owner_company_type      = g_new_data_rec.owner_company_type      -- 本社／工場区分
            ,xiih.install_name            = g_new_data_rec.install_name            -- 設置先名
            ,xiih.install_address         = g_new_data_rec.install_address         -- 設置先住所
            ,xiih.logical_delete_flag     = g_new_data_rec.logical_delete_flag     -- 論理削除フラグ
            ,xiih.account_number          = g_new_data_rec.account_number          -- 顧客コード
            ,xiih.declaration_place       = g_new_data_rec.declaration_place       -- 申告地
            ,xiih.disposal_intaface_flag  = g_new_data_rec.disposal_intaface_flag  -- 廃棄決裁フラグ
            ,xiih.last_updated_by         = cn_last_updated_by                     -- 最終更新者
            ,xiih.last_update_date        = cd_last_update_date                    -- 最終更新日
            ,xiih.last_update_login       = cn_last_update_login                   -- 最終更新ログイン
            ,xiih.request_id              = cn_request_id                          -- 要求ID
            ,xiih.program_application_id  = cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
            ,xiih.program_id              = cn_program_id                          -- コンカレント・プログラムID
            ,xiih.program_update_date     = cd_program_update_date                 -- プログラム更新日
      WHERE  xiih.install_code   = g_new_data_rec.install_code
      ;
    EXCEPTION
      --その他例外
      WHEN OTHERS THEN
        --トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          --アプリケーション短縮名
                          ,iv_name         => cv_msg_ib_info       --メッセージコード
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          --アプリケーション短縮名
                          ,iv_name         => cv_msg_update        --メッセージコード
                         );
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --アプリケーション短縮名
                      ,iv_name         => cv_msg_data_dml_err      --メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END upd_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : lock_xxcso_ib_info_h
   * Description      : 物件関連変更履歴テーブルロック(A-6)
   ***********************************************************************************/
  PROCEDURE lock_xxcso_ib_info_h(
     ov_errbuf           OUT VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'lock_xxcso_ib_info_h';     -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    cv_dummy      VARCHAR2(1);     -- ロックダミー用
    lv_put_msg    VARCHAR2(5000);  -- 出力メッセージ用
    lv_msg_tkn_1  VARCHAR2(100);   -- メッセージトークン取得用1
    lv_msg_tkn_2  VARCHAR2(100);   -- メッセージトークン取得用2
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・カーソル ***
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
--
    -- ========================================
    -- 物件関連変更履歴テーブルロック処理
    -- ========================================
    BEGIN
      --
      SELECT cv_1 lock_dummy
      INTO   cv_dummy
      FROM   xxcso_ib_info_h xiih -- 物件関連情報変更履歴テーブル
      WHERE  xiih.install_code = g_if_rec.object_code -- 物件コード
      FOR UPDATE OF
             xiih.install_code
      NOWAIT
      ;
    EXCEPTION
      -- ロック例外
      WHEN global_lock_expt THEN
        -- トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --アプリケーション短縮名
                          ,iv_name         => cv_msg_ib_info        --メッセージコード
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --アプリケーション短縮名
                          ,iv_name         => cv_msg_lock           --メッセージコード
                         );
        -- メッセージ編集
        lv_put_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --アプリケーション短縮名
                       ,iv_name         => cv_msg_data_dml_err             --メッセージコード
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tkn_1
                       ,iv_token_name2  => cv_tkn_process
                       ,iv_token_value2 => lv_msg_tkn_2
                       ,iv_token_name3  => cv_tkn_bukken
                       ,iv_token_value3 => g_if_rec.object_code
                       ,iv_token_name4  => cv_tkn_err_msg
                       ,iv_token_value4 => SQLERRM
                      );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_put_msg       -- 出力メッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_put_msg       -- ログメッセージ
          );
        ov_retcode := cv_status_warn;
      -- その他の例外
      WHEN OTHERS THEN
        -- トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --アプリケーション短縮名
                          ,iv_name         => cv_msg_ib_info        --メッセージコード
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --アプリケーション短縮名
                          ,iv_name         => cv_msg_instance_code  --メッセージコード
                         );
        -- メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_msg_get_data1_err             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END lock_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : chk_xxcff_if_exists
   * Description      : 自販機物件管理インタフェース存在チェック(A-5)
   ***********************************************************************************/
  PROCEDURE chk_xxcff_if_exists(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_xxcff_if_exists'; -- プログラム名
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
    ln_data_cnt   NUMBER;          -- 存在チェック用
    lv_msg_tkn_1  VARCHAR2(100);   -- メッセージトークン取得用1
    lv_msg_tkn_2  VARCHAR2(100);   -- メッセージトークン取得用2
    lv_put_msg    VARCHAR2(5000);  -- 出力メッセージ用
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・カーソル ***
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
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- ========================================
    -- 自販機物件管理インタフェース存在判定
    -- ========================================
    BEGIN
      --
      SELECT COUNT(xvomi.object_code)
      INTO   ln_data_cnt
      FROM   xxcff_vd_object_mng_if xvomi -- 自販機物件管理インタフェース
      WHERE  xvomi.object_code = g_if_rec.object_code -- 物件コード
      ;
    EXCEPTION
      -- その他例外
      WHEN OTHERS THEN
        --トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --アプリケーション短縮名
                          ,iv_name         => cv_msg_if_name        --メッセージコード
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --アプリケーション短縮名
                          ,iv_name         => cv_msg_instance_code  --メッセージコード
                         );
        -- メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_msg_get_data1_err         --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- IFにデータが残っている場合
    IF ( ln_data_cnt > 0 ) THEN
      --メッセージ編集
      lv_put_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name             --アプリケーション短縮名
                     ,iv_name         => cv_msg_if_exists_err    --メッセージコード
                     ,iv_token_name1  => cv_tkn_bukken
                     ,iv_token_value1 => g_if_rec.object_code
                    );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_put_msg       -- 出力メッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_put_msg       -- ログメッセージ
        );
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
  END chk_xxcff_if_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_xxcso_ib_info_h
   * Description      : 物件関連情報変更チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE chk_xxcso_ib_info_h(
     iv_new_data   IN  g_check_rtype  -- 1.新データ
    ,iv_old_data   IN  g_check_rtype  -- 2.旧データ
    ,on_change_ptn OUT NUMBER         -- 3.変更パターン(1:修正 2:移動)
    ,od_move_date  OUT DATE           -- 4.移動日
    ,ov_errbuf     OUT VARCHAR2       --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2       --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)      --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_xxcso_ib_info_h'; -- プログラム名
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
    ld_move_date   DATE;           -- 実作業日取得用
    lv_msg_tkn_1   VARCHAR2(100);  -- メッセージトークン取得用1
    lv_msg_tkn_2   VARCHAR2(100);  -- メッセージトークン取得用2
    lv_msg_tkn_4   VARCHAR2(100);  -- メッセージトークン取得用4
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
/* 2016.02.09 H.Okada E_本稼働_13456 DEL START */
--    -- 実作業日取得カーソル
--    CURSOR get_act_date
--    IS
--      SELECT TO_DATE( MAX( xiwd.actual_work_date ), cv_yyyymmdd )  actual_work_date
--      FROM   xxcso_in_work_data xiwd
--      WHERE  xiwd.completion_kbn   =  cn_1       -- 完了
--      AND    (
--               ( xiwd.po_req_number    IS NOT NULL )
--               AND
--               ( xiwd.po_req_number <> cv_0 )
--             )                                   -- EBSより発生した作業(店内移動以外)
--      AND    (
--                (
--                  ( xiwd.install_code1           = iv_new_data.install_code )  -- 設置用物件
--                  AND
--                  ( xiwd.install1_processed_flag = cv_yes )  -- 物件反映済
--                )
--                OR
--                (
--                  ( xiwd.install_code2           = iv_new_data.install_code )  -- 引揚用物件
--                  AND
--                  ( xiwd.install2_processed_flag = cv_yes )  -- 物件反映済
--                )
--             )
--      ;
/* 2016.02.09 H.Okada E_本稼働_13456 DEL END */
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
--
    -- 初期化
    on_change_ptn := cn_1;  -- 変更チェックフラグにデフォルト値1(修正)を設定
    ld_move_date  := NULL;  -- 移動日
    --
    --------------------------
    -- 移動となる変更チェック
    --------------------------
    -- 拠点コード(事業所・本社/工場区分)の変更
    IF NVL( iv_old_data.base_code, cv_space ) <> NVL( iv_new_data.base_code, cv_space ) THEN
      --
      on_change_ptn := cn_2; -- 2(移動)とする
      --
      -------------------------------------
      -- 作業による判定
      -------------------------------------
      -- 旧台設置か引揚の場合
      IF ( iv_new_data.base_code = gt_withdraw_base_code )  -- 新拠点が引揚拠点=引揚
         OR
         ( iv_old_data.base_code = gt_withdraw_base_code )  -- 旧拠点が引揚拠点=旧台設置
      THEN
/* 2016.02.09 H.Okada E_本稼働_13456 MOD START */
--        -- EBSより連携された作業の最新より実作業日を取得
--        OPEN  get_act_date;
--        FETCH get_act_date INTO ld_move_date;
--        CLOSE get_act_date;
        -- 物件マスタの固定資産移動日を設定（作業による移動）
        ld_move_date := iv_new_data.fa_move_date;
/* 2016.02.09 H.Okada E_本稼働_13456 MOD END */
      -- それ以外（一般拠点から一般拠点への変更）
      ELSE
        -------------------------------------
        -- 顧客移行・拠点分割による判定
        -------------------------------------
        BEGIN
          --
          SELECT xcsi.cust_shift_date cust_shift_date  --顧客移行日
          INTO   ld_move_date
          FROM   xxcok_cust_shift_info xcsi  -- 顧客移行情報テーブル
          WHERE  xcsi.cust_code        = iv_new_data.account_number     -- 対象顧客
          AND    xcsi.cust_shift_date  = gd_process_date + 1            -- 業務日付の翌日が移行日となっている
          AND    xcsi.base_split_flag  = cv_1                           -- 予約売上拠点コード反映済
          AND    xcsi.new_base_code    = iv_new_data.base_code          -- 売上拠点が物件に紐付く顧客の売上拠点と同一
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          WHEN OTHERS THEN
            -- トークン取得
            lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- アプリケーション短縮名
                              ,iv_name         => cv_msg_cust_shift_err   -- 顧客移行情報テーブル(固定)
                             );
            lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- アプリケーション短縮名
                              ,iv_name         => cv_msg_instance_code    -- 物件コード(固定)
                             );
            lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- アプリケーション短縮名
                              ,iv_name         => cv_msg_cust_code        -- 顧客コード(固定)
                             );
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                 -- アプリケーション短縮名
                          ,iv_name         => cv_msg_get_data1_err        -- 抽出エラーメッセージ(キー付き)
                          ,iv_token_name1  => cv_tkn_task_name
                          ,iv_token_value1 => lv_msg_tkn_1
                          ,iv_token_name2  => cv_tkn_key
                          ,iv_token_value2 => lv_msg_tkn_2
                          ,iv_token_name3  => cv_tkn_key_value
                          ,iv_token_value3 => iv_new_data.install_code
                          ,iv_token_name4  => cv_tkn_item
                          ,iv_token_value4 => lv_msg_tkn_4
                          ,iv_token_name5  => cv_tkn_base_value
                          ,iv_token_value5 => iv_new_data.account_number
                          ,iv_token_name6  => cv_tkn_err_msg
                          ,iv_token_value6 => SQLERRM
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
        --
      END IF;
      --
      -- 拠点が変更されていて、上記までで取得できない場合
      IF ( ld_move_date IS NULL ) THEN
        -- 顧客も変更されている場合、オーナ変更
        IF NVL( iv_old_data.account_number, cv_space ) <> NVL( iv_new_data.account_number, cv_space ) THEN
          ld_move_date  := NULL;             -- 移動日はNULL
          on_change_ptn := cn_1;             -- 1(修正)とする
        --それ以外の場合は、業務日付とする。
        ELSE
          ld_move_date  := gd_process_date;  -- 移動日(業務日付)
          on_change_ptn := cn_2;             -- 2(移動)とする
        END IF;
        --
      END IF;
      --
    END IF;
--
    od_move_date := ld_move_date;
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
  END chk_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : get_relation_data
   * Description      : 物件関連情報取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_relation_data(
     iv_data_type    IN  VARCHAR2                              -- 1.データタイプ(1:新規 2:更新 3:廃棄 4:随時)
    ,it_instance_id  IN  csi_item_instances.instance_id%TYPE   -- 2.物件ID
    ,ov_errbuf       OUT VARCHAR2                              --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode      OUT VARCHAR2                              --   リターン・コード                    --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)                             --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relation_data'; -- プログラム名
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
    cv_dummy                  VARCHAR2(1);                            -- マスタ存在チェック用
    lv_put_msg                VARCHAR2(5000);                         -- 出力メッセージ用
    ln_data_cnt               NUMBER;                                 -- 存在チェック用
    lv_msg_tkn_1              VARCHAR2(100);                          -- メッセージトークン取得用1
    lv_msg_tkn_2              VARCHAR2(100);                          -- メッセージトークン取得用2
    lv_msg_tkn_3              VARCHAR2(100);                          -- メッセージトークン取得用3
    lv_msg_tkn_4              VARCHAR2(100);                          -- メッセージトークン取得用4
    lv_msg_tkn_5              VARCHAR2(100);                          -- メッセージトークン取得用5
    lv_msg_tkn_6              VARCHAR2(5000);                         -- メッセージトークン取得用5
    lt_new_manufacturer_name  fnd_lookup_values_vl.meaning%TYPE;      -- 新_メーカ名
    lt_new_age_type           po_un_numbers_vl.attribute3%TYPE;       -- 新_年式
    lv_owner_company_code     VARCHAR2(1);                            -- 新_本社/工場コード
    lt_new_owner_company      fnd_flex_values_vl.flex_value%TYPE;     -- 新_本社/工場区分
    ln_change_ptn             NUMBER(1);                              -- 変更パターン
    lt_new_location           fnd_flex_values_vl.flex_value%TYPE;     -- 事業所
    ld_move_date              DATE;                                   -- 移動日
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 物件関連情報取得用カーソル
    CURSOR get_new_old_data_cur
    IS
      SELECT /*+
               USE_NL(cii xiih hca hp xca hcas hps hl)
             */
             cii.external_reference        install_code                -- 物件コード
            ,cii.attribute1                new_model                  -- 新_機種(DFF1)
            ,cii.attribute2                new_serial_number          -- 新_機番(DFF2)
            ,cii.quantity                  new_quantity               -- 新_数量
            ,xca.sale_base_code            new_department_code        -- 新_拠点コード
            ,hp.party_name                 new_installation_place     -- 新_設置先名
            ,hl.state    ||
             hl.city     ||
             hl.address1 ||
             hl.address2                   new_installation_address   -- 新_設置先住所
            ,DECODE(cii.instance_status_id
                   ,gn_instance_status_id, cv_yes
                   ,cv_no
             )                             new_active_flag            -- 新_論理削除フラグ
            ,hca.account_number            new_customer_code          -- 新_顧客コード
            ,DECODE(cii.instance_status_id
                   ,gn_instance_status_id, cv_no
                   ,cv_yes
             )                             effective_flag             -- 新_物件有効フラグ
            ,xxcso_util_common_pkg.get_lookup_attribute(
               cv_csi_inst_type_code
              ,cii.instance_type_code
              ,1
              ,gd_process_date
             )                             lease_class                -- 新_リース種別
            ,cii.attribute5                newold_flag                -- 新_新古台フラグ
            ,cii.instance_type_code        new_instance_type_code     -- 新_機器区分
            ,hca.customer_class_code       new_customer_class_code    -- 新_顧客区分
            ,( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
                     ,csi_iea_values          civ   -- 設置機器拡張属性値情報テーブル
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_dclr_place
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             )                            new_declaration_place       -- 新_申告地
            ,( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
                     ,csi_iea_values          civ   -- 設置機器拡張属性値情報テーブル
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_assets_cost
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             )                             new_assets_cost            -- 新_取得価格
            ,TO_DATE( ( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
                     ,csi_iea_values          civ   -- 設置機器拡張属性値情報テーブル
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_disposed_date
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             ), cv_yyyymmdd_sla )          new_disposed_date          -- 新_廃棄決済日
            ,TO_DATE( cii.attribute3, cv_yyyymmddhhmmdd_sla )
                                           new_first_install_date     -- 新_初回設置日
            ,TRUNC(cii.creation_date)      new_creation_date          -- 新_作成日(新古台用)
/* 2016.02.09 H.Okada E_本稼働_13456 ADD START */
            ,TO_DATE( ( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
                     ,csi_iea_values          civ   -- 設置機器拡張属性値情報テーブル
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_fa_move_date
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             ), cv_yyyymmdd_sla )          new_fa_move_date           -- 新_固定資産移動日
/* 2016.02.09 H.Okada E_本稼働_13456 ADD END */
            ,xiih.manufacturer_name        old_manufacturer_name      -- 旧_メーカー名
            ,xiih.age_type                 old_age_type               -- 旧_年式
            ,xiih.un_number                old_model                  -- 旧_機種
            ,xiih.install_number           old_serial_number          -- 旧_機番
            ,xiih.quantity                 old_quantity               -- 旧_数量
            ,xiih.base_code                old_department_code        -- 旧_拠点コード
            ,xiih.owner_company_type       old_owner_company          -- 旧_本社／工場区分
            ,xiih.install_name             old_installation_place     -- 旧_設置先名
            ,xiih.install_address          old_installation_address   -- 旧_設置先住所
            ,xiih.logical_delete_flag      old_active_flag            -- 旧_論理削除フラグ
            ,xiih.account_number           old_customer_code          -- 旧_顧客コード
            ,xiih.declaration_place        old_declaration_place      -- 旧_申告地
      FROM   csi_item_instances       cii    -- 物件マスタ
            ,xxcso_ib_info_h          xiih   -- 物件関連情報変更履歴テーブル
            ,hz_cust_accounts_all     hca    -- 顧客マスタ
            ,hz_parties               hp     -- パーティマスタ
            ,xxcmm_cust_accounts      xca    -- 顧客アドオンマスタ
            ,hz_cust_acct_sites_all   hcas   -- 顧客所在地マスタ
            ,hz_party_sites           hps    -- パーティサイトマスタ
            ,hz_locations             hl     -- 顧客事業所マスタ
      WHERE  cii.instance_id            = it_instance_id       -- A-2で取得した物件ID
      AND    cii.external_reference     = xiih.install_code 
      AND    cii.owner_party_account_id = hca.cust_account_id
      AND    hca.party_id               = hp.party_id
      AND    hca.cust_account_id        = xca.customer_id
      AND    hca.cust_account_id        = hcas.cust_account_id
      AND    hcas.org_id                = gn_org_id
      AND    hcas.party_site_id         = hps.party_site_id
      AND    hp.party_id                = hps.party_id
      AND    hps.location_id            = hl.location_id
      ;
    -- 物件関連情報取得用カーソルレコード型
    l_get_new_old_data_rec  get_new_old_data_cur%ROWTYPE;
    -- 新旧チェック用レコード型(旧データ用)
    l_old_data_rec          g_check_rtype;
    -- *** ローカル例外 ***
    skip_data1_expt   EXCEPTION;      -- データ取得スキップ1(物件マスタ)例外
    skip_data2_expt   EXCEPTION;      -- データ取得スキップ2(その他付随マスタ)例外
    sql_err_expt      EXCEPTION;      -- データ抽出エラー例外
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
--
    BEGIN
      --------------
      -- 変数初期化
      --------------
      lv_put_msg                := NULL;
      ln_data_cnt               := 0;
      lv_msg_tkn_1              := NULL;
      lv_msg_tkn_2              := NULL;
      lv_msg_tkn_3              := NULL;
      lv_msg_tkn_4              := NULL;
      lv_msg_tkn_5              := NULL;
      lv_msg_tkn_6              := NULL;
      lt_new_manufacturer_name  := NULL;
      lt_new_age_type           := NULL;
      lv_owner_company_code     := cv_owner_company_h_office; --デフォルト本社を設定
      lt_new_owner_company      := NULL;
      lt_new_location           := NULL;
      ld_move_date              := NULL;
--
      ------------------------------
      -- 物件・顧客情報取得
      ------------------------------
      OPEN get_new_old_data_cur;
      FETCH get_new_old_data_cur INTO l_get_new_old_data_rec;
      ln_data_cnt := get_new_old_data_cur%ROWCOUNT;
      CLOSE get_new_old_data_cur;
      --データ存在確認
      IF ( ln_data_cnt = cn_0 ) THEN
        -- トークン取得
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name             -- アプリケーション短縮名
                          ,iv_name         => cv_msg_inst_relat_data  -- 物件関連情報(固定)
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name             -- アプリケーション短縮名
                          ,iv_name         => cv_msg_instance_id      -- 物件ID(固定)
                         );
        lv_msg_tkn_3 :=  TO_CHAR( it_instance_id );
        RAISE skip_data1_expt;
      END IF;
--
      ------------------------------
      -- 機種情報抽出
      ------------------------------
      BEGIN
        --
        SELECT xxcso_util_common_pkg.get_lookup_meaning(
                  cv_xxcso_csi_maker_code
                 ,punv.attribute2
                 ,gd_process_date
                )               manufacturer_name  -- 新_メーカー名
              ,punv.attribute3  age_type           -- 新_年式
        INTO   lt_new_manufacturer_name
              ,lt_new_age_type
        FROM   po_un_numbers_vl punv -- 国連番号マスタビュー
        WHERE  punv.un_number = l_get_new_old_data_rec.new_model -- 国連番号
        ;
      EXCEPTION
        -- データが存在しない
        WHEN NO_DATA_FOUND THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_model         -- 機種(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_model_code    -- 機種コード(固定)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_model;
          RAISE skip_data2_expt;
        -- その他例外(中断)
        WHEN OTHERS THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_model         -- 機種(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_model_code    -- 機種コード(固定)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_model;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ------------------------------
      -- 本社/工場区分取得
      ------------------------------
      <<loop_mfg_fctory_cd_chk>>
      FOR i IN 1..g_mfg_fctory_cd.LAST LOOP
        -- 抽出した新_拠点コードがA-1で取得した工場返品倉替先コードと一致する場合
        IF (l_get_new_old_data_rec.new_department_code = g_mfg_fctory_cd(i)) THEN
          -- 新_本社／工場区分に「'2'：工場」を設定
          lv_owner_company_code := cv_owner_company_fact;
        END IF;
      END LOOP loop_mfg_fctory_cd_chk;
      --
      BEGIN
        --
        SELECT ffvv.flex_value  new_owner_company -- 新_本社／工場区分
        INTO   lt_new_owner_company
        FROM   fnd_flex_value_sets ffvs  -- 値セットヘッダ
              ,fnd_flex_values_vl  ffvv  -- 値セット名称
        WHERE  ffvs.flex_value_set_name = cv_xxcff_owner_company  -- 値セット名(XXCFF_OWNER_COMPANY)
        AND    ffvv.flex_value_set_id   = ffvs.flex_value_set_id
        AND    ffvv.enabled_flag        = cv_yes  -- 使用可能フラグ
        AND    gd_process_date BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                               AND     TRUNC(NVL(ffvv.end_date_active,   gd_process_date)) -- 有効期間
        AND    ffvv.flex_value_meaning =
          (
            SELECT flvv.meaning meaning  -- 内容（本社／工場）
            FROM   fnd_lookup_values_vl flvv  -- クイックコード
            WHERE  flvv.lookup_type  = cv_xxcso1_owner_company   -- タイプ
            AND    flvv.lookup_code  = lv_owner_company_code     -- 本社／工場フラグ
            AND    flvv.enabled_flag = cv_yes                    -- 使用可能フラグ
            AND    gd_process_date  BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                    AND     TRUNC(NVL(flvv.end_date_active,   gd_process_date)) -- 有効期間
          )
        ;
      EXCEPTION
        -- データが存在しない
        WHEN NO_DATA_FOUND THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- アプリケーション短縮名
                            ,iv_name         => cv_msg_owner_comp_type  -- 本社/工場区分(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- アプリケーション短縮名
                            ,iv_name         => cv_msg_owner_comp_type  -- 本社/工場区分(固定)
                           );
          lv_msg_tkn_5 :=  lv_owner_company_code;
          RAISE skip_data2_expt;
        -- その他例外(中断)
        WHEN OTHERS THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- アプリケーション短縮名
                            ,iv_name         => cv_msg_owner_comp_type  -- 本社/工場区分(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- アプリケーション短縮名
                            ,iv_name         => cv_msg_owner_comp_type  -- 本社/工場区分(固定)
                           );
          lv_msg_tkn_5 :=  lv_owner_company_code;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ------------------------------
      -- 事業所取得
      ------------------------------
      BEGIN
        --
        SELECT ffvv.flex_value   location    -- 事業所
        INTO   lt_new_location
        FROM   fnd_flex_value_sets   ffvs   -- 値セットヘッダ
              ,fnd_flex_values_vl    ffvv   -- 値セット名称
        WHERE  ffvs.flex_value_set_name  = cv_xxcff_mng_place
        AND    ffvv.attribute1           = l_get_new_old_data_rec.new_department_code
        AND    ffvv.flex_value_set_id    = ffvs.flex_value_set_id
        AND    ffvv.enabled_flag         = cv_yes
        AND    gd_process_date  BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                AND     TRUNC(NVL(ffvv.end_date_active,   gd_process_date))
        ;
      EXCEPTION
        -- データが存在しない
        WHEN NO_DATA_FOUND THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- アプリケーション短縮名
                            ,iv_name         => cv_msg_mng_place      -- 事業所(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- アプリケーション短縮名
                            ,iv_name         => cv_msg_sale_base      -- 売上拠点(固定)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_department_code;
          RAISE skip_data2_expt;
        -- その他例外(中断)
        WHEN OTHERS THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- アプリケーション短縮名
                            ,iv_name         => cv_msg_mng_place      -- 事業所(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- アプリケーション短縮名
                            ,iv_name         => cv_msg_sale_base      -- 売上拠点(固定)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_department_code;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ------------------------------------------------
      -- 申告地(マスタ存在チェック)
      ------------------------------------------------
      -- 申告地
      BEGIN
        --
        SELECT 1
        INTO   cv_dummy
        FROM   fnd_flex_value_sets ffvs  -- 値セットヘッダ
              ,fnd_flex_values_vl  ffvv  -- 値セット名称
        WHERE  ffvs.flex_value_set_name = cv_xxcff_dclr_place  -- 値セット名(XXCFF_DCLR_PLACE)
        AND    ffvv.flex_value_set_id   = ffvs.flex_value_set_id
        AND    ffvv.enabled_flag        = cv_yes  -- 使用可能フラグ
        AND    gd_process_date BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                               AND     TRUNC(NVL(ffvv.end_date_active,   gd_process_date)) -- 有効期間
        AND    ffvv.flex_value          = l_get_new_old_data_rec.new_declaration_place     -- 申告地
        ;
      EXCEPTION
        -- データが存在しない
        WHEN NO_DATA_FOUND THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- アプリケーション短縮名
                            ,iv_name         => cv_msg_dclr_place     -- 申告地(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- アプリケーション短縮名
                            ,iv_name         => cv_msg_dclr_place     -- 申告地(固定)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_declaration_place;
          RAISE skip_data2_expt;
        -- その他例外(中断)
        WHEN OTHERS THEN
          -- トークン取得
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_dclr_place    -- 申告地(固定)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_dclr_place    -- 申告地(固定)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_declaration_place;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ---------------------------------------------------------------
      -- 変更チェック、及び、物件関連情報変更履歴テーブル更新項目設定
      ---------------------------------------------------------------
      -- 比較用(新データ)の格納(物件履歴更新データとしても使用)
      g_new_data_rec.install_code        := l_get_new_old_data_rec.install_code;             -- 物件コード
      g_new_data_rec.manufacturer_name   := lt_new_manufacturer_name;                        -- メーカー名
      g_new_data_rec.age_type            := lt_new_age_type;                                 -- 年式
      g_new_data_rec.un_number           := l_get_new_old_data_rec.new_model;                -- 機種
      g_new_data_rec.install_number      := l_get_new_old_data_rec.new_serial_number;        -- 機番
      g_new_data_rec.quantity            := l_get_new_old_data_rec.new_quantity;             -- 数量
      g_new_data_rec.base_code           := l_get_new_old_data_rec.new_department_code;      -- 拠点コード
      g_new_data_rec.owner_company_type  := lt_new_owner_company;                            -- 本社／工場区分
      g_new_data_rec.install_name        := l_get_new_old_data_rec.new_installation_place;   -- 設置先名
      g_new_data_rec.install_address     := l_get_new_old_data_rec.new_installation_address; -- 設置先住所
      g_new_data_rec.logical_delete_flag := l_get_new_old_data_rec.new_active_flag;          -- 論理削除フラグ
/* 2016.02.09 H.Okada E_本稼働_13456 ADD START */
      g_new_data_rec.fa_move_date        := l_get_new_old_data_rec.new_fa_move_date;         -- 固定資産移動日
/* 2016.02.09 H.Okada E_本稼働_13456 ADD END */
      --
      -- 顧客コード
      IF (l_get_new_old_data_rec.new_customer_class_code = cv_cust_class_10) THEN
        g_new_data_rec.account_number    := l_get_new_old_data_rec.new_customer_code;        -- 顧客コード
      ELSE
        g_new_data_rec.account_number    := gv_customer_code_dammy;                          -- ダミー顧客コード(拠点)
      END IF;
      g_new_data_rec.declaration_place   := l_get_new_old_data_rec.new_declaration_place;    -- 申告地
      --
      -- 廃棄決裁で未連携
      IF ( iv_data_type = cv_disposed ) THEN
        g_new_data_rec.disposal_intaface_flag := cv_yes;
      -- その他
      ELSE
        g_new_data_rec.disposal_intaface_flag := cv_no;
      END IF;
      --
      -- 夜間処理の場合
      IF ( gv_prm_process_date IS NULL) THEN
        -- 変更データの場合
        IF ( iv_data_type = cv_update ) THEN
          --比較用(旧データ)の格納
          l_old_data_rec.manufacturer_name   := l_get_new_old_data_rec.old_manufacturer_name;    -- メーカー名
          l_old_data_rec.age_type            := l_get_new_old_data_rec.old_age_type;             -- 年式
          l_old_data_rec.un_number           := l_get_new_old_data_rec.old_model;                -- 機種
          l_old_data_rec.install_number      := l_get_new_old_data_rec.old_serial_number;        -- 機番
          l_old_data_rec.quantity            := l_get_new_old_data_rec.old_quantity;             -- 数量
          l_old_data_rec.base_code           := l_get_new_old_data_rec.old_department_code;      -- 拠点コード
          l_old_data_rec.owner_company_type  := l_get_new_old_data_rec.old_owner_company;        -- 本社／工場区分
          l_old_data_rec.install_name        := l_get_new_old_data_rec.old_installation_place;   -- 設置先名
          l_old_data_rec.install_address     := l_get_new_old_data_rec.old_installation_address; -- 設置先住所
          l_old_data_rec.logical_delete_flag := l_get_new_old_data_rec.old_active_flag;          -- 論理削除フラグ
          l_old_data_rec.account_number      := l_get_new_old_data_rec.old_customer_code;        -- 顧客コード
          l_old_data_rec.declaration_place   := l_get_new_old_data_rec.old_declaration_place;    -- 申告地
          --
          -- =================================
          -- A-4.物件関連情報変更チェック処理
          -- =================================
          chk_xxcso_ib_info_h(
             iv_new_data     => g_new_data_rec     -- 1.新データ
            ,iv_old_data     => l_old_data_rec     -- 2.旧データ
            ,on_change_ptn   => ln_change_ptn      -- 3.変更パターン(1:修正 2:移動)
            ,od_move_date    => ld_move_date       -- 4.移動日 ※変更パターン2の場合のみ設定
            ,ov_errbuf       => lv_errbuf          --   エラー・メッセージ           --# 固定 #
            ,ov_retcode      => lv_retcode         --   リターン・コード             --# 固定 #
            ,ov_errmsg       => lv_errmsg);        --   ユーザー・エラー・メッセージ --# 固定 #
          -- エラーの場合(中断)
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
      END IF;
--
      -------------------------------------
      -- インターフェースデータ設定
      -------------------------------------
      -- 共通項目
      g_if_rec.object_code           := l_get_new_old_data_rec.install_code;              -- 物件コード
      g_if_rec.generation_date       := gd_process_date;                                  -- 発生日
      g_if_rec.manufacturer_name     := g_new_data_rec.manufacturer_name;                 -- メーカ名
      g_if_rec.age_type              := g_new_data_rec.age_type;                          -- 年式
      g_if_rec.model                 := g_new_data_rec.un_number;                         -- 機種
      g_if_rec.quantity              := g_new_data_rec.quantity;                          -- 数量
      g_if_rec.department_code       := g_new_data_rec.base_code;                         -- 管理部門
      g_if_rec.owner_company_type    := g_new_data_rec.owner_company_type;                -- 本社／工場区分
      g_if_rec.installation_place    := SUBSTRB( g_new_data_rec.install_name, 1, 50 );    -- 現設置先
      g_if_rec.installation_address  := g_new_data_rec.install_address;                   -- 現設置場所
      g_if_rec.active_flag           := l_get_new_old_data_rec.effective_flag;            -- 物件有効フラグ
      g_if_rec.import_status         := cv_0;                                             -- 取込ステータス(未取込)
      g_if_rec.group_id              := NULL;                                             -- グループID
      g_if_rec.customer_code         := g_new_data_rec.account_number;                    -- 顧客コード
      g_if_rec.machine_type          := l_get_new_old_data_rec.new_instance_type_code;    -- 機器区分
      g_if_rec.lease_class           := l_get_new_old_data_rec.lease_class;               -- リース種別
      g_if_rec.assets_cost           := l_get_new_old_data_rec.new_assets_cost;           -- 取得価格
      g_if_rec.dclr_place            := l_get_new_old_data_rec.new_declaration_place;     -- 申告地 
      g_if_rec.location              := SUBSTRB( lt_new_location, 1, 30 );                -- 事業所
      g_if_rec.date_retired          := l_get_new_old_data_rec.new_disposed_date;         -- 除・売却日
      --------------------------
      -- 事業供与日の設定
      --------------------------
      -- 新古台以外
      IF ( NVL( l_get_new_old_data_rec.newold_flag, cv_no ) <> cv_yes ) THEN
        g_if_rec.date_placed_in_service     :=
          TRUNC( ADD_MONTHS( l_get_new_old_data_rec.new_first_install_date, cn_1 ), cv_mm );  -- 事業供用日(初回設置日翌月１日)
      ELSE
        g_if_rec.date_placed_in_service     :=
          TRUNC( ADD_MONTHS( l_get_new_old_data_rec.new_creation_date, cn_1 ), cv_mm );       -- 事業供用日(作成日翌月１日)
      END IF;
      --------------------------
      -- 移動日の設定
      --------------------------
      -- 夜間(新規)
      IF ( iv_data_type = cv_create ) THEN
        g_if_rec.moved_date      := NULL;          -- 移動日
      -- 夜間(更新)
      ELSIF ( iv_data_type = cv_update ) THEN
        -- 2(移動)を伴う場合
        IF ( ln_change_ptn = cn_2 ) THEN
          g_if_rec.moved_date    := ld_move_date;  -- 移動日(顧客移行日 or 実作業日 or 業務日付)
        -- 1(修正)
        ELSE
          g_if_rec.moved_date    := NULL;          -- 移動日(NULL)
        END IF;
      -- 夜間(廃棄)
      ELSIF ( iv_data_type = cv_disposed ) THEN
        g_if_rec.moved_date      := NULL;          -- 移動日(NULL)
      -- 随時
      ELSIF ( iv_data_type = cv_any_time ) THEN
        g_if_rec.moved_date      := NULL;          -- 移動日(NULL)
        g_if_rec.date_retired    := NULL;          -- 除・売却日(NULL)
      END IF;
--
    EXCEPTION
      -- データ取得スキップ(物件マスタ)例外(処理継続)
      WHEN skip_data1_expt THEN
        -- メッセージ編集
        lv_put_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_msg_no_data1_wrn  -- データなし警告メッセージ
                       ,iv_token_name1  => cv_tkn_task_name
                       ,iv_token_value1 => lv_msg_tkn_1
                       ,iv_token_name2  => cv_tkn_item
                       ,iv_token_value2 => lv_msg_tkn_2
                       ,iv_token_name3  => cv_tkn_base_value
                       ,iv_token_value3 => lv_msg_tkn_3
                      );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_put_msg       -- 出力メッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_put_msg       -- ログメッセージ
          );
        ov_retcode := cv_status_warn;
      -- データ取得スキップ(その他付随マスタ)例外(処理継続)
      WHEN skip_data2_expt THEN
        -- トークン編集
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          -- アプリケーション短縮名
                          ,iv_name         => cv_msg_instance_code -- 物件コード(固定)
                         );
        lv_msg_tkn_3 :=  l_get_new_old_data_rec.install_code;
        -- メッセージ編集
        lv_put_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_no_data2_wrn     -- データなしメッセージ(キー付き)
                       ,iv_token_name1  => cv_tkn_task_name
                       ,iv_token_value1 => lv_msg_tkn_1
                       ,iv_token_name2  => cv_tkn_key
                       ,iv_token_value2 => lv_msg_tkn_2
                       ,iv_token_name3  => cv_tkn_key_value
                       ,iv_token_value3 => lv_msg_tkn_3
                       ,iv_token_name4  => cv_tkn_item
                       ,iv_token_value4 => lv_msg_tkn_4
                       ,iv_token_name5  => cv_tkn_base_value
                       ,iv_token_value5 => lv_msg_tkn_5
                      );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_put_msg       -- 出力メッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_put_msg       -- ログメッセージ
          );
        ov_retcode := cv_status_warn;
      -- SQLエラー例外(処理中断)
      WHEN sql_err_expt THEN
        -- トークン編集
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          -- アプリケーション短縮名
                          ,iv_name         => cv_msg_instance_code -- 物件コード(固定)
                         );
        lv_msg_tkn_3 :=  l_get_new_old_data_rec.install_code;
        -- メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_msg_get_data2_err     -- 抽出エラーメッセージ(キー付き)
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_key
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_key_value
                      ,iv_token_value3 => lv_msg_tkn_3
                      ,iv_token_name4  => cv_tkn_item
                      ,iv_token_value4 => lv_msg_tkn_4
                      ,iv_token_name5  => cv_tkn_base_value
                      ,iv_token_value5 => lv_msg_tkn_5
                      ,iv_token_name6  => cv_tkn_err_msg
                      ,iv_token_value6 => lv_msg_tkn_6
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END get_relation_data;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : 対象物件抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- プログラム名
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
    l_get_target_rec  get_target_cur%ROWTYPE;    -- 対象物件取得カーソルレコード変数
    -- *** ローカル例外 ***
    skip_data_expt    EXCEPTION;                 -- スキップデータ例外
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
    OPEN get_target_cur;
    <<loop_get_target>>
    LOOP
      BEGIN
        FETCH get_target_cur INTO l_get_target_rec;
        EXIT WHEN get_target_cur%NOTFOUND;
--
        -- 対象件数の取得
        gn_target_cnt := gn_target_cnt + 1;
--
        -- 変数の初期化
        g_new_data_rec := NULL;  -- 新旧データ比較(物件履歴テーブル更新)用レコード型
        g_if_rec       := NULL;  -- インターフェース登録データ格納用レコード型
--
        -- ========================================
        -- A-3.物件関連情報取得
        -- ========================================
        get_relation_data(
           iv_data_type    => l_get_target_rec.data_type     -- 1.データタイプ(1:新規 2:更新 3:廃棄 4:随時)
          ,it_instance_id  => l_get_target_rec.instance_id   -- 2.物件ID
          ,ov_errbuf       => lv_errbuf                      --   エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode                     --   リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg);                    --   ユーザー・エラー・メッセージ --# 固定 #
        -- エラーの場合(中断)
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        -- 警告の場合(スキップ)
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- =============================================
        -- A-5.自販機物件管理インタフェース存在チェック
        -- =============================================
        chk_xxcff_if_exists(
           ov_errbuf       => lv_errbuf                      --   エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode                     --   リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg);                    --   ユーザー・エラー・メッセージ --# 固定 #
        -- エラーの場合(中断)
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        -- 警告の場合(スキップ)
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- 随時以外の場合
        IF ( l_get_target_rec.data_type NOT IN ( cv_any_time ) ) THEN
          -- =========================================
          -- A-6.物件関連変更履歴テーブルロック処理
          -- =========================================
          lock_xxcso_ib_info_h(
            ov_errbuf       => lv_errbuf                      --   エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode                     --   リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg);                    --   ユーザー・エラー・メッセージ --# 固定 #
           -- エラーの場合(中断)
           IF (lv_retcode = cv_status_error) THEN
             RAISE global_process_expt;
           -- 警告の場合(スキップ)
           ELSIF (lv_retcode = cv_status_warn) THEN
             RAISE skip_data_expt;
           END IF;
--
          -- =========================================
          -- A-7.物件関連変更履歴テーブル更新処理
          -- =========================================
          upd_xxcso_ib_info_h(
            ov_errbuf       => lv_errbuf                      --   エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode                     --   リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg);                    --   ユーザー・エラー・メッセージ --# 固定 #
           -- エラーの場合(中断)
           IF (lv_retcode = cv_status_error) THEN
             RAISE global_process_expt;
           END IF;
           --
        END IF;
--
        -- =========================================
        -- A-8.自販機物件管理インタフェース登録処理
        -- =========================================
        ins_xxcff_if(
           ov_errbuf       => lv_errbuf                      --   エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode                     --   リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg);                    --   ユーザー・エラー・メッセージ --# 固定 #
        -- エラーの場合(中断)
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        gn_normal_cnt := gn_normal_cnt + 1;  --正常件数カウント
--
      EXCEPTION
        -- 警告データ例外(処理継続)
        WHEN skip_data_expt THEN
          gn_warn_cnt := gn_warn_cnt + 1;    -- 警告件数カウント
          ov_retcode  := lv_retcode;         -- 戻り値に警告を設定
      END;
--
    END LOOP get_target_cur;
    --
    --カーソルクローズ
    CLOSE get_target_cur;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
      -- カーソルクローズ
      IF ( get_target_cur%ISOPEN ) THEN
        CLOSE get_target_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_process_date IN  VARCHAR2     -- 1.処理実行日
    ,ov_errbuf       OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
       iv_process_date => iv_process_date   -- 1.処理実行日
      ,ov_errbuf       => lv_errbuf         --   エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode        --   リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);       --   ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象物件抽出(A-2)
    -- ===============================
    get_target_data(
       ov_errbuf       => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode        -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
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
     errbuf          OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
    ,retcode         OUT VARCHAR2      --   リターン・コード    --# 固定 #
    ,iv_process_date IN  VARCHAR2      -- 1.処理実行日
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
       iv_process_date => iv_process_date  -- 1.処理実行日
      ,ov_errbuf       => lv_errbuf        --   エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode       --   リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg        --   ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      --
      --件数設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      --
    END IF;
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
END XXCSO013A03C;
/
