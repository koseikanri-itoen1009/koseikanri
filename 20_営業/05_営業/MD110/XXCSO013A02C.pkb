CREATE OR REPLACE PACKAGE BODY APPS.XXCSO013A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO013A02C(body)
 * Description      : 自販機管理システムから連携されたリース物件に関連する作業の情報を、
 *                    リースアドオンに反映します。
 * MD.050           :  MD050_CSO_013_A02_CSI→FAインタフェース：（OUT）リース資産情報
 * Version          : 1.16
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                          初期処理 (A-1)
 *  get_po_number                 発注番号抽出 (A-3)
 *  get_type_info                 機種情報抽出 (A-4)
 *  get_acct_info                 顧客関連情報抽出 (A-5)
 *  ib_info_change_chk            物件関連情報変更チェック処理 (A-6)
 *  xxcff_vd_object_if_chk        自販機SH物件インタフェース存在チェック (A-7)
 *  xxcso_ib_info_h_lock          物件関連変更履歴テーブルロック (A-8)
 *  insert_xxcff_vd_object_if     自販機SH物件インタフェース登録処理 (A-10)
 *  update_xxcso_ib_info_h        物件関連情報変更履歴テーブル更新処理 (A-11)
 *  submain                       メイン処理プロシージャ
 *                                  物件関連情報抽出 (A-2)
 *                                  セーブポイント発行処理 (A-9)
 *  main                          コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-02    1.0   Tomoko.Mori      新規作成
 *  2009-04-01    1.1   Kazuo.Satomura   T1_0148,0149対応
 *  2009-04-03    1.2   Kazuo.Satomura   T1_0269対応
 *  2009-04-07    1.3   Daisuke.Abe      T1_0339対応
 *  2009-04-07    1.4   Kazuo.Satomura   T1_0378対応
 *  2009-04-08    1.5   Kazuo.Satomura   T1_0372,0403対応
 *  2009-04-28    1.6   Tomoko.Mori      T1_0758対応
 *  2009-05-01    1.7   Tomoko.Mori      T1_0897対応
 *  2009-05-14    1.8   Kazuo.Satomura   T1_0413対応,SQLをコーディング規約通りに修正
 *  2009-05-20    1.9   Kazuo.Satomura   T1_1095対応
 *  2009-05-26    1.10  Daisuke.Abe      T1_1042対応
 *  2009-05-28    1.11  Daisuke.Abe      T1_1042(再)対応
 *  2009-05-28    1.12  Daisuke.Abe      T1_1042(再２)対応
 *  2009-07-02    1.13  Kazuo.Satomura   統合テスト障害対応(0000229,0000334)
 *  2009-07-17    1.14  Hiroshi.Ogawa    0000781対応
 *  2009-08-19    1.15  Kazuo.Satomura   統合テスト障害対応(0001051)
 *  2010-01-13    1.16  Kazuyo.Hosoi     E_本稼動_00443対応
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO013A02C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00250';  -- パラメータ処理区分
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00147';  -- パラメータ処理実行日
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- パラメータ処理区分入力なしエラーメッセージ
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00252';  -- パラメータ処理区分妥当性チェックエラーメッセージ
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';  -- 日付書式エラーメッセージ
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00192';  -- コンカレント入力パラメータなしメッセージ
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日取得エラーメッセージ
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラーメッセージ
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00163';  -- ステータスIDなしエラーメッセージ
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00164';  -- ステータスID抽出エラーメッセージ
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173';  -- 参照タイプなしエラーメッセージ
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00253';  -- 参照タイプ抽出エラーメッセージ
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00242';  -- データなし警告メッセージ
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- データ抽出エラーメッセージ
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00254';  -- 値セットなし警告メッセージ
  cv_tkn_number_16    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00255';  -- 値セット抽出エラーメッセージ
  cv_tkn_number_17    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00158';  -- 登録エラーメッセージ
  cv_tkn_number_18    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00272';  -- 自販機SH物件インタフェース存在チェックエラーメッセージ
  cv_tkn_number_19    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- 物件関連情報抽出エラーメッセージ
  cv_tkn_number_20    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00104';  -- 発注番号なし警告メッセージ
  cv_tkn_number_21    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00105';  -- 発注番号抽出エラーメッセージ
  -- トークンコード
  cv_tkn_entry            CONSTANT VARCHAR2(20) := 'ENTRY';
  cv_tkn_value            CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_prof_name        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_task_name        CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_status_name      CONSTANT VARCHAR2(20) := 'STATUS_NAME';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_value_set_name   CONSTANT VARCHAR2(20) := 'VALUE_SET_NAME';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_bukken           CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
--
  -- メッセージ用固定文字列
  cv_tkn_msg_pro_div      CONSTANT VARCHAR2(200) := '処理区分';
  cv_tkn_msg_pro_date     CONSTANT VARCHAR2(200) := '処理対象日付';
  cv_tkn_msg_itoen_acc_nm CONSTANT VARCHAR2(200) := 'XXCSO:伊藤園顧客名';
  /* 2009.04.28 T.Mori T1_0758対応 START */
  cv_tkn_msg_cust_cd_dammy CONSTANT VARCHAR2(200) := 'XXCSO:AFF顧客コード（定義なし）';
  /* 2009.04.28 T.Mori T1_0758対応 END */
  cv_tkn_msg_org_id       CONSTANT VARCHAR2(200) := 'MO:営業単位';
  cv_tkn_msg_status_id    CONSTANT VARCHAR2(200) := 'インスタンスステータスマスタのステータスID';
  cv_tkn_msg_object_del   CONSTANT VARCHAR2(200) := '物件削除済';
  cv_tkn_msg_lookup_type  CONSTANT VARCHAR2(200) := '参照タイプ';
  cv_tkn_msg_inv_henpin   CONSTANT VARCHAR2(200) := 'INV 工場返品倉替先コード';
  cv_tkn_msg_po_num       CONSTANT VARCHAR2(200) := '発注番号';
  cv_tkn_msg_model        CONSTANT VARCHAR2(200) := '機種';
  cv_tkn_msg_model_cd     CONSTANT VARCHAR2(200) := '機種コード';
  cv_tkn_msg_acct_info    CONSTANT VARCHAR2(200) := '顧客関連情報';
  cv_tkn_msg_account_id   CONSTANT VARCHAR2(200) := '所有者アカウントID';
  cv_tkn_msg_value_set    CONSTANT VARCHAR2(200) := '値セット';
  cv_tkn_msg_owner_comp   CONSTANT VARCHAR2(200) := '本社／工場区分';
  cv_tkn_msg_vd_object_if CONSTANT VARCHAR2(200) := '自販機SH物件インタフェース';
/* 2009.07.17 H.Ogawa 0000781対応 START */
  cv_tkn_msg_target       CONSTANT VARCHAR2(200) := '抽出対象物件';
/* 2009.07.17 H.Ogawa 0000781対応 END */
  cv_tkn_msg_ib_info      CONSTANT VARCHAR2(200) := '物件関連情報';
  cv_tkn_msg_ib_info_h    CONSTANT VARCHAR2(200) := '物件関連情報変更履歴';
  cv_tkn_msg_select       CONSTANT VARCHAR2(200) := '抽出';
  cv_tkn_msg_insert       CONSTANT VARCHAR2(200) := '登録';
  cv_tkn_msg_update       CONSTANT VARCHAR2(200) := '更新';
  cv_tkn_msg_lock         CONSTANT VARCHAR2(200) := 'ロック';
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1_1         CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg1_2         CONSTANT VARCHAR2(200) := 'gd_sys_date = ';
  cv_debug_msg1_3         CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg1_4         CONSTANT VARCHAR2(200) := 'gd_business_date = ';
  cv_debug_msg1_5         CONSTANT VARCHAR2(200) := '<< 処理日取得処理 >>';
  cv_debug_msg1_6         CONSTANT VARCHAR2(200) := 'gd_process_date = ';
  cv_debug_msg1_7         CONSTANT VARCHAR2(200) := '<< 伊藤園顧客名取得処理 >>';
  cv_debug_msg1_8         CONSTANT VARCHAR2(200) := 'gv_itoen_cust_name = ';
  cv_debug_msg1_9         CONSTANT VARCHAR2(200) := '<< 営業単位取得処理 >>';
  cv_debug_msg1_10        CONSTANT VARCHAR2(200) := 'gn_org_id = ';
  cv_debug_msg1_11        CONSTANT VARCHAR2(200) := '<< インスタンスステータスID取得処理 >>';
  cv_debug_msg1_12        CONSTANT VARCHAR2(200) := 'gn_instance_status_id = ';
  cv_debug_msg1_13        CONSTANT VARCHAR2(200) := '<< INV 工場返品倉替先コード取得処理 >>';
  cv_debug_msg1_14        CONSTANT VARCHAR2(200) := '工場返品倉替先コード = ';
  cv_debug_msg1_15        CONSTANT VARCHAR2(200) := 'INV 工場返品倉替先コード取得用カーソル';
/* 2009.07.17 H.Ogawa 0000781対応 START */
  cv_debug_msg1_16        CONSTANT VARCHAR2(200) := '<< IB属性レベル取得処理 >>';
  cv_debug_msg1_17        CONSTANT VARCHAR2(200) := 'gv_attribute_level = ';
  cv_debug_msgsub_0       CONSTANT VARCHAR2(200) := '抽出対象物件取得用カーソル';
/* 2009.07.17 H.Ogawa 0000781対応 END */
  cv_debug_msgsub_1       CONSTANT VARCHAR2(200) := '物件関連情報取得用カーソル';
  cv_debug_msg_rollback   CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err0_1     CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err0_2     CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err0_3     CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err1_1     CONSTANT VARCHAR2(200) := 'prm_check_expt';
  cv_debug_msg_err1_2     CONSTANT VARCHAR2(200) := 'sql_err_expt';
  --
  cv_yes                  CONSTANT VARCHAR2(1) := 'Y';
  cv_no                   CONSTANT VARCHAR2(1) := 'N';
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
  cv_null                 CONSTANT VARCHAR2(10) := 'NULL';
  /* 2009.04.08 K.Satomura T1_0403対応 START */
  cn_zero                 CONSTANT NUMBER := 0;
  /* 2009.04.08 K.Satomura T1_0403対応 END */
  --INパラメータ：処理区分
  cv_prm_normal           CONSTANT VARCHAR2(1) := '1';
  cv_prm_div              CONSTANT VARCHAR2(1) := '2';
  --INパラメータ：処理実行日フォーマット
  cv_prm_date_format      CONSTANT VARCHAR2(8) := 'YYYYMMDD';
  -- インスタンスマスタ：ステータス
  cv_delete_code            CONSTANT VARCHAR2(1) := '6'; -- 物件削除済コード
  -- 参照タイプ
  cv_xxcoi_mfg_fctory_cd    CONSTANT VARCHAR2(200) := 'XXCOI_MFG_FCTORY_CD';
  cv_xxcso1_instance_status CONSTANT VARCHAR2(200) := 'XXCSO1_INSTANCE_STATUS';
  cv_csi_inst_type_code     CONSTANT VARCHAR2(200) := 'CSI_INST_TYPE_CODE';
  cv_xxcso_csi_maker_code   CONSTANT VARCHAR2(200) := 'XXCSO_CSI_MAKER_CODE';
  cv_xxcff_owner_company    CONSTANT VARCHAR2(200) := 'XXCFF_OWNER_COMPANY';
  cv_xxcso1_owner_company   CONSTANT VARCHAR2(200) := 'XXCSO1_OWNER_COMPANY';
  -- 物件マスタ追加属性地取得項目名
  cv_lease_kbn              CONSTANT VARCHAR2(200) := 'LEASE_KBN';
  -- リース区分
  cv_jisya_lease            CONSTANT VARCHAR2(1) := '1'; -- 自社リース
  -- 作業区分
  cv_job_kbn_set            CONSTANT VARCHAR2(1) := '1'; -- 新台設置
  cv_job_kbn_change         CONSTANT VARCHAR2(1) := '3'; -- 新台代替
  -- 完了区分
  cv_comp_kbn_ok            CONSTANT VARCHAR2(1) := '1'; -- 完了
  -- 本社／工場区分
  cv_owner_company_honsya   CONSTANT VARCHAR2(1) := '1'; -- 本社
  cv_owner_company_fact     CONSTANT VARCHAR2(1) := '2'; -- 工場
  -- 取込ステータス（固定値）
  cv_import_status          CONSTANT VARCHAR2(1) := '0'; -- 未取込
  -- 顧客ステータス
  cv_cut_enb_status         CONSTANT VARCHAR2(1) := 'A'; -- 使用可
  /* 2009.04.28 T.Mori T1_0758対応 START */
  -- 顧客区分
  cv_cust_class_10          CONSTANT VARCHAR2(200) := '10'; -- 10:顧客
  -- プロファイル･オプション値
  cv_prf_cust_cd_dammy      CONSTANT VARCHAR2(200) := 'XXCSO1_AFF_CUST_CODE'; -- 顧客コード（定義なし）
  /* 2009.04.28 T.Mori T1_0758対応 END */
/* 2009.07.17 H.Ogawa 0000781対応 START */
  cv_attribute_level        CONSTANT VARCHAR2(200) := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
/* 2009.07.17 H.Ogawa 0000781対応 END */
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- パラメータ格納用
  gv_prm_process_div          VARCHAR2(1);  -- 処理区分
  gv_prm_process_date         VARCHAR2(8);  -- 処理実行日
  -- ロールバック済フラグ
  gv_rollback_flg             VARCHAR2(1);  -- ロールバック済：'Y'
  --
  gd_process_date         DATE;  -- 処理日
  gd_sys_date             DATE;  -- システム日付
  gd_business_date        DATE;  -- 業務処理日付
  -- プロファイル･オプション値
  gv_itoen_cust_name      VARCHAR2(200);  -- 伊藤園顧客名
  gn_org_id               NUMBER;  -- 営業単位
  --
  gn_instance_status_id   NUMBER;  -- インスタンスステータスID
  --
  gn_mfg_fctory_cd_cnt    NUMBER;  -- INV 工場返品倉替先コード件数
  --
  gn_po_number            xxcso_in_work_data.po_number%TYPE;   -- 新_発注番号
  gv_manufacturer_name    fnd_lookup_values_vl.meaning%TYPE;   -- 新_メーカー名
  gv_age_type             po_un_numbers_vl.attribute3%TYPE;    -- 新_年式
  gv_department_code      xxcso_cust_acct_sites_v.customer_class_code%TYPE;
                                                               -- 新_拠点コード
  /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
  --gv_installation_place   xxcso_cust_acct_sites_v.customer_class_name%TYPE;
  --                                                             -- 新_設置先名
  gv_installation_place   hz_parties.party_name%TYPE;
                                                               -- 新_設置先名
  /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
  gv_installation_address VARCHAR2(600);                       -- 新_設置先住所
  gv_customer_code        xxcso_cust_acct_sites_v.account_number%TYPE;
                                                               -- 新_顧客コード
  gv_owner_company        fnd_flex_values_vl.flex_value%TYPE;  -- 新_本社／工場区分
  /* 2009.04.28 T.Mori T1_0758対応 START */
  -- AFF顧客コード（定義なし）
  gv_customer_code_dammy  xxcso_cust_acct_sites_v.account_number%TYPE;
  /* 2009.04.28 T.Mori T1_0758対応 END */
/* 2009.07.17 H.Ogawa 0000781対応 START */
  gv_attribute_level      fnd_profile_option_values.profile_option_value%TYPE;
/* 2009.07.17 H.Ogawa 0000781対応 END */
--
  -- ===============================
  -- ユーザー定義カーソル型
  -- ===============================
  -- INV 工場返品倉替先コード取得用カーソル
  CURSOR mfg_fctory_cd_cur
  IS
    SELECT flvv.lookup_code lookup_code --作成者
    FROM   fnd_lookup_values_vl flvv
    WHERE  flvv.lookup_type = cv_xxcoi_mfg_fctory_cd
    AND    TRUNC(gd_process_date) BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
    AND    TRUNC(NVL(flvv.end_date_active, gd_process_date))
    AND    flvv.enabled_flag = cv_yes
    ;
  -- 物件関連情報取得用カーソル
/* 2009.07.17 H.Ogawa 0000781対応 START */
--CURSOR get_xxcso_ib_info_h_cur
  CURSOR get_xxcso_ib_info_h_cur(
    in_instance_id       NUMBER
  )
/* 2009.07.17 H.Ogawa 0000781対応 END */
  IS
    /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) START */
    --SELECT cii.external_reference        object_code                -- 外部参照（物件コード）
/* 2009.07.17 H.Ogawa 0000781対応 START */
--  SELECT /*+ first_rows leading(cis) use_nl(cii) */
    SELECT /*+ use_nl(cii xiih hca hp xca hcas hps hl) */
/* 2009.07.17 H.Ogawa 0000781対応 END */
           cii.external_reference        object_code                -- 外部参照（物件コード）
    /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) END */
          ,cii.attribute1                new_model                  -- 新_機種(DFF1)
          ,cii.attribute2                new_serial_number          -- 新_機番(DFF2)
          ,cii.owner_party_account_id    owner_party_account_id     -- 所有者アカウントID
          ,DECODE(cii.instance_status_id
                 ,gn_instance_status_id, cv_yes
                 ,cv_no)                 new_active_flag            -- 新_論理削除フラグ
          /* 2009.04.01 K.Satomura T1_0149対応 START */
          --,DECODE(cii.instance_status_id, gn_instance_status_id, cv_yes, cv_no)
          --                               effective_flag             -- 物件有効フラグ
          ,DECODE(cii.instance_status_id
                 ,gn_instance_status_id, cv_no
                 ,cv_yes)                effective_flag             -- 物件有効フラグ
          /* 2009.04.01 K.Satomura T1_0149対応 END */
          ,xxcso_util_common_pkg.get_lookup_attribute(
             cv_csi_inst_type_code
            ,cii.instance_type_code
            ,1
            ,gd_process_date
           )                             lease_class                -- リース種別
          ,cii.quantity                  new_quantity               -- 新_数量
          ,xiih.history_creation_date    history_creation_date      -- 履歴作成日
          ,xiih.interface_flag           interface_flag             -- 連携済フラグ
          ,xiih.po_number                old_po_number              -- 旧_発注番号
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
          /* 2009.04.07 D.Abe T1_0339対応 START */
          ,cii.attribute5                newold_flag                -- 新古台フラグ
          /* 2009.04.07 D.Abe T1_0339対応 END */
          /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) START */
/* 2009.07.17 H.Ogawa 0000781対応 START */
--        ,xca.sale_base_code            new_department_code      -- 新_拠点コード
--        ,xca.established_site_name     new_installation_place   -- 新_設置先名
--        ,xca.state    ||
--         xca.city     ||
--         xca.address1 ||
--         xca.address2                  new_installation_address -- 新_設置先住所
--        ,xca.account_number            new_customer_code        -- 新_顧客コード
--        ,xca.customer_class_code       new_customer_class_code  -- 新_顧客区分コード
          ,xca.sale_base_code            new_department_code      -- 新_拠点コード
          /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
          --,xca.established_site_name     new_installation_place   -- 新_設置先名
          ,hp.party_name                 new_installation_place   -- 新_設置先名
          /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
          ,hl.state    ||
           hl.city     ||
           hl.address1 ||
           hl.address2                   new_installation_address -- 新_設置先住所
          ,hca.account_number            new_customer_code        -- 新_顧客コード
          ,hca.customer_class_code       new_customer_class_code  -- 新_顧客区分コード
/* 2009.07.17 H.Ogawa 0000781対応 END */
          /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) END */
    FROM   csi_item_instances cii    -- インストールベースマスタ
          ,xxcso_ib_info_h xiih      -- 物件関連情報変更履歴テーブル
/* 2009.07.17 H.Ogawa 0000781対応 START */
--        ,csi_instance_statuses cis -- インスタンスステータスマスタ
--        /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) START */
--        ,xxcso_cust_acct_sites_v xca -- 顧客マスタサイトビュー
--        /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) END */
          ,hz_cust_accounts     hca
          ,hz_parties           hp
          ,xxcmm_cust_accounts  xca
          ,hz_cust_acct_sites   hcas
          ,hz_party_sites       hps
          ,hz_locations         hl
/* 2009.07.17 H.Ogawa 0000781対応 END */
    WHERE
/* 2009.07.17 H.Ogawa 0000781対応 START */
           cii.instance_id           = in_instance_id
      AND  xiih.install_code         = cii.external_reference
      AND  hca.cust_account_id       = cii.owner_party_account_id
      AND  hp.party_id               = hca.party_id
      AND  xca.customer_id           = hca.cust_account_id
      AND  hcas.cust_account_id      = hca.cust_account_id
      AND  hps.party_id              = hp.party_id
      AND  hps.party_site_id         = hcas.party_site_id
      AND  hl.location_id            = hps.location_id
--    (
--        /* 2009.05.26 D.Abe T1_1042対応 START */
--        ( (
--             /* 2009.05.28 D.Abe T1_1042(再)対応 START */
--             gv_prm_process_date IS NULL
--             AND  (xiih.history_creation_date < gd_process_date  -- 履歴作成日
--             OR    xiih.interface_flag  =  cv_no             -- 連携済フラグ
--                  )
--             --     gv_prm_process_date IS NULL
--             --AND  xiih.interface_flag  = cv_no         -- 連携済フラグ
--            /* 2009.05.28 D.Abe T1_1042(再)対応 END */
--          )
--          OR (
--                   gv_prm_process_date IS NOT NULL
--               AND TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
--               AND  xiih.interface_flag  = cv_yes      -- 連携済フラグ
--             )
--        )
--      AND
--      --/* 2009.05.14 K.Satomura T1_0413対応 START */
--      --  (
--      --       gv_prm_process_date IS NULL
--      --    OR (
--      --             gv_prm_process_date IS NOT NULL
--      --         AND TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
--      --       )
--      --  )
--      --AND
--      --/* 2009.05.14 K.Satomura T1_0413対応 END */
--      /* 2009.05.26 D.Abe T1_1042対応 END */
--          gv_prm_process_div = cv_prm_normal          -- パラメータ：処理区分
--      AND xiih.install_code  = cii.external_reference -- 物件コード
--      AND xxcso_ib_common_pkg.get_ib_ext_attribs(
--             cii.instance_id
--            ,cv_lease_kbn
--          ) = cv_jisya_lease -- 自社リース
--      AND cii.instance_status_id = cis.instance_status_id -- インスタンスステータスID
--      AND cis.attribute2         = cv_no                  -- 廃棄済フラグ
--      /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) START */
--      AND xca.cust_account_id    = cii.owner_party_account_id -- アカウントID
--      /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) END */
--      /* 2009.05.26 D.Abe T1_1042対応 START */
--      --AND (
--      --         xiih.history_creation_date < gd_process_date  -- 履歴作成日
--      --      OR xiih.interface_flag        = cv_no            -- 連携済フラグ
--      --    )
--      /* 2009.05.26 D.Abe T1_1042対応 END */
--    )
--  OR
--    (
--    /* 2009.05.14 K.Satomura T1_0413対応 START */
--      (
--           gv_prm_process_date IS NULL
--        OR (
--                 gv_prm_process_date IS NOT NULL
--             AND TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
--           )
--      )
--      AND
--    /* 2009.05.14 K.Satomura T1_0413対応 END */
--          gv_prm_process_div = cv_prm_div             -- パラメータ：処理区分
--      AND xiih.install_code  = cii.external_reference -- 物件コード
--      AND xxcso_ib_common_pkg.get_ib_ext_attribs(
--             cii.instance_id
--            ,cv_lease_kbn
--          ) = cv_jisya_lease -- 自社リース
--      AND cii.instance_status_id = cis.instance_status_id -- インスタンスステータスID
--      AND cis.attribute2         = cv_no                  -- 廃棄済フラグ
--      /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) START */
--      AND xca.cust_account_id    = cii.owner_party_account_id -- アカウントID
--      /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) END */
--    )
/* 2009.07.17 H.Ogawa 0000781対応 END */
    ;
/* 2009.07.17 H.Ogawa 0000781対応 START */
  CURSOR get_target_cur
  IS
    SELECT  /*+ LEADING(xiih) INDEX(XXCSO_IB_INFO_H_N02) USE_NL(cii cis) */
            cii.instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
           ,csi_instance_statuses  cis
    WHERE   gv_prm_process_div  = cv_prm_normal
      AND   gv_prm_process_date IS NULL
      AND   xiih.interface_flag    = cv_no
      AND   cii.external_reference = xiih.install_code
      AND   cis.instance_status_id = cii.instance_status_id
      AND   cis.attribute2         = cv_no
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
    UNION ALL
    SELECT  cii.instance_id
    FROM    csi_item_instances   cii
    WHERE   gv_prm_process_div   = cv_prm_normal
      AND   gv_prm_process_date  IS NULL
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
      AND   EXISTS (
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- 新古台以外
                AND   xiih.install_code                  = cii.external_reference
                AND   xiih.history_creation_date         < gd_process_date
                AND   xiih.interface_flag                = cv_yes
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- 顧客コードチェック
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- 売上拠点チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- 設置先名チェック
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- 設置先名チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- 住所チェック
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- 機種チェック
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- 機番チェック
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- 数量チェック
                       OR  NVL(xiih.po_number,' ')            <>                               -- 発注番号チェック
                             (
                              SELECT  NVL(TO_CHAR(MAX(xiwd.po_number)),' ')
                              FROM    xxcso_in_work_data  xiwd
                              WHERE   xiwd.install_code1           = cii.external_reference
                                AND   xiwd.job_kbn                 IN (cv_job_kbn_set, cv_job_kbn_change)
                                AND   xiwd.completion_kbn          = cv_comp_kbn_ok
                                AND   xiwd.install1_processed_flag = cv_yes
                             )
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- メーカー名チェック
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 END */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- 年式チェック
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- 論理削除チェック
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- 本社工場区分チェック
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
              UNION ALL
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
              --WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- 新古台以外
              WHERE   NVL(cii.attribute5,cv_no)          = cv_yes                               -- 新古台
              /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
                AND   xiih.install_code                  = cii.external_reference
                AND   xiih.history_creation_date         < gd_process_date
                AND   xiih.interface_flag                = cv_yes
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- 顧客コードチェック
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- 売上拠点チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- 設置先名チェック
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- 設置先名チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- 住所チェック
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- 機種チェック
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- 機番チェック
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- 数量チェック
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- メーカー名チェック
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 END */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- 年式チェック
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- 論理削除チェック
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- 本社工場区分チェック
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
            )
      AND   EXISTS (
              SELECT  1
              FROM    csi_instance_statuses  cis
              WHERE   cis.instance_status_id   = cii.instance_status_id
                AND   cis.attribute2           = cv_no
                AND   ROWNUM                   = 1
            )
    UNION ALL
    SELECT  /*+ LEADING(xiih) USE_NL(cii cis) */
            cii.instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
           ,csi_instance_statuses  cis
    WHERE   gv_prm_process_div                = cv_prm_normal
      AND   gv_prm_process_date               IS NOT NULL
      AND   TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
      AND   xiih.interface_flag               = cv_yes
      AND   cii.external_reference            = xiih.install_code
      AND   cis.instance_status_id            = cii.instance_status_id
      AND   cis.attribute2                    = cv_no
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
    UNION ALL
    SELECT  cii.instance_id
    FROM    csi_item_instances   cii
    WHERE   gv_prm_process_div   = cv_prm_div
      AND   gv_prm_process_date  IS NULL
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
      AND   EXISTS (
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- 新古台以外
                AND   xiih.install_code                  = cii.external_reference
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- 顧客コードチェック
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- 売上拠点チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- 設置先名チェック
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- 設置先名チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- 住所チェック
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- 機種チェック
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- 機番チェック
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- 数量チェック
                       OR  NVL(xiih.po_number,' ')            <>                               -- 発注番号チェック
                             (
                              SELECT  NVL(TO_CHAR(MAX(xiwd.po_number)),' ')
                              FROM    xxcso_in_work_data  xiwd
                              WHERE   xiwd.install_code1           = cii.external_reference
                                AND   xiwd.job_kbn                 IN (cv_job_kbn_set, cv_job_kbn_change)
                                AND   xiwd.completion_kbn          = cv_comp_kbn_ok
                                AND   xiwd.install1_processed_flag = cv_yes
                             )
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- メーカー名チェック
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 EMD */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- 年式チェック
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- 論理削除チェック
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- 本社工場区分チェック
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
              UNION ALL
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
              --WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- 新古台以外
              WHERE   NVL(cii.attribute5,cv_no)          = cv_yes                               -- 新古台
              /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
                AND   xiih.install_code                  = cii.external_reference
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- 顧客コードチェック
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- 売上拠点チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- 設置先名チェック
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- 設置先名チェック
                       /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- 住所チェック
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- 機種チェック
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- 機番チェック
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- 数量チェック
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- メーカー名チェック
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 END */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- 年式チェック
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051対応 START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051対応 END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- 論理削除チェック
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- 本社工場区分チェック
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
            )
      AND   EXISTS (
              SELECT  1
              FROM    csi_instance_statuses  cis
              WHERE   cis.instance_status_id   = cii.instance_status_id
                AND   cis.attribute2           = cv_no
                AND   ROWNUM                   = 1
            )
    UNION ALL
    SELECT  /*+ LEADING(xiih) USE_NL(cii cis) */
            cii.instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
           ,csi_instance_statuses  cis
    WHERE   gv_prm_process_div                = cv_prm_div
      AND   gv_prm_process_date               IS NOT NULL
      AND   TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
      AND   cii.external_reference            = xiih.install_code
      AND   cis.instance_status_id            = cii.instance_status_id
      AND   cis.attribute2                    = cv_no
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
  ;
/* 2009.07.17 H.Ogawa 0000781対応 END */
  -- ===============================
  -- ユーザー定義グローバルレコード定義
  -- ===============================
  -- INV 工場返品倉替先コード取得用配列定義
  TYPE g_mfg_fctory_cd_rtype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE
   INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
  -- INV 工場返品倉替先コード取得用レコード変数
  g_mfg_fctory_cd_rec  mfg_fctory_cd_cur%ROWTYPE;
  -- INV 工場返品倉替先コード取得用配列変数
  g_mfg_fctory_cd      g_mfg_fctory_cd_rtype;
  -- 物件関連情報取得用レコード変数
  g_get_xxcso_ib_info_h_rec get_xxcso_ib_info_h_cur%ROWTYPE;
/* 2009.07.17 H.Ogawa 0000781対応 START */
  g_get_target_rec          get_target_cur%ROWTYPE;
/* 2009.07.17 H.Ogawa 0000781対応 END */
  -- ===============================
  -- ユーザー定義グローバル例外
  -- ===============================
  g_sql_err_expt         EXCEPTION;  -- SQLエラー例外
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
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
    cv_prof_itoen_cust_name CONSTANT VARCHAR2(100)  := 'XXCSO1_ITOEN_CUST_NAME';   -- プロファイル・オプション：伊藤園顧客名
    cv_prof_org_id          CONSTANT VARCHAR2(100)  := 'ORG_ID';   -- プロファイル・オプション：営業単位
    cv_xxcoi_mfg_fctory_cd  CONSTANT VARCHAR2(100)  := 'XXCOI_MFG_FCTORY_CD';   -- 工場返品倉替先CD
    -- *** ローカル変数 ***
    lb_ret_status    BOOLEAN;  -- 日付書式チェック関数RETURN値格納用
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
    prm_check_expt       EXCEPTION;  -- パラメータチェック例外
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
    gn_mfg_fctory_cd_cnt := 0;
--
    -- *** DEBUG_LOG ***
    -- 取得したWHOカラムをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'WHOカラム'               || CHR(10) ||
                 'created_by:'             || TO_CHAR(cn_created_by            ) || CHR(10) ||
                 'creation_date:'          || TO_CHAR(cd_creation_date         ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 'last_updated_by:'        || TO_CHAR(cn_last_updated_by       ) || CHR(10) ||
                 'last_update_date:'       || TO_CHAR(cd_last_update_date      ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 'last_update_login:'      || TO_CHAR(cn_last_update_login     ) || CHR(10) ||
                 'request_id:'             || TO_CHAR(cn_request_id            ) || CHR(10) ||
                 'program_application_id:' || TO_CHAR(cn_program_application_id) || CHR(10) ||
                 'program_id:'             || TO_CHAR(cn_program_id            ) || CHR(10) ||
                 'program_update_date:'    || TO_CHAR(cd_program_update_date   ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- ===========================
    -- システム日付取得処理
    -- ===========================
    gd_sys_date := SYSDATE;
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_1  || CHR(10) ||
                 cv_debug_msg1_2  || TO_CHAR(gd_sys_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    --
    -- ===========================
    -- パラメータチェック
    -- ===========================
    -- INパラメータの出力処理
    IF (
            (gv_prm_process_div IS NOT NULL)
        AND (gv_prm_process_date IS NOT NULL)
       )
    THEN
      -- パラメータ処理区分、パラメータ処理実行日がNULLではない場合
      --
      -- INパラメータ：処理区分出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_tkn_number_01
                      ,iv_token_name1  => cv_tkn_entry
                      ,iv_token_value1 => gv_prm_process_div
                     );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      -- INパラメータ：処理実行日出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_tkn_number_02
                      ,iv_token_name1  => cv_tkn_value
                      ,iv_token_value1 => gv_prm_process_date
                     );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      -- INパラメータ：処理区分の妥当性チェック
      IF (gv_prm_process_div NOT IN (cv_prm_normal, cv_prm_div)) THEN
        -- パラメータ処理区分が'1','2'ではない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_04             --メッセージコード
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => gv_prm_process_div
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE prm_check_expt;
      END IF;
      --
      -- INパラメータ：処理実行日の書式チェック
      lb_ret_status := xxcso_util_common_pkg.check_date
                        (
                          iv_date         => gv_prm_process_date
                         ,iv_date_format  => cv_prm_date_format
                        );
      IF (lb_ret_status = cb_false) THEN
        -- リターンステータスがFALSEである場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05             --メッセージコード
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_tkn_msg_pro_date
                      ,iv_token_name2  => cv_tkn_base_value
                      ,iv_token_value2 => gv_prm_process_date
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE prm_check_expt;
      END IF;
    ELSE
      -- INパラメータ：処理区分のNULLチェック
      IF (gv_prm_process_div IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_03             --メッセージコード
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_tkn_msg_pro_div
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE prm_check_expt;
      END IF;
    END IF;
    --
    -- ===========================
    -- 業務処理日付取得
    -- ===========================
    --
    gd_business_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_3  || CHR(10) ||
                 cv_debug_msg1_4  || TO_CHAR(gd_business_date,'yyyy/mm/dd hh24:mi:ss') ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gd_business_date = NULL) THEN
      -- 業務処理日付取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_07             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    --
    -- ===========================
    -- 処理日特定
    -- ===========================
    --
    IF (gv_prm_process_date IS NOT NULL) THEN
      -- パラメータ処理実行日が入力されている場合
      --
      -- 処理日にパラメータ処理実行日を設定する
      gd_process_date := TO_DATE(gv_prm_process_date, 'YYYYMMDD HH24:MI:SS');
    ELSE
      --
      -- 処理日にパラメータ処理実行日を設定する
      gd_process_date := gd_business_date;
    END IF;
    -- *** DEBUG_LOG ***
    -- 取得した処理日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_5  || CHR(10) ||
                 cv_debug_msg1_6  || TO_CHAR(gd_process_date,'yyyy/mm/dd hh24:mi:ss') ||
                  CHR(10) ||
                 ''
    );
    --
    -- ===========================
    -- プロファイル・オプション値取得
    -- ===========================
    --
    -- 伊藤園顧客名取得
    gv_itoen_cust_name := FND_PROFILE.VALUE(cv_prof_itoen_cust_name);
    --
    -- *** DEBUG_LOG ***
    -- 取得した処理日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_7  || CHR(10) ||
                 cv_debug_msg1_8  || gv_itoen_cust_name ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gv_itoen_cust_name = NULL) THEN
      -- 伊藤園顧客名取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_08             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_tkn_msg_itoen_acc_nm
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    /* 2009.04.28 T.Mori T1_0758対応 START */
    gv_customer_code_dammy := FND_PROFILE.VALUE(cv_prf_cust_cd_dammy);
    IF (gv_customer_code_dammy = NULL) THEN
      -- AFF顧客コード取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_08             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_tkn_msg_cust_cd_dammy
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    /* 2009.04.28 T.Mori T1_0758対応 END */
    --
    -- 営業単位取得
    gn_org_id := FND_PROFILE.VALUE(cv_prof_org_id);
    --
    -- *** DEBUG_LOG ***
    -- 取得した処理日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_9  || CHR(10) ||
                 cv_debug_msg1_10 || TO_CHAR(gn_org_id) ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gn_org_id = NULL) THEN
      -- 営業単位取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_08             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_tkn_msg_org_id
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    --
/* 2009.07.17 H.Ogawa 0000781対応 START */
    -- IB属性レベル取得
    gv_attribute_level := FND_PROFILE.VALUE(cv_attribute_level);
    --
    -- *** DEBUG_LOG ***
    -- 取得した処理日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_16 || CHR(10) ||
                 cv_debug_msg1_17 || gv_attribute_level ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gv_attribute_level = NULL) THEN
      --IB属性レベル取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_08             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_attribute_level
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
/* 2009.07.17 H.Ogawa 0000781対応 END */
    -- ===========================
    -- インスタンスステータスID取得
    -- ===========================
    --
    BEGIN
      --
      SELECT cis.instance_status_id instance_status_id
      INTO   gn_instance_status_id
      FROM   csi_instance_statuses cis
      WHERE  cis.NAME IN
        (
          SELECT flvv.description
          FROM   fnd_lookup_values_vl flvv
          WHERE  TRUNC(gd_process_date) BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
          AND    TRUNC(NVL(flvv.end_date_active, gd_process_date))
          AND    flvv.enabled_flag = cv_yes
          AND    flvv.lookup_code  = cv_delete_code
          AND    flvv.lookup_type  = cv_xxcso1_instance_status
        )
      AND TRUNC(gd_process_date) BETWEEN TRUNC(NVL(cis.start_date_active, gd_process_date))
      AND TRUNC(NVL(cis.end_date_active, gd_process_date))
      ;
    -- *** DEBUG_LOG ***
    -- 取得したインスタンスステータスIDをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_11 || CHR(10) ||
                 cv_debug_msg1_12 || TO_CHAR(gn_instance_status_id) ||
                  CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 検索結果がない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_09             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_status_id
                      ,iv_token_name2  => cv_tkn_status_name
                      ,iv_token_value2 => cv_tkn_msg_object_del
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_10             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_status_id
                      ,iv_token_name2  => cv_tkn_status_name
                      ,iv_token_value2 => cv_tkn_msg_object_del
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_sql_err_expt;
    END;
    --
    -- ===========================
    -- INV 工場返品倉替先コード取得
    -- ===========================
    --
    BEGIN
      --
      -- カーソルオープン
      OPEN mfg_fctory_cd_cur;
      -- *** DEBUG_LOG ***
      -- カーソルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || CHR(10)   ||
                   cv_debug_msg1_15    || CHR(10)   ||
                   ''
      );
      <<loop_get_mfg_fctory_cd>>
      LOOP
        FETCH mfg_fctory_cd_cur INTO g_mfg_fctory_cd_rec;
        IF (mfg_fctory_cd_cur%ROWCOUNT = 0) THEN
          -- 検索結果がない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_11             --メッセージコード
                        ,iv_token_name1  => cv_tkn_task_name
                        ,iv_token_value1 => cv_tkn_msg_lookup_type
                        ,iv_token_name2  => cv_tkn_lookup_type_name
                        ,iv_token_value2 => cv_tkn_msg_inv_henpin
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE g_sql_err_expt;
        END IF;
        EXIT WHEN mfg_fctory_cd_cur%NOTFOUND;
        gn_mfg_fctory_cd_cnt := gn_mfg_fctory_cd_cnt + 1;
        g_mfg_fctory_cd(gn_mfg_fctory_cd_cnt) := g_mfg_fctory_cd_rec.lookup_code;
        -- *** DEBUG_LOG ***
        -- 取得したINV 工場返品倉替先コードをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg1_13 || CHR(10) ||
                     cv_debug_msg1_14 || TO_CHAR(g_mfg_fctory_cd_rec.lookup_code) ||
                      CHR(10) ||
                     ''
        );
      END LOOP loop_get_mfg_fctory_cd;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_12             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_lookup_type
                      ,iv_token_name2  => cv_tkn_lookup_type_name
                      ,iv_token_value2 => cv_tkn_msg_inv_henpin
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_sql_err_expt;
    END;
    --
    -- カーソルクローズ
    CLOSE mfg_fctory_cd_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1   || CHR(10)   ||
                 cv_debug_msg1_15    || CHR(10)   ||
                 ''
    );
--
  EXCEPTION
--
    -- パラメータチェック例外
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_1  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_2  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_1  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_2 || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_3  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_po_number
   * Description      : 発注番号抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_po_number(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_po_number';     -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
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
    -- 発注番号抽出
    -- ========================================
    BEGIN
    --
      /* 2009.05.20 K.Satomura T1_1095対応 START */
      --SELECT xiwd.po_number
      SELECT MAX(xiwd.po_number)
      /* 2009.05.20 K.Satomura T1_1095対応 END */
      INTO   gn_po_number
      FROM   xxcso_in_work_data xiwd
      WHERE  xiwd.install_code1           = g_get_xxcso_ib_info_h_rec.object_code -- 物件コード
      AND    xiwd.job_kbn                 IN (cv_job_kbn_set, cv_job_kbn_change)  -- 作業区分
      AND    xiwd.completion_kbn          = cv_comp_kbn_ok                        -- 完了区分
      AND    xiwd.install1_processed_flag = cv_yes                                -- 物件1処理済フラグ
      /* 2009.04.08 K.Satomura T1_0372対応 START */
      /* 2009.05.20 K.Satomura T1_1095対応 START */
      --GROUP BY xiwd.po_number
      /* 2009.05.20 K.Satomura T1_1095対応 END */
      /* 2009.04.08 K.Satomura T1_0372対応 END */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 検索結果が0件である場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_20             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_po_num
                      ,iv_token_name2  => cv_tkn_bukken
                      ,iv_token_value2 => g_get_xxcso_ib_info_h_rec.object_code
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_21             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_po_num
                      ,iv_token_name2  => cv_tkn_bukken
                      ,iv_token_value2 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
    END;
--
    /* 2009.07.02 K.Satomura 統合テスト障害対応(0000334) START */
    /* 2009.05.20 K.Satomura T1_1095対応 START */
    --IF (gn_po_number IS NULL) THEN
    --  -- 検索結果が0件である場合
    --  lv_errmsg := xxccp_common_pkg.get_msg(
    --                 iv_application  => cv_app_name      --アプリケーション短縮名
    --                ,iv_name         => cv_tkn_number_20 --メッセージコード
    --                ,iv_token_name1  => cv_tkn_task_name
    --                ,iv_token_value1 => cv_tkn_msg_po_num
    --                ,iv_token_name2  => cv_tkn_bukken
    --                ,iv_token_value2 => g_get_xxcso_ib_info_h_rec.object_code
    --               );
    --  --
    --  lv_errbuf := lv_errmsg || SQLERRM;
    --  ov_retcode := cv_status_warn;
    --  RAISE g_sql_err_expt;
    --  --
    --END IF;
    /* 2009.05.20 K.Satomura T1_1095対応 END */
    /* 2009.07.02 K.Satomura 統合テスト障害対応(0000334) END */
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_po_number;
--
  /**********************************************************************************
   * Procedure Name   : get_type_info
   * Description      : 機種情報抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_type_info(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_type_info';     -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
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
    -- 機種情報抽出
    -- ========================================
    BEGIN
    --
      SELECT xxcso_util_common_pkg.get_lookup_meaning(
                cv_xxcso_csi_maker_code
               ,punv.attribute2
               ,gd_process_date
              ) manufacturer_name     -- 新_メーカー名
            ,punv.attribute3 age_type -- 新_年式
      INTO   gv_manufacturer_name
            ,gv_age_type
      FROM   po_un_numbers_vl punv -- 国連番号マスタビュー
      WHERE  punv.un_number = g_get_xxcso_ib_info_h_rec.new_model -- 国連番号
      /* 2009.08.19 K.Satomura 0001051対応 START */
      --AND    TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date) -- 作業区分
      /* 2009.08.19 K.Satomura 0001051対応 START */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 検索結果が0件である場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_13             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_model
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => cv_tkn_msg_model_cd
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.new_model
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_14             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_model
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => cv_tkn_msg_model_cd
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.new_model
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_type_info;
--
  /**********************************************************************************
   * Procedure Name   : get_acct_info
   * Description      : 顧客関連情報抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_acct_info(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_acct_info';     -- プログラム名
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
    -- *** ローカル変数 ***
    lv_owner_company_flg        VARCHAR2(1);  -- 本社／工場フラグ
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
  /* 2009.04.28 T.Mori T1_0758対応 START */
    lv_customer_class_code      xxcso_cust_acct_sites_v.customer_class_code%TYPE;   -- 新_顧客区分コード
  /* 2009.04.28 T.Mori T1_0758対応 END */
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
    /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) START */
    ---- ========================================
    ---- 顧客関連情報抽出
    ---- ========================================
    --BEGIN
    ----
    --  SELECT xcasv.sale_base_code        new_department_code      -- 新_拠点コード
    --        ,xcasv.established_site_name new_installation_place   -- 新_設置先名
    --        ,xcasv.state    ||
    --         xcasv.city     ||
    --         xcasv.ADDRESS1 ||
    --         xcasv.ADDRESS2              new_installation_address -- 新_設置先住所
    --        ,xcasv.account_number        new_customer_code        -- 新_顧客コード
    --       /* 2009.04.28 T.Mori T1_0758対応 START */
    --        ,xcasv.customer_class_code   new_customer_class_code  -- 新_顧客区分コード
    --       /* 2009.04.28 T.Mori T1_0758対応 END */
    --  INTO   gv_department_code      -- 新_拠点コード
    --        ,gv_installation_place   -- 新_設置先名
    --        ,gv_installation_address -- 新_設置先住所
    --        ,gv_customer_code        -- 新_顧客コード
    --        /* 2009.04.28 T.Mori T1_0758対応 START */
    --        ,lv_customer_class_code  -- 新_顧客区分コード
    --        /* 2009.04.28 T.Mori T1_0758対応 END */
    --  FROM   xxcso_cust_acct_sites_v xcasv  -- 顧客マスタサイトビュー
    --  WHERE  xcasv.cust_account_id   = g_get_xxcso_ib_info_h_rec.owner_party_account_id -- アカウントID
    --  AND    xcasv.account_status    = cv_cut_enb_status                                -- アカウントステータス
    --  AND    xcasv.acct_site_status  = cv_cut_enb_status                                -- 顧客所在地ステータス
    --  AND    xcasv.party_status      = cv_cut_enb_status                                -- パーティステータス
    --  AND    xcasv.party_site_status = cv_cut_enb_status                                -- パーティサイトステータス
    --  ;
    --EXCEPTION
    --  WHEN NO_DATA_FOUND THEN
    --    -- 検索結果が0件である場合
    --    lv_errmsg := xxccp_common_pkg.get_msg(
    --                   iv_application  => cv_app_name                  --アプリケーション短縮名
    --                  ,iv_name         => cv_tkn_number_13             --メッセージコード
    --                  ,iv_token_name1  => cv_tkn_task_name
    --                  ,iv_token_value1 => cv_tkn_msg_acct_info
    --                  ,iv_token_name2  => cv_tkn_item
    --                  ,iv_token_value2 => cv_tkn_msg_account_id
    --                  ,iv_token_name3  => cv_tkn_base_value
    --                  ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.owner_party_account_id
    --                 );
    --    lv_errbuf := lv_errmsg || SQLERRM;
    --    ov_retcode := cv_status_warn;
    --    RAISE g_sql_err_expt;
    --  WHEN OTHERS THEN
    --    -- SQLエラーが発生した場合
    --    lv_errmsg := xxccp_common_pkg.get_msg(
    --                   iv_application  => cv_app_name                  --アプリケーション短縮名
    --                  ,iv_name         => cv_tkn_number_14             --メッセージコード
    --                  ,iv_token_name1  => cv_tkn_task_name
    --                  ,iv_token_value1 => cv_tkn_msg_acct_info
    --                  ,iv_token_name2  => cv_tkn_item
    --                  ,iv_token_value2 => cv_tkn_msg_account_id
    --                  ,iv_token_name3  => cv_tkn_base_value
    --                  ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.owner_party_account_id
    --                  ,iv_token_name4  => cv_tkn_err_msg
    --                  ,iv_token_value4 => SQLERRM
    --                 );
    --    lv_errbuf := lv_errmsg || SQLERRM;
    --    ov_retcode := cv_status_error;
    --    RAISE g_sql_err_expt;
    --END;
    lv_customer_class_code := g_get_xxcso_ib_info_h_rec.new_customer_class_code;
    /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) END */
    /* 2009.04.28 T.Mori T1_0758対応 START */
    IF (lv_customer_class_code <> cv_cust_class_10) THEN
      gv_customer_code := gv_customer_code_dammy;
    END IF;
    /* 2009.04.28 T.Mori T1_0758対応 END */
--
    -- ========================================
    -- 本社／工場区分の抽出
    -- ========================================
    --
    -- 工場返品倉替先コード存在チェック
    --
    -- 新_本社／工場区分にデフォルト値（「'1'：本社」）を設定
    lv_owner_company_flg := cv_owner_company_honsya;
    --
    <<loop_mfg_fctory_cd_chk>>
    FOR i IN 1..gn_mfg_fctory_cd_cnt LOOP
    --
      IF (gv_department_code = g_mfg_fctory_cd(i)) THEN
      -- 抽出した新_拠点コードがA-1で取得した工場返品倉替先コードと一致する場合
      -- 新_本社／工場区分に「'2'：工場」を設定
        lv_owner_company_flg := cv_owner_company_fact;
      END IF;
    END LOOP loop_mfg_fctory_cd_chk;
    --
    BEGIN
    --
      SELECT ffvv.flex_value new_owner_company -- 新_本社／工場区分
      INTO   gv_owner_company -- 新_本社／工場区分
      FROM   fnd_flex_values_vl ffvv  -- 値セット値ビュー
            ,fnd_flex_value_sets ffvs -- 値セット
      WHERE  ffvv.flex_value_set_id   = ffvs.flex_value_set_id  -- 値セットID
      AND    ffvs.flex_value_set_name = cv_xxcff_owner_company  -- 値セット名
      AND    ffvv.enabled_flag        = cv_yes  -- 使用可能フラグ
      AND    TRUNC(gd_process_date) BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
      AND    TRUNC(NVL(ffvv.end_date_active, gd_process_date)) -- 有効期間
      AND    ffvv.flex_value_meaning =
        (
          SELECT flvv.meaning meaning  -- 内容（本社／工場）
          FROM   fnd_lookup_values_vl flvv  -- クイックコード
          WHERE  flvv.lookup_type = cv_xxcso1_owner_company  -- タイプ
          AND    TRUNC(gd_process_date) BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
          AND    TRUNC(NVL(flvv.end_date_active, gd_process_date)) -- 有効期間
          AND    flvv.lookup_code = lv_owner_company_flg  -- 本社／工場フラグ
          AND    flvv.enabled_flag = cv_yes  -- 使用可能フラグ
        )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 検索結果が0件である場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_15             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_value_set
                      ,iv_token_name2  => cv_tkn_value_set_name
                      ,iv_token_value2 => cv_tkn_msg_owner_comp
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_16             --メッセージコード
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_value_set
                      ,iv_token_name2  => cv_tkn_value_set_name
                      ,iv_token_value2 => cv_tkn_msg_owner_comp
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_acct_info;
--
  /**********************************************************************************
   * Procedure Name   : ib_info_change_chk
   * Description      : 物件関連情報変更チェック処理(A-6)
   ***********************************************************************************/
  PROCEDURE ib_info_change_chk(
     ov_change_flg       OUT        VARCHAR2   -- 変更チェックフラグ（変更あり：Y／変更なし：N）
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'ib_info_change_chk';     -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
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
    -- 物件関連情報変更チェック処理
    -- ========================================
    --
    -- 変更チェックフラグにデフォルト値（Y）を設定
    ov_change_flg := cv_yes;
    --
    IF (
        /* 2009.04.08 K.Satomura T1_0403対応 START*/
        --    (
        --       g_get_xxcso_ib_info_h_rec.old_po_number
        --     = gn_po_number                                                       -- 発注番号
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_manufacturer_name
        --     = gv_manufacturer_name                                               -- メーカー名
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_age_type
        --     = gv_age_type                                                        -- 年式
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_model
        --     = g_get_xxcso_ib_info_h_rec.new_model                                -- 機種
        --    )
        --AND (
        --       NVL(g_get_xxcso_ib_info_h_rec.old_serial_number       , cv_null)
        --     = NVL(g_get_xxcso_ib_info_h_rec.new_serial_number       , cv_null)   -- 機番
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_quantity
        --     = g_get_xxcso_ib_info_h_rec.new_quantity                             -- 数量
        --    )
        --AND (
        --       NVL(g_get_xxcso_ib_info_h_rec.old_department_code     , cv_null)
        --     = NVL(gv_department_code                                , cv_null)   -- 拠点コード
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_owner_company
        --     = gv_owner_company                                                   -- 本社／工場区分
        --    )
        --AND (
        --       NVL(g_get_xxcso_ib_info_h_rec.old_installation_place  , cv_null)
        --     = NVL(gv_installation_place                             , cv_null)   -- 設置先名
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_installation_address
        --     = gv_installation_address                                            -- 設置先住所
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_active_flag
        --     = g_get_xxcso_ib_info_h_rec.new_active_flag                          -- 論理削除フラグ
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_customer_code
        --     = gv_customer_code                                                   -- 顧客コード
        --    )
            (
               NVL(g_get_xxcso_ib_info_h_rec.old_po_number, cn_zero)
             = NVL(gn_po_number, cn_zero) -- 発注番号
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_manufacturer_name, cv_null)
             = NVL(gv_manufacturer_name, cv_null) -- メーカー名
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_age_type, cv_null)
             = NVL(gv_age_type, cv_null) -- 年式
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_model, cv_null)
             = NVL(g_get_xxcso_ib_info_h_rec.new_model , cv_null) -- 機種
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_serial_number , cv_null)
             = NVL(g_get_xxcso_ib_info_h_rec.new_serial_number , cv_null) -- 機番
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_quantity, cn_zero)
             = NVL(g_get_xxcso_ib_info_h_rec.new_quantity, cn_zero) -- 数量
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_department_code, cv_null)
             = NVL(gv_department_code, cv_null) -- 拠点コード
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_owner_company, cv_null)
             = NVL(gv_owner_company, cv_null)-- 本社／工場区分
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_installation_place, cv_null)
             = NVL(gv_installation_place, cv_null) -- 設置先名
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_installation_address, cv_null)
             = NVL(gv_installation_address, cv_null)-- 設置先住所
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_active_flag, cv_null)
             = NVL(g_get_xxcso_ib_info_h_rec.new_active_flag, cv_null) -- 論理削除フラグ
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_customer_code, cv_null)
             = NVL(gv_customer_code, cv_null)-- 顧客コード
            )
        /* 2009.04.08 K.Satomura T1_0403対応 END*/
       ) THEN
      -- 変更項目が存在しない場合変更チェックフラグにNを設定
      ov_change_flg := cv_no;
    END IF;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ib_info_change_chk;
--
  /**********************************************************************************
   * Procedure Name   : xxcff_vd_object_if_chk
   * Description      : 自販機SH物件インタフェース存在チェック(A-7)
   ***********************************************************************************/
  PROCEDURE xxcff_vd_object_if_chk(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'xxcff_vd_object_if_chk';     -- プログラム名
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
    -- *** ローカル変数 ***
    ln_data_cnt           NUMBER;  -- 件数カウント
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
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
    -- 自販機SH物件インタフェース存在判定
    -- ========================================
    BEGIN
    --
      SELECT COUNT(xvoi.object_code)
      INTO   ln_data_cnt
      FROM   xxcff_vd_object_if xvoi -- 自販機SH物件インタフェース
      WHERE  xvoi.object_code = g_get_xxcso_ib_info_h_rec.object_code -- 物件コード
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_17             --メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_vd_object_if
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_select
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
    END;
    --
    IF (ln_data_cnt > 0) THEN
      -- 取得件数が0以上である場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_18             --メッセージコード
                    ,iv_token_name1  => cv_tkn_bukken
                    ,iv_token_value1 => g_get_xxcso_ib_info_h_rec.object_code
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      ov_retcode := cv_status_warn;
      RAISE g_sql_err_expt;
    END IF;
--
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END xxcff_vd_object_if_chk;
--
  /**********************************************************************************
   * Procedure Name   : xxcso_ib_info_h_lock
   * Description      : 物件関連変更履歴テーブルロック(A-8)
   ***********************************************************************************/
  PROCEDURE xxcso_ib_info_h_lock(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'xxcso_ib_info_h_lock';     -- プログラム名
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
    -- *** ローカル変数 ***
    lv_install_code       xxcso_ib_info_h.install_code%TYPE;  -- 物件コード
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
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
      SELECT xiih.install_code -- 物件コード
      INTO   lv_install_code
      FROM   xxcso_ib_info_h xiih -- 物件関連情報変更履歴テーブル
      WHERE  xiih.install_code = g_get_xxcso_ib_info_h_rec.object_code -- 物件コード
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 検索結果が0件である場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_17             --メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_ib_info_h
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_select
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_17             --メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_ib_info_h
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_lock
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END xxcso_ib_info_h_lock;
--
  /**********************************************************************************
   * Procedure Name   : insert_xxcff_vd_object_if
   * Description      : 自販機SH物件インタフェース登録処理(A-10)
   ***********************************************************************************/
  PROCEDURE insert_xxcff_vd_object_if(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_xxcff_vd_object_if';     -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
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
    -- 自販機SH物件インタフェース登録処理
    -- ========================================
    BEGIN
    --
      INSERT INTO xxcff_vd_object_if(
         object_code                                 -- 物件コード
        ,generation_date                             -- 発生日
        ,lease_class                                 -- リース種別
        ,po_number                                   -- 発注番号
        ,manufacturer_name                           -- メーカー名
        ,age_type                                    -- 年式
        ,model                                       -- 機種
        ,serial_number                               -- 機番
        ,quantity                                    -- 数量
        ,department_code                             -- 管理部門コード
        ,owner_company                               -- 本社工場区分
        ,installation_place                          -- 現設置先
        ,installation_address                        -- 現設置場所
        ,active_flag                                 -- 物件有効フラグ
        ,import_status                               -- 取込ステータス
        ,customer_code                               -- 顧客コード
        ,group_id                                    -- グループID
        ,created_by                                  -- 作成者
        ,creation_date                               -- 作成日
        ,last_updated_by                             -- 最終更新者
        ,last_update_date                            -- 最終更新日
        ,last_update_login                           -- 最終更新ログイン
        ,request_id                                  -- 要求ID
        ,program_application_id                      -- コンカレント・プログラム・アプリケーションID
        ,program_id                                  -- コンカレント・プログラムID
        ,program_update_date                         -- プログラム更新日
      ) VALUES(
         g_get_xxcso_ib_info_h_rec.object_code       -- 物件コード
        ,gd_process_date                             -- 発生日
        ,g_get_xxcso_ib_info_h_rec.lease_class       -- リース種別
        ,gn_po_number                                -- 発注番号
        ,gv_manufacturer_name                        -- メーカー名
        ,gv_age_type                                 -- 年式
        ,g_get_xxcso_ib_info_h_rec.new_model         -- 機種
        ,g_get_xxcso_ib_info_h_rec.new_serial_number -- 機番
        ,g_get_xxcso_ib_info_h_rec.new_quantity      -- 数量
        ,gv_department_code                          -- 管理部門コード
        ,gv_owner_company                            -- 本社工場区分
        /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
        --,gv_installation_place                       -- 現設置先
        ,SUBSTRB(gv_installation_place, 1, 50)       -- 現設置先
        /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
        ,gv_installation_address                     -- 現設置場所
        /* 2009.04.01 K.Satomura T1_0149対応 START */
        --,g_get_xxcso_ib_info_h_rec.new_active_flag   -- 物件有効フラグ
        ,g_get_xxcso_ib_info_h_rec.effective_flag    -- 物件有効フラグ
        /* 2009.04.01 K.Satomura T1_0149対応 END */
        ,cv_import_status                            -- 取込ステータス（固定値：'0'）
        ,gv_customer_code                            -- 顧客コード
        ,NULL                                        -- グループID
        ,cn_created_by                               -- 作成者
        ,cd_creation_date                            -- 作成日
        ,cn_last_updated_by                          -- 最終更新者
        ,cd_last_update_date                         -- 最終更新日
        ,cn_last_update_login                        -- 最終更新ログイン
        ,cn_request_id                               -- 要求ID
        ,cn_program_application_id                   -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                               -- コンカレント・プログラムID
        ,cd_program_update_date                      -- プログラム更新日
      )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_17             --メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_vd_object_if
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_insert
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_xxcff_vd_object_if;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcso_ib_info_h
   * Description      : 物件関連情報変更履歴テーブル更新処理(A-11)
   ***********************************************************************************/
  PROCEDURE update_xxcso_ib_info_h(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'update_xxcso_ib_info_h';     -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
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
      UPDATE xxcso_ib_info_h
      SET    history_creation_date   = gd_process_date                             -- 履歴作成日
            ,interface_flag          = cv_yes                                      -- 連携済フラグ
            ,po_number               = gn_po_number                                -- 発注番号
            ,manufacturer_name       = gv_manufacturer_name                        -- メーカー名
            ,age_type                = gv_age_type                                 -- 年式
            ,un_number               = g_get_xxcso_ib_info_h_rec.new_model         -- 機種
            ,install_number          = g_get_xxcso_ib_info_h_rec.new_serial_number -- 機番
            ,quantity                = g_get_xxcso_ib_info_h_rec.new_quantity      -- 数量
            ,base_code               = gv_department_code                          -- 拠点コード
            ,owner_company_type      = gv_owner_company                            -- 本社／工場区分
            ,install_name            = gv_installation_place                       -- 設置先名
            ,install_address         = gv_installation_address                     -- 設置先住所
            ,logical_delete_flag     = g_get_xxcso_ib_info_h_rec.new_active_flag   -- 論理削除フラグ
            ,account_number          = gv_customer_code                            -- 顧客コード
            /* 2009.04.03 K.Satomura T1_0269対応 START */
            ,last_updated_by         = cn_last_updated_by                          -- 最終更新者
            ,last_update_date        = cd_last_update_date                         -- 最終更新日
            ,last_update_login       = cn_last_update_login                        -- 最終更新ログイン
            ,request_id              = cn_request_id                               -- 要求ID
            ,program_application_id  = cn_program_application_id                   -- コンカレント・プログラム・アプリケーションID
            ,program_id              = cn_program_id                               -- コンカレント・プログラムID
            ,program_update_date     = cd_program_update_date                      -- プログラム更新日
            /* 2009.04.03 K.Satomura T1_0269対応 END */
      WHERE  install_code = g_get_xxcso_ib_info_h_rec.object_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQLエラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_17             --メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_ib_info_h
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_update
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    -- *** ローカル変数 ***
    lv_change_flg            VARCHAR2(1);  -- 変更チェックフラグ
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;  -- 対象件数
    gn_normal_cnt := 0;  -- 正常件数
    gn_error_cnt  := 0;  -- エラー件数
    gn_warn_cnt   := 0;  -- スキップ件数
--
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
/* 2009.07.17 H.Ogawa 0000781対応 START */
    -- ========================================
    -- A-2-0.抽出対象物件取得
    -- ========================================
    OPEN get_target_cur;
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || CHR(10)   ||
                 cv_debug_msgsub_0   || CHR(10)   ||
                 ''
    );
    --
    <<loop_get_target>>
    LOOP
      BEGIN
        FETCH get_target_cur INTO g_get_target_rec;
      EXCEPTION
        WHEN OTHERS THEN
          -- SQLエラーが発生した場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_19             --メッセージコード
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_tkn_msg_target
                        ,iv_token_name2  => cv_tkn_err_msg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE g_sql_err_expt;
      END;
      EXIT WHEN get_target_cur%NOTFOUND
              OR get_target_cur%ROWCOUNT = 0;
--
      -- 対象件数の取得
      gn_target_cnt := get_target_cur%ROWCOUNT;
/* 2009.07.17 H.Ogawa 0000781対応 END */
      -- ========================================
      -- A-2-1.物件関連情報抽出
      -- ========================================
/* 2009.07.17 H.Ogawa 0000781対応 START */
--    OPEN get_xxcso_ib_info_h_cur;
      OPEN get_xxcso_ib_info_h_cur(g_get_target_rec.instance_id);
/* 2009.07.17 H.Ogawa 0000781対応 END */
      -- *** DEBUG_LOG ***
      -- カーソルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || CHR(10)   ||
                   cv_debug_msgsub_1   || CHR(10)   ||
                   ''
      );
      --
      <<loop_get_xxcso_ib_info>>
      LOOP
        /* 2009.04.07 K.Satomura T1_0378対応 START */
        lv_change_flg := NULL;
        lv_retcode    := cv_status_normal;
        /* 2009.04.07 K.Satomura T1_0378対応 END */
        BEGIN
          FETCH get_xxcso_ib_info_h_cur INTO g_get_xxcso_ib_info_h_rec;
        EXCEPTION
          WHEN OTHERS THEN
            -- SQLエラーが発生した場合
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                  --アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_19             --メッセージコード
                          ,iv_token_name1  => cv_tkn_table
                          ,iv_token_value1 => cv_tkn_msg_ib_info
                          ,iv_token_name2  => cv_tkn_err_msg
                          ,iv_token_value2 => SQLERRM
                         );
            lv_errbuf := lv_errmsg || SQLERRM;
            RAISE g_sql_err_expt;
        END;
        EXIT WHEN get_xxcso_ib_info_h_cur%NOTFOUND
                OR get_xxcso_ib_info_h_cur%ROWCOUNT = 0;
        --
/* 2009.07.17 H.Ogawa 0000781対応 START */
        -- 対象件数の取得
        --gn_target_cnt := get_xxcso_ib_info_h_cur%ROWCOUNT;
/* 2009.07.17 H.Ogawa 0000781対応 START */
--
        /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) START */
        -- 顧客関連情報を退避
        gv_department_code      := g_get_xxcso_ib_info_h_rec.new_department_code;
        gv_installation_place   := g_get_xxcso_ib_info_h_rec.new_installation_place;
        gv_installation_address := g_get_xxcso_ib_info_h_rec.new_installation_address;
        gv_customer_code        := g_get_xxcso_ib_info_h_rec.new_customer_code;
        /* 2009.07.02 K.Satomura 統合テスト障害対応(0000229) END */
        -- ========================================
        -- A-3.発注番号抽出
        -- ========================================
        /* 2009.04.07 D.Abe T1_0339対応 START */
        gn_po_number := NULL;
        IF (g_get_xxcso_ib_info_h_rec.newold_flag = cv_no
          OR g_get_xxcso_ib_info_h_rec.newold_flag IS NULL)
        THEN
        /* 2009.04.07 D.Abe T1_0339対応 END */
          get_po_number(
             ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
            ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
            ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
          );
        /* 2009.04.07 D.Abe T1_0339対応 START */
        ELSE
          lv_retcode := cv_status_normal;
        END IF;
        /* 2009.04.07 D.Abe T1_0339対応 END */
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          -- スキップ件数
          gn_warn_cnt   := gn_warn_cnt + 1;
          -- 固定ステータス設定（警告）
          ov_retcode := cv_status_warn;
          --警告出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  --ユーザー・警告メッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg                  --警告メッセージ
          );
        ELSE
--
          -- ========================================
          -- A-4.機種情報抽出
          -- ========================================
          get_type_info(
             ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
            ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
            ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            -- スキップ件数
            gn_warn_cnt   := gn_warn_cnt + 1;
            -- 固定ステータス設定（警告）
            ov_retcode := cv_status_warn;
            --警告出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  --ユーザー・警告メッセージ
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errmsg                  --警告メッセージ
            );
          ELSE
--
            -- ========================================
            -- A-5.顧客関連情報抽出
            -- ========================================
            get_acct_info(
               ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
              ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
              ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
            );
--
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              -- スキップ件数
              gn_warn_cnt   := gn_warn_cnt + 1;
              -- 固定ステータス設定（警告）
              ov_retcode := cv_status_warn;
              --警告出力
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg                  --ユーザー・警告メッセージ
              );
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg                  --警告メッセージ
              );
            ELSE
--
              /* 2009.05.26 D.Abe T1_1042対応 START */
              /* 2009.05.28 D.Abe T1_1042(再２)対応 START */
              -- 処理区分が1で処理日付が入力済み
              IF (gv_prm_process_div = cv_prm_normal )
                  AND  (gv_prm_process_date IS NOT NULL) THEN
                lv_change_flg := cv_yes;
              ELSE
              ---- 処理区分が２のみ対象とする
              --IF (gv_prm_process_div = cv_prm_div) THEN
              /* 2009.05.28 D.Abe T1_1042(再２)対応 END */
              /* 2009.05.26 D.Abe T1_1042対応 END */
                -- ========================================
                -- A-6.物件関連情報変更チェック処理
                -- ========================================
                /* 2009.04.01 K.Satomura T1_0148対応 START */
                /* 2009.04.07 K.Satomura T1_0378対応 START */
                --IF (g_get_xxcso_ib_info_h_rec.interface_flag <> cv_yes) THEN
                IF (g_get_xxcso_ib_info_h_rec.interface_flag = cv_yes) THEN
                /* 2009.04.07 K.Satomura T1_0378対応 END */
                  -- 連携済フラグがYの場合
                /* 2009.04.01 K.Satomura T1_0148対応 END */
                  ib_info_change_chk(
                     ov_change_flg => lv_change_flg    -- 変更チェックフラグ
                    ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
                    ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
                    ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
                  );
                /* 2009.04.01 K.Satomura T1_0148対応 START */
                END IF;
                /* 2009.04.01 K.Satomura T1_0148対応 END */
                --
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                --
              /* 2009.05.26 D.Abe T1_1042対応 START */
              /* 2009.05.28 D.Abe T1_1042(再２)対応 START */
              --ELSIF ((gv_prm_process_div = cv_prm_normal)
              --     AND (g_get_xxcso_ib_info_h_rec.interface_flag = cv_yes)) THEN
              --  -- 処理区分が１で連携済み
              --  lv_change_flg := cv_yes;
              --ELSE
              --  -- 処理区分が１で未連携
              --  NULL;
              /* 2009.05.28 D.Abe T1_1042(再２)対応 END */
              END IF;
              /* 2009.05.26 D.Abe T1_1042対応 END */
              /* 2009.04.07 K.Satomura T1_0378対応 START */
              IF (lv_change_flg IS NOT NULL) THEN
              /* 2009.04.07 K.Satomura T1_0378対応 END */
                IF (lv_change_flg = cv_no) THEN
                  -- スキップ件数
                  gn_warn_cnt   := gn_warn_cnt + 1;
                ELSE
                  -- 項目が変更されている場合
--
                  -- ========================================
                  -- A-7.自販機SH物件インタフェース存在チェック
                  -- ========================================
                  xxcff_vd_object_if_chk(
                     ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
                    ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
                    ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
                  );
--
                  IF (lv_retcode = cv_status_error) THEN
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    -- スキップ件数
                    gn_warn_cnt   := gn_warn_cnt + 1;
                    -- 固定ステータス設定（警告）
                    ov_retcode := cv_status_warn;
                    --警告出力
                    fnd_file.put_line(
                       which  => FND_FILE.OUTPUT
                      ,buff   => lv_errmsg                  --ユーザー・警告メッセージ
                    );
                    fnd_file.put_line(
                       which  => FND_FILE.LOG
                      ,buff   => lv_errmsg                  --警告メッセージ
                    );
                /* 2009.04.01 K.Satomura T1_0148対応 START */
                  --ELSE
                  END IF;
                END IF;
                /* 2009.04.01 K.Satomura T1_0148対応 END */
                  -- 自販機SH物件インタフェースに登録対象物件が存在しない場合
              /* 2009.04.07 K.Satomura T1_0378対応 START */
              END IF;
              /* 2009.04.07 K.Satomura T1_0378対応 END */
--
              /* 2009.04.01 K.Satomura T1_0148対応 START */
              IF (((NVL(lv_change_flg, cv_yes) <> cv_no)
                OR (g_get_xxcso_ib_info_h_rec.interface_flag <> cv_yes))
                AND (lv_retcode = cv_status_normal))
              THEN
              /* 2009.04.01 K.Satomura T1_0148対応 END */
                /* 2009.05.26 D.Abe T1_1042対応 START */
                /* 2009.05.28 D.Abe T1_1042(再２)対応 START */
                -- 処理区分が1で処理日付が入力済み
                IF (gv_prm_process_div = cv_prm_normal )
                    AND  (gv_prm_process_date IS NOT NULL) THEN
                  NULL;
                ELSE
                ---- 処理区分が１でかつ未連携、または処理区分が２の場合
                --IF (((gv_prm_process_div = cv_prm_normal)
                --     AND (g_get_xxcso_ib_info_h_rec.interface_flag = cv_no))
                --    OR
                --    (gv_prm_process_div = cv_prm_div)
                --   )
                --THEN
                /* 2009.05.28 D.Abe T1_1042(再２)対応 END */
                /* 2009.05.26 D.Abe T1_1042対応 END */
                  -- ========================================
                  -- A-8.物件関連変更履歴テーブルロック
                  -- ========================================
                  xxcso_ib_info_h_lock(
                     ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
                    ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
                    ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
                  );
--
                  IF (lv_retcode = cv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
--
/* 2009.05.26 D.Abe T1_1042対応 START */
                END IF;
/* 2009.05.26 D.Abe T1_1042対応 END */
                -- ========================================
                -- A-9.セーブポイント発行処理
                -- ========================================
                --
                SAVEPOINT ib_info;
--
                -- ========================================
                -- A-10.自販機SH物件インタフェース登録処理
                -- ========================================
                insert_xxcff_vd_object_if(
                   ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
                  ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
                  ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
                );
--
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
--
                ELSIF (lv_retcode = cv_status_warn) THEN
                  -- スキップ件数
                  gn_warn_cnt   := gn_warn_cnt + 1;
                  -- 固定ステータス設定（警告）
                  ov_retcode := cv_status_warn;
                  --警告出力
                  fnd_file.put_line(
                     which  => FND_FILE.OUTPUT
                    ,buff   => lv_errmsg                  --ユーザー・警告メッセージ
                  );
                  fnd_file.put_line(
                     which  => FND_FILE.LOG
                    ,buff   => lv_errmsg                  --警告メッセージ
                  );
                  ROLLBACK TO SAVEPOINT ib_info;
                  --
                  -- *** DEBUG_LOG ***
                  -- ロールバック処理をログ出力
                  fnd_file.put_line(
                     which  => FND_FILE.LOG
                    ,buff   => cv_debug_msg_rollback  || CHR(10) ||
                               cv_tkn_msg_vd_object_if || cv_tkn_msg_insert ||
                                CHR(10) ||
                               ''
                  );
                ELSE
--
                  /* 2009.05.26 D.Abe T1_1042対応 START */
                  /* 2009.05.28 D.Abe T1_1042(再２)対応 START */
                  -- 処理区分が1で処理日付が入力済み
                  IF (gv_prm_process_div = cv_prm_normal )
                      AND  (gv_prm_process_date IS NOT NULL) THEN
                    gn_normal_cnt := gn_normal_cnt + 1;
                  ELSE
                  ---- 処理区分が１でかつ未連携、または処理区分が２
                  --IF (((gv_prm_process_div = cv_prm_normal)
                  --     AND (g_get_xxcso_ib_info_h_rec.interface_flag = cv_no))
                  --    OR
                  --    (gv_prm_process_div = cv_prm_div)
                  --   )
                  --THEN
                  /* 2009.05.28 D.Abe T1_1042(再２)対応 END */
                  /* 2009.05.26 D.Abe T1_1042対応 END */
                    -- ========================================
                    -- A-11.物件関連情報変更履歴テーブル更新処理
                    -- ========================================
                    update_xxcso_ib_info_h(
                       ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
                      ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
                      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
                    );
--
                    IF (lv_retcode = cv_status_error) THEN
                      RAISE global_process_expt;
                    ELSIF (lv_retcode = cv_status_warn) THEN
                      -- スキップ件数
                      gn_warn_cnt   := gn_warn_cnt + 1;
                      -- 固定ステータス設定（警告）
                      ov_retcode := cv_status_warn;
                      --警告出力
                      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => lv_errmsg                  --ユーザー・警告メッセージ
                      );
                      fnd_file.put_line(
                         which  => FND_FILE.LOG
                        ,buff   => lv_errmsg                  --警告メッセージ
                      );
                      ROLLBACK TO SAVEPOINT ib_info;
                      --
                      -- *** DEBUG_LOG ***
                      -- ロールバック処理をログ出力
                      fnd_file.put_line(
                         which  => FND_FILE.LOG
                        ,buff   => cv_debug_msg_rollback  || CHR(10) ||
                                   cv_tkn_msg_ib_info_h || cv_tkn_msg_update ||
                                    CHR(10) ||
                                   ''
                      );
                      --
                    ELSE
                      -- 正常件数取得
                      gn_normal_cnt := gn_normal_cnt + 1;
                    END IF;
                    /* 2009.04.01 K.Satomura T1_0148対応 START */
                    --END IF;
                    /* 2009.04.01 K.Satomura T1_0148対応 END */
                  /* 2009.05.26 D.Abe T1_1042対応 START */
                  /* 2009.05.28 D.Abe T1_1042(再２)対応 START */
                  --ELSE
                  --  -- 正常件数取得
                  --  gn_normal_cnt := gn_normal_cnt + 1;
                  /* 2009.05.28 D.Abe T1_1042(再２)対応 END */
                  END IF;
                  /* 2009.05.26 D.Abe T1_1042対応 END */
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
--
--
      END LOOP loop_get_xxcso_ib_info;
--
      -- カーソルクローズ
      CLOSE get_xxcso_ib_info_h_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || CHR(10)   ||
                   cv_debug_msgsub_1   || CHR(10)   ||
                   ''
      );
--
/* 2009.07.17 H.Ogawa 0000781対応 START */
    END LOOP loop_get_target;
    -- カーソルクローズ
    CLOSE get_target_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1   || CHR(10)   ||
                 cv_debug_msgsub_0   || CHR(10)   ||
                 ''
    );
--
/* 2009.07.17 H.Ogawa 0000781対応 END */
--
  EXCEPTION
--
    -- SQLエラー例外
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_2  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
--
/* 2009.07.17 H.Ogawa 0000781対応 START */
      IF (get_target_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_2  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781対応 END */
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_1  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
--
/* 2009.07.17 H.Ogawa 0000781対応 START */
      IF (get_target_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_1  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781対応 END */
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_2  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
--
/* 2009.07.17 H.Ogawa 0000781対応 START */
      IF (get_target_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_2  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781対応 END */
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_3  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781対応 START */
      IF (get_target_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_3  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781対応 END */
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
     errbuf          OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode         OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_process_div  IN  VARCHAR2           --   処理区分
    ,iv_process_date IN  VARCHAR2           --   処理実行日
  )
  IS
--
--###########################  固定部 START   ###########################
--
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    lv_errbuf          VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
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
    -- パラメータの格納
    -- ===============================================
    gv_prm_process_div  := iv_process_div;
    gv_prm_process_date := iv_process_date;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
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
    -- A-15.終了処理
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    --ステータスセット
    retcode := lv_retcode;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)  -- 抽出件数
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)  -- 出力件数
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
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO013A02C;
/
