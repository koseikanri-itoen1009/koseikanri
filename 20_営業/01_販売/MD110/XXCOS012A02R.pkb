CREATE OR REPLACE PACKAGE BODY APPS.XXCOS012A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS012A02R (body)
 * Description      : ピックリスト（出荷先・販売先・製品別）
 * MD.050           : ピックリスト（出荷先・販売先・製品別） MD050_COS_012_A02
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  check_parameter        パラメータチェック処理(A-1)
 *  get_data               データ取得(A-2)
 *  insert_rpt_wrk_data    帳票ワークテーブル登録(A-3)
 *  execute_svf            ＳＶＦ起動(A-4)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/22    1.0   K.Kakishita      新規作成
 *  2009/02/23    1.1   K.Kakishita      売上区分のクイックコードタイプおよびコードの変更
 *  2009/02/26    1.2   K.Kakishita      帳票コンカレント起動後のワークテーブル削除処理の
 *                                       コメント化を外す。
 *  2009/04/03    1.3   N.Maeda          【ST障害No.T1_0086対応】
 *                                       非在庫品目を抽出対象より除外するよう変更。
 *  2009/06/05    1.4   T.Kitajima       [T1_1334]受注明細、EDI明細結合条件変更
 *  2009/06/09    1.5   T.Kitajima       [T1_1374]拠点名(40byte)
 *                                                チェーン店名(40byte)
 *                                                倉庫名(50byte)
 *                                                店舗コード(10byte)
 *                                                品目コード(16byte)
 *                                                品名(40byte)
 *                                                に修正
 *  2009/06/09    1.5   T.Kitajima       [T1_1375]入数が0の場合、ケース数に0設定、
 *                                                バラ数に数量を設定する。
 *  2009/06/15    1.6   K.Kiriu          [T1_1358]定番特売区分クイックコード値変更対応
 *  2009/07/10    1.7   M.Sano           [0000063]情報区分によるデータ作成対象の制御
 *  2009/07/22    1.8   M.Sano           [T1_1437]データパージ不具合対応
 *  2009/08/11    1.9   M.Sano           [0000008]ピッキングリスト性能懸念対応
 *  2009/08/20    1.10  N.Sano           [0000889]特売区分対応
 *  2010/02/04    1.11  Y.Kikuchi        [E_本稼動_01161]以下の抽出条件を除外する。
 *                                                       ・出荷元保管場所の条件
 *                                                       ・通過在庫型区分
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
  global_proc_date_err_expt EXCEPTION;
  global_api_err_expt       EXCEPTION;
  global_call_api_expt      EXCEPTION;
  global_date_reversal_expt EXCEPTION;
  global_insert_data_expt   EXCEPTION;
  global_delete_data_expt   EXCEPTION;
  global_nodata_expt        EXCEPTION;
  global_get_profile_expt   EXCEPTION;
  global_lookup_code_expt   EXCEPTION;
/* 2009/08/20 Ver1.10 Add Start */
  global_get_bargain_expt   EXCEPTION;
  global_get_fixture_expt   EXCEPTION;
/* 2009/08/20 Ver1.10 Add End   */
  --*** 処理対象データロック例外 ***
  global_data_lock_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS012A02R';          -- パッケージ名
--
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS012A02R';          -- コンカレント名
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS012A02R';          -- 帳票ＩＤ
  cv_extension_pdf          CONSTANT VARCHAR2(100) := '.pdf';                  -- 拡張子（ＰＤＦ）
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS012A02S.xml';      -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS012A02S.vrq';      -- クエリー様式ファイル名
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                     -- 出力区分（ＰＤＦ）
--
  --アプリケーション短縮名
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOS';                      --販物短縮アプリ名
  --販物メッセージ
  ct_msg_lock_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';           --ロック取得エラーメッセージ
  ct_msg_get_profile_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00004';           --プロファイル取得エラー
  ct_msg_date_reversal_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00005';           --日付逆転エラー
  ct_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';           --データ登録エラーメッセージ
  ct_msg_delete_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';           --データ削除エラーメッセージ
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';           --データ取得エラーメッセージ
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00014';           --業務日付取得エラー
  ct_msg_call_api_err       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00017';           --API呼出エラーメッセージ
  ct_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';           --明細0件用メッセージ
  ct_msg_svf_api            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00041';           --ＳＶＦ起動ＡＰＩ
  ct_msg_request            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00042';           --要求ＩＤ
  ct_msg_org_id             CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00047';           --MO:営業単位
  ct_msg_max_date           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00056';           --XXCOS:MAX日付
  ct_msg_case_uom_code      CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00057';           --XXCOS:ケース単位コード
  ct_msg_parameter          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12651';           --パラメータ出力メッセージ
  ct_msg_req_dt_from        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12652';           --着日(From)
  ct_msg_req_dt_to          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12653';           --着日(To)
  ct_msg_rpt_wrk_tbl        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12654';           --帳票ワークテーブル
  ct_msg_bargain_cls_tblnm  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12655';           --定番特売区分クイックコードマスタ
/* 2009/08/20 Ver1.10 Add Start */
  ct_msg_get_fixture_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00186';           --定番情報取得エラー
  ct_msg_get_bargain_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00187';           --特売情報取得エラー
/* 2009/08/20 Ver1.10 Add End   */
  --トークン
  cv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';                  --テーブル
  cv_tkn_date_from          CONSTANT VARCHAR2(100) := 'DATE_FROM';              --日付（From)
  cv_tkn_date_to            CONSTANT VARCHAR2(100) := 'DATE_TO';                --日付（To)
  cv_tkn_profile            CONSTANT VARCHAR2(100) := 'PROFILE';                --プロファイル
  cv_tkn_table_name         CONSTANT VARCHAR2(100) := 'TABLE_NAME';             --テーブル名称
  cv_tkn_key_data           CONSTANT VARCHAR2(100) := 'KEY_DATA';               --キーデータ
  cv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';               --ＡＰＩ名称
  cv_tkn_param1             CONSTANT VARCHAR2(100) := 'PARAM1';                 --第１入力パラメータ
  cv_tkn_param2             CONSTANT VARCHAR2(100) := 'PARAM2';                 --第２入力パラメータ
  cv_tkn_param3             CONSTANT VARCHAR2(100) := 'PARAM3';                 --第３入力パラメータ
  cv_tkn_param4             CONSTANT VARCHAR2(100) := 'PARAM4';                 --第４入力パラメータ
  cv_tkn_param5             CONSTANT VARCHAR2(100) := 'PARAM5';                 --第５入力パラメータ
  cv_tkn_request            CONSTANT VARCHAR2(100) := 'REQUEST';                --要求ＩＤ
  --プロファイル名称
  ct_prof_org_id            CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'ORG_ID';
  ct_prof_max_date          CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_MAX_DATE';
  ct_prof_case_uom_code     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_CASE_UOM_CODE';
  --クイックコードタイプ
  ct_qct_order_type         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_TRAN_TYPE_MST_012_A02';
  ct_qct_order_source       CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_ODR_SRC_MST_012_A02';
  ct_qct_sale_class         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_SALE_CLASS_MST_012_A02';
  ct_qct_sale_class_default CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_SALE_CLASS_MST';
  ct_qct_bargain_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_BARGAIN_CLASS';
  ct_qct_cus_class_mst      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_CUS_CLASS_MST_012_A02';
  ct_qct_edi_item_err_type  CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_EDI_ITEM_ERR_TYPE';
  --クイックコード
  ct_qcc_order_type         CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A02%';
  ct_qcc_ord_src_manual     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A02_1%';
  ct_qcc_ord_src_edi        CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A02_2%';
  ct_qcc_sale_class         CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A02_';
  ct_qcc_sale_class_default CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_%';
  ct_qcc_cus_class_mst1     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A02_1%';
  ct_qcc_cus_class_mst2     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A02_2%';
  ct_xxcos1_no_inv_item_code CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_NO_INV_ITEM_CODE';
  --マルチ検索文字列
  cv_multi                  CONSTANT VARCHAR2(1)   := '%';
  --使用可能フラグ定数
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                          --使用可能
  --受注ヘッダステータス
  ct_hdr_status_booked      CONSTANT oe_order_headers_all.flow_status_code%TYPE
                                     := 'BOOKED';                     --記帳済
  ct_hdr_status_entered     CONSTANT oe_order_headers_all.flow_status_code%TYPE
                                     := 'ENTERED';                    --入力済
  --受注明細ステータス
  ct_ln_status_closed       CONSTANT oe_order_lines_all.flow_status_code%TYPE
                                     := 'CLOSED';                     --クローズ
  ct_ln_status_cancelled    CONSTANT oe_order_lines_all.flow_status_code%TYPE
                                     := 'CANCELLED';                  --取消
  --受注タイプ（ヘッダ）
  ct_tran_type_code_order   CONSTANT oe_transaction_types_all.transaction_type_code%TYPE
                                     := 'ORDER';                      --ORDER
  --受注タイプ（明細）
  ct_tran_type_code_line    CONSTANT oe_transaction_types_all.transaction_type_code%TYPE
                                     := 'LINE';                       --LINE
-- 2010/02/04 Ver1.11 Del Start *
--  --保管場所区分
--  ct_subinv_class           CONSTANT mtl_secondary_inventories.attribute1%TYPE
--                                     := '1';                          --倉庫
--
--  --通過在庫型区分2桁目
--  cv_invtype_dlv            CONSTANT VARCHAR2(1)   := '2';            --在庫型（納品）
--  cv_invtype_dlvfix         CONSTANT VARCHAR2(1)   := '3';            --在庫型（納品確定）
-- 2010/02/04 Ver1.11 Del End   *
  --ＥＤＩ品目エラーフラグ
  cv_edi_item_err_flag_yes  CONSTANT VARCHAR2(1)   := 'Y';            --エラーである
  cv_edi_item_err_flag_no   CONSTANT VARCHAR2(1)   := 'N';            --エラーでない
  --データ種コード
  ct_data_type_code_edi     CONSTANT xxcos_edi_headers.data_type_code%TYPE
                                     := '11';                         --EDI受注
  ct_data_type_code_shop    CONSTANT xxcos_edi_headers.data_type_code%TYPE
                                     := '12';                         --店舗別受注
  --換算率デフォルト
--****************************** 2009/06/09 1.4 T.Kitajima MOD START ******************************--
--  ct_conv_rate_default      CONSTANT mtl_uom_class_conversions.conversion_rate%TYPE
--                                     := 1;                            --換算率
  ct_conv_rate_default      CONSTANT mtl_uom_class_conversions.conversion_rate%TYPE
                                     := 0;                            --換算率
--****************************** 2009/06/09 1.4 T.Kitajima MOD  END  ******************************--
  --存在フラグ
  cv_exists_flag_yes        CONSTANT VARCHAR2(1)   := 'Y';            --存在あり
  cv_exists_flag_no         CONSTANT VARCHAR2(1)   := 'N';            --存在なし
  --定番特売区分
/* 2009/06/15 Ver1.6 Mod Start */
--  cv_bargain_class_all      CONSTANT VARCHAR2(1)   := '0';            --全て
  cv_bargain_class_all      CONSTANT VARCHAR2(2)   := '00';           --全て
/* 2009/06/15 Ver1.6 Mod End   */
  --処理対象フラグ
  cv_target_flag_yes        CONSTANT VARCHAR2(1)   := 'Y';            --対象
  cv_target_flag_no         CONSTANT VARCHAR2(1)   := 'N';            --対象外
  --フォーマット
  cv_fmt_date8              CONSTANT VARCHAR2(8)   := 'RRRRMMDD';
  cv_fmt_date               CONSTANT VARCHAR2(30)  := 'RRRR/MM/DD';
  cv_fmt_datetime           CONSTANT VARCHAR2(30)  := 'RRRR/MM/DD HH24:MI:SS';
  cv_fmt_weekno             CONSTANT VARCHAR2(1)   := 'D';
  --曜日番号
  cv_weekno_sunday          CONSTANT VARCHAR2(1)   := '1';            --日曜日
  cv_weekno_monday          CONSTANT VARCHAR2(1)   := '2';            --月曜日
  cv_weekno_tuesday         CONSTANT VARCHAR2(1)   := '3';            --火曜日
  cv_weekno_wednesday       CONSTANT VARCHAR2(1)   := '4';            --水曜日
  cv_weekno_thursday        CONSTANT VARCHAR2(1)   := '5';            --木曜日
  cv_weekno_friday          CONSTANT VARCHAR2(1)   := '6';            --金曜日
  cv_weekno_saturday        CONSTANT VARCHAR2(1)   := '7';            --土曜日
--****************************** 2009/06/09 1.4 T.Kitajima MOD START ******************************--
  --SUBSTR用
  cn_substr_1               CONSTANT NUMBER        := 1;
  cn_substr_16              CONSTANT NUMBER        := 16;
  cn_substr_40              CONSTANT NUMBER        := 40;
--****************************** 2009/06/09 1.4 T.Kitajima MOD  END  ******************************--
-- 2009/07/10 Ver1.7 Add Start *
  --情報区分
  cv_info_class_01          CONSTANT  VARCHAR2(2)   := '01';          --情報区分：「01」
  cv_info_class_02          CONSTANT  VARCHAR2(2)   := '02';          --情報区分：「02」
-- 2009/07/10 Ver1.7 Add End   *
/* 2009/08/11 Ver1.9 Add Start */
  -- 言語コード
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  -- 時間（最小、最大)
  cv_time_min               CONSTANT VARCHAR2(8)  := '00:00:00';
  cv_time_max               CONSTANT VARCHAR2(8)  := '23:59:59';
/* 2009/08/11 Ver1.9 Add End   */
/* 2009/08/20 Ver1.10 Add Start */
  cv_bargain_class_fixture  CONSTANT VARCHAR2(1)   := 'Y';            --定番特売区分：定番
  cv_bargain_class_bargain  CONSTANT VARCHAR2(1)   := 'N';            --定番特売区分：特売
/* 2009/08/20 Ver1.10 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --帳票ワーク用テーブル型定義
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_pick_deli_pro%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --パラメータ
  gv_login_base_code                  VARCHAR2(4);                    -- 拠点
  gv_login_chain_store_code           VARCHAR2(4);                    -- チェーン店
  gd_request_date_from                DATE;                           -- 着日(From)
  gd_request_date_to                  DATE;                           -- 着日(To)
/* 2009/06/15 Ver1.6 Mod Start */
--  gv_bargain_class                    VARCHAR2(1);                    -- 定番特売区分
  gv_bargain_class                    fnd_lookup_values.lookup_code%TYPE;  -- 定番特売区分
/* 2009/06/15 Ver1.6 Mod End   */
  gt_bargain_class_name               fnd_lookup_values.meaning%TYPE;
                                                                      -- 定番特売区分（ヘッダ）名称
  --初期取得
  gd_process_date                     DATE;                           -- 業務日付
  gn_org_id                           NUMBER;                         -- 営業単位
  gd_max_date                         DATE;                           -- MAX日付
  gt_case_uom_code                    mtl_units_of_measure_tl.uom_code%TYPE;
                                                                      -- ケース単位コード
  --帳票ワーク内部テーブル
  g_rpt_data_tab                      g_rpt_data_ttype;
  --特定マスタのクイックコード生成用
  gt_qcc_sale_class                   fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 売上区分用
/* 2009/08/20 Ver1.10 Mod Start */
  gt_fixture_code                     fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 定番特売区分コード：定番
  gt_fixture_name                     fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 定番特売区分名称  ：定番
  gt_bargain_code                     fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 定番特売区分コード：特売
  gt_bargain_name                     fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 定番特売区分名称  ：特売
/* 2009/08/20 Ver1.10 Mod End   */
--
  -- ===============================
  -- ユーザー定義関数
  -- ===============================
  --数値比較
  FUNCTION comp_num(
    in_arg1                   IN      NUMBER,
    in_arg2                   IN      NUMBER)
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( in_arg1 IS NULL ) AND ( in_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( in_arg1 IS NULL ) AND ( in_arg2 IS NOT NULL ) ) THEN
        RETURN  FALSE;
    ELSIF ( ( in_arg1 IS NOT NULL ) AND ( in_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( in_arg1 = in_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
  --文字列比較
  FUNCTION comp_char(
    iv_arg1                   IN      VARCHAR2,
    iv_arg2                   IN      VARCHAR2)
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( iv_arg1 IS NOT NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( iv_arg1 = iv_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
  --日付比較
  FUNCTION comp_date(
    id_arg1                   IN      DATE,
    id_arg2                   IN      DATE)
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( id_arg1 IS NOT NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( id_arg1 = id_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_login_base_code        IN      VARCHAR2,         -- 1.拠点
    iv_login_chain_store_code IN      VARCHAR2,         -- 2.チェーン店
    iv_request_date_from      IN      VARCHAR2,         -- 3.着日（From）
    iv_request_date_to        IN      VARCHAR2,         -- 4.着日（To）
    iv_bargain_class          IN      VARCHAR2,         -- 5.定番特売区分
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.パラメータ出力
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_parameter,
                                   iv_token_name1        => cv_tkn_param1,
                                   iv_token_value1       => iv_login_base_code,
                                   iv_token_name2        => cv_tkn_param2,
                                   iv_token_value2       => iv_login_chain_store_code,
                                   iv_token_name3        => cv_tkn_param3,
                                   iv_token_value3       => iv_request_date_from,
                                   iv_token_name4        => cv_tkn_param4,
                                   iv_token_value4       => iv_request_date_to,
                                   iv_token_name5        => cv_tkn_param5,
                                   iv_token_value5       => iv_bargain_class
                                 );
    --
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => lv_errmsg
    );
    --1行空白
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => NULL
    );
--
    --==================================
    -- 2.パラメータ変換
    --==================================
    gv_login_base_code        := iv_login_base_code;
    gv_login_chain_store_code := iv_login_chain_store_code;
/* 2009/08/11 Ver1.9 Mod Start */
--    gd_request_date_from      := TO_DATE( iv_request_date_from, cv_fmt_datetime );
--    gd_request_date_to        := TO_DATE( iv_request_date_to, cv_fmt_datetime );
    gd_request_date_from        := TO_DATE( TO_CHAR( TO_DATE(iv_request_date_from, cv_fmt_date)
                                                    ,cv_fmt_date) || cv_time_min
                                           ,cv_fmt_datetime );
    gd_request_date_to          := TO_DATE( TO_CHAR( TO_DATE(iv_request_date_to,   cv_fmt_date)
                                                    ,cv_fmt_date) || cv_time_max
                                           ,cv_fmt_datetime );
/* 2009/08/11 Ver1.9 Mod End   */
/* 2009/06/15 Ver1.6 Mod Start */
--    gv_bargain_class          := SUBSTRB( iv_bargain_class, 1, 1 );
    gv_bargain_class          := iv_bargain_class;
/* 2009/06/15 Ver1.6 Mod End   */
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック処理(A-1)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter';        -- プログラム名
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
    lv_org_id        VARCHAR2(5000);
    lv_max_date      VARCHAR2(5000);
    lv_profile_name  VARCHAR2(5000);
    lv_req_dt_from   VARCHAR2(5000);
    lv_req_dt_to     VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
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
    --==================================
    -- 1.業務日付取得
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.MO:営業単位
    --==================================
    lv_org_id                 := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_org_id
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
--
    --==================================
    -- 3.XXCOS:MAX日付
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 4.XXCOS:ケース単位コード
    --==================================
    gt_case_uom_code          := FND_PROFILE.VALUE( ct_prof_case_uom_code );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_case_uom_code IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_case_uom_code
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 5.パラメータチェック
    --==================================
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      RAISE global_date_reversal_expt;
    END IF;
--
    --==================================
    -- 6.定番特売区分（ヘッダ）チェック
    --==================================
--
    BEGIN
      SELECT
        flv.meaning                     bargain_class_name
      INTO
        gt_bargain_class_name
      FROM
/* 2009/08/11 Ver1.9 Del Start */
--        fnd_application                 fa,
--        fnd_lookup_types                flt,
/* 2009/08/11 Ver1.9 Del End   */
        fnd_lookup_values               flv
      WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--        fa.application_id               = flt.application_id
--      AND flt.lookup_type               = flv.lookup_type
--      AND fa.application_short_name     = ct_xxcos_appl_short_name
--      AND flt.lookup_type               = ct_qct_bargain_class
          flv.lookup_type               = ct_qct_bargain_class
/* 2009/08/11 Ver1.9 Mod End   */
      AND flv.lookup_code               = gv_bargain_class
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
/* 2009/08/11 Ver1.9 Mod Start */
--      AND flv.language                  = USERENV( 'LANG' )
      AND flv.language                  = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_bargain_cls_tblnm
                                 );
        RAISE global_lookup_code_expt;
    END;
    --定番特売区分（ヘッダ） が全ての場合、名称をNULLクリアする。
    IF ( gv_bargain_class = cv_bargain_class_all ) THEN
      gt_bargain_class_name   := NULL;
    END IF;
--
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      RAISE global_date_reversal_expt;
    END IF;
--
/* 2009/08/20 Ver1.10 Mod Start */
    --==================================
    -- 7.定番特売区分「定番」取得
    --==================================
--
    BEGIN
      SELECT
        flv.lookup_code                 fixture_code                --定番特売区分：定番のコード値
       ,flv.meaning                     fixture_name                --定番特売区分：定番の名称
      INTO
        gt_fixture_code
       ,gt_fixture_name
      FROM
        fnd_lookup_values               flv
      WHERE
          flv.lookup_type               = ct_qct_bargain_class
      AND flv.attribute1                = cv_bargain_class_fixture  --取得対象 = 定番
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
      AND flv.language                  = ct_lang
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_get_fixture_expt;
    END;
--
    --==================================
    -- 8.定番特売区分「特売」取得
    --==================================
--
    BEGIN
      SELECT
        flv.lookup_code                 bargain_code                --定番特売区分：特売のコード値
       ,flv.meaning                     bargain_name                --定番特売区分：特売の名称
      INTO
        gt_bargain_code
       ,gt_bargain_name
      FROM
        fnd_lookup_values               flv
      WHERE
          flv.lookup_type               = ct_qct_bargain_class
      AND flv.attribute1                = cv_bargain_class_bargain  --取得対象 = 特売
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
      AND flv.language                  = ct_lang
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_get_bargain_expt;
    END;
/* 2009/08/20 Ver1.10 Mod End   */
  EXCEPTION
/* 2009/08/20 Ver1.10 Mod Start */
    -- *** 定番情報取得例外ハンドラ ***
    WHEN global_get_fixture_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_fixture_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 特売情報取得例外ハンドラ ***
    WHEN global_get_bargain_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_bargain_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2009/08/20 Ver1.10 Mod End   */
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 日付逆転例外ハンドラ ***
    WHEN global_date_reversal_expt THEN
      lv_req_dt_from          := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_req_dt_from
                                 );
      lv_req_dt_to            := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_req_dt_to
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_date_reversal_err,
                                   iv_token_name1        => cv_tkn_date_from,
                                   iv_token_value1       => lv_req_dt_from,
                                   iv_token_name2        => cv_tkn_date_to,
                                   iv_token_value2       => lv_req_dt_to
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** クイックコードマスタ例外ハンドラ ***
    WHEN global_lookup_code_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_select_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
    lv_exists_flag   VARCHAR2(1);
    lv_step          VARCHAR(5000);
    --集計用変数
    ln_quantity      NUMBER;
    --単位換算用変数
    lt_item_code              mtl_system_items_b.segment1%TYPE;
    lt_organization_code      mtl_parameters.organization_code%TYPE;
    lt_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;
    lt_organization_id        mtl_system_items_b.organization_id%TYPE;
    lt_after_uom_code         mtl_units_of_measure_tl.uom_code%TYPE;
    ln_after_quantity         NUMBER;
    ln_content                NUMBER;
    --キーブレイク変数
    lt_key_base_code                    xxcmm_cust_accounts.delivery_base_code%TYPE;
                                                                      --拠点コード
    lt_key_base_name                    hz_parties.party_name%TYPE;
                                                                      --拠点名称
    lt_key_subinventory                 mtl_secondary_inventories.secondary_inventory_name%TYPE;
                                                                      --倉庫
    lt_key_subinventory_name            mtl_secondary_inventories.description%TYPE;
                                                                      --倉庫名
    lt_key_chain_store_code             xxcmm_cust_accounts.chain_store_code%TYPE;
                                                                      --チェーン店コード
    lt_key_chain_store_name             hz_parties.party_name%TYPE;
                                                                      --チェーン店名
    lt_key_deli_center_code             xxcmm_cust_accounts.deli_center_code%TYPE;
                                                                      --センターコード
    lt_key_deli_center_name             xxcmm_cust_accounts.deli_center_name%TYPE;
                                                                      --センター名
    lt_key_edi_district_code            xxcmm_cust_accounts.edi_district_code%TYPE;
                                                                      --地区コード
    lt_key_edi_district_name            xxcmm_cust_accounts.edi_district_name%TYPE;
                                                                      --地区名
    lt_key_store_code                   xxcmm_cust_accounts.store_code%TYPE;
                                                                      --店舗コード
    lt_key_cust_store_name              xxcmm_cust_accounts.cust_store_name%TYPE;
                                                                      --店舗名
    lt_key_delivery_order1              xxcmm_cust_accounts.delivery_order%TYPE;
                                                                      --配送順（月、水、金）
    lt_key_delivery_order2              xxcmm_cust_accounts.delivery_order%TYPE;
                                                                      --配送順（火、木、土）
    lt_key_bargain_class_name           fnd_lookup_values.description%TYPE;
                                                                      --定番特売区分名称
    lt_key_slip_no                      oe_order_headers_all.cust_po_number%TYPE;
                                                                      --伝票NO
    lt_key_schedule_ship_date           oe_order_lines_all.schedule_ship_date%TYPE;
                                                                      --出荷日
    lt_key_request_date                 oe_order_lines_all.request_date%TYPE;
                                                                      --着日
    lt_key_inventory_item_id            mtl_system_items_b.inventory_item_id%TYPE;
                                                                      --品目ID
    lt_key_organization_id              mtl_system_items_b.organization_id%TYPE;
                                                                      --在庫組織ID
    lt_key_item_code                    mtl_system_items_b.segment1%TYPE;
                                                                      --商品コード
    lt_key_item_name                    mtl_system_items_b.description%TYPE;
                                                                      --商品名
    lv_key_edi_item_err_flag            VARCHAR(1);                   --ＥＤＩフラグ
    lt_key_item_code2                   xxcos_edi_lines.product_code2%TYPE;
                                                                      --商品コード２
    lt_key_item_name2                   xxcos_edi_lines.product_name2_alt%TYPE;
                                                                      --商品名２
    lt_key_case_content                 mtl_uom_class_conversions.conversion_rate%TYPE;
                                                                      --ケース入数
--
    -- *** ローカル・カーソル ***
    CURSOR data_cur
    IS
      SELECT
        rpdpi.base_code                       base_code,                      --拠点コード
        rpdpi.base_name                       base_name,                      --拠点名称
        rpdpi.subinventory                    subinventory,                   --倉庫
        rpdpi.subinventory_name               subinventory_name,              --倉庫名
        rpdpi.chain_store_code                chain_store_code,               --チェーン店コード
        rpdpi.chain_store_name                chain_store_name,               --チェーン店名
        rpdpi.deli_center_code                deli_center_code,               --センターコード
        rpdpi.deli_center_name                deli_center_name,               --センター名
        rpdpi.edi_district_code               edi_district_code,              --地区コード
        rpdpi.edi_district_name               edi_district_name,              --地区名
        rpdpi.schedule_ship_date              schedule_ship_date,             --出荷日
        rpdpi.request_date                    request_date,                   --着日
        rpdpi.inventory_item_id               inventory_item_id,              --品目ID
        rpdpi.organization_id                 organization_id,                --在庫組織ID
        rpdpi.item_code                       item_code,                      --商品コード
        rpdpi.item_name                       item_name,                      --商品名
        DECODE( xeiet.lookup_code, NULL, NULL, rpdpi.product_code2 )
                                              item_code2,                     --商品コード２
        DECODE( xeiet.lookup_code, NULL, NULL, rpdpi.product_name2_alt )
                                              item_name2,                     --商品名２
        DECODE( xeiet.lookup_code, NULL, cv_edi_item_err_flag_no, cv_edi_item_err_flag_yes )
                                              edi_item_err_flag,              --ＥＤＩ品目エラーフラグ
        NVL( mucc.conversion_rate, ct_conv_rate_default )
                                              case_content,                   --ケース入数
        rpdpi.order_quantity_uom              order_quantity_uom,             --受注単位コード
        rpdpi.ordered_quantity                ordered_quantity,               --受注数量
        rpdpi.store_code                      store_code,                     --店舗コード
        rpdpi.cust_store_name                 cust_store_name,                --店舗名
        rpdpi.slip_no                         slip_no,                        --伝票NO
        rpdpi.bargain_class_name              bargain_class_name,             --定番特売区分名称
        rpdpi.delivery_order1                 delivery_order1,                --配送順（月、水、金）
        rpdpi.delivery_order2                 delivery_order2                 --配送順（火、木、土）
      FROM
        mtl_uom_class_conversions             mucc,                           --単位変換マスタ
        (
          SELECT
            flv.lookup_code                   lookup_code,                    --EDI品目エラータイプ
            flv.start_date_active             start_date_active,              --有効開始日
            NVL( flv.end_date_active, gd_max_date )
                                              end_date_active                 --有効終了日
          FROM
/* 2009/08/11 Ver1.9 Del Start */
--            fnd_application                   fa,                             --アプリケーションマスタ
--            fnd_lookup_types                  flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
            fnd_lookup_values                 flv                             --クイックコードマスタ
          WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--            fa.application_id                 = flt.application_id
--          AND flt.lookup_type                 = flv.lookup_type
--          AND fa.application_short_name       = ct_xxcos_appl_short_name
--          AND flt.lookup_type                 = ct_qct_edi_item_err_type
--          AND flv.language                    = USERENV( 'LANG' )
              flv.lookup_type                 = ct_qct_edi_item_err_type
          AND flv.language                    = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
          AND flv.enabled_flag                = ct_enabled_flag_yes
        ) xeiet,                                                              --EDI品目エラータイプマスタ
        (
          SELECT
-- 2009/08/11 Ver1.9 Add Start *
            /*+ leading(xca1) use_nl(xca1 hca2 xca3) */
-- 2009/08/11 Ver1.9 Add End   *
            xca1.delivery_base_code           base_code,                      --拠点コード
            hp2.party_name                    base_name,                      --拠点名称
            oola.subinventory                 subinventory,                   --倉庫
            msi.description                   subinventory_name,              --倉庫名
            xca1.chain_store_code             chain_store_code,               --チェーン店コード
            hp3.party_name                    chain_store_name,               --チェーン店名
            xca1.deli_center_code             deli_center_code,               --センターコード
            xca1.deli_center_name             deli_center_name,               --センター名
            xca1.edi_district_code            edi_district_code,              --地区コード
            xca1.edi_district_name            edi_district_name,              --地区名
            TRUNC( oola.schedule_ship_date )  schedule_ship_date,             --出荷日
            TRUNC( oola.request_date )        request_date,                   --着日
            msib.inventory_item_id            inventory_item_id,              --品目ID
            msib.organization_id              organization_id,                --在庫組織ID
            msib.segment1                     item_code,                      --商品コード
            msib.description                  item_name,                      --商品名
            NULL                              product_code2,                  --商品コード２
            NULL                              product_name2_alt,              --商品名２
            ooha.ordered_date                 ordered_date,                   --受注日
            oola.order_quantity_uom           order_quantity_uom,             --受注単位コード
            oola.ordered_quantity             ordered_quantity,               --受注数量
            xca1.store_code                   store_code,                     --店舗コード
            xca1.cust_store_name              cust_store_name,                --店舗名
            ooha.cust_po_number               slip_no,                        --伝票NO
            scm.sale_class_name               bargain_class_name,             --定番特売区分名称
            TRIM( SUBSTRB( xca1.delivery_order, 1, 7 ) )
                                              delivery_order1,                --配送順（月、水、金）
            TRIM( NVL( SUBSTRB( xca1.delivery_order, 8, 7 ), SUBSTRB( xca1.delivery_order, 1, 7 ) ) )
                                              delivery_order2                 --配送順（火、木、土）
          FROM
            oe_order_headers_all              ooha,                           --受注ヘッダテーブル
            oe_order_lines_all                oola,                           --受注明細テーブル
            oe_order_sources                  oos,                            --受注ソースマスタ
            oe_transaction_types_all          otta,                           --受注タイプマスタ
            oe_transaction_types_tl           ottt,                           --受注タイプ翻訳マスタ
            oe_transaction_types_all          otta2,                          --受注タイプマスタ
            oe_transaction_types_tl           ottt2,                          --受注タイプ翻訳マスタ
            hz_cust_accounts                  hca1,                           --顧客マスタ
            xxcmm_cust_accounts               xca1,                           --アカウントアドオンマスタ
            hz_cust_accounts                  hca2,                           --顧客拠点マスタ
            hz_parties                        hp2,                            --パーティ拠点マスタ
            hz_cust_accounts                  hca3,                           --顧客チェーン店マスタ
            hz_parties                        hp3,                            --パーティチェーン店マスタ
            xxcmm_cust_accounts               xca3,                           --アカウントアドオンチェーン店マスタ
            mtl_secondary_inventories         msi,                            --保管場所マスタ
            mtl_system_items_b                msib,                           --品目マスタ
            (
              SELECT
                flv.meaning                   line_type_name,                 --明細タイプ名
                flv.attribute1                sale_class_default,             --売上区分初期値
                flv.start_date_active         start_date_active,              --有効開始日
                NVL( flv.end_date_active, gd_max_date )
                                              end_date_active                 --有効終了日
              FROM
/* 2009/08/11 Ver1.9 Del Start */
--                fnd_application               fa,                             --アプリケーションマスタ
--                fnd_lookup_types              flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                fnd_lookup_values             flv                             --クイックコードマスタ
              WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                fa.application_id             = flt.application_id
--              AND flt.lookup_type             = flv.lookup_type
--              AND fa.application_short_name   = ct_xxcos_appl_short_name
--              AND flt.lookup_type             = ct_qct_sale_class_default
                  flv.lookup_type             = ct_qct_sale_class_default
/* 2009/08/11 Ver1.9 Mod End   */
              AND flv.lookup_code             LIKE ct_qcc_sale_class_default
/* 2009/08/11 Ver1.9 Mod Start */
--              AND flv.language                = USERENV( 'LANG' )
              AND flv.language                = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              AND flv.enabled_flag            = ct_enabled_flag_yes
            ) scdm,                                                           --売上区分初期値マスタ
            (
              SELECT
                flv.meaning                   sale_class,                     --売上区分
                flv.description               sale_class_name,                --売上区分名
                flv.start_date_active         start_date_active,              --有効開始日
                NVL( flv.end_date_active, gd_max_date )
                                              end_date_active                 --有効終了日
              FROM
/* 2009/08/11 Ver1.9 Del Start */
--                fnd_application               fa,                             --アプリケーションマスタ
--                fnd_lookup_types              flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                fnd_lookup_values             flv                             --クイックコードマスタ
              WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                fa.application_id             = flt.application_id
--              AND flt.lookup_type             = flv.lookup_type
--              AND fa.application_short_name   = ct_xxcos_appl_short_name
--              AND flt.lookup_type             = ct_qct_sale_class
                  flv.lookup_type             = ct_qct_sale_class
/* 2009/08/11 Ver1.9 Mod End   */
              AND flv.lookup_code             LIKE ct_qcc_sale_class || cv_multi
/* 2009/08/11 Ver1.9 Mod Start */
--              AND flv.language                = USERENV( 'LANG' )
              AND flv.language                = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              AND flv.enabled_flag            = ct_enabled_flag_yes
            ) scm                                                             --売上区分マスタ
          WHERE
            ooha.header_id                    = oola.header_id
          AND ooha.order_source_id            = oos.order_source_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flt.lookup_type           = ct_qct_order_source
                    flv.lookup_type           = ct_qct_order_source
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_ord_src_manual
                AND flv.meaning               = oos.name
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Del Start */
--                AND ROWNUM                    = 1
/* 2009/08/11 Ver1.9 Del End   */
             )
          AND ooha.order_type_id              = otta.transaction_type_id
          AND otta.transaction_type_id        = ottt.transaction_type_id
          AND otta.transaction_type_code      = ct_tran_type_code_order
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flt.lookup_type           = ct_qct_order_type
                    flv.lookup_type           = ct_qct_order_type
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_order_type
                AND flv.meaning               = ottt.name
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
--                AND ROWNUM                    = 1
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              )
/* 2009/08/11 Ver1.9 Mod Start */
--          AND ottt.language                   = USERENV( 'LANG' )
          AND ottt.language                   = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
          AND oola.line_type_id               = otta2.transaction_type_id
          AND otta2.transaction_type_id       = ottt2.transaction_type_id
          AND otta2.transaction_type_code     = ct_tran_type_code_line
/* 2009/08/11 Ver1.9 Mod Start */
--          AND ottt2.language                  = USERENV( 'LANG' )
          AND ottt2.language                  = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
          AND scdm.line_type_name             = ottt2.name
          AND TRUNC( ooha.ordered_date )      >= scdm.start_date_active
          AND TRUNC( ooha.ordered_date )      <= scdm.end_date_active
          AND ooha.flow_status_code           = ct_hdr_status_booked
          AND oola.flow_status_code           NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
/* 2009/08/11 Ver1.9 Mod Start */
--          AND TRUNC( oola.request_date )      >= gd_request_date_from
--          AND TRUNC( oola.request_date )      <= gd_request_date_to
          AND oola.request_date              >= gd_request_date_from
          AND oola.request_date              <= gd_request_date_to
/* 2009/08/11 Ver1.9 Mod End   */
          AND oola.subinventory               = msi.secondary_inventory_name
          AND oola.ship_from_org_id           = msi.organization_id
-- 2010/02/04 Ver1.11 Del Start *
--          AND msi.attribute1                  = ct_subinv_class
-- 2010/02/04 Ver1.11 Del End   *
          AND oola.inventory_item_id          = msib.inventory_item_id
          AND oola.ship_from_org_id           = msib.organization_id
          AND oola.sold_to_org_id             = hca1.cust_account_id
          AND hca1.cust_account_id            = xca1.customer_id
          AND xca1.chain_store_code           = gv_login_chain_store_code
          AND xca1.delivery_base_code         = gv_login_base_code
-- 2010/02/04 Ver1.11 Del Start *
--          AND SUBSTR( xca1.tsukagatazaiko_div, 2, 1 )
--                                              NOT IN ( cv_invtype_dlv, cv_invtype_dlvfix )
-- 2010/02/04 Ver1.11 Del End   *
          AND xca1.delivery_base_code         = hca2.account_number
          AND hca2.party_id                   = hp2.party_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flv.lookup_type           = ct_qct_cus_class_mst
                    flv.lookup_type           = ct_qct_cus_class_mst
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_cus_class_mst1
                AND flv.meaning               = hca2.customer_class_code
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
--                AND ROWNUM                    = 1
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              )
          AND xca1.chain_store_code           = xca3.chain_store_code
          AND hca3.cust_account_id            = xca3.customer_id
          AND hca3.party_id                   = hp3.party_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flv.lookup_type           = ct_qct_cus_class_mst
                    flv.lookup_type           = ct_qct_cus_class_mst
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_cus_class_mst2
                AND flv.meaning               = hca3.customer_class_code
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
--                AND ROWNUM                    = 1
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              )
          AND ooha.org_id                     = gn_org_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flt.lookup_type           = ct_qct_sale_class
                    flv.lookup_type           = ct_qct_sale_class
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE gt_qcc_sale_class
                AND flv.meaning               = NVL( oola.attribute5, scdm.sale_class_default )
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Del Start */
--                AND ROWNUM                    = 1
/* 2009/08/11 Ver1.9 Del End */
             )
          AND scm.sale_class                  = NVL( oola.attribute5, scdm.sale_class_default )
          AND TRUNC( ooha.ordered_date )      >= scm.start_date_active
          AND TRUNC( ooha.ordered_date )      <= scm.end_date_active
/* 2009/08/11 Ver1.9 Mod Start */
--          AND msib.segment1                   NOT IN (
--                SELECT  look_val.lookup_code    -- 非在庫品目
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     app.application_short_name = ct_xxcos_appl_short_name
          AND NOT EXISTS (
                SELECT  cv_exists_flag_yes          exists_flag
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.lookup_code  = msib.segment1
                AND     look_val.language     = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = ct_enabled_flag_yes
                AND     look_val.lookup_type = ct_xxcos1_no_inv_item_code )
-- 2009/07/10 Ver1.7 Add Start *
          AND (   ooha.global_attribute3 IS NULL
               OR ooha.global_attribute3 IN ( cv_info_class_01, cv_info_class_02 ) )
-- 2009/07/10 Ver1.7 Add End   *
          UNION ALL
          SELECT
-- 2009/08/11 Ver1.9 Add Start *
            /*+ leading(xca1) use_nl(xca1 hca2 xca3) */
-- 2009/08/11 Ver1.9 Add End   *
            xca1.delivery_base_code           base_code,                      --拠点コード
            hp2.party_name                    base_name,                      --拠点名称
            oola.subinventory                 subinventory,                   --倉庫
            msi.description                   subinventory_name,              --倉庫名
            xca1.chain_store_code             chain_store_code,               --チェーン店コード
            hp3.party_name                    chain_store_name,               --チェーン店名
            xca1.deli_center_code             deli_center_code,               --センターコード
            xca1.deli_center_name             deli_center_name,               --センター名
            xca1.edi_district_code            edi_district_code,              --地区コード
            xca1.edi_district_name            edi_district_name,              --地区名
            TRUNC( oola.schedule_ship_date )  schedule_ship_date,             --出荷日
            TRUNC( oola.request_date )        request_date,                   --着日
            msib.inventory_item_id            inventory_item_id,              --品目ID
            msib.organization_id              organization_id,                --在庫組織ID
            msib.segment1                     item_code,                      --商品コード
            msib.description                  item_name,                      --商品名
            xel.product_code2                 product_code2,                  --商品コード２
            xel.product_name2_alt             product_name2_alt,              --商品名２
            ooha.ordered_date                 ordered_date,                   --受注日
            oola.order_quantity_uom           order_quantity_uom,             --受注単位コード
            oola.ordered_quantity             ordered_quantity,               --受注数量
            xca1.store_code                   store_code,                     --店舗コード
            xca1.cust_store_name              cust_store_name,                --店舗名
            ooha.cust_po_number               slip_no,                        --伝票NO
/* 2009/08/20 Ver1.10 Mod Start */
--            scm.sale_class_name               bargain_class_name,             --定番特売区分名称
            CASE
              WHEN xeh.ar_sale_class = gt_fixture_code THEN
                gt_fixture_name
              ELSE
                gt_bargain_name
            END CASE,                                                         --定番特売区分名称
/* 2009/08/20 Ver1.10 Mod Start */
            TRIM( SUBSTRB( xca1.delivery_order, 1, 7 ) )
                                              delivery_order1,                --配送順（月、水、金）
            TRIM( NVL( SUBSTRB( xca1.delivery_order, 8, 7 ), SUBSTRB( xca1.delivery_order, 1, 7 ) ) )
                                              delivery_order2                 --配送順（火、木、土）
          FROM
            oe_order_headers_all              ooha,                           --受注ヘッダテーブル
            oe_order_lines_all                oola,                           --受注明細テーブル
            oe_order_sources                  oos,                            --受注ソースマスタ
            oe_transaction_types_all          otta,                           --受注タイプマスタ
            oe_transaction_types_tl           ottt,                           --受注タイプ翻訳マスタ
            oe_transaction_types_all          otta2,                          --受注タイプマスタ
            oe_transaction_types_tl           ottt2,                          --受注タイプ翻訳マスタ
            hz_cust_accounts                  hca1,                           --顧客マスタ
            xxcmm_cust_accounts               xca1,                           --アカウントアドオンマスタ
            hz_cust_accounts                  hca2,                           --顧客拠点マスタ
            hz_parties                        hp2,                            --パーティ拠点マスタ
            hz_cust_accounts                  hca3,                           --顧客チェーン店マスタ
            hz_parties                        hp3,                            --パーティチェーン店マスタ
            xxcmm_cust_accounts               xca3,                           --アカウントアドオンチェーン店マスタ
            mtl_secondary_inventories         msi,                            --保管場所マスタ
            mtl_system_items_b                msib,                           --品目マスタ
            xxcos_edi_headers                 xeh,                            --EDIヘッダ情報テーブル
            xxcos_edi_lines                   xel,                            --EDI明細情報テーブル
            (
              SELECT
                flv.meaning                   line_type_name,                 --明細タイプ名
                flv.attribute1                sale_class_default,             --売上区分初期値
                flv.start_date_active         start_date_active,              --有効開始日
                NVL( flv.end_date_active, gd_max_date )
                                              end_date_active                 --有効終了日
              FROM
/* 2009/08/11 Ver1.9 Del Start */
--                fnd_application               fa,                             --アプリケーションマスタ
--                fnd_lookup_types              flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                fnd_lookup_values             flv                             --クイックコードマスタ
              WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                fa.application_id             = flt.application_id
--              AND flt.lookup_type             = flv.lookup_type
--              AND fa.application_short_name   = ct_xxcos_appl_short_name
--              AND flt.lookup_type             = ct_qct_sale_class_default
                  flv.lookup_type             = ct_qct_sale_class_default
/* 2009/08/11 Ver1.9 Mod End   */
              AND flv.lookup_code             LIKE ct_qcc_sale_class_default
/* 2009/08/11 Ver1.9 Mod Start */
--              AND flv.language                = USERENV( 'LANG' )
              AND flv.language                = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              AND flv.enabled_flag            = ct_enabled_flag_yes
            ) scdm                                                            --売上区分初期値マスタ
/* 2009/08/20 Ver1.10 Del Start */
--            (
--              SELECT
--                flv.meaning                   sale_class,                     --売上区分
--                flv.description               sale_class_name,                --売上区分名
--                flv.start_date_active         start_date_active,              --有効開始日
--                NVL( flv.end_date_active, gd_max_date )
--                                              end_date_active                 --有効終了日
--              FROM
--/* 2009/08/11 Ver1.9 Del Start */
----                fnd_application               fa,                             --アプリケーションマスタ
----                fnd_lookup_types              flt,                            --クイックコードタイプマスタ
--/* 2009/08/11 Ver1.9 Del End   */
--                fnd_lookup_values             flv                             --クイックコードマスタ
--              WHERE
--/* 2009/08/11 Ver1.9 Mod Start */
----                fa.application_id             = flt.application_id
----              AND flt.lookup_type             = flv.lookup_type
----              AND fa.application_short_name   = ct_xxcos_appl_short_name
----              AND flt.lookup_type             = ct_qct_sale_class
--                  flv.lookup_type             = ct_qct_sale_class
--/* 2009/08/11 Ver1.9 Mod End   */
--              AND flv.lookup_code             LIKE ct_qcc_sale_class || cv_multi
--/* 2009/08/11 Ver1.9 Mod Start */
----              AND flv.language                = USERENV( 'LANG' )
--              AND flv.language                = ct_lang
--/* 2009/08/11 Ver1.9 Mod End   */
--              AND flv.enabled_flag            = ct_enabled_flag_yes
--            ) scm                                                             --売上区分マスタ
/* 2009/08/20 Ver1.10 Del End */
          WHERE
            ooha.header_id                    = oola.header_id
          AND ooha.order_source_id            = oos.order_source_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flt.lookup_type           = ct_qct_order_source
                    flv.lookup_type           = ct_qct_order_source
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_ord_src_edi
                AND flv.meaning               = oos.name
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
--                AND ROWNUM                    = 1
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              )
          AND ooha.order_type_id              = otta.transaction_type_id
          AND otta.transaction_type_id        = ottt.transaction_type_id
          AND otta.transaction_type_code      = ct_tran_type_code_order
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flt.lookup_type           = ct_qct_order_type
                    flv.lookup_type           = ct_qct_order_type
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_order_type
                AND flv.meaning               = ottt.name
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
--                AND ROWNUM                    = 1
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              )
/* 2009/08/11 Ver1.9 Mod Start */
--          AND ottt.language                   = USERENV( 'LANG' )
          AND ottt.language                   = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
          AND oola.line_type_id               = otta2.transaction_type_id
          AND otta2.transaction_type_id       = ottt2.transaction_type_id
          AND otta2.transaction_type_code     = ct_tran_type_code_line
/* 2009/08/11 Ver1.9 Mod Start */
--          AND ottt2.language                  = USERENV( 'LANG' )
          AND ottt2.language                  = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
          AND scdm.line_type_name             = ottt2.name
          AND TRUNC( ooha.ordered_date )      >= scdm.start_date_active
          AND TRUNC( ooha.ordered_date )      <= scdm.end_date_active
          AND ooha.flow_status_code           IN ( ct_hdr_status_booked, ct_hdr_status_entered )
          AND oola.flow_status_code           NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
/* 2009/08/11 Ver1.9 Mod Start */
--          AND TRUNC( oola.request_date )      >= gd_request_date_from
--          AND TRUNC( oola.request_date )      <= gd_request_date_to
          AND oola.request_date              >= gd_request_date_from
          AND oola.request_date              <= gd_request_date_to
/* 2009/08/11 Ver1.9 Mod End   */
          AND oola.subinventory               = msi.secondary_inventory_name
          AND oola.ship_from_org_id           = msi.organization_id
-- 2010/02/04 Ver1.11 Del Start *
--          AND msi.attribute1                  = ct_subinv_class
-- 2010/02/04 Ver1.11 Del End   *
          AND oola.inventory_item_id          = msib.inventory_item_id
          AND oola.ship_from_org_id           = msib.organization_id
          AND oola.sold_to_org_id             = hca1.cust_account_id
          AND hca1.cust_account_id            = xca1.customer_id
          AND xca1.chain_store_code           = gv_login_chain_store_code
          AND xca1.delivery_base_code         = gv_login_base_code
-- 2010/02/04 Ver1.11 Del Start *
--          AND SUBSTR( xca1.tsukagatazaiko_div, 2, 1 )
--                                              NOT IN ( cv_invtype_dlv, cv_invtype_dlvfix )
-- 2010/02/04 Ver1.11 Del End   *
          AND xca1.delivery_base_code         = hca2.account_number
          AND hca2.party_id                   = hp2.party_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flv.lookup_type           = ct_qct_cus_class_mst
                    flv.lookup_type           = ct_qct_cus_class_mst
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_cus_class_mst1
                AND flv.meaning               = hca2.customer_class_code
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
--                AND ROWNUM                    = 1
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              )
          AND xca1.chain_store_code           = xca3.chain_store_code
          AND hca3.cust_account_id            = xca3.customer_id
          AND hca3.party_id                   = hp3.party_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes          exists_flag
                FROM
/* 2009/08/11 Ver1.9 Del Start */
--                  fnd_application             fa,                             --アプリケーションマスタ
--                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
/* 2009/08/11 Ver1.9 Del End   */
                  fnd_lookup_values           flv                             --クイックコードマスタ
                WHERE
/* 2009/08/11 Ver1.9 Mod Start */
--                  fa.application_id           = flt.application_id
--                AND flt.lookup_type           = flv.lookup_type
--                AND fa.application_short_name = ct_xxcos_appl_short_name
--                AND flv.lookup_type           = ct_qct_cus_class_mst
                    flv.lookup_type           = ct_qct_cus_class_mst
/* 2009/08/11 Ver1.9 Mod End   */
                AND flv.lookup_code           LIKE ct_qcc_cus_class_mst2
                AND flv.meaning               = hca3.customer_class_code
                AND TRUNC( ooha.ordered_date )
                                              >= flv.start_date_active
                AND TRUNC( ooha.ordered_date )
                                              <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag          = ct_enabled_flag_yes
/* 2009/08/11 Ver1.9 Mod Start */
--                AND flv.language              = USERENV( 'LANG' )
--                AND ROWNUM                    = 1
                AND flv.language              = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
              )
          AND oola.orig_sys_document_ref      = xeh.order_connection_number
          AND xeh.data_type_code              IN ( ct_data_type_code_edi, ct_data_type_code_shop )
          AND xeh.edi_header_info_id          = xel.edi_header_info_id
--****************************** 2009/06/05 1.4 T.Kitajima MOD START ******************************--
--          AND xel.line_no                     = oola.line_number
          AND xel.order_connection_line_number  = oola.orig_sys_line_ref
--****************************** 2009/06/05 1.4 T.Kitajima MOD  MOD  ******************************--
          AND ooha.org_id                     = gn_org_id
/* 2009/08/11 Ver1.9 Mod Start */
--          AND msib.segment1   NOT IN ( 
--                SELECT  look_val.lookup_code    -- 非在庫品目
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     app.application_short_name = ct_xxcos_appl_short_name
          AND (   NOT EXISTS (
                SELECT  cv_exists_flag_yes    exists_flag
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.lookup_code  = msib.segment1
                AND     look_val.language     = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = ct_enabled_flag_yes
                AND     look_val.lookup_type = ct_xxcos1_no_inv_item_code
/* 2009/08/11 Ver1.9 Mod Start */
--                AND     look_val.lookup_code NOT IN (
--                          SELECT  look_val.lookup_code   --EDI品目エラータイプ
--                          FROM    fnd_lookup_values     look_val,
--                                  fnd_lookup_types_tl   types_tl,
--                                  fnd_lookup_types      types,
--                                  fnd_application_tl    appl,
--                                  fnd_application       app
--                          WHERE   appl.application_id   = types.application_id
--                          AND     app.application_id    = appl.application_id
--                          AND     types_tl.lookup_type  = look_val.lookup_type
--                          AND     types.lookup_type     = types_tl.lookup_type
--                          AND     types.security_group_id   = types_tl.security_group_id
--                          AND     types.view_application_id = types_tl.view_application_id
--                          AND     types_tl.language = USERENV( 'LANG' )
--                          AND     look_val.language = USERENV( 'LANG' )
--                          AND     appl.language     = USERENV( 'LANG' )
--                          AND     app.application_short_name = ct_xxcos_appl_short_name
                )
               OR EXISTS (
                          SELECT  cv_exists_flag_yes    exists_flag
                          FROM    fnd_lookup_values     look_val
                          WHERE   look_val.lookup_code  = msib.segment1
                          AND     look_val.language     = ct_lang
/* 2009/08/11 Ver1.9 Mod End   */
                          AND     gd_process_date      >= look_val.start_date_active
                          AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                          AND     look_val.enabled_flag = ct_enabled_flag_yes
                          AND     look_val.lookup_type =  ct_qct_edi_item_err_type ))
/* 2009/08/20 Ver1.10 Mod Start */
--          AND EXISTS(
--                SELECT
--                  cv_exists_flag_yes          exists_flag
--                FROM
--/* 2009/08/11 Ver1.9 Del Start */
----                  fnd_application             fa,                             --アプリケーションマスタ
----                  fnd_lookup_types            flt,                            --クイックコードタイプマスタ
--/* 2009/08/11 Ver1.9 Del End   */
--                  fnd_lookup_values           flv                             --クイックコードマスタ
--                WHERE
--/* 2009/08/11 Ver1.9 Mod Start */
----                  fa.application_id           = flt.application_id
----                AND flt.lookup_type           = flv.lookup_type
----                AND fa.application_short_name = ct_xxcos_appl_short_name
----                AND flt.lookup_type           = ct_qct_sale_class
--                    flv.lookup_type           = ct_qct_sale_class
--/* 2009/08/11 Ver1.9 Mod End   */
--                AND flv.lookup_code           LIKE gt_qcc_sale_class
--                AND flv.meaning               = NVL( oola.attribute5, scdm.sale_class_default )
--                AND TRUNC( ooha.ordered_date )
--                                              >= flv.start_date_active
--                AND TRUNC( ooha.ordered_date )
--                                              <= NVL( flv.end_date_active, gd_max_date )
--/* 2009/08/11 Ver1.9 Mod Start */
----                AND flv.language              = USERENV( 'LANG' )
--                AND flv.language              = ct_lang
--/* 2009/08/11 Ver1.9 Mod End   */
--                AND flv.enabled_flag          = ct_enabled_flag_yes
--/* 2009/08/11 Ver1.9 Del Start */
----                AND ROWNUM                    = 1
--/* 2009/08/11 Ver1.9 Del End   */
--              )
--          AND scm.sale_class                  = NVL( oola.attribute5, scdm.sale_class_default )
--          AND TRUNC( ooha.ordered_date )      >= scm.start_date_active
--          AND TRUNC( ooha.ordered_date )      <= scm.end_date_active
          AND (   ( cv_bargain_class_all = gv_bargain_class )
               OR ( xeh.ar_sale_class    = gv_bargain_class )   )
/* 2009/08/20 Ver1.10 Mod End   */
-- 2009/07/10 Ver1.7 Add Start *
          AND (   ooha.global_attribute3 IS NULL
               OR ooha.global_attribute3 IN ( cv_info_class_01, cv_info_class_02 ) )
-- 2009/07/10 Ver1.7 Add End   *
      ) rpdpi
      WHERE
        mucc.inventory_item_id (+)            = rpdpi.inventory_item_id
      AND mucc.to_uom_code (+)                = gt_case_uom_code
      AND NVL( mucc.disable_date, gd_max_date )
                                              > TRUNC( rpdpi.ordered_date )
      AND rpdpi.item_code                     = xeiet.lookup_code (+)
      AND TRUNC( rpdpi.ordered_date )         >= xeiet.start_date_active (+)
      AND TRUNC( rpdpi.ordered_date )         <= xeiet.end_date_active (+)
      ORDER BY
        rpdpi.base_code,                                                      --拠点コード
        rpdpi.base_name,                                                      --拠点名称
        rpdpi.subinventory,                                                   --倉庫
        rpdpi.subinventory_name,                                              --倉庫名
        rpdpi.chain_store_code,                                               --チェーン店コード
        rpdpi.chain_store_name,                                               --チェーン店名
        rpdpi.deli_center_code,                                               --センターコード
        rpdpi.deli_center_name,                                               --センター名
        rpdpi.edi_district_code,                                              --地区コード
        rpdpi.edi_district_name,                                              --地区名
        rpdpi.store_code,                                                     --店舗コード
        rpdpi.cust_store_name,                                                --店舗名
        rpdpi.delivery_order1,                                                --配送順（月、水、金）
        rpdpi.delivery_order2,                                                --配送順（火、木、土）
        rpdpi.bargain_class_name,                                             --定番特売区分名称
        rpdpi.slip_no,                                                        --伝票NO
        rpdpi.schedule_ship_date,                                             --出荷日
        rpdpi.request_date,                                                   --着日
        rpdpi.inventory_item_id,                                              --品目ID
        rpdpi.organization_id,                                                --在庫組織ID
        rpdpi.item_code,                                                      --商品コード
        rpdpi.item_name,                                                      --商品名
        edi_item_err_flag,                                                    --ＥＤＩ品目エラーフラグ
        item_code2,                                                           --商品コード２
        item_name2,                                                           --商品名２
        case_content                                                          --ケース入数
      ;
--
    -- *** ローカル・レコード ***
    l_data_rec                          data_cur%ROWTYPE;
--
    -- *** ローカル・プロシージャ ***
    --==================================
    --キーブレイク項目セット
    --==================================
    PROCEDURE set_key_item
    IS
    BEGIN
      lt_key_base_code                := l_data_rec.base_code;
      lt_key_base_name                := l_data_rec.base_name;
      lt_key_subinventory             := l_data_rec.subinventory;
      lt_key_subinventory_name        := l_data_rec.subinventory_name;
      lt_key_chain_store_code         := l_data_rec.chain_store_code;
      lt_key_chain_store_name         := l_data_rec.chain_store_name;
      lt_key_deli_center_code         := l_data_rec.deli_center_code;
      lt_key_deli_center_name         := l_data_rec.deli_center_name;
      lt_key_edi_district_code        := l_data_rec.edi_district_code;
      lt_key_edi_district_name        := l_data_rec.edi_district_name;
      lt_key_store_code               := l_data_rec.store_code;
      lt_key_cust_store_name          := l_data_rec.cust_store_name;
      lt_key_delivery_order1          := l_data_rec.delivery_order1;
      lt_key_delivery_order2          := l_data_rec.delivery_order2;
      lt_key_bargain_class_name       := l_data_rec.bargain_class_name;
      lt_key_slip_no                  := l_data_rec.slip_no;
      lt_key_schedule_ship_date       := l_data_rec.schedule_ship_date;
      lt_key_request_date             := l_data_rec.request_date;
      lt_key_inventory_item_id        := l_data_rec.inventory_item_id;
      lt_key_organization_id          := l_data_rec.organization_id;
      lt_key_item_code                := l_data_rec.item_code;
      lt_key_item_name                := l_data_rec.item_name;
      lv_key_edi_item_err_flag        := l_data_rec.edi_item_err_flag;
      lt_key_item_code2               := l_data_rec.item_code2;
      lt_key_item_name2               := l_data_rec.item_name2;
      lt_key_case_content             := l_data_rec.case_content;
    END;
--
    --==================================
    --内部テーブルセット
    --==================================
    PROCEDURE set_internal_table
    IS
    BEGIN
      -- レコードIDの取得
      BEGIN
        SELECT
          xxcos_rep_pick_deli_pro_s01.NEXTVAL          record_id
        INTO
          ln_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx := ln_idx + 1;
      --
      g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;
      g_rpt_data_tab(ln_idx).base_code                    := lt_key_base_code;
--****************************** 2009/06/09 1.4 T.Kitajima MOD START ******************************--
--      g_rpt_data_tab(ln_idx).base_name                    := lt_key_base_name;
      g_rpt_data_tab(ln_idx).base_name                    := SUBSTRB( lt_key_base_name, cn_substr_1, cn_substr_40 ); 
                                                                           --拠点名を40バイトにカット
--****************************** 2009/06/09 1.4 T.Kitajima MOD  END  ******************************--
      g_rpt_data_tab(ln_idx).whse_code                    := lt_key_subinventory;
      g_rpt_data_tab(ln_idx).whse_name                    := lt_key_subinventory_name;
      g_rpt_data_tab(ln_idx).chain_code                   := lt_key_chain_store_code;
--****************************** 2009/06/09 1.4 T.Kitajima MOD START ******************************--
--      g_rpt_data_tab(ln_idx).chain_name                   := lt_key_chain_store_name;
      g_rpt_data_tab(ln_idx).chain_name                   := SUBSTRB( lt_key_chain_store_name, cn_substr_1, cn_substr_40 );
                                                                           --チェーン店名を40バイトにカット
--****************************** 2009/06/09 1.4 T.Kitajima MOD  END  ******************************--
      g_rpt_data_tab(ln_idx).center_code                  := lt_key_deli_center_code;
      g_rpt_data_tab(ln_idx).center_name                  := lt_key_deli_center_name;
      g_rpt_data_tab(ln_idx).area_code                    := lt_key_edi_district_code;
      g_rpt_data_tab(ln_idx).area_name                    := lt_key_edi_district_name;
      g_rpt_data_tab(ln_idx).shipped_date                 := lt_key_schedule_ship_date;
      g_rpt_data_tab(ln_idx).arrival_date                 := lt_key_request_date;
      g_rpt_data_tab(ln_idx).regular_sale_class_head      := SUBSTRB( gt_bargain_class_name, 1, 4 );
      --品目
--****************************** 2009/06/09 1.4 T.Kitajima MOD START ******************************--
--      g_rpt_data_tab(ln_idx).item_code                    := CASE
--                                                               WHEN ( lv_key_edi_item_err_flag =
--                                                                      cv_edi_item_err_flag_yes )
--                                                               THEN lt_key_item_code2
--                                                               ELSE lt_key_item_code
--                                                             END;
--      g_rpt_data_tab(ln_idx).item_name                    := CASE
--                                                               WHEN ( lv_key_edi_item_err_flag =
--                                                                      cv_edi_item_err_flag_yes )
--                                                               THEN lt_key_item_name2
--                                                               ELSE lt_key_item_name
--                                                             END;
      g_rpt_data_tab(ln_idx).item_code                    := SUBSTRB(
                                                                    CASE
                                                                      WHEN ( lv_key_edi_item_err_flag =
                                                                             cv_edi_item_err_flag_yes )
                                                                      THEN lt_key_item_code2
                                                                      ELSE lt_key_item_code
                                                                    END,
                                                                    cn_substr_1,
                                                                    cn_substr_16
                                                                   ); --16バイトにカット
      g_rpt_data_tab(ln_idx).item_name                    := SUBSTRB(
                                                                    CASE
                                                                      WHEN ( lv_key_edi_item_err_flag =
                                                                             cv_edi_item_err_flag_yes )
                                                                      THEN lt_key_item_name2
                                                                      ELSE lt_key_item_name
                                                                    END,
                                                                    cn_substr_1,
                                                                    cn_substr_40
                                                                   ); --40バイトにカット
--****************************** 2009/06/09 1.4 T.Kitajima MOD  END  ******************************--
      --配送順
      IF ( TO_CHAR( lt_key_request_date, cv_fmt_weekno )
                                        IN ( cv_weekno_monday, cv_weekno_wednesday, cv_weekno_friday ) )
      THEN
        g_rpt_data_tab(ln_idx).delivery_order_edi         := lt_key_delivery_order1;
      ELSIF ( TO_CHAR( lt_key_request_date, cv_fmt_weekno )
                                        IN ( cv_weekno_tuesday, cv_weekno_thursday, cv_weekno_saturday ) )
      THEN
        g_rpt_data_tab(ln_idx).delivery_order_edi         := lt_key_delivery_order2;
      ELSE
        g_rpt_data_tab(ln_idx).delivery_order_edi         := NULL;
      END IF;
      --
      g_rpt_data_tab(ln_idx).shop_code                    := lt_key_store_code;
      g_rpt_data_tab(ln_idx).shop_name                    := lt_key_cust_store_name;
      --
      g_rpt_data_tab(ln_idx).content                      := lt_key_case_content;
--****************************** 2009/06/09 1.4 T.Kitajima MOD START ******************************--
--      g_rpt_data_tab(ln_idx).case_num                     := TRUNC( ln_quantity / lt_key_case_content );
--      g_rpt_data_tab(ln_idx).indivi                       := MOD( ln_quantity, lt_key_case_content );
      IF ( g_rpt_data_tab(ln_idx).content = 0 ) THEN
        g_rpt_data_tab(ln_idx).case_num                   := 0;
        g_rpt_data_tab(ln_idx).indivi                     := ln_quantity;
      ELSE
        g_rpt_data_tab(ln_idx).case_num                   := TRUNC( ln_quantity / lt_key_case_content );
        g_rpt_data_tab(ln_idx).indivi                     := MOD( ln_quantity, lt_key_case_content );
      END IF;
--****************************** 2009/06/09 1.4 T.Kitajima MOD  END  ******************************--
      g_rpt_data_tab(ln_idx).quantity                     := ln_quantity;
      g_rpt_data_tab(ln_idx).entry_number                 := SUBSTRB( lt_key_slip_no, 1, 12 );
      g_rpt_data_tab(ln_idx).regular_sale_class_line      := SUBSTRB( lt_key_bargain_class_name, 1, 4 );
      --
      g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
      g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
      g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
      g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
      g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
      g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
      g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
      g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
      g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
    END;
--
    --==================================
    --単位換算
    --==================================
    PROCEDURE add_conv_quantity
    IS
    BEGIN
      --セット
      lt_item_code                := NULL;
      lt_organization_code        := NULL;
      lt_inventory_item_id        := l_data_rec.inventory_item_id;
      lt_organization_id          := l_data_rec.organization_id;
      lt_after_uom_code           := NULL;
      --単位換算
      xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code        => l_data_rec.order_quantity_uom,   -- 換算前単位コード
        in_before_quantity        => l_data_rec.ordered_quantity,     -- 換算前数量
        iov_item_code             => lt_item_code,                    -- 品目コード
        iov_organization_code     => lt_organization_code,            -- 在庫組織コード
        ion_inventory_item_id     => lt_inventory_item_id,            -- 品目ＩＤ
        ion_organization_id       => lt_organization_id,              -- 在庫組織ＩＤ
        iov_after_uom_code        => lt_after_uom_code,               -- 換算後単位コード
        on_after_quantity         => ln_after_quantity,               -- 換算後数量
        on_content                => ln_content,                      -- 入数
        ov_errbuf                 => lv_errbuf,                       -- エラー・メッセージエラー       #固定#
        ov_retcode                => lv_retcode,                      -- リターン・コード               #固定#
        ov_errmsg                 => lv_errmsg                        -- ユーザー・エラー・メッセージ   #固定#
      );
      --
      IF ( ov_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --数量集計
      ln_quantity := ln_quantity + ln_after_quantity;
    END;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 0.項目初期化
    --==================================
    --
    ln_idx := 0;
    --
    lt_key_base_code                      := NULL;            --拠点コード
    lt_key_base_name                      := NULL;            --拠点名称
    lt_key_subinventory                   := NULL;            --倉庫
    lt_key_subinventory_name              := NULL;            --倉庫名
    lt_key_chain_store_code               := NULL;            --チェーン店コード
    lt_key_chain_store_name               := NULL;            --チェーン店名
    lt_key_deli_center_code               := NULL;            --センターコード
    lt_key_deli_center_name               := NULL;            --センター名
    lt_key_edi_district_code              := NULL;            --地区コード
    lt_key_edi_district_name              := NULL;            --地区名
    lt_key_store_code                     := NULL;            --店舗コード
    lt_key_cust_store_name                := NULL;            --店舗名
    lt_key_delivery_order1                := NULL;            --配送順（月、水、金）
    lt_key_delivery_order2                := NULL;            --配送順（火、木、土）
    lt_key_bargain_class_name             := NULL;            --定番特売区分名称
    lt_key_slip_no                        := NULL;            --伝票NO
    lt_key_schedule_ship_date             := NULL;            --出荷日
    lt_key_request_date                   := NULL;            --着日
    lt_key_inventory_item_id              := NULL;            --品目ID
    lt_key_organization_id                := NULL;            --在庫組織ID
    lt_key_item_code                      := NULL;            --商品コード
    lt_key_item_name                      := NULL;            --商品名
    lv_key_edi_item_err_flag              := NULL;            --ＥＤＩ品目エラーフラグ
    lt_key_item_code2                     := NULL;            --商品コード２
    lt_key_item_name2                     := NULL;            --商品名２
    lt_key_case_content                   := NULL;            --ケース入数
    --
    ln_quantity := 0;
    --売上区分特定マスタ、特売区分特定マスタの生成
    IF ( gv_bargain_class                 = cv_bargain_class_all ) THEN
      gt_qcc_sale_class                   := ct_qcc_sale_class || cv_multi;
    ELSE
      gt_qcc_sale_class                   := ct_qcc_sale_class || gv_bargain_class || cv_multi;
    END IF;
    --
--
    --==================================
    -- 1.データ取得
    --==================================
    <<loop_get_data>>
    FOR l_get_data_rec IN data_cur
    LOOP
      l_data_rec := l_get_data_rec;
      IF ( ( lt_key_base_code             IS NULL )           --拠点コード
        AND ( lt_key_base_name            IS NULL )           --拠点名称
        AND ( lt_key_subinventory         IS NULL )           --倉庫
        AND ( lt_key_subinventory_name    IS NULL )           --倉庫名
        AND ( lt_key_chain_store_code     IS NULL )           --チェーン店コード
        AND ( lt_key_chain_store_name     IS NULL )           --チェーン店名
        AND ( lt_key_deli_center_code     IS NULL )           --センターコード
        AND ( lt_key_deli_center_name     IS NULL )           --センター名
        AND ( lt_key_edi_district_code    IS NULL )           --地区コード
        AND ( lt_key_edi_district_name    IS NULL )           --地区名
        AND ( lt_key_store_code           IS NULL )           --店舗コード
        AND ( lt_key_cust_store_name      IS NULL )           --店舗名
        AND ( lt_key_delivery_order1      IS NULL )           --配送順（月、水、金）
        AND ( lt_key_delivery_order2      IS NULL )           --配送順（火、木、土）
        AND ( lt_key_bargain_class_name   IS NULL )           --定番特売区分名称
        AND ( lt_key_slip_no              IS NULL )           --伝票NO
        AND ( lt_key_schedule_ship_date   IS NULL )           --出荷日
        AND ( lt_key_request_date         IS NULL )           --着日
        AND ( lt_key_inventory_item_id    IS NULL )           --品目ID
        AND ( lt_key_organization_id      IS NULL )           --在庫品目ID
        AND ( lt_key_item_code            IS NULL )           --商品コード
        AND ( lt_key_item_name            IS NULL )           --商品名
        AND ( lv_key_edi_item_err_flag    IS NULL )           --ＥＤＩ品目エラーフラグ
        AND ( lt_key_item_code2           IS NULL )           --商品コード２
        AND ( lt_key_item_name2           IS NULL )           --商品名２
        AND ( lt_key_case_content         IS NULL ) )         --ケース入数
      THEN
        --キーブレイク項目セット
        set_key_item;
        --換算数量加算
        add_conv_quantity;
      ELSE
        IF ( ( comp_char( lt_key_base_code, l_data_rec.base_code ) )                        --拠点コード
          AND ( comp_char( lt_key_base_name, l_data_rec.base_name ) )                       --拠点名称
          AND ( comp_char( lt_key_subinventory, l_data_rec.subinventory ) )                 --倉庫
          AND ( comp_char( lt_key_subinventory_name, l_data_rec.subinventory_name ) )       --倉庫名
          AND ( comp_char( lt_key_chain_store_code, l_data_rec.chain_store_code ) )         --チェーン店コード
          AND ( comp_char( lt_key_chain_store_name, l_data_rec.chain_store_name ) )         --チェーン店名
          AND ( comp_char( lt_key_deli_center_code, l_data_rec.deli_center_code ) )         --センターコード
          AND ( comp_char( lt_key_deli_center_name, l_data_rec.deli_center_name ) )         --センター名
          AND ( comp_char( lt_key_edi_district_code, l_data_rec.edi_district_code ) )       --地区コード
          AND ( comp_char( lt_key_edi_district_name, l_data_rec.edi_district_name ) )       --地区名
          AND ( comp_char( lt_key_store_code, l_data_rec.store_code ) )                     --店舗コード
          AND ( comp_char( lt_key_cust_store_name, l_data_rec.cust_store_name ) )           --店舗名
          AND ( comp_char( lt_key_delivery_order1, l_data_rec.delivery_order1 ) )           --配送順（月、水、金）
          AND ( comp_char( lt_key_delivery_order2, l_data_rec.delivery_order2 ) )           --配送順（火、木、土）
          AND ( comp_char( lt_key_bargain_class_name, l_data_rec.bargain_class_name ) )     --定番特売区分名称
          AND ( comp_char( lt_key_slip_no, l_data_rec.slip_no ) )                           --伝票NO
          AND ( comp_date( lt_key_schedule_ship_date, l_data_rec.schedule_ship_date ) )     --出荷日
          AND ( comp_date( lt_key_request_date, l_data_rec.request_date ) )                 --着日
          AND ( comp_num( lt_key_inventory_item_id, l_data_rec.inventory_item_id ) )        --品目ID
          AND ( comp_num( lt_key_organization_id, l_data_rec.organization_id ) )            --在庫組織ID
          AND ( comp_char( lt_key_item_code, l_data_rec.item_code ) )                       --商品コード
          AND ( comp_char( lt_key_item_name, l_data_rec.item_name ) )                       --商品名
          AND ( comp_char( lv_key_edi_item_err_flag, l_data_rec.edi_item_err_flag ) )       --ＥＤＩ品目エラーフラグ
          AND ( comp_char( lt_key_item_code2, l_data_rec.item_code2 ) )                     --商品コード２
          AND ( comp_char( lt_key_item_name2, l_data_rec.item_name2 ) )                     --商品名２
          AND ( comp_num( lt_key_case_content, l_data_rec.case_content ) ) )                --ケース入数
        THEN
          --換算数量加算
          add_conv_quantity;
        ELSE
          --内部テーブルセット
          set_internal_table;
          --初期化
          ln_quantity := 0;
          --キーブレイク項目セット
          set_key_item;
          --換算数量
          add_conv_quantity;
        END IF;
--
      END IF;
--
    END LOOP loop_get_data;
--
    --==================================
    -- 2.キーブレイク項目のチェック
    --==================================
      IF ( ( lt_key_base_code             IS NULL )           --拠点コード
        AND ( lt_key_base_name            IS NULL )           --拠点名称
        AND ( lt_key_subinventory         IS NULL )           --倉庫
        AND ( lt_key_subinventory_name    IS NULL )           --倉庫名
        AND ( lt_key_chain_store_code     IS NULL )           --チェーン店コード
        AND ( lt_key_chain_store_name     IS NULL )           --チェーン店名
        AND ( lt_key_deli_center_code     IS NULL )           --センターコード
        AND ( lt_key_deli_center_name     IS NULL )           --センター名
        AND ( lt_key_edi_district_code    IS NULL )           --地区コード
        AND ( lt_key_edi_district_name    IS NULL )           --地区名
        AND ( lt_key_store_code           IS NULL )           --店舗コード
        AND ( lt_key_cust_store_name      IS NULL )           --店舗名
        AND ( lt_key_delivery_order1      IS NULL )           --配送順（月、水、金）
        AND ( lt_key_delivery_order2      IS NULL )           --配送順（火、木、土）
        AND ( lt_key_bargain_class_name   IS NULL )           --定番特売区分名称
        AND ( lt_key_slip_no              IS NULL )           --伝票NO
        AND ( lt_key_schedule_ship_date   IS NULL )           --出荷日
        AND ( lt_key_request_date         IS NULL )           --着日
        AND ( lt_key_inventory_item_id    IS NULL )           --品目ID
        AND ( lt_key_organization_id      IS NULL )           --在庫品目ID
        AND ( lt_key_item_code            IS NULL )           --商品コード
        AND ( lt_key_item_name            IS NULL )           --商品名
        AND ( lv_key_edi_item_err_flag    IS NULL )           --ＥＤＩ品目エラーフラグ
        AND ( lt_key_item_code2           IS NULL )           --商品コード２
        AND ( lt_key_item_name2           IS NULL )           --商品名２
        AND ( lt_key_case_content         IS NULL ) )         --ケース入数
      THEN
        NULL;
    ELSE
      --内部テーブルセット
      set_internal_table;
    END IF;
--
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      NULL;
    ELSE
      --対象件数
      gn_target_cnt := g_rpt_data_tab.COUNT;
    END IF;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : 帳票ワークテーブル登録(A-3)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- プログラム名
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    --==================================
    -- 1.帳票ワークテーブル登録処理
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT
      INSERT INTO
        xxcos_rep_pick_deli_pro
      VALUES
        g_rpt_data_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- 正常件数
    gn_normal_cnt := g_rpt_data_tab.COUNT;
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_insert_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : ＳＶＦ起動(A-4)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_svf_api       VARCHAR2(5000);
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
    --==================================
    -- 1.明細0件用メッセージ取得
    --==================================
    lv_nodata_msg             := xxccp_common_pkg.get_msg(
                                   iv_application          => ct_xxcos_appl_short_name,
                                   iv_name                 => ct_msg_nodata_err
                                 );
--
    lv_file_name              := cv_file_id ||
                                   TO_CHAR( SYSDATE, cv_fmt_date8 ) ||
                                   TO_CHAR( cn_request_id ) ||
                                   cv_extension_pdf
                                 ;
    --==================================
    -- 2.SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode,
      ov_errbuf               => lv_errbuf,
      ov_errmsg               => lv_errmsg,
      iv_conc_name            => cv_conc_name,
      iv_file_name            => lv_file_name,
      iv_file_id              => cv_file_id,
      iv_output_mode          => cv_output_mode_pdf,
      iv_frm_file             => cv_frm_file,
      iv_vrq_file             => cv_vrq_file,
      iv_org_id               => NULL,
      iv_user_name            => NULL,
      iv_resp_name            => NULL,
      iv_doc_name             => NULL,
      iv_printer_name         => NULL,
      iv_request_id           => TO_CHAR( cn_request_id ),
      iv_nodata_msg           => lv_nodata_msg,
      iv_svf_param1           => NULL,
      iv_svf_param2           => NULL,
      iv_svf_param3           => NULL,
      iv_svf_param4           => NULL,
      iv_svf_param5           => NULL,
      iv_svf_param6           => NULL,
      iv_svf_param7           => NULL,
      iv_svf_param8           => NULL,
      iv_svf_param9           => NULL,
      iv_svf_param10          => NULL,
      iv_svf_param11          => NULL,
      iv_svf_param12          => NULL,
      iv_svf_param13          => NULL,
      iv_svf_param14          => NULL,
      iv_svf_param15          => NULL
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_call_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_call_api_expt THEN
      lv_svf_api              := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_svf_api
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_svf_api
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-5)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- プログラム名
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT
        xrpdp.record_id                 record_id
      FROM
        xxcos_rep_pick_deli_pro         xrpdp               --ピックリスト_出荷先_販売先_製品別帳票ワークテーブル
      WHERE
        xrpdp.request_id                = cn_request_id     --要求ID
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.帳票ワークテーブルデータロック
    --==================================
    BEGIN
      -- ロック用カーソルオープン
      OPEN lock_cur;
      -- ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.帳票ワークテーブル削除
    --==================================
    BEGIN
      DELETE FROM
        xxcos_rep_pick_deli_pro         xrpdp
      WHERE
        xrpdp.request_id                = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --要求ID文字列取得
        lv_key_info           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_request,
                                   iv_token_name1        => cv_tkn_request,
                                   iv_token_value1       => TO_CHAR( cn_request_id )
                                 );
--
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_key_info
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_login_base_code        IN      VARCHAR2,         -- 1.拠点
    iv_login_chain_store_code IN      VARCHAR2,         -- 2.チェーン店
    iv_request_date_from      IN      VARCHAR2,         -- 3.着日（From）
    iv_request_date_to        IN      VARCHAR2,         -- 4.着日（To）
    iv_bargain_class          IN      VARCHAR2,         -- 5.定番特売区分
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
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
/* 2009/07/22 Ver1.8 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
/* 2009/07/22 Ver1.8 Add End   */
--
--###########################  固定部 END   ####################################
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
    gn_warn_cnt               := 0;
--
    -- ===============================
    -- A-0  初期処理
    -- ===============================
    init(
      iv_login_base_code        => iv_login_base_code,          -- 1.拠点
      iv_login_chain_store_code => iv_login_chain_store_code,   -- 2.チェーン店
      iv_request_date_from      => iv_request_date_from,        -- 3.着日（From）
      iv_request_date_to        => iv_request_date_to,          -- 4.着日（To）
      iv_bargain_class          => iv_bargain_class,            -- 5.定番特売区分
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1  パラメータチェック処理
    -- ===============================
    check_parameter(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  データ取得
    -- ===============================
    get_data(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  帳票ワークテーブル登録
    -- ===============================
    insert_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-4  ＳＶＦ起動
    -- ===============================
    execute_svf(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
--
/* 2009/07/22 Ver1.8 Mod Start */
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/07/22 Ver1.8 Mod End   */
--
    -- ===============================
    -- A-3  帳票ワークテーブル削除
    -- ===============================
    delete_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
/* 2009/07/22 Ver1.8 Mod Start */
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
--
/* 2009/07/22 Ver1.8 Mod End   */
    --明細０件時の警告終了制御
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      ov_retcode  := cv_status_warn;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_login_base_code        IN      VARCHAR2,         -- 1.拠点
    iv_login_chain_store_code IN      VARCHAR2,         -- 2.チェーン店
    iv_request_date_from      IN      VARCHAR2,         -- 3.着日（From）
    iv_request_date_to        IN      VARCHAR2,         -- 4.着日（To）
    iv_bargain_class          IN      VARCHAR2          -- 5.定番特売区分
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
      iv_which    => cv_log_header_log,
      ov_retcode  => lv_retcode,
      ov_errbuf   => lv_errbuf,
      ov_errmsg   => lv_errmsg
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
       iv_login_base_code                  -- 1.拠点
      ,iv_login_chain_store_code           -- 2.チェーン店
      ,iv_request_date_from                -- 3.着日（From）
      ,iv_request_date_to                  -- 4.着日（To）
      ,iv_bargain_class                    -- 5.定番特売区分
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG,
      buff    => NULL
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_skip_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --1行空白
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => NULL
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
END XXCOS012A02R;
/
