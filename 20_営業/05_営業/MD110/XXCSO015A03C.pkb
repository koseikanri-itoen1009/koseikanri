CREATE OR REPLACE PACKAGE BODY APPS.XXCSO015A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO015A03C(body)
 * Description      : SQL*Loaderによって物件データワークテーブル（アドオン）に取り込まれた
 *                      物件の情報を物件マスタに登録します。
 * MD.050           : MD050_自販機-EBSインタフェース：（IN）物件マスタ情報(IB)
 * Version          : 1.40
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  update_in_work_data    作業データテーブルの物件処理フラグ更新処理 (A-9)
 *  get_item_instances     物件情報抽出 (A-4)
 *  insert_item_instances  物件データ登録処理 (A-5)
 *  rock_item_instances    物件ロック処理 (A-7)
 *  update_item_instances  物件データ更新処理 (A-8)
 *  update_item_instances2 物件データ更新処理2 (A-8-1)
 *  update_cust_or_party   顧客アドオンマスタとパーティマスタ更新処理 (A-10)
 *  delete_in_item_data    物件データワークテーブル削除処理 (A-12)
 *  insupd_hht_cdc_trn_proc HHT集配信連携トランザクションテーブル登録更新処理(A-13)
 *  submain                メイン処理プロシージャ
 *                           (IN) 物件マスタ情報抽出 (A-2)
 *                           セーブポイント設定 (A-3)
 *                           論理削除更新チェック (A-6)
 *                           連携済正常メッセージ出力処理 (A-11)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-14)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-20    1.0   kyo              新規作成
 *  2009-03-16    1.1   abe              変更管理番号I_E_108の対応
 *  2009-03-25    1.2   N.Yabuki         【ST障害対応147】物件関連情報変更履歴テーブル登録不正
 *  2009-03-25    1.2   N.Yabuki         【ST障害対応150】引揚時の担当拠点が不正
 *  2009-04-13    1.3   K.Satomura       【T1_0418対応】インスタンスタイプコード不正
 *  2009-04-17    1.4   K.Satomura       【T1_0466対応】A-6の処理を削除
 *  2009-04-27    1.5   K.Satomura       【T1_0490対応】機器状態3を登録更新不正
 *  2009-05-01    1.6   Tomoko.Mori      T1_0897対応
 *  2009-05-07    1.7   Tomoko.Mori      【T1_0439、0530対応】
 *                                       自販機のみ顧客関連情報更新（T1_0439）
 *                                       設置用物件コード不正エラーチェック（T1_0530）
 *  2009-05-19    1.8   K.Satomura       【T1_0959対応】発注依頼番号を比較チェック不正
 *                                       【T1_1066対応】T1_0530対応の取消
 *  2009-05-26    1.9   M.Ohtsuki        【T1_1141対応】初回取引日更新漏れの対応
 *  2009-05-28    1.10  M.Ohtsuki        【T1_1203対応】先月データ更新障害の対応
 *  2009-06-01    1.11  K.Satomura       【T1_1107対応】
 *  2009-06-04    1.12  K.Satomura       【T1_1107再修正対応】
 *  2009-06-15    1.13  K.Satomura       【T1_1239対応】
 *  2009-07-10    1.14  K.Satomura       統合テスト障害対応(0000476)
 *  2009-08-28    1.15  K.Satomura       統合テスト障害対応(0001205)
 *  2009-08-28    1.16  M.Maruyama       統合テスト障害対応(0001192)
 *  2009-09-14    1.17  K.Satomura       統合テスト障害対応(0001335)
 *  2009-11-29    1.18  T.Maruyama       E_本稼動_00120 新台以外はEBSのIBの機種CDを正とする
 *  2009-12-07    1.19  K.Satomura       E_本稼動_00349 指定の作業会社コードの場合は処理を
 *                                       スキップする（暫定対応）
 *                                       物件データワークテーブル削除条件修正（恒久対応）
 *  2009-12-11    1.20  K.Satomura       E_本稼動_00420 完了区分が設置中止の場合の処理変更
 *  2009-12-14    1.21  K.Hosoi          E_本稼動_00466 顧客アドオンマスタ更新処理時の
 *                                       分岐条件変更
 *  2009-12-16    1.22  K.Hosoi          E_本稼動_00502 作業依頼中フラグを更新する際の条件を
 *                                       設定、顧客ステータス更新処理時の更新する値を変更
 *  2010-01-06    1.23  K.Hosoi          E_本稼動_00825 リース区分に関わらず物件情報履歴データ
 *                                       を作成するよう変更。（後で自社リースに変更するケースを考慮）
 *  2010-01-13    1.24  K.Hosoi          E_本稼動_00443対応
 *  2010-01-19    1.25  K.Hosoi          E_本稼動_00818,01177対応
 *  2010-01-26    1.26  K.Hosoi          E_本稼動_00533,00319対応
 *  2010-03-01    1.27  K.Hosoi          E_本稼動_01761対応
 *  2014-05-19    1.28  Y.Shoji          E_本稼動_11853�G対応
 *  2014-07-08    1.29  T.Kobori         E_本稼動_11853�I対応
 *  2014-08-27    1.30  S.Yamashita      E_本稼動_11719対応
 *  2015-06-17    1.31  K.Kiriu          E_本稼動_12984対応 自販機の付帯機器管理に関する改修
 *  2015-07-29    1.32  K.Kiriu          E_本稼動_13237対応 自販機の付帯機器管理に関する改修追加対応
 *  2015-09-04    1.33  S.Yamashita      E_本稼動_13070対応
 *  2016-02-05    1.34  S.Niki           E_本稼動_13456対応
 *  2016-12-15    1.35  S.Niki           E_本稼動_13903対応 新自販機管理システムからの物件データ連携対応（Q2198,2239）
 *  2017-01-27    1.36  S.Niki           E_本稼動_13903追加対応
 *  2023-04-05    1.37  M.Akachi         E_本稼動_18758対応
 *  2023-04-27    1.38  M.Akachi         E_本稼動_18758不具合対応
 *  2024-04-11    1.39  M.Akachi         E_本稼動_19496グループ会社統合対応対応
 *  2024-05-15    1.40  M.Akachi         E_本稼動_19496不具合対応
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSO015A03C';      -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  -- メッセージコード
  cv_tkn_number_01        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  cv_tkn_number_02        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_03        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_04        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00092';  -- 組織ID取得エラー
  cv_tkn_number_05        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00093';  -- 組織ID抽出エラー
  cv_tkn_number_06        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00094';  -- 品目ID取得エラー
  cv_tkn_number_07        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00095';  -- 品目ID抽出エラー
  cv_tkn_number_08        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00163';  -- ステータスID取得エラー
  cv_tkn_number_09        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00164';  -- ステータスID抽出エラー
  cv_tkn_number_10        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- 取引タイプID取得エラー
  cv_tkn_number_11        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- 取引タイプID抽出エラー
  cv_tkn_number_12        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- 追加属性ID抽出エラー
  cv_tkn_number_13        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173';  -- INV工場返品倉替先コード取得エラー
  cv_tkn_number_14        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00242';  -- 顧客マスタ情報なしエラー
  cv_tkn_number_15        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- 顧客マスタ情報抽出エラー
  cv_tkn_number_16        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- データ抽出エラー
  cv_tkn_number_17        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00051';  -- 物件存在チェック警告
  cv_tkn_number_18        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00556';  -- 物件更新チェック警告
  cv_tkn_number_19        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00105';  -- インストールベースマスタ(物件マスタ)抽出エラー
  cv_tkn_number_20        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00090';  -- リース区分取得エラー
/* Ver.1.34 DEL START */
--  cv_tkn_number_21        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00091';  -- リース区分抽出エラー
/* Ver.1.34 DEL END */
  cv_tkn_number_22        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00193';  -- 物件ワークテーブルの機器状態不正
  cv_tkn_number_23        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00098';  -- 顧客マスタ情報取得できない
  cv_tkn_number_24        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00099';  -- 顧客マスタ情報抽出失敗
  cv_tkn_number_25        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00165';  -- データ登録、更新失敗
  cv_tkn_number_26        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00052';  -- 論理削除更新チェックエラー
  cv_tkn_number_27        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00166';  -- ロックエラー
  cv_tkn_number_28        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00104';  -- インスタンスパーティ取得エラー
  cv_tkn_number_29        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00105';  -- インスタンスパーティ取得エラー
  cv_tkn_number_30        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00167';  -- (IN)物件マスタ情報連携済正常メッセージ
  cv_tkn_number_31        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00119';  -- データ削除エラーメッセージ
  cv_tkn_number_32        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00518';  -- データ抽出0件メッセージ
/*20090507_mori_T1_0439 START*/
  cv_tkn_number_33        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00569';  -- 設置用物件コード不正エラー
/*20090507_mori_T1_0439 END*/
  /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
  cv_tkn_number_34        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00590';  -- 有効顧客抽出失敗エラーメッセージ
  /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
  /* 2015-06-17 K.Kiriu E_本稼動_12984 ADD START */
  cv_tkn_number_35        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00757';  -- HHT集配信連携トランザクション(文言)
/* Ver.1.34 DEL START */
--  cv_tkn_number_36        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00761';  -- 対象物件取得エラー
/* Ver.1.34 DEL END */
  cv_tkn_number_37        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00767';  -- ロックエラー
  cv_tkn_number_38        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00768';  -- 対象物件その他例外エラー
  cv_tkn_number_39        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00703';  -- 更新(文言)
  cv_tkn_number_40        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00702';  -- 登録(文言)
/* Ver.1.34 DEL START */
--  cv_tkn_number_41        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00344';  -- 発注依頼情報なしエラーメッセージ
--  cv_tkn_number_42        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00769';  -- 発注依頼情報(文言)
/* Ver.1.34 DEL END */
  /* 2015-06-17 K.Kiriu E_本稼動_12984 ADD END   */
--
  -- トークンコード
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_task_nm          CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_organization     CONSTANT VARCHAR2(20) := 'ORGANIZATION_CODE';
  cv_tkn_segment          CONSTANT VARCHAR2(20) := 'SEGMENT';
  cv_tkn_organization_id  CONSTANT VARCHAR2(20) := 'ORGANIZATION_ID';
  cv_tkn_status_name      CONSTANT VARCHAR2(20) := 'STATUS_NAME';
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  cv_tkn_attribute_name   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_attribute_code   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_bukken           CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_slip_num         CONSTANT VARCHAR2(20) := 'SLIP_NUM';
  cv_tkn_slip_branch_num  CONSTANT VARCHAR2(20) := 'SLIP_BRANCH_NUM';
  cv_tkn_line_num         CONSTANT VARCHAR2(20) := 'LINE_NUM';
  cv_tkn_work_kbn         CONSTANT VARCHAR2(20) := 'WORK_KBN';
  cv_tkn_bukken1          CONSTANT VARCHAR2(20) := 'BUKKEN1';
  cv_tkn_bukken2          CONSTANT VARCHAR2(20) := 'BUKKEN2';
  cv_tkn_hazard_state1    CONSTANT VARCHAR2(20) := 'HAZARD_STATE1';
  cv_tkn_hazard_state2    CONSTANT VARCHAR2(20) := 'HAZARD_STATE2';
  cv_tkn_hazard_state3    CONSTANT VARCHAR2(20) := 'HAZARD_STATE3';
  cv_tkn_account_num1     CONSTANT VARCHAR2(20) := 'ACCOUNT_NUM1';
  cv_tkn_account_num2     CONSTANT VARCHAR2(20) := 'ACCOUNT_NUM2';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_partnership_name CONSTANT VARCHAR2(20) := 'PARTNERSHIP_NAME';
  cv_tkn_cust_status_info CONSTANT VARCHAR2(20) := 'CUST_STATUS_UP_INFO';
  cv_tkn_cnvs_date        CONSTANT VARCHAR2(20) := 'CNVS_DATE';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
/* Ver.1.34 DEL START */
--  cv_tkn_last_req_no      CONSTANT VARCHAR2(20) := 'LAST_REQ_NO';
--  cv_tkn_req_no           CONSTANT VARCHAR2(20) := 'REQ_NO';
/* Ver.1.34 DEL END */
  cv_tkn_seq_no           CONSTANT VARCHAR2(20) := 'SEQ_NO';
  /* 2015-06-17 K.Kiriu E_本稼動_12984 ADD START */
  cv_tkn_action           CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'CUST_CODE';
  cv_tkn_install_code     CONSTANT VARCHAR2(20) := 'INSTALL_CODE';
/* Ver.1.34 DEL START */
--  cv_tkn_req_header_num   CONSTANT VARCHAR2(20) := 'REQ_HEADER_NUM';
/* Ver.1.34 DEL END */
  /* 2015-06-17 K.Kiriu E_本稼動_12984 ADD END   */
--
  -- 作業区分
  cn_work_kbn1            CONSTANT NUMBER        := 1;                -- 新台設置
  cn_work_kbn2            CONSTANT NUMBER        := 2;                -- 旧台設置
  cn_work_kbn3            CONSTANT NUMBER        := 3;                -- 新台代替
  cn_work_kbn4            CONSTANT NUMBER        := 4;                -- 旧台代替
  cn_work_kbn5            CONSTANT NUMBER        := 5;                -- 引揚
  cn_work_kbn6            CONSTANT NUMBER        := 6;                -- 店内移動
/* Ver.1.34 ADD START */
  -- 伝票枝番
  cn_slip_kbn0            CONSTANT NUMBER        := 0;                -- 依頼データ
/* Ver.1.34 ADD END */
--
  cb_true                 CONSTANT BOOLEAN       := TRUE;
--
  cv_true                    CONSTANT VARCHAR2(10) := 'TRUE';    -- 共通関数戻り値判定用
  cv_false                   CONSTANT VARCHAR2(10) := 'FALSE';   -- 共通関数戻り値判定用
--
  cv_active               CONSTANT VARCHAR2(1)   := 'A';              -- ACTIVE
--
  cv_encoded_f            CONSTANT VARCHAR2(1)   := 'F';              -- FALSE   
/*20090507_mori_T1_0439 START*/
--
  cv_instance_type_vd     CONSTANT VARCHAR2(1) := '1';        -- インスタンスステータスタイプ（自販機）
--
/*20090507_mori_T1_0439 END*/
  /* 2009.12.11 K.Satomura E_本稼動_00420対応 START */
  ct_comp_kbn_comp        CONSTANT xxcso_in_work_data.completion_kbn%TYPE := 1;
  /* 2009.12.11 K.Satomura E_本稼動_00420対応 END */
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
  cv_lease_type_assets    CONSTANT VARCHAR2(1)   := '4';                 -- リース区分(固定資産税)
  --参照タイプ
  cv_xxcs01_lease_kbn     CONSTANT VARCHAR2(100) := 'XXCSO1_LEASE_KBN';  -- リース区分
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 ADD START */
  cv_msg_part_only        CONSTANT VARCHAR2(1) := ':';
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 ADD END */
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'lv_inv_mst_org_code   = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'lv_vld_org_code       = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_bukken_item        = ';
-- Ver.1.39 Del Start
--  cv_debug_msg9           CONSTANT VARCHAR2(200) := 'gv_withdraw_base_code    = ';
--  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'gv_jyki_withdraw_base_code = ';
-- Ver.1.39 Del End
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
  cv_debug_msg12          CONSTANT VARCHAR2(200) := 'gv_dclr_place_code = ';
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
  /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
  cv_debug_msg13          CONSTANT VARCHAR2(200) := 'gt_own_base_wkcmp_code = ';
  /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
-- Ver.1.39 Add Start
  cv_debug_msg14          CONSTANT VARCHAR2(200) := 'gn_set_of_bks_id = ';
-- Ver.1.39 Add End
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
-- Ver.1.39 Del Start
--  gn_account_id          NUMBER;                                        -- 引揚拠点アカウントID
--  gn_party_site_id       NUMBER;                                        -- 引揚拠点パーティサイトID
--  gn_party_id            NUMBER;                                        -- 引揚拠点パーティID
--  gv_area_code           VARCHAR2(100);                                 -- 引揚拠点地区コード
--  gn_jyki_account_id     NUMBER;                                        -- 什器引揚拠点アカウントID
--  gn_jyki_party_site_id  NUMBER;                                        -- 什器引揚拠点パーティサイトID
--  gn_jyki_party_id       NUMBER;                                        -- 什器引揚拠点パーティID
--  gv_jyki_area_code      VARCHAR2(100);                                 -- 什器引揚拠点地区コード
-- Ver.1.39 Del End
  gb_insert_process_flg   BOOLEAN;                                       -- 登録更新フラグ「TRUE(登録)、FALSE(更新)」
  gb_rollback_flg         BOOLEAN := FALSE;                              -- TRUE : ロールバック
  gb_cust_status_free_flg BOOLEAN := FALSE;                              -- 顧客ステータス「休止」更新フラグ    
  gb_cust_status_appr_flg BOOLEAN := FALSE;                              -- 顧客ステータス「承認済」更新フラグ    
  gb_cust_cnv_upd_flg     BOOLEAN := FALSE;                              -- 顧客獲得日更新フラグ    
-- Ver.1.39 Del Start
--  gv_withdraw_base_code   VARCHAR2(100);                                 -- 引揚拠点コード
--  gv_jyki_withdraw_base_code  VARCHAR2(100);                             -- 什器引揚拠点コード
-- Ver.1.39 Del End
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
  gv_dclr_place_code      VARCHAR2(5);                                   -- 申告地コード
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
  -- Ver.1.39 Add Start
  gn_set_of_bks_id        NUMBER;                                        -- GL会計帳簿ID
  -- Ver.1.39 Add End
  /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
  gt_own_base_wkcmp_code  fnd_profile_option_values.profile_option_value%TYPE;  -- 自拠点作業時作業会社CD
  /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
  gt_inv_mst_org_id       mtl_parameters.organization_id%TYPE;           -- 組織ID
  gt_vld_org_id           mtl_parameters.organization_id%TYPE;           -- 検証組織ID
  gt_txn_type_id          csi_txn_types.transaction_type_id%TYPE;        -- 取引タイプID
  gt_bukken_item_id       mtl_system_items_b.inventory_item_id%TYPE;     -- 物件用品目ID
-- Ver.1.37 Add Start
  gt_instance_status_id_0 csi_instance_statuses.instance_status_id%TYPE; -- 在庫
-- Ver.1.37 Add End
  gt_instance_status_id_1 csi_instance_statuses.instance_status_id%TYPE; -- 稼働中
  gt_instance_status_id_2 csi_instance_statuses.instance_status_id%TYPE; -- 使用可
  gt_instance_status_id_3 csi_instance_statuses.instance_status_id%TYPE; -- 整備中
  gt_instance_status_id_4 csi_instance_statuses.instance_status_id%TYPE; -- 廃棄手続中
  gt_instance_status_id_5 csi_instance_statuses.instance_status_id%TYPE; -- 廃棄処理済
  gt_instance_status_id_6 csi_instance_statuses.instance_status_id%TYPE; -- 物件削除済
  -- 会計期間チェック用
  gv_chk_rslt               VARCHAR2(10);
  gv_chk_rslt_flag          VARCHAR2(1);
  /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
  gd_cnvs_date              DATE;            -- 顧客獲得日
  /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
  gv_lease_kbn              VARCHAR2(1);     -- リース区分
  /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
--
  -- 追加属性ID格納用レコード型定義
  TYPE gr_ib_ext_attribs_id_rtype IS RECORD(
     count_no              NUMBER               -- カウンターNo.
    ,chiku_cd              NUMBER               -- 地区コード
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
    ,jotai_kbn1            NUMBER               -- 機器状態1（稼動状態）
    ,jotai_kbn2            NUMBER               -- 機器状態2（状態詳細）
    ,jotai_kbn3            NUMBER               -- 機器状態3（廃棄情報）
    ,nyuko_dt              NUMBER               -- 入庫日
    ,hikisakigaisya_cd     NUMBER               -- 引揚会社コード
    ,hikisakijigyosyo_cd   NUMBER               -- 引揚事業所コード
    ,setti_tanto           NUMBER               -- 設置先担当者名
    ,setti_tel1            NUMBER               -- 設置先tel1
    ,setti_tel2            NUMBER               -- 設置先tel2
    ,setti_tel3            NUMBER               -- 設置先tel3
    ,haikikessai_dt        NUMBER               -- 廃棄決裁日
    ,tenhai_tanto          NUMBER               -- 転売廃棄業者
    ,tenhai_den_no         NUMBER               -- 転売廃棄伝票��
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
    ,lease_kbn             NUMBER               -- リース区分
    ,last_inst_cust_code   NUMBER               -- 先月末設置先顧客コード
    ,last_jotai_kbn        NUMBER               -- 先月末機器状態
    ,last_year_month       NUMBER               -- 先月末年月
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    ,vd_shutoku_kg         NUMBER               -- 取得価格
    ,dclr_place            NUMBER               -- 申告地
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD ENDT */
/* Ver.1.34 ADD START */
    ,fa_move_date          NUMBER               -- 固定資産移動日
    ,last_act_date_time    NUMBER               -- 最終有効実作業日時
/* Ver.1.34 ADD END */
  );
  -- 追加属性ID格納用レコード変数
  gr_ext_attribs_id_rec   gr_ib_ext_attribs_id_rtype;
--
  -- 物件情報レコード
  TYPE g_get_data_rtype IS RECORD(
      seq_no                      NUMBER          -- シーケンス番号
     ,slip_no                     NUMBER          -- 伝票No.
     ,slip_branch_no              NUMBER          -- 伝票枝番
     ,line_number                 NUMBER          -- 行番号
     ,job_kbn                     NUMBER          -- 作業区分
     ,install_code1               VARCHAR2(10)    -- 物件コード１（設置用）
     ,install_code2               VARCHAR2(10)    -- 物件コード２（引揚用）
     /* 2009.06.15 K.Satomura T1_1239対応 START */
     ,completion_kbn              NUMBER          -- 完了区分
     /* 2009.06.15 K.Satomura T1_1239対応 END */
     ,safe_setting_standard       VARCHAR2(1)     -- 安全設置基準
     ,install_code                VARCHAR2(10)    -- 物件コード
     ,un_number                   VARCHAR2(14)    -- 機種
     ,install_number              VARCHAR2(14)    -- 機番
     ,machinery_kbn               NUMBER          -- 機器区分
     ,first_install_date          NUMBER          -- 初回設置日
     ,counter_no                  NUMBER          -- カウンターNo.
     ,division_code               VARCHAR2(6)     -- 地区コード
     ,base_code                   VARCHAR2(4)     -- 拠点コード
     ,job_company_code            VARCHAR2(6)     -- 作業会社コード
     ,location_code               VARCHAR2(4)     -- 事業所コード
     ,last_job_slip_no            NUMBER          -- 最終作業伝票No.
     ,last_job_kbn                NUMBER          -- 最終作業区分
     ,last_job_going              NUMBER          -- 最終作業進捗
     ,last_job_cmpltn_plan_date   NUMBER          -- 最終作業完了予定日
     ,last_job_cmpltn_date        NUMBER          -- 最終作業完了日
     ,last_maintenance_contents   NUMBER          -- 最終整備内容
     ,last_install_slip_no        NUMBER          -- 最終設置伝票No.
     ,last_install_kbn            NUMBER          -- 最終設置区分
     ,last_install_plan_date      NUMBER          -- 最終設置予定日
     ,last_install_going          NUMBER          -- 最終設置進捗
     ,machinery_status1           NUMBER          -- 機器状態1（稼動状態）
     ,machinery_status2           NUMBER          -- 機器状態2（状態詳細）
     ,machinery_status3           NUMBER          -- 機器状態3（廃棄情報）
     ,stock_date                  NUMBER          -- 入庫日
     ,withdraw_company_code       VARCHAR2(6)     -- 引揚会社コード
     ,withdraw_location_code      VARCHAR2(4)     -- 引揚事業所コード
     ,resale_disposal_vendor      VARCHAR2(6)     -- 転売廃棄業者
     ,resale_disposal_slip_no     NUMBER          -- 転売廃棄伝票��
     ,owner_company_code          VARCHAR2(4)     -- 所有者
     ,resale_disposal_flag        NUMBER          -- 転売廃棄状況フラグ
     ,resale_completion_kbn       NUMBER          -- 転売完了区分
     ,delete_flag                 NUMBER          -- 削除フラグ
     ,creation_date_time          DATE            -- 作成日時時分秒
     ,update_date_time            DATE            -- 更新日時時分秒
     ,account_number1             VARCHAR2(9)     -- 顧客コード１（新設置先
     ,account_number2             VARCHAR2(9)     -- 顧客コード２（現設置先
/* Ver.1.34 DEL START */
--     ,po_number                   NUMBER          -- 発注番号
--     ,po_line_number              NUMBER          -- 発注明細番号
--     ,po_req_number               NUMBER          -- 発注依頼番号
--     ,line_num                    NUMBER          -- 発注依頼明細番号
/* Ver.1.34 DEL END */
     ,instance_id                 NUMBER          -- インスタンスID
     ,object_version1             NUMBER          -- オブジェクトバージョン番号
     ,instance_status_id          NUMBER          -- インスタンスステータスID
     ,new_old_flg                 VARCHAR2(1)     -- 新古台フラグ
     ,actual_work_date            NUMBER          -- 実作業日
     /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
     ,ib_un_number                VARCHAR2(14)    -- インストールベース機種
     /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */
     /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
     ,actual_work_time1           VARCHAR2(4)     -- 実作業時間１
     /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
/* Ver.1.34 ADD START */
     ,lease_type                  VARCHAR2(1)     -- リース区分
     ,declaration_place           VARCHAR2(10)    -- 申告地
     ,get_price                   NUMBER          -- 取得価格
     ,work_hope_date              NUMBER          -- 作業希望日/引取希望日
/* Ver.1.34 ADD END */
  );
--
  -- 工場返品倉替先コードレコード定義
  TYPE gr_mfg_fctory_code_rtype is RECORD(
     mfg_fctory_code              VARCHAR2(100)          -- INV工場返品倉替先コード
  );
--
  -- 工場返品倉替先コードテーブル定義
  TYPE gt_mfg_fctory_code_ttype is TABLE OF gr_mfg_fctory_code_rtype INDEX BY BINARY_INTEGER;
  -- 工場返品倉替先コードテーブル変数
  gt_mfg_fctory_code_tab  gt_mfg_fctory_code_ttype;
--  
  -- 追加属性値のレコード定義追加属性値ID、追加属性値、オブジェクトバージョン番号の
  TYPE gr_csi_iea_values_rtype is RECORD(
     attribute_value_id          NUMBER                 -- 追加属性値ID
    ,attribute_value             VARCHAR2(240)          -- 追加属性値
    ,object_version_number       NUMBER                 -- オブジェクトバージョン番号
  );
--  
  -- *** ユーザー定義グローバル例外 ***
  global_skip_expt        EXCEPTION;
  global_lock_expt        EXCEPTION;                                 -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate           OUT DATE                 -- システム日付
    ,od_process_date      OUT NOCOPY DATE          -- 業務処理日付
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
--
    -- アプリケーション短縮名
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
    -- プロファイル名
--
-- Ver.1.37 Add Start
    -- 参照タイプのIBステータス(在庫)コード
    cv_instance_status_0      CONSTANT VARCHAR2(1)   := '0';
-- Ver.1.37 Add End
    -- 参照タイプのIBステータス(稼働中)コード
    cv_instance_status_1      CONSTANT VARCHAR2(1)   := '1';
    -- 参照タイプのIBステータス(使用可)コード
    cv_instance_status_2      CONSTANT VARCHAR2(1)   := '2';
    -- 参照タイプのIBステータス(整備中)コード
    cv_instance_status_3      CONSTANT VARCHAR2(1)   := '3';
    -- 参照タイプのIBステータス(廃棄手続中)コード
    cv_instance_status_4      CONSTANT VARCHAR2(1)   := '4';
    -- 参照タイプのIBステータス(廃棄処理済)コード
    cv_instance_status_5      CONSTANT VARCHAR2(1)   := '5';
    -- 参照タイプのIBステータス(物件削除済)コード
    cv_instance_status_6      CONSTANT VARCHAR2(1)   := '6';
    -- XXCSO:在庫マスタ組織
    cv_inv_mst_org_code       CONSTANT VARCHAR2(30)  := 'XXCSO1_INV_MST_ORG_CODE';
    -- XXCSO:検証組織
    cv_vld_org_code           CONSTANT VARCHAR2(30)  := 'XXCSO1_VLD_ORG_CODE';
    -- XXCSO:物件用品目
    cv_bukken_item            CONSTANT VARCHAR2(30)  := 'XXCSO1_BUKKEN_ITEM';
    -- XXCSO:伊藤園顧客名
--    cv_itoen_cust_name        CONSTANT VARCHAR2(30)  := 'XXCSO1_ITOEN_CUST_NAME';
    -- XXCSO:引揚拠点区分
--    cv_withdraw_base_type     CONSTANT VARCHAR2(30)  := 'XXCSO1_WITHDRAW_BASE_TYPE';
-- Ver.1.39 Del Start
--    -- XXCSO:引揚拠点コード
--    cv_withdraw_base_code     CONSTANT VARCHAR2(30)  := 'XXCSO1_WITHDRAW_BASE_CODE';
--    -- XXCSO:什器引揚拠点コード
--    cv_jyki_withdraw_base_code  CONSTANT VARCHAR2(30)  := 'XXCSO1_JYKI_WTHDRW_BASE_CODE';
-- Ver.1.39 Del End
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    -- XXCSO:申告地コード
    cv_dclr_place_code        CONSTANT VARCHAR2(30)  := 'XXCSO1_DCLR_PLACE_CODE';
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
    /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
    -- XXCSO:自拠点作業時作業会社CD
    cv_own_base_wkcmp_code    CONSTANT VARCHAR2(30)  := 'XXCSO1_ZIKYOTEN_WKCMP_FULL_CD';
    /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
-- Ver.1.39 Add Start
    -- 会計帳簿ID
    cv_set_of_books_id        CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID';
-- Ver.1.39 Add End
--
    -- ソーストランザクションタイプ
    cv_src_transaction_type   CONSTANT VARCHAR2(30)  := 'IB_UI';
    -- 工場返品倉替先コード
    cv_xxcoi_mfg_fctory_type  CONSTANT VARCHAR2(30)  := 'XXCOI_MFG_FCTORY_CD';
    -- 参照タイプのIBステータスタイプコード
    cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
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
    -- 抽出内容名(参照タイプの工場返品倉替先コード)
    cv_mfg_fctory_code_info   CONSTANT VARCHAR2(100) := '参照タイプの工場返品倉替先コード';
-- Ver.1.39 Del Start
--    -- 抽出内容名(伊藤園の顧客マスタ情報)
--    cv_cust_acct_sites_info   CONSTANT VARCHAR2(100) := '引揚拠点の顧客マスタ情報';
--    -- 抽出内容名(伊藤園の顧客マスタ情報)
--    cv_cust_acct_sites_info1  CONSTANT VARCHAR2(100) := '什器引揚拠点の顧客マスタ情報';
--    -- 抽出内容名(顧客コード)
--    cv_cust_account_number    CONSTANT VARCHAR2(100) := '顧客コード';
-- Ver.1.39 Del End
-- Ver.1.37 Add Start
    -- ステータス名(在庫)
    cv_statuses_name00        CONSTANT VARCHAR2(100) := '在庫';
-- Ver.1.37 Add End
    -- ステータス名(稼働中)
    cv_statuses_name01        CONSTANT VARCHAR2(100) := '稼働中';
    -- ステータス名(使用可)
    cv_statuses_name02        CONSTANT VARCHAR2(100) := '使用可';
    -- ステータス名(整備中)
    cv_statuses_name03        CONSTANT VARCHAR2(100) := '整備中';
    -- ステータス名(廃棄手続中)
    cv_statuses_name04        CONSTANT VARCHAR2(100) := '廃棄手続中';
    -- ステータス名(廃棄処理済)
    cv_statuses_name05        CONSTANT VARCHAR2(100) := '廃棄処理済';
    -- ステータス名(物件削除済)
    cv_statuses_name06        CONSTANT VARCHAR2(100) := '物件削除済';
--
    -- カウンターNo.
    cv_i_ext_count_no         CONSTANT VARCHAR2(100) := 'カウンターNo.';
    -- 地区コード
    cv_i_ext_chiku_cd         CONSTANT VARCHAR2(100) := '地区コード';
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
    -- 機器状態1（稼動状態）
    cv_i_ext_jotai_kbn1       CONSTANT VARCHAR2(100) := '機器状態1（稼動状態）';
    -- 機器状態2（状態詳細）
    cv_i_ext_jotai_kbn2       CONSTANT VARCHAR2(100) := '機器状態2（状態詳細）';
    -- 機器状態3（廃棄情報）
    cv_i_ext_jotai_kbn3       CONSTANT VARCHAR2(100) := '機器状態3（廃棄情報）';
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
    -- 転売廃棄伝票��
    cv_i_ext_tenhai_den_no    CONSTANT VARCHAR2(100) := '転売廃棄伝票��';
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
    -- リース区分
    cv_i_ext_lease_kbn        CONSTANT VARCHAR2(100) := 'リース区分';
    -- 先月末設置先顧客コード
    cv_i_ext_last_inst_cust_code  CONSTANT VARCHAR2(100) := '先月末設置先顧客コード';
    -- 先月末機器状態
    cv_i_ext_last_jotai_kbn   CONSTANT VARCHAR2(100) := '先月末機器状態';
    -- 先月末年月
    cv_i_ext_last_year_month  CONSTANT VARCHAR2(100) := '先月末年月';
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    -- 取得価格
    cv_i_ext_vd_shutoku_kg    CONSTANT VARCHAR2(100) := '取得価格';
    -- 申告地
    cv_i_ext_dclr_place       CONSTANT VARCHAR2(100) := '申告地';
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD ENDT */
/* Ver.1.34 ADD START */
    -- 固定資産移動日
    cv_i_ext_fa_move_date     CONSTANT VARCHAR2(100) := '固定資産移動日';
/* Ver.1.35 Q2239 MOD START */
    -- 最終有効実作業日時
--    cv_i_ext_last_act_dt      CONSTANT VARCHAR2(100) := '最終実作業日時';
    cv_i_ext_last_act_dt      CONSTANT VARCHAR2(100) := '最終有効実作業日時';
/* Ver.1.35 Q2239 MOD END */
/* Ver.1.34 ADD END */
    -- カウンターNo.
    cv_count_no               CONSTANT VARCHAR2(100) := 'COUNT_NO';
    -- 地区コード
    cv_chiku_cd               CONSTANT VARCHAR2(100) := 'CHIKU_CD';
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
    -- 機器状態1（稼動状態）
    cv_jotai_kbn1             CONSTANT VARCHAR2(100) := 'JOTAI_KBN1';
    -- 機器状態2（状態詳細）
    cv_jotai_kbn2             CONSTANT VARCHAR2(100) := 'JOTAI_KBN2';
    -- 機器状態2（廃棄情報）
    cv_jotai_kbn3             CONSTANT VARCHAR2(100) := 'JOTAI_KBN3';
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
    -- 転売廃棄伝票��
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
    -- リース区分
    cv_lease_kbn              CONSTANT VARCHAR2(100) := 'LEASE_KBN';
    -- 先月末設置先顧客コード
    cv_last_inst_cust_code    CONSTANT VARCHAR2(100) := 'LAST_INST_CUST_CODE';
    -- 先月末機器状態
    cv_last_jotai_kbn         CONSTANT VARCHAR2(100) := 'LAST_JOTAI_KBN';
    -- 先月末年月
    cv_last_year_month        CONSTANT VARCHAR2(100) := 'LAST_YEAR_MONTH';
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    -- 取得価格
    cv_vd_shutoku_kg          CONSTANT VARCHAR2(100) := 'VD_SHUTOKU_KG';
    -- 申告地
    cv_dclr_place             CONSTANT VARCHAR2(100) := 'DCLR_PLACE';
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
/* Ver.1.34 ADD START */
    -- 固定資産移動日
    cv_fa_move_date           CONSTANT VARCHAR2(100) := 'FA_MOVE_DATE';
    -- 最終有効実作業日時
    cv_last_act_dt            CONSTANT VARCHAR2(100) := 'LAST_ACT_DATE_TIME';
/* Ver.1.34 ADD END */
--
    -- INV工場返品倉替先コード
    cv_mfg_fctory_name        CONSTANT VARCHAR2(100) :='「INV工場返品倉替先コード」';
    
--
    -- *** ローカル変数 ***
    -- 業務処理日
    ld_process_date           DATE;
    -- カウント数
    ln_cnt                    NUMBER;
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
    -- *** ローカル・カーソル ***
    CURSOR get_mfg_fctory_code_cur
    IS
      SELECT flvv.lookup_code mfg_fctory_code                         -- コード
      FROM   fnd_lookup_values_vl  flvv                               -- 参照タイプ
      WHERE  flvv.lookup_type      = cv_xxcoi_mfg_fctory_type
        AND  flvv.enabled_flag     = 'Y'
        AND  NVL(flvv.start_date_active, ld_process_date) <= ld_process_date
        AND  NVL(flvv.end_date_active,   ld_process_date) >= ld_process_date
      ;
    -- *** ローカル・レコード ***
    l_mfg_fctory_code_rec      get_mfg_fctory_code_cur%ROWTYPE;

  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =================================
    -- 入力パラメータなしメッセージ出力 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01             --メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- 業務処理日付取得に失敗した場合
    IF (od_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    ld_process_date :=TRUNC(od_process_date);
--
    -- =====================
    -- AR会計期間クローズチェック 
    -- =====================
    /* 2009.08.28 K.Satomura 0001205対応 START */
    --gv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
    --                   id_standard_date => ld_process_date
    --                 );
    --IF (gv_chk_rslt = cv_true) THEN
    --  gv_chk_rslt_flag := 'N';
    --ELSE
    --  gv_chk_rslt_flag := 'C';
    --END IF;
    /* 2009.08.28 K.Satomura 0001205対応 END */
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
-- Ver.1.39 Del Start
--    FND_PROFILE.GET(
--                    cv_withdraw_base_code
--                   ,gv_withdraw_base_code
--                   ); -- 引揚拠点コード
--    FND_PROFILE.GET(
--                    cv_jyki_withdraw_base_code
--                   ,gv_jyki_withdraw_base_code
--                   ); -- 什器引揚拠点コード
-- Ver.1.39 Del End
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    FND_PROFILE.GET(
                    cv_dclr_place_code
                   ,gv_dclr_place_code
                   ); -- 申告地コード
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
    /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
    FND_PROFILE.GET(
                    cv_own_base_wkcmp_code
                   ,gt_own_base_wkcmp_code
                   ); -- 自拠点作業時作業会社CD
    /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
-- Ver.1.39 Add Start
    FND_PROFILE.GET(
                    cv_set_of_books_id
                   ,gn_set_of_bks_id
                   ); -- GL会計帳簿ID
-- Ver.1.39 Add End
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10)               ||
                 cv_debug_msg6  || lv_inv_mst_org_code   || CHR(10) ||
                 cv_debug_msg7  || lv_vld_org_code       || CHR(10) ||
                 cv_debug_msg8  || lv_bukken_item        || CHR(10) ||
                 -- Ver.1.39 Del Start
                 --cv_debug_msg9  || gv_withdraw_base_code || CHR(10) ||
                 --cv_debug_msg10 || gv_jyki_withdraw_base_code || CHR(10) ||
                 -- Ver.1.39 Del End
                 /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
                 cv_debug_msg12 || gv_dclr_place_code    || CHR(10) ||
                 /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
                 /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
                 cv_debug_msg13 || gt_own_base_wkcmp_code || CHR(10) ||
                 /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
                 -- Ver.1.39 Add Start
                 cv_debug_msg14 || gn_set_of_bks_id      || CHR(10) ||
                 -- Ver.1.39 Add End
                 ''
    );
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
    /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
    -- XXCSO:自拠点作業時作業会社CD
    ELSIF (gt_own_base_wkcmp_code IS NULL) THEN
      lv_tkn_value := cv_own_base_wkcmp_code;
    /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
    -- Ver.1.39 Add Start
    -- GL会計帳簿ID
    ELSIF (gn_set_of_bks_id IS NULL) THEN
      lv_tkn_value := cv_set_of_books_id;
    -- Ver.1.39 Add End
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
      WHERE   mp.organization_code = lv_vld_org_code
      ;
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
-- Ver.1.37 Add Start
   -- 初期化
    lv_status_name   := '';
    -- 「在庫」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_0
                          ,ld_process_date);
      SELECT cis.instance_status_id                                     -- インスタンスステータスID
      INTO   gt_instance_status_id_0
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
                       ,iv_token_value2 => cv_statuses_name00           -- トークン値2
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
                       ,iv_token_value2 => cv_statuses_name00           -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
-- Ver.1.37 Add End
--
    -- 初期化
    lv_status_name   := '';
    -- 「稼動中」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_1
                          ,ld_process_date);
      SELECT cis.instance_status_id                                     -- インスタンスステータスID
      INTO   gt_instance_status_id_1
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
                       ,iv_token_value2 => cv_statuses_name01           -- トークン値2
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
                       ,iv_token_value2 => cv_statuses_name01           -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 初期化
    lv_status_name   := '';
    -- 「使用可」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_2
                          ,ld_process_date);
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
    -- 初期化
    lv_status_name   := '';
    -- 「整備中」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_3
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- インスタンスステータスID
      INTO   gt_instance_status_id_3
      FROM   csi_instance_statuses cis                                -- インスタンスステータスマスタ
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
                       ,iv_token_value2 => cv_statuses_name03           -- トークン値2
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
                       ,iv_token_value2 => cv_statuses_name03           -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 初期化
    lv_status_name   := '';
    -- 「廃棄手続中」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_4
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- インスタンスステータスID
      INTO   gt_instance_status_id_4
      FROM   csi_instance_statuses cis                                -- インスタンスステータスマスタ
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
                       ,iv_token_value2 => cv_statuses_name04           -- トークン値2
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
                       ,iv_token_value2 => cv_statuses_name04           -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 初期化
    lv_status_name   := '';
    -- 「廃棄処理済」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_5
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- インスタンスステータスID
      INTO   gt_instance_status_id_5
      FROM   csi_instance_statuses cis                                -- インスタンスステータスマスタ
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
                       ,iv_token_value2 => cv_statuses_name05           -- トークン値2
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
                       ,iv_token_value2 => cv_statuses_name05           -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 初期化
    lv_status_name   := '';
    -- 「物件削除済」
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_6
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- インスタンスステータスID
      INTO   gt_instance_status_id_6
      FROM   csi_instance_statuses cis                                -- インスタンスステータスマスタ
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
                       ,iv_token_value2 => cv_statuses_name06           -- トークン値2
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
                       ,iv_token_value2 => cv_statuses_name06           -- トークン値2
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
    -- 追加属性ID(転売廃棄伝票��)
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
--
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    -- 追加属性ID(取得価格)
    gr_ext_attribs_id_rec.vd_shutoku_kg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_vd_shutoku_kg
                                             ,ld_process_date);
    /* 2014-07-08 T.Kobori E_本稼動_11853�I対応 DEL START */
--    gr_ext_attribs_id_rec.vd_shutoku_kg := NULL;
    /* 2014-07-08 T.Kobori E_本稼動_11853�I対応 DEL END */
    IF (gr_ext_attribs_id_rec.vd_shutoku_kg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_vd_shutoku_kg       -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_vd_shutoku_kg             -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 追加属性ID(申告地)
    gr_ext_attribs_id_rec.dclr_place := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_dclr_place
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.dclr_place IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_dclr_place          -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_dclr_place                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* Ver.1.34 ADD START */
    -- 追加属性ID(固定資産移動日)
    gr_ext_attribs_id_rec.fa_move_date := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_fa_move_date
                                            ,ld_process_date
                                          );
    IF (gr_ext_attribs_id_rec.fa_move_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_fa_move_date        -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_fa_move_date              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- 追加属性ID(最終有効実作業日時)
    gr_ext_attribs_id_rec.last_act_date_time := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                   cv_last_act_dt
                                                  ,ld_process_date
                                                );
    IF (gr_ext_attribs_id_rec.last_act_date_time IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_attribute_id_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_i_ext_last_act_dt         -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_last_act_dt               -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* Ver.1.34 ADD END */
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
    -- =========================================
    -- 参照タイプ「INV工場返品倉替先コード」取得 
    -- =========================================
    ln_cnt := 0;
    OPEN get_mfg_fctory_code_cur;
--
    <<get_data_loop>>
    LOOP
      BEGIN
        FETCH get_mfg_fctory_code_cur INTO l_mfg_fctory_code_rec;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1 => cv_mfg_fctory_code_info      -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg                -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
      EXIT WHEN get_mfg_fctory_code_cur%NOTFOUND
      OR get_mfg_fctory_code_cur%ROWCOUNT = 0;
      ln_cnt := ln_cnt + 1;
      gt_mfg_fctory_code_tab(ln_cnt).mfg_fctory_code := l_mfg_fctory_code_rec.mfg_fctory_code;
    END LOOP;
    CLOSE get_mfg_fctory_code_cur;
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_13             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_mfg_fctory_code_info      -- トークン値1
                     ,iv_token_name2  => cv_tkn_lookup_type_name      -- トークンコード2
                     ,iv_token_value2 => cv_mfg_fctory_name           -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--    
-- Ver.1.39 Del Start
--    -- ===================
--    -- 引揚拠点情報取得 
--    -- ===================
----
--    IF (gv_withdraw_base_code IS NOT NULL) THEN
--      BEGIN
--        SELECT casv.cust_account_id                                     -- アカウントID
--              ,casv.party_site_id                                       -- パーティサイトID
--              ,casv.party_id                                            -- パーティID
--              ,casv.area_code                                           -- 地区コード
--        INTO   gn_account_id
--              ,gn_party_site_id
--              ,gn_party_id
--              ,gv_area_code
--        FROM   xxcso_cust_acct_sites_v casv                             -- 顧客マスタサイトビュー
--        WHERE  casv.account_number    = gv_withdraw_base_code
--          AND  casv.account_status    = cv_active
--          AND  casv.acct_site_status  = cv_active
--          AND  casv.party_status      = cv_active
--          AND  casv.party_site_status = cv_active
--         ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- データが存在しない場合
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_14             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_cust_acct_sites_info      -- トークン値1
--                         ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
--                         ,iv_token_value2 => cv_cust_account_number       -- トークン値2
--                         ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
--                         ,iv_token_value3 => gv_withdraw_base_code        -- トークン値3
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--          -- 抽出に失敗した場合
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_15             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_cust_acct_sites_info      -- トークン値1
--                         ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
--                         ,iv_token_value2 => cv_cust_account_number       -- トークン値2
--                         ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
--                         ,iv_token_value3 => gv_withdraw_base_code        -- トークン値3
--                         ,iv_token_name4  => cv_tkn_errmsg                -- トークンコード4
--                         ,iv_token_value4 => SQLERRM                      -- トークン値4
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
--    END IF;
----    
--    -- ===================
--    -- 什器引揚拠点情報取得 
--    -- ===================
----
--    IF (gv_jyki_withdraw_base_code IS NOT NULL) THEN
--      BEGIN
--        SELECT casv.cust_account_id                                     -- アカウントID
--              ,casv.party_site_id                                       -- パーティサイトID
--              ,casv.party_id                                            -- パーティID
--              ,casv.area_code                                           -- 地区コード
--        INTO   gn_jyki_account_id
--              ,gn_jyki_party_site_id
--              ,gn_jyki_party_id
--              ,gv_jyki_area_code
--        FROM   xxcso_cust_acct_sites_v casv                             -- 顧客マスタサイトビュー
--        WHERE  casv.account_number    = gv_jyki_withdraw_base_code
--          AND  casv.account_status    = cv_active
--          AND  casv.acct_site_status  = cv_active
--          AND  casv.party_status      = cv_active
--          AND  casv.party_site_status = cv_active
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- データが存在しない場合
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_14             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_cust_acct_sites_info1     -- トークン値1
--                         ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
--                         ,iv_token_value2 => cv_cust_account_number       -- トークン値2
--                         ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
--                         ,iv_token_value3 => gv_jyki_withdraw_base_code   -- トークン値3
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--          -- 抽出に失敗した場合
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_15             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_cust_acct_sites_info1     -- トークン値1
--                         ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
--                         ,iv_token_value2 => cv_cust_account_number       -- トークン値2
--                         ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
--                         ,iv_token_value3 => gv_jyki_withdraw_base_code   -- トークン値3
--                         ,iv_token_name4  => cv_tkn_errmsg                -- トークンコード4
--                         ,iv_token_value4 => SQLERRM                      -- トークン値4
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
--    END IF;
-- Ver.1.39 Del End
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
   * Procedure Name   : update_in_work_data
   * Description      : 作業データテーブルの物件フラグ更新処理 (A-9)
   ***********************************************************************************/
  PROCEDURE update_in_work_data(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)物件マスタ情報
    ,id_process_date         IN     DATE                    -- 業務処理日付
    /* 2009.06.01 K.Satomura T1_1107対応 START */
    ,iv_skip_flag            IN     VARCHAR2                -- スキップフラグ
    /* 2009.06.01 K.Satomura T1_1107対応 END */
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_in_work_data'; -- プログラム名
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
    cn_work_kbn5               CONSTANT NUMBER          := 5;                -- 引揚
    cv_kbn1                    CONSTANT VARCHAR2(1)     := '1';
    cv_no                      CONSTANT VARCHAR2(1)     := 'N';
    cv_yes                     CONSTANT VARCHAR2(1)     := 'Y';
    cv_update_process          CONSTANT VARCHAR2(100)   := '更新';
    cv_in_work_info            CONSTANT VARCHAR2(100)   := '作業データテーブル';
--
    -- *** ローカル変数 ***
    ln_seq_no                  NUMBER;                  -- シーケンス番号
    ln_slip_num                NUMBER;                  -- 伝票No.
    ln_slip_branch_num         NUMBER;                  -- 伝票枝番
    ln_line_number             NUMBER;                  -- 行番
    ln_job_kbn                 NUMBER;                  -- 作業区分
    ln_rock_slip_num           NUMBER;                  -- ロック用伝票No.
    ln_rock_slip_branch_num    NUMBER;                  -- ロック用伝票枝番
    ln_rock_line_number        NUMBER;                  -- ロック用行番
/* Ver.1.35 Q2198 ADD START */
    ln_last_job_slip_no        NUMBER;                  -- 最終作業伝票No.
/* Ver.1.35 Q2198 ADD END */
    lv_install_code            VARCHAR2(10);            -- 物件コード
    lv_install_code1           VARCHAR2(10);            -- 物件コード１
    lv_install_code2           VARCHAR2(10);            -- 物件コード２
    lv_account_num1            VARCHAR2(10);            -- 顧客コード１
    lv_account_num2            VARCHAR2(10);            -- 顧客コード２
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
--  
    -- データの格納
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_number        := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
/* Ver.1.35 Q2198 ADD START */
    ln_last_job_slip_no   := io_inst_base_data_rec.last_job_slip_no;  -- 最終作業伝票No.
/* Ver.1.35 Q2198 ADD END */
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
--
    -- 作業データ抽出
    BEGIN
--
      SELECT xiwd.slip_no                                             -- 伝票No.
            ,xiwd.slip_branch_no                                      -- 伝票枝番
            ,xiwd.line_number                                         -- 行番号
      INTO   ln_rock_slip_num
            ,ln_rock_slip_branch_num
            ,ln_rock_line_number
      FROM   xxcso_in_work_data xiwd                                  -- 作業データ
      WHERE  xiwd.seq_no         = ln_seq_no
        AND  xiwd.slip_no        = ln_slip_num
        AND  xiwd.slip_branch_no = ln_slip_branch_num
        AND  xiwd.line_number    = ln_line_number
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_27              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => cv_in_work_info               -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_number)       -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_24              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_in_work_info               -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_number)       -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10=> SQLERRM                       -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
    BEGIN
      /* 2009.06.01 K.Satomura T1_1107対応 START */
      IF (NVL(iv_skip_flag, cv_no) = cv_yes) THEN
        UPDATE xxcso_in_work_data xiw -- 作業データ
        /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
        --SET    xiw.process_no_target_flag = cv_yes -- 作業依頼処理対象外フラグ
        SET    xiw.install1_process_no_target_flg = DECODE(lv_install_code
                                                          ,NVL(lv_install_code1, ' '), cv_yes
                                                          ,xiw.install1_process_no_target_flg
                                                          ) -- 物件１作業依頼処理対象外フラグ
              ,xiw.install2_process_no_target_flg = DECODE(lv_install_code
                                                          ,NVL(lv_install_code2, ' '), cv_yes
                                                          ,xiw.install2_process_no_target_flg
                                                          ) -- 物件２作業依頼処理対象外フラグ
        /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
              ,xiw.last_updated_by        = cn_last_updated_by
              ,xiw.last_update_date       = cd_last_update_date
              ,xiw.last_update_login      = cn_last_update_login
              ,xiw.request_id             = cn_request_id
              ,xiw.program_application_id = cn_program_application_id
              ,xiw.program_id             = cn_program_id
              ,xiw.program_update_date    = cd_program_update_date
        WHERE  xiw.seq_no         = ln_seq_no
        AND    xiw.slip_no        = ln_slip_num
        AND    xiw.slip_branch_no = ln_slip_branch_num
        AND    xiw.line_number    = ln_line_number
        ;
        --
      ELSE
      /* 2009.06.01 K.Satomura T1_1107対応 END */
/* Ver.1.35 Q2198 MOD START */
--        -- 物件データの物件コードが作業データの物件コード１と同一の場合は
--        IF (lv_install_code = NVL(lv_install_code1, ' ')) THEN 
        -- 物件データ.物件コード = 作業データの物件コード１
        -- かつ、物件データ.最終作業伝票No = 作業データ.伝票番号の場合
        IF ( lv_install_code = NVL( lv_install_code1 ,' ' ) ) AND
           ( ln_last_job_slip_no = ln_slip_num )
        THEN
/* Ver.1.35 Q2198 MOD END */
--
          -- ==========================================
          -- 物件１処理済フラグを「Y．連携済」に更新 
          -- ==========================================
          UPDATE xxcso_in_work_data                                        -- 作業データ
          SET    install1_processed_flag = cv_yes                         -- 物件１処理済フラグ
                /* 2009.06.01 K.Satomura T1_1107対応 START */
                ,install1_processed_date = id_process_date -- 物件１処理済日
                /* 2009.06.01 K.Satomura T1_1107対応 END */
                ,last_updated_by         = cn_last_updated_by
                ,last_update_date        = cd_last_update_date
                ,last_update_login       = cn_last_update_login
                ,request_id              = cn_request_id
                ,program_application_id  = cn_program_application_id
                ,program_id              = cn_program_id
                ,program_update_date     = cd_program_update_date
          WHERE  seq_no         = ln_seq_no
            AND  slip_no        = ln_slip_num
            AND  slip_branch_no = ln_slip_branch_num
            AND  line_number    = ln_line_number
          ;
--
/* Ver.1.35 Q2198 MOD START */
        -- 物件データの物件コードが作業データの物件コード２と同一の場合は
--        ELSE
        -- 物件データ.物件コード = 作業データの物件コード２
        -- かつ、物件データ.最終作業伝票No = 作業データ.伝票番号の場合
        ELSIF ( lv_install_code = NVL( lv_install_code2 ,' ' ) ) AND
           ( ln_last_job_slip_no = ln_slip_num )
        THEN
/* Ver.1.35 Q2198 MOD END */
--
          -- ==========================================
          -- 物件２処理済フラグを「Y．連携済」に更新 
          -- ==========================================
          -- 作業区分が「5.引揚」の場合の休止処理済フラグの更新→'1'(休止)
          UPDATE xxcso_in_work_data                                          -- 作業データ
          SET    install2_processed_flag = cv_yes                           -- 物件２処理済フラグ
                ,suspend_processed_flag  = (CASE
                                              WHEN job_kbn = cn_work_kbn5 THEN -- 休止処理済フラグ
                                                cv_kbn1
                                              ELSE
                                                suspend_processed_flag
                                            END)
                /* 2009.06.01 K.Satomura T1_1107対応 START */
                ,install2_processed_date = id_process_date -- 物件２処理済日
                /* 2009.06.01 K.Satomura T1_1107対応 END */
                ,last_updated_by         = cn_last_updated_by
                ,last_update_date        = cd_last_update_date
                ,last_update_login       = cn_last_update_login
                ,request_id              = cn_request_id
                ,program_application_id  = cn_program_application_id
                ,program_id              = cn_program_id
                ,program_update_date     = cd_program_update_date
          WHERE  seq_no         = ln_seq_no
            AND  slip_no        = ln_slip_num
            AND  slip_branch_no = ln_slip_branch_num
            AND  line_number    = ln_line_number
          ;
--
        END IF;
--
      /* 2009.06.01 K.Satomura T1_1107対応 START */
      END IF;
      /* 2009.06.01 K.Satomura T1_1107対応 END */
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_25              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_in_work_info               -- トークン値1
                       ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                       ,iv_token_value2  => cv_update_process             -- トークン値2
                       ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                       ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                       ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                       ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                       ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                       ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                       ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6  => lv_install_code1              -- トークン値6
                       ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7  => lv_install_code2              -- トークン値7
                       ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8  => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2            -- トークンコード9
                       ,iv_token_value9 => lv_account_num2                -- トークン値9
                       ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10 => SQLERRM                       -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
  EXCEPTION
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      -- 更新失敗ロールバックフラグの設定。
      gb_rollback_flg := TRUE;
--      
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 更新失敗ロールバックフラグの設定。
      gb_rollback_flg := TRUE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_in_work_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_instances
   * Description      : 物件情報抽出 (A-4)
   ***********************************************************************************/
  PROCEDURE get_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype          -- (IN)物件マスタ情報
    ,id_process_date         IN     DATE                             -- 業務処理日付
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
-- Ver.1.37 Add Start
    cn_jon_kbn_0             CONSTANT NUMBER := 0;  -- 納品
-- Ver.1.37 Add End
    cn_jon_kbn_1             CONSTANT NUMBER := 1;  -- 新台設置
    cn_jon_kbn_2             CONSTANT NUMBER := 2;  -- 旧台設置
    cn_jon_kbn_3             CONSTANT NUMBER := 3;  -- 新台代替
    cn_jon_kbn_4             CONSTANT NUMBER := 4;  -- 旧台代替
    cn_jon_kbn_5             CONSTANT NUMBER := 5;  -- 引揚
    /* 2009.05.18 K.Satomura T1_0959対応 START */
    cn_jon_kbn_6             CONSTANT NUMBER := 6;  -- 店内移動
    /* 2009.05.18 K.Satomura T1_0959対応 END */
    cv_flg_n                 CONSTANT VARCHAR2(1) := 'N';  -- 新古台フラグ
    cv_flg_y                 CONSTANT VARCHAR2(1) := 'Y';  -- 新古台フラグ
    cv_csi_item_instances    CONSTANT VARCHAR2(100) := 'インストールベースマスタ';  
    /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
    cv_cust_mst_info         CONSTANT VARCHAR2(100) := '顧客マスタ情報';
    --
    cv_zero                  CONSTANT VARCHAR2(1) := '0';
    cn_cmplt                 CONSTANT NUMBER(1)   := 1;
    cb_true                  CONSTANT BOOLEAN     := TRUE;
    cb_false                 CONSTANT BOOLEAN     := FALSE;
    /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
/* Ver.1.34 ADD START */
    -- 追加属性
    cv_last_act_dt           CONSTANT VARCHAR2(18) := 'LAST_ACT_DATE_TIME';
/* Ver.1.34 ADD END */
--
    -- *** ローカル変数 ***
    ln_job_kbn               NUMBER;                    -- 作業区分
    lv_install_code          VARCHAR2(10);              -- 物件コード
    lv_install_code1         VARCHAR2(10);              -- 物件コード１
    lv_install_code2         VARCHAR2(10);              -- 物件コード２
    lv_external_reference    VARCHAR2(10);              -- 外部参照
    lv_new_old_flag          csi_item_instances.attribute5%type;  -- 新古台フラグ
/* Ver.1.34 DEL START */
--    lv_last_po_req_number    csi_item_instances.attribute6%type;  -- 最終発注依頼番号
--    lv_po_req_number         NUMBER;                    -- 発注依頼番号
/* Ver.1.34 DEL END */
    /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START*/
    ln_seq_no                NUMBER;                    -- シーケンス番号
    ln_slip_no               NUMBER;                    -- 伝票No.
    /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END*/
    /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
    lt_actual_work_date      xxcso_in_work_data.actual_work_date%TYPE;
    lt_actual_work_time1     xxcso_in_work_data.actual_work_time1%TYPE;
    lt_acct_num              xxcso_cust_acct_sites_v.account_number%TYPE;
    lb_chk_flg               BOOLEAN DEFAULT FALSE;
    /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
/* Ver.1.34 ADD START */
    ld_last_act_date         DATE;                      -- 最終有効実作業日時
/* Ver.1.34 ADD END */
--
    -- *** ローカル例外 ***
    skip_process_expt       EXCEPTION;
    /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
    skip_process_expt_2     EXCEPTION;
    call_gb_prcss_expt      EXCEPTION;
    call_skp_prcss_expt     EXCEPTION;
    /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
    /* 2009.05.18 K.Satomura T1_1066対応 START */
    --/*20090507_mori_T1_0530 START*/
    --shindai_chk_expt       EXCEPTION;
    --/*20090507_mori_T1_0530 END*/
    /* 2009.05.18 K.Satomura T1_1066対応 END */
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- データの格納
    ln_job_kbn        := io_inst_base_data_rec.job_kbn;
    lv_install_code   := io_inst_base_data_rec.install_code;
    lv_install_code1  := io_inst_base_data_rec.install_code1;
    lv_install_code2  := io_inst_base_data_rec.install_code2;
/* Ver.1.34 DEL START */
--    lv_po_req_number  := io_inst_base_data_rec.po_req_number;
/* Ver.1.34 DEL END */
    /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START*/
    ln_seq_no         := io_inst_base_data_rec.seq_no;        -- シーケンス番号
    ln_slip_no        := io_inst_base_data_rec.slip_no;       -- 伝票No.
    /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END*/
--
    -- 物件情報抽出
    BEGIN
      SELECT ciins.external_reference                                 -- 外部参照
            ,ciins.instance_id                                        -- インスタンスID
            ,ciins.object_version_number                              -- オブジェクトバージョン
            ,ciins.instance_status_id                                 -- インスタンスステータスID
            ,ciins.attribute5                                         -- 新古台フラグ
/* Ver.1.34 DEL START */
--            ,ciins.attribute6                                         -- 最終発注依頼番号
/* Ver.1.34 DEL END */
            /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
            ,ciins.attribute1                                         -- 機種CD
            /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */
/* Ver.1.34 ADD START */
            ,TO_DATE( xxcso_ib_common_pkg.get_ib_ext_attribs(
                         ciins.instance_id
                       , cv_last_act_dt
                      )
                       , 'yyyy/mm/dd hh24:mi:ss' )  last_act_date     -- 最終有効実作業日時
/* Ver.1.34 ADD END */
      INTO   lv_external_reference
            ,io_inst_base_data_rec.instance_id
            ,io_inst_base_data_rec.object_version1
            ,io_inst_base_data_rec.instance_status_id
            ,lv_new_old_flag
/* Ver.1.34 DEL START */
--            ,lv_last_po_req_number
/* Ver.1.34 DEL END */
            /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
            ,io_inst_base_data_rec.ib_un_number                       -- IB機種CD
            /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */
/* Ver.1.34 ADD START */
            ,ld_last_act_date                                         -- 最終有効実作業日時
/* Ver.1.34 ADD END */
      FROM   csi_item_instances ciins                                 -- 物件マスタ
      WHERE  ciins.external_reference = lv_install_code
      ;
      io_inst_base_data_rec.new_old_flg := SUBSTR(lv_new_old_flag, 1, 1);
      /* 2009.05.19 K.Satomur T1_0959,T1_1066対応 START */
      --/*20090507_mori_T1_0530 START*/
      ---- 作業区分が「新台設置」、「新台代替」、かつ作業データの物件コード１が
      ---- 物件データの物件コードと一致であり、新古台フラグが'Y'以外である場合、
      ---- 既に存在する新古台以外の物件が新台として連携されているため、エラーとする。
      --IF (
      --        (ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3)
      --    AND (lv_install_code = NVL(lv_install_code1, ' '))
      --    AND (NVL(io_inst_base_data_rec.new_old_flg, cv_flg_n) <> cv_flg_y)
      --   ) THEN
      --  RAISE shindai_chk_expt;
      --END IF;
      --/*20090507_mori_T1_0530 END*/
--
      --IF (lv_po_req_number < lv_last_po_req_number) THEN
      --  RAISE shindai_chk_expt;
      --END IF;
--
/* Ver.1.34 MOD START */
--      /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
--      -- 最終発注依頼番号がNULLまたは'0'の場合
--      IF (( lv_last_po_req_number IS NULL )
--        OR ( lv_last_po_req_number = cv_zero )) THEN
----
--        NULL;
--      -- 最終発注依頼番号がNOT NULLで且つ'0'でない場合
--      ELSE
--        lb_chk_flg := cb_true;
--        -- 当該物件データの前回実作業日、実作業時間１を取得
--        BEGIN
--          SELECT   xiwd1.actual_work_date    actual_work_date  -- 実作業日
--                  ,xiwd1.actual_work_time1   actual_work_time1 -- 実作業時間１
--          INTO     lt_actual_work_date
--                  ,lt_actual_work_time1
--          FROM     xxcso_in_work_data xiwd1                    -- 作業データテーブル(1)
--          WHERE    xiwd1.seq_no           =  ( SELECT   MAX(xiwd2.seq_no)
--                                               FROM     xxcso_in_work_data xiwd2    -- 作業データテーブル(2)
--                                               WHERE    xiwd2.po_req_number    =  TO_NUMBER(lv_last_po_req_number)
--                                                 AND    xiwd2.completion_kbn   =  cn_cmplt
--                                             )
--          ;
----
--        EXCEPTION
--          WHEN OTHERS THEN
--           -- 取得できない場合は、スキップのチェックはしない
--           lb_chk_flg := cb_false;
--        END;
--      END IF;
----
--      IF (lb_chk_flg = cb_true) THEN
--      --IF (ln_job_kbn IN (cn_jon_kbn_1, cn_jon_kbn_2, cn_jon_kbn_3, cn_jon_kbn_4, cn_jon_kbn_5, cn_jon_kbn_6)) THEN
--      ---- 作業区分が１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動の場合
--      --  IF (lv_po_req_number < lv_last_po_req_number) THEN
----
--        -- 当該処理作業データの実作業日 || 実作業時間１ ＜ 最終発注依頼番号より取得した前回実作業日 || 実作業時間１
--        -- の場合、作業データ取込処理をスキップします。
--        IF (( TO_CHAR(io_inst_base_data_rec.actual_work_date) || io_inst_base_data_rec.actual_work_time1 )
--               < ( TO_CHAR(lt_actual_work_date) || lt_actual_work_time1 )) THEN
--      /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
      --物件に保持している最終有効実作業日時 > 作業ワークの実作業日+実作業時間の場合（作業が逆転している場合）
      IF ( ld_last_act_date IS NOT NULL)
/* Ver.1.35 Q2239 ADD START */
        -- 作業区分が１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動の場合
        AND ( ln_job_kbn IN ( cn_jon_kbn_1 ,cn_jon_kbn_2 ,cn_jon_kbn_3 ,cn_jon_kbn_4 ,cn_jon_kbn_5 ,cn_jon_kbn_6 ) )
/* Ver.1.35 Q2239 ADD END */
        AND ( ld_last_act_date >
              TO_DATE( TO_CHAR(io_inst_base_data_rec.actual_work_date) || io_inst_base_data_rec.actual_work_time1, 'yyyy/mm/dd hh24:mi:ss')
      ) THEN
/* Ver.1.34 MOD END */
        /* 2009.06.01 K.Satomura T1_1107対応 START */
        update_in_work_data(
           io_inst_base_data_rec => io_inst_base_data_rec -- (IN)物件マスタ情報
          ,id_process_date       => id_process_date       -- 業務処理日付
          ,iv_skip_flag          => cv_flg_y              -- スキップフラグ
          ,ov_errbuf             => lv_errbuf             -- エラー・メッセージ            --# 固定 #
          ,ov_retcode            => lv_retcode            -- リターン・コード              --# 固定 #
          ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE skip_process_expt;
        END IF;
        /* 2009.06.01 K.Satomura T1_1107対応 END */
        RAISE skip_process_expt;
        --
      END IF;
      --
/* Ver.1.34 DEL START */
--      END IF;
/* Ver.1.34 DEL END */
      /* 2009.05.18 K.Satomura T1_0959,T1_1066対応 END */
      /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
--
      IF (ln_job_kbn NOT IN (cn_jon_kbn_1, cn_jon_kbn_2, cn_jon_kbn_3, cn_jon_kbn_4, cn_jon_kbn_5, cn_jon_kbn_6)) THEN
      -- 作業区分が１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動 以外の場合
--
        -- ============================
        -- 顧客情報存在チェック
        -- ============================
        BEGIN
          SELECT casv.account_number                                 -- 顧客コード
          INTO   lt_acct_num
          FROM   xxcso_cust_acct_sites_v casv                               -- 顧客マスタサイトビュー
                ,csi_item_instances      ciis                               -- インストールベースマスタ
          WHERE  ciis.external_reference     = lv_install_code
            AND  ciis.owner_party_account_id = casv.cust_account_id
            AND  casv.account_status         = cv_active
            AND  casv.acct_site_status       = cv_active
            AND  casv.party_status           = cv_active
            AND  casv.party_site_status      = cv_active
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- データが存在しない場合
--
            update_in_work_data(
               io_inst_base_data_rec => io_inst_base_data_rec -- (IN)物件マスタ情報
              ,id_process_date       => id_process_date       -- 業務処理日付
              ,iv_skip_flag          => cv_flg_y              -- スキップフラグ
              ,ov_errbuf             => lv_errbuf             -- エラー・メッセージ            --# 固定 #
              ,ov_retcode            => lv_retcode            -- リターン・コード              --# 固定 #
              ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ  --# 固定 #
            );
--
            IF (lv_retcode = cv_status_error) THEN
              RAISE call_gb_prcss_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              RAISE call_skp_prcss_expt;
            END IF;
--
            RAISE skip_process_expt_2;
            -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                                     -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_24                                -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                                  -- トークンコード1
                           ,iv_token_value1 => cv_cust_mst_info                                -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                                   -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)                              -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num                                 -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_no)                             -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num                          -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(io_inst_base_data_rec.slip_branch_no)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num                                 -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(io_inst_base_data_rec.line_number)      -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                                  -- トークンコード6
                           ,iv_token_value6 => io_inst_base_data_rec.install_code1             -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                                  -- トークンコード7
                           ,iv_token_value7 => io_inst_base_data_rec.install_code2             -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1                             -- トークンコード8
                           ,iv_token_value8 => io_inst_base_data_rec.account_number1           -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2                             -- トークンコード9
                           ,iv_token_value9 => io_inst_base_data_rec.account_number2           -- トークン値9
                           ,iv_token_name10 => cv_tkn_errmsg                                   -- トークンコード10
                           ,iv_token_value10=> SQLERRM                                         -- トークン値10
                         );
            lv_errbuf := lv_errmsg;
            RAISE call_skp_prcss_expt;
        END;
--
      END IF;
      /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
      /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
      -----------------------------------------------------
      --機種CDの設定
      --1.新台物件かつ同一物件CDがEBSに存在しない場合
      --     ･･･自販機Sからの物件マスタの機種CDを使用
      --2.新台物件かつ同一物件CDがEBSに存在する場合
      --     ･･･自販機Sからの物件マスタの機種CDを使用
      --3.上記以外の場合
      --     ･･･EBSインストールベースの機種CDを使用
      -----------------------------------------------------
      -- 作業区分が「新台設置」、「新台代替」、かつ作業データの物件コード１が
      -- 物件データの物件コードと一致である場合
      IF ((ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3)
               AND lv_install_code = NVL(lv_install_code1, ' ')) THEN
        --ケース2
        NULL;
      ELSE
        --ケース3
        io_inst_base_data_rec.un_number := io_inst_base_data_rec.ib_un_number;
      END IF;
      /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */

    EXCEPTION
    /* 2009.05.18 K.Satomura T1_1066対応 START */
    --/*20090507_mori_T1_0530 START*/
    --  -- 新台、新古台以外の物件が新台設置／新台代替として連携された場合
    --  WHEN shindai_chk_expt THEN
    --    -- エラーメッセージ作成
    --    lv_errmsg := xxccp_common_pkg.get_msg(
    --                    iv_application  => cv_app_name                            -- アプリケーション短縮名
    --                   ,iv_name         => cv_tkn_number_33                       -- メッセージコード
    --                   ,iv_token_name1  => cv_tkn_slip_num                        -- トークンコード1
    --                   ,iv_token_value1 => io_inst_base_data_rec.slip_no          -- トークン値1
    --                   ,iv_token_name2  => cv_tkn_slip_branch_num                 -- トークンコード2
    --                   ,iv_token_value2 => io_inst_base_data_rec.slip_branch_no   -- トークン値2
    --                   ,iv_token_name3  => cv_tkn_line_num                        -- トークンコード3
    --                   ,iv_token_value3 => io_inst_base_data_rec.line_number      -- トークン値3
    --                   ,iv_token_name4  => cv_tkn_work_kbn                        -- トークンコード4
    --                   ,iv_token_value4 => io_inst_base_data_rec.job_kbn          -- トークン値4
    --                   ,iv_token_name5  => cv_tkn_bukken1                         -- トークンコード5
    --                   ,iv_token_value5 => io_inst_base_data_rec.install_code1    -- トークン値5
    --                   ,iv_token_name6  => cv_tkn_account_num1                    -- トークンコード6
    --                   ,iv_token_value6 => io_inst_base_data_rec.account_number1  -- トークン値6
    --                 );
    --    lv_errbuf := lv_errmsg;
    --    RAISE skip_process_expt;
    --/*20090507_mori_T1_0530 END*/
    /* 2009.05.18 K.Satomura T1_1066対応 END */
      -- データなし
      WHEN NO_DATA_FOUND THEN
        -- 作業区分が「新台設置」、「新台代替」、かつ作業データの物件コード１が
        -- 物件データの物件コードと一致である場合
        -- または作業区分が「納品」かつ作業データの物件コード２（引揚用）が物件データの物件コードと一致である場合
-- Ver.1.37 Mod Start
--        IF ((ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3)
--               AND lv_install_code = NVL(lv_install_code1, ' ')) THEN 
        IF (((ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3)
               AND lv_install_code = NVL(lv_install_code1, ' '))
            OR
            (ln_job_kbn = cn_jon_kbn_0 
               AND lv_install_code = NVL(lv_install_code2, ' '))) THEN
-- Ver.1.37 Mod End
          -- 物件の新規登録フラグを「TRUE」に設定
          gb_insert_process_flg := TRUE;
--        
        ELSE
          -- 物件存在チェック警告
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_17             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_bukken                -- トークンコード1
                         ,iv_token_value1 => lv_install_code              -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
        END IF;
      -- 物件更新チェック警告
      WHEN skip_process_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_18             -- メッセージコード
                       /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START*/
                       --,iv_token_name1  => cv_tkn_bukken                -- トークンコード1
                       --,iv_token_value1 => lv_install_code              -- トークン値1
                       --,iv_token_name2  => cv_tkn_last_req_no           -- トークンコード2
                       --,iv_token_value2 => lv_last_po_req_number        -- トークン値2
                       --,iv_token_name3  => cv_tkn_req_no                -- トークンコード3
                       --,iv_token_value3 => lv_po_req_number             -- トークン値3
                       ,iv_token_name1  => cv_tkn_seq_no                -- トークンコード1
                       ,iv_token_value1 => ln_seq_no                    -- トークン値1
                       ,iv_token_name2  => cv_tkn_slip_num              -- トークンコード2
                       ,iv_token_value2 => ln_slip_no                   -- トークン値2
                       ,iv_token_name3  => cv_tkn_bukken                -- トークンコード3
                       ,iv_token_value3 => lv_install_code              -- トークン値3
/* Ver.1.34 DEL START */
--                       ,iv_token_name4  => cv_tkn_last_req_no           -- トークンコード3
--                       ,iv_token_value4 => lv_last_po_req_number        -- トークン値3
--                       ,iv_token_name5  => cv_tkn_req_no                -- トークンコード3
--                       ,iv_token_value5 => lv_po_req_number             -- トークン値3
/* Ver.1.34 DEL END */
                       /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END*/
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
      /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
      WHEN call_gb_prcss_expt THEN
        RAISE global_process_expt;
--
      WHEN skip_process_expt_2 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_34             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_seq_no                -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(ln_seq_no)           -- トークン値1
                       ,iv_token_name2  => cv_tkn_slip_num              -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_slip_no)          -- トークン値2
                       ,iv_token_name3  => cv_tkn_work_kbn              -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_job_kbn)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_bukken                -- トークンコード3
                       ,iv_token_value4 => lv_install_code              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
--
      WHEN call_skp_prcss_expt THEN
        RAISE skip_process_expt;
--
      /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_19             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_csi_item_instances        -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                       ,iv_token_value2 => lv_install_code              -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
  EXCEPTION
    -- *** スキップ処理例外ハンドラ ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
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
  END get_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : insert_item_instances
   * Description      : 物件データ登録処理 (A-5)
   ***********************************************************************************/
  PROCEDURE insert_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)物件マスタ情報
    ,id_process_date         IN     DATE                    -- 業務処理日付
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
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
    cn_num0                  CONSTANT NUMBER        := 0;
    cn_num1                  CONSTANT NUMBER        := 1;
    cn_num2                  CONSTANT NUMBER        := 2;
    cn_num3                  CONSTANT NUMBER        := 3;
    cn_num4                  CONSTANT NUMBER        := 4;
    cn_num9                  CONSTANT NUMBER        := 9;
-- Ver.1.37 Add Start
    cn_jon_kbn_0             CONSTANT NUMBER        := 0;                   -- 納品
-- Ver.1.37 Add End
    cn_jon_kbn_1             CONSTANT NUMBER        := 1;                   -- 新台設置
    cn_jon_kbn_2             CONSTANT NUMBER        := 2;                   -- 旧台設置
    cn_jon_kbn_3             CONSTANT NUMBER        := 3;                   -- 新台代替
    cn_jon_kbn_4             CONSTANT NUMBER        := 4;                   -- 旧台代替
    cn_jon_kbn_5             CONSTANT NUMBER        := 5;                   -- 引揚
/* Ver.1.35 Q2239 ADD START */
    cn_job_kbn_6             CONSTANT NUMBER        := 6;                   -- 店内移動
/* Ver.1.35 Q2239 ADD END */
    cn_api_version           CONSTANT NUMBER        := 1.0;
    cv_kbn0                  CONSTANT NUMBER        := '0';
    cv_kbn1                  CONSTANT VARCHAR2(1)   := '1'; 
    cv_kbn2                  CONSTANT VARCHAR2(1)   := '2'; 
    cv_lease_type_own        CONSTANT VARCHAR2(1)   := '1';                 -- 自社リース
    cv_unit_of_measure       CONSTANT VARCHAR2(10)  := '台';                -- 単位み
    /*2010.03.01 K.Hosoi E_本稼動_01761対応 START*/
    --cv_approved              CONSTANT VARCHAR2(10)  := 'APPROVED';          -- 承認済み
    /*2010.03.01 K.Hosoi E_本稼動_01761対応 END*/
    cv_cust_mst_info         CONSTANT VARCHAR2(100) := '顧客マスタ情報';    -- 抽出内容
    cv_po_un_numbers_info    CONSTANT VARCHAR2(100) := '国連番号マスタ(機種コードマスタ)情報';    -- 抽出内容
    cv_mfg_fctory_maker_nm   CONSTANT VARCHAR2(100) := '参照タイプのメーカー名';
    cv_xxcso_ib_info_h       CONSTANT VARCHAR2(100) := '物件関連情報変更履歴テーブル';    -- 抽出内容
    cv_inst_base_insert      CONSTANT VARCHAR2(100) := 'インストールベースマスタ';
    cv_insert_process        CONSTANT VARCHAR2(100) := '登録';
    cv_machinery_status      CONSTANT VARCHAR2(100) := '物件データワークテーブルの機器状態'; 
    cv_owner_cmp_info        CONSTANT VARCHAR2(100) := '参照タイプの本社/工場区分';
    cv_location_type_code    CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';    -- 現行事業所タイプ
    cv_instance_usage_code   CONSTANT VARCHAR2(100) := 'OUT_OF_ENTERPRISE'; -- インスタンス使用コード
    cv_party_source_table    CONSTANT VARCHAR2(100) := 'HZ_PARTIES';        -- パーティソーステーブル
    cv_relatnsh_type_code    CONSTANT VARCHAR2(100) := 'OWNER';             -- リレーションタイプ
    cv_xxcso1_owner_company  CONSTANT VARCHAR2(100) := 'XXCSO1_OWNER_COMPANY';
    cv_xxcff_owner_company   CONSTANT VARCHAR2(100) := 'XXCFF_OWNER_COMPANY';
    cv_xxcso_csi_maker_code  CONSTANT VARCHAR2(100) := 'XXCSO_CSI_MAKER_CODE';
    cv_mfg_fctory_maker_cd   CONSTANT VARCHAR2(100) := 'メーカーコード ';
    cv_flg_no                CONSTANT VARCHAR2(1) := 'N';                 -- フラグNO
    cv_flg_yes               CONSTANT VARCHAR2(1) := 'Y';                 -- フラグYES
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
/* Ver.1.34 DEL START */
--    cv_get_po_data             CONSTANT VARCHAR2(100) := '発注データ';              -- 抽出内容名（発注データ）
/* Ver.1.34 DEL END */
    cv_lease_kbn               CONSTANT VARCHAR2(100) := 'リース区分(新規)';        -- 取得内容名
    cv_get_price               CONSTANT VARCHAR2(100) := '取得価格(新規)';          -- 取得内容名
    cv_dclr_place              CONSTANT VARCHAR2(100) := '申告地コード(新規)';      -- 取得内容名
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */
--
    -- *** ローカル変数 ***
    ld_date                    DATE;                    -- 業務処理日付格納用('yyyymmdd'形式)
    /*2009.09.03 M.Maruyama 0001192対応 START*/
    ld_actual_work_date        DATE;                    -- 実作業日('yyyymmdd'形式)
    /*2009.09.03 M.Maruyama 0001192対応 END*/
    ld_install_date            DATE;                    -- 導入日
    ln_cnt                     NUMBER;                  -- カウント数
    ln_seq_no                  NUMBER;                  -- シーケンス番号
    ln_slip_num                NUMBER;                  -- 伝票No.
    ln_slip_branch_num         NUMBER;                  -- 伝票枝番
    ln_line_num                NUMBER;                  -- 行番
    ln_job_kbn                 NUMBER;                  -- 作業区分
    ln_instance_status_id      NUMBER;                  -- インスタンスステータスID
    ln_machinery_status1       NUMBER;                  -- 機器状態1（稼動状態）
    ln_machinery_status2       NUMBER;                  -- 機器状態2（状態詳細）
    ln_machinery_status3       NUMBER;                  -- 機器状態3（廃棄情報）
    ln_account_id              NUMBER;                  -- アカウントID
    ln_party_site_id           NUMBER;                  -- パーティサイトID
    ln_party_id                NUMBER;                  -- パーティID
    lv_area_code               VARCHAR2(100);           -- 地区コード
    ln_delete_flag             NUMBER;                  -- 削除フラグ
    ln_machinery_kbn           NUMBER;                  -- 機器区分
    ln_validation_level        NUMBER;                  -- バリデーションレーベル
    ln_loop_cnt                NUMBER;                  -- ループ用変数
    lv_commit                  VARCHAR2(1);             -- コミットフラグ
    lv_lease_type              VARCHAR2(240);           -- リース区分
    lv_install_code            VARCHAR2(10);            -- 物件コード
    lv_install_code1           VARCHAR2(10);            -- 物件コード１
    lv_install_code2           VARCHAR2(10);            -- 物件コード２
    lv_account_num1            VARCHAR2(10);            -- 顧客コード１
    lv_account_num2            VARCHAR2(10);            -- 顧客コード２
    lv_un_number               VARCHAR2(20);            -- 機種
    lv_install_number          VARCHAR2(20);            -- 機番
    lv_base_code               VARCHAR2(4);             -- 拠点コード
    /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
    --lv_install_name            VARCHAR2(30);            -- 設置先名
    lv_install_name            xxcso_cust_acct_sites_v.party_name%TYPE; -- 設置先名
    /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
    /*20090325_yabuki_ST147 START*/
    --lv_install_address         VARCHAR2(540);           -- 設置先住所
    lv_install_address         VARCHAR2(600);           -- 設置先住所
    /*20090325_yabuki_ST147 END*/
    lv_owner_cmp_flag          VARCHAR2(1);             -- 本社/工場フラグ
    lv_owner_cmp_type          VARCHAR2(150);           -- 本社/工場区分
    lv_owner_cmp_name          VARCHAR2(10);            -- 本社/工場区分名
    lv_init_msg_list           VARCHAR2(2000);          -- メッセージリスト
    lv_first_install_date      VARCHAR2(20);            -- 初回設置日
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
    lv_get_price               VARCHAR2(10);                                        -- 取得価格(設定用)
    lv_dclr_place              VARCHAR2(5);                                         -- 申告地(設定用)
/* Ver.1.34 DEL START */
--    lt_lease_type_po           po_distributions_all.attribute1%TYPE;                -- リース区分（発注）
--    lt_lease_type_un_numbers   po_un_numbers_vl.attribute13%TYPE;                   -- リース区分（機種マスタ）
--    lt_get_price_po            po_distributions_all.attribute2%TYPE;                -- 取得価格（発注）
--    lt_get_price_un_numbers    po_un_numbers_vl.attribute14%TYPE;                   -- 取得価格（機種マスタ）
--    lt_dclr_place_req          xxcso_requisition_lines_v.declaration_place%TYPE;    -- 申告地(発注依頼)
--    lt_dclr_place_po           po_distributions_all.attribute3%TYPE;                -- 申告地(発注)
/* Ver.1.34 DEL END */
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */

    lv_manufacturer_name       xxcso_ib_info_h.manufacturer_name%type;     -- メーカー名
    lv_manufacturer_code       po_un_numbers_b.attribute2%type;            -- メーカーコード
    lv_age_type                po_un_numbers_b.attribute3%type;            -- 年式
    lv_hazard_class            po_hazard_classes_tl.hazard_class%type;      -- 機器区分（危険度区分）

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
    skip_process_expt          EXCEPTION;
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- データの格納
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
    ld_date               := TRUNC(id_process_date);
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    ln_delete_flag        := io_inst_base_data_rec.delete_flag;
    ln_machinery_status1  := io_inst_base_data_rec.machinery_status1;
    ln_machinery_status2  := io_inst_base_data_rec.machinery_status2;
    ln_machinery_status3  := io_inst_base_data_rec.machinery_status3;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
    ln_machinery_kbn      := io_inst_base_data_rec.machinery_kbn;
    lv_un_number          := io_inst_base_data_rec.un_number;
    lv_install_number     := io_inst_base_data_rec.install_number;
    /*2009.09.03 M.Maruyama 0001192対応 START*/
    ld_actual_work_date   := TO_DATE(io_inst_base_data_rec.actual_work_date,'YYYY/MM/DD');
    /*2009.09.03 M.Maruyama 0001192対応 END*/
 --
/* Ver.1.34 DEL START */
--    -- =================
--    -- 1.リース区分抽出
--    -- =================
----
--    -- 1-1.発注搬送からリース区分、申告地、取得価格を取得
--    BEGIN
--      /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 mod START */
----      SELECT   prlv.lease_type             lease_type                       -- リース区分(発注依頼)
--      SELECT   flvv.lookup_code            lease_type                       -- リース区分(発注依頼)
--      /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 mod END   */
--              /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
--              ,pd.attribute1               lease_type_po                    -- リース区分(発注)
--              ,pd.attribute2               get_price_po                     -- 取得価格(発注)
--              ,prlv.declaration_place      declaration_place                -- 申告地(発注依頼)
--              ,pd.attribute3               declaration_place_po             -- 申告地(発注)
--              /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */
--      INTO     lv_lease_type
--              /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
--              ,lt_lease_type_po
--              ,lt_get_price_po
--              ,lt_dclr_place_req
--              ,lt_dclr_place_po
--              /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */
--      FROM     xxcso_requisition_lines_v   prlv                             -- 発注依頼明細情報ビュー
--              ,po_requisition_headers_all  prh                              -- 発注依頼ヘッダビュー
--              /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
--              ,po_req_distributions_all    prd                              -- 発注依頼搬送明細ビュー
--              ,po_distributions_all        pd                               -- 発注搬送明細ビュー
--              ,po_lines_all                pl
--              ,fnd_lookup_values_vl        flvv
--              /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */
--      /*2010.03.01 K.Hosoi E_本稼動_01761対応 START*/
--      --WHERE    prh.segment1               = io_inst_base_data_rec.po_req_number
--      --  AND    prh.authorization_status   = cv_approved
--      WHERE    prh.segment1               = TO_CHAR(io_inst_base_data_rec.po_req_number)
--      /*2010.03.01 K.Hosoi E_本稼動_01761対応 END*/
--        AND    prlv.requisition_header_id = prh.requisition_header_id
--        /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
--        AND    prlv.requisition_line_id   = prd.requisition_line_id
--        AND    prd.distribution_id        = pd.req_distribution_id
--        AND    pd.po_line_id              = pl.po_line_id
--        AND    prlv.lease_type            = flvv.attribute1(+)
--        AND    flvv.lookup_type(+)        = cv_xxcs01_lease_kbn
--        AND    (ld_date BETWEEN(NVL(flvv.start_date_active, ld_date)) AND
--                 TRUNC(NVL(flvv.end_date_active, ld_date)))
--        AND    NVL( flvv.enabled_flag, cv_flg_yes) = cv_flg_yes
--        /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */
--        AND    prlv.line_num              = io_inst_base_data_rec.line_num
--        AND    (ld_date BETWEEN(NVL(prlv.lookup_start_date, ld_date)) AND
--                 TRUNC(NVL(prlv.lookup_end_date, ld_date)))
--        AND    (ld_date BETWEEN(NVL(prlv.category_start_date, ld_date)) AND
--                 TRUNC(NVL(prlv.category_end_date, ld_date)))
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        -- 発注データなし警告
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name                   -- アプリケーション短縮名
--                       ,iv_name         => cv_tkn_number_20              -- メッセージコード
--                       /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 mod START */
----                       ,iv_token_name1  => cv_tkn_seq_no                 -- トークンコード1
----                       ,iv_token_value1 => TO_CHAR(ln_seq_no)            -- トークン値1
----                       ,iv_token_name2  => cv_tkn_slip_num               -- トークンコード2
----                       ,iv_token_value2 => TO_CHAR(ln_slip_num)          -- トークン値2
----                       ,iv_token_name3  => cv_tkn_slip_branch_num        -- トークンコード3
----                       ,iv_token_value3 => TO_CHAR(ln_slip_branch_num)   -- トークン値3
----                       ,iv_token_name4  => cv_tkn_line_num               -- トークンコード4
----                       ,iv_token_value4 => TO_CHAR(ln_line_num)          -- トークン値4
----                       ,iv_token_name5  => cv_tkn_work_kbn               -- トークンコード5
----                       ,iv_token_value5 => TO_CHAR(ln_job_kbn)           -- トークン値5
----                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
----                       ,iv_token_value6 => lv_install_code1              -- トークン値6
----                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
----                       ,iv_token_value7 => lv_install_code2              -- トークン値7
--                       ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                       ,iv_token_value1 => cv_get_po_data                -- トークン値1
--                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
--                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
--                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
--                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
--                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
--                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
--                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
--                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
--                       ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
--                       ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
--                       ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
--                       ,iv_token_value7 => lv_install_code1              -- トークン値7
--                       ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
--                       ,iv_token_value8 => lv_install_code2              -- トークン値8
--                       /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 mod END */
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE skip_process_expt;
--        -- 抽出に失敗した場合
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name                   -- アプリケーション短縮名
--                       ,iv_name         => cv_tkn_number_21              -- メッセージコード
--                       /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 mod START */
----                       ,iv_token_name1  => cv_tkn_seq_no                 -- トークンコード1
----                       ,iv_token_value1 => TO_CHAR(ln_seq_no)            -- トークン値1
----                       ,iv_token_name2  => cv_tkn_slip_num               -- トークンコード2
----                       ,iv_token_value2 => TO_CHAR(ln_slip_num)          -- トークン値2
----                       ,iv_token_name3  => cv_tkn_slip_branch_num        -- トークンコード3
----                       ,iv_token_value3 => TO_CHAR(ln_slip_branch_num)   -- トークン値3
----                       ,iv_token_name4  => cv_tkn_line_num               -- トークンコード4
----                       ,iv_token_value4 => TO_CHAR(ln_line_num)          -- トークン値4
----                       ,iv_token_name5  => cv_tkn_work_kbn               -- トークンコード5
----                       ,iv_token_value5 => TO_CHAR(ln_job_kbn)           -- トークン値5
----                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
----                       ,iv_token_value6 => lv_install_code1              -- トークン値6
----                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
----                       ,iv_token_value7 => lv_install_code2              -- トークン値7
----                       ,iv_token_name8  => cv_tkn_errmsg                 -- トークンコード8
----                       ,iv_token_value8 => SQLERRM                       -- トークン値8
--                       ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                       ,iv_token_value1 => cv_get_po_data                -- トークン値1
--                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
--                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
--                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
--                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
--                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
--                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
--                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
--                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
--                       ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
--                       ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
--                       ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
--                       ,iv_token_value7 => lv_install_code1              -- トークン値7
--                       ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
--                       ,iv_token_value8 => lv_install_code2              -- トークン値8
--                       ,iv_token_name9  => cv_tkn_errmsg                 -- トークンコード9
--                       ,iv_token_value9 => SQLERRM                       -- トークン値9
--                       /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 mod END */
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE skip_process_expt;
--    END;
/* Ver.1.34 DEL END */
--
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 del START */
--    lv_lease_type := SUBSTR(lv_lease_type, cn_num1, cn_num1);
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 del END   */
    -- ========================
    -- 2.機器状態整合性チェック
    -- ========================
-- 
    -- 削除フラグが「９：論理削除」の場合
    IF (ln_delete_flag = cn_num9) THEN
      ln_instance_status_id := gt_instance_status_id_6;
    -- 機器状態１が「１：稼動中」の場合
    ELSIF (ln_machinery_status1 = cn_num1) THEN
      ln_instance_status_id := gt_instance_status_id_1;
    -- 作業区分が「０：納品」以外
    -- 機器状態１が「２：滞留」
    -- 機器状態２が「０：情報無」または「１：整備済」
    -- 機器状態３が「０：予定無し」の場合
-- Ver.1.37 Mod Start
--   ELSIF (ln_machinery_status1 = cn_num2
    ELSIF (  ln_job_kbn <> cn_jon_kbn_0 AND ln_machinery_status1 = cn_num2
-- Ver.1.37 Mod End
             AND (ln_machinery_status2 = cn_num0 OR ln_machinery_status2 = cn_num1)
             AND ln_machinery_status3  = cn_num0) THEN
      ln_instance_status_id := gt_instance_status_id_2;
-- Ver.1.37 Add Start
    -- 作業区分が「０：納品」
    -- 機器状態１が「２：滞留」
    -- 機器状態２が「１：整備済」
    -- 機器状態３が「０：予定無し」の場合
    ELSIF (  ln_job_kbn = cn_jon_kbn_0 
             AND ln_machinery_status1 = cn_num2
             AND ln_machinery_status2 = cn_num1
             AND ln_machinery_status3  = cn_num0 ) THEN
      ln_instance_status_id := gt_instance_status_id_0;
-- Ver.1.37 Add End
    -- 機器状態１が「２：滞留」
    -- 機器状態２が「２：整備予定」または「３：保管」または「９：故障中」
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status2 = cn_num2 OR
                    /* 2009.07.10 K.Satomura 統合テスト障害対応(0000476) START */
                    --ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num4)
                    ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num9)
                    /* 2009.07.10 K.Satomura 統合テスト障害対応(0000476) END */
             AND ln_machinery_status3  = cn_num0) THEN
      ln_instance_status_id := gt_instance_status_id_3;
    -- 機器状態１が「２：滞留」
    -- 機器状態３が「１：廃棄予定」または「２．廃棄申請中」または「３：廃棄決裁済」の場合
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status3 = cn_num1 OR 
                    ln_machinery_status3 = cn_num2 OR ln_machinery_status3 = cn_num3)) THEN
      ln_instance_status_id := gt_instance_status_id_4;
    -- 機器状態１が「１：廃棄済」の場合
    ELSIF (ln_machinery_status1 = cn_num3) THEN
      ln_instance_status_id := gt_instance_status_id_5;
    -- 機器状態不正
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                   -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_22              -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                     ,iv_token_value1 => cv_machinery_status           -- トークン値1
                     ,iv_token_name2  => cv_tkn_bukken                 -- トークンコード2
                     ,iv_token_value2 => lv_install_code               -- トークン値2
                     ,iv_token_name3  => cv_tkn_hazard_state1          -- トークンコード3
                     ,iv_token_value3 => TO_CHAR(ln_machinery_status1) -- トークン値3
                     ,iv_token_name4  => cv_tkn_hazard_state2          -- トークンコード4
                     ,iv_token_value4 => TO_CHAR(ln_machinery_status2) -- トークン値4
                     ,iv_token_name5  => cv_tkn_hazard_state3          -- トークンコード5
                     ,iv_token_value5 => TO_CHAR(ln_machinery_status3) -- トークン値5
                   );
      lv_errbuf := lv_errmsg;
      RAISE skip_process_expt;
    END IF; 
--
    -- ============================
    -- 3.顧客マスタ新設置先情報抽出
    -- ============================
--
    BEGIN
      SELECT casv.cust_account_id                                     -- アカウントID
            ,casv.party_site_id                                       -- パーティサイトID
            ,casv.party_id                                            -- パーティID
            ,casv.area_code                                           -- 地区コード
      INTO   ln_account_id
            ,ln_party_site_id
            ,ln_party_id
            ,lv_area_code
      FROM   xxcso_cust_acct_sites_v casv                             -- 顧客マスタサイトビュー
      WHERE  casv.account_number    = lv_account_num1
        AND  casv.account_status    = cv_active
        AND  casv.acct_site_status  = cv_active
        AND  casv.party_status      = cv_active
        AND  casv.party_site_status = cv_active
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_24              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10=> SQLERRM                       -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
    -- ================================
    -- 4.国連番号マスタビュー抽出
    -- ================================
--
    BEGIN
      SELECT punv.attribute2                        -- メーカーコード
            ,punv.attribute3                        -- 年式
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 START */
--            ,SUBSTRB(phcv.hazard_class,1,1)         -- 機器区分（危険度区分）
            ,SUBSTRB(phcv.hazard_class,1,INSTRB(phcv.hazard_class,cv_msg_part_only,1,1)-1)  -- 機器区分（危険度区分）
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 END */
            /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
/* Ver.1.34 DEL START */
--            ,punv.attribute13                       -- リース区分(機種マスタ)
--            ,punv.attribute14                       -- 取得価格(機種マスタ)
/* Ver.1.34 DEL END */
            /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */
      INTO   lv_manufacturer_code
            ,lv_age_type
            ,lv_hazard_class
            /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
/* Ver.1.34 DEL START */
--            ,lt_lease_type_un_numbers
--            ,lt_get_price_un_numbers
/* Ver.1.34 DEL END */
            /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END*/
      FROM   po_un_numbers_vl     punv               -- 国連番号マスタビュー
            ,po_hazard_classes_vl phcv               -- 危険度区分マスタビュー
      WHERE  punv.un_number        = lv_un_number
        AND  punv.hazard_class_id  = phcv.hazard_class_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_24              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10=> SQLERRM                       -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
/* Ver.1.34 MOD START */
--    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add START */
--    --リース区分の優先判定(発注⇒機種マスタ⇒発注依頼)
--    IF ( lt_lease_type_po IS NOT NULL ) THEN
--      lv_lease_type := lt_lease_type_po;            --発注
--    ELSIF ( lt_lease_type_un_numbers IS NOT NULL ) THEN
--      lv_lease_type := lt_lease_type_un_numbers;    --機種マスタ
--    ELSIF ( lv_lease_type IS NOT  NULL) THEN
--      lv_lease_type := lv_lease_type;               --発注依頼
--    ELSE
--      --リース区分なしエラー
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name                   -- アプリケーション短縮名
--                     ,iv_name         => cv_tkn_number_20              -- メッセージコード
--                     ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                     ,iv_token_value1 => cv_lease_kbn                  -- トークン値1
--                     ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
--                     ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
--                     ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
--                     ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
--                     ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
--                     ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
--                     ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
--                     ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
--                     ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
--                     ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
--                     ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
--                     ,iv_token_value7 => lv_install_code1              -- トークン値7
--                     ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
--                     ,iv_token_value8 => lv_install_code2              -- トークン値8
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE skip_process_expt;
--    END IF;
--
    --そのまま設定(リース区分)
    lv_lease_type := io_inst_base_data_rec.lease_type;
/* Ver.1.34 MOD END */
    --リース区分が"固定資産"の場合、取得価格・申告地の値の設定を判定
    IF ( lv_lease_type = cv_lease_type_assets ) THEN
--
/* Ver.1.34 MOD START */
--      --取得価格の優先判定(発注⇒機種マスタ)
--      IF ( lt_get_price_po IS NOT NULL ) THEN
--        lv_get_price := lt_get_price_po;          --発注
--      ELSIF ( lt_get_price_un_numbers IS NOT NULL ) THEN
--        lv_get_price := lt_get_price_un_numbers;  --機種マスタ
--      ELSE
--        --取得価格なしエラー
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name                   -- アプリケーション短縮名
--                       ,iv_name         => cv_tkn_number_20              -- メッセージコード
--                       ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                       ,iv_token_value1 => cv_get_price                  -- トークン値1
--                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
--                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
--                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
--                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
--                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
--                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
--                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
--                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
--                       ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
--                       ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
--                       ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
--                       ,iv_token_value7 => lv_install_code1              -- トークン値7
--                       ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
--                       ,iv_token_value8 => lv_install_code2              -- トークン値8
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE skip_process_expt;
--      END IF;
--
--      --申告地の優先判定(発注⇒発注依頼)
--      IF ( lt_dclr_place_po IS NOT NULL ) THEN
--        lv_dclr_place := lt_dclr_place_po;  --発注
--      ELSIF ( lt_dclr_place_req IS NOT NULL ) THEN
--        lv_dclr_place := lt_dclr_place_req; --発注依頼
--      ELSE
--        --申告地なしエラー
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name                   -- アプリケーション短縮名
--                       ,iv_name         => cv_tkn_number_20              -- メッセージコード
--                       ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                       ,iv_token_value1 => cv_dclr_place                 -- トークン値1
--                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
--                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
--                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
--                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
--                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
--                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
--                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
--                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
--                       ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
--                       ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
--                       ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
--                       ,iv_token_value7 => lv_install_code1              -- トークン値7
--                       ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
--                       ,iv_token_value8 => lv_install_code2              -- トークン値8
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE skip_process_expt;
--      END IF;
--
      --そのまま設定(取得価格)
      lv_get_price  := io_inst_base_data_rec.get_price;
-- Ver.1.37 Mod Start
--      lv_dclr_place := io_inst_base_data_rec.declaration_place;
      --(申告地)
      --作業区分が納品の場合、引揚申告地コードを設定
      --作業区分が納品以外の場合、そのまま設定
      IF (ln_job_kbn = cn_jon_kbn_0) THEN
        lv_dclr_place := gv_dclr_place_code;
      ELSE
        lv_dclr_place := io_inst_base_data_rec.declaration_place;
      END IF;
-- Ver.1.37 Mod End
/* Ver.1.34 MOD END */
    --リース区分が固定資産以外
    ELSE
      --取得価格・申告地はNULLとする
      lv_get_price  := NULL;
      lv_dclr_place := NULL;
    END IF;
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 add END */
    -- ================================
    -- 5.登録用インスタンスレコード作成
    -- ================================
--
    -- 導入日編集
    IF (io_inst_base_data_rec.actual_work_date IS NOT NULL) THEN
      ld_install_date := TO_DATE(io_inst_base_data_rec.actual_work_date, 'yyyy/mm/dd');
    END IF; 
    -- 初回設置日編集
    IF (io_inst_base_data_rec.first_install_date IS NOT NULL) THEN 
      lv_first_install_date := TO_CHAR(TO_DATE(TO_CHAR(
        io_inst_base_data_rec.first_install_date),'yyyy/mm/dd'), 'yyyy/mm/dd hh24:mi:ss');
    END IF;
    l_instance_rec.external_reference         := lv_install_code;              -- 外部参照
    l_instance_rec.inventory_item_id          := gt_bukken_item_id;            -- 在庫品目ID
    l_instance_rec.vld_organization_id        := gt_vld_org_id;                -- 検証組織ID
    l_instance_rec.inv_master_organization_id := gt_inv_mst_org_id;            -- 在庫マスター組織ID
    l_instance_rec.quantity                   := cn_num1;                      -- 数量
    l_instance_rec.unit_of_measure            := cv_unit_of_measure;           -- 単位
    l_instance_rec.instance_status_id         := ln_instance_status_id;        -- インスタンスステータスID
    /* 2009.04.13 K.Satomura T1_0418対応 START */
    --l_instance_rec.instance_type_code         := TO_CHAR(ln_machinery_kbn);    -- インスタンスタイプコード
    l_instance_rec.instance_type_code         := TO_CHAR(lv_hazard_class);    -- インスタンスタイプコード
    /* 2009.04.13 K.Satomura T1_0418対応 START */
    l_instance_rec.location_type_code         := cv_location_type_code;        -- 現行事業所タイプ
    l_instance_rec.location_id                := ln_party_site_id;             -- 現行事業所ID
    l_instance_rec.install_date               := ld_install_date;              -- 導入日
    l_instance_rec.attribute1                 := lv_un_number;                 -- 機種(コード)
    l_instance_rec.attribute2                 := lv_install_number;            -- 機番
    l_instance_rec.attribute3                 := lv_first_install_date;        -- 初回設置日
    l_instance_rec.attribute4                 := cv_flg_no;                    -- 作業依頼中フラグ
/* Ver.1.34 DEL START */
--    l_instance_rec.attribute6                 := io_inst_base_data_rec.po_req_number;  -- 最終発注依頼番号
/* Ver.1.34 DEL END */
    l_instance_rec.instance_usage_code        := cv_instance_usage_code;       -- インスタンス使用コード
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
--
    -- ==================================
    -- 6.登録用設置機器拡張属性値情報作成
    -- ==================================
--
    -- カウンターNo.
    ln_cnt := 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.count_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.counter_no;
--
    -- 地区コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.chiku_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_area_code;
--
    -- 作業会社コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyougaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.job_company_code;
--
    -- 事業所コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jigyousyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.location_code;
--
    -- 最終作業伝票No.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_slip_no;
--
    -- 最終作業区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_kbn;
--
    -- 最終作業進捗
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_going;
--
    -- 最終作業完了予定日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.yotei_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_cmpltn_plan_date;
--
    -- 最終作業完了日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_cmpltn_date;
--
    -- 最終整備内容
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyo_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_maintenance_contents;
--
    -- 最終設置伝票No.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_install_slip_no;
--
    -- 最終設置区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_install_kbn;
--
    -- 最終設置進捗
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_install_going;
--
    -- 機器状態1（稼動状態）
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.machinery_status1;
--
    -- 機器状態2（状態詳細）
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.machinery_status2;
--
    -- 機器状態3（廃棄情報）
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn3;
    /* 2009.04.27 K.Satomura T1_0490対応 START */
    --l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.machinery_status3;
    /* 2009.04.27 K.Satomura T1_0490対応 END */
--
    -- 入庫日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.nyuko_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.stock_date;
--
    -- 引揚会社コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakigaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.withdraw_company_code;
--
    -- 引揚事業所コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakijigyosyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.withdraw_location_code;
--
    -- 設置先担当者名
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 設置先tel1
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 設置先tel2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 設置先tel3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel3;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 廃棄決裁日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.haikikessai_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 転売廃棄業者
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_disposal_vendor;
--
    -- 転売廃棄伝票��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_disposal_slip_no;
--
    -- 所有者
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.syoyu_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.owner_company_code;
--
    -- 転売廃棄状況フラグ
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_disposal_flag;
--
    -- 転売完了区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_completion_kbn;
--
    -- 削除フラグ
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sakujo_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.delete_flag;
--
    -- 最終顧客コード
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kyaku_last;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社コード１
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社台数１
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社コード2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社台数2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社コード3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社台数3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社コード4
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社台数4
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社コード5
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 他社台数5
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 廃棄フラグ
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_haiki_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;
--
    -- 資産区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_sisan_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 購買日付
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_ymd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 購買金額
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_kg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- 安全設置基準
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.safty_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.safe_setting_standard;
--
    -- リース区分
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.lease_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_lease_type;
--
    /*2009.09.03 M.Maruyama 0001192対応 START*/
    IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM')) THEN
--
      -- 先月末年月
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_year_month;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
--
      -- 先月末設置先顧客コード
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_inst_cust_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_account_num1;
--
      -- 先月末機器状態
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_jotai_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := ln_machinery_status1;
--    
    ELSE
    /*2009.09.03 M.Maruyama 0001192対応 END*/
      -- 先月末年月
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_year_month;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
      -- 先月末設置先顧客コード
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_inst_cust_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
      -- 先月末機器状態
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_jotai_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
    /*2009.09.03 M.Maruyama 0001192対応 START*/
    END IF;
    /*2009.09.03 M.Maruyama 0001192対応 END*/
--
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    -- 取得価格
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.vd_shutoku_kg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_get_price;
--
    -- 申告地
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.dclr_place;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_dclr_place;
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
/* Ver.1.34 ADD START */
--
    -- 固定資産移動日
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.fa_move_date;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := TO_CHAR(io_inst_base_data_rec.actual_work_date);
--
-- Ver.1.37 Mod Start
/* Ver.1.35 Q2239 ADD START */
    -- 作業区分が１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動の場合
--    IF ( ln_job_kbn IN ( cn_jon_kbn_1 ,cn_jon_kbn_2 ,cn_jon_kbn_3 ,cn_jon_kbn_4 ,cn_jon_kbn_5 ,cn_job_kbn_6 ) ) THEN
/* Ver.1.35 Q2239 ADD END */
    -- 作業区分が0：納品、１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動の場合
    IF ( ln_job_kbn IN ( cn_jon_kbn_0 ,cn_jon_kbn_1 ,cn_jon_kbn_2 ,cn_jon_kbn_3 ,cn_jon_kbn_4 ,cn_jon_kbn_5 ,cn_job_kbn_6 ) ) THEN
-- Ver.1.37 Mod End
      -- 最終有効実作業日時
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_act_date_time;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := TO_CHAR(io_inst_base_data_rec.actual_work_date) ||
                                                         io_inst_base_data_rec.actual_work_time1;
/* Ver.1.35 Q2239 ADD START */
    END IF;
/* Ver.1.35 Q2239 ADD END */
--
/* Ver.1.34 ADD END */
--
    -- ====================
    -- 7.パーティデータ作成
    -- ====================
--
    ln_cnt := 1;
    l_party_tab(ln_cnt).party_source_table       := cv_party_source_table;
    l_party_tab(ln_cnt).party_id                 := ln_party_id;
    l_party_tab(ln_cnt).relationship_type_code   := cv_relatnsh_type_code;
    l_party_tab(ln_cnt).CONTACT_FLAG             := cv_flg_no;
--
    -- ===============================
    -- 8.パーティアカウントデータ作成
    -- ===============================
--
    ln_cnt := 1;
    l_account_tab(ln_cnt).parent_tbl_index       := cn_num1;
    l_account_tab(ln_cnt).party_account_id       := ln_account_id;
    l_account_tab(ln_cnt).relationship_type_code := cv_relatnsh_type_code;
--
    -- ===============================
    -- 9.取引レコードデータ作成
    -- ===============================
--
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;
--
    -- =================================
    -- 10.標準APIより、物件登録処理を行う
    -- =================================
--
    BEGIN
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
      -- 正常終了でない場合
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE update_error_expt;
      END IF;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
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
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_25              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_inst_base_insert           -- トークン値1
                       ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                       ,iv_token_value2  => cv_insert_process             -- トークン値2
                       ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                       ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                       ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                       ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                       ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                       ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                       ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6  => lv_install_code1              -- トークン値6
                       ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7  => lv_install_code2              -- トークン値7
                       ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8  => lv_account_num1               -- トークン値8
                       ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9  => lv_account_num2               -- トークン値9
                       ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10 => lv_msg_data                   -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--  
    /* 2010.01.06 K.Hosoi E_本稼動_00825対応 START */
    --リース区分に関わらず履歴テーブルを作成する
    ---- リターンステータスが[S]で、リース区分が[1.自社リース]の場合
    --IF (lv_lease_type = cv_lease_type_own) THEN 
    /* 2010.01.06 K.Hosoi E_本稼動_00825対応 END */
      -- ========================================
      -- 11.物件関連情報変更履歴テーブルの登録処理
      -- ========================================
--
      -- メーカー名取得
      lv_manufacturer_name := xxcso_util_common_pkg.get_lookup_meaning(
                                cv_xxcso_csi_maker_code
                               ,lv_manufacturer_code
                               ,ld_date);
--
      IF (lv_manufacturer_name is null) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_mfg_fctory_maker_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_lookup_type_name      -- トークンコード2
                       ,iv_token_value2 => cv_mfg_fctory_maker_cd       -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      END IF;
--
      BEGIN
        /*2009.09.03 M.Maruyama 0001192対応 START*/
        --SELECT casv.sale_base_code                                        -- 売上拠点コード
        SELECT (CASE
                WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                THEN casv.sale_base_code
                ELSE casv.past_sale_base_code
                END) sale_base_code                                  -- 売上拠点コード
        /*2009.09.03 M.Maruyama 0001192対応 END*/
              /* 2010.01.13 K.Hosoi E_本稼動_00443対応 START */
              --,casv.established_site_name                                 -- 設置先名
              ,casv.party_name                                       -- 設置先名
              /* 2010.01.13 K.Hosoi E_本稼動_00443対応 END */
              ,casv.state || casv.city || casv.address1 || casv.address2  -- 設置先住所
        INTO   lv_base_code
              ,lv_install_name
              ,lv_install_address
        FROM   xxcso_cust_acct_sites_v casv                               -- 顧客マスタサイトビュー
        WHERE  casv.account_number    = lv_account_num1
          AND  casv.account_status    = cv_active
          AND  casv.acct_site_status  = cv_active
          AND  casv.party_status      = cv_active
          AND  casv.party_site_status = cv_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_23              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_24              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                         ,iv_token_value10=> SQLERRM                       -- トークン値10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
      BEGIN
        -- 本社/工場フラグの初期化
        lv_owner_cmp_flag := cv_kbn1;
        -- 本社/工場フラグの編集
        <<mfg_fctory_loop>>
        FOR ln_loop_cnt IN 1..gt_mfg_fctory_code_tab.count LOOP
          IF (gt_mfg_fctory_code_tab(ln_loop_cnt).mfg_fctory_code = lv_base_code) THEN
            lv_owner_cmp_flag := cv_kbn2;
            EXIT;
          END IF;
        END LOOP mfg_fctory_loop;
  --
        -- 本社/工場区分の編集
        lv_owner_cmp_name := xxcso_util_common_pkg.get_lookup_meaning(
                               cv_xxcso1_owner_company
                              ,lv_owner_cmp_flag
                              ,id_process_date);  
  --
        SELECT ffvv.flex_value                                         -- 値
        INTO   lv_owner_cmp_type
        FROM   fnd_flex_values_vl    ffvv                              -- 値セット(値)
              ,fnd_flex_value_sets   ffvs                              -- 値セット
        WHERE  ffvv.flex_value_set_id   = ffvs.flex_value_set_id
          AND  ffvs.flex_value_set_name = cv_xxcff_owner_company
          AND  ffvv.enabled_flag        = cv_flg_yes
          AND  ld_date BETWEEN trunc(nvl(ffvv.start_date_active,ld_date))
                 AND trunc(nvl(ffvv.end_date_active,ld_date))
          AND  ffvv.flex_value_meaning  = lv_owner_cmp_name
        ;  
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_16             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                         ,iv_token_value1 => cv_owner_cmp_info            -- トークン値1
                         ,iv_token_name2  => cv_tkn_errmsg                -- トークンコード2
                         ,iv_token_value2 => SQLERRM                      -- トークン値2
                     );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
  --
      BEGIN
        -- 物件関連情報変更履歴テーブルの登録
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
          /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
          ,declaration_place                      -- 申告地
          ,disposal_intaface_flag                -- 廃棄連携フラグ
          /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
          ,created_by                             -- 作成者
          ,creation_date                          -- 作成日
          ,last_updated_by                        -- 最終更新者
          ,last_update_date                       -- 最終更新日
          ,last_update_login                      -- 最終更新ログイン
          ,request_id                             -- 要求ID
          ,program_application_id                 -- コンカレント・プログラム・アプリケーションID
          ,program_id                             -- コンカレント・プログラムID PROGRAM_ID
          ,program_update_date                    -- プログラム更新日
        )VALUES(
-- Ver.1.37 Mod Start
--           lv_install_code1                       -- 物件コード
           DECODE( ln_job_kbn, cn_jon_kbn_0, lv_install_code2, lv_install_code1 ) -- 物件コード
-- Ver.1.37 Mod End
          ,ld_date                                -- 履歴作成日
          ,cv_flg_no                              -- 連携済フラグ
/* Ver.1.34 MOD START */
--          ,io_inst_base_data_rec.po_number        -- 発注番号
          ,NULL
/* Ver.1.34 MOD END */
          ,lv_manufacturer_name                   -- メーカー名
          ,lv_age_type                            -- 年式
          ,lv_un_number                           -- 機種
          ,lv_install_number                      -- 機番
          ,cn_num1                                -- 数量
          ,lv_base_code                           -- 拠点コード
          ,lv_owner_cmp_type                      -- 本社／工場区分
          ,lv_install_name                        -- 設置先名
          ,lv_install_address                     -- 設置先住所
          ,cv_flg_no                              -- 論理削除フラグ
          ,lv_account_num1                        -- 顧客コード
          /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
          ,lv_dclr_place                          -- 申告地
          ,cv_flg_no                              -- 廃棄連携フラグ
          /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
          ,cn_created_by                          -- 作成者
          ,SYSDATE                                -- 作成日
          ,cn_last_updated_by                     -- 最終更新者
          ,SYSDATE                                -- 最終更新日
          ,cn_last_update_login                   -- 最終更新ログイン
          ,cn_request_id                          -- 要求ID
          ,cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                          -- コンカレント・プログラムID PROGRAM_ID
          ,SYSDATE                                -- プログラム更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name          => cv_tkn_number_25              -- メッセージコード
                         ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                         ,iv_token_value1  => cv_xxcso_ib_info_h            -- トークン値1
                         ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                         ,iv_token_value2  => cv_insert_process             -- トークン値2
                         ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                         ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                         ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                         ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                         ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                         ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                         ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6  => lv_install_code1              -- トークン値6
                         ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7  => lv_install_code2              -- トークン値7
                         ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8  => lv_account_num1               -- トークン値8
                         ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9  => lv_account_num2               -- トークン値9
                         ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                         ,iv_token_value10 => SQLERRM                       -- トークン値10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
    /* 2010.01.06 K.Hosoi E_本稼動_00825対応 START */
    --END IF;
    /* 2010.01.06 K.Hosoi E_本稼動_00825対応 END */
--
  EXCEPTION
    -- *** スキップ処理例外ハンドラ ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      -- 更新失敗ロールバックフラグの設定。
      gb_rollback_flg := TRUE;
--      
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Procedure Name   : rock_item_instances
   * Description      : 物件ロック処理 (A-7)
   ***********************************************************************************/
  PROCEDURE rock_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)物件マスタ情報
    ,id_process_date         IN     DATE                    -- 業務処理日付
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rock_item_instances'; -- プログラム名
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
    cv_install_base_info       CONSTANT VARCHAR2(100)   := 'インストールベースマスタ(物件マスタ)';
    cv_ex_lease_kbn            CONSTANT VARCHAR2(100)   := 'LEASE_KBN';
--
    -- *** ローカル変数 ***
    ln_seq_no                  NUMBER;                  -- シーケンス番号
    ln_slip_num                NUMBER;                  -- 伝票No.
    ln_slip_branch_num         NUMBER;                  -- 伝票枝番
    ln_line_num                NUMBER;                  -- 行番
    ln_job_kbn                 NUMBER;                  -- 作業区分
    lv_install_code            VARCHAR2(10);            -- 物件コード
    lv_install_code1           VARCHAR2(10);            -- 物件コード１
    lv_install_code2           VARCHAR2(10);            -- 物件コード２
    lv_account_num1            VARCHAR2(10);            -- 顧客コード１
    lv_account_num2            VARCHAR2(10);            -- 顧客コード２
    lv_rock_install_code       VARCHAR2(10);            -- ロック用物件コード
--
    -- *** ローカル例外 ***
    skip_process_expt          EXCEPTION;
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- データの格納
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
--
    -- 物件情報抽出
    BEGIN
      SELECT ciins.external_reference                                    -- 外部参照
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
            ,xxcso_ib_common_pkg.get_ib_ext_attribs(ciins.instance_id,cv_ex_lease_kbn) -- リース区分(物件マスタ)
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
      INTO   lv_rock_install_code
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
            ,gv_lease_kbn
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
      FROM   csi_item_instances ciins                                    -- インストールベースマスタ
      WHERE  ciins.external_reference = lv_install_code
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_27              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => cv_install_base_info          -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_19             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_install_base_info         -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                       ,iv_token_value2 => lv_install_code              -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
  EXCEPTION
    -- *** スキップ処理例外ハンドラ ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END rock_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : update_item_instances
   * Description      : 物件データ更新処理 (A-8)
   ***********************************************************************************/
  PROCEDURE update_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)物件マスタ情報
    ,id_process_date         IN     DATE                    -- 業務処理日付
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_item_instances'; -- プログラム名
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
    cn_num0                   CONSTANT NUMBER        := 0;
    cn_num1                   CONSTANT NUMBER        := 1;
    cn_num2                   CONSTANT NUMBER        := 2;
    cn_num3                   CONSTANT NUMBER        := 3;
    cn_num4                   CONSTANT NUMBER        := 4;
    cn_num9                   CONSTANT NUMBER        := 9;
    cn_jon_kbn_1              CONSTANT NUMBER        := 1;                   -- 新台設置
    cn_jon_kbn_2              CONSTANT NUMBER        := 2;                   -- 旧台設置
    cn_jon_kbn_3              CONSTANT NUMBER        := 3;                   -- 新台代替
    cn_jon_kbn_4              CONSTANT NUMBER        := 4;                   -- 旧台代替
    cn_jon_kbn_5              CONSTANT NUMBER        := 5;                   -- 引揚
    /*20090528_Ohtsuki_T1_1203 START*/
    cn_job_kbn_6              CONSTANT NUMBER        := 6;                   -- 店内移動
    cn_job_kbn_8              CONSTANT NUMBER        := 8;                   -- 是正
    cn_job_kbn_9              CONSTANT NUMBER        := 9;                   -- 出張修理
    cn_job_kbn_10             CONSTANT NUMBER        := 10;                  -- 整備
    cn_job_kbn_15             CONSTANT NUMBER        := 15;                  -- 転送
    cn_job_kbn_16             CONSTANT NUMBER        := 16;                  -- 転売
    cn_job_kbn_17             CONSTANT NUMBER        := 17;                  -- 廃棄引取
    /*20090528_Ohtsuki_T1_1203 END*/
    cn_api_version            CONSTANT NUMBER        := 1.0;
    cv_kbn1                   CONSTANT VARCHAR2(1)   := '1'; 
    cv_kbn2                   CONSTANT VARCHAR2(1)   := '2'; 
    cv_cust_mst_info          CONSTANT VARCHAR2(100) := '顧客マスタ情報';    -- 抽出内容
    /*20090325_yabuki_ST150 START*/
    cv_cust_base_info          CONSTANT VARCHAR2(100) := '引揚前設置先顧客の売上拠点情報';    -- 抽出内容
    /*20090325_yabuki_ST150 END*/
    cv_inst_party_info        CONSTANT VARCHAR2(100) := 'インスタンスパーティ情報';      -- 抽出内容
    cv_inst_account_info      CONSTANT VARCHAR2(100) := 'インスタンスアカウント情報';    -- 抽出内容
    cv_inst_base_insert       CONSTANT VARCHAR2(100) := 'インストールベースマスタ';
/* Ver.1.34 ADD START */
    cv_inst_ext_att_val       CONSTANT VARCHAR2(100) := '設置機器拡張属性値';
    cv_insert_process         CONSTANT VARCHAR2(100) := '登録';
/* Ver.1.34 ADD END */
    cv_update_process         CONSTANT VARCHAR2(100) := '更新';
    cv_machinery_status       CONSTANT VARCHAR2(100) := '物件データワークテーブルの機器状態'; 
    cv_location_type_code     CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';    -- 現行事業所タイプ
    cv_instance_usage_code    CONSTANT VARCHAR2(100) := 'OUT_OF_ENTERPRISE'; -- インスタンス使用コード
    cv_party_source_table     CONSTANT VARCHAR2(100) := 'HZ_PARTIES';        -- パーティソーステーブル
    cv_relatnsh_type_code     CONSTANT VARCHAR2(100) := 'OWNER';             -- リレーションタイプ
    cv_ex_count_no            CONSTANT VARCHAR2(100) := 'COUNT_NO';           
    cv_ex_chiku_cd            CONSTANT VARCHAR2(100) := 'CHIKU_CD';           
    cv_ex_sagyougaisya_cd     CONSTANT VARCHAR2(100) := 'SAGYOUGAISYA_CD';    
    cv_ex_jigyousyo_cd        CONSTANT VARCHAR2(100) := 'JIGYOUSYO_CD';       
    cv_ex_den_no              CONSTANT VARCHAR2(100) := 'DEN_NO';             
    cv_ex_job_kbn             CONSTANT VARCHAR2(100) := 'JOB_KBN';            
    cv_ex_sintyoku_kbn        CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN';       
    cv_ex_yotei_dt            CONSTANT VARCHAR2(100) := 'YOTEI_DT';           
    cv_ex_kanryo_dt           CONSTANT VARCHAR2(100) := 'KANRYO_DT';          
    cv_ex_sagyo_level         CONSTANT VARCHAR2(100) := 'SAGYO_LEVEL';        
    cv_ex_den_no2             CONSTANT VARCHAR2(100) := 'DEN_NO2';            
    cv_ex_job_kbn2            CONSTANT VARCHAR2(100) := 'JOB_KBN2';           
    cv_ex_sintyoku_kbn2       CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN2';      
    cv_ex_jotai_kbn1          CONSTANT VARCHAR2(100) := 'JOTAI_KBN1';         
    cv_ex_jotai_kbn2          CONSTANT VARCHAR2(100) := 'JOTAI_KBN2';         
    cv_ex_nyuko_dt            CONSTANT VARCHAR2(100) := 'NYUKO_DT';           
    cv_ex_hikisakigaisya_cd   CONSTANT VARCHAR2(100) := 'HIKISAKIGAISYA_CD';  
    cv_ex_hikisakijigyosyo_cd CONSTANT VARCHAR2(100) := 'HIKISAKIJIGYOSYO_CD';
    cv_ex_setti_tenmei        CONSTANT VARCHAR2(100) := 'SETTI_TENMEI';       
    cv_ex_tenhai_tanto        CONSTANT VARCHAR2(100) := 'TENHAI_TANTO';       
    cv_ex_tenhai_den_no       CONSTANT VARCHAR2(100) := 'TENHAI_DEN_NO';      
    cv_ex_syoyu_cd            CONSTANT VARCHAR2(100) := 'SYOYU_CD';           
    cv_ex_tenhai_flg          CONSTANT VARCHAR2(100) := 'TENHAI_FLG';         
    cv_ex_kanryo_kbn          CONSTANT VARCHAR2(100) := 'KANRYO_KBN';         
    cv_ex_sakujo_flg          CONSTANT VARCHAR2(100) := 'SAKUJO_FLG';         
    cv_ex_ven_kyaku_last      CONSTANT VARCHAR2(100) := 'VEN_KYAKU_LAST';     
    cv_ex_ven_haiki_flg       CONSTANT VARCHAR2(100) := 'VEN_HAIKI_FLG';      
    cv_ex_safty_level         CONSTANT VARCHAR2(100) := 'SAFTY_LEVEL';        
    cv_ex_lease_kbn           CONSTANT VARCHAR2(100) := 'LEASE_KBN';          
    cv_ex_last_inst_cust_code CONSTANT VARCHAR2(100) := 'LAST_INST_CUST_CODE';
    cv_ex_last_jotai_kbn      CONSTANT VARCHAR2(100) := 'LAST_JOTAI_KBN';     
    cv_ex_last_year_month     CONSTANT VARCHAR2(100) := 'LAST_YEAR_MONTH';    
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    cv_ex_dclr_place          CONSTANT VARCHAR2(100) := 'DCLR_PLACE';
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
/* Ver.1.34 ADD START */
    cv_fa_move_date           CONSTANT VARCHAR2(100) := 'FA_MOVE_DATE';
    cv_last_act_dt            CONSTANT VARCHAR2(100) := 'LAST_ACT_DATE_TIME';
/* Ver.1.34 ADD END */
    cv_flg_no                 CONSTANT VARCHAR2(100) := 'N';                 -- フラグNO
    cv_flg_yes                CONSTANT VARCHAR2(100) := 'Y';                 -- フラグYES
    /* 2009.04.13 K.Satomura T1_0418対応 START */
    cv_po_un_numbers_info     CONSTANT VARCHAR2(100) := '国連番号マスタ(機種コードマスタ)情報';    -- 抽出内容
    /* 2009.04.13 K.Satomura T1_0418対応 END */
    /* 2009.04.27 K.Satomura T1_0490対応 START */
    cv_ex_jotai_kbn3          CONSTANT VARCHAR2(100) := 'JOTAI_KBN3';
    /* 2009.04.27 K.Satomura T1_0490対応 END */
    /* 2009.06.01 K.Satomura T1_1107対応 START */
    ct_comp_kbn_comp         CONSTANT xxcso_in_work_data.completion_kbn%TYPE := 1;
    /* 2009.06.01 K.Satomura T1_1107対応 END */
    /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
    cv_day_zero              CONSTANT VARCHAR2(1) := '0';
    /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    cv_dclr_place              CONSTANT VARCHAR2(100) := '申告地コード(更新)';     -- 取得内容名
    cv_lease_kbn               CONSTANT VARCHAR2(100) := 'リース区分(更新)';       -- 取得内容名
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
-- Ver.1.39 Add Start
    -- 会社別引揚拠点コード
    cv_cp_withdraw_base_code_type  CONSTANT VARCHAR2(30)  := 'XXCSO1_COMP_WITHDRAW_BASE_CODE';
    -- 会社別什器引揚拠点コード
    cv_cp_j_wthdrw_base_code_type  CONSTANT VARCHAR2(30)  := 'XXCSO1_COMP_J_WTHDRW_BASE_CODE';
    -- 抽出内容名(伊藤園の顧客マスタ情報)
    cv_cust_acct_sites_info        CONSTANT VARCHAR2(100) := '引揚拠点の顧客マスタ情報';
    -- 抽出内容名(伊藤園の顧客マスタ情報)
    cv_cust_acct_sites_info1       CONSTANT VARCHAR2(100) := '什器引揚拠点の顧客マスタ情報';
    -- 抽出内容名(顧客コード)
    cv_cust_account_number         CONSTANT VARCHAR2(100) := '顧客コード';
-- Ver.1.39 Add End
--
    -- *** ローカル変数 ***
    ld_date                    DATE;                    -- 業務処理日付格納用('yyyymmdd'形式)
    ld_actual_work_date        DATE;                    -- 実作業日('yyyymmdd'形式)
    ld_install_date            DATE;                    -- 導入日
    ln_cnt                     NUMBER;                  -- カウント数
/* Ver.1.34 ADD START */
    ln_cnt2                    NUMBER;                  -- カウント数
/* Ver.1.34 ADD END */
    ln_seq_no                  NUMBER;                  -- シーケンス番号
    ln_slip_num                NUMBER;                  -- 伝票No.
    ln_slip_branch_num         NUMBER;                  -- 伝票枝番
    ln_line_num                NUMBER;                  -- 行番
    ln_job_kbn                 NUMBER;                  -- 作業区分
    ln_instance_status_id      NUMBER;                  -- インスタンスステータスID
    ln_machinery_status1       NUMBER;                  -- 機器状態1（稼動状態）
    ln_machinery_status1_wk    NUMBER;                  -- 機器状態1（稼動状態）
    ln_machinery_status2       NUMBER;                  -- 機器状態2（状態詳細）
    ln_machinery_status3       NUMBER;                  -- 機器状態3（廃棄情報）
    ln_account_id              NUMBER;                  -- アカウントID
    ln_party_site_id           NUMBER;                  -- パーティサイトID
    ln_party_id                NUMBER;                  -- パーティID
    lv_area_code               VARCHAR2(100);           -- 地区コード
    ln_delete_flag             NUMBER;                  -- 削除フラグ
    ln_machinery_kbn           NUMBER;                  -- 機器区分
    ln_validation_level        NUMBER;                  -- バリデーションレーベル
    ln_instance_id             NUMBER;                  -- インスタンスID
    ln_instance_party_id       NUMBER;                  -- インスタンスパーティID
    ln_object_version_number2  NUMBER;                  -- オブジェクトバージョン番号
    ln_ip_account_id           NUMBER;                  -- インスタンスアカウントID
    ln_object_version_number3  NUMBER;                  -- オブジェクトバージョン番号
    ln_loop_cnt                NUMBER;                  -- ループ用変数
    lv_commit                  VARCHAR2(1);             -- コミットフラグ
    lv_install_code            VARCHAR2(10);            -- 物件コード
    lv_install_code1           VARCHAR2(10);            -- 物件コード１
    lv_install_code2           VARCHAR2(10);            -- 物件コード２
    lv_account_num             VARCHAR2(10);            -- 顧客コード
    lv_account_num1            VARCHAR2(10);            -- 顧客コード１
    lv_account_num2            VARCHAR2(10);            -- 顧客コード２
    lv_un_number               VARCHAR2(20);            -- 機種
    lv_install_number          VARCHAR2(20);            -- 機番
    lv_last_cust_num           VARCHAR2(10);            -- 最終顧客コード
    lv_init_msg_list           VARCHAR2(2000);          -- メッセージリスト
    lv_last_inst_cust_code     VARCHAR2(10);            -- 先月末設置先顧客コード
    ln_last_jotai_kbn          NUMBER;                  -- 先月末機器状態
    lv_last_year_month         VARCHAR2(10);            -- 先月末年月
    /*20090325_yabuki_ST150 START*/
    lt_sale_base_code          xxcso_cust_acct_sites_v.sale_base_code%TYPE;       -- 売上拠点コード
    /*20090325_yabuki_ST150 END*/
    /*2009.09.03 M.Maruyama 0001192対応 START*/
    lt_past_sale_base_code     xxcso_cust_acct_sites_v.past_sale_base_code%TYPE;  -- 前月売上拠点コード
    lt_sl_bs_cd_fr_bfr_mnth_dt xxcso_cust_acct_sites_v.past_sale_base_code%TYPE;  -- 前月売上拠点コード(先月末顧客コード用)
    ld_ib_install_date         DATE;                                              -- 設置日
    /*2009.09.03 M.Maruyama 0001192対応 END*/
    /* 2009.04.13 K.Satomura T1_0418対応 START */
    lv_hazard_class            po_hazard_classes_tl.hazard_class%type; -- 機器区分（危険度区分）
    /* 2009.04.13 K.Satomura T1_0418対応 END */
    -- Ver.1.39 Add Start
    lt_comp_withdraw_base_code fnd_lookup_values_vl.attribute1%type;   -- 会社別引揚拠点コード
    lt_comp_j_wthdrw_base_code fnd_lookup_values_vl.attribute1%type;   -- 会社別什器引揚拠点コード
    ln_account_id_withdraw     NUMBER;                                 -- 引揚拠点アカウントID
    ln_party_site_id_withdraw  NUMBER;                                 -- 引揚拠点パーティサイトID
    ln_party_id_withdraw       NUMBER;                                 -- 引揚拠点パーティID
    lv_area_code_withdraw      VARCHAR2(100);                          -- 引揚拠点地区コード
    ln_jyki_account_id         NUMBER;                                 -- 什器引揚拠点アカウントID
    ln_jyki_party_site_id      NUMBER;                                 -- 什器引揚拠点パーティサイトID
    ln_jyki_party_id           NUMBER;                                 -- 什器引揚拠点パーティID
    lv_jyki_area_code          VARCHAR2(100);                          -- 什器引揚拠点地区コード
    -- Ver.1.39 Add End
    -- API戻り値格納用
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
/* Ver.1.34 DEL START */
--    lt_po_req_number           po_requisition_headers_all.segment1%TYPE;  -- 発注依頼番号
--    lt_line_num                po_requisition_lines_all.line_num%TYPE;    -- 発注依頼明細番号
/* Ver.1.34 DEL END */
    lv_dclr_place              VARCHAR2(5);                               -- 申告地
    lv_dclr_place_upd_flg      VARCHAR2(1);                               -- 申告地更新フラグ
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
/* Ver.1.34 ADD START */
    lv_ib_ext_attr_flg         VARCHAR2(1);                               -- 設置機器拡張属性値登録フラグ
/* Ver.1.34 ADD END */
-- Ver.1.40 Add Start
    lt_dept_code               xxcfr_bd_dept_comp_info_v.dept_code%TYPE;  -- 部門コード
-- Ver.1.40 Add End
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
    l_instance_id_lst          csi_datastructures_pub.id_tbl;
/* Ver.1.34 ADD START */
    l_cre_ext_attr_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
/* Ver.1.34 ADD END */
    l_ext_attrib_rec           csi_iea_values%ROWTYPE;
    l_ext_attrib_rec_wk        csi_iea_values%ROWTYPE;
--
    l_csi_iea_values_rec       gr_csi_iea_values_rtype;
    -- *** ローカル例外 ***
    skip_process_expt          EXCEPTION;
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- データの格納
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
    ld_date               := TRUNC(id_process_date);
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    ln_delete_flag        := io_inst_base_data_rec.delete_flag;
    ln_machinery_status1  := io_inst_base_data_rec.machinery_status1;
    ln_machinery_status2  := io_inst_base_data_rec.machinery_status2;
    ln_machinery_status3  := io_inst_base_data_rec.machinery_status3;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
    ln_machinery_kbn      := io_inst_base_data_rec.machinery_kbn;
    lv_un_number          := io_inst_base_data_rec.un_number;
    lv_install_number     := io_inst_base_data_rec.install_number;
    ln_instance_id        := io_inst_base_data_rec.instance_id;
    ld_actual_work_date   := TO_DATE(io_inst_base_data_rec.actual_work_date,'YYYY/MM/DD');
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
/* Ver.1.34 DEL START */
--    lt_po_req_number      := io_inst_base_data_rec.po_req_number;
--    lt_line_num           := io_inst_base_data_rec.line_num;
/* Ver.1.34 DEL END */
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
--
    -- ========================
    -- 1.機器状態整合性チェック
    -- ========================
-- 
/* Ver.1.35 Q2239 ADD START */
    -- 作業区分が１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動の場合
    IF ( ln_job_kbn IN ( cn_jon_kbn_1 ,cn_jon_kbn_2 ,cn_jon_kbn_3 ,cn_jon_kbn_4 ,cn_jon_kbn_5 ,cn_job_kbn_6 ) ) THEN
/* Ver.1.35 Q2239 ADD END */
      -- 削除フラグが「９：論理削除」の場合
      IF (ln_delete_flag = cn_num9) THEN
        ln_instance_status_id := gt_instance_status_id_6;
      -- 機器状態１が「１：稼動中」の場合
      ELSIF (ln_machinery_status1 = cn_num1) THEN
        ln_instance_status_id := gt_instance_status_id_1;
      -- 機器状態１が「２：滞留」
      -- 機器状態２が「０：情報無」または「１：整備済」
      -- 機器状態３が「０：予定無し」の場合
      ELSIF (ln_machinery_status1 = cn_num2
               AND (ln_machinery_status2 = cn_num0 OR ln_machinery_status2 = cn_num1)
               AND ln_machinery_status3  = cn_num0) THEN
        ln_instance_status_id := gt_instance_status_id_2;
      -- 機器状態１が「２：滞留」
      -- 機器状態２が「２：整備予定」または「３：保管」または「９：故障中」
      ELSIF (ln_machinery_status1 = cn_num2
               AND (ln_machinery_status2 = cn_num2 OR
                      /* 2009.07.10 K.Satomura 統合テスト障害対応(0000476) START */
                      --ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num4)
                      ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num9)
                      /* 2009.07.10 K.Satomura 統合テスト障害対応(0000476) END */
               AND ln_machinery_status3  = cn_num0) THEN
        ln_instance_status_id := gt_instance_status_id_3;
      -- 機器状態１が「２：滞留」
      -- 機器状態３が「１：廃棄予定」または「２．廃棄申請中」または「３：廃棄決裁済」の場合
      ELSIF (ln_machinery_status1 = cn_num2
               AND (ln_machinery_status3 = cn_num1 OR 
                      ln_machinery_status3 = cn_num2 OR ln_machinery_status3 = cn_num3)) THEN
        ln_instance_status_id := gt_instance_status_id_4;
      -- 機器状態１が「１：廃棄済」の場合
      ELSIF (ln_machinery_status1 = cn_num3) THEN
        ln_instance_status_id := gt_instance_status_id_5;
      -- 機器状態不正
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_22              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_machinery_status           -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                 -- トークンコード2
                       ,iv_token_value2 => lv_install_code               -- トークン値2
                       ,iv_token_name3  => cv_tkn_hazard_state1          -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_machinery_status1) -- トークン値3
                       ,iv_token_name4  => cv_tkn_hazard_state2          -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_machinery_status2) -- トークン値4
                       ,iv_token_name5  => cv_tkn_hazard_state3          -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_machinery_status3) -- トークン値5
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
      END IF; 
/* Ver.1.35 Q2239 ADD START */
    -- 作業区分が上記の場合
    ELSE
      ln_instance_status_id := io_inst_base_data_rec.instance_status_id;
    END IF;
/* Ver.1.35 Q2239 ADD END */
--
    -- ===============
    -- 2.変数の初期化
    -- ===============
    ln_account_id     := cn_num0;
    ln_party_site_id  := cn_num0;
    ln_party_id       := cn_num0;
    lv_area_code      := NULL;
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    lv_dclr_place_upd_flg := cv_flg_no;
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
/* Ver.1.34 ADD START */
    ln_cnt2               := cn_num0;    --設置機器拡張属性値登録用カウンタ
    lv_ib_ext_attr_flg    := cv_flg_no;  --設置機器拡張属性値登録フラグ
/* Ver.1.34 ADD END */
-- Ver.1.40 Add Start
    lt_dept_code      := NULL;
-- Ver.1.40 Add End
--
    -- 3.設置機器拡張属性値(更新用)データ作成
--
    -- カウンターNo.
    ln_cnt := 1;
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_count_no);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.counter_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 作業会社コード
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sagyougaisya_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.job_company_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 事業所コード
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jigyousyo_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.location_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終作業伝票No.
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_den_no);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_slip_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終作業区分
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_job_kbn);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終作業進捗
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sintyoku_kbn);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_going;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終作業完了予定日
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_yotei_dt);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_cmpltn_plan_date;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終作業完了日
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_kanryo_dt);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_cmpltn_date;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終整備内容
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sagyo_level);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_maintenance_contents;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終設置伝票No.
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_den_no2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_install_slip_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終設置区分
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_job_kbn2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_install_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 最終設置進捗
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sintyoku_kbn2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_install_going;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 機器状態1（稼動状態）
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jotai_kbn1);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
/* Ver.1.36 ADD START */
      -- 作業区分が１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動の場合
      IF ( ln_job_kbn IN ( cn_jon_kbn_1 ,cn_jon_kbn_2 ,cn_jon_kbn_3 ,cn_jon_kbn_4 ,cn_jon_kbn_5 ,cn_job_kbn_6 ) ) THEN
/* Ver.1.36 ADD END   */
        l_ext_attrib_values_tab(ln_cnt).attribute_value     := io_inst_base_data_rec.machinery_status1;
/* Ver.1.36 ADD START */
      ELSE
        l_ext_attrib_values_tab(ln_cnt).attribute_value     := l_ext_attrib_rec.attribute_value;
      END IF;
/* Ver.1.36 ADD END   */
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
      ln_machinery_status1_wk := l_ext_attrib_rec.attribute_value;
    END IF;
--
    -- 機器状態2（状態詳細）
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jotai_kbn2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status2;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    /* 2009.04.27 K.Satomura T1_0490対応 START */
    -- 機器状態3（廃棄情報）
    l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jotai_kbn3);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL) THEN
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status3;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
    /* 2009.04.27 K.Satomura T1_0490対応 END */
    -- 入庫日
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_nyuko_dt);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.stock_date;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 引揚会社コード
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_hikisakigaisya_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.withdraw_company_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 引揚事業所コード
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_hikisakijigyosyo_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.withdraw_location_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 転売廃棄業者
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_tenhai_tanto);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_disposal_vendor;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 転売廃棄伝票��
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_tenhai_den_no);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_disposal_slip_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 所有者
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_syoyu_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.owner_company_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 転売廃棄状況フラグ
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_tenhai_flg);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_disposal_flag;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 転売完了区分
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_kanryo_kbn);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_completion_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 削除フラグ
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sakujo_flg);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.delete_flag;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- 安全設置基準
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_safty_level);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.safe_setting_standard;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
/* Ver.1.34 ADD START */
/* Ver.1.35 Q2239 ADD START */
    -- 作業区分が１：新台設置、２：旧台設置、３：新台代替、４：旧台代替、５：引揚、６：店内移動の場合
    IF ( ln_job_kbn IN ( cn_jon_kbn_1 ,cn_jon_kbn_2 ,cn_jon_kbn_3 ,cn_jon_kbn_4 ,cn_jon_kbn_5 ,cn_job_kbn_6 ) ) THEN
/* Ver.1.35 Q2239 ADD END */
      -- 最終有効実作業日時
      l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(ln_instance_id, cv_last_act_dt);
      IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
        ln_cnt := ln_cnt + 1;
        l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
        l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(io_inst_base_data_rec.actual_work_date) ||
                                                                 io_inst_base_data_rec.actual_work_time1;
        l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
        l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
      ELSE
        ln_cnt2 := ln_cnt2 + 1;
        l_cre_ext_attr_values_tab(ln_cnt2).instance_id        := ln_instance_id;
        l_cre_ext_attr_values_tab(ln_cnt2).attribute_id       := gr_ext_attribs_id_rec.last_act_date_time;
        l_cre_ext_attr_values_tab(ln_cnt2).attribute_value    := TO_CHAR(io_inst_base_data_rec.actual_work_date) ||
                                                                 io_inst_base_data_rec.actual_work_time1;
        -- 設置機器拡張属性値登録フラグ「Y」
        lv_ib_ext_attr_flg := cv_flg_yes;
      END IF;
/* Ver.1.35 Q2239 ADD START */
    END IF;
/* Ver.1.35 Q2239 ADD END */
--
/* Ver.1.34 ADD END */
--
    -- ============================
    -- 3.顧客情報抽出
    -- ============================
--
    -- 作業データ.実作業日の年月 = 業務処理日付の前月の年月
    BEGIN
      SELECT casv.account_number                                      -- 顧客コード
            ,casv.cust_account_id                                     -- アカウントID
            ,casv.party_site_id                                       -- パーティサイトID
            ,casv.party_id                                            -- パーティID
            ,casv.area_code                                           -- 地区コード
            /*20090325_yabuki_ST150 START*/
            ,casv.sale_base_code                                      -- 売上拠点コード
            /*s_yabuki_ST150 END*/
            /*2009.09.03 M.Maruyama 0001192対応 START*/
            ,casv.past_sale_base_code                                 -- 前月売上拠点コード
            ,ciis.install_date                                        -- 設置日
            /*2009.09.03 M.Maruyama 0001192対応 END*/
      INTO   lv_account_num
            ,ln_account_id
            ,ln_party_site_id
            ,ln_party_id
            ,lv_area_code
            /*20090325_yabuki_ST150 START*/
            ,lt_sale_base_code
            /*20090325_yabuki_ST150 END*/
            /*2009.09.03 M.Maruyama 0001192対応 START*/
            ,lt_past_sale_base_code
            ,ld_ib_install_date
            /*2009.09.03 M.Maruyama 0001192対応 END*/
      FROM   xxcso_cust_acct_sites_v casv                               -- 顧客マスタサイトビュー
            ,csi_item_instances      ciis                               -- インストールベースマスタ
      WHERE  ciis.external_reference     = lv_install_code
        AND  ciis.owner_party_account_id = casv.cust_account_id
        AND  casv.account_status         = cv_active
        AND  casv.acct_site_status       = cv_active
        AND  casv.party_status           = cv_active
        AND  casv.party_site_status      = cv_active
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_24              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10=> SQLERRM                       -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
      -- 先月末年月の取得
      l_ext_attrib_rec_wk := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
      lv_last_year_month := l_ext_attrib_rec_wk.attribute_value;
--
    /*20090528_Ohtsuki_T1_1203 START*/
    -- 作業区分が【店内移動】【是正】【出張修理】【整備】【転送】【転売】【廃棄引取】以外の場合
    IF (io_inst_base_data_rec.job_kbn  NOT IN 
         (cn_job_kbn_6,cn_job_kbn_8,cn_job_kbn_9,cn_job_kbn_10,cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_17)) THEN
    /*20090528_Ohtsuki_T1_1203 END*/
    
      -- 先月末年月≠業務処理日付の前月の年月
      IF (lv_last_year_month <> TO_NUMBER(TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM')) OR
          lv_last_year_month IS NULL) THEN
          
        -- 実作業日の年月＝業務処理日付の前月の年月
        IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM')) THEN
--
          /*2009.09.03 M.Maruyama 0001192対応 START*/
          -- 作業データ．作業区分が「新台設置」「新台代替」「旧台設置」「旧台代替」のいずれか、
          --   且つ物件ファイル．物件コード＝作業データ．物件コード１
          IF ((io_inst_base_data_rec.job_kbn IN (cn_jon_kbn_1,cn_jon_kbn_2,cn_jon_kbn_3,cn_jon_kbn_4)) 
            AND (lv_install_code = lv_install_code1)) THEN
--
            -- 先月末年月の取得
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- 先月末設置先顧客コード(作業データ.顧客データ1)
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_account_num1;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- 先月末機器状態(物件ファイル.機器状態1 [稼働中])
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
          -- 作業データ．作業区分が「新台代替」「旧台代替」「引揚」のいずれか、
          --   且つ 物件ファイル．物件コード＝作業データ．物件コード２
          ELSIF ((io_inst_base_data_rec.job_kbn IN (cn_jon_kbn_3,cn_jon_kbn_4,cn_jon_kbn_5))
               AND (lv_install_code = lv_install_code2)) THEN
--
            -- 機器区分取得
            BEGIN
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 START */
--              SELECT SUBSTRB(phcv.hazard_class,1,1) -- 機器区分（危険度区分）
              SELECT SUBSTRB(phcv.hazard_class,1,INSTRB(phcv.hazard_class,cv_msg_part_only,1,1)-1) -- 機器区分（危険度区分）
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 END */
              INTO   lv_hazard_class
              FROM   po_un_numbers_vl     punv               -- 国連番号マスタビュー
                    ,po_hazard_classes_vl phcv               -- 危険度区分マスタビュー
              WHERE  punv.un_number        = lv_un_number
                AND  punv.hazard_class_id  = phcv.hazard_class_id
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データが存在しない場合
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_23              -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                               ,iv_token_value1 => cv_po_un_numbers_info         -- トークン値1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                               ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                               ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                               ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                               ,iv_token_value6 => lv_install_code1              -- トークン値6
                               ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                               ,iv_token_value7 => lv_install_code2              -- トークン値7
                               ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                               ,iv_token_value8 => lv_account_num1               -- トークン値8
                               ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                               ,iv_token_value9 => lv_account_num2               -- トークン値9
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
                -- 抽出に失敗した場合
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_24              -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                               ,iv_token_value1 => cv_po_un_numbers_info         -- トークン値1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                               ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                               ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                               ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                               ,iv_token_value6 => lv_install_code1              -- トークン値6
                               ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                               ,iv_token_value7 => lv_install_code2              -- トークン値7
                               ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                               ,iv_token_value8 => lv_account_num1               -- トークン値8
                               ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                               ,iv_token_value9 => lv_account_num2               -- トークン値9
                               ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                               ,iv_token_value10=> SQLERRM                       -- トークン値10
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
            END;
--
            -- 前月売上拠点コード取得
            BEGIN
              SELECT past_sale_base_code                                      -- 前月売上拠点コード
              INTO   lt_sl_bs_cd_fr_bfr_mnth_dt
              FROM   xxcso_cust_acct_sites_v casv                               -- 顧客マスタサイトビュー
                    ,csi_item_instances      ciis                               -- インストールベースマスタ
              WHERE  ciis.external_reference     = lv_install_code2
                AND  ciis.owner_party_account_id = casv.cust_account_id
                AND  casv.account_status         = cv_active
                AND  casv.acct_site_status       = cv_active
                AND  casv.party_status           = cv_active
                AND  casv.party_site_status      = cv_active
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データが存在しない場合
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_23              -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                               ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                               ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                               ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                               ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                               ,iv_token_value6 => lv_install_code1              -- トークン値6
                               ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                               ,iv_token_value7 => lv_install_code2              -- トークン値7
                               ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                               ,iv_token_value8 => lv_account_num1               -- トークン値8
                               ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                               ,iv_token_value9 => lv_account_num2               -- トークン値9
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
                -- 抽出に失敗した場合
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_24              -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                               ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                               ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                               ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                               ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                               ,iv_token_value6 => lv_install_code1              -- トークン値6
                               ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                               ,iv_token_value7 => lv_install_code2              -- トークン値7
                               ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                               ,iv_token_value8 => lv_account_num1               -- トークン値8
                               ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                               ,iv_token_value9 => lv_account_num2               -- トークン値9
                               ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                               ,iv_token_value10=> SQLERRM                       -- トークン値10
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
            END;
-- Ver.1.39 Add Start
            -- 取得した機器区分が'1'（自販機）の場合
            IF ( lv_hazard_class = cv_kbn1 ) THEN
              -- 会社別引揚拠点コードを取得する
              BEGIN
                SELECT flvv.attribute1  AS  comp_withdraw_base_code  -- 会社別引揚拠点コード
                INTO   lt_comp_withdraw_base_code
                FROM   xxcfr_bd_dept_comp_info_v xbdciv              -- 基準日部門会社情報ビュー
                      ,fnd_lookup_values_vl      flvv                -- 参照表(会社別引揚拠点コード)
                WHERE  xbdciv.dept_code       = lt_sl_bs_cd_fr_bfr_mnth_dt           -- 前月売上拠点コード
                AND    xbdciv.set_of_books_id = gn_set_of_bks_id                     -- 会計帳簿ID
                AND    xbdciv.enabled_flag    = 'Y'
                AND    ld_actual_work_date BETWEEN xbdciv.comp_start_date            -- 実作業日
                                               AND NVL( xbdciv.comp_end_date, ld_actual_work_date )
                AND    flvv.lookup_type       = cv_cp_withdraw_base_code_type
                AND    flvv.lookup_code       = xbdciv.company_code_bd
                AND    flvv.enabled_flag      = 'Y'
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lt_comp_withdraw_base_code := NULL;
              END;
              --
              IF ( lt_comp_withdraw_base_code IS NOT NULL ) THEN
                -- ====================
                -- 引揚拠点顧客情報取得
                -- ====================
                BEGIN
                  SELECT casv.cust_account_id                                     -- アカウントID
                        ,casv.party_site_id                                       -- パーティサイトID
                        ,casv.party_id                                            -- パーティID
                        ,casv.area_code                                           -- 地区コード
                  INTO   ln_account_id_withdraw
                        ,ln_party_site_id_withdraw
                        ,ln_party_id_withdraw
                        ,lv_area_code_withdraw
                  FROM   xxcso_cust_acct_sites_v casv                             -- 顧客マスタサイトビュー
                  WHERE  casv.account_number    = lt_comp_withdraw_base_code
                    AND  casv.account_status    = cv_active
                    AND  casv.acct_site_status  = cv_active
                    AND  casv.party_status      = cv_active
                    AND  casv.party_site_status = cv_active
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    -- データが存在しない場合
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_app_name                  -- アプリケーション短縮名
                                   ,iv_name         => cv_tkn_number_14             -- メッセージコード
                                   ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                                   ,iv_token_value1 => cv_cust_acct_sites_info      -- トークン値1
                                   ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                                   ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                                   ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                                   ,iv_token_value3 => lt_comp_withdraw_base_code   -- トークン値3
                                 );
                    lv_errbuf := lv_errmsg;
                    RAISE skip_process_expt;
                    -- 抽出に失敗した場合
                  WHEN OTHERS THEN
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_app_name                  -- アプリケーション短縮名
                                   ,iv_name         => cv_tkn_number_15             -- メッセージコード
                                   ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                                   ,iv_token_value1 => cv_cust_acct_sites_info      -- トークン値1
                                   ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                                   ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                                   ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                                   ,iv_token_value3 => lt_comp_withdraw_base_code   -- トークン値3
                                   ,iv_token_name4  => cv_tkn_errmsg                -- トークンコード4
                                   ,iv_token_value4 => SQLERRM                      -- トークン値4
                                 );
                    lv_errbuf := lv_errmsg;
                    RAISE skip_process_expt;
                END;
              END IF;
            -- 取得した機器区分≠'1'（什器）の場合
            ELSIF ( lv_hazard_class <> cv_kbn1 ) THEN
              -- 会社別什器引揚拠点コードを取得する
              BEGIN
                SELECT flvv.attribute1  AS  comp_j_wthdrw_base_code  -- 会社別什器引揚拠点コード
                INTO   lt_comp_j_wthdrw_base_code
                FROM   xxcfr_bd_dept_comp_info_v xbdciv              -- 基準日部門会社情報ビュー
                      ,fnd_lookup_values_vl      flvv                -- 参照表(会社別引揚拠点コード)
                WHERE  xbdciv.dept_code       = lt_sl_bs_cd_fr_bfr_mnth_dt           -- 前月売上拠点コード
                AND    xbdciv.set_of_books_id = gn_set_of_bks_id                     -- 会計帳簿ID
                AND    xbdciv.enabled_flag    = 'Y'
                AND    ld_actual_work_date BETWEEN xbdciv.comp_start_date            -- 実作業日
                                               AND NVL( xbdciv.comp_end_date, ld_actual_work_date )
                AND    flvv.lookup_type       = cv_cp_j_wthdrw_base_code_type
                AND    flvv.lookup_code       = xbdciv.company_code_bd
                AND    flvv.enabled_flag      = 'Y'
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lt_comp_j_wthdrw_base_code := NULL;
              END;
              --
              IF ( lt_comp_j_wthdrw_base_code IS NOT NULL ) THEN
                -- ========================
                -- 什器引揚拠点顧客情報取得
                -- ========================
                BEGIN
                  SELECT casv.cust_account_id                                     -- アカウントID
                        ,casv.party_site_id                                       -- パーティサイトID
                        ,casv.party_id                                            -- パーティID
                        ,casv.area_code                                           -- 地区コード
                  INTO   ln_jyki_account_id
                        ,ln_jyki_party_site_id
                        ,ln_jyki_party_id
                        ,lv_jyki_area_code
                  FROM   xxcso_cust_acct_sites_v casv                             -- 顧客マスタサイトビュー
                  WHERE  casv.account_number    = lt_comp_j_wthdrw_base_code
                    AND  casv.account_status    = cv_active
                    AND  casv.acct_site_status  = cv_active
                    AND  casv.party_status      = cv_active
                    AND  casv.party_site_status = cv_active
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    -- データが存在しない場合
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_app_name                  -- アプリケーション短縮名
                                   ,iv_name         => cv_tkn_number_14             -- メッセージコード
                                   ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                                   ,iv_token_value1 => cv_cust_acct_sites_info1     -- トークン値1
                                   ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                                   ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                                   ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                                   ,iv_token_value3 => lt_comp_j_wthdrw_base_code   -- トークン値3
                                 );
                    lv_errbuf := lv_errmsg;
                    RAISE skip_process_expt;
                    -- 抽出に失敗した場合
                  WHEN OTHERS THEN
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_app_name                  -- アプリケーション短縮名
                                   ,iv_name         => cv_tkn_number_15             -- メッセージコード
                                   ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                                   ,iv_token_value1 => cv_cust_acct_sites_info1     -- トークン値1
                                   ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                                   ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                                   ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                                   ,iv_token_value3 => lt_comp_j_wthdrw_base_code   -- トークン値3
                                   ,iv_token_name4  => cv_tkn_errmsg                -- トークンコード4
                                   ,iv_token_value4 => SQLERRM                      -- トークン値4
                                 );
                    lv_errbuf := lv_errmsg;
                    RAISE skip_process_expt;
                END;
              END IF;
            END IF;
-- Ver.1.39 Add End
--
-- Ver.1.39 Mod Start
--            -- 物件ファイル．機種をもとに機種マスタより導出した機器区分＝'1'（自販機）、
--            -- 且つプロファイル「XXCSO:引揚拠点コード」のサイト値がNULL以外
--            -- 且つ自拠点作業以外の場合
--            /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD START */
----            IF ((lv_hazard_class = cv_kbn1) AND (gv_withdraw_base_code IS NOT NULL)) THEN
--            IF ( (lv_hazard_class = cv_kbn1) AND (gv_withdraw_base_code IS NOT NULL) AND
--                 ( (io_inst_base_data_rec.withdraw_company_code || io_inst_base_data_rec.withdraw_location_code) <> gt_own_base_wkcmp_code )
--            ) THEN
--            /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD END */
            -- 物件ファイル．機種をもとに機種マスタより導出した機器区分＝'1'（自販機）、
            -- 且つ会社別引揚拠点コードがNULL以外
            -- 且つ自拠点作業以外の場合
            IF ( (lv_hazard_class = cv_kbn1) AND (lt_comp_withdraw_base_code IS NOT NULL) AND
                 ( (io_inst_base_data_rec.withdraw_company_code || io_inst_base_data_rec.withdraw_location_code) <> gt_own_base_wkcmp_code )
            ) THEN
-- Ver.1.39 Mod End
--
              -- 先月末年月の取得
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末設置先顧客コード(プロファイル「XXCSO:引揚拠点コード」のサイト値)
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                -- Ver.1.39 Mod Start
                --l_ext_attrib_values_tab(ln_cnt).attribute_value       := gv_withdraw_base_code;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := lt_comp_withdraw_base_code;
                -- Ver.1.39 Mod End
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末機器状態(物件ファイル.機器状態1 [稼働中])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
-- Ver.1.39 Mod Start
--            -- 物件ファイル．機種をもとに機種マスタより導出した機器区分≠'1'（什器）、
--            --   且つプロファイル「XXCSO:什器引揚拠点コード」のサイト値がNULL以外
--            --   且つ自拠点作業以外の場合
--            /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD START */
----            ELSIF ((lv_hazard_class <> cv_kbn1) AND (gv_jyki_withdraw_base_code IS NOT NULL)) THEN
--            ELSIF ( (lv_hazard_class <> cv_kbn1) AND (gv_jyki_withdraw_base_code IS NOT NULL) AND
--                    ( (io_inst_base_data_rec.withdraw_company_code || io_inst_base_data_rec.withdraw_location_code) <> gt_own_base_wkcmp_code )
--            ) THEN
--            /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD END */
            -- 物件ファイル．機種をもとに機種マスタより導出した機器区分≠'1'（什器）、
            --   且つ会社別什器引揚拠点コードがNULL以外
            --   且つ自拠点作業以外の場合
            ELSIF ( (lv_hazard_class <> cv_kbn1) AND (lt_comp_j_wthdrw_base_code IS NOT NULL) AND
                    ( (io_inst_base_data_rec.withdraw_company_code || io_inst_base_data_rec.withdraw_location_code) <> gt_own_base_wkcmp_code )
            ) THEN
-- Ver.1.39 Mod End
--
              -- 先月末年月の取得
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末設置先顧客コード(プロファイル「XXCSO:什器引揚拠点コード」のサイト値)
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                -- Ver.1.39 Mod Start
                --l_ext_attrib_values_tab(ln_cnt).attribute_value       := gv_jyki_withdraw_base_code;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := lt_comp_j_wthdrw_base_code;
                -- Ver.1.39 Mod End
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末機器状態(物件ファイル.機器状態1 [稼働中])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
            -- 上記以外
            ELSE
--
              -- 先月末年月の取得
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末設置先顧客コード(作業データ．顧客コード２を検索条件に取得した顧客マスタの前月売上拠点コード)
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := lt_sl_bs_cd_fr_bfr_mnth_dt;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末機器状態(物件ファイル.機器状態1 [稼働中])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
            END IF;
          END IF;
        -- 実作業日の年月＝業務処理日付の年月
        -- ELSIF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM') AND
        --       lv_last_year_month IS NOT NULL) THEN
        ELSIF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')) THEN
--
          -- 物件マスタ．先月末年月が未設定
          IF (lv_last_year_month IS NULL) THEN
            -- 作業データ．実作業日の年月＝物件マスタ．導入日（設置日）の年月
            IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_ib_install_date,'YYYYMM')) THEN
              NULL;
            ELSE
          /*2009.09.03 M.Maruyama 0001192対応 END*/
--
              -- 先月末年月の取得
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末設置先顧客コード(物件マスタに紐付く顧客コード[更新前の状態])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_account_num;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- 先月末機器状態(物件マスタ.機器状態1 [稼働中])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := ln_machinery_status1_wk;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
            END IF;
          /*2009.09.03 M.Maruyama 0001192対応 START*/
          ELSE
--
            -- 先月末年月の取得
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- 先月末設置先顧客コード(物件マスタに紐付く顧客コード[更新前の状態])
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_account_num;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- 先月末機器状態(物件ファイル.機器状態1 [稼働中])
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := ln_machinery_status1_wk;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
          END IF;
          /*2009.09.03 M.Maruyama 0001192対応 END*/
        END IF;
--
      END IF;
--
    /*20090528_Ohtsuki_T1_1203 START*/
    END IF;
    /*20090528_Ohtsuki_T1_1203 END*/
    -- 作業区分が「新台設置」、「新台代替」、「旧台設置」または「旧台代替」、
    -- かつ物件データの物件コードが作業データの物件コード１(新設置先)と同一の場合
    IF ((ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_2 OR
        ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4)
          AND lv_install_code = lv_install_code1) THEN
      -- ============================
      -- 3.�@顧客マスタ情報(更新用)抽出
      -- ============================
--
      BEGIN
        SELECT casv.cust_account_id                                   -- 顧客アカウントID
              ,casv.party_site_id                                     -- パーティサイトID
              ,casv.party_id                                          -- パーティID
              ,casv.area_code                                         -- 地区コード
        INTO   ln_account_id
              ,ln_party_site_id
              ,ln_party_id
              ,lv_area_code
       FROM   xxcso_cust_acct_sites_v casv                           -- 顧客マスタサイトビュー
        WHERE  casv.account_number    = lv_account_num1
          AND  casv.account_status    = cv_active
          AND  casv.acct_site_status  = cv_active
          AND  casv.party_status      = cv_active
          AND  casv.party_site_status = cv_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_23              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_24             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                         ,iv_token_value10=> SQLERRM                       -- トークン値10
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
      END;
--
    -- 作業区分が「新台代替」或いは「旧台代替」或いは「引揚」、
    -- かつ物件データの物件コードが作業データの物件コード２(現設置先)と同一である場合
    ELSIF ((ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4 OR ln_job_kbn = cn_jon_kbn_5)
          AND lv_install_code = lv_install_code2) THEN
--
      -- =======================
      -- 3.最終顧客コード抽出
      -- =======================
--
      -- 顧客コード
      lv_last_cust_num := lv_account_num;
      -- アカウントID
      ln_account_id    := ln_account_id;
      -- パーティサイトID
      ln_party_site_id := ln_party_site_id;
      -- パーティID
      ln_party_id      := ln_party_id;
      -- 地区コード
      lv_area_code     := lv_area_code;
--
      -- 最終顧客コード
      l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_ven_kyaku_last);
      IF (l_ext_attrib_rec.attribute_id IS NOT NULL)  THEN 
        ln_cnt := ln_cnt + 1;
        l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
        l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_last_cust_num;
        l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
        l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
      END IF;
--
      -- 機器区分が’1’かつ、自拠点作業以外の場合
      IF (io_inst_base_data_rec.machinery_kbn = cv_kbn1 AND
      /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD START */
--          gv_withdraw_base_code IS NOT NULL)THEN
-- Ver.1.40 Del Start
--          -- Ver.1.39 Mod Start
--          --( gv_withdraw_base_code IS NOT NULL ) AND
--          ( lt_comp_withdraw_base_code IS NOT NULL ) AND
--          -- Ver.1.39 Mod End
-- Ver.1.40 Del End
          ( (io_inst_base_data_rec.withdraw_company_code || io_inst_base_data_rec.withdraw_location_code) <> gt_own_base_wkcmp_code )
      ) THEN
      /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD END */
        -- アカウントID、パーティサイトID、パーティID、地区コードの設定
-- Ver.1.40 Add Start
          IF ( lt_comp_withdraw_base_code IS NULL ) THEN
            -- メッセージ出力用に拠点コードを保持
            BEGIN
              SELECT CASE
                     WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                     THEN lt_sale_base_code             -- 売上拠点コード
                     ELSE lt_past_sale_base_code        -- 前月売上拠点コード
                     END
              INTO   lt_dept_code
              FROM   dual;
            END;
            -- 会社別引揚拠点コードに紐付く顧客情報を取得する
            BEGIN
              SELECT flvv.attribute1       AS  comp_withdraw_base_code  -- 会社別引揚拠点コード
                    ,casv.cust_account_id  AS  comp_withdraw_base_code  -- アカウントID
                    ,casv.party_site_id    AS  party_site_id_withdraw   -- パーティサイトID
                    ,casv.party_id         AS  party_id_withdraw        -- パーティID
                    ,casv.area_code        AS  area_code_withdraw       -- 地区コード
              INTO   lt_comp_withdraw_base_code
                    ,ln_account_id_withdraw
                    ,ln_party_site_id_withdraw
                    ,ln_party_id_withdraw
                    ,lv_area_code_withdraw
              FROM   xxcfr_bd_dept_comp_info_v xbdciv              -- 基準日部門会社情報ビュー
                    ,fnd_lookup_values_vl      flvv                -- 参照表(会社別引揚拠点コード)
                    ,xxcso_cust_acct_sites_v   casv                -- 顧客マスタサイトビュー
              WHERE  xbdciv.dept_code          =  (CASE
                                                   WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                                                   THEN lt_sale_base_code             -- 売上拠点コード
                                                   ELSE lt_past_sale_base_code        -- 前月売上拠点コード
                                                   END)
              AND    xbdciv.set_of_books_id    = gn_set_of_bks_id                     -- 会計帳簿ID
              AND    xbdciv.enabled_flag       = 'Y'
              AND    ld_actual_work_date BETWEEN xbdciv.comp_start_date            -- 実作業日
                                             AND NVL( xbdciv.comp_end_date, ld_actual_work_date )
              AND    flvv.lookup_type          = cv_cp_withdraw_base_code_type
              AND    flvv.lookup_code          = xbdciv.company_code_bd
              AND    flvv.enabled_flag         = 'Y'
              AND    casv.account_number(+)    = flvv.attribute1      -- 会社別引揚拠点コード
              AND    casv.account_status(+)    = cv_active
              AND    casv.acct_site_status(+)  = cv_active
              AND    casv.party_status(+)      = cv_active
              AND    casv.party_site_status(+) = cv_active
              ;
              IF ( ln_account_id_withdraw IS NULL ) THEN
                  RAISE skip_process_expt;
              END IF;
            EXCEPTION
              WHEN skip_process_expt THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                  -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_14             -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                               ,iv_token_value1 => cv_cust_acct_sites_info      -- トークン値1
                               ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                               ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                               ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                               ,iv_token_value3 => lt_comp_withdraw_base_code   -- トークン値3
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                  -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_15             -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                               ,iv_token_value1 => cv_cust_acct_sites_info      -- トークン値1
                               ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                               ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                               ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                               ,iv_token_value3 => lt_dept_code                 -- トークン値3
                               ,iv_token_name4  => cv_tkn_errmsg                -- トークンコード4
                               ,iv_token_value4 => SQLERRM                      -- トークン値4
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
            END;
          END IF;
-- Ver.1.40 Add End
        -- Ver.1.39 Mod Start
        --ln_account_id     := gn_account_id;
        --ln_party_site_id  := gn_party_site_id;
        --ln_party_id       := gn_party_id;
        --lv_area_code      := gv_area_code;
        ln_account_id     := ln_account_id_withdraw;
        ln_party_site_id  := ln_party_site_id_withdraw;
        ln_party_id       := ln_party_id_withdraw;
        lv_area_code      := lv_area_code_withdraw;
        -- Ver.1.39 Mod End
      -- 機器区分が’1’以外かつ、自拠点作業以外の場合
      ELSIF (io_inst_base_data_rec.machinery_kbn <> cv_kbn1 AND
      /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD START */
--             gv_jyki_withdraw_base_code IS NOT NULL) THEN
-- Ver.1.40 Del Start
--             -- Ver.1.39 Mod Start
--             --( gv_jyki_withdraw_base_code IS NOT NULL ) AND
--             ( lt_comp_j_wthdrw_base_code IS NOT NULL ) AND
--             -- Ver.1.39 Mod End
-- Ver.1.40 Del End
             ( (io_inst_base_data_rec.withdraw_company_code || io_inst_base_data_rec.withdraw_location_code) <> gt_own_base_wkcmp_code )
      ) THEN
      /* 2015-09-04 S.Yamashita E_本稼動_13070対応 MOD END */
        -- アカウントID、パーティサイトID、パーティID、地区コードの設定
-- Ver.1.40 Add Start
          IF ( lt_comp_j_wthdrw_base_code IS NULL ) THEN
            -- メッセージ出力用に拠点コードを保持
            BEGIN
              SELECT CASE
                     WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                     THEN lt_sale_base_code             -- 売上拠点コード
                     ELSE lt_past_sale_base_code        -- 前月売上拠点コード
                     END
              INTO   lt_dept_code
              FROM   dual;
            END;
            -- 会社別什器引揚拠点コードに紐付く顧客情報を取得する
            BEGIN
              SELECT flvv.attribute1       AS  comp_j_wthdrw_base_code  -- 会社別什器引揚拠点コード
                    ,casv.cust_account_id  AS  jyki_account_id          -- アカウントID
                    ,casv.party_site_id    AS  jyki_party_site_id       -- パーティサイトID
                    ,casv.party_id         AS  jyki_party_id            -- パーティID
                    ,casv.area_code        AS  jyki_area_code           -- 地区コード
              INTO   lt_comp_j_wthdrw_base_code
                    ,ln_jyki_account_id
                    ,ln_jyki_party_site_id
                    ,ln_jyki_party_id
                    ,lv_jyki_area_code
              FROM   xxcfr_bd_dept_comp_info_v xbdciv              -- 基準日部門会社情報ビュー
                    ,fnd_lookup_values_vl      flvv                -- 参照表(会社別引揚拠点コード)
                    ,xxcso_cust_acct_sites_v   casv                -- 顧客マスタサイトビュー
              WHERE  xbdciv.dept_code          =  (CASE
                                                   WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                                                   THEN lt_sale_base_code             -- 売上拠点コード
                                                   ELSE lt_past_sale_base_code        -- 前月売上拠点コード
                                                   END)
              AND    xbdciv.set_of_books_id    = gn_set_of_bks_id                     -- 会計帳簿ID
              AND    xbdciv.enabled_flag       = 'Y'
              AND    ld_actual_work_date BETWEEN xbdciv.comp_start_date            -- 実作業日
                                             AND NVL( xbdciv.comp_end_date, ld_actual_work_date )
              AND    flvv.lookup_type          = cv_cp_j_wthdrw_base_code_type
              AND    flvv.lookup_code          = xbdciv.company_code_bd
              AND    flvv.enabled_flag         = 'Y'
              AND    casv.account_number(+)    = flvv.attribute1      -- 会社別什器引揚拠点コード
              AND    casv.account_status(+)    = cv_active
              AND    casv.acct_site_status(+)  = cv_active
              AND    casv.party_status(+)      = cv_active
              AND    casv.party_site_status(+) = cv_active
              ;
              IF ( ln_jyki_account_id IS NULL ) THEN
                  RAISE skip_process_expt;
              END IF;
            EXCEPTION
              WHEN skip_process_expt THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                  -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_14             -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                               ,iv_token_value1 => cv_cust_acct_sites_info1      -- トークン値1
                               ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                               ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                               ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                               ,iv_token_value3 => lt_comp_j_wthdrw_base_code   -- トークン値3
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
              -- 抽出に失敗した場合
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                  -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_15             -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                               ,iv_token_value1 => cv_cust_acct_sites_info1     -- トークン値1
                               ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                               ,iv_token_value2 => cv_cust_account_number       -- トークン値2
                               ,iv_token_name3  => cv_tkn_base_value            -- トークンコード3
                               ,iv_token_value3 => lt_dept_code                 -- トークン値3
                               ,iv_token_name4  => cv_tkn_errmsg                -- トークンコード4
                               ,iv_token_value4 => SQLERRM                      -- トークン値4
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
            END;
          END IF;
-- Ver.1.40 Add End
        -- Ver.1.39 Mod Start
        --ln_account_id     := gn_jyki_account_id;
        --ln_party_site_id  := gn_jyki_party_site_id;
        --ln_party_id       := gn_jyki_party_id;
        --lv_area_code      := gv_jyki_area_code;
        ln_account_id     := ln_jyki_account_id;
        ln_party_site_id  := ln_jyki_party_site_id;
        ln_party_id       := ln_jyki_party_id;
        lv_area_code      := lv_jyki_area_code;
        -- Ver.1.39 Mod End
        --
      /*20090325_yabuki_ST150 START*/
      ELSE
        -- ============================
        -- 3.引揚前設置先顧客の売上拠点情報抽出
        -- ============================
        BEGIN
          SELECT casv.account_number                                      -- 顧客コード
                ,casv.cust_account_id                                     -- アカウントID
                ,casv.party_site_id                                       -- パーティサイトID
                ,casv.party_id                                            -- パーティID
                ,casv.area_code                                           -- 地区コード
          INTO   lv_account_num
                ,ln_account_id
                ,ln_party_site_id
                ,ln_party_id
                ,lv_area_code
          FROM   xxcso_cust_acct_sites_v casv                             -- 顧客マスタサイトビュー
          /*2009.09.03 M.Maruyama 0001192対応 START*/
          --WHERE  casv.account_number    = lt_sale_base_code
          WHERE  casv.account_number    = (CASE
                                             WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                                             THEN lt_sale_base_code
                                             ELSE lt_past_sale_base_code
                                           END)
          /*2009.09.03 M.Maruyama 0001192対応 END*/
            AND  casv.account_status    = cv_active
            AND  casv.acct_site_status  = cv_active
            AND  casv.party_status      = cv_active
            AND  casv.party_site_status = cv_active
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- データが存在しない場合
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_23              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_cust_base_info             -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                         );
            lv_errbuf := lv_errmsg;
            RAISE skip_process_expt;
            -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_24              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_cust_base_info             -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10=> SQLERRM                       -- トークン値10
                         );
            lv_errbuf := lv_errmsg;
            RAISE skip_process_expt;
        END;
--
      /*20090325_yabuki_ST150 END*/
      END IF;
--
    END IF;
--
    -- 地区コード
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_chiku_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_area_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD START */
    -- リース区分チェック
    IF ( gv_lease_kbn IS NULL ) THEN
            --リース区分なしエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                   -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_20              -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
                     ,iv_token_value1 => cv_lease_kbn                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                     ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                     ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                     ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                     ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                     ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                     ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                     ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                     ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
                     ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
                     ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
                     ,iv_token_value7 => lv_install_code1              -- トークン値7
                     ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
                     ,iv_token_value8 => lv_install_code2              -- トークン値8
                   );
      lv_errbuf := lv_errmsg;
      RAISE skip_process_expt;
    END IF;
    -- ============================
    -- 3.�C申告地(更新用)抽出
    -- ============================
    -- リース区分：「固定資産」の場合のみ設定する
    IF (gv_lease_kbn = cv_lease_type_assets) THEN
/* Ver.1.34 MOD START */
--      -- �C-1.旧台設置、旧台代替の場合かつ抽出した物件コードが物件コード１と同一(設置用物件)
--      IF ((ln_job_kbn = cn_jon_kbn_2 OR ln_job_kbn = cn_jon_kbn_4)
--        AND lv_install_code = NVL(lv_install_code1, ' ')) THEN
--        --
--        BEGIN
--          -- 購買依頼から申告地を取得
--          SELECT xrlv.declaration_place dclr_place
--          INTO   lv_dclr_place
--          FROM   po_requisition_headers_all prha
--                ,xxcso_requisition_lines_v  xrlv
--          WHERE  prha.segment1              = lt_po_req_number
--          AND    prha.requisition_header_id = xrlv.requisition_header_id
--          AND    xrlv.line_num              = lt_line_num
--          ;
--        EXCEPTION
--          -- 抽出に失敗した場合
--          WHEN OTHERS THEN
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_app_name                   -- アプリケーション短縮名
--                           ,iv_name         => cv_tkn_number_21              -- メッセージコード
--                           ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                           ,iv_token_value1 => cv_dclr_place                 -- トークン値1
--                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
--                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
--                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
--                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
--                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
--                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
--                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
--                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
--                           ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
--                           ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
--                           ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
--                           ,iv_token_value7 => lv_install_code1              -- トークン値7
--                           ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
--                           ,iv_token_value8 => lv_install_code2              -- トークン値8
--                           ,iv_token_name9  => cv_tkn_errmsg                 -- トークンコード9
--                           ,iv_token_value9 => SQLERRM                       -- トークン値9
--                         );
--            lv_errbuf := lv_errmsg;
--            RAISE skip_process_expt;
--        END;
--        -- 申告地更新フラグにYをセット
--        lv_dclr_place_upd_flg := cv_flg_yes;
--      -- �C-2.新台代替、旧台代替、引揚の時かつ抽出した物件コードが物件コード２と同一(引揚用物件)
--      ELSIF (( ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4 OR ln_job_kbn = cn_jon_kbn_5 )
--        AND lv_install_code = lv_install_code2 ) THEN
--          /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
--          -- 自拠点作業以外の場合
--          IF ( (io_inst_base_data_rec.withdraw_company_code || io_inst_base_data_rec.withdraw_location_code) <> gt_own_base_wkcmp_code ) THEN
--          /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
--            -- プロファイル取得した引揚用の申告地を設定
--            lv_dclr_place := gv_dclr_place_code;
--            -- 申告地更新フラグにYをセット
--            lv_dclr_place_upd_flg := cv_flg_yes;
--          /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD START */
--          ELSE
--            -- 自拠点作業の場合、申告地更新フラグにNをセット
--            lv_dclr_place_upd_flg := cv_flg_no;
--          END IF;
--          /* 2015-09-04 S.Yamashita E_本稼動_13070対応 ADD END */
--      END IF;
--      -- 更新対象の作業区分（�C-1、�C-2の条件に該当する）の場合
--      IF ( lv_dclr_place_upd_flg = cv_flg_yes ) THEN
--        -- 申告地が取得できた場合、更新する
--        IF (lv_dclr_place IS NOT NULL) THEN
--          -- 申告地の更新
--          l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_dclr_place);
--          IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
--            ln_cnt := ln_cnt + 1;
--            l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
--            l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_dclr_place;
--            l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
--            l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
--          END IF;
--        ELSE
--          -- 申告地なしエラー
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                   -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_20              -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                         ,iv_token_value1 => cv_dclr_place                 -- トークン値1
--                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
--                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
--                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
--                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
--                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
--                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
--                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
--                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
--                         ,iv_token_name6  => cv_tkn_work_kbn               -- トークンコード6
--                         ,iv_token_value6 => TO_CHAR(ln_job_kbn)           -- トークン値6
--                         ,iv_token_name7  => cv_tkn_bukken1                -- トークンコード7
--                         ,iv_token_value7 => lv_install_code1              -- トークン値7
--                         ,iv_token_name8  => cv_tkn_bukken2                -- トークンコード8
--                         ,iv_token_value8 => lv_install_code2              -- トークン値8
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE skip_process_expt;
--        END IF;
--      --
--      END IF;
--
      -- 申告地
      l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_dclr_place);
      IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
        ln_cnt := ln_cnt + 1;
        l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
        l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.declaration_place;
        l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
        l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
      END IF;
--
      -- 固定資産移動日
      l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(ln_instance_id, cv_fa_move_date);
      IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN
        ln_cnt := ln_cnt + 1;
        l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
        l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(io_inst_base_data_rec.actual_work_date);
        l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
        l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
      ELSE
        ln_cnt2 := ln_cnt2 + 1;
        l_cre_ext_attr_values_tab(ln_cnt2).instance_id        := ln_instance_id;
        l_cre_ext_attr_values_tab(ln_cnt2).attribute_id       := gr_ext_attribs_id_rec.fa_move_date;
        l_cre_ext_attr_values_tab(ln_cnt2).attribute_value    := TO_CHAR(io_inst_base_data_rec.actual_work_date);
        -- 設置機器拡張属性値登録フラグ「Y」
        lv_ib_ext_attr_flg := cv_flg_yes;
      END IF;
/* Ver.1.34 MOD END */
    END IF;
    /* 2014-05-19 Y.Shoji E_本稼動_11853�G対応 ADD END */
    -- ================================
    -- 4.インスタンスパーティ情報抽出
    -- ================================
--
    BEGIN
--
      SELECT cip.instance_party_id                                      -- インスタンスパーティID
            ,cip.object_version_number                                  -- オブジェクトバージョン
      INTO   ln_instance_party_id
            ,ln_object_version_number2
      FROM   csi_i_parties cip                                          -- インスタンスパーティ
      WHERE  cip.instance_id  = io_inst_base_data_rec.instance_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_28             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_inst_party_info           -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                       ,iv_token_value2 => lv_install_code              -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_29             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_inst_party_info           -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                       ,iv_token_value2 => lv_install_code              -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
    -- ================================
    -- 5.インスタンスアカウント情報抽出
    -- ================================
--
    BEGIN
--
      SELECT cipa.ip_account_id                                         -- インスタンスアカウントID
            ,cipa.object_version_number                                 -- オブジェクトバージョン 
      INTO   ln_ip_account_id
            ,ln_object_version_number3
      FROM   csi_ip_accounts cipa
      WHERE  cipa.instance_party_id  = ln_instance_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_28             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_inst_account_info         -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                       ,iv_token_value2 => lv_install_code              -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_29             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_inst_account_info         -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                       ,iv_token_value2 => lv_install_code              -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
    /* 2009.04.13 K.Satomura T1_0418対応 START*/
    -- ================================
    -- 国連番号マスタビュー抽出
    -- ================================
--
    BEGIN
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 START */
--      SELECT SUBSTRB(phcv.hazard_class,1,1) -- 機器区分（危険度区分）
      SELECT SUBSTRB(phcv.hazard_class,1,INSTRB(phcv.hazard_class,cv_msg_part_only,1,1)-1) -- 機器区分（危険度区分）
/* 2014.08.27 S.Yamashita E_本稼動_11719対応 END */
      INTO   lv_hazard_class
      FROM   po_un_numbers_vl     punv               -- 国連番号マスタビュー
            ,po_hazard_classes_vl phcv               -- 危険度区分マスタビュー
      WHERE  punv.un_number        = lv_un_number
        AND  punv.hazard_class_id  = phcv.hazard_class_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_24              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- トークン値1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                       ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6 => lv_install_code1              -- トークン値6
                       ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7 => lv_install_code2              -- トークン値7
                       ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8 => lv_account_num1               -- トークン値8
                       ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9 => lv_account_num2               -- トークン値9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10=> SQLERRM                       -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
    /* 2009.04.13 K.Satomura T1_0418対応 END*/
--
    -- ================================
    -- 6.インスタンスレコード作成
    -- ================================
--
    -- 導入日編集
    IF (io_inst_base_data_rec.last_job_cmpltn_date IS NOT NULL) THEN
      /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
      IF  (io_inst_base_data_rec.last_job_cmpltn_date <> cv_day_zero) THEN
      /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */
        ld_install_date := TO_DATE(
                           TO_CHAR(io_inst_base_data_rec.last_job_cmpltn_date), 'yyyy/mm/dd');
      /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
      END IF;
      /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */                           
    END IF; 
    l_instance_rec.instance_id                := ln_instance_id;               -- インスタンスID
    l_instance_rec.external_reference         := lv_install_code;              -- 外部参照
    /* 2009.06.15 K.Satomura T1_1239対応 SATRT */
    IF (io_inst_base_data_rec.completion_kbn = ct_comp_kbn_comp) THEN
    /* 2009.06.15 K.Satomura T1_1239対応 END */
      l_instance_rec.inv_master_organization_id := gt_inv_mst_org_id;            -- 在庫マスター組織ID
      l_instance_rec.instance_status_id         := ln_instance_status_id;        -- インスタンスステータスID
      /* 2009.04.13 K.Satomura T1_0418対応 START*/
      --l_instance_rec.instance_type_code         := TO_CHAR(ln_machinery_kbn);    -- インスタンスタイプコード
      l_instance_rec.instance_type_code         := TO_CHAR(lv_hazard_class);    -- インスタンスタイプコード
      /* 2009.04.13 K.Satomura T1_0418対応 END*/
      IF (ln_party_site_id IS NOT NULL) THEN
        l_instance_rec.location_type_code       := cv_location_type_code;        -- 現行事業所タイプ
        l_instance_rec.location_id              := ln_party_site_id;             -- 現行事業所ID
      END IF;
      IF (ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_2 OR
          ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4 OR
          ln_job_kbn = cn_jon_kbn_5) THEN
        /* 2009.11.29 T.Maruyama E_本稼動_00120対応 START */
        IF ld_install_date IS NOT NULL THEN
          l_instance_rec.install_date             := ld_install_date;              -- 導入日
        END IF;
        /* 2009.11.29 T.Maruyama E_本稼動_00120対応 END */
      END IF;
      l_instance_rec.attribute1                 := lv_un_number;                 -- 機種(コード)
      l_instance_rec.attribute2                 := lv_install_number;            -- 機番
      /* 2009.05.26 M.Ohtsuki T1_1141対応 START*/
--      -- Ver.1.37 Mod Start
--      IF (io_inst_base_data_rec.new_old_flg = cv_flg_yes) THEN                                        -- 新古台フラグがYの場合
      -- Ver.1.38 Mod Start
--      IF ( ln_job_kbn = cn_jon_kbn_1 ) THEN                                      --新台設置の場合
      IF ( ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3 ) THEN          --新台設置または新台代替の場合
      -- Ver.1.38 Mod End
      -- Ver.1.37 Mod End
        l_instance_rec.attribute3 := TO_CHAR(TO_DATE(TO_CHAR(
          io_inst_base_data_rec.first_install_date),'yyyy/mm/dd'), 'yyyy/mm/dd hh24:mi:ss'); -- 初回設置日
      END IF;
      /* 2009.05.26 M.Ohtsuki T1_1141対応 END*/
      /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START*/
      IF (ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_2 OR
          ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4 OR
          ln_job_kbn = cn_jon_kbn_5 OR ln_job_kbn = cn_job_kbn_6) THEN
        l_instance_rec.attribute4               := cv_flg_no;                    -- 作業依頼中フラグ
        /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
        l_instance_rec.attribute8               := NULL;                         -- 作業依頼中購買依頼番号/顧客CD
        /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      END IF;
      /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END*/
      l_instance_rec.attribute5                 := cv_flg_no;                    -- 新古台フラグ
/* Ver.1.34 DEL START */
--      IF (io_inst_base_data_rec.po_req_number IS NOT NULL AND
--          io_inst_base_data_rec.po_req_number <> 0) THEN
--        l_instance_rec.attribute6                 := io_inst_base_data_rec.po_req_number;  -- 最終発注依頼番号
--      END IF;
/* Ver.1.34 DEL END */
    /* 2009.06.15 K.Satomura T1_1239対応 SATRT */
    ELSE
      l_instance_rec.attribute4 := cv_flg_no; -- 作業依頼中フラグ
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8 := NULL;      -- 作業依頼中購買依頼番号/顧客CD
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      --
    END IF;
    /* 2009.06.15 K.Satomura T1_1239対応 END */
    l_instance_rec.object_version_number      := 
      io_inst_base_data_rec.object_version1;                                   -- オブジェクトバージョン番号
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
--
    -- ====================
    -- 7.パーティデータ作成
    -- ====================
--
    IF (ln_party_id IS NOT NULL) THEN
      ln_cnt := 1;
      l_party_tab(ln_cnt).instance_party_id        := ln_instance_party_id;
      l_party_tab(ln_cnt).party_source_table       := cv_party_source_table;
      l_party_tab(ln_cnt).party_id                 := ln_party_id;
      l_party_tab(ln_cnt).relationship_type_code   := cv_relatnsh_type_code;
      l_party_tab(ln_cnt).contact_flag             := cv_flg_no;
      l_party_tab(ln_cnt).object_version_number    := ln_object_version_number2;
    END IF;
--
    -- ===============================
    -- 8.パーティアカウントデータ作成
    -- ===============================
--
    IF (ln_account_id IS NOT NULL) THEN
      ln_cnt := 1;
      l_account_tab(ln_cnt).ip_account_id          := ln_ip_account_id;
      l_account_tab(ln_cnt).instance_party_id      := ln_instance_party_id;
      l_account_tab(ln_cnt).parent_tbl_index       := cn_num1;
      l_account_tab(ln_cnt).party_account_id       := ln_account_id;
      l_account_tab(ln_cnt).relationship_type_code := cv_relatnsh_type_code;
      l_account_tab(ln_cnt).object_version_number  := ln_object_version_number3;
    END IF;
--
    -- ===============================
    -- 9.取引レコードデータ作成
    -- ===============================
--
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;
--
    -- =================================
    -- 10.標準APIより、物件更新処理を行う
    -- =================================
--
    BEGIN
--
      CSI_ITEM_INSTANCE_PUB.update_item_instance(
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
        ,x_instance_id_lst       => l_instance_id_lst
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      -- 正常終了でない場合
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE update_error_expt;
      END IF;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
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
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_25              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_inst_base_insert           -- トークン値1
                       ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                       ,iv_token_value2  => cv_update_process             -- トークン値2
                       ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                       ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                       ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                       ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                       ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                       ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                       ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                       ,iv_token_value6  => lv_install_code1              -- トークン値6
                       ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                       ,iv_token_value7  => lv_install_code2              -- トークン値7
                       ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                       ,iv_token_value8  => lv_account_num1               -- トークン値8
                       ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                       ,iv_token_value9  => lv_account_num2               -- トークン値9
                       ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                       ,iv_token_value10 => lv_msg_data                   -- トークン値10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
/* Ver.1.34 ADD START */
    -- 設置機器拡張属性値登録フラグ「Y」の場合
    IF ( lv_ib_ext_attr_flg = cv_flg_yes ) THEN
      -- =================================
      -- 11.標準APIより、設置機器拡張属性値登録処理を行なう
      -- =================================
      BEGIN
        CSI_ITEM_INSTANCE_PUB.create_extended_attrib_values(
           p_api_version      => cn_api_version
          ,p_commit           => lv_commit
          ,p_init_msg_list    => lv_init_msg_list
          ,p_validation_level => ln_validation_level
          ,p_ext_attrib_tbl   => l_cre_ext_attr_values_tab
          ,p_txn_rec          => l_txn_rec
          ,x_return_status    => lv_return_status
          ,x_msg_count        => ln_msg_count
          ,x_msg_data         => lv_msg_data
        );
        -- 正常終了でない場合
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          RAISE update_error_expt;
        END IF;
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
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
          END IF;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name          => cv_tkn_number_25              -- メッセージコード
                         ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                         ,iv_token_value1  => cv_inst_ext_att_val           -- トークン値1
                         ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                         ,iv_token_value2  => cv_insert_process             -- トークン値2
                         ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                         ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                         ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                         ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                         ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                         ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                         ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6  => lv_install_code1              -- トークン値6
                         ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7  => lv_install_code2              -- トークン値7
                         ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8  => lv_account_num1               -- トークン値8
                         ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9  => lv_account_num2               -- トークン値9
                         ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                         ,iv_token_value10 => lv_msg_data                   -- トークン値10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
    END IF;
/* Ver.1.34 ADD END */
--  
  EXCEPTION
    -- *** スキップ処理例外ハンドラ ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      -- 更新失敗ロールバックフラグの設定。
      gb_rollback_flg := TRUE;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_item_instances;
--
  /* 2009.12.11 K.Satomura E_本稼動_00420対応 START */
  /**********************************************************************************
   * Procedure Name   : update_item_instances2
   * Description      : 物件データ更新処理2 (A-8-1)
   ***********************************************************************************/
  PROCEDURE update_item_instances2(
     io_inst_base_data_rec IN OUT NOCOPY g_get_data_rtype -- (IN)物件マスタ情報
    ,id_process_date       IN     DATE                    -- 業務処理日付
/* Ver.1.34 ADD START */
    ,iv_modem_flag         IN     VARCHAR2                -- 通信モデム判定フラグ
/* Ver.1.34 ADD END */
    ,ov_errbuf             OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode            OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg             OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_item_instances2'; -- プログラム名
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
    cn_api_version      CONSTANT NUMBER        := 1.0;
    cv_inst_base_insert CONSTANT VARCHAR2(100) := 'インストールベースマスタ';
    cv_update_process   CONSTANT VARCHAR2(100) := '更新';
    cv_flg_no           CONSTANT VARCHAR2(100) := 'N';
/* Ver.1.34 ADD START */
    cn_num1                CONSTANT NUMBER        := 1;
    cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';
    cv_inst_base_info      CONSTANT VARCHAR2(100) := 'インストールベースマスタ';    -- 抽出内容
    cv_inst_party_info     CONSTANT VARCHAR2(100) := 'インスタンスパーティ情報';    -- 抽出内容
    cv_inst_account_info   CONSTANT VARCHAR2(100) := 'インスタンスアカウント情報';  -- 抽出内容
    cv_cust_mst_info       CONSTANT VARCHAR2(100) := '顧客マスタ情報';              -- 抽出内容
    cv_location_type_code  CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';              -- 現行事業所タイプ
    cv_instance_usage_code CONSTANT VARCHAR2(100) := 'OUT_OF_ENTERPRISE';           -- インスタンス使用コード
    cv_party_source_table  CONSTANT VARCHAR2(100) := 'HZ_PARTIES';                  -- パーティソーステーブル
    cv_relatnsh_type_code  CONSTANT VARCHAR2(100) := 'OWNER';                       -- リレーションタイプ
/* Ver.1.34 ADD END */
    --
    -- *** ローカル変数 ***
    lv_commit           VARCHAR2(1);    -- コミットフラグ
    lv_init_msg_list    VARCHAR2(2000); -- メッセージリスト
    ln_validation_level NUMBER;         -- バリデーションレーベル
/* Ver.1.34 ADD START */
    ln_seq_no                  NUMBER;                  -- シーケンス番号
    lv_install_code            VARCHAR2(10);            -- 物件コード
    lv_install_code1           VARCHAR2(10);            -- 物件コード１
    lv_install_code2           VARCHAR2(10);            -- 物件コード２
    lv_account_num1            VARCHAR2(10);            -- 顧客コード１
    lv_account_num2            VARCHAR2(10);            -- 顧客コード２
    ln_instance_party_id       NUMBER;                  -- インスタンスパーティID
    ln_object_version_number2  NUMBER;                  -- オブジェクトバージョン番号
    ln_ip_account_id           NUMBER;                  -- インスタンスアカウントID
    ln_object_version_number3  NUMBER;                  -- オブジェクトバージョン番号
    ln_account_id              NUMBER;                  -- アカウントID
    ln_party_site_id           NUMBER;                  -- パーティサイトID
    ln_party_id                NUMBER;                  -- パーティID
    ln_slip_num                NUMBER;                  -- 伝票No.
    ln_slip_branch_num         NUMBER;                  -- 伝票枝番
    ln_line_num                NUMBER;                  -- 行番
    ln_cnt                     NUMBER;                  -- カウント数
/* Ver.1.34 ADD END */
    --
    -- API戻り値格納用
    lv_return_status VARCHAR2(1);
    lv_msg_data      VARCHAR2(5000);
    lv_io_msg_data   VARCHAR2(5000);
    ln_msg_count     NUMBER;
    ln_io_msg_count  NUMBER;
    --
    -- API入出力レコード値格納用
    l_txn_rec               csi_datastructures_pub.transaction_rec;
    l_instance_rec          csi_datastructures_pub.instance_rec;
    l_party_tab             csi_datastructures_pub.party_tbl;
    l_account_tab           csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab    csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab   csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab  csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab csi_datastructures_pub.extend_attrib_values_tbl;
    l_instance_id_lst       csi_datastructures_pub.id_tbl;
    --
    -- *** ローカル例外 ***
    update_error_expt EXCEPTION;
/* Ver.1.34 ADD START */
    skip_process_expt EXCEPTION;
/* Ver.1.34 ADD END */
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- データの格納
    lv_commit        := fnd_api.g_false;
    lv_init_msg_list := fnd_api.g_true;
    --
/* Ver.1.34 ADD START */
    ln_seq_no          := io_inst_base_data_rec.seq_no;
    ln_slip_num        := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num := io_inst_base_data_rec.slip_branch_no;
    ln_line_num        := io_inst_base_data_rec.line_number;
    lv_account_num1    := io_inst_base_data_rec.account_number1;
    lv_account_num2    := io_inst_base_data_rec.account_number2;
    lv_install_code    := io_inst_base_data_rec.install_code;
    lv_install_code1   := io_inst_base_data_rec.install_code1;
    lv_install_code2   := io_inst_base_data_rec.install_code2;
    --
    --�@作業が「旧台設置」かつ�A伝票枝番が「依頼」かつ�B通信モデムの場合、
    --顧客と物件の紐つけを実施  ※�@�Aはsubmainで判定
    IF ( iv_modem_flag = cv_yes ) THEN
      -----------------------------------
      -- インストールベースマスタの取得
      -----------------------------------
      BEGIN
        SELECT ciins.object_version_number AS object_version1 -- オブジェクトバージョン
        INTO   io_inst_base_data_rec.object_version1
        FROM   csi_item_instances ciins                  -- インストールベースマスタ
        WHERE  ciins.external_reference  = lv_install_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_28             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_inst_base_info            -- トークン値1
                         ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                         ,iv_token_value2 => lv_install_code              -- トークン値2
                         );
          lv_errbuf  := lv_errmsg;
          RAISE skip_process_expt;
      END;
      -----------------------------------
      -- インスタンスパーティの取得
      -----------------------------------
      BEGIN
        SELECT cip.instance_party_id       instance_party_id     -- インスタンスパーティＩＤ
              ,cip.object_version_number   object_version_number -- オブジェクトバージョン番号
        INTO   ln_instance_party_id
              ,ln_object_version_number2
        FROM   csi_i_parties cip
        WHERE  cip.instance_id = io_inst_base_data_rec.instance_id -- インスタンスID
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_28             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_inst_party_info           -- トークン値1
                         ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                         ,iv_token_value2 => lv_install_code              -- トークン値2
                         );
          lv_errbuf  := lv_errmsg;
          RAISE skip_process_expt;
      END;
      -----------------------------------
      -- インスタンスアカウント情報の取得
      -----------------------------------
      BEGIN
        SELECT cipa.ip_account_id          ip_account_id          -- インスタンスアカウントID
              ,cipa.object_version_number  object_version_number  -- オブジェクトバージョン 
        INTO   ln_ip_account_id
              ,ln_object_version_number3
        FROM   csi_ip_accounts cipa
        WHERE  cipa.instance_party_id  = ln_instance_party_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_28             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_inst_account_info         -- トークン値1
                         ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                         ,iv_token_value2 => lv_install_code              -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
      END;
      -----------------------------------
      -- 顧客マスタ情報の取得
      -----------------------------------
      BEGIN
        SELECT casv.cust_account_id        cust_account_id        -- 顧客アカウントID
              ,casv.party_site_id          party_site_id          -- パーティサイトID
              ,casv.party_id               party_id               -- パーティID
        INTO   ln_account_id
              ,ln_party_site_id
              ,ln_party_id
        FROM   xxcso_cust_acct_sites_v casv
        WHERE  casv.account_number    = io_inst_base_data_rec.account_number1
        AND    casv.account_status    = cv_active
        AND    casv.acct_site_status  = cv_active
        AND    casv.party_status      = cv_active
        AND    casv.party_site_status = cv_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_23              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_cust_mst_info              -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
      END;
      -- ==========================
      -- インスタンスレコード作成
      -- ==========================
      l_instance_rec.location_type_code            := cv_location_type_code;         -- ロケーションタイプコード
      l_instance_rec.location_id                   := ln_party_site_id;              -- ロケーションID
      -- ====================
      -- パーティデータ作成
      -- ====================
      ln_cnt := 1;
      l_party_tab(ln_cnt).instance_party_id        := ln_instance_party_id;
      l_party_tab(ln_cnt).party_source_table       := cv_party_source_table;
      l_party_tab(ln_cnt).party_id                 := ln_party_id;
      l_party_tab(ln_cnt).relationship_type_code   := cv_relatnsh_type_code;
      l_party_tab(ln_cnt).contact_flag             := cv_flg_no;
      l_party_tab(ln_cnt).object_version_number    := ln_object_version_number2;
      -- ==============================
      -- パーティアカウントデータ作成
      -- ==============================
      ln_cnt := 1;
      l_account_tab(ln_cnt).ip_account_id          := ln_ip_account_id;
      l_account_tab(ln_cnt).instance_party_id      := ln_instance_party_id;
      l_account_tab(ln_cnt).parent_tbl_index       := cn_num1;
      l_account_tab(ln_cnt).party_account_id       := ln_account_id;
      l_account_tab(ln_cnt).relationship_type_code := cv_relatnsh_type_code;
      l_account_tab(ln_cnt).object_version_number  := ln_object_version_number3;
--
    END IF;
/* Ver.1.34 ADD END */
    -- ================================
    -- 1.インスタンスレコード作成
    -- ================================
    l_instance_rec.instance_id            := io_inst_base_data_rec.instance_id;     -- インスタンスID
    l_instance_rec.attribute4             := cv_flg_no;                             -- 作業依頼中フラグ
    /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
    l_instance_rec.attribute8             := NULL;                                  -- 作業依頼中購買依頼番号/顧客CD
    /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
    l_instance_rec.object_version_number  := io_inst_base_data_rec.object_version1; -- オブジェクトバージョン番号
    l_instance_rec.request_id             := cn_request_id;                         -- REQUEST_ID
    l_instance_rec.program_application_id := cn_program_application_id;             -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id             := cn_program_id;                         -- PROGRAM_ID
    l_instance_rec.program_update_date    := cd_program_update_date;                -- PROGRAM_UPDATE_DATE
    --
    -- ===============================
    -- 2.取引レコードデータ作成
    -- ===============================
    l_txn_rec.transaction_date        := SYSDATE;
    l_txn_rec.source_transaction_date := SYSDATE;
    l_txn_rec.transaction_type_id     := gt_txn_type_id;
    --
    -- =================================
    -- 3.標準APIより、物件更新処理を行う
    -- =================================
    BEGIN
      csi_item_instance_pub.update_item_instance(
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
        ,x_instance_id_lst       => l_instance_id_lst
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      --
      -- 正常終了でない場合
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        RAISE update_error_expt;
        --
      END IF;
      --
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        IF (fnd_msg_pub.count_msg > 0) THEN
          FOR i IN 1..fnd_msg_pub.count_msg LOOP
            fnd_msg_pub.get(
               p_msg_index     => i
              ,p_encoded       => cv_encoded_f
              ,p_data          => lv_io_msg_data
              ,p_msg_index_out => ln_io_msg_count
            );
            --
            lv_msg_data := lv_msg_data || lv_io_msg_data;
            --
          END LOOP;
          --
        END IF;
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_25                              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                                  -- トークンコード1
                       ,iv_token_value1  => cv_inst_base_insert                           -- トークン値1
                       ,iv_token_name2   => cv_tkn_process                                -- トークンコード2
                       ,iv_token_value2  => cv_update_process                             -- トークン値2
                       ,iv_token_name3   => cv_tkn_seq_no                                 -- トークンコード3
                       ,iv_token_value3  => TO_CHAR(io_inst_base_data_rec.seq_no)         -- トークン値3
                       ,iv_token_name4   => cv_tkn_slip_num                               -- トークンコード4
                       ,iv_token_value4  => TO_CHAR(io_inst_base_data_rec.slip_no)        -- トークン値4
                       ,iv_token_name5   => cv_tkn_slip_branch_num                        -- トークンコード5
                       ,iv_token_value5  => TO_CHAR(io_inst_base_data_rec.slip_branch_no) -- トークン値5
                       ,iv_token_name6   => cv_tkn_bukken1                                -- トークンコード6
                       ,iv_token_value6  => io_inst_base_data_rec.install_code1           -- トークン値6
                       ,iv_token_name7   => cv_tkn_bukken2                                -- トークンコード7
                       ,iv_token_value7  => io_inst_base_data_rec.install_code2           -- トークン値7
                       ,iv_token_name8   => cv_tkn_account_num1                           -- トークンコード8
                       ,iv_token_value8  => io_inst_base_data_rec.account_number1         -- トークン値8
                       ,iv_token_name9   => cv_tkn_account_num2                           -- トークンコード9
                       ,iv_token_value9  => io_inst_base_data_rec.account_number2         -- トークン値9
                       ,iv_token_name10  => cv_tkn_errmsg                                 -- トークンコード10
                       ,iv_token_value10 => lv_msg_data                                   -- トークン値10
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
        --
    END;
    --
  EXCEPTION
/* Ver.1.34 ADD START */
    -- *** スキップ処理例外ハンドラ ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
/* Ver.1.34 ADD END */
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      -- 更新失敗ロールバックフラグの設定。
      gb_rollback_flg := TRUE;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_item_instances2;
--
  /* 2009.12.11 K.Satomura E_本稼動_00420対応 END */
  /**********************************************************************************
   * Procedure Name   : update_cust_or_party
   * Description      : 顧客アドオンマスタとパーティマスタ更新処理 (A-10)
   ***********************************************************************************/
  PROCEDURE update_cust_or_party(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)物件マスタ情報
    ,id_process_date         IN     DATE                    -- 業務処理日付
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cust_or_party'; -- プログラム名
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
    cv_no                      CONSTANT  VARCHAR2(1)     := 'N';
    cv_yes                     CONSTANT  VARCHAR2(1)     := 'Y';
    cv_cust_status30           CONSTANT  VARCHAR2(30)    := '30';   -- 承認済
    cv_cust_status40           CONSTANT  VARCHAR2(30)    := '40';   -- 顧客
    cv_cust_status50           CONSTANT  VARCHAR2(30)    := '50';   -- 休止
    cv_business_low_type_24    CONSTANT  VARCHAR2(2)     := '24';   -- フルサービス(消化)VD
    cv_business_low_type_25    CONSTANT  VARCHAR2(2)     := '25';   -- フルサービスVD
    cv_business_low_type_27    CONSTANT  VARCHAR2(2)     := '27';   -- (消化)VD
    cv_update_process1         CONSTANT  VARCHAR2(100)   := '更新（顧客ステータス：「50(休止)」→「40(顧客)」）';
    cv_update_process2         CONSTANT  VARCHAR2(100)   := '更新（顧客ステータス：「30(承認済)」→「40(顧客)」）';
    cv_party_info              CONSTANT  VARCHAR2(100)   := 'パーティマスタ情報';
    cv_hz_parties              CONSTANT  VARCHAR2(100)   := 'パーティマスタ';
    cv_party_name_info         CONSTANT  VARCHAR2(100)   := '顧客マスタサイトビューの顧客名';
    cv_xxcmm_cust_accounts     CONSTANT  VARCHAR2(100)   := '顧客アドオンマスタ';
    cv_xca_business_low_type   CONSTANT  VARCHAR2(100)   := '顧客アドオンマスタの業態小分類';
    cv_xca_cnvs_date           CONSTANT  VARCHAR2(100)   := '顧客アドオンマスタの顧客獲得日';
    cv_up_cnvs_process         CONSTANT  VARCHAR2(100)   := '更新（顧客獲得日）';
    /*20090507_mori_T1_0439 START*/
    cv_instance_type_code      CONSTANT  VARCHAR2(100)   := 'インスタンスタイプコード';
    /*20090507_mori_T1_0439 END*/
    /* 2009.09.14 K.Satomura 0001335対応 START */
    ct_cust_cl_cd_round        CONSTANT hz_cust_accounts.customer_class_code%TYPE := '15'; -- 顧客区分=店舗営業
    cv_cust_class_code         CONSTANT VARCHAR2(100)    := '顧客区分';
    /* 2009.09.14 K.Satomura 0001335対応 END */
    /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
    cv_cls                     CONSTANT VARCHAR2(100)    := 'C';
    /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
--
    -- *** ローカル変数 ***
    ld_cnvs_date               DATE;                    -- 顧客獲得日
    ln_seq_no                  NUMBER;                  -- シーケンス番号
    ln_slip_num                NUMBER;                  -- 伝票No.
    ln_slip_branch_num         NUMBER;                  -- 伝票枝番
    ln_line_num                NUMBER;                  -- 行番
    ln_job_kbn                 NUMBER;                  -- 作業区分
    ln_party_id                NUMBER;                  -- パーティID
    ln_object_ver_num          NUMBER;                  -- オブジェクトバージョン
    ln_count                   NUMBER;                  -- 取得カウント
    ln_customer_id             NUMBER;                  -- 顧客ID 
    lv_install_code            VARCHAR2(10);            -- 物件コード
    lv_install_code1           VARCHAR2(10);            -- 物件コード１
    lv_install_code2           VARCHAR2(10);            -- 物件コード２
    lv_account_num1            VARCHAR2(10);            -- 顧客コード１
    lv_account_num2            VARCHAR2(10);            -- 顧客コード２
    lv_party_name              VARCHAR2(360);           -- 顧客名
    lv_init_msg_list           VARCHAR2(2000);          -- メッセージリスト
    lv_last_job_cmpltn_date    VARCHAR2(20);            -- 最終作業完了日
    lb_goto_flg                BOOLEAN;                 -- 処理続けフラグ
    ld_actual_work_date        DATE;                    -- 実作業日
    /*20090507_mori_T1_0439 START*/
    lv_instance_type_code     csi_item_instances.instance_type_code%TYPE;       -- インスタンスタイプコード
    /*20090507_mori_T1_0439 END*/
    
--
    -- 戻り値格納用
    ln_profile_id              NUMBER;                  -- プロファイルID
    lv_return_status           VARCHAR2(10);            -- 戻り値ステータス
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;

--
    -- API入出力レコード値格納用
    l_party_rec                hz_party_v2pub.party_rec_type;
    l_organization_rec         hz_party_v2pub.organization_rec_type;
--
    -- *** ローカル例外 ***
    skip_process_expt          EXCEPTION;
    update_error_expt          EXCEPTION;
    /*20090507_mori_T1_0439 START*/
    instance_type_expt         EXCEPTION;  -- 対象物件が自販機以外である場合
    /*20090507_mori_T1_0439 END*/
    /* 2009.09.14 K.Satomura 0001335対応 START */
    lt_customer_class_code     hz_cust_accounts.customer_class_code%TYPE;
    /* 2009.09.14 K.Satomura 0001335対応 END */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    -- データの格納
    lv_init_msg_list      := fnd_api.g_true;
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
    ld_actual_work_date   := TO_DATE(io_inst_base_data_rec.actual_work_date,'YYYY/MM/DD');
    lb_goto_flg           := FALSE;
  /*20090507_mori_T1_0439 START*/
    -- 対象物件のインスタンスタイプコード取得
    BEGIN
      SELECT ciins.instance_type_code  instance_type_code             -- インスタンスタイプコード
      INTO   lv_instance_type_code                                    -- インスタンスタイプコード
      FROM   csi_item_instances ciins                                 -- 物件マスタ
      WHERE  ciins.external_reference = lv_install_code
      ;
--
      -- 対象物件が自販機以外である場合、以降の処理を行わない
      IF (lv_instance_type_code <> cv_instance_type_vd) THEN
        RAISE instance_type_expt;
      END IF;
      /* 2009.09.14 K.Satomura 0001335対応 START */
      BEGIN
        SELECT hca.customer_class_code customer_class_code -- 顧客区分
        INTO   lt_customer_class_code
        FROM   csi_item_instances cii -- 物件マスタ
              ,hz_cust_accounts   hca -- 顧客マスタ
        WHERE  cii.external_reference     = lv_install_code
        AND    cii.owner_party_account_id = hca.cust_account_id
        ;
        --
        -- 顧客区分が15(店舗営業)の場合、以降の処理を行わない
        IF (lt_customer_class_code = ct_cust_cl_cd_round) THEN
          RAISE instance_type_expt;
          --
        END IF;
        --
      EXCEPTION
        WHEN instance_type_expt THEN
          RAISE instance_type_expt;
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name        -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_19   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm     -- トークンコード1
                         ,iv_token_value1 => cv_cust_class_code -- トークン値1
                         ,iv_token_name2  => cv_tkn_bukken      -- トークンコード2
                         ,iv_token_value2 => lv_install_code    -- トークン値2
                         ,iv_token_name3  => cv_tkn_errmsg      -- トークンコード3
                         ,iv_token_value3 => SQLERRM            -- トークン値3
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
          --
      END;
      /* 2009.09.14 K.Satomura 0001335対応 END */
    EXCEPTION
      WHEN instance_type_expt THEN
        RAISE instance_type_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_19             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_instance_type_code        -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                -- トークンコード2
                       ,iv_token_value2 => lv_install_code              -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
  /*20090507_mori_T1_0439 END*/
--
    /* 2009.08.28 K.Satomura 0001205対応 START */
    -- ==========================
    -- AR会計期間クローズチェック
    -- ==========================
    gv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
                      id_standard_date => ld_actual_work_date
                   );
    --
    IF (gv_chk_rslt = cv_true) THEN
      gv_chk_rslt_flag := 'N';
      --
    ELSE
      gv_chk_rslt_flag := 'C';
      --
    END IF;
    --
    /* 2009.08.28 K.Satomura 0001205対応 END */
    -- 作業区分が「1.新台設置」、「3.新台代替」、「2. 旧台設置」、または「4.旧台代替」で、
    -- 物件データの物件コードが作業データの物件コード１(新設置先)と同一の場合、
    -- 顧客ステータス（休止→顧客）更新の処理を行う。
    IF((ln_job_kbn = cn_work_kbn1 OR ln_job_kbn = cn_work_kbn2 OR
        ln_job_kbn = cn_work_kbn3 OR ln_job_kbn = cn_work_kbn4)
        AND lv_install_code = NVL(lv_install_code1, ' '))
    THEN
      -- 1.DUNS(顧客ステータス)「'50'(休止)」→「'40'(顧客)」
      BEGIN
        -- �@顧客名の取得
        SELECT xcav.party_name                                            -- 顧客名
        INTO   lv_party_name
        FROM   xxcso_cust_accounts_v xcav                                 -- 顧客マスタビュー
        WHERE  xcav.account_number = lv_account_num1
          AND  xcav.account_status = cv_active
          AND  xcav.party_status   = cv_active
        ;
      EXCEPTION
        -- データなし場合の例外
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_23              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_party_name_info            -- トークン値1
                         ,iv_token_name2   => cv_tkn_seq_no                -- トークンコード2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)           -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_24              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_party_name_info            -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                         ,iv_token_value10=> SQLERRM                       -- トークン値10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
      BEGIN
        -- �AパーティIDを取得
        SELECT hp.party_id                                                 -- パーティID
              ,hp.object_version_number                                    -- オブジェクトバージョン
        INTO   ln_party_id
              ,ln_object_ver_num
        FROM   hz_cust_accounts hca                                        -- 顧客マスタ
              ,hz_parties       hp                                         -- パーティマスタ
        WHERE  hca.account_number = lv_account_num1
          AND  hca.party_id       = hp.party_id
          AND  hca.status         = cv_active
          AND  hp.status          = cv_active
          AND  hp.duns_number_c   = cv_cust_status50
        FOR UPDATE OF hp.party_id NOWAIT
        ;
--
      EXCEPTION
        -- データなし場合の例外
        WHEN NO_DATA_FOUND THEN
          lb_goto_flg := TRUE;
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_27              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                         ,iv_token_value1 => cv_hz_parties                 -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_24              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                         ,iv_token_value1 => cv_party_info                 -- トークン値1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                         ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                         ,iv_token_value6 => lv_install_code1              -- トークン値6
                         ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                         ,iv_token_value7 => lv_install_code2              -- トークン値7
                         ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                         ,iv_token_value8 => lv_account_num1               -- トークン値8
                         ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                         ,iv_token_value9 => lv_account_num2               -- トークン値9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                         ,iv_token_value10=> SQLERRM                       -- トークン値10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--

      -- 処理続けフラグが「FALSE」(「'50'(休止)」→「'40'(顧客)」の顧客情報がある)
      IF (lb_goto_flg = FALSE) THEN
        -- �Bパーティレコードの作成
        l_party_rec.party_id := ln_party_id;                                 -- パーティID
--
        -- �C顧客情報レコードの作成
        l_organization_rec.organization_name := lv_party_name;               -- 顧客名
        l_organization_rec.duns_number_c     := cv_cust_status40;            -- 「40．顧客」
        l_organization_rec.party_rec         := l_party_rec;                 -- パーティレコード
--
        BEGIN
--
          -- �D標準APIよりパーティマスタを更新する。
          hz_party_v2pub.update_organization(
             p_init_msg_list               => lv_init_msg_list
            ,p_organization_rec            => l_organization_rec
            ,p_party_object_version_number => ln_object_ver_num
            ,x_profile_id                  => ln_profile_id
            ,x_return_status               => lv_return_status
            ,x_msg_count                   => ln_msg_count
            ,x_msg_data                    => lv_msg_data
          );
        EXCEPTION
          -- *** OTHERS例外ハンドラ ***
          WHEN OTHERS THEN
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
            END IF;
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application   => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name          => cv_tkn_number_25              -- メッセージコード
                           ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                           ,iv_token_value1  => cv_hz_parties                 -- トークン値1
                           ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                           ,iv_token_value2  => cv_update_process1            -- トークン値2
                           ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                           ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                           ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                           ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                           ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                           ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                           ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6  => lv_install_code1              -- トークン値6
                           ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7  => lv_install_code2              -- トークン値7
                           ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8  => lv_account_num1               -- トークン値8
                           ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9  => lv_account_num2               -- トークン値9
                           ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10 => lv_msg_data                   -- トークン値10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
        /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START */
        -- 顧客ステータス「休止」更新フラグを「TRUE」に設定
        gb_cust_status_free_flg := TRUE;
        /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END */
--
        IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
            gv_chk_rslt_flag = 'N') THEN
          -- 顧客アドオンマスタのロック処理
          BEGIN
--
            SELECT xca.cnvs_date                                             -- 顧客獲得日
            INTO   ld_cnvs_date
            FROM   xxcmm_cust_accounts    xca                                -- 顧客アドオンマスタ
            WHERE  xca.customer_code = lv_account_num1
            FOR UPDATE NOWAIT
            ;
--
          EXCEPTION
            WHEN global_lock_expt THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_27              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                           ,iv_token_value1 => cv_xxcmm_cust_accounts        -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_24              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_xca_cnvs_date              -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10=> SQLERRM                       -- トークン値10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
          END;
--
          BEGIN
--
            UPDATE xxcmm_cust_accounts                                      -- 顧客アドオンマスタ
            /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START */
            --SET    past_customer_status   = cv_cust_status50,               -- 前月顧客ステータス
            SET    past_customer_status   = cv_cust_status40,               -- 前月顧客ステータス
            /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END */
                   last_updated_by        = cn_last_updated_by,
                   last_update_date       = cd_last_update_date,
                   last_update_login      = cn_last_update_login,
                   request_id             = cn_request_id,
                   program_application_id = cn_program_application_id,
                   program_id             = cn_program_id,
                   program_update_date    = cd_program_update_date
            WHERE  customer_code = lv_account_num1
            ;
          EXCEPTION
          -- *** OTHERS例外ハンドラ ***
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name          => cv_tkn_number_25              -- メッセージコード
                           ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                           ,iv_token_value1  => cv_xxcmm_cust_accounts        -- トークン値1
                           ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                           ,iv_token_value2  => cv_up_cnvs_process            -- トークン値2
                           ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                           ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                           ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                           ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                           ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                           ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                           ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6  => lv_install_code1              -- トークン値6
                           ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7  => lv_install_code2              -- トークン値7
                           ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8  => lv_account_num1               -- トークン値8
                           ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9  => lv_account_num2               -- トークン値9
                           ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10 => SQLERRM                       -- トークン値10
                         );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
--
          /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START */
          ---- 顧客ステータス「休止」更新フラグを「TRUE」に設定
          --gb_cust_status_free_flg := TRUE;
          /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END */
        END IF;
--
      END IF;  
    END IF;
-- 
    -- 作業区分が「1.新台設置」または「2.旧台設置」場合
    IF (ln_job_kbn = cn_work_kbn1 OR ln_job_kbn = cn_work_kbn2) THEN
--
      -- 2.DUNS(顧客ステータス)「'30'(承認済)」→「'40'(顧客)」
      BEGIN
        -- �@業態小分類のチェック
        SELECT COUNT(*)                                                    -- 件数
        INTO   ln_count
        FROM   xxcso_cust_accounts_v xcav                                  -- 顧客マスタビュー
        WHERE  xcav.account_number = lv_account_num1
          AND  xcav.account_status = cv_active
          AND  xcav.party_status   = cv_active
          AND  xcav.business_low_type IN ( cv_business_low_type_24
                                          ,cv_business_low_type_25
                                          ,cv_business_low_type_27)
        ;
      EXCEPTION
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_24              -- メッセージコード
                             ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                             ,iv_token_value1 => cv_xca_cnvs_date              -- トークン値1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                             ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                             ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                             ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                             ,iv_token_value6 => lv_install_code1              -- トークン値6
                             ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                             ,iv_token_value7 => lv_install_code2              -- トークン値7
                             ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                             ,iv_token_value8 => lv_account_num1               -- トークン値8
                             ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                             ,iv_token_value9 => lv_account_num2               -- トークン値9
                             ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                             ,iv_token_value10=> SQLERRM                       -- トークン値10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
      -- データがある場合
      IF(ln_count IS NOT NULL AND ln_count > 0) THEN
--
        -- �A顧客獲得日のチェック
        BEGIN
--
          SELECT xca.cnvs_date                                             -- 顧客獲得日
                ,xca.customer_id                                           -- 顧客ID
          INTO   ld_cnvs_date
                ,ln_customer_id
          FROM   xxcmm_cust_accounts   xca                                 -- 顧客アドオンマスタ
                ,hz_cust_accounts      hca                                 -- 顧客マスタ
          WHERE  hca.account_number  = lv_account_num1
            AND  hca.cust_account_id = xca.customer_id
            AND  hca.status          = cv_active
          ;
--
        EXCEPTION
          -- データなし場合の例外
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_23              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_xca_cnvs_date              -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
          -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_24              -- メッセージコード
                             ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                             ,iv_token_value1 => cv_xca_cnvs_date              -- トークン値1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                             ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                             ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                             ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                             ,iv_token_value6 => lv_install_code1              -- トークン値6
                             ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                             ,iv_token_value7 => lv_install_code2              -- トークン値7
                             ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                             ,iv_token_value8 => lv_account_num1               -- トークン値8
                             ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                             ,iv_token_value9 => lv_account_num2               -- トークン値9
                             ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                             ,iv_token_value10=> SQLERRM                       -- トークン値10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
--
        /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
        ---- 顧客獲得日が設定されてない場合
        --IF (ld_cnvs_date IS NULL) AND
        --   (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
        --        gv_chk_rslt_flag = 'C') OR
        --    ((TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
        --              gv_chk_rslt_flag = 'N') OR
        --     (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(id_process_date ,'YYYYMM'))
        --    )
        -- THEN 
        -- 顧客獲得日が設定されてない場合
        IF (ld_cnvs_date IS NULL) THEN
        /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
          -- 顧客アドオンマスタのロック処理
          BEGIN
--
            SELECT xca.cnvs_date                                             -- 顧客獲得日
            INTO   ld_cnvs_date
            FROM   xxcmm_cust_accounts    xca                                -- 顧客アドオンマスタ
            WHERE  xca.customer_code = lv_account_num1
            FOR UPDATE NOWAIT
            ;
--
          EXCEPTION
            WHEN global_lock_expt THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_27              -- メッセージコード
                             ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                             ,iv_token_value1 => cv_xxcmm_cust_accounts        -- トークン値1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                             ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                             ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                             ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                             ,iv_token_value6 => lv_install_code1              -- トークン値6
                             ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                             ,iv_token_value7 => lv_install_code2              -- トークン値7
                             ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                             ,iv_token_value8 => lv_account_num1               -- トークン値8
                             ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                             ,iv_token_value9 => lv_account_num2               -- トークン値9
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
            -- 抽出に失敗した場合
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_24              -- メッセージコード
                             ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                             ,iv_token_value1 => cv_xca_cnvs_date              -- トークン値1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                             ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                             ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                             ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                             ,iv_token_value6 => lv_install_code1              -- トークン値6
                             ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                             ,iv_token_value7 => lv_install_code2              -- トークン値7
                             ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                             ,iv_token_value8 => lv_account_num1               -- トークン値8
                             ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                             ,iv_token_value9 => lv_account_num2               -- トークン値9
                             ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                             ,iv_token_value10=> SQLERRM                       -- トークン値10
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
--
          BEGIN
--
            /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
            ---- 実作業日の年月＝業務処理日付の前月の年月かつAR会計期間チェックフラグがクローズ
            --IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
            --    gv_chk_rslt_flag = 'C') THEN
            -- AR会計期間チェックフラグがクローズ
            IF (gv_chk_rslt_flag = cv_cls) THEN
            /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
              UPDATE xxcmm_cust_accounts                                         -- 顧客アドオンマスタ
              SET    cnvs_date = id_process_date,    -- 顧客獲得日
                     last_updated_by        = cn_last_updated_by,
                     last_update_date       = cd_last_update_date,
                     last_update_login      = cn_last_update_login,
                     request_id             = cn_request_id,
                     program_application_id = cn_program_application_id,
                     program_id             = cn_program_id,
                     program_update_date    = cd_program_update_date
              WHERE  customer_code = lv_account_num1
              ;
            /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
              -- 顧客獲得日を、メッセージ出力用グローバル変数に格納
              gd_cnvs_date := id_process_date;
            ---- 実作業日の年月＝業務処理日付の前月の年月かつAR会計期間チェックフラグがオープンまたは実作業日の年月＝業務処理日付の年月
            --ELSIF ((TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
            --        gv_chk_rslt_flag = 'N') OR
            --       (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(id_process_date ,'YYYYMM'))
            --      ) THEN
            -- AR会計期間チェックフラグがオープン
            ELSIF (gv_chk_rslt_flag = cv_no) THEN
            /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
              UPDATE xxcmm_cust_accounts                                         -- 顧客アドオンマスタ
              SET    cnvs_date = ld_actual_work_date,    -- 顧客獲得日
                     last_updated_by        = cn_last_updated_by,
                     last_update_date       = cd_last_update_date,
                     last_update_login      = cn_last_update_login,
                     request_id             = cn_request_id,
                     program_application_id = cn_program_application_id,
                     program_id             = cn_program_id,
                     program_update_date    = cd_program_update_date
              WHERE  customer_code = lv_account_num1
              ;
            /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
              -- 顧客獲得日を、メッセージ出力用グローバル変数に格納
              gd_cnvs_date := ld_actual_work_date;
            /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
            END IF;

          EXCEPTION
            -- *** OTHERS例外ハンドラ ***
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_app_name                   -- アプリケーション短縮名
                             ,iv_name          => cv_tkn_number_25              -- メッセージコード
                             ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                             ,iv_token_value1  => cv_xxcmm_cust_accounts        -- トークン値1
                             ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                             ,iv_token_value2  => cv_up_cnvs_process            -- トークン値2
                             ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                             ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                             ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                             ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                             ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                             ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                             ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                             ,iv_token_value6  => lv_install_code1              -- トークン値6
                             ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                             ,iv_token_value7  => lv_install_code2              -- トークン値7
                             ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                             ,iv_token_value8  => lv_account_num1               -- トークン値8
                             ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                             ,iv_token_value9  => lv_account_num2               -- トークン値9
                             ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                             ,iv_token_value10 => SQLERRM                       -- トークン値10
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
--
          -- 顧客獲得日更新フラグを「TRUE」に設定
          gb_cust_cnv_upd_flg := TRUE;
        END IF;
--
        BEGIN
          -- �B顧客名の取得
          SELECT xcav.party_name                                                -- 顧客名
          INTO   lv_party_name
          FROM   xxcso_cust_accounts_v xcav                                     -- 顧客マスタビュー
          WHERE  xcav.account_number = lv_account_num1
            AND  xcav.account_status = cv_active
            AND  xcav.party_status   = cv_active
          ;
        EXCEPTION
          -- データなし場合の例外
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_23              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_party_name_info            -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
--
          -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_24              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_party_name_info            -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコー4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10=> SQLERRM                       -- トークン値10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
--
        -- 処理続けフラグ初期化
        lb_goto_flg             := FALSE;
--
        BEGIN
          -- �CパーティIDを取得
          SELECT hp.party_id                                                 -- パーティID
                ,hp.object_version_number                                    -- オブジェクトバージョン
          INTO   ln_party_id
                ,ln_object_ver_num
          FROM   hz_cust_accounts hca                                        -- 顧客マスタ
                ,hz_parties       hp                                         -- パーティマスタ
          WHERE  hca.account_number = lv_account_num1
            AND  hca.party_id       = hp.party_id
            AND  hca.status         = cv_active
            AND  hp.status          = cv_active
            AND  hp.duns_number_c   = cv_cust_status30
          FOR UPDATE OF hp.party_id NOWAIT
          ;
--
        EXCEPTION
          -- データなし場合の例外
          WHEN NO_DATA_FOUND THEN
            -- 処理続けフラグを「TRUE」に設定
            lb_goto_flg := TRUE;
          -- ロック失敗した場合の例外
          WHEN global_lock_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_27              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                           ,iv_token_value1 => cv_hz_parties                 -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
            -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_24              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_party_info                 -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10=> SQLERRM                       -- トークン値10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
--
        -- 処理続けフラグが「FALSE」（「'30'(承認済)」→「'40'(顧客)」の顧客情報がある）
        IF (lb_goto_flg = FALSE) THEN
          -- �Dパーティレコードの作成
          l_party_rec.party_id := ln_party_id;                                 -- パーティID
--
          -- �E顧客情報レコードの作成
          l_organization_rec.organization_name := lv_party_name;               -- 顧客名
          l_organization_rec.duns_number_c     := cv_cust_status40;            -- 「40．顧客」
          l_organization_rec.party_rec         := l_party_rec;                 -- パーティレコード
--
          BEGIN
            -- �F標準APIよりパーティマスタを更新する。
            hz_party_v2pub.update_organization(
               p_init_msg_list               => lv_init_msg_list
              ,p_organization_rec            => l_organization_rec
              ,p_party_object_version_number => ln_object_ver_num
              ,x_profile_id                  => ln_profile_id
              ,x_return_status               => lv_return_status
              ,x_msg_count                   => ln_msg_count
              ,x_msg_data                    => lv_msg_data
            );
          EXCEPTION
            -- *** OTHERS例外ハンドラ ***
            WHEN OTHERS THEN
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
              END IF;
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_app_name                   -- アプリケーション短縮名
                             ,iv_name          => cv_tkn_number_25              -- メッセージコード
                             ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                             ,iv_token_value1  => cv_hz_parties                 -- トークン値1
                             ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                             ,iv_token_value2  => cv_update_process2            -- トークン値2
                             ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                             ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                             ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                             ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                             ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                             ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                             ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                             ,iv_token_value6  => lv_install_code1              -- トークン値6
                             ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                             ,iv_token_value7  => lv_install_code2              -- トークン値7
                             ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                             ,iv_token_value8  => lv_account_num1               -- トークン値8
                             ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                             ,iv_token_value9  => lv_account_num2               -- トークン値9
                             ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                             ,iv_token_value10 => lv_msg_data                   -- トークン値10
                          );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
          /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START */
          -- 顧客ステータス「承認済」更新フラグを「TRUE」に設定
          gb_cust_status_appr_flg  := TRUE;
          /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END */
--
          IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
              gv_chk_rslt_flag = 'N') THEN
            -- 顧客アドオンマスタのロック処理
            BEGIN
--
              SELECT xca.cnvs_date                                             -- 顧客獲得日
              INTO   ld_cnvs_date
              FROM   xxcmm_cust_accounts    xca                                -- 顧客アドオンマスタ
              WHERE  xca.customer_code = lv_account_num1
              FOR UPDATE NOWAIT
              ;
--
            EXCEPTION
              WHEN global_lock_expt THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_27              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                           ,iv_token_value1 => cv_xxcmm_cust_accounts        -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                           );
                lv_errbuf := lv_errmsg;
                RAISE update_error_expt;
            -- 抽出に失敗した場合
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_24              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                           ,iv_token_value1 => cv_xca_cnvs_date              -- トークン値1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- トークン値2
                           ,iv_token_name3  => cv_tkn_slip_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- トークン値3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- トークンコード4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                           ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- トークン値5
                           ,iv_token_name6  => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6 => lv_install_code1              -- トークン値6
                           ,iv_token_name7  => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7 => lv_install_code2              -- トークン値7
                           ,iv_token_name8  => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8 => lv_account_num1               -- トークン値8
                           ,iv_token_name9  => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9 => lv_account_num2               -- トークン値9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10=> SQLERRM                       -- トークン値10
                         );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
            END;
--
            BEGIN
--
              UPDATE xxcmm_cust_accounts                                      -- 顧客アドオンマスタ
              /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START */
              --SET    past_customer_status   = cv_cust_status30,               -- 前月顧客ステータス
              SET    past_customer_status   = cv_cust_status40,               -- 前月顧客ステータス
              /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END */
                     last_updated_by        = cn_last_updated_by,
                     last_update_date       = cd_last_update_date,
                     last_update_login      = cn_last_update_login,
                     request_id             = cn_request_id,
                     program_application_id = cn_program_application_id,
                     program_id             = cn_program_id,
                     program_update_date    = cd_program_update_date
              WHERE  customer_code = lv_account_num1
              ;
            EXCEPTION
            -- *** OTHERS例外ハンドラ ***
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name          => cv_tkn_number_25              -- メッセージコード
                           ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                           ,iv_token_value1  => cv_xxcmm_cust_accounts        -- トークン値1
                           ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                           ,iv_token_value2  => cv_up_cnvs_process            -- トークン値2
                           ,iv_token_name3   => cv_tkn_seq_no                 -- トークンコード3
                           ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- トークン値3
                           ,iv_token_name4   => cv_tkn_slip_num               -- トークンコード4
                           ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- トークン値4
                           ,iv_token_name5   => cv_tkn_slip_branch_num        -- トークンコード5
                           ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- トークン値5
                           ,iv_token_name6   => cv_tkn_bukken1                -- トークンコード6
                           ,iv_token_value6  => lv_install_code1              -- トークン値6
                           ,iv_token_name7   => cv_tkn_bukken2                -- トークンコード7
                           ,iv_token_value7  => lv_install_code2              -- トークン値7
                           ,iv_token_name8   => cv_tkn_account_num1           -- トークンコード8
                           ,iv_token_value8  => lv_account_num1               -- トークン値8
                           ,iv_token_name9   => cv_tkn_account_num2           -- トークンコード9
                           ,iv_token_value9  => lv_account_num2               -- トークン値9
                           ,iv_token_name10  => cv_tkn_errmsg                 -- トークンコード10
                           ,iv_token_value10 => SQLERRM                       -- トークン値10
                         );
                lv_errbuf := lv_errmsg;
                RAISE update_error_expt;
            END;
            /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START */
            ---- 顧客ステータス「承認済」更新フラグを「TRUE」に設定
            --gb_cust_status_appr_flg  := TRUE;
            /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END */
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** スキップ処理例外ハンドラ ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      -- 更新失敗ロールバックフラグの設定。
      gb_rollback_flg := TRUE;
--      
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
  /*20090507_mori_T1_0439 START*/
--
    -- *** 自販機以外スキップ処理例外ハンドラ ***
    WHEN instance_type_expt THEN
      -- 処理なし
      NULL;
  /*20090507_mori_T1_0439 END*/
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
  END update_cust_or_party;
--
--
   /**********************************************************************************
   * Procedure Name   : delete_in_item_data
   * Description      : 物件データワークテーブル削除処理(A-12)
   ***********************************************************************************/
  PROCEDURE delete_in_item_data(
     ov_errbuf               OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
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
    cv_no                    CONSTANT  VARCHAR2(1)    := 'N';
    cv_yes                   CONSTANT  VARCHAR2(1)    := 'Y';
    cv_table_name            CONSTANT  VARCHAR2(100)  := 'xxcso_in_item_data';
    /* 2009.06.01 K.Satomura T1_1107対応 START */
    ct_comp_kbn_comp         CONSTANT xxcso_in_work_data.completion_kbn%TYPE := 1;
    /* 2009.06.01 K.Satomura T1_1107対応 END */
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
      DELETE FROM xxcso_in_item_data  xiid                -- 物件ワークテーブル
      WHERE  EXISTS
             (
               SELECT xiwd.slip_no
               FROM   xxcso_in_work_data xiwd
               WHERE  xiwd.install_code1 = xiid.install_code
               OR     xiwd.install_code2 = xiid.install_code
             )
      AND    NOT EXISTS
             (
               SELECT xiwd2.slip_no
               FROM   xxcso_in_work_data xiwd2
               WHERE  (
                        /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
                        (
                        /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
                              xiwd2.install_code1           = xiid.install_code
/* Ver.1.35 Q2198 ADD START */
                          AND xiwd2.slip_no                 = xiid.last_job_slip_no
/* Ver.1.35 Q2198 ADD END */
                          AND xiwd2.install1_processed_flag = cv_no
                          /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
                          AND xiwd2.install1_process_no_target_flg = cv_no
                        )
                          /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
                      )
               OR     (
                        /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
                        (
                        /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
                              xiwd2.install_code2           = xiid.install_code
/* Ver.1.35 Q2198 ADD START */
                          AND xiwd2.slip_no                 = xiid.last_job_slip_no
/* Ver.1.35 Q2198 ADD END */
                          AND xiwd2.install2_processed_flag = cv_no
                          /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
                          AND xiwd2.install2_process_no_target_flg = cv_no
                        )
                          /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
                      )
               /* 2009.06.01 K.Satomura T1_1107対応 START */
               -- 本処理で処理対象となる作業データについて物件の処理が行われていること
               /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
               --AND    xiwd2.process_no_target_flag = cv_no
               /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
               --/* 2009.12.07 K.Satomura E_本稼動_00349対応 START */
               --AND    xiwd2.completion_kbn         = ct_comp_kbn_comp
               --/* 2009.06.01 K.Satomura T1_1107対応 END */
               /* 2009.12.07 K.Satomura E_本稼動_00349対応 END */
             );
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_31             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1 => cv_table_name                -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg                -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
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
/* 2015-06-17 K.Kiriu E_本稼動_12984 ADD START */
  /**********************************************************************************
   * Procedure Name   : insupd_hht_cdc_trn_proc
   * Description      : HHT集配信連携トランザクションテーブル登録更新処理(A-13)
   ***********************************************************************************/
  PROCEDURE insupd_hht_cdc_trn_proc(
    i_inst_base_data_rec IN  g_get_data_rtype,                            -- 1.(IN)物件マスタ情報
    id_process_date      IN  DATE,                                        -- 2.業務処理日付
    it_job_kbn           IN  xxcso_in_work_data.job_kbn%TYPE,             -- 3.作業区分
/* Ver.1.34 ADD START */
    ov_modem_flag        OUT VARCHAR2,     --   通信モデム判定フラグ
/* Ver.1.34 ADD END */
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insupd_hht_cdc_trn_proc'; -- プログラム名
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
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';  -- 汎用「Y」
    cv_no                CONSTANT VARCHAR2(1)   := 'N';  -- 汎用「N」
    cv_vd_accessory_type CONSTANT VARCHAR2(24)  := 'XXCSO1_VD_ACCESSORY_TYPE';
   /* 2015.07.29 K.Kiriu E_本稼動_13237対応 ADD START */
/* Ver.1.34 DEL START */
--   cv_category_kbn_w     CONSTANT VARCHAR2(2)   := '50'; -- カテゴリ区分（引揚）
/* Ver.1.34 DEL END */
   /* 2015.07.29 K.Kiriu E_本稼動_13237対応 ADD END   */
/* Ver.1.34 ADD START */
    -- 追加属性
    cv_ps_id             CONSTANT VARCHAR2(100) := 'PS_ID';
    cv_line_number       CONSTANT VARCHAR2(100) := 'LINE_NUMBER';
/* Ver.1.34 ADD END */
--
    -- *** ローカル変数 ***
    lt_cooperate_flag    xxcso_hht_col_dlv_coop_trn.cooperate_flag%TYPE; -- 連携フラグ
    lt_install_code      csi_item_instances.external_reference%TYPE;     -- 物件コード
    lt_account_number    hz_cust_accounts.account_number%TYPE;           -- 顧客コード
    lt_install_psid      xxcso_hht_col_dlv_coop_trn.install_psid%TYPE;   -- 設置PSID
    lt_line_number       xxcso_hht_col_dlv_coop_trn.line_number%TYPE;    -- 回線番号
/* Ver.1.34 ADD START */
    lt_install_psid_1    xxcso_hht_col_dlv_coop_trn.install_psid%TYPE;   -- 設置PSID(旧台設置用)
    lt_line_number_1     xxcso_hht_col_dlv_coop_trn.line_number%TYPE;    -- 回線番号(旧台設置用)
    lt_line_number_3     xxcso_hht_col_dlv_coop_trn.line_number%TYPE;    -- 回線番号(登録用)
/* Ver.1.34 ADD END */
    lt_cooperate_date    xxcso_hht_col_dlv_coop_trn.cooperate_date%TYPE; -- 連携日
    lt_approval_date     xxcso_hht_col_dlv_coop_trn.approval_date%TYPE;  -- 承認日
    lr_row_id            ROWID;
    ln_dummy             NUMBER;
    lv_tkn_msg1          VARCHAR2(100);
    lv_tkn_msg2          VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・例外 ***
    update_error_expt    EXCEPTION;
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
    --初期化
    lt_install_code   := NULL;
    lt_account_number := NULL;
    lr_row_id         := NULL;
    lt_install_psid   := NULL;
    lt_line_number    := NULL;
/* Ver.1.34 ADD START */
    lt_install_psid_1 := NULL;
    lt_line_number_1  := NULL;
/* Ver.1.34 ADD END */
    lt_cooperate_date := NULL;
    lt_approval_date  := NULL;
    lt_cooperate_flag := NULL;
/* Ver.1.34 ADD START */
    ov_modem_flag     := cv_no;
/* Ver.1.34 ADD END */
--
    ----------------------------------------------
    -- HHT集配新連携トランザクション作成更新の判断
    ----------------------------------------------
    -- 作業区分「引揚」の場合
    IF ( it_job_kbn = cn_work_kbn5 ) THEN
      lt_install_code := i_inst_base_data_rec.install_code2;
    -- 上記以外の場合
    ELSE
      lt_install_code := i_inst_base_data_rec.install_code1;
    END IF;
    --
    BEGIN
      -- 物件がHHT集配信連携トランザクションの作成更新対象か確認
      SELECT hca.account_number       account_number -- 顧客コード
/* Ver.1.34 ADD START */
            ,xxcso_ib_common_pkg.get_ib_ext_attribs(
                ccii.instance_id
              , cv_ps_id
             )                        install_psid_1 -- 設置PSID
            ,xxcso_ib_common_pkg.get_ib_ext_attribs(
                ccii.instance_id
              , cv_line_number
             )                        line_number_1  -- 回線番号
/* Ver.1.34 ADD END */
      INTO   lt_account_number
/* Ver.1.34 ADD START */
            ,lt_install_psid_1
            ,lt_line_number_1
/* Ver.1.34 ADD END */
      FROM   csi_item_instances   ccii -- インストールベースマスタ
            ,po_un_numbers_vl     punv -- 機種マスタビュー
            ,fnd_lookup_values_vl flvv -- 参照タイプ
            ,hz_cust_accounts     hca  -- 顧客マスタ
      WHERE  ccii.external_reference     =  lt_install_code
      AND    ccii.attribute1             =  punv.un_number
      AND    punv.attribute15            =  flvv.lookup_code
      AND    flvv.lookup_type            =  cv_vd_accessory_type  -- 参照タイプ「XXCSO1_VD_ACCESSORY_TYPE」
      AND    flvv.attribute1             =  cv_yes                -- MaRooN連携対象
      AND    flvv.enabled_flag           =  cv_yes
      AND    id_process_date             BETWEEN NVL( flvv.start_date_active, id_process_date )
                                         AND     NVL( flvv.end_date_active  , id_process_date )
      AND    ccii.owner_party_account_id =  hca.cust_account_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 存在しない場合(対象外の場合)、当処理は終了
        RETURN;
    END;
/* Ver.1.34 ADD START */
    -- 存在する場合、通信モデムと判定
    ov_modem_flag := cv_yes;
/* Ver.1.34 ADD END */
--
    ----------------------------------------------
    -- HHT集配新連携トランザクション前回データ取得
    ----------------------------------------------
    BEGIN
      SELECT xhcdct.rowid          row_id         -- ROWID(更新条件)
            ,xhcdct.install_psid   install_psid   -- 設置PSID
            ,xhcdct.line_number    line_number    -- 回線番号
/* Ver.1.34 DEL START */
--            ,xhcdct.cooperate_date cooperate_date -- 連携日
--            ,xhcdct.approval_date  approval_date  -- 承認日
/* Ver.1.34 DEL END */
      INTO   lr_row_id
            ,lt_install_psid
            ,lt_line_number
/* Ver.1.34 DEL START */
--            ,lt_cooperate_date
--            ,lt_approval_date
/* Ver.1.34 DEL END */
      FROM   xxcso_hht_col_dlv_coop_trn xhcdct -- HHT集配信連携トランザクション
/* Ver.1.34 MOD START */
--      WHERE  xhcdct.install_code   = lt_install_code   -- 物件コード
--      AND    xhcdct.account_number = lt_account_number -- 顧客コード
      WHERE  xhcdct.account_number = lt_account_number -- 顧客コード
/* Ver.1.34 MOD END */
      AND    xhcdct.cooperate_flag = cv_yes            -- 連携フラグ「Y」
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
/* Ver.1.34 MOD START */
--        -- データなしエラー
--        lv_tkn_msg1 := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name         -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_35    -- メッセージコード
--                       );
--        lv_errmsg   := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name         -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_36    -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_action       -- トークンコード1
--                         ,iv_token_value1 => lv_tkn_msg1         -- トークン値1
--                         ,iv_token_name2  => cv_tkn_cust_code    -- トークンコード2
--                         ,iv_token_value2 => lt_account_number   -- トークン値2
--                         ,iv_token_name3  => cv_tkn_install_code -- トークンコード3
--                         ,iv_token_value3 => lt_install_code     -- トークン値3
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE update_error_expt;
--
        --エラーとせず処理継続
        lr_row_id := NULL;
/* Ver.1.34 MOD END */
    END;
--
/* Ver.1.34 MOD START */
--    -- 作業区分「引揚」の場合
--    IF ( it_job_kbn = cn_work_kbn5 ) THEN
    -- 前回データが存在する場合
    IF ( lr_row_id IS NOT NULL ) THEN
/* Ver.1.34 MOD END */
      -------------------------------------------
      -- 前回のHHT集配信連携トランザクション更新
      ------------------------------------------
      BEGIN
        -- ロックの取得
        SELECT 1
        INTO   ln_dummy
        FROM   xxcso_hht_col_dlv_coop_trn xhcdct
        WHERE  rowid = lr_row_id
        FOR UPDATE NOWAIT
        ;
        -- 更新
        UPDATE  xxcso_hht_col_dlv_coop_trn xhcdct
        SET     xhcdct.cooperate_flag        = cv_no
               ,xhcdct.last_updated_by       = cn_last_updated_by
               ,xhcdct.last_update_date      = cd_last_update_date
               ,xhcdct.last_update_login     = cn_last_update_login
               ,request_id                   = cn_request_id
               ,program_application_id       = cn_program_application_id
               ,program_id                   = cn_program_id
               ,program_update_date          = cd_program_update_date
        WHERE   rowid                        = lr_row_id
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          -- ロックエラー
          lv_tkn_msg1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name         -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_35    -- メッセージコード
                         );
          lv_errmsg   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name         -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_37    -- メッセージコード
                           ,iv_token_name1  => cv_tkn_action       -- トークンコード1
                           ,iv_token_value1 => lv_tkn_msg1         -- トークン値1
                           ,iv_token_name2  => cv_tkn_cust_code    -- トークンコード2
                           ,iv_token_value2 => lt_account_number   -- トークン値2
                           ,iv_token_name3  => cv_tkn_install_code -- トークンコード3
                           ,iv_token_value3 => lt_install_code     -- トークン値3
                         );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
        WHEN OTHERS THEN
          -- その他例外
          lv_tkn_msg1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_35     -- メッセージコード
                         );
          lv_tkn_msg2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_39     -- メッセージコード
                         );
          lv_errmsg   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name         -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_38    -- メッセージコード
                           ,iv_token_name1  => cv_tkn_action       -- トークンコード1
                           ,iv_token_value1 => lv_tkn_msg1         -- トークン値1
                           ,iv_token_name2  => cv_tkn_process      -- トークンコード2
                           ,iv_token_value2 => lv_tkn_msg2         -- トークン値2
                           ,iv_token_name3  => cv_tkn_cust_code    -- トークンコード3
                           ,iv_token_value3 => lt_account_number   -- トークン値3
                           ,iv_token_name4  => cv_tkn_install_code -- トークンコード4
                           ,iv_token_value4 => lt_install_code     -- トークン値4
                           ,iv_token_name5  => cv_tkn_errmsg       -- トークンコード5
                           ,iv_token_value5 => SQLERRM             -- トークン値5
                         );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
/* Ver.1.34 DEL START */
--      -----------------------------
--      -- 新規作成データの値設定(引揚)
--      -----------------------------
--      lt_cooperate_flag := cv_yes;  -- 連携フラグ(連携)
--      BEGIN
--        -- 購買依頼データ取得
--        SELECT  TO_DATE( xrlv.work_hope_year || xrlv.work_hope_month || xrlv.work_hope_day,'yyyymmdd') work_hope_date  -- 連携日
--               ,TRUNC(pha.approved_date)                                                               approved_date   -- 承認日
--        INTO    lt_cooperate_date
--               ,lt_approval_date
--        FROM    po_requisition_headers_all pha
--               ,xxcso_requisition_lines_v  xrlv
--        WHERE   pha.segment1              = TO_CHAR(i_inst_base_data_rec.po_req_number)
--        AND     pha.requisition_header_id = xrlv.requisition_header_id
--        /* 2015.07.29 K.Kiriu E_本稼動_13237対応 MOD START */
----        AND     xrlv.line_num             = i_inst_base_data_rec.line_num
--        AND     xrlv.category_kbn         = cv_category_kbn_w
--        /* 2015.07.29 K.Kiriu E_本稼動_13237対応 MOD END   */
--        ;
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_tkn_msg1 := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_app_name                       -- アプリケーション短縮名
--                          ,iv_name         => cv_tkn_number_42                  -- メッセージコード
--                         );
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                        -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_41                   -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_table                       -- トークンコード1
--                         ,iv_token_value1 => lv_tkn_msg1                        -- トークン値1
--                         ,iv_token_name2  => cv_tkn_req_header_num              -- トークンコード2
--                         ,iv_token_value2 => i_inst_base_data_rec.po_req_number -- トークン値2
--                         ,iv_token_name3  => cv_tkn_errmsg                      -- トークンコード3
--                         ,iv_token_value3 => SQLERRM                            -- トークン値3
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE update_error_expt;
--      END;
--      --
--    -- 作業区分「店内移動」(新台・旧台代替の付替え作業)の場合
--    ELSE
--      -----------------------------
--      -- 新規作成データの値設定(店内移動)
--      -----------------------------
--      lt_cooperate_flag := cv_no;   -- 連携フラグ(未連携)
--      --
/* Ver.1.34 DEL END */
    END IF;
/* Ver.1.34 ADD START */
    lt_cooperate_flag := cv_yes;  -- 連携フラグ(連携対象)
    lt_cooperate_date := TO_DATE( i_inst_base_data_rec.work_hope_date,'YYYYMMDD' );  -- 連携日
    lt_approval_date  := TRUNC( cd_creation_date );                                  -- 承認日
--
    -- 作業区分「引揚」の場合
    IF ( it_job_kbn = cn_work_kbn5 ) THEN
      lt_install_psid_1 := NULL;              -- 設置PSID
      lt_line_number_3  := lt_line_number;    -- 回線番号(前回データ)
    ELSE
      lt_install_psid   := NULL;              -- 引揚PSID
      lt_line_number_3  := lt_line_number_1;  -- 回線番号(物件から取得)
    END IF;
/* Ver.1.34 ADD END */
--
    ------------------------------------------------
    -- HHT集配信連携トランザクションデータ挿入処理
    ------------------------------------------------
    BEGIN
      INSERT INTO xxcso_hht_col_dlv_coop_trn(
         account_number          -- 顧客コード
        ,install_code            -- 物件コード
        ,creating_source_code    -- 発生元ソースコード
        ,install_psid            -- 設置PSID
        ,withdraw_psid           -- 引揚PSID
        ,line_number             -- 回線番号
        ,cooperate_flag          -- 連携フラグ
        ,cooperate_date          -- 連携日
        ,approval_date           -- 承認日
        ,created_by              -- 作成者
        ,creation_date           -- 作成日
        ,last_updated_by         -- 最終更新者
        ,last_update_date        -- 最終更新日
        ,last_update_login       -- 最終更新ログイン
        ,request_id              -- 要求ID
        ,program_application_id  -- コンカレント・プログラム・アプリケーションID
        ,program_id              -- コンカレント・プログラムID
        ,program_update_date     -- プログラム更新日
      )VALUES(
         lt_account_number                           -- 顧客コード
        ,lt_install_code                             -- 物件コード
/* Ver.1.34 MOD START */
--        ,TO_CHAR(i_inst_base_data_rec.po_req_number) -- 発生元ソースコード(発注依頼番号)
--        ,NULL                                        -- 設置PSID
--        ,lt_install_psid                             -- 引揚PSID
--        ,lt_line_number                              -- 回線番号
        ,cv_pkg_name                                 -- 発生元ソースコード(発注依頼番号)
        ,lt_install_psid_1                           -- 設置PSID
        ,lt_install_psid                             -- 引揚PSID
        ,lt_line_number_3                            -- 回線番号
/* Ver.1.34 MOD END */
        ,lt_cooperate_flag                           -- 連携フラグ
        ,lt_cooperate_date                           -- 連携日
        ,lt_approval_date                            -- 承認日
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
        -- その他例外
        lv_tkn_msg1 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name          -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_35     -- メッセージコード
                       );
        lv_tkn_msg2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name          -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_40     -- メッセージコード
                       );
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_38    -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action       -- トークンコード1
                         ,iv_token_value1 => lv_tkn_msg1         -- トークン値1
                         ,iv_token_name2  => cv_tkn_process      -- トークンコード2
                         ,iv_token_value2 => lv_tkn_msg2         -- トークン値2
                         ,iv_token_name3  => cv_tkn_cust_code    -- トークンコード3
                         ,iv_token_value3 => lt_account_number   -- トークン値3
                         ,iv_token_name4  => cv_tkn_install_code -- トークンコード4
                         ,iv_token_value4 => lt_install_code     -- トークン値4
                         ,iv_token_name5  => cv_tkn_errmsg       -- トークンコード5
                         ,iv_token_value5 => SQLERRM             -- トークン値5
                       );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      -- 更新失敗ロールバックフラグの設定。
      gb_rollback_flg := TRUE;
      ov_errmsg       := lv_errmsg;
      ov_errbuf       := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode      := cv_status_warn;
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
  END insupd_hht_cdc_trn_proc;
--
/* 2015-06-17 K.Kiriu E_本稼動_12984 ADD END   */
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cn_kbn1                   CONSTANT  NUMBER          := 1;
    cv_no                     CONSTANT  VARCHAR2(1)     := 'N';
    cv_yes                    CONSTANT  VARCHAR2(1)     := 'Y';
    cv_haihun                 CONSTANT  VARCHAR2(1)     := '-';
    cv_inst_base_info         CONSTANT  VARCHAR2(100)   := '(IN)物件マスタ情報';
    cv_update_process1        CONSTANT  VARCHAR2(100)   := '「50(休止)」→「40(顧客)」';
    cv_update_process2        CONSTANT  VARCHAR2(100)   := '「30(承認済)」→「40(顧客)」';
    /* 2009.06.15 K.Satomura T1_1239対応 START */
    cv_comp_kbn_comp          CONSTANT  VARCHAR2(100)   := '1'; -- 完了区分＝完了
    /* 2009.06.15 K.Satomura T1_1239対応 END */
    /* 2009.12.07 K.Satomura E_本稼動_00349対応 START */
    cv_skip_company_code      CONSTANT  VARCHAR2(100)   := '117777';
    cv_skip_location_code     CONSTANT  VARCHAR2(100)   := '0010';
    /* 2009.12.07 K.Satomura E_本稼動_00349対応 END */
--
    -- *** ローカル変数 ***
    ld_sysdate                DATE;                    -- システム日付
    ld_process_date           DATE;                    -- 業務処理日
    ld_cnvs_date              DATE;                    -- 顧客獲得日
    ln_seq_no                 NUMBER;                  -- シーケンス番号
    ln_slip_num               NUMBER;                  -- 伝票No.
    ln_slip_branch_num        NUMBER;                  -- 伝票枝番
    ln_line_num               NUMBER;                  -- 行番
    ln_job_kbn                NUMBER;                  -- 作業区分
    ln_instance_status_id     NUMBER;                  -- インスタンスステータスID
    lv_bukken_code            VARCHAR2(10);            -- 物件コード
    lv_install_code1          VARCHAR2(10);            -- 物件コード１
    lv_install_code2          VARCHAR2(10);            -- 物件コード２
    lv_account_num1           VARCHAR2(10);            -- 顧客コード１
    lv_account_num2           VARCHAR2(10);            -- 顧客コード２
    lv_cnvs_date              VARCHAR2(20);            -- 顧客獲得日
    lv_info                   VARCHAR2(5000);          -- 連携メッセージ
/* Ver.1.34 ADD START */
    lv_modem_flag             VARCHAR2(1);             -- 通信モデム判定フラグ
/* Ver.1.34 ADD END */
--
    -- *** ローカル・カーソル ***
    CURSOR get_inst_base_data_cur
    IS
      SELECT   xciwd.seq_no                         seq_no                      -- シーケンス番号.
              ,xciwd.slip_no                        slip_no                     -- 伝票No.
              ,xciwd.slip_branch_no                 slip_branch_no              -- 伝票枝番
              ,xciwd.line_number                    line_number                 -- 行番号
              ,xciwd.job_kbn                        job_kbn                     -- 作業区分
              ,xciwd.install_code1                  install_code1               -- 物件コード１（設置用）
              ,xciwd.install_code2                  install_code2               -- 物件コード２（引揚用）
              /* 2009.06.15 K.Satomura T1_1239対応 START */
              ,xciwd.completion_kbn                 completion_kbn              -- 完了区分
              /* 2009.06.15 K.Satomura T1_1239対応 END */
              ,xciwd.safe_setting_standard          safe_setting_standard       -- 安全設置基準
              ,xciid.install_code                   install_code                -- 物件コード
              ,xciid.un_number                      un_number                   -- 機種
              ,xciid.install_number                 install_number              -- 機番
              ,xciid.machinery_kbn                  machinery_kbn               -- 機器区分
              ,xciid.first_install_date             first_install_date          -- 初回設置日
              ,xciid.counter_no                     counter_no                  -- カウンターNo.
              ,xciid.division_code                  division_code               -- 地区コード
              ,xciid.base_code                      base_code                   -- 拠点コード
              ,xciid.job_company_code               job_company_code            -- 作業会社コード
              ,xciid.location_code                  location_code               -- 事業所コード
              ,xciid.last_job_slip_no               last_job_slip_no            -- 最終作業伝票No.
              ,xciid.last_job_kbn                   last_job_kbn                -- 最終作業区分
              ,xciid.last_job_going                 last_job_going              -- 最終作業進捗
              ,xciid.last_job_completion_plan_date  last_job_cmpltn_plan_date   -- 最終作業完了予定日
              ,xciid.last_job_completion_date       last_job_cmpltn_date        -- 最終作業完了日
              ,xciid.last_maintenance_contents      last_maintenance_contents   -- 最終整備内容
              ,xciid.last_install_slip_no           last_install_slip_no        -- 最終設置伝票No.
              ,xciid.last_install_kbn               last_install_kbn            -- 最終設置区分
              ,xciid.last_install_plan_date         last_install_plan_date      -- 最終設置予定日
              ,xciid.last_install_going             last_install_going          -- 最終設置進捗
              ,xciid.machinery_status1              machinery_status1           -- 機器状態1（稼動状態）
              ,xciid.machinery_status2              machinery_status2           -- 機器状態2（状態詳細）
              ,xciid.machinery_status3              machinery_status3           -- 機器状態3（廃棄情報）
              ,xciid.stock_date                     stock_date                  -- 入庫日
              ,xciid.withdraw_company_code          withdraw_company_code       -- 引揚会社コード
              ,xciid.withdraw_location_code         withdraw_location_code      -- 引揚事業所コード
              ,xciid.resale_disposal_vendor         resale_disposal_vendor      -- 転売廃棄業者
              ,xciid.resale_disposal_slip_no        resale_disposal_slip_no     -- 転売廃棄伝票��
              ,xciid.owner_company_code             owner_company_code          -- 所有者
              ,xciid.resale_disposal_flag           resale_disposal_flag        -- 転売廃棄状況フラグ
              ,xciid.resale_completion_kbn          resale_completion_kbn       -- 転売完了区分
              ,xciid.delete_flag                    delete_flag                 -- 削除フラグ
              ,xciid.creation_date_time             creation_date_time          -- 作成日時時分秒
              ,xciid.update_date_time               update_date_time            -- 更新日時時分秒
              ,xciwd.account_number1                account_number1             -- 顧客コード１（新設置先）
              ,xciwd.account_number2                account_number2             -- 顧客コード２（現設置先）
/* Ver.1.34 DEL START */
--              ,xciwd.po_number                      po_number                   -- 発注番号
--              ,xciwd.po_line_number                 po_line_number              -- 発注明細番号
--              ,xciwd.po_req_number                  po_req_number               -- 発注依頼番号
--              ,xciwd.line_num                       line_num                    -- 発注依頼明細番号
/* Ver.1.34 DEL END */
              ,xciwd.actual_work_date               actual_work_date            -- 実作業日
              /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
              ,xciwd.actual_work_time1              actual_work_time1           -- 実作業時間１
              /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
/* Ver.1.34 ADD START */
              ,xciid.lease_type                     lease_type                  -- リース区分
              ,xciid.declaration_place              declaration_place           -- 申告地
              ,xciid.get_price                      get_price                   -- 取得価格
              ,xciwd.work_hope_date                 work_hope_date              -- 作業希望日/引取希望日
/* Ver.1.34 ADD END */
      FROM     xxcso_in_work_data    xciwd
              ,xxcso_in_item_data    xciid
      /* 2009.06.15 K.Satomura T1_1239対応 START */
      --WHERE    xciwd.completion_kbn   = cn_kbn1
      --  AND    (
      WHERE    (
      /* 2009.06.15 K.Satomura T1_1239対応 END */
                 (
                       xciid.install_code                   = NVL(xciwd.install_code1, ' ')
/* Ver.1.35 Q2198 ADD START */
                   AND xciwd.slip_no                        = xciid.last_job_slip_no
/* Ver.1.35 Q2198 ADD END */
                   AND xciwd.install1_processed_flag        = cv_no
                   /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
                   AND xciwd.install1_process_no_target_flg = cv_no
                   /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
                 )
               OR
                 (
                       xciid.install_code                   = NVL(xciwd.install_code2, ' ') 
/* Ver.1.35 Q2198 ADD START */
                   AND xciwd.slip_no                        = xciid.last_job_slip_no
/* Ver.1.35 Q2198 ADD END */
                   AND xciwd.install2_processed_flag        = cv_no
                   /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
                   AND xciwd.install2_process_no_target_flg = cv_no
                   /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
                 )
               )
         /* 2009.06.04 K.Satomura T1_1107再修正対応 START */
         --/* 2009.06.01 K.Satomura T1_1107対応 START */
         --AND   xciwd.process_no_target_flag = cv_no
         --/* 2009.06.01 K.Satomura T1_1107対応 END */
         /* 2009.06.04 K.Satomura T1_1107再修正対応 END */
      ORDER BY xciwd.actual_work_date
              ,xciwd.actual_work_time2
    ;
--
    -- *** ローカル・レコード ***
    l_inst_base_data_rec   get_inst_base_data_cur%ROWTYPE;
    l_g_get_data_rec       g_get_data_rtype;
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
       od_sysdate            => ld_sysdate          -- システム日付
      ,od_process_date       => ld_process_date     -- 業務処理日付
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
    -- A-2.(IN) 物件マスタ情報抽出処理
    -- ========================================
    -- カーソルオープン
    OPEN get_inst_base_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    <<get_inst_base_data_loop>>
    LOOP
--    
      BEGIN
        FETCH get_inst_base_data_cur INTO l_inst_base_data_rec;
--
      EXCEPTION
        WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16             -- メッセージコード 
                       ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1 => cv_inst_base_info            -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg                -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
                      );
        lv_errbuf  := lv_errmsg;  
        RAISE global_process_expt;
      END;
      BEGIN
        -- 処理対象件数格納
        gn_target_cnt := get_inst_base_data_cur%ROWCOUNT;
--
        EXIT WHEN get_inst_base_data_cur%NOTFOUND
        OR  get_inst_base_data_cur%ROWCOUNT = 0;
--
        -- 初期化
        l_g_get_data_rec := NULL;
        -- 物件コード
        lv_bukken_code := l_inst_base_data_rec.install_code;
--
        -- レコードの格納
        l_g_get_data_rec.seq_no                    := l_inst_base_data_rec.seq_no;
        l_g_get_data_rec.slip_no                   := l_inst_base_data_rec.slip_no;
        l_g_get_data_rec.slip_branch_no            := l_inst_base_data_rec.slip_branch_no;
        l_g_get_data_rec.line_number               := l_inst_base_data_rec.line_number;
        l_g_get_data_rec.job_kbn                   := l_inst_base_data_rec.job_kbn;
        l_g_get_data_rec.install_code1             := l_inst_base_data_rec.install_code1;
        l_g_get_data_rec.install_code2             := l_inst_base_data_rec.install_code2;
        l_g_get_data_rec.safe_setting_standard     := l_inst_base_data_rec.safe_setting_standard;
        l_g_get_data_rec.install_code              := l_inst_base_data_rec.install_code;
        l_g_get_data_rec.un_number                 := l_inst_base_data_rec.un_number;
        l_g_get_data_rec.install_number            := l_inst_base_data_rec.install_number;
        l_g_get_data_rec.machinery_kbn             := l_inst_base_data_rec.machinery_kbn;
        l_g_get_data_rec.first_install_date        := l_inst_base_data_rec.first_install_date;
        l_g_get_data_rec.counter_no                := l_inst_base_data_rec.counter_no;
        l_g_get_data_rec.division_code             := l_inst_base_data_rec.division_code;
        l_g_get_data_rec.base_code                 := l_inst_base_data_rec.base_code;
        l_g_get_data_rec.job_company_code          := l_inst_base_data_rec.job_company_code;
        l_g_get_data_rec.location_code             := l_inst_base_data_rec.location_code;
        l_g_get_data_rec.last_job_slip_no          := l_inst_base_data_rec.last_job_slip_no;
        l_g_get_data_rec.last_job_kbn              := l_inst_base_data_rec.last_job_kbn;
        l_g_get_data_rec.last_job_going            := l_inst_base_data_rec.last_job_going;
        l_g_get_data_rec.last_job_cmpltn_plan_date := l_inst_base_data_rec.last_job_cmpltn_plan_date;
        l_g_get_data_rec.last_job_cmpltn_date      := l_inst_base_data_rec.last_job_cmpltn_date;
        l_g_get_data_rec.last_maintenance_contents := l_inst_base_data_rec.last_maintenance_contents;
        l_g_get_data_rec.last_install_slip_no      := l_inst_base_data_rec.last_install_slip_no;
        l_g_get_data_rec.last_install_kbn          := l_inst_base_data_rec.last_install_kbn;
        l_g_get_data_rec.last_install_plan_date    := l_inst_base_data_rec.last_install_plan_date;
        l_g_get_data_rec.last_install_going        := l_inst_base_data_rec.last_install_going;
        l_g_get_data_rec.machinery_status1         := l_inst_base_data_rec.machinery_status1;
        l_g_get_data_rec.machinery_status2         := l_inst_base_data_rec.machinery_status2;
        l_g_get_data_rec.machinery_status3         := l_inst_base_data_rec.machinery_status3;
        l_g_get_data_rec.stock_date                := l_inst_base_data_rec.stock_date;
        l_g_get_data_rec.withdraw_company_code     := l_inst_base_data_rec.withdraw_company_code;
        l_g_get_data_rec.withdraw_location_code    := l_inst_base_data_rec.withdraw_location_code;
        l_g_get_data_rec.resale_disposal_vendor    := l_inst_base_data_rec.resale_disposal_vendor;
        l_g_get_data_rec.resale_disposal_slip_no   := l_inst_base_data_rec.resale_disposal_slip_no;
        l_g_get_data_rec.owner_company_code        := l_inst_base_data_rec.owner_company_code;
        l_g_get_data_rec.resale_disposal_flag      := l_inst_base_data_rec.resale_disposal_flag;
        l_g_get_data_rec.resale_completion_kbn     := l_inst_base_data_rec.resale_completion_kbn;
        l_g_get_data_rec.delete_flag               := l_inst_base_data_rec.delete_flag;
        l_g_get_data_rec.creation_date_time        := l_inst_base_data_rec.creation_date_time;
        l_g_get_data_rec.update_date_time          := l_inst_base_data_rec.update_date_time;
        l_g_get_data_rec.account_number1           := l_inst_base_data_rec.account_number1;
        l_g_get_data_rec.account_number2           := l_inst_base_data_rec.account_number2;
/* Ver.1.34 DEL START */
--        l_g_get_data_rec.po_number                 := l_inst_base_data_rec.po_number;
--        l_g_get_data_rec.po_line_number            := l_inst_base_data_rec.po_line_number;
--        l_g_get_data_rec.po_req_number             := l_inst_base_data_rec.po_req_number;
--        l_g_get_data_rec.line_num                  := l_inst_base_data_rec.line_num;
/* Ver.1.34 DEL END */
        l_g_get_data_rec.actual_work_date          := l_inst_base_data_rec.actual_work_date;
        /* 2009.06.15 K.Satomura T1_1239対応 START */
        l_g_get_data_rec.completion_kbn            := l_inst_base_data_rec.completion_kbn;
        /* 2009.06.15 K.Satomura T1_1239対応 END */
        /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 START */
        l_g_get_data_rec.actual_work_time1         := l_inst_base_data_rec.actual_work_time1;
        /* 2010.01.19 K.Hosoi E_本稼動_00818,01177対応 END */
/* Ver.1.34 ADD START */
        l_g_get_data_rec.lease_type                := l_inst_base_data_rec.lease_type;        --リース区分
        l_g_get_data_rec.declaration_place         := l_inst_base_data_rec.declaration_place; --申告地
        l_g_get_data_rec.get_price                 := l_inst_base_data_rec.get_price;         --取得価格
        l_g_get_data_rec.work_hope_date            := l_inst_base_data_rec.work_hope_date;    --作業希望日/引取希望日
/* Ver.1.34 ADD END */
--
        -- メッセージ格納用
        ln_seq_no                     := l_inst_base_data_rec.seq_no;
        ln_slip_num                   := l_inst_base_data_rec.slip_no;
        ln_slip_branch_num            := l_inst_base_data_rec.slip_branch_no;
        ln_line_num                   := l_inst_base_data_rec.line_number;
        ln_job_kbn                    := l_inst_base_data_rec.job_kbn;
        lv_install_code1              := l_inst_base_data_rec.install_code1;
        lv_install_code2              := l_inst_base_data_rec.install_code2;
        lv_account_num1               := l_inst_base_data_rec.account_number1;
        lv_account_num2               := l_inst_base_data_rec.account_number2;
        /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
        --lv_cnvs_date                  := TO_CHAR(l_inst_base_data_rec.last_job_cmpltn_date);
        lv_cnvs_date                  := NULL;
        gd_cnvs_date                  := NULL;
        /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
--
        -- ========================================
        -- A-3.(更新失敗用)セーブポイント設定
        -- ========================================
        SAVEPOINT item_proc_up;
        -- ========================================
        -- A-4.物件情報抽出処理
        -- ========================================
        -- 登録更新フラグの初期化
        gb_insert_process_flg   := FALSE;
        -- 顧客ステータス「休止」更新フラグの初期化
        gb_cust_status_free_flg := FALSE;
        -- 顧客ステータス「承認済」更新フラグの初期化
        gb_cust_status_appr_flg := FALSE;
        -- 顧客獲得日更新フラグの初期化
        gb_cust_cnv_upd_flg     := FALSE;
--
        /* 2009.12.07 K.Satomura E_本稼動_00349対応 START */
        IF (
             (
                   l_g_get_data_rec.job_company_code = cv_skip_company_code
               AND l_g_get_data_rec.location_code = cv_skip_location_code
             )
             OR
             (
                   l_g_get_data_rec.withdraw_company_code = cv_skip_company_code
               AND l_g_get_data_rec.withdraw_location_code = cv_skip_location_code
             )
          )
        THEN
          -- 作業会社・事業所コード又は、引揚会社・事業所コードが該当のコードの場合、処理をスキップする
          lv_errmsg := '作業会社・事業所コード又は、引揚会社・事業所コードが特殊会社コードの為、処理をスキップします。（'
                    || 'シーケンス番号：' || l_g_get_data_rec.seq_no         || '、'
                    || '伝票No： '        || l_g_get_data_rec.slip_no        || '、'
                    || '伝票枝番：'       || l_g_get_data_rec.slip_branch_no || '、'
                    || '行番号：'         || l_g_get_data_rec.line_number    || '、'
                    || '物件コード1：'    || l_g_get_data_rec.install_code1  || '、'
                    || '物件コード2：'    || l_g_get_data_rec.install_code2
                    ;
          lv_errbuf := lv_errmsg;
          --
          RAISE skip_process_expt;
          --
        END IF;
        --
        /* 2009.12.07 K.Satomura E_本稼動_00349対応 END */
        get_item_instances(
           io_inst_base_data_rec   => l_g_get_data_rec --(IN)物件マスタ情報
          ,id_process_date         => ld_process_date  -- 業務処理日付
          ,ov_errbuf               => lv_errbuf        -- エラー・メッセージ            --# 固定 #
          ,ov_retcode              => lv_sub_retcode   -- リターン・コード              --# 固定 #
          ,ov_errmsg               => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE skip_process_expt;
        END IF;
--
        /* 2009.12.11 K.Satomura E_本稼動_00420対応 START */
        --IF (gb_insert_process_flg = TRUE) THEN
        IF (gb_insert_process_flg = TRUE
         AND l_g_get_data_rec.completion_kbn = ct_comp_kbn_comp)
        THEN
        /* 2009.12.11 K.Satomura E_本稼動_00420対応 END */
          -- ========================================
          -- A-5.物件データ登録処理
          -- ========================================
--
          insert_item_instances(
             io_inst_base_data_rec   => l_g_get_data_rec --(IN)物件マスタ情報
            ,id_process_date         => ld_process_date  -- 業務処理日付
            ,ov_errbuf               => lv_errbuf        -- エラー・メッセージ            --# 固定 #
            ,ov_retcode              => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg               => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
--
        /* 2009.12.11 K.Satomura E_本稼動_00420対応 START */
        --ELSE
        END IF;
        --
        IF (gb_insert_process_flg = FALSE) THEN
        /* 2009.12.11 K.Satomura E_本稼動_00420対応 END */
          ln_instance_status_id := l_g_get_data_rec.instance_status_id; 
          -- ========================================
          -- A-6.論理削除更新チェック処理
          -- ========================================
          /* 2009.04.17 K.Satomura T1_0466対応 START */
          --IF (ln_instance_status_id = gt_instance_status_id_6) THEN
          --  lv_errmsg := xxccp_common_pkg.get_msg(
          --                  iv_application  => cv_app_name                  -- アプリケーション短縮名
          --                 ,iv_name         => cv_tkn_number_26             -- メッセージコード
          --                 ,iv_token_name1  => cv_tkn_bukken                -- トークンコード1
          --                 ,iv_token_value1 => lv_bukken_code               -- トークン値1
          --               );
          --  lv_errbuf := lv_errmsg;
          --  RAISE skip_process_expt;
          --END IF;
          /* 2009.04.17 K.Satomura T1_0466対応 END */
--
          -- ========================================
          -- A-7.物件ロック処理
          -- ========================================
          rock_item_instances(
             io_inst_base_data_rec   => l_g_get_data_rec --(IN)物件マスタ情報
            ,id_process_date         => ld_process_date  -- 業務処理日付
            ,ov_errbuf               => lv_errbuf        -- エラー・メッセージ            --# 固定 #
            ,ov_retcode              => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg               => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
--
          /* 2009.12.11 K.Satomura E_本稼動_00420対応 START */
          IF (l_g_get_data_rec.completion_kbn = ct_comp_kbn_comp) THEN
          /* 2009.12.11 K.Satomura E_本稼動_00420対応 END */
            /* 2015-06-17 K.Kiriu E_本稼動_12984 ADD START */
/* Ver.1.34 MOD START */
--            -- 作業が「引揚」「店内移動」の場合
--            IF ( ln_job_kbn = cn_work_kbn5 OR ln_job_kbn = cn_work_kbn6 ) THEN
            -- 作業が引揚の場合
            IF  ( ln_job_kbn = cn_work_kbn5 ) THEN
/* Ver.1.34 MOD END */
              -- ======================================================
              -- A-13.HHT集配信連携トランザクションテーブル登録更新処理
              -- ======================================================
              insupd_hht_cdc_trn_proc(
                 i_inst_base_data_rec => l_g_get_data_rec
                ,id_process_date      => ld_process_date
                ,it_job_kbn           => ln_job_kbn
/* Ver.1.34 ADD START */
                ,ov_modem_flag        => lv_modem_flag    -- 通信モデム判定フラグ
/* Ver.1.34 ADD END */
                ,ov_errbuf            => lv_errbuf
                ,ov_retcode           => lv_sub_retcode
                ,ov_errmsg            => lv_errmsg
              );
              --
              IF (lv_sub_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              ELSIF (lv_sub_retcode = cv_status_warn) THEN
                RAISE skip_process_expt;
              END IF;
              --
            END IF;
            /* 2015-06-17 K.Kiriu E_本稼動_12984 ADD END   */
            -- ========================================
            -- A-8.物件データ更新処理
            -- ========================================
--
            update_item_instances(
               io_inst_base_data_rec   => l_g_get_data_rec --(IN)物件マスタ情報
              ,id_process_date         => ld_process_date  -- 業務処理日付
              ,ov_errbuf               => lv_errbuf        -- エラー・メッセージ            --# 固定 #
              ,ov_retcode              => lv_sub_retcode   -- リターン・コード              --# 固定 #
              ,ov_errmsg               => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
            );
--
/* Ver.1.34 ADD START */
            IF (lv_sub_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              RAISE skip_process_expt;
            END IF;
--
            -- 作業が「旧台設置」かつ伝票枝番が「依頼」の場合
            IF ( ln_job_kbn         = cn_work_kbn2  AND
                 ln_slip_branch_num = cn_slip_kbn0
            ) THEN
              -- ======================================================
              -- A-13.HHT集配信連携トランザクションテーブル登録更新処理
              -- ======================================================
              insupd_hht_cdc_trn_proc(
                 i_inst_base_data_rec => l_g_get_data_rec
                ,id_process_date      => ld_process_date
                ,it_job_kbn           => ln_job_kbn
                ,ov_modem_flag        => lv_modem_flag
                ,ov_errbuf            => lv_errbuf
                ,ov_retcode           => lv_sub_retcode
                ,ov_errmsg            => lv_errmsg
              );
              --
              IF (lv_sub_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              ELSIF (lv_sub_retcode = cv_status_warn) THEN
                RAISE skip_process_expt;
              END IF;
--
              -- ========================================
              -- A-8-1.物件データ更新処理2
              -- ========================================
              update_item_instances2(
                 io_inst_base_data_rec => l_g_get_data_rec --(IN)物件マスタ情報
                ,id_process_date       => ld_process_date  -- 業務処理日付
                ,iv_modem_flag         => lv_modem_flag    -- 通信モデム判定フラグ
                ,ov_errbuf             => lv_errbuf        -- エラー・メッセージ            --# 固定 #
                ,ov_retcode            => lv_sub_retcode   -- リターン・コード              --# 固定 #
                ,ov_errmsg             => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
              );
            END IF;
/* Ver.1.34 ADD END */
          /* 2009.12.11 K.Satomura E_本稼動_00420対応 START */
          ELSE
            /* 2009.12.16 K.Hosoi E_本稼動_00502対応 START */
            IF (ln_job_kbn = cn_work_kbn1 OR ln_job_kbn = cn_work_kbn2 OR
                ln_job_kbn = cn_work_kbn3 OR ln_job_kbn = cn_work_kbn4 OR
                ln_job_kbn = cn_work_kbn5 OR ln_job_kbn = cn_work_kbn6) THEN
              -- ========================================
              -- A-8-1.物件データ更新処理2
              -- ========================================
              update_item_instances2(
                 io_inst_base_data_rec => l_g_get_data_rec --(IN)物件マスタ情報
                ,id_process_date       => ld_process_date  -- 業務処理日付
/* Ver.1.34 ADD START */
                ,iv_modem_flag         => lv_modem_flag    -- 通信モデム判定フラグ
/* Ver.1.34 ADD END */
                ,ov_errbuf             => lv_errbuf        -- エラー・メッセージ            --# 固定 #
                ,ov_retcode            => lv_sub_retcode   -- リターン・コード              --# 固定 #
                ,ov_errmsg             => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
              );
              --
            END IF;
            /* 2009.12.16 K.Hosoi E_本稼動_00502対応 END */
          END IF;
          --
          /* 2009.12.11 K.Satomura E_本稼動_00420対応 END */
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
--
        END IF;
--
        -- ========================================
        -- A-9.作業データ更新処理
        -- ========================================
--
        update_in_work_data(
           io_inst_base_data_rec   => l_g_get_data_rec --(IN)物件マスタ情報
          ,id_process_date         => ld_process_date  -- 業務処理日付
          /* 2009.06.01 K.Satomura T1_1107対応 START */
          ,iv_skip_flag            => cv_no            -- スキップフラグ
          /* 2009.06.01 K.Satomura T1_1107対応 END */
          ,ov_errbuf               => lv_errbuf        -- エラー・メッセージ            --# 固定 #
          ,ov_retcode              => lv_sub_retcode   -- リターン・コード              --# 固定 #
          ,ov_errmsg               => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE skip_process_expt;
        END IF;
--

        -- ====================================================
        -- A-10.顧客アドオンマスタとパーティマスタ更新処理
        -- ====================================================
--
        /* 2009.06.15 K.Satomura T1_1239対応 START */
        IF (l_g_get_data_rec.completion_kbn = cv_comp_kbn_comp) THEN
        /* 2009.06.15 K.Satomura T1_1239対応 END */
          update_cust_or_party(
             io_inst_base_data_rec   => l_g_get_data_rec --(IN)物件マスタ情報
            ,id_process_date         => ld_process_date  -- 業務処理日付
            ,ov_errbuf               => lv_errbuf        -- エラー・メッセージ            --# 固定 #
            ,ov_retcode              => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg               => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
        /* 2009.06.15 K.Satomura T1_1239対応 START */
        END IF;
        /* 2009.06.15 K.Satomura T1_1239対応 END */
--
        -- ===================================
        -- A-11.連携済正常メッセージ出力処理
        -- ===================================
--
        IF (gb_cust_status_free_flg = TRUE ) THEN 
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name          => cv_tkn_number_30              -- メッセージコード
                         ,iv_token_name1   => cv_tkn_partnership_name       -- トークンコード1
                         ,iv_token_value1  => cv_inst_base_info             -- トークン値1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3   => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5   => cv_tkn_bukken1                -- トークンコード5
                         ,iv_token_value5  => lv_install_code1              -- トークン値5
                         ,iv_token_name6   => cv_tkn_bukken2                -- トークンコード6
                         ,iv_token_value6  => lv_install_code2              -- トークン値6
                         ,iv_token_name7   => cv_tkn_account_num1           -- トークンコード7
                         ,iv_token_value7  => lv_account_num1               -- トークン値7
                         ,iv_token_name8   => cv_tkn_account_num2           -- トークンコード8
                         ,iv_token_value8  => lv_account_num2               -- トークン値8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- トークンコード9
                         ,iv_token_value9  => cv_update_process1            -- トークン値9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- トークンコード10
                         ,iv_token_value10 => cv_haihun                     -- トークン値10
                    );
        ELSIF(gb_cust_status_appr_flg = TRUE) THEN 
          IF (gb_cust_cnv_upd_flg = FALSE) THEN
            lv_cnvs_date := cv_haihun;
          /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
          ELSE
            lv_cnvs_date := TO_CHAR(gd_cnvs_date,'YYYY/MM/DD');
          END IF;
          /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name          => cv_tkn_number_30              -- メッセージコード
                         ,iv_token_name1   => cv_tkn_partnership_name       -- トークンコード1
                         ,iv_token_value1  => cv_inst_base_info             -- トークン値1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3   => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5   => cv_tkn_bukken1                -- トークンコード5
                         ,iv_token_value5  => lv_install_code1              -- トークン値5
                         ,iv_token_name6   => cv_tkn_bukken2                -- トークンコード6
                         ,iv_token_value6  => lv_install_code2              -- トークン値6
                         ,iv_token_name7   => cv_tkn_account_num1           -- トークンコード7
                         ,iv_token_value7  => lv_account_num1               -- トークン値7
                         ,iv_token_name8   => cv_tkn_account_num2           -- トークンコード8
                         ,iv_token_value8  => lv_account_num2               -- トークン値8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- トークンコード9
                         ,iv_token_value9  => cv_update_process2            -- トークン値9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- トークンコード10
                         ,iv_token_value10 => lv_cnvs_date                  -- トークン値10
                    );
        ELSIF(gb_cust_cnv_upd_flg = TRUE) THEN
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name          => cv_tkn_number_30              -- メッセージコード
                         ,iv_token_name1   => cv_tkn_partnership_name       -- トークンコード1
                         ,iv_token_value1  => cv_inst_base_info             -- トークン値1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3   => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5   => cv_tkn_bukken1                -- トークンコード5
                         ,iv_token_value5  => lv_install_code1              -- トークン値5
                         ,iv_token_name6   => cv_tkn_bukken2                -- トークンコード6
                         ,iv_token_value6  => lv_install_code2              -- トークン値6
                         ,iv_token_name7   => cv_tkn_account_num1           -- トークンコード7
                         ,iv_token_value7  => lv_account_num1               -- トークン値7
                         ,iv_token_name8   => cv_tkn_account_num2           -- トークンコード8
                         ,iv_token_value8  => lv_account_num2               -- トークン値8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- トークンコード9
                         ,iv_token_value9  => cv_haihun                     -- トークン値9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- トークンコード10
                         /* 2009.12.14 K.Hosoi E_本稼動_00466対応 START */
                         --,iv_token_value10 => lv_cnvs_date                  -- トークン値10
                         ,iv_token_value10 => TO_CHAR(gd_cnvs_date,'YYYY/MM/DD') -- トークン値10
                         /* 2009.12.14 K.Hosoi E_本稼動_00466対応 END */
                    );
                 
        ELSE
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- アプリケーション短縮名
                         ,iv_name          => cv_tkn_number_30              -- メッセージコード
                         ,iv_token_name1   => cv_tkn_partnership_name       -- トークンコード1
                         ,iv_token_value1  => cv_inst_base_info             -- トークン値1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- トークンコード2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- トークン値2
                         ,iv_token_name3   => cv_tkn_slip_num               -- トークンコード3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- トークン値3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- トークンコード4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- トークン値4
                         ,iv_token_name5   => cv_tkn_bukken1                -- トークンコード5
                         ,iv_token_value5  => lv_install_code1              -- トークン値5
                         ,iv_token_name6   => cv_tkn_bukken2                -- トークンコード6
                         ,iv_token_value6  => lv_install_code2              -- トークン値6
                         ,iv_token_name7   => cv_tkn_account_num1           -- トークンコード7
                         ,iv_token_value7  => lv_account_num1               -- トークン値7
                         ,iv_token_name8   => cv_tkn_account_num2           -- トークンコード8
                         ,iv_token_value8  => lv_account_num2               -- トークン値8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- トークンコード9
                         ,iv_token_value9  => cv_haihun                     -- トークン値9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- トークンコード10
                         ,iv_token_value10 => cv_haihun                     -- トークン値10
                    );
        END IF;
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_info                                         -- ユーザ・正常連携メッセージ
        );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_info                                         -- 正常連携メッセージ
        );
        -- 正常件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** スキップ例外ハンドラ ***
        WHEN skip_process_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
--
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
          -- ロールバック
          IF gb_rollback_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT item_proc_up;          -- ROLLBACK
            gb_rollback_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg11|| CHR(10)
            );
          END IF;
--
        -- *** スキップ例外OTHERSハンドラ ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
--
          -- ログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf  ||SQLERRM              -- エラーメッセージ
          );
          -- ロールバック
          IF gb_rollback_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT item_proc_up;          -- ROLLBACK
            gb_rollback_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg11|| CHR(10)
            );
          END IF;
--
      END;
    END LOOP get_inst_base_data_loop;
--
    ov_retcode   := lv_retcode;
    -- カーソルクローズ
    CLOSE get_inst_base_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
--
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
      -- ======================================
      -- A-12.物件データワークテーブル削除処理
      -- ======================================
--
      delete_in_item_data(
         ov_errbuf               => lv_errbuf        -- エラー・メッセージ            --# 固定 #
        ,ov_retcode              => lv_retcode       -- リターン・コード              --# 固定 #
        ,ov_errmsg               => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--      
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがクローズされていない場合
      IF (get_inst_base_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_inst_base_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (get_inst_base_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_inst_base_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (get_inst_base_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_inst_base_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   ''
      );
      END IF;
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
    retcode       OUT  NOCOPY  VARCHAR2       --   リターン・コード    --# 固定 #
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
      ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- A-14.終了処理 
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
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
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
        ,buff   => cv_debug_msg11 || CHR(10) ||
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
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO015A03C;
/
